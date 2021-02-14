-- Name: storage.lua
-- Description: Handles network storage actions.

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
			
			-- Gets display name
			local item_details = storage_chest.getItemDetail(slot)
			
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
					displayName = item_details.displayName,
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

local function get_item(item, amount, storage_items, to_inventory, to_slot)
	-- Moves an amount of the given item to the given inventory
	local item_found = false
	local moved_count = 0

	for item_name, item_details in pairs(storage_items) do
		
		-- Check if current item matches required item
		if item == item_name then

			item_found = true

			-- Check if amount is less than or equal to stored amount
			if amount > item_details.totalCount then
				return false, "Not enough of item"
			end
			
			-- Move items from storage to inventory
			for inventory_name, inventory_item_details in pairs(item_details.locations) do

				-- Calculates amount to move from current location
				local move_amount = math.min(amount - moved_count, inventory_item_details.count)
				
				-- Wrap taget inventory
				local inventory = peripheral.wrap(inventory_name)
				if inventory == nil then return false, "Couldn't wrap inventory "..inventory_name end
				
				-- Moves item
				local moved = inventory.pushItems(to_inventory, inventory_item_details.slot, move_amount, to_slot)
				
				-- Update storage index
				local item_record = storage_items[item_name] 
				item_record.totalCount = item_record.totalCount - moved
				
				if item_record.totalCount <= 0 then
					-- None of item remaining
					storage_items[item_name] = nil
				else
					-- Update inventory count
					item_record.locations[inventory_name].count = item_record.locations[inventory_name].count - moved
				
					if item_record.locations[inventory_name].count <= 0 then
						-- Remove location from index
						item_record.locations[inventory_name] = nil
					end
				end
				
				-- Update moved count
				moved_count = moved_count + moved
				
				-- Stop looking if already moved enough
				if moved_count == amount then
					return true, moved_count
				end
			end
			
			-- Exit loop
			break
		end
	end
	
	-- Returns error if not found
	if item_found == false then
		return false, "Item not found"
	end
	
	-- Returns error if not enough moved
	if moved_count ~= amount then
		return false, moved_count
	else
		return true, moved_count
	end
end

return {
	get_items = get_items,
	get_item = get_item
}