--GUIMODE=1
-- H7-TOOL 像素小鸟：上或OK=跳，下=重开，电源=暂停，C长按退出
local W,H=240,320
local C={sky=RGB565(25,105,155),panel=RGB565(18,40,62),white=RGB565(250,250,245),yellow=RGB565(255,215,45),orange=RGB565(255,145,35),green=RGB565(65,205,90),dark=RGB565(20,105,45),red=RGB565(245,70,65),ink=RGB565(45,32,25)}
local bird={x=62,y=150,vy=0};local pipes={};local score,best=0,0;local paused,over=false,false;local tick=0
local function reset() bird.y=150;bird.vy=0;pipes={{x=250,gap=120},{x=390,gap=175}};score=0;paused=false;over=false;tick=0 end
local function flap() if over then reset() else bird.vy=-3.8 end end
local function key(k) if k==1 or k==15 then if not paused then flap() end elseif k==30 or k==32 then paused=not paused elseif k==8 and over then reset() end end
local function fillClip(x,y,h,w,color)
 x=math.floor(x);w=math.floor(w)
 if x<0 then w=w+x;x=0 end
 if x>=W then return end
 if x+w>W then w=W-x end
 if w>0 and h>0 then lcd_fill_rect(x,y,h,w,color) end
end
local function drawBird(x,y)
 -- 22x16 像素鸟：深色轮廓、圆身体、眼睛、双色嘴和动态翅膀。
 local flapUp=(tick%12)<6
 lcd_fill_rect(x-11,y-3,3,5,C.ink)
 lcd_fill_rect(x-11,y+2,3,6,C.ink)
 lcd_fill_rect(x-9,y-6,12,3,C.ink)
 lcd_fill_rect(x-6,y-8,16,12,C.ink)
 lcd_fill_rect(x+6,y-6,12,4,C.ink)
 lcd_fill_rect(x-7,y-6,12,13,C.yellow)
 lcd_fill_rect(x-5,y-7,2,9,C.yellow)
 lcd_fill_rect(x-9,y-2,7,5,C.orange)
 if flapUp then
  lcd_fill_rect(x-8,y-5,6,7,C.orange)
  lcd_fill_rect(x-6,y-7,3,5,C.orange)
 else
  lcd_fill_rect(x-8,y+1,6,8,C.orange)
  lcd_fill_rect(x-5,y+6,2,5,C.orange)
 end
 lcd_fill_rect(x+1,y-6,6,6,C.white)
 lcd_fill_rect(x+5,y-4,3,2,C.ink)
 lcd_fill_rect(x+9,y-2,3,8,C.orange)
 lcd_fill_rect(x+9,y+1,3,6,C.red)
 lcd_fill_rect(x+9,y,1,8,C.ink)
end
local function modal(title,line,hint)
 lcd_fill_rect(16,96,124,208,C.panel);lcd_fill_rect(16,96,3,208,C.yellow);lcd_fill_rect(16,217,3,208,C.yellow)
 lcd_disp_str(16,112,title,24,C.yellow,C.panel,208,1);lcd_disp_str(16,151,line,16,C.white,C.panel,208,1);lcd_disp_str(16,192,hint,12,C.white,C.panel,208,1)
end
local function step()
 if paused or over then return end;tick=tick+1;bird.vy=bird.vy+.19;bird.y=bird.y+bird.vy
 for i=1,#pipes do local p=pipes[i];p.x=p.x-1.7;if not p.scored and p.x+28<bird.x then p.scored=true;score=score+1;if score>best then best=score end end
  if bird.x+10>p.x and bird.x-9<p.x+28 and (bird.y-8<p.gap-38 or bird.y+8>p.gap+38) then over=true end
 end
 if pipes[1].x+31<=0 then table.remove(pipes,1);local last=pipes[#pipes];local g=80+((tick*37)%140);pipes[#pipes+1]={x=last.x+140,gap=g} end
 if bird.y<31 or bird.y>295 then over=true end
end
local function draw()
 lcd_clr(C.sky);lcd_fill_rect(0,0,24,W,C.panel);lcd_disp_str(4,3,"像素小鸟",16,C.yellow,C.panel,90,0);lcd_disp_str(100,4,"分 "..score,12,C.white,C.panel,60,0);lcd_disp_str(166,4,"最高 "..best,12,C.white,C.panel,70,0)
 for i=1,#pipes do local p=pipes[i];local top=p.gap-38-24;if top>0 then fillClip(p.x,24,top,28,C.green);fillClip(p.x-3,p.gap-44,6,34,C.dark) end;local by=p.gap+38;fillClip(p.x,by,302-by,28,C.green);fillClip(p.x-3,by,6,34,C.dark) end
 drawBird(bird.x,math.floor(bird.y))
 if over then modal("游戏结束","得分 "..score,"上/OK 重来   长按C退出") elseif paused then modal("已暂停","得分 "..score,"电源继续      长按C退出") end
 lcd_fill_rect(0,302,18,W,C.panel);lcd_disp_str(4,304,"上/OK=跳  电源=暂停  C长按退出",12,C.white,C.panel,232,1);lcd_refresh()
end
while get_key()>0 do end;reset();print("H7_FLAPPY_BEGIN");while true do local k=get_key();while k>0 do key(k);k=get_key() end;step();draw();delayms(5) end
