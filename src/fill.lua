--
-- Implementation of the `fill` command
--

local util = require 'src.util'
local pretty = require "cc.pretty"


local HEAT_PLATING = {id = "ic2:itemreactorplating"}
local COMP_VENT = {id = "ic2:reactorventspread"}
local ELEC_OC_HEAT_VENT = {id = "ic2:itemheatvent"}
local FUEL_ROD = {id = "ic2:itemreactorrods", data = 13} -- NetherStart Enriched Dual Rod


-- Patterns should have no empty slots, but rather use some filler (like a heat capacity vent)
local PATTERNS = {
    ['4chamber'] = {
        size = { rows = 6, columns = 7 },
        slots = {
            { HEAT_PLATING, COMP_VENT, ELEC_OC_HEAT_VENT, COMP_VENT, ELEC_OC_HEAT_VENT, COMP_VENT, HEAT_PLATING },
            { COMP_VENT, ELEC_OC_HEAT_VENT, FUEL_ROD, ELEC_OC_HEAT_VENT, FUEL_ROD, ELEC_OC_HEAT_VENT, COMP_VENT },

            { HEAT_PLATING, COMP_VENT, ELEC_OC_HEAT_VENT, COMP_VENT, ELEC_OC_HEAT_VENT, COMP_VENT, HEAT_PLATING },
            { COMP_VENT, ELEC_OC_HEAT_VENT, FUEL_ROD, ELEC_OC_HEAT_VENT, FUEL_ROD, ELEC_OC_HEAT_VENT, COMP_VENT },

            { ELEC_OC_HEAT_VENT, FUEL_ROD, ELEC_OC_HEAT_VENT, COMP_VENT, ELEC_OC_HEAT_VENT, FUEL_ROD, ELEC_OC_HEAT_VENT },
            { COMP_VENT, ELEC_OC_HEAT_VENT, COMP_VENT, HEAT_PLATING, COMP_VENT, ELEC_OC_HEAT_VENT, COMP_VENT }
        }
    }
}

local function find_item_slot(req_item)
    -- Find the slot of the item in the inventory
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name == req_item.id then
            if not req_item.data or req_item.data == item.damage then
                return i
            end
        end
    end

    -- If the item is not found, return nil
    return nil
end

-- Find request pipe
local function find_lp_request_pipe()
    for _, name in pairs(peripheral.getNames()) do
        if peripheral.getType(name) == "LogisticsPipes:Request" then
            return peripheral.wrap(name)
        end
    end
    error("No Logistics Pipes provider found. Make sure you have a Logistics Pipes network set up and a provider module in the turtle's inventory.")
end

-- Use an Request Logistics Pipes to request an item
local function request_item_from_lp(item)
    local pipe = find_lp_request_pipe()

    local lp = pipe.getLP()
    local id_builder = lp.getItemIdentifierBuilder()
    id_builder.setItemID(item.id)
    if item.data then
        id_builder.setItemData(item.data)
    end
    local stack = id_builder.build().makeStack(1)
    print(stack.getType())

    repeat
        local status, list = pipe.makeRequest(stack) -- TODO: Bug in LP/CC, cant call this method
        print("Requesting item: " .. item.id .. " (data: " .. (item.data or "nil") .. "), status: " .. tostring(status))
        if status ~= "DONE" then
            os.sleep(1)
            print("...retrying in 1s")
        end
    until status ~= "DONE"
end

local function get_or_wait_for_item(item)
    while true do
        -- Check if the item is already in the inventory
        local slot = find_item_slot(item)
        if slot then
            return slot
        end

        -- Request from LP
        --request_item_from_lp(item)

        -- Wait for the item to be added to the inventory
        print("Waiting for item: " .. item.id)
        os.pullEvent("turtle_inventory")
    end
end


