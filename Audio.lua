function GuildRadioFM:PlayLocalTrack(song)
    -- Playback stays local through WoW's Dialog channel.
    song = song or self:GetCurrentSong()
    if not song or not song.file then
        self:Print("No local file path found for this song.")
        return
    end

    self:StopLocalTrack()

    if self.db and self.db.muted then
        self:Print("Muted. Unmute to hear playback.")
        return
    end

    local ok, willPlay, soundHandle = pcall(PlaySoundFile, song.file, self.soundChannel or "Dialog")
    if ok and willPlay then
        self.soundHandle = soundHandle
        self:Print("Playing: " .. (song.title or song.file))
    else
        self.db.isPlaying = false
        self.startedAt = nil
        self:Print("Could not play local file: " .. song.file)
        self:Print("Check the filename in SongList.lua, then restart WoW.")
    end
end

function GuildRadioFM:StopLocalTrack()
    local handle = self.soundHandle
    self.soundHandle = nil
    if handle then StopSound(handle) end
end
