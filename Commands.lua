SLASH_GUILDRADIOFM1 = "/grfm"
SLASH_GUILDRADIOFM2 = "/guildradiofm"
SLASH_GUILDRADIOFM3 = "/gr"

-- Local player commands only.
local function Trim(value)
    if strtrim then return strtrim(value or "") end
    return string.match(value or "", "^%s*(.-)%s*$")
end

function GuildRadioFM:ShowHelp()
    self:Print("Commands:")
    self:Print("/grfm, /grfm play, /grfm stop, /grfm next, /grfm back")
    self:Print("/grfm library, /grfm playlists, /grfm mini, /grfm settings")
    self:Print("/grfm options")
    self:Print("/grfm addsongs")
    self:Print("/grfm shuffle, /grfm repeat, /grfm autonext, /grfm mute, /grfm favorite, /grfm unlike")
    self:Print("/grfm favorites, /grfm playliked")
    self:Print("/grfm queue, /grfm queue status, /grfm queue clear")
    self:Print("/grfm restart, /grfm seek 60, /grfm seek +10, /grfm seek -10")
    self:Print("/grfm share, /grfm request, /grfm requests, /grfm share status")
    self:Print("/grfm sharing on, /grfm sharing off, /grfm sharing status")
    self:Print("/grfm lyrics test, /grfm lyrics status")
    self:Print("/grfm volume 50, /grfm v 50, /grfm song 1, /grfm reset")
end

SlashCmdList["GUILDRADIOFM"] = function(message)
    local raw = Trim(message)
    local lower = string.lower(raw)

    if lower == "" then GuildRadioFM:ToggleMainWindow() return end
    if lower == "help" then GuildRadioFM:ShowHelp() return end
    if lower == "signature" or lower == "credits" then GuildRadioFM:ShowSignature() return end
    if lower == "play" then GuildRadioFM:Play() return end
    if lower == "stop" then GuildRadioFM:Stop() return end
    if lower == "next" then GuildRadioFM:Next() return end
    if lower == "back" then GuildRadioFM:Back() return end
    if lower == "library" then GuildRadioFM:ToggleLibraryWindow() return end
    if lower == "favorites" or lower == "liked" then GuildRadioFM:SetLibraryView("favorites"); GuildRadioFM:ToggleLibraryWindow() return end
    if lower == "playliked" or lower == "playfavorites" then GuildRadioFM:PlayFavoriteEntry(1) return end
    if lower == "queue" then GuildRadioFM:ToggleQueueWindow(true) return end
    if lower == "queue clear" then GuildRadioFM:ClearQueue() return end
    if lower == "queue status" then GuildRadioFM:Print("Songs queued: " .. tostring(GuildRadioFM:GetQueueCount())) return end
    if lower == "restart" then GuildRadioFM:RestartCurrentTrack() return end
    if lower == "share" or lower == "share current" then GuildRadioFM:ShareCurrentSong() return end
    if lower == "request" or lower == "request current" then GuildRadioFM:RequestCurrentSong() return end
    if lower == "requests" or lower == "share inbox" then GuildRadioFM:ToggleSharingWindow(true) return end
    if lower == "share clear" then GuildRadioFM:ClearSharingInbox() return end
    if lower == "share status" then GuildRadioFM:PrintSharingStatus() return end
    if lower == "share toggle" then GuildRadioFM:ToggleSharing() return end
    if lower == "sharing on" then GuildRadioFM:SetMetadataSharingAllowed(true) return end
    if lower == "sharing off" then GuildRadioFM:SetMetadataSharingAllowed(false) return end
    if lower == "sharing status" then GuildRadioFM:PrintMetadataSharingStatus() return end
    local seekAmount = string.match(lower, "^seek%s+([%+%-]?%d+)$")
    if seekAmount then
        if string.sub(seekAmount, 1, 1) == "+" or string.sub(seekAmount, 1, 1) == "-" then
            GuildRadioFM:SeekBy(tonumber(seekAmount))
        else
            GuildRadioFM:SeekTo(tonumber(seekAmount))
        end
        return
    end
    if lower == "lyrics test" then GuildRadioFM:StartLyricsTest(); if GuildRadioFM.RefreshPlaybackTicker then GuildRadioFM:RefreshPlaybackTicker() end return end
    if lower == "lyrics status" then GuildRadioFM:PrintLyricsStatus() return end
    if lower == "secret reset" then GuildRadioFM:ResetSecretFrequency() return end
    if lower == "listener" then GuildRadioFM:UnlockHiddenFrequency() return end
    if lower == "hidden" then GuildRadioFM:ShowHiddenFrequency() return end
    if lower == "lockhidden" then GuildRadioFM:LockHiddenFrequencyForTesting() return end
    if lower == "tune" then GuildRadioFM:TuneFrequency("") return end
    local frequency = string.match(lower, "^tune%s+(.+)$")
    if frequency then GuildRadioFM:TuneFrequency(frequency) return end
    if lower == "playlist" or lower == "playlists" then GuildRadioFM:TogglePlaylistWindow() return end
    if lower == "mini" then GuildRadioFM:ToggleMiniWindow() return end
    if lower == "settings" then GuildRadioFM:ToggleSettingsWindow() return end
    if lower == "options" or lower == "config" then GuildRadioFM:OpenOptionsPanel() return end
    if lower == "addsong" or lower == "addsongs" or lower == "upload" then GuildRadioFM:ToggleAddSongsWindow() return end
    if lower == "shuffle" then GuildRadioFM:ToggleShuffle() return end
    if lower == "repeat" then GuildRadioFM:ToggleRepeat() return end
    if lower == "favorite" or lower == "like" then GuildRadioFM:ToggleFavorite() return end
    if lower == "unfavorite" or lower == "unlike" then GuildRadioFM:RemoveFavorite() return end
    if lower == "mute" then GuildRadioFM:ToggleMute() return end
    if lower == "autonext" then GuildRadioFM:ToggleAutoNext() return end
    if lower == "reset" then GuildRadioFM:Reset() return end

    local volume = string.match(lower, "^volume%s+(%d+)$") or string.match(lower, "^v%s+(%d+)$")
    if volume then GuildRadioFM:SetVolume(volume) return end

    local songIndex = string.match(lower, "^song%s+(%d+)$")
    if songIndex then GuildRadioFM:PlaySong(tonumber(songIndex)) return end

    GuildRadioFM:Print("Unknown command. Try /grfm help.")
end
