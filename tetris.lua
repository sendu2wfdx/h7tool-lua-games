--GUIMODE=1
-- ============================================================================
--  俄罗斯方块
--
--  按键（这台工具只有 4 个键，所以这样分配）：
--      ▲ 单击 = 左移      长按/连发 = 连续左移
--      ▼ 单击 = 右移      长按/连发 = 连续右移
--      OK 单击 = 旋转
--      C  单击 = 下落一格  长按 = 直接落底   双击 = 退出
--
--  固件按键模型：每个键产生 6 个事件码，顺序固定
--      1=按下 2=单击 3=长按 4=长按弹起 5=连发 6=双击
--  第 N 键的事件码 = (N-1)*6 + 事件号。本程序按"事件"分发，不按"键"分发。
--
--  屏幕：整屏重绘（实测局部重绘会把屏幕画花）。800 个矩形 21ms + 刷新 26ms，
--  所以每帧约 30ms，足够流畅。
--
--  自测：把全局 H7_TETRIS_TEST 设为 true 再 dofile 本文件，会跑逻辑自测并退出，
--  不进入游戏循环（这样旋转/碰撞/消行都能在设备上验证）。
-- ============================================================================

local COLS, ROWS = 10, 20

local PIECES = {
    { n = "I", m = { { 0, 0, 0, 0 }, { 1, 1, 1, 1 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } } },
    { n = "O", m = { { 1, 1 }, { 1, 1 } } },
    { n = "T", m = { { 0, 1, 0 }, { 1, 1, 1 }, { 0, 0, 0 } } },
    { n = "S", m = { { 0, 1, 1 }, { 1, 1, 0 }, { 0, 0, 0 } } },
    { n = "Z", m = { { 1, 1, 0 }, { 0, 1, 1 }, { 0, 0, 0 } } },
    { n = "J", m = { { 1, 0, 0 }, { 1, 1, 1 }, { 0, 0, 0 } } },
    { n = "L", m = { { 0, 0, 1 }, { 1, 1, 1 }, { 0, 0, 0 } } },
}

-- ---------------------------------------------------------------- 纯逻辑
local function newBoard()
    local b = {}
    for y = 1, ROWS do
        b[y] = {}
        for x = 1, COLS do b[y][x] = 0 end
    end
    return b
end

local function rotate(m)
    local n = #m
    local r = {}
    for y = 1, n do
        r[y] = {}
        for x = 1, n do r[y][x] = m[n - x + 1][y] end
    end
    return r
end

local function fits(board, m, px, py)
    for y = 1, #m do
        for x = 1, #m[y] do
            if m[y][x] == 1 then
                local bx, by = px + x - 1, py + y - 1
                if bx < 1 or bx > COLS or by > ROWS then return false end
                if by >= 1 and board[by][bx] == 1 then return false end
            end
        end
    end
    return true
end

local function merge(board, m, px, py)
    for y = 1, #m do
        for x = 1, #m[y] do
            if m[y][x] == 1 then
                local bx, by = px + x - 1, py + y - 1
                if by >= 1 and by <= ROWS and bx >= 1 and bx <= COLS then
                    board[by][bx] = 1
                end
            end
        end
    end
end

local function clearLines(board)
    local cleared = 0
    local y = ROWS
    while y >= 1 do
        local full = true
        for x = 1, COLS do
            if board[y][x] == 0 then full = false break end
        end
        if full then
            cleared = cleared + 1
            for yy = y, 2, -1 do
                for x = 1, COLS do board[yy][x] = board[yy - 1][x] end
            end
            for x = 1, COLS do board[1][x] = 0 end
        else
            y = y - 1
        end
    end
    return cleared
end

