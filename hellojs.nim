import htmlgen, dom, strutils

proc log(a: cstring) {.importc.}

log(cstring("Ships"))

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

proc bindFieldClick(field: Matrix, i,j: int): proc(event: ref TEvent)=
    result = proc (event: ref TEvent)=
        if field[i][j] == 0:
            #check diagonals
            if i > 1 and j > 1 and field[i - 1][j - 1] != 0:
                return
            if i < 10 and j < 10 and field[i + 1][j + 1] != 0:
                return
            if i > 1 and j < 10 and field[i - 1][j + 1] != 0:
                return
            if i < 10 and j > 1 and field[i + 1][j - 1] != 0:
                return
            fieldA[i][j] = 1
            event.target.innerHTML = ship
        else:
            fieldA[i][j] = 0
            event.target.innerHTML = empty


proc drawGrid(elementid: cstring, field: Matrix) =
    let el = window.document.getElementById(elementid)
    for i in 1..10:
        var row = document.createElement("div")
        el.appendChild(row)

        for j in 1..10:
            let f = bindFieldClick(field, i, j);

            var cell = document.createElement("span")
            cell.innerHTML = empty
            cell.classList.add("cell")

            {.emit:"`cell`.onclick=`f`;"}

            # cell.onclick = f
            cell.data = cstring(intToStr(i) & "_" & intToStr(j))
            el.appendChild(cell)

drawGrid("playerA", fieldA)
