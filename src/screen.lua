require "globals"
require "piece_table"
require "control"


local function draw_file()
  local rowfile
  local start_row = Row_offset + 1
  local end_row = Row_offset + Row_screen
  local start_page = "\x1b[H"
  rowfile = Fill_rowfile()
  for i=start_row, end_row-1 do
    start_page = start_page .. "\x1b[K"
    if rowfile[i] ~= nil then
      start_page = start_page .. rowfile[i] .. "\r\n"
    else
      start_page = start_page .. "~\r\n"
    end
  end
  if rowfile[end_row] == nil then
    start_page = start_page .. "\x1b[K"
    start_page = start_page .. "~"
  else
    start_page = start_page .. rowfile[end_row]
  end
  start_page = start_page .. "\x1b["..Cursor_y-Row_offset..";"..Cursor_x.."H"
  io.write(start_page)
  io.flush()
end

function Draw_editor()
  local start_page = "\x1b[H"
  local handler = io.popen("tput lines")
  if handler ~= nil then
    Row_screen = tonumber(handler:read('*l'))
    handler:close()
  else error("handler nil") end
  handler = io.popen("tput cols")
  if handler ~= nil then
    Col_screen = tonumber(handler:read('*l'))
    handler:close()
  else error("handler nil") end
  local file = arg[1] or "newfile.txt"
  local readfile = io.open(file, "r")
  if file == nil or readfile == nil then
    Ptable = {{
      ["file"] = "new",
      ["start"] = 1,
      ["length"] = 0}}
      for i=1, Row_screen-1 do
        start_page = start_page .. "\x1b[K"
        start_page = start_page .. "~\r\n"
      end
      start_page = start_page .. "~" .. "\x1b[H"
      io.write(start_page)
      io.flush()
    else
      draw_file()
    end
end


local function editor_scroll()
  if Cursor_y <= Row_offset then
    Row_offset = Cursor_y-1
  end
  if Cursor_y > Row_offset + Row_screen then
    Row_offset = Cursor_y - Row_screen
  end
end


function Refresh_screen()
  editor_scroll()
  draw_file()
end
