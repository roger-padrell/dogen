import os, utils
import std/strutils, std/json, std/tables

## This module generates a JSON object/file with the content that will be then rendered to other languages like HTML, MarkDown...

type Param = object
    ## A parameter in a proc
    name*: string
    typeName*: string
    description*: string
    default*: string = "!exists"

type

    Returns = object
        description*: string
        typeName*: string

    WalkItem* = object
        ## An item in the documentation
        name*: string
        fullContent*: string = ""
        body*: string = ""
        description*: string = ""
        typeName*: string = ""
        returns*: Returns = Returns()
        params*: Table[string, Param] = initTable[string, Param]()
        example*: string = ""
        
    WalkCont* = object
        name*: string
        source*: string
        items*: Table[string, WalkItem]

    ILevel = object
        name*: string
        kind*: string

    IndentationList = seq[ILevel]

proc formatFullContent(res: var WalkCont) = 
    ## Format a WalkCont
    for item in res.items.keys:
        res.items[item].fullContent.removePrefix("\n")
        res.items[item].fullContent.removeSuffix("\n")
        res.items[item].fullContent.removeWhiteSpace()
        var lineN = 0;
        var inExample = false;
        for line in res.items[item].fullContent.split("\n"):
            # Remove the DocComent
            var noComSeq: seq[string] = line.split("##");
            noComSeq.del(0)
            let withoutComment = noComSeq.join("##")
            let withoutIndent = withoutComment.removeWhiteSpace();

            # Set as description if it's first line
            if lineN == 0:
                res.items[item].description = withoutIndent;

            # Add to body if it does not start with "@" (it's not an object marker)
            if not (withoutIndent.startsWith("@")) and not inExample:
                if res.items[item].body != "":
                    res.items[item].body = res.items[item].body & "\n" & withoutIndent
                else:
                    res.items[item].body = withoutIndent;

            # Add to example if "inExample" is true and it does not start with "@eox"
            if not (withoutIndent.startsWith("@eox")) and inExample:
                if res.items[item].example != "":
                    res.items[item].example = res.items[item].example & "\n" & withoutComment
                else:
                    res.items[item].example = withoutComment;

            # Turn "inExample" on/off
            if withoutIndent.startsWith("@eox"):
                inExample = false;
            if withoutIndent.startsWith("@example"):
                inExample = true;
                # Add "@example" to body
                if res.items[item].body != "":
                    res.items[item].body = res.items[item].body & "\n@example"
                else:
                    res.items[item].body = "@example";

            # Add returns description
            if withoutIndent.startsWith("@returns"):
                # Add "@returns" to body
                if res.items[item].body != "":
                    res.items[item].body = res.items[item].body & "\n@returns"
                else:
                    res.items[item].body = "@returns";
                # Add data to "returns"
                res.items[item].returns.description = withoutIndent.split("@returns")[1].removeWhiteSpace()

            # Add parameter description
            if withoutIndent.startsWith("@param"):
                let paramName = withoutIndent.split("@param")[1].split(" ")[1]
                # Add "@param+name" to body
                if res.items[item].body != "":
                    res.items[item].body = res.items[item].body & "\n@param" & paramName
                else:
                    res.items[item].body = "@param" & paramName;
                # Add data to "param[name]"
                res.items[item].params[paramName].description = withoutIndent.split(paramName)[1].removeWhiteSpace()

            # Update lineN
            lineN = lineN + 1;

