  # ######################################################################################################################################################### #
 # ################################################################### PARSER ASM ########################################################################## #
# ######################################################################################################################################################### #

import std/[tables, strutils, parseopt]

type
  ASMOp = enum
    opHalt = 0 # Default op to stop the program

    # System ops
    opLoad = 1
    opStore = 2
    opPush = 3
    opPop = 4

    # Arithmetic ops
    opAdd = 5
    opSub = 6
    opMul = 7
    opDiv = 8

    # Branching
    opBranch = 9
    opBGT = 10
    opBGE = 11
    opBEZ = 12
    opBLT = 13
    opBLE = 14

    # IO
    opRead = 15
    opPrint = 16

    # Unknown
    opUnknown = 17

  ASMExecMode = enum
    aemZeroAddr
    aemOneAddr
    aemTwoAddr
    aemThreeAddr

  TokenKind = enum
    noToken
    cmdToken
    regToken
    labToken
    immToken

  Token = object
    case kind: TokenKind
    of cmdToken:
      op: ASMOp
    of regToken, labToken:
      name: string
    else:
      value: int
    
    children: seq[Token]

  CodeGenCtx = object
    mode: ASMExecMode
    symbols: Table[string, int]
    pc: int
    goToLabel: string
    lastRes: int
    acc: int
    stack: seq[int]

const 
  VERSION = "v0.1.0"
  HOST_PLATFORM = 
    when defined(windows): "Windows"
    elif defined(macosx): "MacOS"
    elif defined(bsd): "FreeBSD"
    else: "Linux"
  USAGE = "ASM Compiler for Computer Architecture Course " & VERSION & """

   (c) 2026 Kaptue Talom

Usage:
  archer [options] [command]

Command:
  r project.asm: Run the ASM program
  
Options:
  -m, --mode: How the ASM code will be run, expected values are 0, 1, 2, 3
  """

proc writeHelp() = quit(USAGE, QuitSuccess)
proc writeVersion() = quit(VERSION & " " & HOST_PLATFORM & "\n", QuitSuccess)

  # ######################################################################################################
 # #
# ########################################################################################################

proc toOp(op: string): ASMOp =
  let rawOp = op.toLowerAscii()
  case rawOp:
  of "exit": opHalt
  of "load": opLoad
  of "store": opStore
  of "push": opPush
  of "pop": opPop
  of "add": opAdd
  of "sub": opSub
  of "mul", "mpy": opMul
  of "div": opDiv
  of "branch": opBranch
  of "bgt": opBGT
  of "bge": opBGE
  of "bez": opBEZ
  of "blt": opBLT
  of "ble": opBLE
  of "read": opRead
  of "print": opPrint
  else: opUnknown

proc toMode(s: string): ASMExecMode =
  case s:
  of "0": return aemZeroAddr
  of "1": return aemOneAddr
  of "2": return aemTwoAddr
  of "3": return aemThreeAddr
  else: assert false, "Unknown mode `" & s & "`."

proc parseToken(str: string): Token =
  try:
    let val = parseInt(str)
    return Token(kind: immToken, value: val)
  except:
    return Token(kind: regToken, name: str)

proc parseInstruction(instruction: string): seq[Token] =
  var current = ""
  var lastCurrent = ""
  var op: ASMOp = opUnknown
  var opFound = false
  
  result.setLen(1)
  for s in instruction:
    case s:
      of ' ':
        if not opFound and current != "":
          op = toOp(current)
          lastCurrent = current
          current = ""
          opFound = true
          result[^1] = Token(kind: cmdToken, op: op)
      of ',':
        assert current != "", "Empty operand found."
        result[^1].children.add(parseToken(current))
        current = ""
      of ':':
        result[0] = Token(kind: labToken, name: if current == "": lastCurrent else: current)
        result.setLen(2)
        current = ""
      of 'a'..'z', 'A'..'Z', '0'..'9':
        current.add(s)
      of '\n': discard
      else: discard

  if current != "": result[^1].children.add(parseToken(current))
  if result[^1].kind == noToken: discard result.pop()

  echo result

proc fetchSymbol(ctx: var CodeGenCtx, sym: string, def = 0): int =
  ctx.symbols.getOrDefault(sym, def)

proc tryFetchSymbol(ctx: CodeGenCtx, sym: string): int =
  assert sym in ctx.symbols, "Register `" & sym & "` doesn't exist."
  ctx.symbols[sym]

proc getTokenValue(ctx: CodeGenCtx, tok: Token): int =
  case tok.kind:
  of immToken:
    return tok.value
  of regToken:
    return ctx.tryFetchSymbol(tok.name)
  else:
    assert false, "Can't get value for a command."

proc doArithmeticOp(op: ASMOp, a, b: int): int =
  case op:
  of opAdd: return a + b
  of opSub: return a - b
  of opMul: return a * b
  of opDiv: return a div b
  else: assert(false, "Can't execute non arithmetic operation")

