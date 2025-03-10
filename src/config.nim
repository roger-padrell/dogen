import utils, tables, strutils, os, jsony

type Config* = object
    onlyExported*: bool = false
    name*: string = "*default*"
    source*: string = "*default*"


proc parseConfigText*(configText: string): Config = 
    return configText.fromJson(Config)

proc parseConfig*(filePath: string): Config = 
    if not fileExists(filePath):
        raise newException(Exception,"File " & filePath & " not found")
    let file = readFile(filePath)
    return parseConfigText(file)

proc useConfig*(data: var WalkCont, config: Config) =
    # Filter only exported
    if config.onlyExported == true:
        var datakeys: seq[string] = @[];
        for item in data.items.keys:
            datakeys.add(item)
        for item in datakeys:
            if (not item.endsWith("*")) and (item != "main"):
                data.items.del(item)

    # Set custom name
    if config.name != "*default*":
        data.name = config.name;

    # Set custom source
    if config.source != "*default*":
        data.source = config.source;