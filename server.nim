import sockets
import websockets
import jester
import asyncio
import json

type Game = object of RootObj
    first*: WebSocket
    second*: WebSocket

var queued: WebSocket = nil
var games: Table[int, Game] = initTable[int, Game]()
var game_num: int = 1


proc onConnected(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "------ connected ------"
    if queued.isNil:
        queued = client
        ws.send(client, pretty(%*["queued"]))
    else:
        games.add(game_num, Game(first: queued, second: client))
        game_num += 1
        ws.send(queued, pretty(%*["commenced"]))
        ws.send(client, pretty(%*["commenced"]))
        queued = nil

proc onMessage(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "message: ", message.data

proc onDisconnected(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "client left, remaining: ", ws.clients.len
    if queued == client:
        echo "removing queued"
        queued = nil
    else:
        echo "checking games"
        for id, game in pairs(games):
            if game.first == client:
                ws.send(game.second, pretty(%*["peer_disconnected"]))
            elif game.second == client:
                ws.send(game.first, pretty(%*["peer_disconnected"]))
            del games, id

echo "Running websocket test"

#Choose which type of websocket to test

var ws            = open("", Port(8080), isAsync=true)
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
