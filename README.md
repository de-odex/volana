# Volana
I'm still setting things up here, most of everything is still identical to nimLUA, just with different naming.
Volana is a fork of nimLUA, adding some things I think would be neat and changing some stuff I don't like.
Naturally, this makes the library relatively opinionated.
Please note that version numbers will not follow nimLUA. Changes moving forward will not always follow nimLUA.

---

glue code generator to bind Nim and Lua together using Nim's powerful macro

![nimble](https://img.shields.io/badge/available%20on-nimble-yellow.svg?style=flat-square)
![license](https://img.shields.io/github/license/citycide/cascade.svg?style=flat-square)
![Github action](https://github.com/de-odex/volana/workflows/CI/badge.svg)
- - -

**Features**:

* bind free proc
* bind proc as Lua method
* bind const
* bind enum
* bind object
* generic proc binding
* closure binding
* properties getter/setter
* automatic resolve overloaded proc
* easy namespace creation
* easy debugging
* consistent simple API
* can rename exported symbol
* support automatic type conversion
* can change binding dynamically at runtime too
* generate clean and optimized glue code that you can inspect at compile time
* it's free

**planned features**:

* complex data types conversion, at least standard container
* access Lua code/data from Nim

- - -
**Current version API**:
no need to remember complicated API, the API is simple but powerful

* newVolana
* bindEnum
* bindConst
* bindFunction/bindProc
* bindObject

- - -

## **DATA TYPE CONVERSION**

| Nim | Lua |
|--------------------------------|----------------------------------|
| char,int,uint,int8-64,uint8-64 | integer/number |
| float, float32, float64 | number |
| array[0..n, T], [n, T] | array[1..n] |
| enum | integer/number |
| string, cstring | string |
| ref/object | userdata |
| bool | boolean |
| seq[T] | array[1..n] |
| set[T] | table with unique element |
| pointer | light user data |
| ptr T | light user data |
| range/subrange | integer |
| openArray[T] | table -> seq[T] |
| tuple | assoc-table or array |
| varargs[T] | not supported |
---
## **HOW TO USE**

### **1. bindEnum**

```nimrod
import volana, os

type
  FRUIT = enum
    APPLE, BANANA, PEACH, PLUM
  SUBATOM = enum
    ELECTRON, PROTON, NEUTRON
  GENE = enum
    ADENINE, CYTOSINE, GUANINE, THYMINE

proc test(L: PState, fileName: string) =
  if L.doFile("test" & DirSep & fileName) != 0.cint:
    echo L.toString(-1)
    L.pop(1)
  else:
    echo fileName & " .. OK"

proc main() =
  var L = newVolana()
  L.bindEnum(FRUIT, SUBATOM, GENE)
  L.test("test.lua")
  L.close()

main()
```
and you can access them at Lua side like this:

```Lua
assert(FRUIT.APPLE == 0)
assert(FRUIT.BANANA == 1)
assert(FRUIT.PEACH == 2)
assert(FRUIT.PLUM == 3)

assert(GENE.ADENINE == 0)
assert(GENE.CYTOSINE == 1)
assert(GENE.GUANINE == 2)
assert(GENE.THYMINE == 3)

assert(SUBATOM.ELECTRON == 0)
assert(SUBATOM.PROTON == 1)
assert(SUBATOM.NEUTRON == 2)
```

another style:

```nimrod
L.bindEnum:
  FRUIT
  SUBATOM
  GENE
```
if you want to rename the namespace, you can do this:
```nimrod
L.bindEnum:
  GENE -> "DNA"
  SUBATOM -> GLOBAL
```
or
```nimrod
L.bindEnum(GENE -> "DNA", SUBATOM -> GLOBAL)
```

a note on **GLOBAL** and "GLOBAL":

* **GLOBAL** without quote will not create namespace on Lua side but will bind the symbol in Lua globalspace
* "GLOBAL" with quote, will create "GLOBAL" namespace on Lua side

now Lua side will become:

```Lua
assert(DNA.ADENINE == 0)
assert(DNA.CYTOSINE == 1)
assert(DNA.GUANINE == 2)
assert(DNA.THYMINE == 3)

assert(ELECTRON == 0)
assert(PROTON == 1)
assert(NEUTRON == 2)
```

### **2. bindConst**

```nimrod
import volana

const
  MANGOES = 10.0
  PAPAYA = 11.0'f64
  LEMON = 12.0'f32
  GREET = "hello world"
  connected = true

proc main() =
  var L = newVolana()
  L.bindConst(MANGOES, PAPAYA, LEMON)
  L.bindConst:
    GREET
    connected
  L.close()

main()
```

by default, bindConst will not generate namespace, so how do you create namespace for const? easy:

```nimrod
L.bindConst("fruites", MANGOES, PAPAYA, LEMON)
L.bindConst("status"):
  GREET
  connected
```
first argument(actually second) to bindConst will become the namespace. Without namespace, symbol will be put into global namespace

if you use **GLOBAL** without quote as namespace, it will have no effect

operator `->` have same meaning with bindEnum, to rename exported symbol on Lua side

### **3. bindFunction/bindProc**

bindFunction is an alias to bindProc, they behave identically

```nimrod
import volana

proc abc(a, b: int): int =
  result = a + b

var L = newVolana()
L.bindFunction(abc)
L.bindFunction:
  abc -> "cba"
L.bindFunction("alphabet", abc)
```

bindFunction more or less behave like bindConst, without namespace, it will bind symbol to global namespace.

overloaded procs will be automatically resolved by their params count and types

operator `->` have same meaning with bindEnum, to rename exported symbol on Lua side

### **4. bindObject**

```nimrod
import volana

type
  Foo = ref object
    name: string

proc newFoo(name: string): Foo =
  new(result)
  result.name = name

proc addv(f: Foo, a, b: int): int =
  result = 2 * (a + b)

proc addv(f: Foo, a, b: string): string =
  result = "hello: my name is $1, here is my message: $2, $3" % [f.name, a, b]

proc addk(f: Foo, a, b: int): string =
  result = f.name & ": " & $a & " + " & $b & " = " & $(a+b)

proc main() =
  var L = newVolana()
  L.bindObject(Foo):
    newFoo -> constructor
    addv
    addk -> "add"
  L.close()

main()
```
this time, Foo will become object name and also namespace name in Lua

"newFoo `->` constructor" have special meaning, it will create constructor on Lua side with special name: `new`(this is an artefact)
but any other constructor like procs will be treated as constructor too:

```nimrod
L.bindObject(Foo):
  newFoo                    #constructor #1 'newFoo'
  newFoo -> constructor     #constructor #2 'new'
  newFoo -> "whatever"      #constructor #3 'whatever'
  makeFoo -> "constructor"  #constructor #4 'constructor'
```

operator `->` on non constructor will behave the same as other binder.

overloaded proc will be automatically resolved by their params count and types, including overloaded constructor

destructor will be generated automatically for ref object, none for regular object.
GC safety works as usual on both side of Nim and Lua, no need to worry, except when you manually allocated memory

```Lua
local foo = Foo.new("fred")
local m = foo:add(3, 4)

-- "fred: 3 + 4 = 7"
print(m)

assert(foo:addv(4,5) == 2 * (4+5))

-- "hello: my name is fred, here is my message: abc, nop"
print(foo:addv("abc", "nop"))
```

operator `->` when applied to object, will rename exported symbol on Lua side:

```nimrod
L.bindObject(Foo -> "cat"):
  newFoo -> constructor
```

on Lua side:

```lua
local c = cat.new("fred") --not 'Foo' anymore
```

both **bindObject** and **bindFunction** and **bindConst** can add member to existing namespace

if you want to turn off this functionality, call **volanaOptions**(nloAddMember, false)

```nimrod
L.bindObject(Foo): #namespace creation
  newFoo -> constructor

L.bindObject(Foo): #add new member
  addv
  addk -> "add"

L.bindFunction("gem"): #namespace "gem" creation
  mining

L.bindFunction("gem"): #add 'polish' member
  polish
```

#### **4.1. bindObject without member**

It's ok to call bindObject without any additional member/method if you want to
register object type and use it later. For example if you want to create your own
object constructor

#### **4.2. bindObject for opaque C pointer**

Usually a C library have constructor(s) and destructor function.
The constructor will return an opaque pointer.

On Nim side, we usually use something like:

```Nim
type
  CContext* = distinct pointer

proc createCContext*(): CContext {.cdecl, importc.}
proc deleteCContext*(ctx: CContext) {.cdecl, importc.}
```

Of course this is not an object or ref object, but we treat it as an object in this case.
Therefore bindObject will work like usual.
Only this time, we also need to specify the destructor function using `~` operator.

```Nim
L.bindObject(CContext):
  createCContext -> "create"
  ~deleteCContext
```

## **PASSING BY REFERENCE**

Lua basic data types cannot be passed by reference, but Nim does

if you have something like this in Nim:

```nimrod
proc abc(a, b: var int) =
  a = a + 1
  b = b + 5
```

then on Lua side:

```lua
a = 10
b = 20
a, b = abc(a, b)
assert(a == 11)
assert(b == 25)
```

basically, outval will become retval, FIFO ordered

## **GENERIC PROC BINDING**
```nimrod
proc mew[T, K](a: T, b: K): T =
  discard

L.bindFunction:
  mew[int, string]
  mew[int, string] -> "mewt"
```

## **CLOSURE BINDING**
```nimrod
proc main() =
  ...

  var test = 1237
  proc cl() =
    echo test

  L.bindFunction:
    [cl]
    [cl] -> "clever"
```

## **GETTER/SETTER**
```nimrod
type
  Ship = object
    speed*: int
    power: int

L.bindObject(Ship):
  speed(set)
  speed(get) -> "currentSpeed"
  speed(get, set) -> "velocity"
```

then you can access the object's properties on lua side using '.' (dot) and not ':' (colon)
```lua
local b = Ship.newShip()
b.speed = 19
assert(b.speed == nil) -- setter only
assert(b.currentSpeed == 19) -- getter only
b.velocity = 20
assert(b.velocity == 20) -- getter & setter
```

## **HOW TO DEBUG**

you can call **volanaOptions**(nloDebug, true/false)

```nimrod
volanaOptions(nloDebug, true) #turn on debug
L.bindEnum:
  GENE
  SUBATOM

volanaOptions(nloDebug, false) #turn off debug mode
L.bindFunction:
  machine
  engine
```

## **DANGEROUS ZONE**
lua_error, lua_checkstring, lua_checkint, lua_checkudata and other lua C API that can throw error
are dangerous functions when called from Nim context. lua_error use `longjmp` when compiled to C
or `throw` when compiled to C++.

Although Nim compiled to C, Nim have it's own stack frame. Calling lua_error and other functions
that can throw error will disrupt Nim stack frame, and application will crash.

Volana avoid using those dangerous functions and and use it's own set of functions that is considerably
safe. those functions are:

| lua | Volana |
|-----|--------|
| lua_error | N/A |
| lua_checkstring | nimCheckString |
| lua_checkinteger | nimCheckInteger |
| lua_checkbool | nimCheckBool |
| lua_checknumber | nimCheckNumber |
| N/A | nimCheckCstring |
| N/A | nimCheckChar |
| lua_newmetatable | nimNewMetaTable |
| lua_getmetatable | nimGetMetaTable |
| lua_checkudata | nimCheckUData |

## **Error Handling**
```Nim
  NLError* = object
    source: string
    currentLine: int
    msg: string

  NLErrorFunc* = proc(ctx: pointer, err: NLError) {.nimcall.}

proc NLSetErrorHandler*(L: PState, errFunc: NLErrorFunc)
proc NLSetErrorContext*(L: PState, errCtx: pointer)
```

This is actually not a real error handler, because you cannot use raise exception.
The purpose of this function is to provide information to user about wrong argument type
passed from Lua to Nim.

Volana already provide a default error handler in case you forget to provide one.

## **HOW TO ACCESS LUA CODE FROM NIM?**

still under development, contributions are welcome

## Installation via nimble
> nimble install https://github.com/de-odex/volana

## Override shared library name

You can use compiler switch `-d:SHARED_LIB_NAME="yourlibname"`

```bash
$> nim c -r -d:SHARED_LIB_NAME="lua534.dll" test/test
```
