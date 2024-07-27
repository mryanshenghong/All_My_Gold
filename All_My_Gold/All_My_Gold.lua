-- MyGoldTracker.lua
local MyGoldTracker = LibStub("AceAddon-3.0"):NewAddon("All_My_Gold", "AceConsole-3.0", "AceEvent-3.0")

-- 存储角色金币数据的数据库
All_My_Gold_Database = All_My_Gold_Database or {}
-- 创建 LibDataBroker 对象
local dataObject = LibStub("LibDataBroker-1.1"):NewDataObject("All_My_Gold", {
    type = "data source",
    text = "Gold Tracker",
    icon = "Interface\\Icons\\inv_misc_coin_01",
    OnClick = function(_, button)
        if button == "LeftButton" then
            
            -- 关闭摘要窗口（如果打开的话）
            if MyGoldTracker.summaryFrame and MyGoldTracker.summaryFrame:IsVisible() then
                MyGoldTracker.summaryFrame:Hide()
            else
                MyGoldTracker:ShowGoldSummary()
            end
        elseif button == "RightButton" then
            MyGoldTracker:ResetDatabase()
        end
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("金币总和", 1, 1, 1) -- 添加标题
        GameTooltip:AddLine("左键点击查看所有角色金币", 1, 1, 1)
        GameTooltip:AddLine("右键清空数据", 1, 1, 1)
        GameTooltip:Show()
    end,
    OnLeave = function()
        GameTooltip:Hide()
    end,
})


-- 初始化
function MyGoldTracker:OnInitialize()
    self:UpdateTotalGold() -- 初始化时更新金币总数
end

-- 注册聊天命令
function MyGoldTracker:OnEnable()
    self:RegisterChatCommand("goldtracker", "ChatCommand")
    self:UpdateGoldData()
end

function MyGoldTracker:ChatCommand(input)
    if input == "show" then
        self:ShowGoldSummary()
    elseif input == "reset" then
        self:ResetDatabase()
    else
        print("Usage: /goldtracker show | reset")
    end
end

-- 显示金币摘要窗口
function MyGoldTracker:ShowGoldSummary()
    if not self.summaryFrame then
        -- 创建 summaryFrame
        self.summaryFrame = CreateFrame("Frame", "MyGoldTrackerSummaryFrame", UIParent, "BasicFrameTemplateWithInset")
        self.summaryFrame:SetSize(300, 400)
        self.summaryFrame:SetPoint("CENTER")
        self.summaryFrame:SetMovable(true)
        self.summaryFrame:EnableMouse(true)
        self.summaryFrame:RegisterForDrag("LeftButton")
        self.summaryFrame:SetScript("OnDragStart", self.summaryFrame.StartMoving)
        self.summaryFrame:SetScript("OnDragStop", self.summaryFrame.StopMovingOrSizing)

        local title = self.summaryFrame:CreateFontString(nil, "OVERLAY")
        title:SetFontObject("GameFontHighlightLarge")
        title:SetPoint("CENTER", self.summaryFrame.TitleBg, "CENTER", 5, 0)
        title:SetText("金币总和")

        local scrollFrame = CreateFrame("ScrollFrame", nil, self.summaryFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(260, 360)
        scrollFrame:SetScrollChild(content)

        local offsetY = -10
        local totalGold = 0

        for realmName, realmData in pairs(All_My_Gold_Database) do
            local realmTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            realmTitle:SetPoint("TOPLEFT", 10, offsetY)
            realmTitle:SetText(realmName)
            offsetY = offsetY - 20

            for characterName, gold in pairs(realmData) do
                local charGold = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                charGold:SetPoint("TOPLEFT", 20, offsetY)
                if type(gold) == "number" then
                    charGold:SetText(characterName .. ": " .. C_CurrencyInfo.GetCoinTextureString(gold))
                    totalGold = totalGold + gold -- 累加金币
                else
                    charGold:SetText(characterName .. ": 0")
                end
                offsetY = offsetY - 20
            end

            offsetY = offsetY - 10
        end

        -- 显示总金币
        local totalLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        totalLabel:SetPoint("TOPLEFT", 10, offsetY)
        totalLabel:SetText("合计: " .. C_CurrencyInfo.GetCoinTextureString(totalGold))
    else
        self.summaryFrame:Show()
    end
end

-- 重置数据库
function MyGoldTracker:ResetDatabase()
    All_My_Gold_Database = {} -- 清空数据库
    -- print("All_My_Gold_Database has been reset.")
    self:UpdateTotalGold()    -- 更新总金币显示

    -- 关闭摘要窗口（如果打开的话）
    if self.summaryFrame and self.summaryFrame:IsVisible() then
        self.summaryFrame:Hide()
        self.summaryFrame = nil -- 释放引用
        -- print("Gold summary UI has been closed.")
    else
        -- print("Gold summary UI is not open.")
    end
end

-- 更新金币数据
function MyGoldTracker:UpdateGoldData()
    local realmName = GetRealmName()
    local characterName = UnitName("player")
    local gold = GetMoney() -- 获取当前角色的金币

    -- 确保数据库中有该角色的金币数据
    if not All_My_Gold_Database[realmName] then
        All_My_Gold_Database[realmName] = {}
    end
    All_My_Gold_Database[realmName][characterName] = gold

    -- print("Updated " .. characterName .. "'s gold to " .. C_CurrencyInfo.GetCoinTextureString(gold))
    self:UpdateTotalGold() -- 更新总金币显示
end

-- 更新总金币显示
function MyGoldTracker:UpdateTotalGold()
    local totalGold = 0
    for realmName, realmData in pairs(All_My_Gold_Database) do
        for characterName, gold in pairs(realmData) do
            if type(gold) == "number" then
                totalGold = totalGold + gold
            else
                print("Warning: Invalid gold value for character " .. characterName .. " in realm " .. realmName)
            end
        end
    end
    dataObject.text = "合计: " .. C_CurrencyInfo.GetCoinTextureString(totalGold)
    -- print("Updated total gold: " .. totalGold)
end

-- 创建小地图按钮
local LDBIcon = LibStub("LibDBIcon-1.0")
LDBIcon:Register("All_My_Gold", dataObject, {})
