-- 创建一个框架，并使用 BackdropTemplateMixin
local frame = CreateFrame("Frame", "MyFirstAddonFrame", UIParent, "BackdropTemplate")
frame:SetSize(200, 100)  -- 设置框架大小
frame:SetPoint("CENTER") -- 设置框架位置为屏幕中央

-- 添加一个背景颜色
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 1) -- 背景颜色：黑色

-- 创建一个文本标签
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")                    -- 设置文本位置为框架中央
text:SetText("Welcome to My First Addon!") -- 设置文本内容

-- 注册一个事件
frame:RegisterEvent("PLAYER_LOGIN")

-- 定义事件处理函数
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("My First Addon loaded!")
        -- 显示框架
        frame:Show()
    end
end)

-- 确保框架显示
frame:Show()
