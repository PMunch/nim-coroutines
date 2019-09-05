import tables, macros, hashes

type CoroutineId* = distinct int
proc `==`*(x, y: CoroutineId): bool {.borrow.}

var coroutineIds {.compileTime.} = initTable[string, CoroutineId]()

macro Coroutine*(x: untyped): untyped =
  nnkCall.newTree(
    newIdentNode("CoroutineId"),
    newLit(int(coroutineIds[$x]))
  )

macro coroutine*(call: untyped): untyped =
  if call[3].len > 0 and call[3][0].kind != nnkEmpty:
    error("Coroutines can't return anything", call[3][0])
  result = copyNimTree(call)
  result[3][0] = nnkIteratorTy.newTree(
    nnkFormalParams.newTree(
      newIdentNode("CoroutineId")
    ),
    newEmptyNode()
  )
  if call[6].kind == nnkEmpty:
    if coroutineIds.hasKey($call[0]):
      error("Coroutine already defined elsewhere", call[0])
    coroutineIds[$call[0]] = CoroutineId(hash($call[0]))
  else:
    if not coroutineIds.hasKey($call[0]):
      coroutineIds[$call[0]] = CoroutineId(hash($call[0]))
    echo call.treeRepr
    result[6] = newStmtList(
      nnkReturnStmt.newTree(
        nnkIteratorDef.newTree(
          newEmptyNode(), newEmptyNode(), newEmptyNode(),
          nnkFormalParams.newTree(
            newIdentNode("CoroutineId")
          ),
          newEmptyNode(), newEmptyNode(),
          result[6]
        )
      )
    )

var coroutines {.threadvar.}: Table[CoroutineId, iterator(): CoroutineId]

macro schedule*(call: untyped): untyped =
  if call.kind != nnkCall:
    error("schedule must be given a call", call)
  let callIdent = call[0]
  result = quote do:
    coroutines[Coroutine(`callIdent`)] = `call`

proc coroutineLoop*(start: CoroutineId) =
  var current = start
  while true:
    current = coroutines[current]()
