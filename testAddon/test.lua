local frame = CreateFrame('Frame')

frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    print("test")
end)
