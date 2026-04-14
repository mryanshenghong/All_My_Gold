local _, MyGoldTracker = ...
local L = MyGoldTracker.L

MyGoldTracker = LibStub("AceAddon-3.0"):NewAddon("All_My_Gold", "AceConsole-3.0", "AceEvent-3.0")



-- 存储角色金币数据的数据库
All_My_Gold_Database = All_My_Gold_Database or {}
All_My_Gold_Database.position = All_My_Gold_Database.position or {}
All_My_Gold_Database.data = All_My_Gold_Database.data or {}
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
        GameTooltip:AddLine(L['TOOLTIP_GOLD_SUMMARY'], 1, 1, 1) -- 添加标题
        GameTooltip:AddLine(L["LEFT_CLICK_TOOLTIP"], 1, 1, 1)
        GameTooltip:AddLine(L["RIGHT_CLICK_TOOLTIP"], 1, 1, 1)
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
    self:GenerateGoldTrackerMiniUI()
end

function MyGoldTracker:ChatCommand(input)
    if input == "show" then
        self:ShowGoldSummary()
    elseif input == "reset" then
        self:ResetDatabase()
    else
        print(L['COMMAND_USAGE'])
    end
end

-- 显示金币摘要窗口
function MyGoldTracker:ShowGoldSummary()
    if not self.summaryFrame then
        self.summaryFrame = CreateFrame("Frame", "MyGoldTrackerSummaryFrame", UIParent, "BackdropTemplate")
        self.summaryFrame:SetSize(300, 150)
        self.summaryFrame:SetPoint("CENTER")
        self.summaryFrame:SetMovable(true)
        self.summaryFrame:EnableMouse(true)
        self.summaryFrame:RegisterForDrag("LeftButton")
        self.summaryFrame:SetScript("OnDragStart", self.summaryFrame.StartMoving)
        self.summaryFrame:SetScript("OnDragStop", self.summaryFrame.StopMovingOrSizing)

        self.summaryFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })

        self.summaryFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
        self.summaryFrame:SetBackdropBorderColor(0, 0, 0, 1)

        -- 窗口主要内容
        local scrollFrame = CreateFrame("ScrollFrame", nil, self.summaryFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -40)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

        local content = CreateFrame("Frame", nil, scrollFrame)
        content:SetSize(300, 300)
        scrollFrame:SetScrollChild(content)

        local offsetY = -10
        local totalGold = 0

        for realmName, realmData in pairs(All_My_Gold_Database.data) do
            local realmTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            realmTitle:SetPoint("TOPLEFT", 10, offsetY)
            realmTitle:SetText(realmName)
            offsetY = offsetY - 20

            for characterName, gold in pairs(realmData) do
                local charGold = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                charGold:SetPoint("TOPLEFT", 20, offsetY)
                if type(gold) == "number" then
                    charGold:SetText(characterName .. ": " .. C_CurrencyInfo.GetCoinTextureString(gold))
                    totalGold = totalGold + gold
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
        totalLabel:SetText(L["GOLD_TOTAL"] .. C_CurrencyInfo.GetCoinTextureString(totalGold))
    else
        self.summaryFrame:Show()
    end
end

-- 重置数据库
function MyGoldTracker:ResetDatabase()
    All_My_Gold_Database = {} -- 清空数据库
    All_My_Gold_Database.position = All_My_Gold_Database.position or {}
    All_My_Gold_Database.data = All_My_Gold_Database.data or {}
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
    if not All_My_Gold_Database.data[realmName] then
        All_My_Gold_Database.data[realmName] = {}
    end
    All_My_Gold_Database.data[realmName][characterName] = gold

    -- print("Updated " .. characterName .. "'s gold to " .. C_CurrencyInfo.GetCoinTextureString(gold))
    self:UpdateTotalGold() -- 更新总金币显示
end

