import ../src/genmd, unittest, os, ../src/genraw

suite "Markdown":
    test "NIM to MD":
        # Generate Markdown documentation for "genraw.nim"
        const outputFilePath = NIMtoMD("./src/genraw.nim");
        echo outputFilePath
    test "DOGEN to MD":
        # Generate raw .DOGEN.json documentation for "genraw.nim"
        const dogenFilePath = genRaw("./src/genraw.nim");
        assert fileExists(dogenFilePath) == true
        const outputFPath = DOGENtoMD(dogenFilePath)