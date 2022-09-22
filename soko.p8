pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- main
-- todo: replace cls by draw only necessary parts

-- sprite flags:
--   0-usr,1-wall,2-target,3-box

-- functions
function _init()
  extcmd("set_title","soko")
  _initmenu()
  _update=_updatemenu
  _draw=_drawmenu
end

function _menu2level(mn)
  local lv=readlv(mn.lv)
  _initlevel(lv)
  _update=_updatelevel
  _draw=_drawlevel
end

-- end main
-->8
-- levels

-- read level from map editor
function readlv(n)
  local lv={
    x0=0, y0=0, -- pos in map
    env={}, -- unmovable
    obj={}, -- movable
    siz={x=16,y=16},
    cnt=0, -- count filled targets
    usr={x=1,y=1},
    usrface=3, -- face orientation
  }
  lv.x0=((n-1)%8)*16
  lv.y0=((n-1)\8)*16 -- int div
  for y=1,lv.siz.y do
    local lv_env_y={}
    local lv_obj_y={}
    for x=1,lv.siz.x do
      local sp=mget(lv.x0+x-1,lv.y0+y-1)
      local env=0
      local obj=0
      -- env
      if (fget(sp,1)) env=1
      if (fget(sp,2)) then
        env=2
        lv.cnt+=1
      end
      -- obj
      if (fget(sp,3)) obj=1
      -- usr
      if (fget(sp,0)) lv.usr={x=x,y=y}
      add(lv_env_y,env,x)
      add(lv_obj_y,obj,x)
    end
    add(lv.env,lv_env_y,y)
    add(lv.obj,lv_obj_y,y)
  end
  return lv
end

-- end preset levels
-->8
-- inlevel
-- global var: clv

-- init, update, draw

function _initlevel(lv)
  clv=lv
end

function _updatelevel()
  if (btnp(0) or btnp(1)
      or btnp(2) or btnp(3)) then
    _updatebtnpdpad()
  end
end

function _drawlevel()
  _drawlevelall()
end

-- custom functions

function iswall(x,y)
  return (clv.env[y][x] == 1)
end

function isoutsidelv(x,y)
  return ((x < 1) or (x > clv.siz.x)
          or (y < 1) or (y > clv.siz.y))
end

-- update only if any dpad button is pressed
function _updatebtnpdpad()
  local nx=clv.usr.x
  local ny=clv.usr.y
  local nx2=nx
  local ny2=ny
  local cant_move=0
  local is_push=0
  if btnp(0) then -- left
    clv.usrface=0
    nx-=1
    nx2-=2
  elseif btnp(1) then -- right
    clv.usrface=1
    nx+=1
    nx2+=2
  elseif btnp(2) then -- up
    clv.usrface=2
    ny-=1
    ny2-=2
  elseif btnp(3) then -- down
    clv.usrface=3
    ny+=1
    ny2+=2
  end
  -- detect outside map
  if (isoutsidelv(nx,ny)) cant_move=1
  -- detect wall collision
  if (cant_move == 0
      and (iswall(nx,ny))) then
    cant_move=1
  end
  -- next position is obj
  if (cant_move == 0
      and clv.obj[ny][nx] > 0) then
    -- detect out of map
    if (isoutsidelv(nx2,ny2)) cant_move=1
    -- detect wall collision
    if (cant_move == 0
      and iswall(nx2,ny2)) then
      cant_move=1
    end
    -- detect if reach target
    if (cant_move == 0) then
      is_push=1
      -- compute remain targets
      if (clv.env[ny][nx] != 2
          and clv.env[ny2][nx2] == 2) then
        clv.cnt-=1
      end
      if (clv.env[ny][nx] == 2
          and clv.env[ny2][nx2] != 2) then
        clv.cnt+=1
      end
    end
  end
  -- move usr and obj
  if (cant_move == 0) then
    clv.usr.x=nx
    clv.usr.y=ny
    if (is_push == 1) then
      clv.obj[ny2][nx2]=clv.obj[ny][nx]
      clv.obj[ny][nx]=0
    end
  end
end

