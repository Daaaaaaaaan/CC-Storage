-- Name: startup.lua
-- Description: Startup script for remote terminal.
--              Deletes and downloads latest required 
--              programs then runs remote-terminal.lua

-- Define Programs 
local programs = {
	{"", "/startup"},
	{"", "/remote-terminal/remote-terminal.lua"}
}

-- Loops through required programs
for _, program in pairs(programs) do
	-- Update User
	print("Updating "..program[2])
	-- Delete Existing 
	shell.run("rm", program[2])
	-- Download Latest Program
	shell.run("pastebin", "get", program[1], program[2])
end
    
-- Run Startup Script
shell.run("/remote-terminal/remote-terminal.lua")