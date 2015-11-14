import htmlgen, dom, strutils

proc consolelog(a: cstring) {.importc.}

proc log(s: string)=
    consolelog(cstring(s))
log("Hello")

const ship = "&#128674;"
const empty = "&nbsp;"

type
  Matrix[W, H: static[int]] =
    array[1..W, array[1..H, int]]

var fieldA: Matrix[10, 10] = [
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
]

var fieldB: Matrix[10, 10] = [
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0],
]

proc exampleShip(elemid:string, number: int, size: int) =
    let el = window.document.getElementById(elemid)
    for i in 1..size:
        var row = document.createElement("div")
        var cell = document.createElement("span")
        cell.innerHTML = ship;
        cell.classList.add("cell")
        row.appendChild(cell);
        el.appendChild(row);
    var row = document.createElement("div")
    var cell = document.createElement("span")
    cell.innerHTML = intToStr(number)
    cell.classList.add("cell")
    row.appendChild(cell);
    el.appendChild(row);

exampleShip("ship4", 1, 4)
exampleShip("ship3", 2, 3)
exampleShip("ship2", 3, 2)
exampleShip("ship1", 4, 1)

proc getHSize(field: Matrix, i,j: int): int =
    var result = 0

    for k in j..10:
        if field[i][k] == 1:
            result += 1
        else:
            break

    for k in countdown(j - 1, 1, 1):
        if field[i][k] == 1:
            result += 1
        else:
            break


proc getVSize(field: Matrix, i,j: int): int =
    var result = 0

    for k in i..10:
        if field[k][j] == 1:
            result += 1
        else:
            break

    for k in countdown(i - 1, 1, 1):
        if field[k][j] == 1:
            result += 1
        else:
            break

proc validateField(field: Matrix): bool =
    result = true
    var oneCells = 4
    var twoCells = 4
    var threeCells = 6
    var fourCells = 4
    for i in 1..10:
        for j in 1..10:
            if field[i][j] == 0:
                continue
            #check diagonals
            if i > 1 and j > 1 and field[i - 1][j - 1] != 0:
                result = false
                return
            if i < 10 and j < 10 and field[i + 1][j + 1] != 0:
                result = false
                return
            if i > 1 and j < 10 and field[i - 1][j + 1] != 0:
                result = false
                return
            if i < 10 and j > 1 and field[i + 1][j - 1] != 0:
                result = false
                return
            var size = max(getHSize(field, i, j), getVSize(field, i, j))



proc bindFieldClick(field: var Matrix, i,j: int): proc(event: ref TEvent)=
    result = proc (event: ref TEvent)=
        if field[i][j] == 0:
            field[i][j] = 1
            if not validateField(field):
                field[i][j] = 0
                return
            event.target.innerHTML = ship
        else:
            field[i][j] = 0
            event.target.innerHTML = empty


proc drawGrid(elementid: cstring, field: var Matrix) =
    let el = window.document.getElementById(elementid)
    for i in 1..10:
        var row = document.createElement("div")
        el.appendChild(row)

        for j in 1..10:
            let f = bindFieldClick(field, i, j);

            var cell = document.createElement("span")
            cell.innerHTML = empty
            cell.classList.add("cell")

            {.emit:"`cell`.onclick=`f`; "}

            # cell.onclick = f
            cell.data = cstring(intToStr(i) & "_" & intToStr(j))
            el.appendChild(cell)

drawGrid("playerA", fieldA)

type
  WebSocket* {.importc.} = object of RootObj
    onopen*: proc (event: ref TEvent) {.nimcall.}
    send: proc(val: cstring)

proc new_wsock(): WebSocket {.importc.}

{.emit:""" function new_wsock() {
    return new WebSocket('ws://localhost:8080', ['battleship'])
    } """.}

var ws: WebSocket
ws = new_wsock()
ws.onopen = proc(ev: ref TEvent) =
    echo "connected"
    ws.send("hello")
