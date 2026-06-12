function GuildRadioFM:PlayLocalTrack(song)
    -- Playback stays local through WoW's Dialog channel.
    song = song or self:GetCurrentSong()
    if not song or not song.file then
        self:Print("No local file path found for this song.")
        return false
    end

    self:StopLocalTrack("new-playback")

    if self.db and self.db.muted then
        self:SetDialogVolume(0)
        self:Print("Muted. Unmute to hear playback.")
        return false
    end

    local willPlay, soundHandle = PlaySoundFile(song.file, "Dialog")
    if willPlay then
        self.soundHandle = soundHandle
        self:Print("Playing: " .. (song.title or song.file))
        return true
    else
        self.db.isPlaying = false
        self.startedAt = nil
        self:Print("Could not play local file: " .. song.file)
        self:Print("Check the filename in SongList.lua, then restart WoW.")
        return false
    end
end

function GuildRadioFM:StopLocalTrack()
    local handle = self.soundHandle
    self.soundHandle = nil
    if handle and StopSound then
        pcall(StopSound, handle)
    end
end
