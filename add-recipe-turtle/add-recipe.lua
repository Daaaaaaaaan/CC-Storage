modem = nil

function init_modem()

	-- Wrap modem
	modem = peripheral.wrap("right")
	modem.open(1)
end

function draw_screen()
	
	-- Clear the screen
	term.clear()
	term.setTextColour(colors.lime)
	
	-- Write Title
	term.setCursorPos(1,1)
	term.write("Add Recipe")

	-- Write Top Border Line
	term.setTextColour(colors.white)
	term.setCursorPos(1,2)
	term.write(string.rep("-", 39))

	-- Write Instructions
	term.setTextColour(colors.lime)
	term.setCursorPos(1,3)
	term.write("Draw recipe then press enter")

	-- Write Bottom Border Line
	term.setTextColour(colors.white)
	term.setCursorPos(1,13)
	term.write(string.rep("-", 39))
end

function show_success(recipe)
	-- Display success message
	term.setTextColour(colors.lime)
	term.setCursorPos(1,11)
	term.write("Stored "..recipe.result.name)
	term.setCursorPos(1,12)
	term.write("Press enter to continue")
end

function show_error(reason)
	-- Display error message
	term.setTextColour(colors.red)
	term.setCursorPos(1,11)
	term.write(reason)
	term.setCursorPos(1,12)
	term.write("Press enter to continue")
end

function check_inventory()

	local item = nil
	local foundItem = false
	for i = 1,16,1 do
		item = turtle.getItemDetail(i)
		if item then
			foundItem = true
			
			if item.count > 1 then
				return false, "Multiple items in slot "..i
			end
		end
	end
	
	if item then
		return false, "Item in result slot (16)"
	end
	
	if foundItem == false then
		return false, "No items found"
	end
	
	return true, "Success"
end

function add_recipe()

	recipe = {}
	recipe['recipe'] = {}
	recipe['needs'] = {}
	recipe['result'] = {}
	
	for i = 1,16,1 do
		if i % 4 ~= 0 and math.floor(i / 4) <= 2 then
			local item = turtle.getItemDetail(i)
			if item then
				recipe.recipe[tostring(i)] = item.name
				if recipe.needs[item.name] then
					recipe.needs[item.name] = recipe.needs[item.name] + 1
				else
					recipe.needs[item.name] = 1
				end
			end
		end	
	end

	turtle.select(16)
	turtle.craft(1)

	local result = turtle.getItemDetail(16)
	if result then
		recipe.result['name'] = result.name
		recipe.result['amount'] = turtle.getItemCount(16)
		
		-- Open and read existing recipes.json file
		local recipe_file, err = fs.open("/disk/recipes.json","r")
		
		-- Read and close file then serialize json if exists
		if recipe_file then
			local recipe_list = textutils.unserialiseJSON(recipe_file.readAll())
			recipe_file.close()
		else
			return false, err
		end
		
		-- Refresh the list if contains invalid json or first run
		if recipe_list == nil then
			recipe_list = {
				recipes = {}
			}
		end

		-- Add recipe to recipe list
		recipe_list.recipes[recipe.result.name] = recipe
		
		-- Serialize Rcipe List
		local result = {pcall(textutils.serialiseJSON, recipe_list)}
		
		-- Check serialise result
		local raw_recipe_list = nil
		if result[1] then
			raw_recipe_list = result[2]
		else
			return false, result[2]
		end

		-- Open recipe file for write
		local recipe_file, err = fs.open("/disk/recipes.json","w")
		
		-- Check success and write to file
		if recipe_file then
			recipe_file.write(raw_recipe_list)
			recipe_file.close()
		else
			return false, err
		end

		-- Return result
		return true, recipe
	else
		return false, "Not a recipe"
	end
end

function process_request()
	-- Check if user has entered anything
	local success, reason = check_inventory()
	
	if success then
		return add_recipe()
	else
		return false, reason
	end
end

function waitForEnter()
	-- Waits for press of enter key event
	local key = 0
	while key ~= keys.enter do
		_, key, _ = os.pullEvent("key")
	end
end

function main()

	-- Setup modem
	init_modem()
	
	while true do

		-- Draw GUI
		draw_screen()

		-- Wait for user to press enter
		waitForEnter()
		
		-- Adds recipe to system
		success, result = process_request()
		
		-- Updates GUI
		if success then
			show_success(result)
			waitForEnter()
		else
			show_error(result)
			waitForEnter()
		end
	end
end

main()