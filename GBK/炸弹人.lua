--GUIMODE=1
-- H7-TOOL 炸弹人：上/下/C左/电源右，OK放炸弹，C长按退出
local W,H=240,320
local COLS,ROWS,TILE=11,13,20
local OX,OY=10,26
local C={bg=RGB565(7,14,24),panel=RGB565(16,42,78),floor=RGB565(45,62,70),wall=RGB565(60,125,180),edge=RGB565(120,205,235),crate=RGB565(185,110,45),crate2=RGB565(235,165,65),white=RGB565(250,250,245),yellow=RGB565(255,205,35),orange=RGB565(250,115,30),red=RGB565(235,55,55),cyan=RGB565(55,215,235),purple=RGB565(180,75,220),black=RGB565(0,0,0)}
local walls,crates,bombs,fire,enemies={},{},{},{},{}
local pr,pc=2,2
local score,level=0,1
local gameOver,win=false,false
local tick,seed=0,12345
local function id(r,c) return r..","..c end
local function rnd() seed=(seed*1103515245+12345)%2147483648 return math.floor(seed/65536) end
local function inBounds(r,c) return r>=1 and r<=ROWS and c>=1 and c<=COLS end
local function bombAt(r,c) for i=1,#bombs do local b=bombs[i] if b.active and b.r==r and b.c==c then return b end end return nil end
local function blocked(r,c) local k=id(r,c);return walls[k] or crates[k] or bombAt(r,c) end
local function clearSpawn(r,c) crates[id(r,c)]=nil;crates[id(r-1,c)]=nil;crates[id(r+1,c)]=nil;crates[id(r,c-1)]=nil;crates[id(r,c+1)]=nil end
local function makeLevel()
 walls={};crates={};bombs={};fire={};enemies={};tick=0;gameOver=false;win=false;pr,pc=2,2
 for r=1,ROWS do for c=1,COLS do local k=id(r,c);if r==1 or r==ROWS or c==1 or c==COLS or (r%2==1 and c%2==1) then walls[k]=true elseif rnd()%100<43 then crates[k]=true end end end
 clearSpawn(2,2);local starts={{ROWS-1,COLS-1},{ROWS-1,2},{2,COLS-1},{ROWS-3,COLS-1},{ROWS-1,COLS-3}}
 local count=math.min(2+level,5);for i=1,count do local p=starts[i];clearSpawn(p[1],p[2]);enemies[#enemies+1]={r=p[1],c=p[2],alive=true,color=(i%2==0) and C.purple or C.red} end
end
local function resetGame() score=0;level=1;seed=((os.time() or 1)*1009+get_runtime()*97)%2147483647;makeLevel() end
local function addFire(r,c) fire[id(r,c)]=9 end
local function explode(b)
 if not b.active then return end;b.active=false;addFire(b.r,b.c);local dirs={{-1,0},{1,0},{0,-1},{0,1}}
 for d=1,4 do local dr,dc=dirs[d][1],dirs[d][2];for n=1,2 do local r,c=b.r+dr*n,b.c+dc*n;local k=id(r,c);if walls[k] then break end;addFire(r,c);local other=bombAt(r,c);if other then explode(other) end;if crates[k] then crates[k]=nil;score=score+5;break end end end
end
local function placeBomb() if gameOver or win or bombAt(pr,pc) then return end;local active=0 for i=1,#bombs do if bombs[i].active then active=active+1 end end;if active<1+math.floor((level-1)/3) then bombs[#bombs+1]={r=pr,c=pc,fuse=48,active=true} end end
local function move(dr,dc) if gameOver or win then return end;local r,c=pr+dr,pc+dc;if not blocked(r,c) then pr,pc=r,c end end
local function key(k)
 if gameOver or win then if k==100 then if win then level=level+1;makeLevel() else makeLevel() end end;return end
 if k==1 then move(-1,0) elseif k==8 then move(1,0) elseif k==101 then move(0,-1) elseif k==29 then move(0,1) elseif k==100 then placeBomb() end
end
local function enemyStep(e)
 local dirs={{-1,0},{1,0},{0,-1},{0,1}};local start=(rnd()%4)+1
 for n=0,3 do local d=dirs[((start+n-1)%4)+1];local r,c=e.r+d[1],e.c+d[2];if not blocked(r,c) then e.r,e.c=r,c;return end end
end
local function update()
 if gameOver or win then return end;tick=tick+1
 for i=1,#bombs do local b=bombs[i] if b.active then b.fuse=b.fuse-1;if b.fuse<=0 then explode(b) end end end
 for k,v in pairs(fire) do v=v-1;if v<=0 then fire[k]=nil else fire[k]=v end end
 if tick%9==0 then for i=1,#enemies do if enemies[i].alive then enemyStep(enemies[i]) end end end
 if fire[id(pr,pc)] then gameOver=true end
 local alive=0;for i=1,#enemies do local e=enemies[i] if e.alive then if fire[id(e.r,e.c)] then e.alive=false;score=score+50 elseif e.r==pr and e.c==pc then gameOver=true else alive=alive+1 end end end
 if alive==0 and not gameOver then win=true end
end
local function modal(title,line,hint) lcd_fill_rect(16,96,124,208,C.panel);lcd_fill_rect(16,96,3,208,C.yellow);lcd_fill_rect(16,217,3,208,C.yellow);lcd_disp_str(16,112,title,24,C.yellow,C.panel,208,1);lcd_disp_str(16,151,line,16,C.white,C.panel,208,1);lcd_disp_str(16,192,hint,12,C.white,C.panel,208,1) end
local function draw()
 lcd_clr(C.bg);lcd_fill_rect(0,0,24,W,C.panel);lcd_disp_str(4,3,"炸弹人",16,C.yellow,C.panel,72,0);lcd_disp_str(82,4,"分 "..score,12,C.white,C.panel,74,0);lcd_disp_str(168,4,"关 "..level,12,C.cyan,C.panel,68,0)
 for r=1,ROWS do for c=1,COLS do local x,y=OX+(c-1)*TILE,OY+(r-1)*TILE;local k=id(r,c);lcd_fill_rect(x,y,TILE-1,TILE-1,C.floor);if walls[k] then lcd_fill_rect(x,y,TILE-1,TILE-1,C.wall);lcd_draw_rect(x,y,TILE-1,TILE-1,C.edge) elseif crates[k] then lcd_fill_rect(x+2,y+2,TILE-5,TILE-5,C.crate);lcd_draw_line(x+3,y+3,x+15,y+15,C.crate2);lcd_draw_line(x+15,y+3,x+3,y+15,C.crate2) end end end
 for i=1,#bombs do local b=bombs[i] if b.active then local x,y=OX+(b.c-1)*TILE,OY+(b.r-1)*TILE;lcd_fill_rect(x+5,y+5,10,10,C.black);lcd_fill_rect(x+8,y+3,3,5,(b.fuse%8<4) and C.yellow or C.red) end end
 for k,_ in pairs(fire) do local comma=string.find(k,",");local r=tonumber(string.sub(k,1,comma-1));local c=tonumber(string.sub(k,comma+1));local x,y=OX+(c-1)*TILE,OY+(r-1)*TILE;lcd_fill_rect(x+2,y+2,15,15,C.orange);lcd_fill_rect(x+6,y+6,7,7,C.yellow) end
 for i=1,#enemies do local e=enemies[i] if e.alive then local x,y=OX+(e.c-1)*TILE,OY+(e.r-1)*TILE;lcd_fill_rect(x+3,y+5,12,14,e.color);lcd_fill_rect(x+5,y+3,4,10,e.color);lcd_fill_rect(x+6,y+7,3,3,C.white);lcd_fill_rect(x+11,y+7,3,3,C.white) end end
 local x,y=OX+(pc-1)*TILE,OY+(pr-1)*TILE;lcd_fill_rect(x+4,y+4,13,12,C.cyan);lcd_fill_rect(x+6,y+2,4,8,C.white);lcd_fill_rect(x+6,y+7,3,3,C.black);lcd_fill_rect(x+11,y+7,3,3,C.black)
 if gameOver then modal("游戏结束","得分 "..score,"OK 重来      长按C退出") elseif win then modal("本关完成","得分 "..score,"OK 进入下一关") end
 lcd_fill_rect(0,286,34,W,C.panel);lcd_disp_str(4,290,"上/下  C=左  电源=右",12,C.white,C.panel,232,1);lcd_disp_str(4,305,"OK=放炸弹    长按C退出",12,C.white,C.panel,232,1);lcd_refresh()
end
while get_key()>0 do end;resetGame();print("H7_BOMBER_BEGIN");while true do local k=get_key();while k>0 do key(k);k=get_key() end;update();draw();delayms(7) end
