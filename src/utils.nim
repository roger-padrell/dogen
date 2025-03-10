import strutils, tables

proc countLeadingSpaces*(s: string): int =
  result = 0
  for c in s:
    if c == ' ':
        inc(result)
    else:
        break

proc removeWhiteSpace*(s: var string) = 
    s.removePrefix(" ".repeat(s.countLeadingSpaces()))

proc removeWhiteSpace*(st: string): string = 
    var s = st;
    s.removePrefix(" ".repeat(s.countLeadingSpaces()))
    return s;

proc removePrefix*(s: string, sub: string): string = 
    var st = s;
    st.removePrefix(sub)
    return st;

proc removeSuffix*(s: string, sub: string): string = 
    var st = s;
    st.removeSuffix(sub)
    return st;

type Param* = object
    ## A parameter in a proc
    name*: string
    typeName*: string
    description*: string
    default*: string = "!exists"

type
    Returns* = object
        description*: string
        typeName*: string

    WalkItem* = object
        ## An item in the documentation
        name*: string
        fullContent*: string = ""
        body*: string = ""
        description*: string = ""
        typeName*: string = ""
        returns*: Returns = Returns()
        params*: Table[string, Param] = initTable[string, Param]()
        example*: string = ""
        
    WalkCont* = object
        name*: string
        source*: string
        items*: Table[string, WalkItem]

    ILevel* = object
        name*: string
        kind*: string

    IndentationList* = seq[ILevel]