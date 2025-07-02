
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
    end
}
