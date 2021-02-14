-- Name: crafter.lua
-- Description: Allows the controller to store new recipes

-- Define Globals
local crafting_slots = {"1","2","3","5","6","7","9","10","11"}

local io_chest = {}
local wired_modem = {}

local storage_items = {}
local recipe_list = {}

local craft_plan = {}
local craft_step = 1

-- Define Functions
local function wrap_periferals()
	-- Wrap periferals
	local io_chest = peripheral.wrap("bottom")
	local wired_modem = peripheral.wrap("back")
	return io_chest, wired_modem
end

local function load_recipes()
	-- Load recipe list to global
	local recipe_file = fs.open("/disk/recipes.json","r")
	if recipe_file then
		recipe_list = textutils.unserialiseJSON(recipe_file.readAll())
		recipe_file.close()
		return recipe_list
	end
	
	-- Failed to load
	return false
end

local function get_items()
	-- Wraps all storage chests
	local storage_chests = {peripheral.find("ironchest:gold_chest")}
	
	-- Loops through chests and counts items
	local items = {}
	
	for _, storage_chest in pairs(storage_chests) do
		
		-- Gets current chest name
		local chest_name = peripheral.getName(storage_chest)
		
		-- Gets list of items in chest
		local chest_items = storage_chest.list()
		
		-- Loop through items and add to list
		for slot, item in pairs(chest_items) do
			
			-- Checks if item already exists in list
			if items[item.name] then
				-- Adds items to existing list
				items[item.name].totalCount = items[item.name].totalCount + item.count
				items[item.name].locations[chest_name] = {
					count = item.count,
					["slot"] = slot
				}
			else
				-- Adds items to list
				items[item.name] = {
					totalCount = item.count,
					locations = {
						[chest_name] = {
							count = item.count,
							["slot"] = slot
						}
					}
				}
			end
		end
	end
	
	return items
end

local function has_item(item_name, chest_items, new_items)
	-- Checks if the given item is in storage or has already been crafted in plan
	local found_item = nil
	
	-- Checks for item in storage
	for item_index, item_data in pairs(chest_items) do
        
		-- Store item data if found
		if item_name == item_index then
			found_item = item_data
			break
        end
    end
	
	-- Checks for item in items already crafted
	for item_index, item_count in pairs(new_items) do
		
		-- Checks if match found
		if item_name == item_index then
			
			-- If found item already exists add to count else create item
			if found_item then
				found_item.totalCount = found_item.totalCount + item_data.count
			else
				found_item = {
					totalCount = item_count
				}
			end
		end				
	end
	
	-- Return found item if found else return false
	if found_item then
		return found_item
	else
		return false
	end
end

local function get_item(item, amount, to_inventory, to_slot)
	-- Moves an amount of the given item to the given inventory
	for item_name, item_details in pairs(storage_items) do
		
		-- Check if current item matches required item
		if item == item_name then
		
			-- Check if amount is less than or equal to stored amount
			if amount > item_details.totalCount then
				return false, "Not enough of item"
			end
			
			-- Move items from storage to inventory
			local moved_count = 0
			for inventory_name, inventory_item_details in pairs(item_details.locations) do
				
				-- Calculates amount to move from current location
				local move_amount = math.min(amount - moved_count, inventory_item_details.count)
				
				local inventory = peripheral.wrap(inventory_name)
				inventory.pushItems(to_inventory, inventory_item_details.slot, move_amount, to_slot)
				moved_count = moved_count + move_amount
				
				-- Stop looking if already moved enough
				if moved_count == amount then
					return true, move_amount
				end
			end
			
			-- Exit loop
			break
		end
	end
end

function dump_item()
	-- Takes items from IO Chest and returns to storage
	-- TODO Make this smart and fill stacks etc
	local storage_chest = peripheral.wrap("ironchest:gold_chest_2")
	storage_chest.pullItems("minecraft:chest_14", 1)
end

local function get_recipe(item)
	-- Loops through recipes
	for recipe_name, value in pairs(recipe_list.recipes) do
		-- If recipe found return
		if item == recipe_name then
			return value
        end
    end
	
	-- Recipe not found returns false
	return false
end

local function can_craft(recipe, craft_amount, used_items, new_items)
	-- Checks if a recipe can be crafted with avaliable items and recipes
	for item, amount in pairs(recipe.needs) do
	
		-- Check if any items in storage
		local found_item = has_item(item, storage_items, new_items)

		if found_item then
			
			-- Gets count of item already used
			local used_count = 0
			if type(used_items[item]) == "number" then
				used_count = used_items[item]
			end
			
			if found_item.totalCount >= ((amount * craft_amount) - used_count) then
				-- Add to used_items
				if used_items[item] then
					used_items[item] = used_items[item] + (amount * craft_amount)
				else
					used_items[item] = (amount * craft_amount)
				end
			else
				-- Some in chest not enough
				print("Some "..item.." in chest but not enough logic not coded")
				return false
			end
		end
		
		-- Check if has recipe if item not found
		if found_item == false then
			local found_recipe = get_recipe(item)
			if found_recipe then
				-- Recipe found
				local needed_amount = math.ceil((amount * craft_amount) / found_recipe.result.amount)
				craft_plan[craft_step] = {
					["name"] = item,
					["amount"] = needed_amount
				}
				craft_step = craft_step + 1
				used_items, new_items = can_craft(found_recipe, needed_amount, used_items, new_items)
				if used_items == false then return false end
				
				if new_items[item] then
					new_items[item] = new_items[item] + (needed_amount * found_recipe.result.amount)
				else
					new_items[item] = (needed_amount * found_recipe.result.amount)
				end
			else
				-- Recipe not found
				print("No recipe for "..item)
				return false
			end
		end
	end
	return used_items, new_items
end

local function craft_item(craft_plan)
	-- Crafts an item given a craft plan
	
	-- Loop through craft plan
	for step, to_craft in pairs(craft_plan) do
		-- Get recipe
		local recipe = get_recipe(to_craft.name)
		
		if recipe == false then return false end
		
		-- Moves each item to turtle
		for slot, needed_item in pairs(recipe.recipe) do
			
			-- Updates item list
			storage_items = get_items()
		
			-- Move item to IO Chest
			get_item(
				needed_item,
				to_craft.amount,
				"minecraft:chest_14",
				1)
			
			-- Turtle picks item out of chest
			turtle.select(tonumber(slot))
			turtle.suckDown(to_craft.amount)
		end
		
		turtle.select(16)
		turtle.craft(to_craft.amount)
		
		local crafted_item = turtle.getItemDetail(16, false)
	
		if crafted_item.name == recipe.result.name then
			turtle.select(16)
			turtle.dropDown()
			dump_item()
			storage_items = get_items()
		else
			print("Failed to craft "..to_craft.name)
			return false
		end
	end
end

local function craft(item, amount, reply_channel, modem) 
	
	-- Wrap peripherals
	io_chest, wired_modem = wrap_periferals()
	
	-- Loads items in storage and recipes
	storage_items = get_items()
	recipe_list = load_recipes()
	
	-- Get recipe
	local recipe = get_recipe(item, recipe_list)
	
	-- Generate craft plan
	success, _ = can_craft(recipe, 1, {}, {})
	
	if success == false then 
		print("Can't craft")
		return
	end
	
	craft_plan[craft_step] = {
		["name"] = recipe.result.name,
		["amount"] = 1
	}
	print(textutils.serialize(craft_plan))
	
	-- Craft craft plan
	craft_item(craft_plan)
	
	-- Clear craft plan
	craft_plan = {}
	craft_step = 1
end

return {craft = craft}