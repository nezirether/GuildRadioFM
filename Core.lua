GuildRadioFM = GuildRadioFM or {}
GuildRadioFM.Version = "0.6.4"
GuildRadioFM.version = GuildRadioFM.Version
GuildRadioFM.soundChannel = "Dialog"

local SECRET_FREQUENCY_CODE = "1138"
local SECRET_FREQUENCY_CATEGORY = "Secret Frequency"
local BUILD_OWNER = { 81, 104, 125 }
local BUILD_TRACE = { 74, 120, 108, 111, 103, 85, 100, 103, 108, 114, 73, 80, 61, 61, 81, 104, 125, 61, 61, 111, 114, 102, 100, 111, 48, 111, 108, 101, 117, 100, 117, 124, 48, 114, 113, 111, 124, 61, 61, 53, 51, 53, 57, 48, 51, 56, 48, 53, 59 }
local BUILD_NOTE = { 69, 120, 108, 111, 119, 35, 105, 114, 117, 35, 81, 104, 125, 49, 35, 76, 105, 35, 105, 114, 120, 113, 103, 35, 108, 113, 35, 119, 107, 104, 35, 122, 108, 111, 103, 47, 35, 119, 107, 104, 35, 112, 120, 118, 108, 102, 35, 118, 119, 108, 111, 111, 35, 117, 104, 112, 104, 112, 101, 104, 117, 118, 35, 122, 107, 114, 35, 119, 120, 113, 104, 103, 35, 119, 107, 104, 35, 103, 108, 100, 111, 49 }

local function DecodeBuildMark(values)
    local out = {}
    for i, value in ipairs(values) do
        out[i] = string.char(value - 3)
    end
    return table.concat(out)
end

-- Local library rebuild note: keep this addon intentionally offline and packaged-only.
local defaults = {
    schemaVersion = 1,
    volume = 50,
    previousVolume = 50,
    muted = false,
    currentIndex = 1,
    isPlaying = false,
    shuffle = false,
    repeatSong = false,
    autoNext = true,
    search = "",
    libraryView = "all",
    secretFrequencyUnlocked = false,
    hiddenFrequencyUnlocked = false,
    favorites = {},
    playlists = {},
    queue = {},
    seek = { offset = 0, lastPercent = 0 },
    sharing = { enabled = true, inbox = {} },
    selectedLibrarySongIndex = 1,
    selectedPlaylistIndex = 1,
    playlistEntryIndex = 1,
    playFromPlaylist = false,
    favoriteEntryIndex = 1,
    playFromFavorites = false,
    window = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0, width = 520, height = 420 },
    libraryWindow = { point = "CENTER", relativePoint = "CENTER", x = 60, y = -20, width = 520, height = 520 },
    playlistWindow = { point = "CENTER", relativePoint = "CENTER", x = 100, y = -40, width = 560, height = 520 },
    miniWindow = { point = "CENTER", relativePoint = "CENTER", x = 0, y = -180, width = 340, height = 98 },
    settingsWindow = { point = "CENTER", relativePoint = "CENTER", x = -60, y = -20, width = 420, height = 330 },
    addSongsWindow = { point = "CENTER", relativePoint = "CENTER", x = -90, y = -40, width = 560, height = 420 },
    hiddenFrequencyWindow = { point = "CENTER", relativePoint = "CENTER", x = 120, y = -60, width = 520, height = 360 },
    queueWindow = { point = "CENTER", relativePoint = "CENTER", x = 140, y = -80, width = 520, height = 420 },
    sharingWindow = { point = "CENTER", relativePoint = "CENTER", x = 160, y = -100, width = 540, height = 420 },
    minimap = { hide = false, angle = 225 },
}

local function CopyDefaults(source, destination)
    -- Keep saved settings without importing old radio/share state.
    for key, value in pairs(source) do
        if type(value) == "table" then
            destination[key] = destination[key] or {}
            CopyDefaults(value, destination[key])
        elseif destination[key] == nil then
            destination[key] = value
        end
    end
end

local function SaveFramePosition(frame, storage)
    if not frame or not storage then return end
    local point, _, relativePoint, x, y = frame:GetPoint()
    storage.point = point or "CENTER"
    storage.relativePoint = relativePoint or "CENTER"
    storage.x = x or 0
    storage.y = y or 0
    storage.width = frame:GetWidth()
    storage.height = frame:GetHeight()
end

function GuildRadioFM:Print(message)
    print("|cffffcc33GuildRadioFM:|r " .. tostring(message))
end

function GuildRadioFM:GetSignature()
    return DecodeBuildMark(BUILD_TRACE)
end

local function TrimValue(value)
    if strtrim then return strtrim(value or "") end
    return string.match(value or "", "^%s*(.-)%s*$")
end

local function SongKey(song)
    if not song then return nil end
    if song.id and song.id ~= "" then return "id:" .. string.lower(song.id) end
    if song.file and song.file ~= "" then return "file:" .. string.lower(song.file) end
    if song.title and song.title ~= "" then return "title:" .. string.lower(song.title) end
    return nil
end

