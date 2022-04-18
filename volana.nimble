packageName   = "volana"
version       = "0.4.0"
author        = "Andri Lim, de-odex"
description   = "glue code generator to bind Nim and Lua together using Nim's powerful macro"
license       = "MIT"
skipDirs      = @["test", "scripts"]
srcDir        = "src"

requires: "nim >= 1.2.2"

### Helper functions
proc test(defines, path: string) =
  # Compilation language is controlled by TEST_LANG
  var lang = "c"
  if existsEnv"TEST_LANG":
    lang = getEnv"TEST_LANG"
    debugEcho "LANG: ", lang

  when defined(unix):
    const libm = "-lm"
  else:
    const libm = ""

  # nim bug not applicable for 1.2.14
  # when defined(macosx):
  #   # nim bug, incompatible pointer assignment
  #   # see nim-lang/Nim#16123
  #   if lang == "cpp":
  #     lang = "c"

  if not dirExists "build":
    mkDir "build"

  let command = "nim c --backend:" & lang & " " & defines &
  " --outdir:build -r --hints:off --warnings:off " &
  " -d:lua_static_lib --passL:\"-Lexternal -llua " & libm & "\" " & path

  echo "running ", command

  exec command


task test, "Run all tests":
  test "-d:nimDebugDlOpen", "tests/test_features"
  test "-d:nimDebugDlOpen -d:release", "tests/test_features"
  test "-d:importLogging", "tests/test_bugfixes"
  test "-d:importLogging -d:release", "tests/test_bugfixes"
