import os
import std/strformat, std/strutils, std/json, std/tables

## This module generates a JSON object/file with the content that will be then rendered to other languages like HTML, MarkDown...

type Param = object
    ## A parameter in a proc
    name*: string
    typeName*: string
    description*: string
    default*: string = "!exists"

type
    WalkItem* = object
        ## An item in the documentation
        name*: string
        fullContent*: string = ""
        description*: string = ""
        returns*: string = ""
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

proc countLeadingSpaces(s: string): int =
  result = 0
  for c in s:
    if c == ' ':
        inc(result)
    else:
        break

proc formatFullContent(res: var WalkCont) = 
    discard

proc generateJSON*(filePath: string): JsonNode = 
    ## This function generates the JSON object with the pre-render content
    ## @params filePath The path to the file that will be readed and converted to JSON documentation
    ## @returns The JSON Object
    ## @example
    ## # Import the module...
    ## echo generateJSON("test1.nim")
    if not fileExists(filePath):
        echo &"File {filePath} does not exist"
        return;
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
    for f in fileLines:
        # Update "current" and "indent" if necessary
        # Remove item from indent
        if (f.countLeadingSpaces()/indentCount.len()) < float(current):
            let toRemove = float(current) - (f.countLeadingSpaces()/indentCount.len())
            for i in 0..int(toRemove):
                if indent[current].name == "*multipleTypeGen*":
                    multipleTypes=false;
                current = current - 1;
                indent.shrink(current+1)

        # Remove indent
        var removedIndent = f;
        removedIndent.removePrefix(" ".repeat(removedIndent.countLeadingSpaces()))
        removedIndent.removeSuffix(" ")
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
            var params: Table[string, Param] = initTable[string, Param]()
            let betweenParenthesis = removedIndent.split("(")[1].split(")")[0]
            let paramString = betweenParenthesis.split(",")
            if not (paramString.len() == 1 and paramString[0] == ""):
                for p in paramString:
                    let pa = p.split(":")
                    if "=" in pa[1]:
                        params[pa[0]] = Param(name: pa[0], typeName: pa[1].split("=")[0], default: pa[1].split("=")[1])
                    else:
                        params[pa[0]] = Param(name: pa[0], typeName: pa[1])

                res.items[indent[current].name] = WalkItem(name:indent[current].name, params:params)
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
                res.items[indent[current].name] = WalkItem(name:indent[current].name)
                res.items[indent[current].name].fullContent = f;
                addedItems.add(indent[current].name)

        # Format the "fullContent" into specialized properties
        res.formatFullContent()

    return %* res