function GuildRadioFM:ShowSignature()
    self:Print("Owner tag: " .. DecodeBuildMark(BUILD_OWNER))
    self:Print("Signature: " .. tostring(self:GetSignature()))
    self:Print(DecodeBuildMark(BUILD_NOTE))
end

function GuildRadioFM:IsSecretFrequencyUnlocked()
    return self.db and self.db.secretFrequencyUnlocked == true
end

function GuildRadioFM:IsHiddenSong(song)
    return type(song) == "table" and song.hidden == true
end

function GuildRadioFM:GetHiddenCategory(song)
    if type(song) == "table" and song.hiddenCategory and song.hiddenCategory ~= "" then
        return tostring(song.hiddenCategory)
    end
    return SECRET_FREQUENCY_CATEGORY
end

function GuildRadioFM:CanShowSongInLibrary(song, view)
    if not self:IsHiddenSong(song) then return view ~= "secret" end
    return view == "secret" and self:IsSecretFrequencyUnlocked()
end

function GuildRadioFM:GetSecretFrequencySongCount()
    local count = 0
    for _, song in ipairs(self.songs or {}) do
        if self:IsHiddenSong(song) and self:GetHiddenCategory(song) == SECRET_FREQUENCY_CATEGORY then
            count = count + 1
        end
    end
    return count
end

function GuildRadioFM:UnlockSecretFrequency(code)
    if self:IsSecretFrequencyUnlocked() then
        self:Print("Secret Frequency already unlocked.")
        return true
    end
    code = TrimValue(code)
    if code ~= SECRET_FREQUENCY_CODE then
        self:Print("Only static answers.")
        return false
    end
    self.db.secretFrequencyUnlocked = true
    self.db.libraryView = "secret"
    self.db.libraryScroll = 0
    self:Print("Secret Frequency unlocked.")
    self:RefreshAll()
    return true
end

function GuildRadioFM:ResetSecretFrequency()
    self.db.secretFrequencyUnlocked = false
    if self.db.libraryView == "secret" then
        self.db.libraryView = "all"
        self.db.libraryScroll = 0
    end
    self:Print("Secret Frequency locked.")
    self:RefreshAll()
end

