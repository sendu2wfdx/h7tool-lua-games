--GUIMODE=1
-- H7-TOOL 推箱子：上/下/C左/电源右，OK短按重开，C长按退出
local W,H,T=240,320,20
local C={bg=RGB565(12,18,27),panel=RGB565(24,43,61),floor=RGB565(55,67,74),wall=RGB565(65,125,165),edge=RGB565(115,195,225),goal=RGB565(235,80,80),box=RGB565(225,160,55),boxok=RGB565(80,205,115),player=RGB565(255,225,65),white=RGB565(245,245,245)}
local levels={
 -- 第1关：热身，但必须绕到箱子后方，不能原地直推。
 {"##########","#   #    #","# .   .  #","#  $$ #  #","# #  $ . #","#   @    #","#   ##   #","#        #","#        #","##########"},
 -- 第2关：分隔墙迫使玩家多次绕行。
 {"##########","# . #  . #","#   #    #","# $   $  #","#    #   #","#  $   . #","#   @    #","#        #","#        #","##########"},
 -- 第3关：双通道与三个箱子。
 {"##########","# .    . #","#  ##    #","# $  $   #","#  # #   #","#  $   . #","#    @   #","#   ##   #","#        #","##########"},
 -- 第4关：四箱、墙洞和多个推箱次序选择。
 {"##########","# .  # . #","#    #   #","# $$   $ #","#  # #   #","#  .   $ #","#   .#   #","#   @    #","#        #","##########"},
 -- 第5关：两排断墙，最少需要约20次推动。
 {"##########","#  . .   #","# ## ##  #","#  $ $   #","#   #    #","#  $ .   #","#   @    #","#        #","#        #","##########"},
}
local level=1;local walls,goals,boxes={}, {}, {};local pr,pc=1,1;local moves=0;local complete=false;local completeTick=0;local history={}
local function id(r,c) return r..","..c end
local function loadLevel(n)
 level=n;if level>#levels then level=1 end;walls={};goals={};boxes={};moves=0;complete=false;completeTick=0;history={}
 local m=levels[level];for r=1,#m do for c=1,10 do local ch=string.sub(m[r],c,c);local k=id(r,c);if ch=="#" then walls[k]=true elseif ch=="." then goals[k]=true elseif ch=="$" then boxes[k]=true elseif ch=="@" then pr,pc=r,c elseif ch=="*" then goals[k]=true;boxes[k]=true end end end
end
local function solved() for k,_ in pairs(goals) do if not boxes[k] then return false end end return true end
local function saveState()
 local b={} for k,v in pairs(boxes) do b[k]=v end;history[#history+1]={pr=pr,pc=pc,boxes=b,moves=moves};if #history>100 then table.remove(history,1) end
end
local function undo()
 local s=history[#history];if not s then return end;history[#history]=nil;pr,pc=s.pr,s.pc;boxes=s.boxes;moves=s.moves;complete=false;completeTick=0
end
local function move(dr,dc)
 if complete then return end;local nr,nc=pr+dr,pc+dc;local nk=id(nr,nc);if walls[nk] then return end
 local bk=nil;if boxes[nk] then local br,bc=nr+dr,nc+dc;bk=id(br,bc);if walls[bk] or boxes[bk] then return end end
 saveState();if bk then boxes[nk]=nil;boxes[bk]=true end
 pr,pc=nr,nc;moves=moves+1;if solved() then complete=true;completeTick=0 end
end
local function key(k) if k==1 then move(-1,0) elseif k==8 then move(1,0) elseif k==101 then move(0,-1) elseif k==29 then move(0,1) elseif k==100 then undo() elseif k==17 then loadLevel(level) end end
local function modal(title,line,hint)
 lcd_fill_rect(16,96,124,208,C.panel);lcd_fill_rect(16,96,3,208,C.player);lcd_fill_rect(16,217,3,208,C.player)
 lcd_disp_str(16,112,title,24,C.player,C.panel,208,1);lcd_disp_str(16,151,line,16,C.white,C.panel,208,1);lcd_disp_str(16,192,hint,12,C.white,C.panel,208,1)
end
local function draw()
 lcd_clr(C.bg);lcd_fill_rect(0,0,42,W,C.panel);lcd_disp_str(5,4,"推箱子",20,C.player,C.panel,80,0);lcd_disp_str(92,5,"关卡 "..level.."/"..#levels,12,C.white,C.panel,75,0);lcd_disp_str(170,5,"步数 "..moves,12,C.white,C.panel,66,0)
 local ox,oy=20,52;for r=1,10 do for c=1,10 do local x,y=ox+(c-1)*T,oy+(r-1)*T;local k=id(r,c);if walls[k] then lcd_fill_rect(x,y,T-1,T-1,C.wall);lcd_draw_rect(x,y,T-1,T-1,C.edge) else lcd_fill_rect(x,y,T-1,T-1,C.floor);if goals[k] then lcd_fill_rect(x+7,y+7,6,6,C.goal) end;if boxes[k] then local bc=goals[k] and C.boxok or C.box;lcd_fill_rect(x+3,y+3,14,14,bc);lcd_draw_rect(x+3,y+3,14,14,C.white) end;if r==pr and c==pc then lcd_fill_rect(x+5,y+4,12,10,C.player);lcd_fill_rect(x+7,y+2,4,6,C.player) end end end end
 if complete then modal("过关！","步数 "..moves,"即将进入下一关") end
 lcd_fill_rect(0,264,56,W,C.panel);lcd_disp_str(4,271,"上/下  C=左  电源=右",12,C.white,C.panel,232,1);lcd_disp_str(4,291,"OK短按撤销 / 长按重开",12,C.white,C.panel,232,1);lcd_refresh()
end
while get_key()>0 do end;loadLevel(1);print("H7_SOKOBAN_BEGIN");while true do local k=get_key();while k>0 do key(k);k=get_key() end;if complete then completeTick=completeTick+1;if completeTick>28 then loadLevel(level+1) end end;draw();delayms(12) end
