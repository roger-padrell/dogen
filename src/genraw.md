From [genraw.nim](./src/genraw.nim) Using [**DOGEN**](https://roger-padrell.github.io/dogen/)
# genraw


This module generates a JSON object/file with the content that will be then rendered to other languages like HTML, MarkDown...

## Param (`type`)
A parameter in a proc

## generateJSON* (`proc`)
This function generates the JSON object with the pre-render content
### Parameter `filePath` (`string`)
The path to the file that will be readed and converted to JSON documentation
### Output (`JsonNode`)
The JSON Object
```
 # Import the module...
 echo generateJSON("test1.nim")
```

## formatFullContent (`proc`)
Format a WalkCont

## WalkItem* (`type`)
An item in the documentation

## genRaw* (`proc`)
