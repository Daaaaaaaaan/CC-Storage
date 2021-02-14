-- Name: remote-terminal.lua
-- Description: Controls the remote terminal GUI and sends
--              requests to the server.

-- Require Modules

-- Define globals
local modem = nil

-- Define Functions
function init_modem()

	-- Wrap modem
	modem = peripheral.wrap("back")
	modem.open(3)
end

local function draw_home()
	
	-- Refresh screen
	term.setTextColour(colors.white)
	term.setBackgroundColour(colors.lightGray)
	term.clear()
	
	-- Draw buttons
	term.setBackgroundColour(colors.red)
	term.setCursorPos(2,1)
	term.write(" Home ")
	term.setCursorPos(9,1)
	term.write(" Craft ")
	
	-- Draw search heading
	term.setBackgroundColour(colors.lightGray)
	term.setCursorPos(1,3)
	term.write("Search:")
	
	-- Create search bar window
	local search_window = window.create(term.current(), 2, 4, 24, 1, true)
	search_window.setBackgroundColour(colors.white)
	search_window.setTextColour(colors.black)
	search_window.clear()
	
	-- Draw results heading
	term.setBackgroundColour(colors.lightGray)
	term.setTextColour(colors.white)
	term.setCursorPos(1,6)
	term.write("Results:")
	
	-- Create results area window
	local results_window = window.create(term.current(), 2, 7, 24, 13, true)
	results_window.setBackgroundColour(colors.white)
	results_window.setTextColour(colors.black)
	results_window.clear()
	
	-- Draw message heading
	term.setBackgroundColour(colors.lightGray)
	term.setTextColour(colors.white)
	term.setCursorPos(1,20)
	term.write("Message: ")
	
	-- Create message area window
	local message_window = window.create(term.current(), 10, 20, 14, 1, true)
	message_window.setBackgroundColour(colors.lightGray)
	term.setTextColour(colors.white)
	message_window.clear()
	
	return search_window, results_window, message_window
end 

local function main()
	
	-- Inits
	
	-- Draw home screen
	local search = ""
	local displayed_search = ""
	local results = {}
	
	init_modem()
	local search_window, results_window, message_window = draw_home()
	
	while true do
		local event_data = {os.pullEvent()}
		
		if event_data[1] == "char" then
			-- Add character to search
			search = search..event_data[2]
		elseif event_data[1] == "key" then
			-- Catch backspacek
			local key = keys.getName(event_data[2])
			if key == "backspace" then
				search = string.sub(search, 1, -2)
			end
		elseif event_data[1] == "mouse_click" and event_data[2] == 1 then
			-- Mouse clicked on screen
			local click_x = event_data[3]
			local click_y = event_data[4]
			
			if click_x >= 2 and click_x <= 25 then
				if click_y >= 7 and click_y <= 19 then
					-- Click on results list
					local row_clicked = click_y - 6
					
					-- Gets clicked row
					local count = 1
					local item_clicked = nil

					for item, details in pairs(results) do
						if count == row_clicked then
							item_clicked = item
							break
						end
						count = count + 1
					end
					
					-- Sends fetch packet to server
					local request = {
						["type"] = "get_item",
						["item"] = item_clicked,
						["amount"] = 1
					}
					modem.transmit(0, 3, textutils.serializeJSON(request))
					
					local event, side, channel, replyChannel, res, distance = os.pullEvent("modem_message")
					res = textutils.unserializeJSON(res)
			
					-- Display Result
					message_window.setCursorPos(1,1)
					message_window.write(res.status)
				end
			end
		end
		
		if event_data[1] == "char" or 
		  (event_data[1] == "key" and 
		   keys.getName(event_data[2]) == "backspace") then
		
			-- Creates displayed search
			local search_length = string.len(search)
			if search_length > 24 then
				displayed_search = search.sub(search, search_length - 23, -1)
			else
				displayed_search = search
			end
			
			-- Redraws search
			search_window.clear()
			search_window.setCursorPos(1,1)
			search_window.write(displayed_search)
			
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
				
				results = res.results
				
				local row = 1
				for key, value in pairs(res.results) do
					results_window.setCursorPos(1,row)
					results_window.write(value.displayName)
					row = row + 1
					
					if row > 13 then
						break
					end
				end
			else
				print("Error")
			end
		end
	end
end

-- Call main function
main()