function GuildRadioFM:RebuildSongLibrary()
    local songs = {}
    local seenId = {}
    local seenFile = {}
    local seenTitle = {}
    local songIndexById = {}

    local function addSong(song, packId)
        if type(song) ~= "table" or not song.file or song.file == "" then return nil end
        local copy = {}
        for key, value in pairs(song) do copy[key] = value end
        if packId and (not copy.id or copy.id == "") then
            copy.id = tostring(packId) .. ":" .. tostring(copy.title or copy.file)
        end
        local idKey = copy.id and string.lower(copy.id) or nil
        local fileKey = copy.file and string.lower(copy.file) or nil
        local titleKey = copy.title and string.lower(copy.title) or nil
        if idKey and seenId[idKey] then return seenId[idKey] end
        if fileKey and seenFile[fileKey] then return seenFile[fileKey] end
        if titleKey and seenTitle[titleKey] then return seenTitle[titleKey] end
        songs[#songs + 1] = copy
        local index = #songs
        if idKey then seenId[idKey] = index end
        if fileKey then seenFile[fileKey] = index end
        if titleKey then seenTitle[titleKey] = index end
        if copy.id then songIndexById[copy.id] = index end
        return index
    end

    for _, song in ipairs(GuildRadioFMSongList or {}) do
        addSong(song)
    end

    self.runtimePlaylists = {}
    for _, pack in pairs(self.songPacks or {}) do
        local playlist = {
            name = pack.playlistName or pack.packName or pack.packId or "Song Pack",
            songs = {},
            runtime = true,
            packId = pack.packId,
        }
        for _, song in ipairs(pack.songs or {}) do
            local index = addSong(song, pack.packId)
            if index then
                local already = false
                for _, existingIndex in ipairs(playlist.songs) do
                    if existingIndex == index then already = true break end
                end
                if not already then playlist.songs[#playlist.songs + 1] = index end
            end
        end
        if #playlist.songs > 0 then
            self.runtimePlaylists[#self.runtimePlaylists + 1] = playlist
        end
    end

    self.songs = songs
    self.songIndexById = songIndexById
end

function GuildRadioFM.RegisterSongPack(pack)
    local self = GuildRadioFM
    if type(pack) ~= "table" then return false end
    local packId = TrimValue(pack.packId or pack.packName or pack.playlistName)
    if packId == "" then return false end

    self.songPacks = self.songPacks or {}
    pack.packId = packId
    pack.packName = pack.packName or packId
    pack.playlistName = pack.playlistName or pack.packName
    self.songPacks[packId] = pack
    if self.RegisterLyricsTable and type(pack.lyrics) == "table" then
        self:RegisterLyricsTable(pack.lyrics)
    end
    if self.RegisterSongLyrics then
        for _, song in ipairs(pack.songs or {}) do
            self:RegisterSongLyrics(song)
        end
    end

    if self.db then
        self:RebuildSongLibrary()
        self.db.currentIndex = self:NormalizeIndex(self.db.currentIndex)
        self:EnsurePlaylists()
        self:RefreshAll()
    end

    self:Print((pack.packName or packId) .. " loaded.")
    return true
end

function GuildRadioFM.AddSong(song)
    return GuildRadioFM.RegisterSongPack({
        packId = "Loose Songs",
        packName = "Loose Songs",
        playlistName = "Loose Songs",
        songs = { song },
    })
end

GuildRadioFM.RegisterSong = GuildRadioFM.AddSong

function GuildRadioFM:Initialize()
    if type(GuildRadioFMDB) ~= "table" then GuildRadioFMDB = {} end
    CopyDefaults(defaults, GuildRadioFMDB)

    self.db = GuildRadioFMDB
    self.db.schemaVersion = 1
    self.songPacks = self.songPacks or {}
    -- Easter egg locks are playful discovery states, not DRM. Addon code is always inspectable.
    self.db.hiddenFrequencyUnlocked = false
    self._foundSignal404 = false
    self:RebuildSongLibrary()
    self.db.favorites = self.db.favorites or {}
    self:EnsurePlaylists()
    if self.InitializeQueue then self:InitializeQueue() end
    if self.InitializeSeek then self:InitializeSeek() end
    if self.InitializeSharing then self:InitializeSharing() end
    self.db.currentIndex = self:NormalizeIndex(self.db.currentIndex)
    self.db.selectedLibrarySongIndex = self:NormalizeIndex(self.db.selectedLibrarySongIndex)
    self.db.isPlaying = false
    self.startedAt = nil
    self.lastPlayStartedAt = nil
    self.playbackToken = 0
    self.autoAdvanceToken = nil
    self.playbackAdvanceInProgress = false
    self.soundHandle = nil

    self:CreateEventFrame()
    self:SetDialogVolume(self.db.muted and 0 or self.db.volume)
    if self.RefreshPlaybackTicker then self:RefreshPlaybackTicker() end
    if self.CreateMinimapButton then self:CreateMinimapButton() end
    if self.CreateOptionsPanel then self:CreateOptionsPanel() end
    self:Print("v" .. self.Version .. " loaded. Use /grfm or /grfm help.")
end

function GuildRadioFM:EnsurePlaylists()
    self.db.playlists = self.db.playlists or {}
    self.db.selectedPlaylistIndex = tonumber(self.db.selectedPlaylistIndex) or 1
    self.db.playlistEntryIndex = tonumber(self.db.playlistEntryIndex) or 1
    if self.db.selectedPlaylistIndex < 1 then self.db.selectedPlaylistIndex = 1 end
    local totalPlaylists = self:GetPlaylistCount()
    if self.db.selectedPlaylistIndex > totalPlaylists and totalPlaylists > 0 then
        self.db.selectedPlaylistIndex = totalPlaylists
    end
end

function GuildRadioFM:GetUserPlaylistCount()
    self.db.playlists = self.db.playlists or {}
    return #self.db.playlists
end

function GuildRadioFM:GetAllPlaylists()
    local playlists = {}
    for _, playlist in ipairs(self.db.playlists or {}) do
        playlists[#playlists + 1] = playlist
    end
    for _, playlist in ipairs(self.runtimePlaylists or {}) do
        playlists[#playlists + 1] = playlist
    end
    return playlists
end

function GuildRadioFM:GetPlaylistCount()
    return #(self.db and self.db.playlists or {}) + #(self.runtimePlaylists or {})
end

function GuildRadioFM:NormalizeIndex(index)
    local count = self:GetSongCount()
    index = tonumber(index) or 1
    if count == 0 then return 0 end
    if index < 1 then return count end
    if index > count then return 1 end
    return index
end

function GuildRadioFM:GetSongCount()
    return #(self.songs or GuildRadioFMSongList or {})
end

function GuildRadioFM:GetSong(index)
    local songs = self.songs or GuildRadioFMSongList or {}
    index = self:NormalizeIndex(index or self.db.currentIndex)
    if index == 0 then return nil end
    return songs[index], index
end

function GuildRadioFM:GetCurrentSong()
    return self:GetSong(self.db.currentIndex)
end

function GuildRadioFM:GetCurrentTitle()
    local song = self:GetCurrentSong()
    if song and song.title then return song.title end
    return "No local songs found"
end

function GuildRadioFM:IsFavorite(index)
    index = self:NormalizeIndex(index or self.db.currentIndex)
    return index > 0 and self.db.favorites and self.db.favorites[index] == true
end

function GuildRadioFM:GetFavoriteIndices()
    local indices = {}
    for index in ipairs(self.songs or {}) do
        if self:IsFavorite(index) then
            indices[#indices + 1] = index
        end
    end
    return indices
end

function GuildRadioFM:NormalizeFavoriteEntry(index)
    local favorites = self:GetFavoriteIndices()
    index = tonumber(index) or 1
    if #favorites == 0 then return 0 end
    if index < 1 then return #favorites end
    if index > #favorites then return 1 end
    return index
end

function GuildRadioFM:GetFavoriteEntryForSong(songIndex)
    songIndex = self:NormalizeIndex(songIndex or self.db.currentIndex)
    for entryIndex, favoriteSongIndex in ipairs(self:GetFavoriteIndices()) do
        if favoriteSongIndex == songIndex then return entryIndex end
    end
    return 1
end

function GuildRadioFM:UseFavorites(entryIndex)
    local favorites = self:GetFavoriteIndices()
    if #favorites == 0 then return false end
    self.db.playFromPlaylist = false
    self.db.playFromFavorites = true
    self.db.favoriteEntryIndex = self:NormalizeFavoriteEntry(entryIndex or self.db.favoriteEntryIndex)
    self.db.currentIndex = self:NormalizeIndex(favorites[self.db.favoriteEntryIndex])
    return self.db.currentIndex > 0
end

function GuildRadioFM:ToggleFavorite(index)
    index = self:NormalizeIndex(index or self.db.currentIndex)
    local song = self:GetSong(index)
    if not song then
        self:Print("No song selected.")
        return
    end
    self.db.favorites = self.db.favorites or {}
    self.db.favorites[index] = not self.db.favorites[index] or nil
    if self.db.playFromFavorites then
        if self.db.favorites[index] then
            self.db.favoriteEntryIndex = self:GetFavoriteEntryForSong(index)
        elseif #self:GetFavoriteIndices() == 0 then
            self.db.playFromFavorites = false
        else
            self:UseFavorites(self.db.favoriteEntryIndex)
        end
    end
    self:Print((self.db.favorites[index] and "Liked: " or "Unliked: ") .. (song.title or ("Song " .. tostring(index))))
    self:RefreshAll()
end

function GuildRadioFM:RemoveFavorite(index)
    index = self:NormalizeIndex(index or self.db.currentIndex)
    local song = self:GetSong(index)
    if not song then
        self:Print("No song selected.")
        return
    end

    self.db.favorites = self.db.favorites or {}
    if not self.db.favorites[index] then
        self:Print("That song is not liked.")
        return
    end

    self.db.favorites[index] = nil
    if self.db.playFromFavorites then
        local favorites = self:GetFavoriteIndices()
        if #favorites == 0 then
            self.db.playFromFavorites = false
        else
            self:UseFavorites(self.db.favoriteEntryIndex)
        end
    end

    self:Print("Removed from liked: " .. (song.title or ("Song " .. tostring(index))))
    self:RefreshAll()
end

function GuildRadioFM:PlayFavoriteEntry(entryIndex)
    if not self:UseFavorites(entryIndex or self:GetFavoriteEntryForSong(self.db.currentIndex)) then
        self:Print("No liked songs yet.")
        return
    end
    self:Play()
end

function GuildRadioFM:SetLibraryView(view)
    view = string.lower(view or "all")
    if view == "secret" and not self:IsSecretFrequencyUnlocked() then view = "all" end
    if view ~= "all" and view ~= "favorites" and view ~= "secret" then view = "all" end
    self.db.libraryView = view
    self.db.libraryScroll = 0
    self:RefreshAll()
end

function GuildRadioFM:GetSelectedPlaylist()
    self:EnsurePlaylists()
    local playlists = self:GetAllPlaylists()
    return playlists[self.db.selectedPlaylistIndex], self.db.selectedPlaylistIndex
end

function GuildRadioFM:GetPlaylistEntryCount()
    local playlist = self:GetSelectedPlaylist()
    return playlist and playlist.songs and #playlist.songs or 0
end

function GuildRadioFM:NormalizePlaylistEntry(index)
    local count = self:GetPlaylistEntryCount()
    index = tonumber(index) or 1
    if count == 0 then return 0 end
    if index < 1 then return count end
    if index > count then return 1 end
    return index
end

function GuildRadioFM:UseSelectedPlaylist(entryIndex)
    local playlist = self:GetSelectedPlaylist()
    if not playlist or not playlist.songs or #playlist.songs == 0 then return false end
    self.db.playFromPlaylist = true
    self.db.playFromFavorites = false
    self.db.playlistEntryIndex = self:NormalizePlaylistEntry(entryIndex or self.db.playlistEntryIndex)
    self.db.currentIndex = self:NormalizeIndex(playlist.songs[self.db.playlistEntryIndex])
    return self.db.currentIndex > 0
end

function GuildRadioFM:CreatePlaylist(name)
    self:EnsurePlaylists()
    name = strtrim and strtrim(name or "") or string.match(name or "", "^%s*(.-)%s*$")
    if name == "" then name = "Playlist " .. tostring(#self.db.playlists + 1) end
    self.db.playlists[#self.db.playlists + 1] = { name = name, songs = {} }
    self.db.selectedPlaylistIndex = #self.db.playlists
    self.db.playlistEntryIndex = 1
    self.db.playlistScroll = #self.db.playlists
    self.db.playlistSongScroll = 0
    self:Print("Created playlist: " .. name)
    self:RefreshAll()
end

function GuildRadioFM:DeleteSelectedPlaylist()
    local playlist, index = self:GetSelectedPlaylist()
    if not playlist then
        self:Print("No playlist selected.")
        return
    end
    if playlist.runtime then
        self:Print("Song pack playlists are managed by their expansion addon.")
        return
    end
    table.remove(self.db.playlists, index)
    self.db.selectedPlaylistIndex = math.min(index, #self.db.playlists)
    if self.db.selectedPlaylistIndex < 1 then self.db.selectedPlaylistIndex = 1 end
    self.db.playlistEntryIndex = 1
    self.db.playFromPlaylist = false
    self:Print("Deleted playlist: " .. playlist.name)
    self:RefreshAll()
end

function GuildRadioFM:SelectPlaylist(index)
    self:EnsurePlaylists()
    index = tonumber(index) or 1
    if index < 1 or index > self:GetPlaylistCount() then return end
    self.db.selectedPlaylistIndex = index
    self.db.playlistEntryIndex = 1
    self.db.playlistSongScroll = 0
    self:UseSelectedPlaylist(1)
    self:RefreshAll()
end

function GuildRadioFM:AddSongToSelectedPlaylist(songIndex)
    local playlist = self:GetSelectedPlaylist()
    local song = self:GetSong(songIndex)
    if not playlist then
        self:Print("Create a playlist first.")
        return
    end
    if playlist.runtime then
        self:Print("Song pack playlists cannot be edited.")
        return
    end
    if not song then
        self:Print("That song is not in the local library.")
        return
    end
    playlist.songs = playlist.songs or {}
    local wasEmpty = #playlist.songs == 0
    playlist.songs[#playlist.songs + 1] = tonumber(songIndex)
    if wasEmpty then self:UseSelectedPlaylist(1) end
    self:Print("Added to " .. playlist.name .. ": " .. (song.title or ("Song " .. tostring(songIndex))))
    self:RefreshAll()
end

function GuildRadioFM:RemovePlaylistSong(entryIndex)
    local playlist = self:GetSelectedPlaylist()
    if not playlist or not playlist.songs then return end
    if playlist.runtime then
        self:Print("Song pack playlists cannot be edited.")
        return
    end
    entryIndex = tonumber(entryIndex) or 0
    if entryIndex < 1 or entryIndex > #playlist.songs then return end
    table.remove(playlist.songs, entryIndex)
    self.db.playlistSongScroll = 0
    if self.db.playlistEntryIndex > #playlist.songs then self.db.playlistEntryIndex = #playlist.songs end
    if self.db.playlistEntryIndex < 1 then self.db.playlistEntryIndex = 1 end
    if #playlist.songs == 0 then
        self.db.playFromPlaylist = false
    elseif self.db.playFromPlaylist then
        self:UseSelectedPlaylist(self.db.playlistEntryIndex)
    end
    self:RefreshAll()
end

function GuildRadioFM:MovePlaylistSong(entryIndex, direction)
    local playlist = self:GetSelectedPlaylist()
    if not playlist or not playlist.songs then return end
    if playlist.runtime then
        self:Print("Song pack playlists cannot be edited.")
        return
    end
    entryIndex = tonumber(entryIndex) or self.db.playlistEntryIndex or 1
    direction = tonumber(direction) or 0
    local targetIndex = entryIndex + direction
    if entryIndex < 1 or entryIndex > #playlist.songs then return end
    if targetIndex < 1 or targetIndex > #playlist.songs then return end

    playlist.songs[entryIndex], playlist.songs[targetIndex] = playlist.songs[targetIndex], playlist.songs[entryIndex]
    self.db.playlistEntryIndex = targetIndex
    if self.db.playFromPlaylist then self:UseSelectedPlaylist(targetIndex) end
    self:RefreshAll()
end

function GuildRadioFM:ClearSelectedPlaylist()
    local playlist = self:GetSelectedPlaylist()
    if not playlist then
        self:Print("No playlist selected.")
        return
    end
    if playlist.runtime then
        self:Print("Song pack playlists cannot be edited.")
        return
    end
    playlist.songs = {}
    self.db.playlistEntryIndex = 1
    self.db.playlistSongScroll = 0
    self.db.playFromPlaylist = false
    self:Print("Cleared playlist: " .. playlist.name)
    self:RefreshAll()
end

function GuildRadioFM:PlayPlaylistEntry(entryIndex)
    if not self:UseSelectedPlaylist(entryIndex) then
        self:Print("Selected playlist is empty.")
        return
    end
    self:Play()
end

function GuildRadioFM:SetCurrentIndex(index)
    self.db.currentIndex = self:NormalizeIndex(index)
    self.startedAt = nil
    self:RefreshAll()
end

function GuildRadioFM:GetNextIndex(direction)
    local count = self:GetSongCount()
    if count == 0 then return 0 end
    local playlist = self:GetSelectedPlaylist()
    if self.db.playFromPlaylist and playlist and playlist.songs and #playlist.songs > 0 then
        local entryCount = #playlist.songs
        local entryIndex = self.db.playlistEntryIndex or 1
        if self.db.shuffle and entryCount > 1 then
            local nextEntry = entryIndex
            for _ = 1, 8 do
                nextEntry = math.random(1, entryCount)
                if nextEntry ~= entryIndex then break end
            end
            self.db.playlistEntryIndex = nextEntry
        else
            self.db.playlistEntryIndex = entryIndex + (direction or 1)
            if self.db.playlistEntryIndex < 1 then self.db.playlistEntryIndex = entryCount end
            if self.db.playlistEntryIndex > entryCount then self.db.playlistEntryIndex = 1 end
        end
        return self:NormalizeIndex(playlist.songs[self.db.playlistEntryIndex])
    end
    if self.db.playFromFavorites then
        local favorites = self:GetFavoriteIndices()
        if #favorites > 0 then
            local entryIndex = self.db.favoriteEntryIndex or self:GetFavoriteEntryForSong(self.db.currentIndex)
            if self.db.shuffle and #favorites > 1 then
                local nextEntry = entryIndex
                for _ = 1, 8 do
                    nextEntry = math.random(1, #favorites)
                    if nextEntry ~= entryIndex then break end
                end
                self.db.favoriteEntryIndex = nextEntry
            else
                self.db.favoriteEntryIndex = self:NormalizeFavoriteEntry(entryIndex + (direction or 1))
            end
            return self:NormalizeIndex(favorites[self.db.favoriteEntryIndex])
        end
        self.db.playFromFavorites = false
    end
    if self.db.shuffle and count > 1 then
        local current = self.db.currentIndex or 1
        local nextIndex = current
        for _ = 1, 8 do
            nextIndex = math.random(1, count)
            if nextIndex ~= current then break end
        end
        return nextIndex
    end
    return self:NormalizeIndex((self.db.currentIndex or 1) + (direction or 1))
end

function GuildRadioFM:Play(index)
    if index then
        self.db.playFromPlaylist = false
        self.db.playFromFavorites = false
        self.db.currentIndex = self:NormalizeIndex(index)
    elseif self.db.playFromPlaylist then
        self:UseSelectedPlaylist(self.db.playlistEntryIndex)
    elseif self.db.playFromFavorites then
        self:UseFavorites(self.db.favoriteEntryIndex)
    end

    local song = self:GetCurrentSong()
    if not song then
        self.db.isPlaying = false
        self:Print("No songs are listed in SongList.lua.")
        self:RefreshAll()
        return
    end

    self.playbackToken = (self.playbackToken or 0) + 1
    self.autoAdvanceToken = nil
    self.playbackAdvanceInProgress = false
    self.db.isPlaying = true
    self.startedAt = GetTime and GetTime() or nil
    self.lastPlayStartedAt = self.startedAt
    if self.ResetSeekState then self:ResetSeekState() end
    self.lastProgressRefresh = nil
    self.durationAdvanceStartedAt = nil

    local started = true
    if self.PlayLocalTrack then started = self:PlayLocalTrack(song) end
    if not started then
        self.db.isPlaying = false
        self.startedAt = nil
        self.lastPlayStartedAt = nil
        self.durationAdvanceStartedAt = nil
        self.autoAdvanceToken = nil
        if self.StopLyrics then self:StopLyrics() end
        self:RefreshAll()
        return
    end

    if self.db.isPlaying and self.StartLyrics then
        local songID = self.GetSongID and self:GetSongID(song) or song.id
        self:StartLyrics(songID)
    end
    if self.ShowNowPlayingToast then self:ShowNowPlayingToast(song) end
    if self.RefreshPlaybackTicker then self:RefreshPlaybackTicker() end
    self:RefreshAll()
end

function GuildRadioFM:Stop()
    self.playbackToken = (self.playbackToken or 0) + 1
    self.autoAdvanceToken = nil
    self.playbackAdvanceInProgress = false
    self.db.isPlaying = false
    self.startedAt = nil
    self.lastPlayStartedAt = nil
    if self.ResetSeekState then self:ResetSeekState() end
    self.durationAdvanceStartedAt = nil
    if self.StopLyrics then self:StopLyrics() end
    if self.StopLocalTrack then self:StopLocalTrack() end
    if self.RefreshPlaybackTicker then self:RefreshPlaybackTicker() end
    self:RefreshAll()
end

function GuildRadioFM:StopForWorldTransition(reason)
    self.playbackToken = (self.playbackToken or 0) + 1
    self.autoAdvanceToken = nil
    self.playbackAdvanceInProgress = false
    if self.StopLocalTrack then self:StopLocalTrack(reason or "world-transition") end
    self.db.isPlaying = false
    self.startedAt = nil
    self.lastPlayStartedAt = nil
    self.durationAdvanceStartedAt = nil
    self.lastProgressRefresh = nil
    if self.ResetSeekState then self:ResetSeekState() end
    if self.StopLyrics then self:StopLyrics() end
    if self.RefreshPlaybackTicker then self:RefreshPlaybackTicker() end
    self:RefreshAll()
end

function GuildRadioFM:Next()
    local nextIndex = self:GetNextIndex(1)
    if nextIndex == 0 then
        self:Stop()
        self:Print("No songs are listed in SongList.lua.")
        return
    end
    self.db.currentIndex = nextIndex
    if self.db.playFromPlaylist then
        self:UseSelectedPlaylist(self.db.playlistEntryIndex)
    elseif self.db.playFromFavorites then
        self:UseFavorites(self.db.favoriteEntryIndex)
    end
    self:Play()
end

function GuildRadioFM:Back()
    local nextIndex = self:GetNextIndex(-1)
    if nextIndex == 0 then
        self:Stop()
        self:Print("No songs are listed in SongList.lua.")
        return
    end
    self.db.currentIndex = nextIndex
    if self.db.playFromPlaylist then
        self:UseSelectedPlaylist(self.db.playlistEntryIndex)
    elseif self.db.playFromFavorites then
        self:UseFavorites(self.db.favoriteEntryIndex)
    end
    self:Play()
end

function GuildRadioFM:PlaySong(index)
    self.db.playFromPlaylist = false
    self.db.playFromFavorites = false
    self:Play(index)
end

function GuildRadioFM:ToggleShuffle()
    self.db.shuffle = not self.db.shuffle
    self:Print("Shuffle " .. (self.db.shuffle and "on." or "off."))
    self:RefreshAll()
end

function GuildRadioFM:ToggleRepeat()
    self.db.repeatSong = not self.db.repeatSong
    self:Print("Repeat " .. (self.db.repeatSong and "on." or "off."))
    self:RefreshAll()
end

function GuildRadioFM:ToggleAutoNext()
    self.db.autoNext = not self.db.autoNext
    self:Print("Auto-next " .. (self.db.autoNext and "on." or "off."))
    self:RefreshAll()
end

function GuildRadioFM:SetDialogVolume(amount)
    amount = tonumber(amount) or 0
    if amount < 0 then amount = 0 end
    if amount > 100 then amount = 100 end
    if self.originalDialogVolume == nil and GetCVar then
        self.originalDialogVolume = GetCVar("Sound_DialogVolume")
    end
    self.changedDialogVolume = true
    if SetCVar then SetCVar("Sound_DialogVolume", tostring(amount / 100)) end
end

function GuildRadioFM:RestoreDialogVolume()
    if self.changedDialogVolume and self.originalDialogVolume ~= nil and SetCVar then
        SetCVar("Sound_DialogVolume", tostring(self.originalDialogVolume))
    end
    self.changedDialogVolume = false
end

function GuildRadioFM:SetVolume(amount)
    amount = tonumber(amount)
    if not amount then
        self:Print("Volume must be a number from 0 to 100.")
        return
    end
    if amount < 0 then amount = 0 end
    if amount > 100 then amount = 100 end

    self.db.volume = amount
    if self.db.muted then
        if amount > 0 then self.db.previousVolume = amount end
        self:SetDialogVolume(0)
        self:RefreshAll()
        return
    end
    if amount > 0 then
        self.db.previousVolume = amount
    end
    self:SetDialogVolume(amount)
    self:Print("Dialog volume set to " .. amount .. "%.")
    self:RefreshAll()
end

function GuildRadioFM:ToggleMute()
    self.db.muted = not self.db.muted
    if self.db.muted then
        self.db.previousVolume = self.db.volume > 0 and self.db.volume or self.db.previousVolume
        self.db.resumeAfterMute = self.db.isPlaying
        if self.StopLocalTrack then self:StopLocalTrack() end
        self:SetDialogVolume(0)
        self:Print("Muted GuildRadioFM.")
    else
        self.db.volume = self.db.previousVolume or 50
        self:SetDialogVolume(self.db.volume)
        self:Print("Unmuted GuildRadioFM.")
        if self.db.resumeAfterMute then
            self.db.resumeAfterMute = false
            self:Play()
            return
        end
    end
    self:RefreshAll()
end

function GuildRadioFM:GetProgressText()
    local song = self:GetCurrentSong()
    if not self.db.isPlaying or not song then return "Stopped" end
    if self.GetSeekProgressText then return self:GetSeekProgressText() end
    if not song.duration or not self.startedAt or not GetTime then return "Playing" end

    local elapsed = math.max(0, math.floor(GetTime() - self.startedAt))
    local duration = math.max(1, tonumber(song.duration) or 1)
    if elapsed > duration then elapsed = duration end
    return string.format("%d:%02d / %d:%02d", math.floor(elapsed / 60), elapsed % 60, math.floor(duration / 60), duration % 60)
end

function GuildRadioFM:RefreshProgressDisplays()
    if self.UpdateMainWindow then self:UpdateMainWindow() end
    if self.UpdateMiniWindow then self:UpdateMiniWindow() end
end

function GuildRadioFM:AdvanceAfterTrackEnd(reason, token)
    -- Path-based MP3 playback does not produce a reliable event-driven finished
    -- signal in WoW. Auto-advance is intentionally owned by the duration clock.
    if token and token ~= self.playbackToken then return end
    if self.playbackAdvanceInProgress then return end
    self.playbackAdvanceInProgress = true

    if not self.db.isPlaying then
        self.playbackAdvanceInProgress = false
        return
    end
    if self.db.repeatSong then
        self:Play()
    elseif self.db.autoNext then
        self:Next()
    else
        self.db.isPlaying = false
        self.startedAt = nil
        self.durationAdvanceStartedAt = nil
        if self.StopLyrics then self:StopLyrics() end
        if self.StopLocalTrack then self:StopLocalTrack("duration-ended") end
        if self.RefreshPlaybackTicker then self:RefreshPlaybackTicker() end
        self:RefreshAll()
    end
    self.playbackAdvanceInProgress = false
end

function GuildRadioFM:HandleSoundFinished(handle)
    -- SOUNDKIT_FINISHED is useful for Blizzard sound kits, but local MP3 paths
    -- played with PlaySoundFile are not reliable enough to drive track changes.
    -- Keep this as a no-op so the duration clock remains the single authority.
end

function GuildRadioFM:HandlePlaybackTick()
    if not self.db or not self.db.isPlaying then return end

    local now = GetTime and GetTime() or nil
    if not now then return end

    if not self.lastProgressRefresh or now - self.lastProgressRefresh >= 1 then
        self.lastProgressRefresh = now
        self:RefreshProgressDisplays()
    end

    local song = self:GetCurrentSong()
    local duration = song and tonumber(song.duration) or nil
    -- Missing duration is allowed: the song can play and manual controls still
    -- work, but GuildRadioFM will not invent a fake end time or auto-advance.
    if not duration or duration <= 0 or not self.startedAt then return end
    local token = self.playbackToken
    if self.autoAdvanceToken == token then return end

    if now - self.startedAt >= duration then
        self.autoAdvanceToken = token
        self.durationAdvanceStartedAt = self.startedAt
        self:AdvanceAfterTrackEnd("duration", token)
    end
end

function GuildRadioFM:CreateEventFrame()
    if self.eventFrame then return end
    local frame = CreateFrame("Frame")
    self.eventFrame = frame
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:RegisterEvent("PLAYER_LEAVING_WORLD")
    frame:RegisterEvent("LOADING_SCREEN_ENABLED")
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_ADDON" and GuildRadioFM.HandleAddonMessage then
            GuildRadioFM:HandleAddonMessage(...)
        elseif event == "PLAYER_LOGOUT" or event == "PLAYER_LEAVING_WORLD" or event == "LOADING_SCREEN_ENABLED" then
            if event == "PLAYER_LOGOUT" and GuildRadioFM.RestoreDialogVolume then
                GuildRadioFM:RestoreDialogVolume()
            end
            GuildRadioFM:StopForWorldTransition(event)
        end
    end)
    self.playbackOnUpdate = function()
        if GuildRadioFM.UpdateLyrics then GuildRadioFM:UpdateLyrics() end
        GuildRadioFM:HandlePlaybackTick()
        if GuildRadioFM.RefreshPlaybackTicker then GuildRadioFM:RefreshPlaybackTicker() end
    end
    self:RefreshPlaybackTicker()
end

function GuildRadioFM:RefreshPlaybackTicker()
    if not self.eventFrame then return end
    local lyricsActive = self.lyricState and self.lyricState.active
    local playing = self.db and self.db.isPlaying
    if playing or lyricsActive then
        self.eventFrame:SetScript("OnUpdate", self.playbackOnUpdate)
    else
        self.eventFrame:SetScript("OnUpdate", nil)
    end
end

function GuildRadioFM:Reset()
    GuildRadioFMDB = {}
    CopyDefaults(defaults, GuildRadioFMDB)
    self.db = GuildRadioFMDB
    self.db.schemaVersion = 1
    self:RebuildSongLibrary()
    self.db.favorites = self.db.favorites or {}
    self:EnsurePlaylists()
    if self.InitializeQueue then self:InitializeQueue() end
    self:Stop()
    self:SetDialogVolume(self.db.volume)
    self:Print("Settings reset.")
    self:RefreshAll()
end

function GuildRadioFM:SaveWindow(frame, storage)
    SaveFramePosition(frame, storage)
end

function GuildRadioFM:RefreshAll()
    if self.UpdateMainWindow then self:UpdateMainWindow() end
    if self.UpdateMiniWindow then self:UpdateMiniWindow() end
    if self.UpdateLibraryWindow then self:UpdateLibraryWindow() end
    if self.UpdatePlaylistWindow then self:UpdatePlaylistWindow() end
    if self.UpdateQueueWindow then self:UpdateQueueWindow() end
    if self.UpdateSettingsWindow then self:UpdateSettingsWindow() end
    if self.UpdateOptionsPanel then self:UpdateOptionsPanel() end
    if self.UpdateMinimapButton then self:UpdateMinimapButton() end
end

local addonFrame = CreateFrame("Frame")
addonFrame:RegisterEvent("ADDON_LOADED")
addonFrame:SetScript("OnEvent", function(_, _, addonName)
    if addonName == "GuildRadioFM" then
        GuildRadioFM:Initialize()
    end
end)
