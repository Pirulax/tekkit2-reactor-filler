local fill_command = require("src.fill")

local VERSION = "1.0.0"
local AUTHOR = "Pirulax"

local ARGS = {...};

local function show_help()
    print("Usage: main [options]")
    print("Options:")
    print("  help       Show this help message")
    print("  version    Show the version of the script")
    print("  fill       Fill the reactor according to the code from reactor planner")
end

local function find_item_slot(id)

end


if ARGS[1] == "help" then
    show_help()
elseif ARGS[1] == "version" then
    print("Reactor Filler v" .. VERSION .. " by " .. AUTHOR)
else
    -- 
    -- Make sure turtle is fuelled up
    -- We expect fuel to be in slot 1
    --
    turtle.select(1)
    turtle.refuel()

    if ARGS[1] == "fill" then
        fill_command(ARGS) 
    else
        show_help()
    end
end
