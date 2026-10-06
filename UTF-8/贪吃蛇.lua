--GUIMODE=1
-- 贪吃蛇 for H7-TOOL（240x320）
--   上 = 左转 90°      OK = 右转 90°     ← 只需两个方向键，永远不可能反向
--   下 = 切换加速                        C 单击 = 切换穿墙
--   电源键 = 暂停/继续
--   长按 C = 退出（固件行为，本程序不处理）
-- 键码为实测值（APP V2.33）：
--   上 1按下 2单击 3长按 5连发 4长按弹起
--   下 8按下 9单击 10长按 12连发 11长按弹起
--   OK 15按下 100单击 17长按 19连发 18长按弹起
--   C  22按下 101单击 24长按 26连发 25长按弹起
-- 注意：lcd_fill_rect 的参数顺序是 (x, y, h, w, color) —— 高度在前

local C = {
    black = RGB565(0, 0, 0),
    navy = RGB565(16, 40, 72),
    gray = RGB565(30, 34, 40),
    pale = RGB565(216, 238, 248),
    light = RGB565(200, 208, 216),
    white = RGB565(255, 255, 255),
    yellow = RGB565(255, 200, 40),
    green = RGB565(70, 200, 90),
    head = RGB565(150, 240, 140),
    red = RGB565(230, 70, 60),
}

local COLS, ROWS = 18, 18
local CELL = 13
local FX, FY = 3, 28

-- 撞墙行为开关：
--   WRAP = false（默认）→ 撞墙即死
--   WRAP = true         → 穿墙（从对面出来）
local WRAP = false

local DIRS = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }   -- 1上 2右 3下 4左

--=====================================================================
-- 纯逻辑（与绘图分离，便于自测）
--=====================================================================

local function rnd(s)
    s.seed = (s.seed * 1103515245 + 12345) % 2147483648
    return s.seed
end

local function occupied(s, x, y)
    for i = 1, #s.body do
        if s.body[i].x == x and s.body[i].y == y then return true end
    end
    return false
end

