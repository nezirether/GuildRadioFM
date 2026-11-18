-- Keep fallback timers inside the addon.
GuildRadioFM = GuildRadioFM or {}

function GuildRadioFM.After(delay, callback)
    if C_Timer and C_Timer.After then return C_Timer.After(delay, callback) end
    local elapsed = 0
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, delta)
        elapsed = elapsed + delta
        if elapsed >= delay then
            self:SetScript("OnUpdate", nil)
            callback()
        end
    end)
end
