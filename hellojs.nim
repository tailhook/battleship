import htmlgen, dom, strutils
import lib

proc consolelog(a: cstring) {.importc.}

proc log(s: string) =
    consolelog(cstring(s))

proc logint(i:int) =
    log(intToStr(i))

log("Hello")

const ship = "&#128674;"
const empty = "&nbsp;"


var playerField: Matrix[10, 10] = [
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
]

var enemyField: Matrix[10, 10] = [
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
]

var waiting_enemy_turn = false

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

proc drawExample() =
    exampleShip("ship4", 1, 4)
    exampleShip("ship3", 2, 3)
    exampleShip("ship2", 3, 2)
    exampleShip("ship1", 4, 1)

proc clearExample() =
    let el = window.document.getElementById("rules")
    el.innerHTML = ""

proc bindSetupFieldClick(field: var Matrix, i,j: int, setupFinished: proc()): proc(event: ref TEvent)=
    result = proc (event: ref TEvent)=
        if field[i][j] == cEmpty:
            field[i][j] = cShip
            if not validateField(field):
                field[i][j] = cEmpty
                return
            event.target.innerHTML = ship
        else:
            field[i][j] = cEmpty
            if not validateField(field):
                field[i][j] = cShip
                return
            event.target.innerHTML = empty
        if isFilled(field):
            log("FILLED")
            setupFinished()

proc bindEnemyFieldClick(field: var Matrix, i,j: int): proc(event: ref TEvent)=
    result = proc (event: ref TEvent)=
        if waiting_enemy_turn:
            return
        if field[i][j] == cDead:
            return
        log("Attack at [" & intToStr(i) & ", " & intToStr(j) & "]")


proc drawSetupGrid(elementid: cstring, field: var Matrix, setupFinished: proc()) =
    let el = window.document.getElementById(elementid)
    el.innerHTML = ""
    for i in 1..10:
        var row = document.createElement("div")
        el.appendChild(row)

        for j in 1..10:
            let f = bindSetupFieldClick(field, i, j, setupFinished);
            var cell = document.createElement("span")
            cell.innerHTML = empty
            cell.classList.add("cell")
            {.emit:"`cell`.onclick=`f`; "}
            el.appendChild(cell)

proc drawPlayerGrid(elementid: cstring, field: var Matrix) =
    let el = window.document.getElementById(elementid)
    el.innerHTML = ""
    for i in 1..10:
        var row = document.createElement("div")
        el.appendChild(row)
        for j in 1..10:
            var cell = document.createElement("span")
            if field[i][j] == cShip:
                cell.innerHTML = ship
            else:
                cell.innerHTML = empty
            cell.classList.add("cell")
            el.appendChild(cell)

proc drawEnemyGrid(elementid: cstring, field: var Matrix) =
    let el = window.document.getElementById(elementid)
    for i in 1..10:
        var row = document.createElement("div")
        el.appendChild(row)

        for j in 1..10:
            let f = bindEnemyFieldClick(field, i, j);
            var cell = document.createElement("span")
            if field[i][j] == cShip:
                cell.innerHTML = ship
            else:
                cell.innerHTML = empty
            cell.classList.add("cell")
            {.emit:"`cell`.onclick=`f`; "}
            el.appendChild(cell)

proc setup(setupFinished: proc()) =
    drawSetupGrid("player", playerField, setupFinished)
    drawExample()

proc play() =
    clearExample()
    drawPlayerGrid("player", playerField)
    drawEnemyGrid("enemy", enemyField)

setup(play)

type
  WebSocket* {.importc.} = object of RootObj
    onopen*: proc (event: ref TEvent) {.nimcall.}
    onmessage*: proc (event: ref MessageEvent) {.nimcall.}
    send: proc(val: cstring)
  MessageEvent {.importc.} = object of RootObj
    data*: cstring

proc newWebsocket(): WebSocket {.importc:""" function() {
    return new WebSocket('ws://localhost:8080', ['battleship'])
    }"""}

var ws: WebSocket = newWebsocket()
ws.onopen = proc(ev: ref TEvent) =
    log("connected")
ws.onmessage = proc(ev: ref MessageEvent) =
    log("Message", ev.data)