proc generateJSON*(filePath: string): JsonNode = 
    ## This function generates the JSON object with the pre-render content
    ## @param filePath The path to the file that will be readed and converted to JSON documentation
    ## @returns The JSON Object
    ## @example
    ## # Import the module...
    ## echo generateJSON("test1.nim")
    ## @eox
    if not fileExists(filePath):
        raise newException(Exception,"File " & filePath & " not found")
    let file = readFile(filePath)
    let fileLines = file.split("\n")

    var res: WalkCont = WalkCont(name: filePath.lastPathPart().split(".")[0], source: filePath)
    var addedItems: seq[string] = @[];
    var current: int = 0;
    var indentCount: string = "    ";
    var multipleTypes = false;
    var indent: IndentationList = @[ILevel(name:"main", kind:"main")]

    # Count the leading spaces with the first line with indentation to get the default indentation count (directly as a string made of spaces)
    for f in fileLines:
        if f.startsWith(" "):
            indentCount = " ".repeat(f.countLeadingSpaces())
            break;
    # Create the objects in the indent
    var n = -1;
    for f in fileLines:
        n = n + 1;
        # Update "current" and "indent" if necessary
        # Remove item from indent
        if (f.countLeadingSpaces()/indentCount.len()) < float(current):
            let toRemove = float(current) - (f.countLeadingSpaces()/indentCount.len())
            for i in 0..int(toRemove):
                if indent[current].name == "*multipleTypeGen*" and (("=" in fileLines[n+2] and (not ("proc" in fileLines[n+2]) and not ("let " in fileLines[n+2]) and not ("var " in fileLines[n+2]) and not ("const " in fileLines[n+2]))) or ("=" in fileLines[n+1] and (not ("proc" in fileLines[n+1]) and not ("let " in fileLines[n+1]) and not ("var " in fileLines[n+1]) and not ("const " in fileLines[n+1])))):
                    break;
                else:
                    current = current - 1;
                    indent.shrink(current+1)

        # Remove indent
        var removedIndent = f;
        removedIndent.removeWhiteSpace()
        # Check if it provoques a change of indent
        if removedIndent.startsWith("if"):
            indent.add(ILevel(name:"if", kind:"if"))
            current = current + 1;
        elif removedIndent.startsWith("for"):
            indent.add(ILevel(name:"for", kind:"for"))
            current = current + 1;
        elif removedIndent.startsWith("while"):
            indent.add(ILevel(name:"while", kind:"while"))
            current = current + 1;
        elif removedIndent.startsWith("proc"):
            indent.add(ILevel(name:removedIndent.split(" ")[1].split("(")[0], kind:"proc"))
            current = current + 1;
            # Parse params
            var params: Table[string, Param] = initTable[string, Param]()
            let betweenParenthesis = removedIndent.split("(")[1].split(")")[0]
            let paramString = betweenParenthesis.split(",")
            if not (paramString.len() == 1 and paramString[0] == ""):
                for p in paramString:
                    let pa = p.split(":")
                    if "=" in pa[1]:
                        params[pa[0].removeWhiteSpace()] = Param(name: pa[0].removeWhiteSpace(), typeName: pa[1].split("=")[0].removeWhiteSpace(), default: pa[1].split("=")[1].removeWhiteSpace())
                    else:
                        params[pa[0].removeWhiteSpace()] = Param(name: pa[0].removeWhiteSpace(), typeName: pa[1].removeWhiteSpace())

            # Parse return type
            var afterPArr = removedIndent.split(")")
            afterPArr.del(0);
            let afterP = afterPArr.join(")")
            var returnType = "";
            if ":" in afterP:
                returnType = afterP.split(":")[1].split("=")[0]
            returnType.removeWhiteSpace()
            # Add as WalkItem
            res.items[indent[current].name] = WalkItem(name:indent[current].name, params:params, returns: Returns(typeName:returnType), typeName: "proc")
            addedItems.add(indent[current].name)
        elif removedIndent.startsWith("type") and len(removedIndent.split(" ")) > 1:
            indent.add(ILevel(name:removedIndent.split(" ")[1], kind:"type"))
            current = current + 1;
        elif removedIndent.startsWith("type"):
            multipleTypes = true;
            indent.add(ILevel(name:"*multipleTypeGen*", kind:"type"))
            current = current + 1;
        elif multipleTypes and ("=" in removedIndent):
            indent.add(ILevel(name:removedIndent.split(" ")[0], kind:"type"))
            current = current + 1;

        # Use if it's a documentation coment (##)
        # Classify each doccoment in the "fullContent" property
        if removedIndent.startsWith("##"):
            if indent[current].name in addedItems:
                res.items[indent[current].name].fullContent = res.items[indent[current].name].fullContent & "\n" & f
            else:
                res.items[indent[current].name] = WalkItem(name:indent[current].name, typeName: indent[current].kind)
                res.items[indent[current].name].fullContent = f;
                addedItems.add(indent[current].name)

    # Format the "fullContent" into specialized properties
    res.formatFullContent()

    return %* res

proc genRaw*(filePath: string, outputFilePath: string = filePath.replace(".nim",".dogen.json")): string = 
    let content = $pretty(generateJSON(filePath))
    writeFile(outputFilePath, content)
    return outputFilePath;