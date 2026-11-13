function GuildRadioFM:PlayLocalTrack(song)
    -- Playback stays local through WoW's Dialog channel.
    song = song or self:GetCurrentSong()
    if not song or not song.file then
        self:Print("No local file path found for this song.")
        return
    end

    if self.soundHandle then
        StopSound(self.soundHandle)
        self.soundHandle = nil
    end

    if self.db and self.db.muted then
        self:SetDialogVolume(0)
        self:Print("Muted. Unmute to hear playback.")
        return
    end

    local willPlay, soundHandle = PlaySoundFile(song.file, "Dialog")
    if willPlay then
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
    if self.soundHandle then
        StopSound(self.soundHandle)
        self.soundHandle = nil
    end
end
