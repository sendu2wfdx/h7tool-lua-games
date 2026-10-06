--GUIMODE=1
-- H7-TOOL 小蜜蜂：上=左，OK=右，下=开火，电源=暂停，C长按退出
local W,H=240,320
local C={bg=RGB565(5,10,22),panel=RGB565(18,38,61),white=RGB565(245,245,245),cyan=RGB565(55,215,235),yellow=RGB565(255,215,50),red=RGB565(245,65,70),green=RGB565(70,225,120),purple=RGB565(185,80,235)}
local px=112;local left,right,paused,gameOver=false,false,false,false;local shot=nil;local bombs={};local enemies={};local dir=1;local tick,score,lives=0,0,3
local function resetWave() enemies={};for r=1,4 do for c=1,7 do enemies[#enemies+1]={x=20+(c-1)*30,y=48+(r-1)*22,on=true} end end;dir=1 end
local function reset() px=112;shot=nil;bombs={};score=0;lives=3;paused=false;gameOver=false;resetWave() end
local function alive() local n=0 for i=1,#enemies do if enemies[i].on then n=n+1 end end return n end
local function fire() if not shot then shot={x=px+8,y=270} end end
local function key(k) if gameOver then if k==100 then reset() end;return elseif k==1 then left=not paused elseif k==2 or k==4 then left=false elseif k==15 then right=not paused elseif k==100 or k==18 then right=false elseif k==8 and not paused then fire() elseif k==30 or k==32 then paused=not paused;left=false;right=false end end
local function step()
 if paused or gameOver then return end;tick=tick+1;px=math.max(4,math.min(220,px+(left and -3 or (right and 3 or 0))))
 if shot then shot.y=shot.y-5;if shot.y<25 then shot=nil else for i=1,#enemies do local e=enemies[i] if e.on and shot and shot.x>=e.x and shot.x<=e.x+16 and shot.y>=e.y and shot.y<=e.y+10 then e.on=false;shot=nil;score=score+10 end end end end
 if tick%12==0 then local edge=false;for i=1,#enemies do local e=enemies[i] if e.on and ((dir>0 and e.x>216) or (dir<0 and e.x<8)) then edge=true end end;for i=1,#enemies do local e=enemies[i] if e.on then if edge then e.y=e.y+9 else e.x=e.x+dir*3 end end end;if edge then dir=-dir end end
 if tick%55==0 then local pool={};for i=1,#enemies do if enemies[i].on then pool[#pool+1]=enemies[i] end end;if #pool>0 then local e=pool[(tick%#pool)+1];bombs[#bombs+1]={x=e.x+8,y=e.y+12} end end
 for i=#bombs,1,-1 do local b=bombs[i];b.y=b.y+3;if b.y>305 then table.remove(bombs,i) elseif b.y>276 and b.x>=px and b.x<=px+20 then table.remove(bombs,i);lives=lives-1;if lives<=0 then lives=0;gameOver=true end end end
 if alive()==0 then resetWave() end
end
local function modal(title,line,hint) lcd_fill_rect(16,96,124,208,C.panel);lcd_fill_rect(16,96,3,208,C.yellow);lcd_fill_rect(16,217,3,208,C.yellow);lcd_disp_str(16,112,title,24,C.yellow,C.panel,208,1);lcd_disp_str(16,151,line,16,C.white,C.panel,208,1);lcd_disp_str(16,192,hint,12,C.white,C.panel,208,1) end
local function draw()
 lcd_clr(C.bg);lcd_fill_rect(0,0,24,W,C.panel);lcd_disp_str(4,3,"小蜜蜂",16,C.yellow,C.panel,70,0);lcd_disp_str(82,4,"分 "..score,12,C.white,C.panel,80,0);lcd_disp_str(170,4,"命 "..lives,12,C.green,C.panel,64,0)
 for i=1,#enemies do local e=enemies[i] if e.on then lcd_fill_rect(math.floor(e.x),math.floor(e.y),9,16,(i%2==0) and C.purple or C.green);lcd_fill_rect(math.floor(e.x)-3,math.floor(e.y)+7,3,22,C.cyan) end end
 lcd_fill_rect(px,278,8,20,C.cyan);lcd_fill_rect(px+7,272,7,6,C.white);if shot then lcd_fill_rect(shot.x,shot.y,6,2,C.yellow) end;for i=1,#bombs do local b=bombs[i];lcd_fill_rect(b.x,b.y,5,3,C.red) end
 if gameOver then modal("游戏结束","得分 "..score,"OK 重来      长按C退出") elseif paused then modal("已暂停","得分 "..score,"电源继续      长按C退出") end
 lcd_fill_rect(0,302,18,W,C.panel);lcd_disp_str(4,304,"上=左  OK=右  下=开火  电源=暂停",12,C.white,C.panel,232,1);lcd_refresh()
end
while get_key()>0 do end;reset();print("H7_INVADERS_BEGIN");while true do local k=get_key();while k>0 do key(k);k=get_key() end;step();draw();delayms(4) end
