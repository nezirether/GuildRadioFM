SLASH_GUILDRADIOFM1 = "/grfm"
SLASH_GUILDRADIOFM2 = "/guildradiofm"

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
    self:Print("/grfm volume 50, /grfm v 50, /grfm song 1, /grfm reset")
    self:Print("Rooms: /grfm live (window), /grfm dj (open a room), /grfm room <name>, /grfm invite (whole guild), /grfm invite <name>, /grfm pass <name>, /grfm endset, /grfm tune, /grfm tuneout, /grfm unblock")
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
    if lower == "live" or lower == "requests" then GuildRadioFM:ToggleTab("live") return end
    if lower == "golive" or lower == "dj" then GuildRadioFM.Live:GoLive() return end
    local passTo = string.match(raw, "^[Pp][Aa][Ss][Ss]%s+(%S+)$")
    if passTo then GuildRadioFM.Live:OfferHost(passTo) return end
    local roomName = string.match(raw, "^[Rr][Oo][Oo][Mm]%s+(.+)$")
    if roomName then GuildRadioFM.Live:SetRoomName(roomName); GuildRadioFM:Print("Room name: " .. GuildRadioFM.Live:RoomName()); GuildRadioFM:RefreshAll() return end
    local inviteWho = string.match(raw, "^[Ii][Nn][Vv][Ii][Tt][Ee]%s+(%S+)$")
    if inviteWho then GuildRadioFM.Live:InviteOne(inviteWho) return end
    if lower == "invite" then GuildRadioFM.Live:Announce() return end
    if lower == "endset" then GuildRadioFM.Live:EndSet() return end
    if lower == "tune" or lower == "tunein" then GuildRadioFM.Live:TuneIn() return end
    if lower == "tuneout" then GuildRadioFM.Live:TuneOut() return end
    if lower == "unblock" then GuildRadioFM.db.eb.blocked = {}; GuildRadioFM:Print("Do-not-play list cleared.") return end

    local volume = string.match(lower, "^volume%s+(%d+)$") or string.match(lower, "^v%s+(%d+)$")
    if volume then GuildRadioFM:SetVolume(volume) return end

    local songIndex = string.match(lower, "^song%s+(%d+)$")
    if songIndex then GuildRadioFM:PlaySong(tonumber(songIndex)) return end

    GuildRadioFM:Print("Unknown command. Try /grfm help.")
end