local function spawnIndex(seedValue)
    return (seedValue % #PIECES) + 1
end

-- ---------------------------------------------------------------- 自测
if _G.H7_TETRIS_TEST then
    -- ASCII check names: the console codepage mangles Chinese, and we need to read this
    local pass, fail = 0, 0
    local function check(name, cond)
        if cond then
            pass = pass + 1
        else
            fail = fail + 1
            print("H7T FAIL " .. name)
        end
    end

    local function same(a, b)
        for y = 1, #a do
            for x = 1, #a[y] do
                if a[y][x] ~= b[y][x] then return false end
            end
        end
        return true
    end

    local b = newBoard()
    check("empty-fit", fits(b, PIECES[3].m, 4, 1))

    local m = PIECES[3].m
    local r1 = rotate(m)
    local r2 = rotate(r1)
    local r3 = rotate(r2)
    local r4 = rotate(r3)
    check("rot4-identity", same(r4, m))
    check("rot1-changed", not same(r1, m))
    check("rot2-changed", not same(r2, m))
    check("rot1-shape", r1[1][2] == 1 and r1[2][2] == 1 and r1[2][3] == 1 and r1[3][2] == 1)

    check("wall-left", not fits(b, PIECES[2].m, -1, 1))
    check("wall-right", not fits(b, PIECES[2].m, COLS, 1))
    check("wall-bottom", not fits(b, PIECES[2].m, 1, ROWS))

    local b2 = newBoard()
    for x = 1, COLS do b2[ROWS][x] = 1 end
    check("stack-block", not fits(b2, PIECES[2].m, 1, ROWS - 1))
    check("stack-above-ok", fits(b2, PIECES[2].m, 1, ROWS - 3))

    local b3 = newBoard()
    for x = 1, COLS do b3[ROWS][x] = 1 end
    b3[ROWS][5] = 0
    check("no-clear-when-gap", clearLines(b3) == 0)
    b3[ROWS][5] = 1
    check("clear-one-line", clearLines(b3) == 1)
    local emptied = true
    for x = 1, COLS do
        if b3[ROWS][x] == 1 then emptied = false end
    end
    check("cleared-empty", emptied)

    local b4 = newBoard()
    for x = 1, COLS do b4[ROWS][x] = 1 end
    b4[ROWS - 1][1] = 1
    clearLines(b4)
    check("gravity-after-clear", b4[ROWS][1] == 1 and b4[ROWS - 1][1] == 0)

    local b5 = newBoard()
    merge(b5, PIECES[3].m, 1, 1)
    check("merge-writes", b5[1][2] == 1 and b5[2][1] == 1 and b5[2][2] == 1 and b5[2][3] == 1)

    check("piece-count-7", #PIECES == 7)
    check("spawn-wraps", spawnIndex(7) == 1 and spawnIndex(0) == 1)

    print(string.format("H7T RESULT pass=%d fail=%d", pass, fail))
    print("H7T DONE")
    return
end

-- ---------------------------------------------------------------- 界面
local C = {
    white = RGB565(255, 255, 255), black = RGB565(0, 0, 0),
    navy = RGB565(16, 42, 78), gray = RGB565(30, 34, 40),
    light = RGB565(200, 208, 216), dark = RGB565(96, 106, 116),
    yellow = RGB565(250, 196, 40), cyan = RGB565(60, 200, 220),
    purple = RGB565(170, 90, 200), green = RGB565(60, 190, 90),
    red = RGB565(220, 70, 70), orange = RGB565(240, 140, 40),
    blue = RGB565(70, 120, 230), pale = RGB565(216, 238, 248),
}

-- 20 行 x 13px = 260，从 y=28 画到 288：让开顶部标题条(0..24)与底部提示条(306..)
local CELL = 13
local BOARD_X, BOARD_Y = 4, 28
local COLORS = { C.cyan, C.yellow, C.purple, C.green, C.red, C.blue, C.orange }

local board = newBoard()
local cur, curM, curX, curY, curColor = 1, PIECES[1].m, 4, 1, 1
local nextPiece = 1
local score, lines, level = 0, 0, 1
local dropCounter, dropEvery = 0, 26
local gameOver = false
local seed = 12345

local function rnd()
    seed = (seed * 1103515245 + 12345) % 2147483648
    return math.floor(seed / 65536)
end

local function newPiece()
    cur = nextPiece
    curM = PIECES[cur].m
    curX, curY = 4, 1
    curColor = (cur - 1) % #COLORS + 1
    nextPiece = spawnIndex(rnd())
    if not fits(board, curM, curX, curY) then gameOver = true end
end

local function drawCell(x, y, color)
    lcd_fill_rect(BOARD_X + (x - 1) * CELL, BOARD_Y + (y - 1) * CELL, CELL - 1, CELL - 1, color)
end

local function draw()
    lcd_clr(C.gray)

    lcd_fill_rect(0, 0, 14, 240, C.navy)
    lcd_disp_str(4, 1, "俄罗斯方块", 12, C.white, C.navy, 232, 0)

    -- 边框用四条细线：整块 h=262 超过 255，可能被截断导致露底色
    do
        local bw = COLS * CELL
        local bh = ROWS * CELL
        lcd_fill_rect(BOARD_X - 2, BOARD_Y - 2, 2, bw + 4, C.black)
        lcd_fill_rect(BOARD_X - 2, BOARD_Y + bh, 2, bw + 4, C.black)
        lcd_fill_rect(BOARD_X - 2, BOARD_Y - 2, bh + 4, 2, C.black)
        lcd_fill_rect(BOARD_X + bw, BOARD_Y - 2, bh + 4, 2, C.black)
    end

    for y = 1, ROWS do
        for x = 1, COLS do
            -- 先整格铺黑：方块之间的 1px 缝就变成"黑线"（方格感），而不是露底色
            local cx = BOARD_X + (x - 1) * CELL
            local cy = BOARD_Y + (y - 1) * CELL
            lcd_fill_rect(cx, cy, CELL, CELL, C.black)
            if board[y][x] == 1 then
                lcd_fill_rect(cx, cy, CELL - 1, CELL - 1, C.light)
            end
        end
    end

    if not gameOver then
        for y = 1, #curM do
            for x = 1, #curM[y] do
                if curM[y][x] == 1 then
                    local bx, by = curX + x - 1, curY + y - 1
                    if by >= 1 then drawCell(bx, by, COLORS[curColor]) end
                end
            end
        end
    end

    local sx = BOARD_X + COLS * CELL + 8
    lcd_fill_rect(sx - 4, BOARD_Y - 1, 78, 70, C.navy)
    lcd_disp_str(sx, BOARD_Y + 2, "下一个", 12, C.yellow, C.navy, 66, 0)
    local nm = PIECES[nextPiece].m
    for y = 1, #nm do
        for x = 1, #nm[y] do
            if nm[y][x] == 1 then
                lcd_fill_rect(sx - 2 + (x - 1) * 12, BOARD_Y + 18 + (y - 1) * 12, 11, 11,
                              COLORS[(nextPiece - 1) % #COLORS + 1])
            end
        end
    end

    lcd_disp_str(sx, BOARD_Y + 80, "得分", 12, C.pale, C.gray, 70, 0)
    lcd_disp_str(sx, BOARD_Y + 96, tostring(score), 16, C.white, C.gray, 70, 0)
    lcd_disp_str(sx, BOARD_Y + 130, "行数", 12, C.pale, C.gray, 70, 0)
    lcd_disp_str(sx, BOARD_Y + 146, tostring(lines), 16, C.white, C.gray, 70, 0)
    lcd_disp_str(sx, BOARD_Y + 180, "等级", 12, C.pale, C.gray, 70, 0)
    lcd_disp_str(sx, BOARD_Y + 196, tostring(level), 16, C.white, C.gray, 70, 0)

    if gameOver then
        -- 深蓝面板 + 黄色上下描边，文字居中，比原来的红色横条干净
        lcd_fill_rect(16, 96, 124, 208, C.navy)
        lcd_fill_rect(16, 96, 3, 208, C.yellow)
        lcd_fill_rect(16, 217, 3, 208, C.yellow)
        lcd_disp_str(16, 112, "游戏结束", 24, C.yellow, C.navy, 208, 1)
        lcd_disp_str(16, 148, "得分 " .. score, 16, C.white, C.navy, 208, 1)
        lcd_disp_str(16, 172, "行数 " .. lines, 12, C.light, C.navy, 208, 1)
        -- 最后一行与下边框之间留一行空白
        lcd_disp_str(16, 192, "OK 重来      长按C退出", 12, C.pale, C.navy, 208, 1)
    end

    lcd_fill_rect(3, 288, 32, 132, C.navy)          -- 与棋盘左右对齐(x=3,w=132)，并让开棋盘框
    lcd_disp_str(3, 297, "长按C退出", 12, C.pale, C.navy, 132, 1)

    -- 四个按键的图形：按工具实际布局 2x2（左上 上、右上 OK、左下 下、右下 C）
    do
        local bx, by, bw, bh = 142, 246, 46, 30
        -- 上下键的三角形用图形画（设备字库没有 ▼ 这个字符）
        local function tri_up(x, y, w, color)
            local rows = math.floor(w / 2)
            for i = 0, rows - 1 do
                local half = i
                lcd_fill_rect(x + (rows - 1 - half), y + i, 1, half * 2 + 1, color)
            end
        end
        local function tri_down(x, y, w, color)
            local rows = math.floor(w / 2)
            for i = 0, rows - 1 do
                local half = rows - 1 - i
                lcd_fill_rect(x + (rows - 1 - half), y + i, 1, half * 2 + 1, color)
            end
        end

        local caps = {
            { bx, by, "up", "左" },
            { bx + bw + 4, by, "OK", "右" },
            { bx, by + bh + 4, "down", "落" },
            { bx + bw + 4, by + bh + 4, "C", "转" },
        }
        for i = 1, #caps do
            local c = caps[i]
            -- 键帽：深蓝底（原先那两条"边框"h/w 写反了，画成了横线戳出键帽，已删除）
            lcd_fill_rect(c[1], c[2], bh, bw, C.navy)
            if c[3] == "up" then
                tri_up(c[1] + 5, c[2] + 12, 15, C.yellow)
            elseif c[3] == "down" then
                tri_down(c[1] + 5, c[2] + 12, 15, C.yellow)
            else
                lcd_disp_str(c[1], c[2] + 9, c[3], 12, C.yellow, C.navy, 22, 1)
            end
            lcd_disp_str(c[1] + 22, c[2] + 9, c[4], 12, C.white, C.navy, 22, 1)
        end
    end
end

-- 必须在 tick() 之前声明，否则 tick 读到的是 nil 全局变量
local softDrop = false

local function tick()
    if gameOver then return end
    dropCounter = dropCounter + 1
    local every = dropEvery
    if dropCounter >= every then
        dropCounter = 0
        if fits(board, curM, curX, curY + 1) then
            curY = curY + 1
        else
            merge(board, curM, curX, curY)
            local n = clearLines(board)
            if n > 0 then
                lines = lines + n
                score = score + n * n * 10
                level = 1 + math.floor(lines / 5)
                dropEvery = math.max(6, 26 - (level - 1) * 3)
            end
            newPiece()
        end
    end
end

local function move(dx)
    if not gameOver and fits(board, curM, curX + dx, curY) then curX = curX + dx end
end

local function doRotate()
    if gameOver then return end
    local r = rotate(curM)
    if fits(board, r, curX, curY) then curM = r
    elseif fits(board, r, curX - 1, curY) then curM = r curX = curX - 1
    elseif fits(board, r, curX + 1, curY) then curM = r curX = curX + 1 end
end

local function hardDrop()
    if gameOver then return end
    while fits(board, curM, curX, curY + 1) do curY = curY + 1 end
    merge(board, curM, curX, curY)
    local n = clearLines(board)
    if n > 0 then
        lines = lines + n
        score = score + n * n * 10
        level = 1 + math.floor(lines / 5)
        dropEvery = math.max(6, 26 - (level - 1) * 3)
    end
    newPiece()
    dropCounter = 0
end

local function reset()
    board = newBoard()
    score, lines, level = 0, 0, 1
    dropEvery = 26
    dropCounter = 0
    gameOver = false
    seed = 12345
    nextPiece = spawnIndex(rnd())
    newPiece()
end

-- 按键码直接绑定（这台工具的键号不连号，实测 OK=100 C=101，不能用键号推断）
-- 键码表（实测 V2.33）。左侧 上/下，右侧 OK/C
--   上 1按下 2单击 3长按 5连发 4长按弹起
--   下 8按下 9单击 10长按 12连发 11长按弹起
--   OK 15按下 100单击 17长按 19连发 18长按弹起   ← 实测"未连发"，所以重复由本程序自己计时
--   C  22按下 101单击 24长按 26连发 25长按弹起   ← 长按 C = 固件"用户中止"
local LEFT_ONCE = { [2] = true }          -- 上 单击：左移一格
local LEFT_HOLD_ON = { [3] = true }      -- 上 长按：开始连续左移
local LEFT_HOLD_OFF = { [4] = true }     -- 上 长按弹起：停止
local RIGHT_ONCE = { [100] = true }      -- OK 单击：右移一格
local RIGHT_HOLD_ON = { [17] = true }    -- OK 长按：开始连续右移（OK 无固件连发，靠本程序计时）
local RIGHT_HOLD_OFF = { [18] = true }   -- OK 长按弹起：停止
local DOWN_ONCE = { [9] = true }         -- 下 单击：秒落（直接到底）
local ROTATE_KEYS = { [101] = true }     -- C 单击：旋转
-- 下的长按(10)/连发(12)/长按弹起(11) 一律不绑定；长按 C(24) 由固件中止
local holdLeft, holdRight = false, false
local holdTicks = 0
local HOLD_PERIOD = 3

local function main()
    while get_key() > 0 do end
    reset()
    draw()
    lcd_refresh()

    while true do
        local k = get_key()
        while k ~= 0 do
            if gameOver then
                holdLeft, holdRight = false, false
                if ROTATE_KEYS[k] or RIGHT_ONCE[k] or DOWN_ONCE[k] or LEFT_ONCE[k] then reset() end
            elseif LEFT_ONCE[k] then
                move(-1)
            elseif LEFT_HOLD_ON[k] then
                holdLeft = true
            elseif LEFT_HOLD_OFF[k] then
                holdLeft = false
            elseif RIGHT_ONCE[k] then
                move(1)
            elseif RIGHT_HOLD_ON[k] then
                holdRight = true
            elseif RIGHT_HOLD_OFF[k] then
                holdRight = false
            elseif DOWN_ONCE[k] then
                hardDrop()                          -- 下 单击：秒落
            elseif ROTATE_KEYS[k] then
                doRotate()                          -- C 单击：旋转
            end
            -- 长按 C 退出由固件处理；下的长按不绑定
            k = get_key()
        end

        -- 长按加速：自己的计时器，每 HOLD_PERIOD 帧走一格
        holdTicks = holdTicks + 1
        if holdTicks >= HOLD_PERIOD then
            holdTicks = 0
            if holdLeft then move(-1) end
            if holdRight then move(1) end
        end

        tick()
        draw()
        lcd_refresh()
        delayms(5)
    end
end

main()