-- Drop `count` items from the turtles selected slot into the inventory of the given peripheral
-- Assumes that the turtle is already turned appropriately to drop in the items (eg.: facing the inventory, or it's above/below the turtle)
local function drop_item_into_inventory(inventory_peripheral, count)
    local dir = inventory_peripheral.getName()
    if dir == 'up' then
        turtle.dropUp(count)
    elseif dir == 'down' then
        turtle.dropDown(count)
    elseif dir == 'front' then
        turtle.drop(count)
    else
        error("Inventory peripheral is not in a valid position (up, down, front): " .. dir)
    end
end

-- Place the Logistics Pipes Chassis and the provider module into it
-- @param place_at The position where the chassis should be placed (up, down)
--local function place_logistics_chassis(place_at)
--    for mk = 1, 5 do
--        -- Place down the Logistics Pipes Chassis MK(1-5)
--        local chassis_slot = get_or_wait_for_item("logisticspipes:pipe_chassis_mk" .. mk)
--        turtle.select(chassis_slot)
--        if place_at == "up" then
--            turtle.placeUp()
--        elseif place_at == "down" then
--            turtle.placeDown()
--        end
--        local chassis = peripheral.wrap(place_at, "inventory")
--`
--        -- Place the provider module into it
--        local provider_slot = get_or_wait_for_item("logisticspipes:module_provider")
--        inventory.push()
--
--
--    
--        -- Select the provider module slot
--    
--        -- Place the provider module in the chassis
--        if not turtle.place() then
--            error("Failed to place the Logistics Provider Module")
--        end
--    end
--end

-- Fill the reactor currently at `side` of the turtle according to the pattern
-- @param reactor The reactor to fill
-- @param pattern The pattern to fill the reactor with (From the `PATTERNS` table)
local function fill_reactor(reactor, pattern)
    -- Face the reactor
    local turn_back = util.turn_to_face(peripheral.getName(reactor))

    -- Iterate through the slots in the pattern and fill them
    for row = 0, pattern.size.rows - 1 do
        for col = 0, pattern.size.columns - 1 do
            local item = pattern.slots[row + 1][col + 1]
            local slot = get_or_wait_for_item(item)

            turtle.select(slot)
            util.drop_item_into_inventory(reactor, 1)

            --core_inventory.pushItems(turtle.getNameLocal(), slot, 1, col * pattern.size.columns + row)
        end
    end

    -- Turn back to the original direction (As placed by the player)
    turn_back()
end

-- Go forwards until a reactor core/chamber is found or the maximum distance is reached
local function find_reactor(max_dist)
    for i = 1, max_dist do
        local reactor = peripheral.find("ic2:reactor chamber") or peripheral.find("ic2:reactor core")
        if reactor then
            return reactor
        end
        turtle.forward()
    end
    return nil
end

local function show_usage(args)
    print("Usage: main fill <pattern id> [max reactor count to fill] [max search distance (forwards)]")
    print("In order for this to work, you must give the turtle a 'Provider Module' set up with the items used to fill and also a Chassis MK(1-5) the module can be put in")
    print("Obviously this pipe when placed should connect to a Logistics Pipes network that can provide the necessary items")
    print("Available patterns:")
    for id, pattern in pairs(PATTERNS) do
        print("\t" .. id .. ": " .. pattern.size.rows .. " rows, " .. pattern.size.columns .. " columns")
    end
    print("Available logistics pipe place positions:")
    print("\tup, down")
end

return function(args) 
    -- 
    -- Parse the arguments
    --
    local pattern_id = args[2]
    if not pattern_id then
        show_usage(args)
        return
    end
    if pattern_id == nil or not PATTERNS[pattern_id] then
        error('Unrecognized pattern: ' .. pattern_id)
        return
    end
    local pattern = PATTERNS[pattern_id]
    
    local max_count_reactors = util.get_numeric_arg(args[3], "max reactor count to fill") or 1
    local max_search_distance = util.get_numeric_arg(args[4], "max search distance (forwards)", max_count_reactors)

    --
    -- Go on filling the reactors
    --
    local count = 0
    while count < max_count_reactors do
        local reactor = find_reactor(max_search_distance)

        if not reactor then
            print("No reactor core/chamber found within " .. max_search_distance .. " blocks")
            break
        end

        print("Filling reactor " .. (count + 1) .. " of " .. max_count_reactors)
        fill_reactor(reactor, pattern)
        count = count + 1
        
        turtle.forward()
    end
    print("Finished filling " .. count .. " reactors.")
end
