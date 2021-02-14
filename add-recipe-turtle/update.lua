-- Name: update.lua
-- Description: Update script for add recipe turtle.
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
	{base_url.."/add-recipe-turtle/add-recipe.lua", "/add-recipe-turtle/add-recipe.lua"},
	{base_url.."/add-recipe-turtle/update.lua", "/add-recipe-turtle/update.lua"},
	{base_url.."/add-recipe-turtle/startup", "/startup"}
}

for _, program in pairs(programs) do
	-- Update User
	print("Updating "..program[2])
	-- Delete Existing 
	shell.run("rm", program[2])
	-- Download Latest Program
	shell.run("wget", program[1], program[2])
end