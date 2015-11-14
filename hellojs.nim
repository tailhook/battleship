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
            var class: Classlist
            new(class)
            class.add("cell")
            cell.innerHTML = "X"
            cell.classList = class
            el.appendChild(cell)

drawGrid("playerA")
drawGrid("playerB")
