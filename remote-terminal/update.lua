-- Name: update.lua
-- Description: Updates the required programs for this
--              computer.

-- Load Config
local file = fs.open("/config.json", "r")

-- Check if file is avaliable
local config = nil
if file then
	config = textutils.unserializeJSON(file.readAll())
	file.close()
else
	error("Update Failed - Failed to load config.json")
end

-- Create Base URL
local base_url = "https://raw.githubusercontent.com/Daaaaaaaaan/CC-Storage/"..config.branch

-- Define Programs 
local programs = {
	{base_url.."/remote-terminal/startup", "/startup"},
	{base_url.."/remote-terminal/update.lua", "/remote-terminal/update.lua"},
	{base_url.."/remote-terminal/remote-terminal.lua", "/remote-terminal/remote-terminal.lua"}
}

-- Loops through required programs
for _, program in pairs(programs) do
	-- Update User
	print("Updating "..program[2])
	-- Delete Existing 
	shell.run("rm", program[2])
	-- Download Latest Program
	shell.run("wget", program[1], program[2])
end