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

function create_home_screen()
	
	local home_screen = gui.Screen.new("home_screen", term, colours.lightGray)

	local craft_button = gui.Button.new("craft_button", " Craft ", nil, 2, 1)
	home_screen.add(craft_button)

	local search_label = gui.Label.new("search_label", "Search:", 1, 3)
	home_screen.add(search_label)

	local search_box = gui.TextBox.new("search_box", "", 2, 4, 24, false)
	home_screen.add(search_box)

	local results_label = gui.Label.new("results_label", "Results:", 1, 6)
	home_screen.add(results_label)

	local results_box = gui.List.new("results_list", {}, 2, 7, 24, 13)
	home_screen.add(results_box)

	local message_label = gui.Label.new("message_label", "Message: ", 1, 20)
	home_screen.add(message_label)

	local message_holder = gui.Label.new("message_holder", "", 10, 20)
	home_screen.add(message_holder)
	
	return home_screen
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