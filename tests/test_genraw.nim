import ../src/genraw, unittest, os

test "Raw .DOGEN.json generation":
    # Generate raw .DOGEN.json documentation for "genraw.nim"
    const outputFilePath =  genRaw("./src/genraw.nim");
    assert fileExists(outputFilePath) == true