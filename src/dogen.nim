import os, genmd, genraw, strutils
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
if command == "json":
  let filePath = getFilePath();
  echo genRaw(filePath)
elif command == "md":
  let filePath = getFilePath();
  if filePath.endsWith(".dogen.json"):
    green DOGENtoMD(filePath)
  elif filePath.endsWith(".nim"):
    green NIMtoMD(filePath)
  else:
    red "File type not compatible. You can only generate MarkDown from .dogen.json or nim files"
else:
  red("Error: Command not found")