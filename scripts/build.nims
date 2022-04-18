import os, strutils

const
  compatFlag = "-DLUA_COMPAT_ALL" # or "-DLUA_COMPAT_5_2"
  linkFlags = ""
  extraFlag = when defined(unix):
      "-fPIC" #"-DLUA_BUILD_AS_DLL"
    else:
      when defined(build32):
        "-m32"
      else:
        ""

when defined(MACOSX):
  const LIB_NAME* = "liblua5.3.dylib"
elif defined(FREEBSD):
  const LIB_NAME* = "liblua-5.3.so"
elif defined(UNIX):
  const LIB_NAME* = "liblua5.3.so"
else:
  const LIB_NAME* = "lua53.dll"

type
  FileName = tuple[dir, name, ext: string]

proc getCFiles(dir: string): seq[FileName] =
  var files = listFiles(dir)
  result = @[]
  for c in files:
    let x = c.splitFile
    if cmpIgnoreCase(x.name, "lua") == 0: continue
    if cmpIgnoreCase(x.name, "luac") == 0: continue
    if cmpIgnoreCase(x.ext, ".c") == 0:
      result.add x

proc toString(names: seq[string]): string =
  result = ""
  for c in names:
    result.add c
    result.add " "

#

proc objList(staticLib: bool): string =
  let src = getCFiles("external" / "lua" / "src")
  var objs: seq[string] = @[]

  for x in src:
    let fileName = x.dir / x.name
    let buildCmd = if not staticLib:
        "gcc -O2 -Wall $1 $2 -c -o $3.o $3.c $4" % [extraFlag, compatFlag, fileName, linkFlags]
      else:
        "gcc -O2 -Wall $1 -c -o $2.o $2.c" % [compatFlag, fileName]
    try:
      exec(buildCmd)
      echo buildCmd
      objs.add(fileName & ".o")
    except:
      echo "failed to build ", fileName

  result = toString(objs)

proc makeLib(staticLib: bool) =
  echo "building ", if staticLib: "static" else: "dynamic"

  let linkCmd = if staticLib:
      "ar rcs external/liblua.a " & objList(staticLib)
    else:
      "gcc -shared $4 -o $1$2$3 $5" % [".", $DirSep, LIB_NAME, extraFlag, objList(staticLib)]

  echo linkCmd
  exec(linkCmd)

makeLib(defined(volanaStatic))