-- clean and redraw all elements
function _drawlevelall()
  cls()
  -- draw env (layer 2-wall 3-target)
  map(clv.x0,clv.y0,0,0,clv.siz.x,clv.siz.y,6)
  for y=1,clv.siz.y do
    for x=1,clv.siz.x do
      local x0=(x-1)*8
      local y0=(y-1)*8
      -- draw obj
      if (clv.obj[y][x] != 0) then
        spr(clv.obj[y][x]+15,x0,y0)
      end
    end
  end
  -- draw usr
  spr(32+clv.usrface,(clv.usr.x-1)*8,(clv.usr.y-1)*8)
  -- draw win
  if (clv.cnt == 0) then
    print("\#2you win!",0,0)
  end
end

-- end inlevel
-->8
-- menu
-- global var: mn

-- init, update, draw

function _initmenu()
  mn={
    itm={"start", "level 1"},
    pos={x=5,y=5},
    sel=1,
    lvmax=5,
    lv=1,
  }
end

function _updatemenu()
  -- navigate with up/down
  if btnp(2) then
    mn.sel-=1
    if (mn.sel < 1) mn.sel=1
  end
  if btnp(3) then
    mn.sel+=1
    if (mn.sel > #mn.itm) mn.sel=#mn.itm
  end
  -- conditional action
  if (mn.sel == 1) then
    if btnp(5) then
      -- enter level
      _menu2level(mn)
    end
  elseif (mn.sel == 2) then
    -- next level
    if (btnp(5) or btnp(1)) then
      if (mn.lv < mn.lvmax) then
        mn.lv+=1
      else
        mn.lv=1
      end
      mn.itm[2]="level "..mn.lv
    end
    if (btnp(0)) then
      if (mn.lv > 1) then
        mn.lv-=1
      else
        mn.lv=mn.lvmax
      end
      mn.itm[2]="level "..mn.lv
    end
  end
end

function _drawmenu()
  cls()
  for i=1,#mn.itm do
    if (mn.sel == i) then
      print("> "..mn.itm[i],
            mn.pos.x*8, (mn.pos.y+i)*8)
    else
      print("  "..mn.itm[i],
            mn.pos.x*8, (mn.pos.y+i)*8)
    end
  end
end

-- end menu
__gfx__
00000000666666660000000000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660555555000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700666666660500005000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000666666660500005000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000666666660500005000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700666666660500005000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660555555000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666660000000000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06500660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06056060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06065060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06600560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880088888800888888008888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880088888800818818008888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08181880088181800818818008888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08181880088181800888888008188180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880088888800888888008188180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880088888800888888008888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0002040802000000000000000000000008010101000000000000000000000000010101010100000000000000000000000204000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010104040404040404040404040404040404010101010101010101010101010101010404040404040404040404040404040401010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000000000000000000000000000004010000000000000000000000000000010400000000000000000000000000000401000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000000000000000000000000000004010000000000000000000000000000010400000000000000000000000000000401000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000000000000000000000000000004010000200000000000000000000000010400000000000000000000000020000401000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000000000000000000000000000004010000000000000000000000000000010400000000000000000000000000000401000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000010000000000000000000000004010000000000001000000000000000010400000000020000000000000000000401000000000000101000100000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000000000000000000000000000004010000000000000000000000000000010400000000000000020000000000000401000000000010000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000230000000000000000000104000000000000000000000000000004010000000000000000100000000000010400000000000000000000000000000401000010000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000000000000000000000200000004010000000000000000000000000000010400000000000000000200000000000401000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000000000021000000000000000004010000000010000000000000000000010400000000100000000000000000000401000000000200000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000100000000000000000000104000000000000000000000000000004010000000000000000000000020000010400000000000010000000000000000401000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000000000000000000000000000004010000000002000002000000000000010400000000000000100000000000000401000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000020000000000000104000010000000000000020000000004010000000000000000000000000000010400000000020000000000000000000401000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000000000000000000000000000004010000000000000000000000000000010400000000000000100000000000000401000020000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000104000000000000000000000000000004010000000000000000000000000000010400000000000000000000000000000401000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010104040404040404040404040404040404010101010101010101010101010101010404040404040404040404040404040401010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
