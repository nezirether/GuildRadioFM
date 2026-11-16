local R = GuildRadioFM
local lyricsBySong = {}

local function key(value)
    if type(value) == "string" and value ~= "" then return value:lower() end
end

local function lyricLines(source)
    local lines = {}
    if type(source) == "string" then
        for line in source:gmatch("[^\r\n]+") do
            local m, s, fraction, text = line:match("^%[(%d+):(%d%d)%.?(%d*)%]%s*(.-)%s*$")
            if m then
                lines[#lines + 1] = {time=tonumber(m)*60+tonumber(s)+(tonumber("0."..fraction) or 0), text=text}
            end
        end
    elseif type(source) == "table" then
        for _, line in ipairs(source) do
            local at = type(line) == "table" and tonumber(line.time or line[1])
            local text = type(line) == "table" and (line.text or line[2])
            if at and at >= 0 and at < math.huge and type(text) == "string" then
                lines[#lines + 1] = {time=at, text=text}
            end
        end
    end
    table.sort(lines, function(a, b) return a.time < b.time end)
    return #lines > 0 and lines or nil
end

function R:RegisterLyrics(songID, source, aliases)
    local id = key(songID)
    local lines = lyricLines(source)
    if not id or not lines then return false end
    lyricsBySong[id] = lines
    if type(aliases) == "table" then
        for _, alias in ipairs(aliases) do
            if key(alias) then lyricsBySong[key(alias)] = lines end
        end
    end
    return true
end

function R:RegisterLyricsTable(entries)
    if type(entries) ~= "table" then return end
    for id, source in pairs(entries) do self:RegisterLyrics(id, source) end
end

function R:RegisterSongLyrics(song)
    if type(song) ~= "table" or not song.lyrics then return end
    self:RegisterLyrics(song.id or song.title or song.file, song.lyrics, {song.title or song.file})
end

function R:GetLyricsForSong(song)
    if not song then return end
    return lyricsBySong[key(song.id)] or lyricsBySong[key(song.title)] or lyricsBySong[key(song.file)]
end

function R:CurrentLyric()
    if not self.db or not self.db.isPlaying or not self.startedAt then return "" end
    if self.Live and self.Live:JoiningIn() then return "" end
    local elapsed = GetTime() - self.startedAt
    local lines = self:GetLyricsForSong(self:GetCurrentSong())
    if not lines or elapsed < 0 then return "" end
    local low, high = 1, #lines
    while low <= high do
        local middle = math.floor((low + high)/2)
        if lines[middle].time <= elapsed then low = middle + 1 else high = middle - 1 end
    end
    return lines[high] and lines[high].text or ""
end

function R:CanPlaySong(song)
    return type(song) == "table" and (not song.hidden or self.db.secretFrequencyUnlocked == true)
end

function R:TuneFrequency(frequency)
    if frequency == "1138" then
        self.db.secretFrequencyUnlocked = true
        self:Print("Secret Frequency unlocked in your library.")
        self:RefreshAll()
    elseif frequency == "404" then
        self.db.hiddenFrequencyUnlocked = true
        self:Print("Channel 404 detected. Only installed tracks can be played.")
    else
        self:Print("Nothing but static...")
    end
end

function R:GetQueue()
    return self.db.queue
end

function R:AddToQueue(index)
    local song = self:GetSong(index)
    if not self:CanPlaySong(song) then return false end
    local queue = self:GetQueue()
    if #queue >= 200 then self:Print("The local queue is full."); return false end
    queue[#queue + 1] = {songID=song.id, file=song.file, title=song.title}
    self:RefreshAll()
    self:Print("Queued locally: " .. (song.title or song.file))
    return true
end

local function queuedIndex(radio, entry)
    if type(entry) ~= "table" then return end
    for i, song in ipairs(radio.songs or {}) do
        if radio:CanPlaySong(song) and
            ((entry.songID and key(entry.songID) == key(song.id)) or
             (entry.file and key(entry.file) == key(song.file)) or
             (not entry.file and key(entry.title) and key(entry.title) == key(song.title))) then
            return i
        end
    end
end

function R:PlayNextInQueue()
    local queue = self:GetQueue()
    for i, entry in ipairs(queue) do
        local index = queuedIndex(self, entry)
        if index then
            table.remove(queue, i)
            self:PlaySong(index)
            return true
        end
    end
    if #queue > 0 then self:Print("Queued songs are unavailable. Their entries were kept.") end
    return false
end

function R:RemoveFromQueue(index)
    index = tonumber(index)
    local queue = self:GetQueue()
    if not index or index % 1 ~= 0 or index < 1 or index > #queue then return end
    local removed = table.remove(queue, index)
    self:RefreshAll()
    return removed
end
