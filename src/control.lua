require "globals"
require "input"
require "piece_table"

local ctrl = 1
local arrows = 10
local letter = 0
local unknown = -1

local function save_file()
  local file = String_of_table()
  if file ~= nil then
    if arg[1] then
      local handler = io.open(arg[1], "w+")
      if handler ~= nil then
        handler:write(file)
        handler:close()
      end
    else
      local handler = io.open("newfile.txt", "w+")
      if handler ~= nil then
        handler:write(file)
        handler:close()
      end
    end
  end
end

local function move_cursor(key)
  if key == "A" then -- Arriba
    if Cursor_y > 1 then
      Cursor_y = Cursor_y - 1
      if Last_x <= Total_rows[Cursor_y] then
        Char_count = Char_count - Cursor_x - Total_rows[Cursor_y] + Last_x - 1
        Cursor_x = Last_x
      else
        Char_count = Char_count - Cursor_x
        Cursor_x = Total_rows[Cursor_y]+1
      end
    end
  elseif key == "B" then -- Abajo
    if Cursor_y < #Total_rows then
      if Last_x <= Total_rows[Cursor_y+1] then
        Char_count = Char_count - Cursor_x + Total_rows[Cursor_y] + Last_x + 1 -- El \n
        Cursor_x = Last_x
      else
        Char_count = Char_count - Cursor_x + Total_rows[Cursor_y] + Total_rows[Cursor_y+1] + 2
        Cursor_x = Total_rows[Cursor_y+1]+1
      end
      Cursor_y = Cursor_y+1
    end
  elseif key == "C" then -- Derecha
    if Cursor_x < Total_rows[Cursor_y]+1 then
      Cursor_x = Cursor_x + 1
      Last_x = Cursor_x
      Char_count = Char_count + 1
    end
  elseif key == "D" then -- Izquierda
    if Cursor_x > 1 then
      Cursor_x = Cursor_x - 1
      Last_x = Cursor_x
      Char_count = Char_count - 1
    end
  end
end

function Control_input ()
  local _, err = pcall(function ()
    local key
    while true do
      local key_byte, chk = key_input()
      if key_byte > 127 or key_byte < 0 then -- Arreglo temporal, solo acepta ascii original
        key = "ñ"
        key_input()
      else
        key = string.char(key_byte)
      end
      if chk == letter then
        Insert(key)
        Cursor_x = Cursor_x + 1
        Last_x = Cursor_x
        Char_count = Char_count + 1
      elseif chk == arrows then
        move_cursor(key)
      elseif chk == ctrl then
        if key_byte == 3 then break
        elseif key_byte == 19 then
          save_file()
        elseif key_byte == 9 then
          for i=1, 4 do
            Insert(" ")
          end
          Cursor_x = Cursor_x + 4
          Last_x = Cursor_x
          Char_count = Char_count + 4
        elseif key_byte == 127 then
          if Cursor_x ~= 1 or Cursor_y ~= 1 then
            Delete()
            Char_count = Char_count - 1
            Last_x = Cursor_x
          end
        elseif key_byte == 13 then
          key = "\r\n"
          Insert(key)
          Char_count = Char_count + Total_rows[Cursor_y] - Cursor_x + 2 -- \n y Cursor_x empieza en 1
          Cursor_y = Cursor_y + 1
          Cursor_x = 1
          Last_x = Cursor_x
        end
      elseif chk == unknown then
        error("key is unknown")
      end
      Refresh_screen()
    end
  end)
  if err ~= nil then
    print(err)
  end
end
