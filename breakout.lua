--GUIMODE=1
-- H7-TOOL 打砖块：上=左，OK=右，下=发球，电源=暂停，C长按退出
local W,H=240,320
local C={bg=RGB565(8,14,28),panel=RGB565(20,42,65),white=RGB565(245,245,245),cyan=RGB565(60,215,235),yellow=RGB565(255,215,55),red=RGB565(245,75,75),green=RGB565(70,225,125),blue=RGB565(70,125,245),purple=RGB565(185,80,235)}
local colors={C.red,C.yellow,C.green,C.cyan,C.blue,C.purple}
local left,right,paused,gameOver,levelClear=false,false,false,false,false
local clearTick=0
local score,lives,level=0,3,1
local paddle={x=88,y=278,w=64,h=7}
local ball={x=120,y=268,vx=2.2,vy=-3.0,r=4,wait=true}
local bricks={}
local function clamp(v,a,b) if v<a then return a elseif v>b then return b end return v end
local function circle(x,y,r,c) for d=-r,r do local q=math.floor(math.sqrt(r*r-d*d)); lcd_fill_rect(x-q,y+d,1,q*2+1,c) end end
local function resetBall() ball.x=paddle.x+paddle.w/2;ball.y=268;ball.vx=2.1;ball.vy=-3.1-level*.12;ball.wait=true end
local function makeBricks()
  bricks={}
  for r=1,6 do for col=1,8 do bricks[#bricks+1]={x=7+(col-1)*29,y=42+(r-1)*15,w=26,h=11,on=true,c=colors[r]} end end
end
local function resetGame() score,lives,level=0,3,1;paddle.x=88;makeBricks();resetBall();paused=false;gameOver=false;levelClear=false;clearTick=0 end
local function remaining() local n=0 for i=1,#bricks do if bricks[i].on then n=n+1 end end return n end
local function hitBrick(b)
  if not b.on then return false end
  if ball.x+ball.r<b.x or ball.x-ball.r>b.x+b.w or ball.y+ball.r<b.y or ball.y-ball.r>b.y+b.h then return false end
  b.on=false;score=score+10;ball.vy=-ball.vy;return true
end
local function physics()
  if paused or gameOver or levelClear then return end
  local speed=left and -3.7 or (right and 3.7 or 0);paddle.x=clamp(paddle.x+speed,5,W-paddle.w-5)
  if ball.wait then ball.x=paddle.x+paddle.w/2 return end
  ball.x=ball.x+ball.vx;ball.y=ball.y+ball.vy
  if ball.x<ball.r+5 then ball.x=ball.r+5;ball.vx=math.abs(ball.vx) end
  if ball.x>W-ball.r-5 then ball.x=W-ball.r-5;ball.vx=-math.abs(ball.vx) end
  if ball.y<28 then ball.y=28;ball.vy=math.abs(ball.vy) end
  if ball.vy>0 and ball.y+ball.r>=paddle.y and ball.y-ball.r<=paddle.y+paddle.h and ball.x>=paddle.x-3 and ball.x<=paddle.x+paddle.w+3 then
    ball.y=paddle.y-ball.r;local t=(ball.x-(paddle.x+paddle.w/2))/(paddle.w/2);ball.vx=t*3.8;ball.vy=-math.abs(ball.vy)
  end
  for i=1,#bricks do if hitBrick(bricks[i]) then break end end
  if remaining()==0 then levelClear=true;clearTick=0;ball.wait=true;left=false;right=false end
  if ball.y>305 then lives=lives-1;if lives<=0 then lives=0;gameOver=true;ball.wait=true else resetBall() end end
end
local function key(k)
  if levelClear then left=false;right=false;return end
  if gameOver then if k==100 then resetGame() end;return end
  if k==1 then left=not paused elseif k==2 or k==4 then left=false
  elseif k==15 then right=not paused elseif k==100 or k==18 then right=false
  elseif k==8 and ball.wait and not paused then ball.wait=false
  elseif k==30 or k==32 then paused=not paused;left=false;right=false end
end
local function modal(title,line,hint) lcd_fill_rect(16,96,124,208,C.panel);lcd_fill_rect(16,96,3,208,C.yellow);lcd_fill_rect(16,217,3,208,C.yellow);lcd_disp_str(16,112,title,24,C.yellow,C.panel,208,1);lcd_disp_str(16,151,line,16,C.white,C.panel,208,1);lcd_disp_str(16,192,hint,12,C.white,C.panel,208,1) end
local function draw()
  lcd_clr(C.bg);lcd_fill_rect(0,0,24,W,C.panel);lcd_disp_str(4,3,"打砖块",16,C.yellow,C.panel,72,0);lcd_disp_str(82,4,"分 "..score,12,C.white,C.panel,74,0);lcd_disp_str(154,4,"关 "..level,12,C.cyan,C.panel,42,0);lcd_disp_str(198,4,"球 "..lives,12,C.green,C.panel,38,0)
  for i=1,#bricks do local b=bricks[i] if b.on then lcd_fill_rect(b.x,b.y,b.h,b.w,b.c) end end
  lcd_fill_rect(math.floor(paddle.x),paddle.y,paddle.h,paddle.w,C.cyan);circle(math.floor(ball.x),math.floor(ball.y),ball.r,C.white)
  if ball.wait then lcd_disp_str(55,220,"按下键发球",16,C.yellow,C.bg,130,1) end
  if gameOver then modal("游戏结束","得分 "..score,"OK 重来      长按C退出") elseif levelClear then modal("本关完成","得分 "..score,"即将进入第 "..(level+1).." 关") elseif paused then modal("已暂停","得分 "..score,"电源继续      长按C退出") end
  lcd_fill_rect(0,302,18,W,C.panel);lcd_disp_str(4,304,"上=左  OK=右  下=发球  电源=暂停",12,C.white,C.panel,232,1);lcd_refresh()
end
while get_key()>0 do end;resetGame();print("H7_BREAKOUT_BEGIN")
while true do local k=get_key();while k>0 do key(k);k=get_key() end;if levelClear then clearTick=clearTick+1;if clearTick>36 then level=level+1;makeBricks();resetBall();levelClear=false end end;physics();draw();delayms(4) end
