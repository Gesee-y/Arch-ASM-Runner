  # ######################################################################################################################################################### #
 # ################################################################### PARSER ASM ########################################################################## #
# ######################################################################################################################################################### #

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
    opBE = 13
    opBLT = 14
    opBLE = 15

    # IO
    opRead = 10
    opPrint = 11

    # Unknown
    opUnknown = 12

  ASMExecMode = enum
    aemZeroAddr
    aemOneAddr
    aemTwoAddr
    aemThreeAddr

  TokenKind = enum
    cmdToken
    regToken
    immToken

  Token = object
    case kind: TokenKind
    of cmdToken:
      op: ASMOp
    of regToken:
      name: string
    else:
      value: int
    
    children: seq[Token]

  SymbolTable = object
    syms: Table[string, int]

  CodeGenCtx = object
    mode: ASMExecMode
    symbols: SymbolTable
    pc: int
    acc: int
    stack: seq[int]

proc toOp(op: string): ASMOp =
  let rawOp = op.lowercase()
  case op:
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
  of "be": opBE
  of "bez": opBEZ
  of "blt": opBLT
  of "ble": opBLE
  of "read": opRead
  of "print": opPrint
  else: opUnknown

proc parseToken(str: string): Token =
  try:
    let val = parseInt(str)
    return Token(kind: immToken, value: val)
  except:
    return Token(kind: regToken, name: str)

proc parseInstruction(instruction: string): Token =
  var op: ASMOp = opUnknown
  let data = instruction.split(" ")
  op = toOp(data[0])

  assert op != opUnknown, "Invalid instruction: " & data[0] & " is not an operation."
  result = Token(kind: cmdToken, op: op)

  for d in data[1: ^1]:
    result.children.add(parseToken(d))

proc fetchSymbol(ctx: var CodeGenCtx, sym: string, def = 0): int =
  ctx.symbols.getOrDefault(sym, def)

proc tryFetchSymbol(ctx: CodeGenCtx, sym: string): int =
  assert sym in ctx.symbols, "Register `" & sym & "` doesn't exist."
  ctx.symbols[sym]

proc getTokenValue(ctx: CodeGenCtx, tok: Token): int =
  case tok:
  of immToken:
    return reg.value
  of regToken:
    return ctx.tryFetchSymbol(reg.name)
  else:
    assert false, "Can't get value for a command."

proc doArithmeticOp(op: ASMOp, a, b: int):
  case op:
  of opAdd: return a + b
  of opSub: return a - b
  of opMul: return a * b
  of opDiv: return a div b
  else: error("Can't execute non arithmetic operation")

proc execInstruction(ctx: var CodeGenCtx, token: Token) =
  assert token.kind == cmdToken, "Error: Need an instruction to execute, not a token."
  case token.op:
  of opHalt: quit()

  of opLoad: 
    let reg = token.children[0]
    ctx.acc = ctx.getTokenValue(reg)

  of opStore:
    let reg = token.children[0]

    case reg:
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

    case reg:
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
    
    of aemOneAddr:
      assert token.children.len >= 1, "Error: 1 address ASM need this command to have 1 operands."
      let reg = token.children[0]
      ctx.acc = doArithmeticOp(token.op, ctx.acc, ctx.getTokenValue(reg))
    
    of aemTwoAddr:
      assert token.children.len >= 2, "Error: 2 address ASM need this command to have 2 operands."
      let a = token.children[0]
      let b = token.children[1]

      assert a.kind == regToken, "Destination register can't be an immediate value."
      ctx.symbols[a.name] = doArithmeticOp(token.op, ctx.symbols[a.name], ctx.getTokenValue(b)()

    of aemThreeAddr:
      assert token.children.len >= 3, "Error: 3 address ASM need this command to have 3 operands."
      let a = token.children[0]
      let b = token.children[1]
      let c = token.children[2]

      assert a.kind == regToken, "Destination register can't be an immediate value."
      ctx.symbols[a.name] = doArithmeticOp(token.op, ctx.getTokenValue(b), ctx.getTokenValue(c))

  of opRead:
    assert token.children.len >= 1, "Error: READ instruction need a destination register."
    let reg = token.children[0]

    assert reg.kind == regToken, "Destination register can't be an immediate value."
    ctx.symbols[reg.name] = parseInt(readLine())

  of opPrint:
    assert token.children.len >= 1, "Error: PRINT instruction need an operand."
    
    let reg = token.children[0]
    echo ctx.getTokenValue(reg)


proc runASM(ctx: var CodeGenCtx, instructions: seq[string]) =
  ctx.pc = 0
  while ctx.pc < instructions.len:
    let tokens = parseInstruction(instructions[ctx.pc])
    ctx.execInstruction(tokens)

