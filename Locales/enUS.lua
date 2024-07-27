local _, MyGoldTracker = ...

local locale_enUS = {
    -- Minimap
    ["TOOLTIP_GOLD_SUMMARY"] = "Click to show gold summary",
    ["LEFT_CLICK_TOOLTIP"] = "Left click to see gold for all characters",
    ["RIGHT_CLICK_TOOLTIP"] = "Right click to reset all saved data",

    -- Commands
    ["COMMAND_USAGE"] = "\n /goldtracker show to open gold summary window \n /goldtracker reset to reset all data",

    -- Main window
    ["GOLD_SUMMARY"] = "Gold summary",
    ["GOLD_TOTAL"] = "Total gold",

    -- LOG
    ["Warning: Invalid gold value for character %s in realm %s"] = "Warning: Invalid gold value for character %s in realm %s"
}

if tostring(MyGoldTracker.locale) == "enUS" then
    MyGoldTracker.L = locale_enUS
end
