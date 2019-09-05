import random, "../src/coroutines"

const QUEUE_SIZE = 10

var q: seq[int]

proc consume() {.coroutine.}

proc produce(x: int) {.coroutine.} =
  while true:
    while q.len < QUEUE_SIZE:
      q.add rand(x)
    yield Coroutine(consume)

proc consume() {.coroutine.} =
  while true:
    while q.len != 0:
      echo q.pop()
    yield Coroutine(produce)

schedule(produce(1000))
schedule(consume())

coroutineLoop(start = Coroutine(produce))
