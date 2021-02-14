-- Name: main-craft.lua
-- Description: Listens for craft requests and crafts
--              requested items.

-- Require Modules
local crafter = require("crafter")

-- Define globals

-- Define functions
local function init_modem()
	-- Init Modem
	modem = peripheral.wrap("right")
	modem.open(2)
	return modem
end

local function main()
	-- Init modem
	local modem = init_modem()
		
	-- Main Event Loop
	while true do

		-- Wait for any event
		local event_data = {os.pullEvent("modem_message")}
		local channel = event_data[3]
		local reply_channel = event_data[4]
		local raw_request = event_data[5]
		
		-- Parse request
		local request = textutils.unserializeJSON(raw_request)
		
		-- Check decode success
		if request then
			-- Check request type and action
			if request.type == "craft_item" then
				-- Craft item
				crafter.craft(
					request.item,
					1,
					0,
					modem)
					
				response = {
					status = "Success"
				}
				
				modem.transmit(reply_channel, 2, textutils.serializeJSON(response))
			else
				-- Unknown request type
				print("Unknown request type")
			end
		end
	end
end

-- Call main function
main()