local _, MyGoldTracker = ...

local locale_zhCN = {
    -- Minimap
    ["TOOLTIP_GOLD_SUMMARY"] = "点击查看金币总和",
    ["LEFT_CLICK_TOOLTIP"] = "左键点击查看所有角色金币",
    ["RIGHT_CLICK_TOOLTIP"] = "右键清空数据",

    -- Commands
    ["COMMAND_USAGE"] = "\n /goldtracker show 打开金币总和窗口 \n /goldtracker reset 重置所有数据",

    -- Main window
    ["GOLD_SUMMARY"] = "金币总和",
    ["GOLD_TOTAL"] = "合计",

    -- LOG
    ["Warning: Invalid gold value for character %s in realm %s"] = "Warning: 角色 %s - %s 金币是无效值"
}

if MyGoldTracker.locale == "zhCN" then
    MyGoldTracker.L = locale_zhCN
end
