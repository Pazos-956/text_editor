require "globals"

Original = {}
New = {}

local function start_ptable()
  local tabla = {
    ["file"] = "original",
    ["start"] = 1,
    ["length"] = #Original
  }
  Ptable = {{}}
  Ptable[1] = tabla
end

local function clean_table()
  if Ptable ~= nil then
    local i = 1
    while i ~= #Ptable do
      if Ptable[i]["file"] == Ptable[i+1]["file"] then
        if Ptable[i]["length"] + Ptable[i]["start"] == Ptable[i+1]["start"] then
          Ptable[i]["length"] = Ptable[i+1]["length"] + Ptable[i]["length"]
          table.remove(Ptable, i+1)
        else i=i+1
        end
      else i=i+1
      end
    end
  end
end

local function find_one_piece() -- referencia
  local piece_pos = 1
  local until_piece = 0 -- Tamaño de las piezas anteriores, para calcular la división de una pieza
  local position = Ptable[1]["length"]
  while position < Char_count do
    piece_pos = piece_pos+1
    position = position + Ptable[piece_pos]["length"]
    until_piece = until_piece + Ptable[piece_pos-1]["length"]
  end
  return piece_pos, until_piece
end

function Insert(char)
  New[#New+1] = char
  local new_piece = {
    ["file"] = "new",
    ["start"] = #New,
    ["length"] = 1
  }
  if Cursor_y == 1 and Cursor_x == 1 then
    for i=#Ptable, 1,-1 do
      Ptable[i+1] = Ptable[i]
    end
    Ptable[1] = new_piece
  else
    local piece_number, until_piece = find_one_piece()
    local cursor_pos = Char_count - until_piece
    local second_piece = {
      ["file"] = Ptable[piece_number]["file"],
      ["start"] = Ptable[piece_number]["start"] + cursor_pos,
      ["length"] = Ptable[piece_number]["length"] - cursor_pos
    }
    Ptable[piece_number]["length"] = cursor_pos
    if second_piece["length"] == 0 then -- Evitas meter piezas con tamaño 0
      for i=#Ptable, piece_number+1,-1 do
        Ptable[i+1] = Ptable[i]
      end
      Ptable[piece_number+1] = new_piece
    else
      for i=#Ptable, piece_number+1,-1 do
        Ptable[i+2] = Ptable[i]
      end
      Ptable[piece_number+1] = new_piece
      Ptable[piece_number+2] = second_piece
    end
  end
  if char == "\r\n" then
    local handler = Total_rows[Cursor_y]
    Total_rows[Cursor_y] = Cursor_x - 1
    table.insert(Total_rows, Cursor_y+1, handler-Total_rows[Cursor_y])
  else
    Total_rows[Cursor_y] = Total_rows[Cursor_y] + 1
  end
  clean_table()
end

function Delete()
  local piece_number, until_piece = find_one_piece()
  local tabla
  local cursor_pos = Char_count - until_piece
  local first_piece = {
    ["file"] =  Ptable[piece_number]["file"],
    ["start"] =  Ptable[piece_number]["start"],
    ["length"] = cursor_pos - 1
  }
  local second_piece = {
    ["file"] = Ptable[piece_number]["file"],
    ["start"] = Ptable[piece_number]["start"] + cursor_pos,
    ["length"] = Ptable[piece_number]["length"] - cursor_pos
  }
  if Ptable[piece_number]["length"] == 1 then
    for i=piece_number, #Ptable do
      Ptable[i] = Ptable[i+1]
    end
  else
    Ptable[piece_number]["length"] = first_piece["length"]
    if first_piece["length"] == 0 then
      Ptable[piece_number] = second_piece
    elseif second_piece["length"] ~= 0 then -- Evitas meter piezas con tamaño 0
      for i=#Ptable, piece_number+1,-1 do
        Ptable[i+1] = Ptable[i]
      end
      Ptable[piece_number+1] = second_piece
    end
  end
  if Ptable[piece_number]["file"] == "original" then
      tabla = Original
    else
      tabla = New
  end
    if tabla[Ptable[piece_number]["start"]+Ptable[piece_number]["length"]] == "\r\n" then
      Cursor_y = Cursor_y - 1
      Cursor_x = Total_rows[Cursor_y]+1
      Total_rows[Cursor_y] = Total_rows[Cursor_y] + Total_rows[Cursor_y+1]
      table.remove(Total_rows,Cursor_y+1)
    else
      Cursor_x = Cursor_x - 1
      Total_rows[Cursor_y] = Total_rows[Cursor_y] - 1
    end
  clean_table()
end

function Fill_original()
  local file = arg[1]
  local y = 1
  local readfile = io.open(file, "r")
  if readfile == nil then error("readfile is null") end
  local i = 1
  local rowfile = {}
  while true do
    rowfile[i] = readfile:read("*l")
    if rowfile[i]== nil then break end
    Total_rows[i] = #rowfile[i]
    for char in string.gmatch(rowfile[i], ".") do
      Original[y] = char
      y=y+1
    end
    Original[y] = "\r\n"
    y=y+1
    i = i+1
  end
  start_ptable()
end

function String_of_table()
  local string_file = ""
  local tabla
  for i=1, #Ptable do
    local start = Ptable[i]["start"]
    local length = Ptable[i]["length"]
    if Ptable[i]["file"] == "original" then
      tabla = Original
    else
      tabla = New
    end
    for y=start, start + length-1 do
      string_file = string_file .. tabla[y]
    end
  end
  return string_file
end


function Fill_rowfile()
  if Ptable == nil then Fill_original() end
  local tabla
  local rowfile = {}
  local str = ""
  local rows = 1
  for i=1, #Ptable do
    local start = Ptable[i]["start"]
    local length = Ptable[i]["length"]
    if Ptable[i]["file"] == "original" then
      tabla = Original
    else
      tabla = New
    end
    for y=start, start + length-1 do
      if tabla[y] == "\r\n" then
        rowfile[rows] = str
        rows = rows+1
        str = ""
      else
        str = str .. tabla[y]
      end
    end
    rowfile[rows] = str
  end
  return rowfile
end
