import ../src/genraw, unittest, os, ../src/parsedgn

test "Raw .DOGEN.json parsing":
    # Generate raw .DOGEN.json documentation for "genraw.nim"
    const outputFilePath =  genRaw("./src/genraw.nim");
    assert fileExists(outputFilePath) == true
    # Parse it
    let content = parseDOGENfile(outputFilePath);
    assert true;
    discard content.name == "genraw";