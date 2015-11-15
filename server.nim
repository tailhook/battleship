import enemynames
import sockets
import websockets
import jester
import asyncio
import json
import lib
import unicode

type State = enum
    Commencing, Playing, Done

type Party = enum
    First, Second

type VoidParty = enum
    pNobody, pFirst, pSecond

type Game = ref object of RootObj
    socks*: array[First..Second, WebSocket]
    fields*: array[First..Second, Matrix]
    filled_fields*: array[First..Second, bool]
    state*: State
    won*: VoidParty
    turn*: VoidParty

var queued: WebSocket = nil
var games: Table[int, Game] = initTable[int, Game]()
var game_num: int = 1

proc `not` (p: Party): Party =
    case p
    of First: return Second
    of Second: return First

proc `toVoid` (p: Party): VoidParty =
    case p
    of First: return pFirst
    of Second: return pSecond

proc onConnected(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "------ connected ------"
    if queued.isNil:
        queued = client
        ws.send(client, pretty(%*["queued"]))
    else:
        games.add(game_num, Game(
            socks: [queued, client],
            fields: [newField(), newField()],
            filled_fields: [false, false],
            state: Commencing,
            won: pNobody,
            turn: pNobody,
            ))
        game_num += 1
        var amer = randomAmericanName().toRunes
        var japa = randomJapaneseName().toRunes
        amer[0] = amer[0].toUpper
        japa[0] = japa[0].toUpper
        ws.send(queued, pretty(%*["commenced", $ amer, $ japa]))
        ws.send(client, pretty(%*["commenced", $ japa, $ amer]))
        queued = nil

proc findGame(client: WebSocket): (int, Party) =
    for id, game in pairs(games):
        for p, c in pairs(game.socks):
            if c == client:
                return (id, p)
    return (0, First)

proc onMessage(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "message: ", message.data
    let data = parseJson(message.data)
    case data[0].getStr()
    of "field":
        let fld = matrixFromJson(data[1])
        if not isFilled(fld) or not validateField(fld):
            echo "bad field: ", message.data
            ws.send(client, pretty(%*["fuck_off"]))
        else:
            let (id, party) = findGame(client)
            if id == 0:
                ws.send(client, $ %*["no_game_for_you"])
                return
            var game = games[id]
            if game.state != Commencing:
                ws.send(client, $ %*["too_late"])
                return
            game.fields[party] = fld
            game.filled_fields[party] = true
            ws.send(client, $ %*["nice_field"])
            if game.filled_fields[not party] == true:
                game.state = Playing
                # the faster party start the game
                game.turn = (not party).toVoid
                ws.send(game.socks[not party], $ %*["start", "you"])
                ws.send(game.socks[party], $ %*["start", "enemy"])
    of "shoot":
        let x = data[1].getNum()
        let y = data[2].getNum()
        let (id, party) = findGame(client)
        if id == 0:
            ws.send(client, $ %*["no_game_for_you"])
            return
        var game = games[id]
        if game.turn != party.toVoid:
            ws.send(client, $ %*["too_early_or_too_late"])
            return
        var oppo = game.socks[not party]
        var cell = game.fields[not party][x][y]
        case cell
        of cEmpty:
            ws.send(client, $ %*["outgoing", "miss", x, y])
            ws.send(oppo, $ %*["incoming", "miss", x, y])
            game.turn = (not party).toVoid
            game.fields[not party][x][y] = cMiss
            return
        of cShip:
            ws.send(client, $ %*["outgoing", "hit", x, y])
            ws.send(oppo, $ %*["incoming", "hit", x, y])
            game.fields[not party][x][y] = cDead
            # check for win
            return
        of cMiss, cDead:
            ws.send(client, $ %*["already_shooted"])
            return
    else:
        echo "Got garbage: ", data

proc onDisconnected(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "client left, remaining: ", ws.clients.len
    if queued == client:
        echo "removing queued"
        queued = nil
    else:
        echo "checking games"
        let (id, party) = findGame(client)
        if id != 0:
            let game = games[id]
            ws.send(game.socks[not party], pretty(%*["peer_disconnected"]))
            del games, id

echo "Running websocket test"

#Choose which type of websocket to test

var ws            = open("", Port(5001), isAsync=true)
ws.onConnected    = onConnected
ws.onMessage      = onMessage
ws.onDisconnected = onDisconnected

let dispatch = newDispatcher()
dispatch.register(ws)

while true:
    try:
        discard dispatch.poll()
    except KeyError:
        echo "KeyError: ", getCurrentExceptionMsg()
