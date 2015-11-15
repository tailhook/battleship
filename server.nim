import sockets
import websockets
import jester
import asyncio
import json
import lib

type State = enum
    Commencing, Playing, Done

type Party = enum
    First, Second

type VoidParty = enum
    pNobody, pFirst, pSecond

type Game = object of RootObj
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
            filled_fields: [true, true],
            state: Commencing,
            won: pNobody,
            turn: pNobody,
            ))
        game_num += 1
        ws.send(queued, pretty(%*["commenced"]))
        ws.send(client, pretty(%*["commenced"]))
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
