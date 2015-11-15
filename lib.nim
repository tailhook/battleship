type Cell* = enum
    cEmpty, cShip, cDead

type
  Matrix*[W, H: static[int]] =
    array[1..W, array[1..H, Cell]]

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
