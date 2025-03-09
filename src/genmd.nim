import parsedgn, strformat, tables, strutils, genraw, json, utils

proc parseSingleItem(i: WalkItem): string = 
    var res: string = "\n## " & i.name & " (`" & i.typeName & "`)";
    let lines = i.body.split("\n")
    # init shown
    # If the result typeName is blank, it does not exist
    var shownReturn = (i.returns.typeName == "");
    var shownParams: Table[string, bool] = initTable[string, bool]()
    for p in i.params.keys:
        shownParams[p] = false;
    # loop over lines and create document
    for l in lines:
        # Add if common
        if not l.startsWith("@"):
            res = res & "\n" & l;
        # Add returns
        if l.startsWith("@returns") and not shownReturn:
            shownReturn = true;
            var added = "### Output (`" & i.returns.typeName.removeSuffix(" ") & "`)"
            if i.returns.description != "":
                added = added & "\n" & i.returns.description;
            res = res & "\n" & added;
        # Add example
        if l.startsWith("@example"):
            res = res & "\n```\n" & i.example & "\n```";
        # Add param
        if l.startsWith("@param"):
            let paramName = l.replace("@param","")
            if paramName in i.params:
                res = res & "\n### Parameter `" & paramName & "` (`" & i.params[paramName].typeName & "`)";
                if i.params[paramName].description != "":
                    res = res & "\n" & i.params[paramName].description;
                if i.params[paramName].default != "!exists":
                    res = res & "\nDefault parameter value:" & i.params[paramName].default;

    return res;

proc generateMD*(dogen: WalkCont): string = 
    # Generate
    # Parse the file data
    let data: WalkCont = dogen;
    # Start generating
    # Init from metadata
    var md: string = &"""From [{data.name}.nim]({data.source}) Using [**DOGEN**](https://roger-padrell.github.io/dogen/)
# {data.name}"""

    # Add main
    var main = (parseSingleItem(data.items["main"])).replace("## main (`main`)","")
    md = md & "\n" & main;

    # Add all but main
    for item in data.items.keys:
        if data.items[item].name != "main" and data.items[item].typeName != "main":
            md = md & "\n" & parseSingleItem(data.items[item])

    return md;

proc NIMtoMD*(filePath: string, outputFilePath: string = filePath.replace(".nim",".md")): string = 
    let dogen = parseDOGEN($generateJSON(filePath))
    let content = generateMD(dogen)
    writeFile(outputFilePath, content)
    return outputFilePath;

proc DOGENtoMD*(filePath: string, outputFilePath: string = filePath.replace(".dogen.json",".md")): string = 
    let content = generateMD(parseDOGENfile(filePath))
    writeFile(outputFilePath, content)
    return outputFilePath;