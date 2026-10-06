--GUIMODE=1
-- H7-TOOL 2048：上/下/C左/电源右，OK短按重开，C长按退出
local W,H=240,320
local C={bg=RGB565(25,22,20),panel=RGB565(55,48,42),board=RGB565(105,92,78),empty=RGB565(145,130,112),white=RGB565(250,248,240),dark=RGB565(65,58,52),yellow=RGB565(255,215,65),red=RGB565(235,80,70)}
local tileColors={
 [2]=RGB565(235,225,205),[4]=RGB565(232,215,180),[8]=RGB565(245,170,95),[16]=RGB565(245,140,70),
 [32]=RGB565(240,105,70),[64]=RGB565(235,75,55),[128]=RGB565(225,190,70),[256]=RGB565(215,175,55),
 [512]=RGB565(205,155,40),[1024]=RGB565(190,135,30),[2048]=RGB565(245,205,45)
}
local board,score,best,over,won={},0,0,false,false
local function blank() board={} for r=1,4 do board[r]={0,0,0,0} end end
local function emptyCells() local t={} for r=1,4 do for c=1,4 do if board[r][c]==0 then t[#t+1]={r,c} end end end return t end
local function addTile() local e=emptyCells() if #e==0 then return end local p=e[math.random(#e)];board[p[1]][p[2]]=(math.random(10)==1) and 4 or 2 end
local function reset() blank();score=0;over=false;won=false;addTile();addTile() end
local function squeeze(a)
 local b={} for i=1,4 do if a[i]~=0 then b[#b+1]=a[i] end end
 local out={} local i=1
 while i<=#b do if i<#b and b[i]==b[i+1] then local v=b[i]*2;out[#out+1]=v;score=score+v;if v==2048 then won=true end;i=i+2 else out[#out+1]=b[i];i=i+1 end end
 while #out<4 do out[#out+1]=0 end return out
end
local function snapshot() local s="" for r=1,4 do for c=1,4 do s=s..board[r][c].."," end end return s end
local function canMove()
 if #emptyCells()>0 then return true end
 for r=1,4 do for c=1,4 do local v=board[r][c] if c<4 and board[r][c+1]==v then return true end;if r<4 and board[r+1][c]==v then return true end end end return false
end
local function move(dir)
 if over then return end local old=snapshot()
 for n=1,4 do local a={}
  for i=1,4 do local r,c;if dir=="L" then r,c=n,i elseif dir=="R" then r,c=n,5-i elseif dir=="U" then r,c=i,n else r,c=5-i,n end;a[i]=board[r][c] end
  local b=squeeze(a)
  for i=1,4 do local r,c;if dir=="L" then r,c=n,i elseif dir=="R" then r,c=n,5-i elseif dir=="U" then r,c=i,n else r,c=5-i,n end;board[r][c]=b[i] end
 end
 if snapshot()~=old then addTile();if score>best then best=score end end;if not canMove() then over=true end
end
local function key(k) if k==1 then move("U") elseif k==8 then move("D") elseif k==101 then move("L") elseif k==29 then move("R") elseif k==100 then reset() end end
local function progress()
 local m=2;for r=1,4 do for c=1,4 do if board[r][c]>m then m=board[r][c] end end end
 local n,v=1,2;while v<m and n<11 do v=v*2;n=n+1 end;return m,math.floor(n*100/11)
end
local function modal(title,line,hint)
 lcd_fill_rect(16,96,124,208,C.panel);lcd_fill_rect(16,96,3,208,C.yellow);lcd_fill_rect(16,217,3,208,C.yellow)
 lcd_disp_str(16,112,title,24,C.yellow,C.panel,208,1);lcd_disp_str(16,151,line,16,C.white,C.panel,208,1);lcd_disp_str(16,192,hint,12,C.white,C.panel,208,1)
end
local function drawTile(r,c,v)
 local x=19+(c-1)*51;local y=64+(r-1)*51;local color=tileColors[v] or C.red;lcd_fill_rect(x,y,47,47,v==0 and C.empty or color)
 if v~=0 then local text=tostring(v);local fs=(v<100 and 24 or (v<1000 and 16 or 12));local fg=(v<=4 and C.dark or C.white);lcd_disp_str(x,y+math.floor((47-fs)/2),fs,fg,color,47,1) end
end
local function draw()
 local maxv,pct=progress();lcd_clr(C.bg);lcd_fill_rect(0,0,48,W,C.panel);lcd_disp_str(7,6,"2048",32,C.yellow,C.panel,84,0);lcd_disp_str(100,5,"得分 "..score,12,C.white,C.panel,130,0);lcd_disp_str(100,22,"进度 "..maxv.."/2048",12,C.white,C.panel,130,0);lcd_fill_rect(100,40,4,130,C.empty);lcd_fill_rect(100,40,4,math.max(2,math.floor(130*pct/100)),C.yellow)
 lcd_fill_rect(14,59,208,208,C.board);for r=1,4 do for c=1,4 do drawTile(r,c,board[r][c]) end end
 if over or won then modal(over and "游戏结束" or "达成目标",over and ("得分 "..score) or "合成 2048！","OK 重来      长按C退出") end
 lcd_fill_rect(0,286,34,W,C.panel);lcd_disp_str(4,290,"上/下  C=左  电源=右",12,C.white,C.panel,232,1);lcd_disp_str(4,305,"OK短按重开 / C长按退出",12,C.white,C.panel,232,1);lcd_refresh()
end
math.randomseed(get_runtime());while get_key()>0 do end;reset();print("H7_2048_BEGIN");while true do local k=get_key();while k>0 do key(k);k=get_key() end;draw();delayms(8) end
