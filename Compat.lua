-- Compatibility layer for legacy WoW clients. Experimental; verify against Forever client.
if not C_Timer then C_Timer = {} end
if not C_Timer.After then
    function C_Timer.After(delay, callback)
        if type(callback) ~= "function" then return end
        local elapsed = 0
        local frame = CreateFrame("Frame")
        frame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= (tonumber(delay) or 0) then
                self:SetScript("OnUpdate", nil)
                callback()
            end
        end)
    end
end
