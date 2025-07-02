
return {
    get_numeric_arg = function (arg, name, default)
        local num = tonumber(arg)
        if not arg or not num then
            if default then
                return default
            end
            error("Invalid value for " .. name .. ": " .. arg)
            return nil
        end
        return num
    end,
    
    -- Turn to face a direction
    -- @param direction The direction to turn to ('back', 'left', 'right')
    -- @return A function that turns the turtle back to its original direction
    turn_to_face = function (direction)
        if dir == 'back' then
            turtle.turnRight()
            turtle.turnRight()
            return function()
                turtle.turnRight()
                turtle.turnRight()
            end
        elseif dir == 'left' then
            turtle.turnLeft()
            return function()
                turtle.turnRight()
            end
        elseif dir == 'right' then
            turtle.turnRight()
            return function()
                turtle.turnLeft()
            end
        end
    end,

    -- Drop `count` items from the turtles selected slot into the inventory of the given peripheral
    -- Assumes that the turtle is already turned appropriately to drop in the items (eg.: facing the inventory, or it's above/below the turtle)
    drop_item_into_inventory = function (inventory_peripheral, count)
        local dir = peripheral.getName(inventory_peripheral)
        if dir == 'top' then
            turtle.dropUp(count)
        elseif dir == 'down' then
            turtle.dropDown(count)
        elseif dir == 'front' then
            turtle.drop(count)
        else
            error("Inventory peripheral is not in a valid position (top, down, front): " .. dir)
        end
    end,
}
