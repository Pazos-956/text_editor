require "screen"
require "control"

local _, err = pcall(function()
  os.execute("stty -icanon -echo -isig -ixon -icrnl -opost")
  Draw_editor()
  Control_input()
  io.write("\x1b[2J")
  io.write("\x1b[H")
end)
os.execute("stty icanon echo isig ixon icrnl opost")

if err ~= nil then print(err) end
