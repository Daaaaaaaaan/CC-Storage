-- Name: main-controller.lua
-- Description: Main controller program for computer system
--              containing the event handling.

-- Require Modules
local add_recipe = require("add-recipe")
local storage = require("storage")

-- Define globals
local recipe_list = nil
local items = nil
	
-- Define Functions
local function init_modem()
	-- Init Modem
	modem = peripheral.wrap("right")
	modem.open(0)
	return modem
end

local function init_monitor()
	-- Init Monitor
	monitor = peripheral.wrap("monitor_0")
	monitor.clear()
	return monitor
end

local function load_recipes()
	-- Load recipe list to global
	local recipe_file = fs.open("/controller-computer/recipes.json","r")
	if recipe_file then
		recipe_list = textutils.unserialiseJSON(recipe_file.readAll())
		recipe_file.close()
	end
end

local function handle_click(event_data, modem, monitor)
	-- TODO: Implement handling
end

local function handle_packet(event_data, modem, monitor)
	-- Parse event data
	local channel = event_data[3]
	local reply_channel = event_data[4]
	local raw_message = event_data[5]
	
	-- Unserialize JSON message
	local req = textutils.unserializeJSON(raw_message)
	
	-- If exists check type and action 
	if req then
		if req.type == "add_recipe" then
			-- Add recipe packet
			add_recipe.add_recipe(req, reply_channel, modem, monitor)
			load_recipes()
		elseif req.type == "get_recipe" then
			-- Get recipe packet
			local response = {
				status = "Success",
				recipe = recipe_list.recipes[req.item]
			}
			local raw_response = textutils.serializeJSON(response)
			
			-- Send
			modem.transmit(reply_channel, 0, raw_response)
		elseif req.type == "items_search" then
			-- Finds matching items
			local search = req.search
			
			local results = {}
			local result_count = 0
			for key, value in pairs(items) do
				
				if result_count == 13 then
					break
				end
				
				if (string.sub(value.displayName, 1, #search) == search) == true then
					results[key] = value
					result_count = result_count + 1
				end
			end

			-- Returns search results
			local response = {
				status = "Success",
				["results"] = results
			}
			local raw_response = textutils.serializeJSON(response)
			
			-- Send
			modem.transmit(reply_channel, 0, raw_response)
		
		elseif req.type == "get_item" then
			-- Moves item from storage to main io chest
			local success, amount = storage.get_item(req.item, req.amount, items, "minecraft:chest_11", nil)	
			print(amount)
			
			local response = nil
			if success then
				-- Return success response
				response = {
					status = "Success"
				}
			else
				-- Return fail response
				response = {
					status = "Failed",
					["amount"] = amount
				}
			end
			
			-- Send
			local raw_response = textutils.serializeJSON(response)
			modem.transmit(reply_channel, 0, raw_response)
		elseif req.type == "craft_item" then
			-- Sends craft request to crafting turtle
			local request = {
				["type"] = "craft_item",
				["item"] = item_clicked,
				["amount"] = 1
			}
			modem.transmit(2, 0, textutils.serializeJSON(request))
			
			local event, side, channel, replyChannel, res, distance = os.pullEvent("modem_message")
			res = textutils.unserializeJSON(res)
	
			-- Return fail response
			if res.status == "Success" then
				-- Return success response
				response = {
					status = "Success"
				}
			else
				-- Return fail response
				response = {
					status = "Failed"
				}
			end
			
			modem.transmit(reply_channel, 0, textutils.serializeJSON(request))
		else
			-- Unknown packet type no action
			print("Unknown packet type")
		end
	end
end

local function main()
	
	-- Setup
	local modem = init_modem()
	local monitor, row = init_monitor()
	
	load_recipes()
	items = storage.get_items()
	
	-- Main Event Loop
	while true do

		-- Wait for any event
		local event_data = {os.pullEvent()}
		local event = event_data[1]
		
		if event == "mouse_click" then
			-- Handle Click
			handle_click(event_data, modem, monitor)
		elseif event == "modem_message" then 
			-- Handle Packet
			handle_packet(event_data, modem, monitor)
		end
	end
end

-- Call main function
main()