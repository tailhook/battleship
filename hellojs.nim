import lib, json
import htmlgen, dom, strutils, enemynames


proc consolelog(a: cstring) {.importc.}

proc log(s: string) =
    consolelog(cstring(s))

proc logint(i:int) =
    log(intToStr(i))

const ship = "&#x1F6A2;"
const empty = "&nbsp;"
const miss = "&#x2218;"
const hit = "&#x2620;"

type
  WebSocket* {.importc.} = object of RootObj
    onopen*: proc (event: ref TEvent) {.nimcall.}
    onmessage*: proc (event: ref MessageEvent) {.nimcall.}
    send: proc(val: cstring)
  MessageEvent {.importc.} = object of RootObj
    data*: cstring

proc newWebsocket(): WebSocket {.importc:""" function() {
    return new WebSocket('ws://' + location.hostname + ':5001', ['battleship'])
    }"""}

var ws: WebSocket = newWebsocket()
ws.onopen = proc(ev: ref TEvent) =
    log("connected")

proc shoot(x, y: int) =
    ws.send($ %*["shoot", x, y])


var playerField = newField()

var enemyField = newField()

var enemy_connected = false
var player_ready = false
var enemy_ready = false
var your_name = ""
var enemy_name = ""
var waiting_enemy_turn = true

proc setDisclaimer(message: string) =
    let el = window.document.getElementById("disclaimer")
    el.innerHTML = message

proc clearDisclaimer() =
    setDisclaimer("")

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

proc clear_enemy_turn()=
    let el = document.getElementById("turn")
    el.innerHTML = "(SHOOT)"
    waiting_enemy_turn = false

proc set_enemy_turn()=
    let el = document.getElementById("turn")
    el.innerHTML = "(WAIT)"
    waiting_enemy_turn = true

proc bindEnemyFieldClick(field: var Matrix, i,j: int): proc(event: ref TEvent)=
    result = proc (event: ref TEvent)=
        if waiting_enemy_turn:
            return
        if field[i][j] == cDead:
            return
        if field[i][j] == cMiss:
            return
        if field[i][j] == cShip:
            field[i][j] = cDead
        if field[i][j] == cEmpty:
            field[i][j] = cMiss
        set_enemy_turn()
        log("Attack at [" & intToStr(i) & ", " & intToStr(j) & "]")
        shoot(i, j)

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
            elif field[i][j] == cEmpty:
                cell.innerHTML = empty
            elif field[i][j] == cDead:
                cell.innerHTML = hit
            else:
                cell.innerHTML = miss
            cell.classList.add("cell")
            el.appendChild(cell)

proc drawEnemyGrid(elementid: cstring, field: var Matrix) =
    let el = window.document.getElementById(elementid)
    el.innerHTML = ""
    for i in 1..10:
        var row = document.createElement("div")
        el.appendChild(row)

        for j in 1..10:
            let f = bindEnemyFieldClick(field, i, j);
            var cell = document.createElement("span")
            cell.classList.add("cell")
            if field[i][j] == cShip:
                cell.innerHTML = ship
            elif field[i][j] == cEmpty:
                cell.innerHTML = empty
            elif field[i][j] == cDead:
                cell.innerHTML = hit
            else:
                cell.innerHTML = miss
            {.emit:"`cell`.onclick=`f`; "}
            el.appendChild(cell)

proc setup(setupFinished: proc()) =
    setDisclaimer("Waiting for enemy...")
    drawSetupGrid("player", playerField, setupFinished)
    drawExample()

proc play() =
    ws.send(matrixToJson(playerField))
    clearExample()
    drawPlayerGrid("player", playerField)
    if enemy_ready:
        drawEnemyGrid("enemy", playerField)
    else:
        setDisclaimer("Waiting for " & enemy_name & " to setup board...")

ws.onmessage = proc(ev: ref MessageEvent) =
    log("Message", ev.data)
    var parsed = parseJson($ev.data)
    var message_kind = parsed[0].getStr()
    if message_kind == "incoming":
        var incoming_kind = parsed[1].getStr()
        var x = parsed[2].getNum()
        var y = parsed[3].getNum()
        if incoming_kind == "hit":
            playerField[x][y] = cDead
        elif incoming_kind == "miss":
            playerField[x][y] = cMiss
            clear_enemy_turn()
        drawPlayerGrid("player", playerField)
    elif message_kind == "outgoing":
        var outgoing_kind = parsed[1].getStr()
        var x = parsed[2].getNum()
        var y = parsed[3].getNum()
        if outgoing_kind == "hit":
            enemyField[x][y] = cDead
            clear_enemy_turn()
        elif outgoing_kind == "miss":
            enemyField[x][y] = cMiss
        drawEnemyGrid("enemy", enemyField)
    elif message_kind == "commenced":
        your_name = parsed[1].getStr()
        enemy_name = parsed[2].getStr()
        let el = document.getElementById("names")
        el.innerHTML = your_name & " VS " & enemy_name
        enemy_connected = true
        setDisclaimer("Enemy " & enemy_name & " connected")
    elif message_kind == "start":
        if parsed[1].getStr() == "you":
            clear_enemy_turn()
        elif parsed[1].getStr() == "enemy":
            set_enemy_turn()
        clearDisclaimer()
        drawEnemyGrid("enemy", enemyField)
    elif message_kind == "win":
        set_enemy_turn()
        let el = document.getElementById("names")
        el.innerHTML = your_name & " WINS!"
    elif message_kind == "loose":
        set_enemy_turn()
        let el = document.getElementById("names")
        el.innerHTML = your_name & " LOOSES!"


setup(play)
