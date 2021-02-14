-- Name: add-recipe.lua
-- Description: Allows the controller to store new recipes

local function add_recipe(req, reply_channel, modem, monitor) 
	
	-- Open and read existing recipes.json file
	local recipeFile = fs.open("/disk/recipes.json","r")
	
	-- Read and close file then serialize json if exists
	if recipeFile then
		local recipeList = textutils.unserialiseJSON(recipeFile.readAll())
		recipeFile.close()
	end
	
	-- Refresh the list if contains invalid json or first run
	if recipeList == nil then
		recipeList = {
			recipes = {}
		}
	end
	
	-- Get recipe from request
	recipe = req.recipe	
	
	-- Add recipe to recipe list
	recipeList.recipes[recipe.result.name] = recipe
	
	-- Write recipe list to file
	local recipeFile = fs.open("/disk/recipes.json","w")
	recipeFile.write(textutils.serialiseJSON(recipeList))
	recipeFile.close()
	
	-- Update display
	_, y = monitor.getCursorPos()
	monitor.setCursorPos(1,y + 1)
	monitor.write("Recipe added "..req.recipe.result.name)

	-- Create response
	local res = textutils.serializeJSON(
		{["status"] = "Success"}
	)
	
	-- Send response to client
	modem.transmit(reply_channel, 0, res)
end

return {add_recipe = add_recipe}