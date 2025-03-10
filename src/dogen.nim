import os, genmd, genraw, strutils, config
var
  arguments = commandLineParams()

proc help() = 
  echo """
Welcome to DOGEN

DOGEN is a DOcumentation GENerator written in, and for, the NIM programming language.

Usage:
  dogen                           | Displays this help message

  dogen help                      | Displays this help message

  dogen json someFile.nim         | Generates the DOGEN.json file for that nim file

  dogen md someFile.nim           | Generates a markdown documentation for that nim file

  dogen md someFile.dogen.json    | Generates the markdown representation of an already-created dogen.json file

Flags:
  --output                        | Define the path of the desired output file
      dogen md someFile.nim --output:someOutput.md
  
  --config                        | Define the path for the configuration file that will be used in the DOGEN.JSON generation
      dogen json someFile.nim --config:config.json
      or
      dogen mf someFile.nim --config:config.json

"""

var command = ""
if arguments.len() > 0:
  command = arguments[0]
else:
  help()
  quit(0)

proc red(msg: string, error=true) = 
  echo "\e[31m"&msg&"\e[0m";
  if error:
    quit(1)

proc green(msg: string) = 
  echo "\e[32m" & msg & "\e[0m";

proc getFilePath(minArguments:int=2):string = 
  if arguments.len >= minArguments:
    let filePath = arguments[1];
    return filePath
  else:
    red("Error: Some arguments are missing")

if command == "help":
  help()
  quit(0)

proc json(): string = 
  let filePath = getFilePath();
  var withOutput = false;
  var output = "";
  var withConfig = false;
  var config: Config = Config()
  var configPath = "";
  # Specified output file
  for a in arguments:
    if "--output:" in a:
      withOutput = true;
      output = a.replace("--output:","")
    if "--config:" in a:
      withConfig = true;
      configPath = a.replace("--config:","")
      # Read config file
      config = parseConfig(configPath);
  if withOutput:
    return genRaw(filePath, output, config)
  else:
    return genRaw(filePath, config=config)

if command == "json":
  green json()

elif command == "md":
  let filePath = getFilePath();
  if filePath.endsWith(".dogen.json"):
    green DOGENtoMD(filePath)
  elif filePath.endsWith(".nim"):
    let jsonpath = json()
    green DOGENtoMD(jsonpath)
  else:
    red "File type not compatible. You can only generate MarkDown from .dogen.json or nim files"
else:
  red("Error: Command not found")