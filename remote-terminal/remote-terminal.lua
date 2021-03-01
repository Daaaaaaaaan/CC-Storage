-- Name: remote-terminal.lua
-- Description: Controls the remote terminal GUI and sends
--              requests to the server.

-- Require Modules
local gui = require("gui")

-- Define globals
local modem = nil

-- Define Functions
function init_modem()

	-- Wrap modem
	modem = peripheral.wrap("back")
	modem.open(3)
end

function search_items(search)
	-- Get results from server
	local request = {
		["type"] = "items_search",
		["search"] = search
	}
	modem.transmit(0, 3, textutils.serializeJSON(request))

	local event, side, channel, replyChannel, res, distance = os.pullEvent("modem_message")
	res = textutils.unserializeJSON(res)

	-- Clears results area
	results_window.clear()

	if res.status == "Success" then
		
		return true, res.results
	else
		return false, res.status
	end
end

function create_home_screen()
	
	local home_screen = gui.Screen.new("home_screen", term, colours.lightGray)

	local craft_button = gui.Button.new(
		"craft_button",
		" Craft ",
		function (screen)
			-- Navigates to crafting screen
			screen.pushScreen(create_craft_screen())
		end,
		2,
		1)
	home_screen.add(craft_button)

	local dump_button = gui.Button.new(
		"dump_button",
		" Dump ",
		function (screen)
			-- Dumps inventory to storage
			
		end,
		11,
		1)
	home_screen.add(dump_button)

	local search_label = gui.Label.new("search_label", "Search:", 1, 3)
	home_screen.add(search_label)

	local search_box = gui.TextBox.new(
		"search_box",
		"",
		2,
		4,
		24,
		false,
		function (screen, text)
			-- On text changed
			
			-- Get search results
			local success, results = search_items(text)
			
			-- Update stored results
			if success then
				-- Store results in screen table
				screen.search_results = results

				-- Create displayable results list
				local display_results = {}
				for id, details in pairs(results) do
					display_results[#display_results + 1] = details.displayName
				end

				-- Update resulrs on screen
				screen.get("search_box").values = display_results
				screen.draw()
			else
				-- Display error
				screen.get("message_holder").text = results
			end
		end)
	home_screen.add(search_box)

	local results_label = gui.Label.new("results_label", "Results:", 1, 6)
	home_screen.add(results_label)

	local results_box = gui.List.new(
		"results_list",
		{},
		2,
		7,
		24,
		13,
		function (screen, row)
			-- Launch Item details screen
			screen.pushScreen(create_item_details_screen(row))
		end)
	home_screen.add(results_box)

	local message_label = gui.Label.new("message_label", "Message: ", 1, 20)
	home_screen.add(message_label)

	local message_holder = gui.Label.new("message_holder", "", 10, 20)
	home_screen.add(message_holder)
	
	return home_screen
end

function create_craft_screen()
	
	local craft_screen = gui.Screen.new("craft_screen", term, colours.lightGray)

	local back_button = gui.Button.new(
		"back_button",
		" Back ",
		function (screen)
			-- Returns to previous screen
			screen.popScreen()
		end,
		2,
		1)
	craft_screen.add(back_button)

	local search_label = gui.Label.new("craft_label", "Craft Screen", 2, 3)
	craft_screen.add(search_label)

	return craft_screen
end

function create_item_details_screen(row)
	
	local item_details_screen = gui.Screen.new("item_details_screen", term, colours.lightGray)

	local back_button = gui.Button.new(
		"back_button",
		" Back ",
		function (screen)
			-- Returns to previous screen
			screen.popScreen()
		end,
		2,
		1)
		item_details_screen.add(back_button)

	local title_label = gui.Label.new("title_label", "Item Details Screen", 2, 3)
	item_details_screen.add(title_label)

	local item_label = gui.Label.new("item_label", row, 2, 3)
	item_details_screen.add(item_label)

	return item_details_screen
end

function main()
	
	-- Inits
	init_modem()

	-- Get home screen
	local home_screen = create_home_screen()
	
	-- Start event loop
	home_screen.run()
end

-- Call main function
main()