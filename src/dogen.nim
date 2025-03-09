import os, genmd, genraw
var
  arguments = commandLineParams()

let command = arguments[0]

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

if command == "json":
  let filePath = getFilePath();
  echo genRaw(filePath)
elif command == "md":
  let filePath = getFilePath();
  green genRaw(filePath)
else:
  red("Error: Command not found")