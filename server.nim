import sockets
import websockets
import jester
import asyncio

type Game = object of RootObj
    first*: WebSocket
    second*: WebSocket

var queued: WebSocket = nil
var games: seq[Game] = @[]


proc onConnected(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "------ connected ------"
    if queued.isNil:
        queued = client
        ws.send(client, "Okay, queued")
    else:
        games.add(Game(first: queued, second: client))
        queued = nil
        ws.send(client, "Okay, game")

proc onMessage(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "message: ", message.data

proc onDisconnected(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "client left, remaining: ", ws.clients.len
    if queued == client:
        echo "removing"
        queued = nil
    else:
        for game in games:
            if game.first == client:
                ws.send(game.second, "Oh, crap")
            elif game.second == client:
                ws.send(game.first, "Oh, crap")

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