proc doBranchingOp(op: ASMOp, a: int): bool =
  case op:
  of opBGT: return a > 0
  of opBGE: return a >= 0
  of opBEZ: return a == 0
  of opBLT: return a < 0
  of opBLE: return a <= 0
  else: assert(false, "Can't execute comparison on non branching operation.")

proc execInstruction(ctx: var CodeGenCtx, token: Token) =
  if ctx.goToLabel != "":
    if token.kind == labToken and ctx.goToLabel == token.name:
      ctx.goToLabel = ""

    return

  if token.kind == labToken: return
  assert token.kind == cmdToken, "Error: Need an instruction to execute, not a token."
  case token.op:
  of opHalt: quit()

  of opLoad: 
    let reg = token.children[0]
    ctx.acc = ctx.getTokenValue(reg)

  of opStore:
    let reg = token.children[0]

    case reg.kind:
      of immToken:
        assert false, "Error: Can't store accumulator in an immediate value."
      of regToken:
        ctx.symbols[reg.name] = ctx.acc
      else: discard

  of opPush:
    let reg = token.children[0]
    ctx.stack.add(ctx.getTokenValue(reg))

  of opPop:
    let reg = token.children[0]

    case reg.kind:
      of immToken:
        assert false, "Error: Can't store stack top in an immediate value."
      of regToken:
        ctx.stack[^1] = ctx.tryFetchSymbol(reg.name)
      else: discard

  of opAdd, opSub, opMul, opDiv:
    case ctx.mode:
    
    of aemZeroAddr:
      let b = ctx.stack.pop()
      ctx.stack[^1] = doArithmeticOp(token.op, ctx.stack[^1], b)
      ctx.lastRes = ctx.stack[^1] 
    
    of aemOneAddr:
      assert token.children.len >= 1, "Error: 1 address ASM need this command to have 1 operands."
      let reg = token.children[0]
      ctx.acc = doArithmeticOp(token.op, ctx.acc, ctx.getTokenValue(reg))
      ctx.lastRes = ctx.acc
    
    of aemTwoAddr:
      assert token.children.len >= 2, "Error: 2 address ASM need this command to have 2 operands."
      let a = token.children[0]
      let b = token.children[1]

      assert a.kind == regToken, "Destination register can't be an immediate value."
      ctx.symbols[a.name] = doArithmeticOp(token.op, ctx.symbols[a.name], ctx.getTokenValue(b))
      ctx.lastRes = ctx.symbols[a.name]

    of aemThreeAddr:
      assert token.children.len >= 3, "Error: 3 address ASM need this command to have 3 operands."
      let a = token.children[0]
      let b = token.children[1]
      let c = token.children[2]

      assert a.kind == regToken, "Destination register can't be an immediate value."
      ctx.symbols[a.name] = doArithmeticOp(token.op, ctx.getTokenValue(b), ctx.getTokenValue(c))
      ctx.lastRes = ctx.symbols[a.name]
  
  of opBranch:
    let dst = token.children[0]
    ctx.goToLabel = dst.name

  of opBGT, opBGE, opBEZ, opBLT, opBLE:
    let dst = token.children[0]
    if doBranchingOp(token.op, ctx.lastRes):
      ctx.goToLabel = dst.name

  of opRead:
    assert token.children.len >= 1, "Error: READ instruction need a destination register."
    let reg = token.children[0]

    assert reg.kind == regToken, "Destination register can't be an immediate value."
    ctx.symbols[reg.name] = parseInt(readLine(stdin))

  of opPrint:
    assert token.children.len >= 1, "Error: PRINT instruction need an operand."
    
    let reg = token.children[0]
    echo ctx.getTokenValue(reg)
  else: 
    assert false, "Unknown operation."


proc runASM(ctx: var CodeGenCtx, instructions: seq[string]) =
  ctx.pc = 0
  while ctx.pc < instructions.len:
    let tokens = parseInstruction(instructions[ctx.pc])
    for token in tokens:
      ctx.execInstruction(token)

    inc ctx.pc

proc executeFile(filename: string, mode: ASMExecMode) =
  let code = readFile(filename)
  var ctx = CodeGenCtx(mode: mode)
  var instructions = code.split("\n")

  runASM(ctx, instructions)

proc runPrompt() =
  var p = initOptParser()
  var args: seq[string] = @[]
  var mode = aemTwoAddr

  while true:
    p.next()

    case p.kind:
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      case p.key:
        of "m", "mode":
          mode = toMode(p.val)
        else: discard
    of cmdArgument:
      args.add(p.key)

  
  if args.len < 1:
    writeHelp()

  let cmd = args[0].toLower
  if cmd != "r": 
    echo "Unknown command."
    echo USAGE
    quit(1)

  if args.len < 2:
    echo "Command `r` need a file to process."
    quit(1)

  let file = args[1]
  executeFile(file, mode)


when isMainModule:
  runPrompt()