local function spawnFood(s)
    local pick = {}
    for y = 1, ROWS do
        for x = 1, COLS do
            if not occupied(s, x, y) then pick[#pick + 1] = { x = x, y = y } end
        end
    end
    if #pick == 0 then s.win = true s.food = nil return false end
    s.food = pick[(rnd(s) % #pick) + 1]
    return true
end

local function newState()
    local s = {
        body = { { x = 8, y = 9 }, { x = 7, y = 9 }, { x = 6, y = 9 } },
        dir = 2, pending = {}, food = nil, score = 0,
        alive = true, win = false, paused = false, boost = false,
        steps = 0, seed = 20250101,
    }
    spawnFood(s)
    return s
end

-- 相对转向：delta = -1 左转，+1 右转。相对转永远不可能是 180° 掉头
local function turn(s, delta)
    if #s.pending >= 2 then return false end
    local last = s.dir
    if #s.pending > 0 then last = s.pending[#s.pending] end
    local nd = ((last - 1 + delta) % 4) + 1
    if nd == last then return false end
    s.pending[#s.pending + 1] = nd
    return true
end

local function step(s)
    if not s.alive or s.paused then return end
    if #s.pending > 0 then
        s.dir = table.remove(s.pending, 1)
    end
    local h = s.body[1]
    local d = DIRS[s.dir]
    local nx, ny = h.x + d[1], h.y + d[2]

    if nx < 1 or nx > COLS or ny < 1 or ny > ROWS then
        if not WRAP then
            s.alive = false
            return
        end
        -- 穿墙：从对面出来
        if nx < 1 then nx = COLS elseif nx > COLS then nx = 1 end
        if ny < 1 then ny = ROWS elseif ny > ROWS then ny = 1 end
    end

    local grow = (s.food ~= nil and nx == s.food.x and ny == s.food.y)
    local limit = #s.body - (grow and 0 or 1)      -- 不吃食物时尾巴会让位
    for i = 1, limit do
        if s.body[i].x == nx and s.body[i].y == ny then
            s.alive = false
            return
        end
    end

    table.insert(s.body, 1, { x = nx, y = ny })
    if grow then
        s.score = s.score + 10
        spawnFood(s)
    else
        table.remove(s.body)
    end
    s.steps = s.steps + 1
end

--=====================================================================
-- 界面
--=====================================================================

local state
local frame = 0
local BASE_FRAMES = 6
local FRAME_MS = 5

local function cellRect(x, y)
    return FX + (x - 1) * CELL, FY + (y - 1) * CELL
end

local function drawCell(x, y, color)
    local px, py = cellRect(x, y)
    lcd_fill_rect(px, py, CELL, CELL, C.black)      -- 先铺黑：格子之间就是黑线
    lcd_fill_rect(px, py, CELL - 1, CELL - 1, color)
end

local function draw()
    lcd_clr(C.gray)

        lcd_fill_rect(0, 0, 14, 240, C.navy)
        lcd_disp_str(4, 1, "贪吃蛇", 12, C.white, C.navy, 232, 0)

    -- 场地底色：逐格铺黑（不用大矩形：高度超 255 可能被截断）
    for y = 1, ROWS do
        for x = 1, COLS do
            local px, py = cellRect(x, y)
            lcd_fill_rect(px, py, CELL, CELL, C.black)
        end
    end

    if state.food then drawCell(state.food.x, state.food.y, C.red) end
    for i = #state.body, 1, -1 do
        local seg = state.body[i]
        if i == 1 then
            drawCell(seg.x, seg.y, C.head)
        else
            drawCell(seg.x, seg.y, C.green)
        end
    end

        -- 竖屏：信息行 + 底部提示
        lcd_disp_str(4, 266, "得分 " .. state.score, 12, C.white, C.gray, 100, 0)
        lcd_disp_str(108, 266, "长度 " .. #state.body, 12, C.pale, C.gray, 60, 0)
        local tag = ""
        if state.paused then tag = "暂停" elseif state.boost and WRAP then tag = "速+穿" elseif state.boost then tag = "加速" elseif WRAP then tag = "穿墙" end
        lcd_disp_str(172, 266, tag, 12, C.yellow, C.gray, 66, 2)

        lcd_fill_rect(3, 286, 34, 234, C.navy)
        lcd_disp_str(3, 289, "上=左转 OK=右转 下=切换加速", 12, C.pale, C.navy, 234, 1)
        lcd_disp_str(3, 305, "电源=暂停  C=穿墙:" .. (WRAP and "开" or "关"), 12, C.pale, C.navy, 234, 1)

    if state.win then
        lcd_fill_rect(16, 108, 100, 208, C.navy)
        lcd_fill_rect(16, 108, 3, 208, C.yellow)
        lcd_fill_rect(16, 205, 3, 208, C.yellow)
        lcd_disp_str(16, 126, "通关啦", 24, C.yellow, C.navy, 208, 1)
        lcd_disp_str(16, 162, "整屏都被你占满了", 12, C.white, C.navy, 208, 1)
        lcd_disp_str(16, 184, "按上或OK再来一局", 12, C.pale, C.navy, 208, 1)
    elseif not state.alive then
        lcd_fill_rect(16, 108, 112, 208, C.navy)
        lcd_fill_rect(16, 108, 3, 208, C.yellow)
        lcd_fill_rect(16, 217, 3, 208, C.yellow)
        lcd_disp_str(16, 122, "游戏结束", 24, C.yellow, C.navy, 208, 1)
        lcd_disp_str(16, 158, "得分 " .. state.score, 16, C.white, C.navy, 208, 1)
        lcd_disp_str(16, 180, "长度 " .. #state.body, 12, C.light, C.navy, 208, 1)
        lcd_disp_str(16, 198, "按上或OK再来一局", 12, C.pale, C.navy, 208, 1)
    elseif state.paused then
        lcd_fill_rect(16, 108, 112, 208, C.navy)
        lcd_fill_rect(16, 108, 3, 208, C.yellow)
        lcd_fill_rect(16, 217, 3, 208, C.yellow)
        lcd_disp_str(16, 122, "已暂停", 24, C.yellow, C.navy, 208, 1)
        lcd_disp_str(16, 158, "得分 " .. state.score, 16, C.white, C.navy, 208, 1)
        lcd_disp_str(16, 180, "穿墙 " .. (WRAP and "开启" or "关闭"), 12, C.light, C.navy, 208, 1)
        lcd_disp_str(16, 198, "电源继续      长按C退出", 12, C.pale, C.navy, 208, 1)
    end
end

--=====================================================================
-- 按键
--=====================================================================

local KEY = {
    left_turn = 2,      -- 上 单击
    right_turn = 100,   -- OK 单击
    boost_down = 9,     -- 下 单击
    wrap = 101,         -- C 单击
    pause_short = 30,   -- 电源短按弹起
    pause_long_up = 32, -- 电源长按弹起
}

local function handleKey(k)
    if k == KEY.left_turn then
        turn(state, -1)
    elseif k == KEY.right_turn then
        turn(state, 1)
    elseif k == KEY.boost_down then
        state.boost = not state.boost
    elseif k == KEY.wrap then
        WRAP = not WRAP
    elseif k == KEY.pause_short or k == KEY.pause_long_up then
        state.paused = not state.paused
    end
end

local function isGameKey(k)
    return k == KEY.left_turn or k == KEY.right_turn or k == KEY.boost_down
        or k == KEY.wrap or k == KEY.pause_short or k == KEY.pause_long_up
end

local function main()
    while get_key() > 0 do end
    state = newState()
    draw()
    lcd_refresh()

    while true do
        local k = get_key()
        while k ~= 0 do
            if not state.alive or state.win then
                if k == KEY.left_turn or k == KEY.right_turn then
                    state = newState()
                end
            else
                handleKey(k)
            end
            k = get_key()
        end

        if state.alive and not state.win and not state.paused then
            frame = frame + 1
            local every = BASE_FRAMES
            local lvl = math.floor(state.score / 50)
            if lvl > 3 then lvl = 3 end
            every = BASE_FRAMES - lvl
            if every < 3 then every = 3 end
            if state.boost then every = 2 end          -- 按住"下"加速
            if frame >= every then
                frame = 0
                step(state)
            end
        end

        draw()
        lcd_refresh()
        delayms(FRAME_MS)
    end
end

--=====================================================================
-- 自测（设置 _G.H7_SNAKE_TEST = true 后 dofile 本文件即运行自测，不进入游戏）
--=====================================================================

local function runTests()
    local ok, fail = 0, 0
    local function chk(name, cond)
        if cond then ok = ok + 1 else fail = fail + 1 print("H7T FAIL " .. name) end
    end

    local s = newState()
    chk("initial_length_3", #s.body == 3)
    chk("initial_dir_right", s.dir == 2)
    chk("initial_alive", s.alive == true)
    chk("initial_food_set", s.food ~= nil)
    chk("food_not_on_body", not occupied(s, s.food.x, s.food.y))
    chk("head_position", s.body[1].x == 8 and s.body[1].y == 9)

    step(s)
    chk("moves_right", s.body[1].x == 9 and s.body[1].y == 9)
    chk("length_keeps_3", #s.body == 3)
    chk("steps_counted", s.steps == 1)

    -- 相对转向
    chk("turn_left_ok", turn(s, -1) == true)       -- 右 → 上
    step(s)
    chk("turned_to_up", s.body[1].y == 8 and s.body[1].x == 9)
    chk("turn_right_ok", turn(s, 1) == true)       -- 上 → 右
    step(s)
    chk("turned_to_right", s.body[1].x == 10 and s.body[1].y == 8)
    chk("turn_left_twice", turn(s, -1) == true and turn(s, -1) == true)  -- 右 → 上 → 左（队列满）
    chk("queue_full_rejects", turn(s, -1) == false)

    -- 吃食物
    local s2 = newState()
    s2.food = { x = s2.body[1].x + 1, y = s2.body[1].y }
    local before = #s2.body
    step(s2)
    chk("grow_on_food", #s2.body == before + 1)
    chk("score_10", s2.score == 10)
    chk("new_food_spawned", s2.food ~= nil)
    chk("new_food_valid", not occupied(s2, s2.food.x, s2.food.y))

    -- 撞墙
    local s3 = newState()
    s3.body = { { x = COLS, y = 5 }, { x = COLS - 1, y = 5 }, { x = COLS - 2, y = 5 } }
    s3.dir = 2
    step(s3)
    chk("wall_kills", s3.alive == false)

    -- 穿墙宏：打开后从对面出来
    local s3b = newState()
    s3b.body = { { x = COLS, y = 5 }, { x = COLS - 1, y = 5 }, { x = COLS - 2, y = 5 } }
    s3b.dir = 2
    WRAP = true
    step(s3b)
    chk("wrap_survives", s3b.alive == true)
    chk("wrap_to_left_edge", s3b.body[1].x == 1 and s3b.body[1].y == 5)
    WRAP = false
    local s3c = newState()
    s3c.body = { { x = 1, y = 5 }, { x = 2, y = 5 }, { x = 3, y = 5 } }
    s3c.dir = 4
    step(s3c)
    chk("wall_still_kills_when_off", s3c.alive == false)

    -- 咬到自己
    local s4 = newState()
    s4.body = {
        { x = 5, y = 5 }, { x = 6, y = 5 }, { x = 6, y = 6 },
        { x = 5, y = 6 }, { x = 4, y = 6 }, { x = 4, y = 5 },
    }
    s4.dir = 2
    step(s4)
    chk("self_collision_kills", s4.alive == false)

    -- 暂停时不前进
    local s5 = newState()
    s5.paused = true
    local hx, hy = s5.body[1].x, s5.body[1].y
    step(s5)
    chk("paused_does_not_move", s5.body[1].x == hx and s5.body[1].y == hy)

    -- 食物永远合法
    local s6 = newState()
    local good = true
    for i = 1, 30 do
        spawnFood(s6)
        if s6.food then
            if s6.food.x < 1 or s6.food.x > COLS or s6.food.y < 1 or s6.food.y > ROWS then good = false end
            if occupied(s6, s6.food.x, s6.food.y) then good = false end
        end
    end
    chk("food_always_valid_30x", good)

    -- 转向后的方向一定不等于 180° 反向
    local s7 = newState()
    local ok180 = true
    for d = -1, 1, 2 do
        local s8 = newState()
        turn(s8, d)
        step(s8)
        if s8.dir == ((2 - 1 + 2) % 4) + 1 then ok180 = false end
    end
    chk("never_reverses", ok180)

    print("H7T DONE ok=" .. ok .. " fail=" .. fail)
end

if _G.H7_SNAKE_TEST then
    runTests()
    return
end

main()