-- 更新总金币显示
function MyGoldTracker:UpdateTotalGold()
    local totalGold = 0
    for realmName, realmData in pairs(All_My_Gold_Database.data) do
        for characterName, gold in pairs(realmData) do
            if type(gold) == "number" then
                totalGold = totalGold + gold
            else
                local warning = ("").format(L["Warning: Invalid gold value for character %s in realm %s"], characterName,
                    realmName)
                print(warning)
            end
        end
    end
    dataObject.text = L["GOLD_TOTAL"] .. C_CurrencyInfo.GetCoinTextureString(totalGold)
    -- print("Updated total gold: " .. totalGold)
end


-- 创建界面UI小框体
function MyGoldTracker:GenerateGoldTrackerMiniUI()
    -- 200 * 20 迷你框体
    local f = CreateFrame("Frame", "GoldTrackerFrame", UIParent, "BackdropTemplate")
    f:SetSize(350, 20)

    local pos = All_My_Gold_Database.position
    if type(pos) == "table" and pos.point and pos.relativePoint and pos.x ~= nil and pos.y ~= nil then
        f:ClearAllPoints()
        f:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        f:SetPoint("CENTER", 0, 200)
    end

    local isMiniUIMoving = false

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)

    f:SetScript("OnDragStart", function(self)
        isMiniUIMoving = true
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        C_Timer.After(0.05, function()
            isMiniUIMoving = false
        end)

        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()

        All_My_Gold_Database.position = {
            point = point,
            relativePoint = relativePoint,
            x = xOfs,
            y = yOfs
        }
        
    end)

    -- 扁平背景
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    f:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    local totalGoldOnMiniCard = 0
    for realmName, realmData in pairs(All_My_Gold_Database.data) do
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(realmName, 0, 1, 1)
        for characterName, gold in pairs(realmData) do
            if type(gold) == "number" then
                totalGoldOnMiniCard = totalGoldOnMiniCard + gold
            end
        end
    end
    -- 创建当前角色金币文本
    local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", 20, 0)
    text:SetText(L['CURRENT_CHARACTER'].. ": " .. C_CurrencyInfo.GetCoinTextureString(GetMoney()) .. " | " ..  L["GOLD_TOTAL"] .. ": " .. C_CurrencyInfo.GetCoinTextureString(totalGoldOnMiniCard))
    

    -- 鼠标点击或者悬浮显示对话框
    f:SetScript("OnEnter", function(ss)
        if isMiniUIMoving then return end

        GameTooltip:SetOwner(ss, "ANCHOR_CURSOR")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("金币统计", 1, 0.8, 0)

        local totalGold = 0
        for realmName, realmData in pairs(All_My_Gold_Database.data) do
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(realmName, 0, 1, 1)
            for characterName, gold in pairs(realmData) do
                if type(gold) == "number" then

                    GameTooltip:AddDoubleLine(
                        characterName,
                        C_CurrencyInfo.GetCoinTextureString(gold),
                        1,1,1,
                        1,1,1
                    )
                    totalGold = totalGold + gold
                else
                    GameTooltip:AddDoubleLine(
                        characterName,
                        "0",
                        1,1,1,
                        1,1,1
                    )
                end
            end
        end


        -- 显示总金币
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(
            L["GOLD_TOTAL"],
            C_CurrencyInfo.GetCoinTextureString(totalGold),
            1,1,1,
            1,1,1
        )        

        -- 战团银行金币总和
        GameTooltip:AddDoubleLine(
            L["WAR_BAND_TOTAL"],
            C_CurrencyInfo.GetCoinTextureString(C_Bank.FetchDepositedMoney(Enum.BankType.Account)),
            1,1,1,
            1,1,1
        )   

        -- 时光徽章金币总和
        GameTooltip:AddDoubleLine(
            L["CURRENT_WOW_TOKEN"],
            C_CurrencyInfo.GetCoinTextureString(C_WowTokenPublic.GetCurrentMarketPrice(),14),
            1,1,1,
            1,1,1
        )        



         GameTooltip:Show()
    end)

    f:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end


-- 创建小地图按钮
local LDBIcon = LibStub("LibDBIcon-1.0")
LDBIcon:Register("All_My_Gold", dataObject, {})
