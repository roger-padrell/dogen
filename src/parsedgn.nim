import ./genraw, jsony, os, tables

proc parseDOGEN*(dogen: string): WalkCont = 
    return dogen.fromJson(WalkCont)

proc parseDOGENfile*(filePath: string): WalkCont = 
    if not fileExists(filePath):
        raise newException(Exception,"File " & filePath & " not found")
    let file = readFile(filePath)
    return parseDOGEN(file)

export genraw