local _, MyGoldTracker = ...
local L = setmetatable({}, {
    __index = function(table, key)
        if key then
            table[key] = tostring(key)
        end
        return tostring(key)
    end,
})

MyGoldTracker.L = L

local locale = GetLocale()

MyGoldTracker.locale = locale
