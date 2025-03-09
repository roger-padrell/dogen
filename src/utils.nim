import strutils

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