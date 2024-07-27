-- 创建一个表来存储角色数据
local characters = {}

-- 创建一个框架，并使用 BackdropTemplateMixin
local frame = CreateFrame("Frame", "MyFirstAddonFrame", UIParent, "BackdropTemplate")
frame:SetSize(300, 400)  -- 设置框架大小
frame:SetPoint("CENTER") -- 设置框架位置为屏幕中央
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 1) -- 背景颜色：黑色

-- 创建滚动框架
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -10)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(1, 1) -- 初始大小，可以在之后调整

scrollFrame:SetScrollChild(content)

-- 更新显示的角色数据
local function updateCharacterList()
    local previousLabel
    for i, character in ipairs(characters) do
        local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetText(character.name .. " - " .. GetCoinTextureString(character.money))
        if previousLabel then
            label:SetPoint("TOPLEFT", previousLabel, "BOTTOMLEFT", 0, -5)
        else
            label:SetPoint("TOPLEFT", 0, 0)
        end
        previousLabel = label
    end
    content:SetHeight(#characters * 20 + (#characters - 1) * 5)
end

-- 注册事件
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")

-- 事件处理函数
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "PLAYER_LOGIN" then
        local name = UnitName("player")
        local realm = GetRealmName()
        local fullName = name .. " - " .. realm
        local money = GetMoney()

        -- 检查角色是否已被记录
        local found = false
        for _, character in ipairs(characters) do
            if character.name == fullName then
                character.money = money
                found = true
                break
            end
        end

        -- 如果角色不在列表中，则添加
        if not found then
            table.insert(characters, { name = fullName, money = money })
        end

        -- 保存到SavedVariables
        All_My_Gold_CharacterList = characters
        updateCharacterList()
        frame:Show()
    elseif event == "ADDON_LOADED" and addonName == "All_My_Gold" then
        -- 从SavedVariables加载已记录的角色数据
        if All_My_Gold_CharacterList then
            characters = All_My_Gold_CharacterList
        end
    end
end)

-- 确保框架显示
frame:Show()
