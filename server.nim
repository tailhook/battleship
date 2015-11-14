import sockets
import websockets
import jester
import asyncio

type Game = object of RootObj
    first*: WebSocket
    second*: WebSocket

var queued: WebSocket = nil
var games: ref Table[int, Game];
new(games)
var game_num: int = 0


proc onConnected(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "------ connected ------"
    if queued.isNil:
        queued = client
        ws.send(client, "Okay, queued")
    else:
        games.add(game_num, Game(first: queued, second: client))
        game_num += 1
        ws.send(queued, "Okay, game")
        ws.send(client, "Okay, game")
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
                ws.send(game.second, "Oh, crap")
            elif game.second == client:
                ws.send(game.first, "Oh, crap")
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
