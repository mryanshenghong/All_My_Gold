-- 创建一个表来存储角色数据
local characters = {}

-- 创建一个框架，并使用 BackdropTemplateMixin
local frame = CreateFrame("Frame", "All_My_Gold_Frame", UIParent, "BackdropTemplate")
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
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- 创建滚动框架
local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 10, -10)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(1, 1) -- 初始大小，可以在之后调整

scrollFrame:SetScrollChild(content)

-- 更新显示的角色数据
local function updateCharacterList()
    -- 清空现有的内容
    content:SetHeight(0) -- 重置内容的高度以清空内容

    local previousLabel
    local totalMoney = 0 -- 用于累加所有角色的金币

    for i, character in ipairs(characters) do
        totalMoney = totalMoney + character.money -- 累加金币
        local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetText(character.name .. " - " .. GetMoneyString(character.money))
        if previousLabel then
            label:SetPoint("TOPLEFT", previousLabel, "BOTTOMLEFT", 0, -5)
        else
            label:SetPoint("TOPLEFT", 0, 0)
        end
        previousLabel = label
    end

    -- 创建一个显示总金币的标签
    local totalLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    totalLabel:SetText("总金币: " .. GetMoneyString(totalMoney))
    totalLabel:SetPoint("TOPLEFT", previousLabel, "BOTTOMLEFT", 0, -10) -- 将总金币标签放在角色列表下方

    content:SetHeight(#characters * 20 + (#characters - 1) * 5 + 30)    -- 适应总金币标签的高度
end

-- 注册事件
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")

-- 事件处理函数
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "PLAYER_LOGIN" then
        -- 玩家登录时初始化数据
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
    elseif event == "ADDON_LOADED" and addonName == "All_My_Gold" then
        -- 从SavedVariables加载已记录的角色数据
        if All_My_Gold_CharacterList then
            characters = All_My_Gold_CharacterList
        end
    end
end)

-- 创建小地图按钮
local minimapButton = CreateFrame("Button", "MyFirstAddonMinimapButton", Minimap)
minimapButton:SetSize(30, 30)

-- 设置按钮的正常纹理为圆形图标
local normalTexture = minimapButton:CreateTexture()
normalTexture:SetAllPoints()
normalTexture:SetTexture("Interface/Icons/INV_Misc_QuestionMark") -- 替换为你想要的图标
minimapButton:SetNormalTexture(normalTexture)

-- 设置高亮纹理
local highlightTexture = minimapButton:CreateTexture()
highlightTexture:SetAllPoints()
highlightTexture:SetTexture("Interface/Buttons/UI-Common-MouseHilight")
highlightTexture:SetBlendMode("ADD")
minimapButton:SetHighlightTexture(highlightTexture)

-- 创建遮罩来实现圆形效果
local mask = minimapButton:CreateTexture(nil, "OVERLAY")
mask:SetAllPoints()
mask:SetTexture("Interface/Buttons/WHITE8X8") -- 白色方块作为遮罩
mask:SetTexCoord(0.25, 0.75, 0.25, 0.75)      -- 使用纹理的中间部分作为圆形遮罩
minimapButton:SetTexture(mask)

minimapButton:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -10, -10)

-- 小地图按钮点击事件
minimapButton:SetScript("OnClick", function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end)

-- 确保框架初始隐藏
frame:Hide() -- 初始隐藏框架，待点击小地图按钮时显示
