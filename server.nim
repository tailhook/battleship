import sockets
import websockets
import jester
import asyncio

proc onConnected(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "------ connected ------"
    ws.send(client, "hello world!")

proc onMessage(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "message: ", message.data

proc onDisconnected(ws: WebSocketServer, client: WebSocket, message: WebSocketMessage) =
    echo "client left, remaining: ", ws.clients.len

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
