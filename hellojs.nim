import htmlgen, dom

proc log(a: cstring) {.importc.}

log(cstring("Hello world"))

proc drawGrid(elementid: cstring) =
    let el = window.document.getElementById(elementid)
    for i in 'a'..'j':
        var row = document.createElement("div")
        el.appendChild(row)
        for j in 0..10:
            var cell = document.createElement("span")
            cell.innerHTML = "X"
            cell.classList.add("cell")
            el.appendChild(cell)

drawGrid("playerA")
drawGrid("playerB")
