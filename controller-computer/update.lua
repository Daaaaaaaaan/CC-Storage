-- Name: update.lua
-- Description: Updates the required programs for this
--              computer.

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
	{base_url.."/controller-computer/startup", "/startup"},
	{base_url.."/controller-computer/update.lua", "/controller-computer/update.lua"},
	{base_url.."/controller-computer/add-recipe.lua", "/controller-computer/add-recipe.lua"},
	{base_url.."/controller-computer/main-controller.lua", "/controller-computer/main-controller.lua"},
	{base_url.."/apis/storage.lua", "/controller-computer/storage.lua"}
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