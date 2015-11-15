import json

type Cell* = enum
    cEmpty, cShip, cMiss, cDead

type
  Matrix* = array[1..10, array[1..10, Cell]]

proc newField*(): Matrix =
    var m: Matrix = [
        [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
        [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
        [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
        [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
        [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
        [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
        [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
        [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
        [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
        [cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty, cEmpty],
    ]
    result = m


proc matrixToJson*(field: Matrix): string=
    var container = newJArray()
    var jField = newJArray()
    for i in 1..10:
        var jRow = newJArray()
        for j in 1..10:
            jRow.add(newJInt(ord(field[i][j])))
        jField.add(jRow)
    container.add(newJString("field"))
    container.add(jField)
    result = $container

proc matrixFromJson*(raw_json: string): Matrix =
    var field = newField()
    var container = parseJson(raw_json)
    var jField = container[1]
    var i = 1
    var j = 1
    for jRow in jField:
        j = 1
        for jCell in jRow:
            field[i][j] = Cell(jCell.getNum())
            j += 1
        i += 1
    result = field


proc getHSize(field: Matrix, i,j: int): int =
    result = 0

    for k in j..10:
        if field[i][k] == cShip:
            result += 1
        else:
            break

    for k in countdown(j - 1, 1, 1):
        if field[i][k] == cShip:
            result += 1
        else:
            break


proc getVSize(field: Matrix, i,j: int): int =
    result = 0

    for k in i..10:
        if field[k][j] == cShip:
            result += 1
        else:
            break

    for k in countdown(i - 1, 1, 1):
        if field[k][j] == cShip:
            result += 1
        else:
            break

proc validateField*(field: Matrix): bool =
    result = false
    var oneCells = 4
    var twoCells = 6
    var threeCells = 6
    var fourCells = 4
    for i in 1..10:
        for j in 1..10:
            if field[i][j] == cEmpty:
                continue
            #check diagonals
            if i > 1 and j > 1 and field[i - 1][j - 1] != cEmpty:
                return
            if i < 10 and j < 10 and field[i + 1][j + 1] != cEmpty:
                return
            if i > 1 and j < 10 and field[i - 1][j + 1] != cEmpty:
                return
            if i < 10 and j > 1 and field[i + 1][j - 1] != cEmpty:
                return
            var size = max(getHSize(field, i, j), getVSize(field, i, j))
            if size > 4:
                return
            if size == 4:
                if fourCells == 0:
                    result = false
                    return
                fourCells -= 1
            if size == 3:
                if threeCells == 0:
                    return
                threeCells -= 1
            if size == 2:
                if twoCells == 0:
                    return
                twoCells -= 1
            if size == 1:
                if oneCells == 0:
                    return
                oneCells -= 1
    result = true

proc isFilled*(field: Matrix): bool =
    var sum = 0
    for i in 1..10:
        for j in 1..10:
            if field[i][j] == cShip:
                sum += 1
    result = sum == 20
