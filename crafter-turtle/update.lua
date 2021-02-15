-- Name: update.lua
-- Description: Update script for crafter turtle.
--              Deletes and downloads latest required 
--              programs.

-- Load Config
local file = fs.open("/disk/config.json", "r")

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
	{base_url.."/crafter-turtle/main-craft.lua", "/crafter-turtle/main-craft.lua"},
	{base_url.."/crafter-turtle/crafter.lua", "/crafter-turtle/crafter.lua"},
	{base_url.."/crafter-turtle/update.lua", "/crafter-turtle/update.lua"},
	{base_url.."/crafter-turtle/startup", "/startup"},
	{base_url.."/apis/storage.lua", "/crafter-turtle/storage.lua"}
}

for _, program in pairs(programs) do
	-- Update User
	print("Updating "..program[2])
	-- Delete Existing 
	shell.run("rm", program[2])
	-- Download Latest Program
	shell.run("wget", program[1], program[2])
end