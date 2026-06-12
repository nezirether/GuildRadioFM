local GOLD = { 0.86, 0.66, 0.24, 1 }
local DARK = { 0.035, 0.03, 0.025, 0.96 }
local DARKER = { 0.015, 0.012, 0.01, 0.98 }
local HILITE = { 0.22, 0.16, 0.06, 0.9 }
local LYRIC_CURRENT = { 1, 0.92, 0.68, 1 }
local LYRIC_CONTEXT = { 0.72, 0.64, 0.48, 1 }
local LYRIC_MUTED = { 0.48, 0.43, 0.34, 1 }
local ICON_TEXTURE = "Interface\\AddOns\\GuildRadioFM\\Media\\GuildRadioFM_Icon.tga"

-- Dark panels and gold trim for the local player UI.
local function ApplyPanel(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(DARK[1], DARK[2], DARK[3], DARK[4])
    frame:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], GOLD[4])
end

local function ApplyInset(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(DARKER[1], DARKER[2], DARKER[3], DARKER[4])
    frame:SetBackdropBorderColor(0.32, 0.24, 0.1, 1)
end

local function MakeText(parent, font, justify)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(font or "GameFontNormal")
    text:SetJustifyH(justify or "LEFT")
    text:SetTextColor(1, 0.88, 0.58)
    return text
end

local function AddTooltip(frame, title, text)
    if not frame then return end
    if frame.SetMotionScriptsWhileDisabled then frame:SetMotionScriptsWhileDisabled(true) end
    frame:SetScript("OnEnter", function(selfFrame)
        if not GameTooltip then return end
        GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 0.82, 0.25)
        if text and text ~= "" then
            GameTooltip:AddLine(text, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

local RaiseWindow

local function RefreshWindowForKey(key)
    if key == "mainFrame" and GuildRadioFM.UpdateMainWindow then
        GuildRadioFM:UpdateMainWindow()
    elseif key == "miniFrame" and GuildRadioFM.UpdateMiniWindow then
        GuildRadioFM:UpdateMiniWindow()
    elseif key == "libraryFrame" and GuildRadioFM.UpdateLibraryWindow then
        GuildRadioFM:UpdateLibraryWindow()
    elseif key == "playlistFrame" and GuildRadioFM.UpdatePlaylistWindow then
        GuildRadioFM:UpdatePlaylistWindow()
    elseif key == "queueFrame" and GuildRadioFM.UpdateQueueWindow then
        GuildRadioFM:UpdateQueueWindow()
    elseif key == "sharingFrame" and GuildRadioFM.UpdateSharingWindow then
        GuildRadioFM:UpdateSharingWindow()
    elseif key == "settingsFrame" and GuildRadioFM.UpdateSettingsWindow then
        GuildRadioFM:UpdateSettingsWindow()
    elseif key == "hiddenFrequencyFrame" and GuildRadioFM.UpdateHiddenFrequencyWindow then
        GuildRadioFM:UpdateHiddenFrequencyWindow()
    end
end

local function GetOwningWindow(frame)
    local current = frame
    local owner = frame
    while current and current ~= UIParent do
        owner = current
        current = current:GetParent()
    end
    return owner
end

local function MakeButton(parent, label, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 70, height or 24)
    button:SetText(label)
    button:SetScript("OnClick", function(selfButton, ...)
        RaiseWindow(GetOwningWindow(selfButton))
        onClick(selfButton, ...)
    end)
    return button
end

local function MakeToggleButton(parent, label, onClick)
    local button = MakeButton(parent, label, 92, 24, onClick)
    button.stateText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    button.stateText:SetPoint("CENTER")
    return button
end

local function MakeCheckButton(parent, label, onClick)
    local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("LEFT", button, "RIGHT", 2, 0)
    button.text:SetText(label)
    button:SetScript("OnClick", onClick)
    return button
end

local function GetVisibleRowCount(container, rowHeight, maxRows)
    local height = container and container:GetHeight() or 0
    local count = math.floor(math.max(0, height - 8) / rowHeight)
    if count < 1 then count = 1 end
    if count > maxRows then count = maxRows end
    return count
end

local function ClampScrollOffset(offset, totalRows, visibleRows)
    local maxOffset = math.max(0, (totalRows or 0) - (visibleRows or 0))
    offset = tonumber(offset) or 0
    if offset < 0 then offset = 0 end
    if offset > maxOffset then offset = maxOffset end
    return offset
end

local function AddMouseWheelScroll(frame, getState, updateFunc)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, delta)
        RaiseWindow(GetOwningWindow(frame))
        local db, key, totalRows, visibleRows = getState()
        if not db or not key then return end
        db[key] = ClampScrollOffset((db[key] or 0) - delta, totalRows, visibleRows)
        updateFunc()
    end)
end

RaiseWindow = function(frame)
    if not frame then return end
    GuildRadioFM.frameLevel = (GuildRadioFM.frameLevel or 100) + 10
    if GuildRadioFM.frameLevel > 9000 then GuildRadioFM.frameLevel = 110 end
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(GuildRadioFM.frameLevel)
end

local function RestoreFrame(frame, saved, fallbackWidth, fallbackHeight)
    frame:SetSize(saved.width or fallbackWidth, saved.height or fallbackHeight)
    frame:SetPoint(saved.point or "CENTER", UIParent, saved.relativePoint or "CENTER", saved.x or 0, saved.y or 0)
end

local function SetResizeLimits(frame, minWidth, minHeight, maxWidth, maxHeight)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
        return
    end
    if frame.SetMinResize then frame:SetMinResize(minWidth, minHeight) end
    if frame.SetMaxResize then frame:SetMaxResize(maxWidth, maxHeight) end
end

local function MakeResizeGrip(frame, saved)
    frame:SetResizable(true)
    SetResizeLimits(frame, 260, 80, 900, 760)

    local grip = CreateFrame("Button", nil, frame)
    grip:SetSize(14, 14)
    grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function()
        RaiseWindow(frame)
        frame:StartSizing("BOTTOMRIGHT")
    end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        GuildRadioFM:SaveWindow(frame, saved)
        GuildRadioFM:RefreshAll()
    end)
end

local function MakeWindow(key, name, title, width, height)
    -- Every window remembers its own spot and rises when touched.
    local frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    GuildRadioFM[key] = frame
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    ApplyPanel(frame)
    RaiseWindow(frame)

    local storageKey = key == "mainFrame" and "window" or string.gsub(key, "Frame$", "Window")
    local saved = GuildRadioFM.db[storageKey] or GuildRadioFM.db.window
    RestoreFrame(frame, saved, width, height)
    MakeResizeGrip(frame, saved)

    frame:SetScript("OnMouseDown", function(selfFrame) RaiseWindow(selfFrame) end)
    frame:SetScript("OnDragStart", function(selfFrame)
        RaiseWindow(selfFrame)
        selfFrame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(selfFrame)
        selfFrame:StopMovingOrSizing()
        GuildRadioFM:SaveWindow(selfFrame, saved)
    end)
    frame:SetScript("OnSizeChanged", function()
        RefreshWindowForKey(key)
    end)

    frame.title = MakeText(frame, "GameFontHighlightLarge", "CENTER")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -10)
    frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -32, -10)
    frame.title:SetText(title)

    frame.close = MakeButton(frame, "X", 22, 22, function() frame:Hide() end)
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -7, -7)

    frame:SetScript("OnShow", function(selfFrame) RaiseWindow(selfFrame) end)
    frame:Hide()
    return frame
end

function GuildRadioFM:CreateMainWindow()
    if self.mainFrame then return end

    local frame = MakeWindow("mainFrame", "GuildRadioFMMainFrame", "GuildRadioFM Maxi Player", 520, 420)
    SetResizeLimits(frame, 420, 330, 900, 760)
    if frame:GetWidth() < 420 or frame:GetHeight() < 330 then frame:SetSize(520, 420) end
    frame.songText = MakeText(frame, "GameFontHighlight")
    frame.songText:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -46)
    frame.songText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -46)

    frame.progressText = MakeText(frame, "GameFontNormalSmall")
    frame.progressText:SetPoint("TOPLEFT", frame.songText, "BOTTOMLEFT", 0, -8)
    frame.progressText:SetPoint("TOPRIGHT", frame.songText, "BOTTOMRIGHT", 0, -8)

    frame.stateText = MakeText(frame, "GameFontNormalSmall")
    frame.stateText:SetPoint("TOPLEFT", frame.progressText, "BOTTOMLEFT", 0, -8)
    frame.stateText:SetPoint("TOPRIGHT", frame.progressText, "BOTTOMRIGHT", 0, -8)

    local controls = CreateFrame("Frame", nil, frame)
    controls:SetPoint("TOPLEFT", frame.stateText, "BOTTOMLEFT", 0, -18)
    controls:SetSize(320, 26)
    frame.controls = controls

    MakeButton(controls, "Back", 62, 24, function() GuildRadioFM:Back() end):SetPoint("LEFT", controls, "LEFT", 0, 0)
    MakeButton(controls, "Play", 62, 24, function() GuildRadioFM:Play() end):SetPoint("LEFT", controls, "LEFT", 68, 0)
    MakeButton(controls, "Stop", 62, 24, function() GuildRadioFM:Stop() end):SetPoint("LEFT", controls, "LEFT", 136, 0)
    MakeButton(controls, "Next", 62, 24, function() GuildRadioFM:Next() end):SetPoint("LEFT", controls, "LEFT", 204, 0)

    frame.volumeText = MakeText(frame, "GameFontNormalSmall")
    frame.volumeText:SetPoint("TOPLEFT", controls, "BOTTOMLEFT", 0, -16)
    frame.volumeText:SetText("Volume")

    frame.volumeSlider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    frame.volumeSlider:SetPoint("LEFT", frame.volumeText, "RIGHT", 12, 0)
    frame.volumeSlider:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
    frame.volumeSlider:SetMinMaxValues(0, 100)
    frame.volumeSlider:SetValueStep(1)
    frame.volumeSlider:SetObeyStepOnDrag(true)
    frame.volumeSlider:SetScript("OnValueChanged", function(_, value)
        if GuildRadioFM.suppressVolumeUpdate then return end
        GuildRadioFM:SetVolume(math.floor(value + 0.5))
    end)
    frame.volumeSlider.Low:SetText("0")
    frame.volumeSlider.High:SetText("100")
    frame.volumeSlider.Text:SetText("")

    frame.seekText = MakeText(frame, "GameFontNormalSmall")
    frame.seekText:SetPoint("TOPLEFT", frame.volumeText, "BOTTOMLEFT", 0, -18)
    frame.seekText:SetText("Seek Preview")

    frame.seekBackButton = MakeButton(frame, "-10", 42, 22, function() GuildRadioFM:SeekBy(-10) end)
    frame.seekBackButton:SetPoint("LEFT", frame.seekText, "RIGHT", 12, 0)
    frame.restartButton = MakeButton(frame, "Restart", 66, 22, function() GuildRadioFM:RestartCurrentTrack() end)
    frame.restartButton:SetPoint("LEFT", frame.seekBackButton, "RIGHT", 6, 0)
    frame.seekForwardButton = MakeButton(frame, "+10", 42, 22, function() GuildRadioFM:SeekBy(10) end)
    frame.seekForwardButton:SetPoint("LEFT", frame.restartButton, "RIGHT", 6, 0)

    frame.seekSlider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    frame.seekSlider:SetPoint("LEFT", frame.seekForwardButton, "RIGHT", 12, 0)
    frame.seekSlider:SetPoint("RIGHT", frame, "RIGHT", -28, 0)
    frame.seekSlider:SetMinMaxValues(0, 100)
    frame.seekSlider:SetValueStep(1)
    frame.seekSlider:SetObeyStepOnDrag(true)
    frame.seekSlider:SetScript("OnValueChanged", function(_, value)
        if GuildRadioFM.suppressSeekUpdate then return end
        GuildRadioFM:SeekToPercent(math.floor(value + 0.5), true)
    end)
    frame.seekSlider.Low:SetText("")
    frame.seekSlider.High:SetText("")
    frame.seekSlider.Text:SetText("")
    frame.seekBackButton:Disable()
    frame.seekForwardButton:Disable()
    frame.seekSlider:Disable()
    AddTooltip(frame.seekBackButton, "Seek Preview", "Preview feature. WoW cannot currently seek within MP3 playback.")
    AddTooltip(frame.seekForwardButton, "Seek Preview", "Preview feature. WoW cannot currently seek within MP3 playback.")
    AddTooltip(frame.seekSlider, "Seek Preview", "Shows playback position when duration is known. Drag seeking is not available inside WoW MP3 playback.")
    AddTooltip(frame.restartButton, "Restart Track", "Stops and starts the current track from the beginning.")

    frame.lyricsFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.lyricsFrame:SetPoint("TOPLEFT", frame.seekText, "BOTTOMLEFT", 0, -18)
    frame.lyricsFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 54)
    ApplyInset(frame.lyricsFrame)

    frame.lyricsTitle = MakeText(frame.lyricsFrame, "GameFontNormalSmall")
    frame.lyricsTitle:SetPoint("TOPLEFT", frame.lyricsFrame, "TOPLEFT", 10, -8)
    frame.lyricsTitle:SetPoint("TOPRIGHT", frame.lyricsFrame, "TOPRIGHT", -10, -8)
    frame.lyricsTitle:SetText("Lyrics")
    frame.lyricsTitle:SetTextColor(GOLD[1], GOLD[2], GOLD[3], GOLD[4])

    frame.lyricRows = {}
    for i = 1, 5 do
        local row = frame.lyricsFrame:CreateFontString(nil, "OVERLAY")
        row:SetFontObject(i == 3 and "GameFontHighlight" or "GameFontNormalSmall")
        row:SetJustifyH("CENTER")
        row:SetWordWrap(false)
        row:SetPoint("LEFT", frame.lyricsFrame, "LEFT", 12, 0)
        row:SetPoint("RIGHT", frame.lyricsFrame, "RIGHT", -12, 0)
        if i == 1 then
            row:SetPoint("TOP", frame.lyricsTitle, "BOTTOM", 0, -12)
        else
            row:SetPoint("TOP", frame.lyricRows[i - 1], "BOTTOM", 0, -8)
        end
        frame.lyricRows[i] = row
    end

    frame.libraryButton = MakeButton(frame, "Library", 78, 24, function() GuildRadioFM:ToggleLibraryWindow() end)
    frame.libraryButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 18)
    frame.playlistButton = MakeButton(frame, "Playlists", 82, 24, function() GuildRadioFM:TogglePlaylistWindow() end)
    frame.playlistButton:SetPoint("LEFT", frame.libraryButton, "RIGHT", 8, 0)
    frame.queueButton = MakeButton(frame, "Queue", 66, 24, function() GuildRadioFM:ToggleQueueWindow() end)
    frame.queueButton:SetPoint("LEFT", frame.playlistButton, "RIGHT", 8, 0)
    frame.miniButton = MakeButton(frame, "Mini", 58, 24, function() GuildRadioFM:ToggleMiniWindow() end)
    frame.miniButton:SetPoint("LEFT", frame.queueButton, "RIGHT", 8, 0)
    frame.settingsButton = MakeButton(frame, "Settings", 82, 24, function() GuildRadioFM:ToggleSettingsWindow() end)
    frame.settingsButton:SetPoint("LEFT", frame.miniButton, "RIGHT", 8, 0)
    frame.shareButton = MakeButton(frame, "Share Meta", 78, 24, function() GuildRadioFM:ShareCurrentSong() end)
    frame.shareButton:SetPoint("LEFT", frame.settingsButton, "RIGHT", 8, 0)
    AddTooltip(frame.shareButton, "Metadata Sharing", "Sends song metadata only. GuildRadioFM does not transmit audio files.")

    self:UpdateMainWindow()
end

function GuildRadioFM:UpdateMainWindow()
    if not self.mainFrame or not self.db then return end
    local frame = self.mainFrame
    local song, index = self:GetCurrentSong()
    local count = self:GetSongCount()
    local title = song and song.title or "No local songs found"

    frame.songText:SetText("Song: " .. title .. (count > 0 and ("  (" .. index .. "/" .. count .. ")") or ""))
    frame.progressText:SetText("Progress: " .. self:GetProgressText())
    local playlist = self:GetSelectedPlaylist()
    local source = "Library"
    if self.db.playFromPlaylist and playlist then
        source = "Playlist: " .. playlist.name
    elseif self.db.playFromFavorites then
        source = "Liked"
    end
    frame.stateText:SetText(source .. "   Shuffle: " .. (self.db.shuffle and "On" or "Off") .. "   Repeat: " .. (self.db.repeatSong and "On" or "Off") .. "   Auto-next: " .. (self.db.autoNext and "On" or "Off"))
    frame.volumeText:SetText("Dialog Volume: " .. tostring(self.db.muted and 0 or self.db.volume) .. "%")
    self.suppressVolumeUpdate = true
    frame.volumeSlider:SetValue(self.db.muted and 0 or self.db.volume)
    self.suppressVolumeUpdate = false
    if frame.seekText and frame.seekSlider then
        frame.seekText:SetText("Seek Preview: " .. self:GetProgressText())
        self.suppressSeekUpdate = true
        frame.seekSlider:SetValue(self.GetSeekPercent and self:GetSeekPercent() or 0)
        self.suppressSeekUpdate = false
    end
    self:UpdateMainLyrics()
end

function GuildRadioFM:UpdateMainLyrics()
    local frame = self.mainFrame
    if not frame or not frame.lyricRows then return end

    local display = self.GetLyricDisplayState and self:GetLyricDisplayState() or nil
    local song = self:GetCurrentSong()
    local lyrics = display and display.lyrics or nil
    local currentIndex = display and tonumber(display.currentIndex) or 0

    if display and display.debug then
        frame.lyricsTitle:SetText("Lyrics - Test Playback")
    elseif display and display.active then
        frame.lyricsTitle:SetText("Lyrics - Live")
    else
        frame.lyricsTitle:SetText("Lyrics")
    end

    if not song and not (display and display.debug) then
        frame.lyricRows[1]:SetText("")
        frame.lyricRows[2]:SetText("")
        frame.lyricRows[3]:SetText("No song selected")
        frame.lyricRows[4]:SetText("Choose a track to see synced lyrics.")
        frame.lyricRows[5]:SetText("")
    elseif type(lyrics) ~= "table" or #lyrics == 0 then
        frame.lyricRows[1]:SetText("")
        frame.lyricRows[2]:SetText("")
        frame.lyricRows[3]:SetText("No lyrics for this track yet")
        frame.lyricRows[4]:SetText("Album packs can add timed lines by song ID.")
        frame.lyricRows[5]:SetText("")
    else
        local centerIndex = currentIndex
        if centerIndex < 1 then centerIndex = 1 end
        for rowIndex, row in ipairs(frame.lyricRows) do
            local lyricIndex = centerIndex + rowIndex - 3
            local line = lyrics[lyricIndex]
            row:SetText(line and line.text or "")
        end
        if currentIndex == 0 and lyrics[1] then
            frame.lyricRows[3]:SetText("...")
            frame.lyricRows[4]:SetText(lyrics[1].text or "")
        end
    end

    for rowIndex, row in ipairs(frame.lyricRows) do
        if rowIndex == 3 then
            row:SetFontObject("GameFontHighlight")
            row:SetTextColor(LYRIC_CURRENT[1], LYRIC_CURRENT[2], LYRIC_CURRENT[3], LYRIC_CURRENT[4])
        elseif rowIndex == 2 or rowIndex == 4 then
            row:SetFontObject("GameFontNormalSmall")
            row:SetTextColor(LYRIC_CONTEXT[1], LYRIC_CONTEXT[2], LYRIC_CONTEXT[3], LYRIC_CONTEXT[4])
        else
            row:SetFontObject("GameFontNormalSmall")
            row:SetTextColor(LYRIC_MUTED[1], LYRIC_MUTED[2], LYRIC_MUTED[3], LYRIC_MUTED[4])
        end
    end
end

function GuildRadioFM:ToggleMainWindow()
    self:CreateMainWindow()
    if self.mainFrame:IsShown() then self.mainFrame:Hide() else self.mainFrame:Show() self:UpdateMainWindow() end
end

function GuildRadioFM:CreateMiniWindow()
    if self.miniFrame then return end

    local frame = MakeWindow("miniFrame", "GuildRadioFMMiniFrame", "GRFM", 340, 98)
    SetResizeLimits(frame, 320, 92, 650, 220)
    if frame:GetWidth() > 430 or frame:GetHeight() > 136 or frame:GetWidth() < 320 or frame:GetHeight() < 92 then
        frame:SetSize(340, 98)
        if self.db and self.db.miniWindow then
            self.db.miniWindow.width = 340
            self.db.miniWindow.height = 98
        end
    end

    frame.songText = MakeText(frame, "GameFontHighlightSmall")
    frame.songText:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -24)
    frame.songText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -24)

    frame.progressText = MakeText(frame, "GameFontDisableSmall")
    frame.progressText:SetPoint("TOPLEFT", frame.songText, "BOTTOMLEFT", 0, -2)
    frame.progressText:SetPoint("TOPRIGHT", frame.songText, "BOTTOMRIGHT", 0, -2)

    frame.sourceText = MakeText(frame, "GameFontDisableSmall")
    frame.sourceText:SetPoint("TOPLEFT", frame.progressText, "BOTTOMLEFT", 0, -2)
    frame.sourceText:SetPoint("TOPRIGHT", frame.progressText, "BOTTOMRIGHT", 0, -2)
    frame.sourceText:SetTextColor(GOLD[1], GOLD[2], GOLD[3], GOLD[4])

    frame.backButton = MakeButton(frame, "<", 30, 20, function() GuildRadioFM:Back() end)
    frame.backButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 7, 6)
    frame.playButton = MakeButton(frame, "Play", 42, 20, function() GuildRadioFM:Play() end)
    frame.playButton:SetPoint("LEFT", frame.backButton, "RIGHT", 4, 0)
    frame.stopButton = MakeButton(frame, "Stop", 42, 20, function() GuildRadioFM:Stop() end)
    frame.stopButton:SetPoint("LEFT", frame.playButton, "RIGHT", 4, 0)
    frame.nextButton = MakeButton(frame, ">", 30, 20, function() GuildRadioFM:Next() end)
    frame.nextButton:SetPoint("LEFT", frame.stopButton, "RIGHT", 4, 0)
    frame.likeButton = MakeButton(frame, "Like", 42, 20, function() GuildRadioFM:ToggleFavorite() end)
    frame.likeButton:SetPoint("LEFT", frame.nextButton, "RIGHT", 4, 0)
    frame.muteButton = MakeButton(frame, "Mute", 46, 20, function() GuildRadioFM:ToggleMute() end)
    frame.muteButton:SetPoint("LEFT", frame.likeButton, "RIGHT", 4, 0)
    frame.restartButton = MakeButton(frame, "Restart", 54, 20, function() GuildRadioFM:RestartCurrentTrack() end)
    frame.restartButton:SetPoint("LEFT", frame.muteButton, "RIGHT", 4, 0)

    frame.volumeText = MakeText(frame, "GameFontDisableSmall")
    frame.volumeText:SetPoint("BOTTOMLEFT", frame.backButton, "TOPLEFT", 0, 4)

    frame.volumeSlider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    frame.volumeSlider:SetPoint("LEFT", frame.volumeText, "RIGHT", 6, 0)
    frame.volumeSlider:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
    frame.volumeSlider:SetMinMaxValues(0, 100)
    frame.volumeSlider:SetValueStep(1)
    frame.volumeSlider:SetObeyStepOnDrag(true)
    frame.volumeSlider:SetScript("OnValueChanged", function(_, value)
        if GuildRadioFM.suppressMiniVolumeUpdate then return end
        GuildRadioFM:SetVolume(math.floor(value + 0.5))
    end)
    frame.volumeSlider.Low:SetText("")
    frame.volumeSlider.High:SetText("")
    frame.volumeSlider.Text:SetText("")

    self:UpdateMiniWindow()
end

function GuildRadioFM:UpdateMiniWindow()
    if not self.miniFrame then return end
    local frame = self.miniFrame
    local playlist = self:GetSelectedPlaylist()
    local source = "Library"
    local song, index = self:GetCurrentSong()
    local count = self:GetSongCount()
    local title = song and song.title or self:GetCurrentTitle()
    if self.db and self.db.playFromPlaylist and playlist then
        source = playlist.name
    elseif self.db and self.db.playFromFavorites then
        source = "Liked"
    end
    frame.songText:SetText("Song: " .. (self:IsFavorite() and "* " or "") .. tostring(title or "No song selected") .. (count > 0 and ("  (" .. tostring(index or 0) .. "/" .. tostring(count) .. ")") or ""))
    frame.progressText:SetText("Progress: " .. self:GetProgressText())
    frame.sourceText:SetText("List: " .. source .. "   S:" .. (self.db and self.db.shuffle and "On" or "Off") .. " R:" .. (self.db and self.db.repeatSong and "On" or "Off") .. " A:" .. (self.db and self.db.autoNext and "On" or "Off"))
    frame.likeButton:SetText(self:IsFavorite() and "Liked" or "Like")
    frame.muteButton:SetText(self.db and self.db.muted and "Unmute" or "Mute")
    frame.volumeText:SetText("Vol: " .. tostring(self.db and (self.db.muted and 0 or self.db.volume) or 0) .. "%")
    self.suppressMiniVolumeUpdate = true
    frame.volumeSlider:SetValue(self.db and (self.db.muted and 0 or self.db.volume) or 0)
    self.suppressMiniVolumeUpdate = false
end

function GuildRadioFM:ToggleMiniWindow()
    self:CreateMiniWindow()
    if self.miniFrame:IsShown() then self.miniFrame:Hide() else self.miniFrame:Show() self:UpdateMiniWindow() end
end

function GuildRadioFM:CreateToast()
    if self.toastFrame then return end

    local frame = CreateFrame("Frame", "GuildRadioFMToastFrame", UIParent, "BackdropTemplate")
    self.toastFrame = frame
    frame:SetSize(360, 54)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -140)
    frame:SetFrameStrata("DIALOG")
    ApplyPanel(frame)

    frame.title = MakeText(frame, "GameFontNormalSmall", "CENTER")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -8)
    frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -8)
    frame.title:SetText("Now Playing")

    frame.songText = MakeText(frame, "GameFontHighlight", "CENTER")
    frame.songText:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
    frame.songText:SetPoint("TOPRIGHT", frame.title, "BOTTOMRIGHT", 0, -4)
    frame:Hide()
end

function GuildRadioFM:ShowNowPlayingToast(song)
    self:CreateToast()
    if not self.toastFrame then return end

    self.toastSerial = (self.toastSerial or 0) + 1
    local serial = self.toastSerial
    self.toastFrame.songText:SetText(song and song.title or self:GetCurrentTitle())
    self.toastFrame:Show()

    if C_Timer and C_Timer.After then
        C_Timer.After(3, function()
            if GuildRadioFM.toastSerial == serial and GuildRadioFM.toastFrame then
                GuildRadioFM.toastFrame:Hide()
            end
        end)
    end
end

function GuildRadioFM:IsLibrarySongVisible(songIndex)
    songIndex = tonumber(songIndex)
    if not songIndex then return false end
    for _, item in ipairs(self:GetFilteredSongs()) do
        if item.index == songIndex then return true end
    end
    return false
end

function GuildRadioFM:SelectLibrarySong(songIndex)
    songIndex = tonumber(songIndex)
    if not songIndex or not self:GetSong(songIndex) then return false end
    self.db.selectedLibrarySongIndex = songIndex
    self:UpdateLibraryWindow()
    return true
end

function GuildRadioFM:PlaySelectedLibrarySong()
    local songIndex = self.db and self.db.selectedLibrarySongIndex
    if not self:IsLibrarySongVisible(songIndex) then
        self:Print("Select a song first.")
        return
    end
    self:PlaySong(songIndex)
end

function GuildRadioFM:QueueSelectedLibrarySong()
    local songIndex = self.db and self.db.selectedLibrarySongIndex
    if not self:IsLibrarySongVisible(songIndex) then
        self:Print("Select a song first.")
        return
    end
    self:AddToQueue(songIndex)
end

function GuildRadioFM:CreateLibraryWindow()
    if self.libraryFrame then return end

    local frame = MakeWindow("libraryFrame", "GuildRadioFMLibraryFrame", "Local Library", 520, 520)
    frame.allButton = MakeButton(frame, "All", 54, 22, function() GuildRadioFM:SetLibraryView("all") end)
    frame.allButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -44)
    frame.favoriteButton = MakeButton(frame, "Liked", 64, 22, function() GuildRadioFM:SetLibraryView("favorites") end)
    frame.favoriteButton:SetPoint("LEFT", frame.allButton, "RIGHT", 8, 0)
    frame.secretButton = MakeButton(frame, "Secret Frequency", 128, 22, function() GuildRadioFM:SetLibraryView("secret") end)
    frame.secretButton:SetPoint("LEFT", frame.favoriteButton, "RIGHT", 8, 0)
    frame.playLikedButton = MakeButton(frame, "Play Liked", 88, 22, function() GuildRadioFM:PlayFavoriteEntry(1) end)
    frame.playLikedButton:SetPoint("LEFT", frame.secretButton, "RIGHT", 8, 0)
    frame.unlikeButton = MakeButton(frame, "Unlike", 70, 22, function() GuildRadioFM:RemoveFavorite() end)
    frame.unlikeButton:SetPoint("LEFT", frame.playLikedButton, "RIGHT", 8, 0)

    frame.countText = MakeText(frame, "GameFontDisableSmall", "RIGHT")
    frame.countText:SetPoint("LEFT", frame.unlikeButton, "RIGHT", 8, 0)
    frame.countText:SetPoint("RIGHT", frame, "RIGHT", -18, -44)

    frame.searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.searchBox:SetPoint("TOPLEFT", frame.allButton, "BOTTOMLEFT", 0, -10)
    frame.searchBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -76)
    frame.searchBox:SetHeight(24)
    frame.searchBox:SetAutoFocus(false)
    frame.searchBox:SetText(self.db.search or "")
    frame.searchBox:SetScript("OnTextChanged", function(box)
        GuildRadioFM.db.search = box:GetText() or ""
        GuildRadioFM.db.libraryScroll = 0
        GuildRadioFM:UpdateLibraryWindow()
    end)

    frame.playSongButton = MakeButton(frame, "Play Song", 88, 22, function() GuildRadioFM:PlaySelectedLibrarySong() end)
    frame.playSongButton:SetPoint("TOPLEFT", frame.searchBox, "BOTTOMLEFT", 0, -8)
    frame.queueSongButton = MakeButton(frame, "Add To Queue", 112, 22, function() GuildRadioFM:QueueSelectedLibrarySong() end)
    frame.queueSongButton:SetPoint("LEFT", frame.playSongButton, "RIGHT", 8, 0)
    frame.queueOpenButton = MakeButton(frame, "Queue", 70, 22, function() GuildRadioFM:ToggleQueueWindow(true) end)
    frame.queueOpenButton:SetPoint("LEFT", frame.queueSongButton, "RIGHT", 8, 0)

    frame.selectedText = MakeText(frame, "GameFontDisableSmall", "RIGHT")
    frame.selectedText:SetPoint("LEFT", frame.queueOpenButton, "RIGHT", 8, 0)
    frame.selectedText:SetPoint("RIGHT", frame, "RIGHT", -18, -108)

    frame.list = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.list:SetPoint("TOPLEFT", frame.playSongButton, "BOTTOMLEFT", -2, -12)
    frame.list:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
    ApplyInset(frame.list)
    frame.rows = {}
    AddMouseWheelScroll(frame.list, function()
        local filteredRows = GuildRadioFM:GetFilteredSongs()
        return GuildRadioFM.db, "libraryScroll", #filteredRows, GetVisibleRowCount(frame.list, 24, #frame.rows)
    end, function() GuildRadioFM:UpdateLibraryWindow() end)

    for i = 1, 30 do
        local row = CreateFrame("Button", nil, frame.list, "BackdropTemplate")
        row:SetHeight(22)
        row:SetPoint("TOPLEFT", frame.list, "TOPLEFT", 4, -4 - ((i - 1) * 24))
        row:SetPoint("TOPRIGHT", frame.list, "TOPRIGHT", -4, -4 - ((i - 1) * 24))
        row.text = MakeText(row, "GameFontNormalSmall")
        row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row:SetScript("OnMouseDown", function(button) RaiseWindow(GetOwningWindow(button)) end)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        AddMouseWheelScroll(row, function()
            local filteredRows = GuildRadioFM:GetFilteredSongs()
            return GuildRadioFM.db, "libraryScroll", #filteredRows, GetVisibleRowCount(frame.list, 24, #frame.rows)
        end, function() GuildRadioFM:UpdateLibraryWindow() end)
        row:SetScript("OnClick", function(button, mouseButton)
            if not button.songIndex then return end
            if mouseButton == "RightButton" then
                if GuildRadioFM.db.libraryView == "favorites" then
                    GuildRadioFM:RemoveFavorite(button.songIndex)
                else
                    GuildRadioFM:AddSongToSelectedPlaylist(button.songIndex)
                end
            else
                GuildRadioFM:SelectLibrarySong(button.songIndex)
            end
        end)
        row:SetScript("OnDoubleClick", function(button)
            if button.songIndex then
                GuildRadioFM:SelectLibrarySong(button.songIndex)
                GuildRadioFM:PlaySelectedLibrarySong()
            end
        end)
        frame.rows[i] = row
    end

    self:UpdateLibraryWindow()
end

function GuildRadioFM:GetFilteredSongs()
    local filter = string.lower(self.db.search or "")
    local view = self.db.libraryView or "all"
    local rows = {}
    for index, song in ipairs(self.songs or {}) do
        local title = string.lower(song.title or "")
        local file = string.lower(song.file or "")
        local category = string.lower(self.GetHiddenCategory and self:GetHiddenCategory(song) or "")
        local matchesView = self.CanShowSongInLibrary and self:CanShowSongInLibrary(song, view)
        if view == "favorites" then matchesView = matchesView and self:IsFavorite(index) end
        local matchesFilter = filter == "" or string.find(title, filter, 1, true) or string.find(file, filter, 1, true)
            or string.find(category, filter, 1, true)
        if matchesView and matchesFilter then
            rows[#rows + 1] = { index = index, song = song }
        end
    end
    return rows
end

function GuildRadioFM:UpdateLibraryWindow()
    if not self.libraryFrame or not self.db then return end
    local frame = self.libraryFrame
    local rows = self:GetFilteredSongs()
    local visibleRows = GetVisibleRowCount(frame.list, 24, #frame.rows)
    self.db.libraryScroll = ClampScrollOffset(self.db.libraryScroll, #rows, visibleRows)
    frame.allButton:SetText((self.db.libraryView or "all") == "all" and "All *" or "All")
    frame.favoriteButton:SetText(self.db.libraryView == "favorites" and "Liked *" or "Liked")
    if self:IsSecretFrequencyUnlocked() then
        frame.secretButton:Show()
        frame.playLikedButton:ClearAllPoints()
        frame.playLikedButton:SetPoint("LEFT", frame.secretButton, "RIGHT", 8, 0)
        frame.secretButton:SetText(self.db.libraryView == "secret" and "Secret Frequency *" or "Secret Frequency")
    else
        frame.secretButton:Hide()
        frame.playLikedButton:ClearAllPoints()
        frame.playLikedButton:SetPoint("LEFT", frame.favoriteButton, "RIGHT", 8, 0)
    end
    if self.db.libraryView == "favorites" then
        frame.unlikeButton:Show()
    else
        frame.unlikeButton:Hide()
    end
    local firstVisible = #rows == 0 and 0 or (self.db.libraryScroll or 0) + 1
    local lastVisible = math.min(#rows, (self.db.libraryScroll or 0) + visibleRows)
    frame.countText:SetText(firstVisible .. "-" .. lastVisible .. " of " .. #rows)
    local selectedSong = self:GetSong(self.db.selectedLibrarySongIndex)
    if selectedSong and self:IsLibrarySongVisible(self.db.selectedLibrarySongIndex) then
        frame.selectedText:SetText("Selected: " .. tostring(selectedSong.title or selectedSong.file or "Untitled"))
    else
        frame.selectedText:SetText("Select a song")
    end

    for i, row in ipairs(frame.rows) do
        local item = rows[i + (self.db.libraryScroll or 0)]
        if item and i <= visibleRows then
            row.songIndex = item.index
            row.text:SetText((self:IsFavorite(item.index) and "* " or "") .. item.index .. ". " .. (item.song.title or item.song.file or "Untitled"))
            row:Show()
            if item.index == self.db.selectedLibrarySongIndex then
                row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
                row:SetBackdropColor(0.18, 0.28, 0.34, 0.42)
            elseif item.index == self.db.currentIndex then
                row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
                row:SetBackdropColor(HILITE[1], HILITE[2], HILITE[3], HILITE[4])
            else
                row:SetBackdrop(nil)
            end
        else
            row.songIndex = nil
            row:Hide()
        end
    end

    if #rows == 0 then
        frame.rows[1]:Show()
        frame.rows[1].songIndex = nil
        if self.db.libraryView == "secret" then
            frame.rows[1].text:SetText("No Secret Frequency songs are installed.")
        else
            frame.rows[1].text:SetText(self:GetSongCount() == 0 and "No songs listed in SongList.lua." or "No songs match this view.")
        end
        frame.rows[1]:SetBackdrop(nil)
    end
end

function GuildRadioFM:ToggleLibraryWindow()
    self:CreateLibraryWindow()
    if self.libraryFrame:IsShown() then self.libraryFrame:Hide() else self.libraryFrame:Show() self:UpdateLibraryWindow() end
end

function GuildRadioFM:CreatePlaylistWindow()
    if self.playlistFrame then return end

    local frame = MakeWindow("playlistFrame", "GuildRadioFMPlaylistFrame", "Playlists", 560, 520)
    frame.nameBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    frame.nameBox:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -44)
    frame.nameBox:SetSize(180, 24)
    frame.nameBox:SetAutoFocus(false)

    frame.newButton = MakeButton(frame, "New", 58, 24, function()
        GuildRadioFM:CreatePlaylist(frame.nameBox:GetText())
        frame.nameBox:SetText("")
    end)
    frame.newButton:SetPoint("LEFT", frame.nameBox, "RIGHT", 10, 0)

    frame.deleteButton = MakeButton(frame, "Delete", 70, 24, function() GuildRadioFM:DeleteSelectedPlaylist() end)
    frame.deleteButton:SetPoint("LEFT", frame.newButton, "RIGHT", 8, 0)

    frame.playButton = MakeButton(frame, "Play", 58, 24, function() GuildRadioFM:PlayPlaylistEntry(GuildRadioFM.db.playlistEntryIndex) end)
    frame.playButton:SetPoint("LEFT", frame.deleteButton, "RIGHT", 8, 0)

    frame.clearButton = MakeButton(frame, "Clear", 62, 24, function() GuildRadioFM:ClearSelectedPlaylist() end)
    frame.clearButton:SetPoint("TOPLEFT", frame.nameBox, "BOTTOMLEFT", 0, -8)

    frame.upButton = MakeButton(frame, "Up", 44, 24, function() GuildRadioFM:MovePlaylistSong(GuildRadioFM.db.playlistEntryIndex, -1) end)
    frame.upButton:SetPoint("LEFT", frame.clearButton, "RIGHT", 8, 0)

    frame.downButton = MakeButton(frame, "Down", 58, 24, function() GuildRadioFM:MovePlaylistSong(GuildRadioFM.db.playlistEntryIndex, 1) end)
    frame.downButton:SetPoint("LEFT", frame.upButton, "RIGHT", 8, 0)

    frame.statusText = MakeText(frame, "GameFontDisableSmall", "RIGHT")
    frame.statusText:SetPoint("LEFT", frame.downButton, "RIGHT", 8, 0)
    frame.statusText:SetPoint("RIGHT", frame, "RIGHT", -18, -76)

    frame.playlistList = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.playlistList:SetPoint("TOPLEFT", frame.clearButton, "BOTTOMLEFT", -2, -12)
    frame.playlistList:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 18)
    frame.playlistList:SetWidth(190)
    ApplyInset(frame.playlistList)
    frame.playlistRows = {}
    AddMouseWheelScroll(frame.playlistList, function()
        return GuildRadioFM.db, "playlistScroll", GuildRadioFM:GetPlaylistCount(), GetVisibleRowCount(frame.playlistList, 26, #frame.playlistRows)
    end, function() GuildRadioFM:UpdatePlaylistWindow() end)

    for i = 1, 18 do
        local row = CreateFrame("Button", nil, frame.playlistList, "BackdropTemplate")
        row:SetHeight(24)
        row:SetPoint("TOPLEFT", frame.playlistList, "TOPLEFT", 4, -4 - ((i - 1) * 26))
        row:SetPoint("TOPRIGHT", frame.playlistList, "TOPRIGHT", -4, -4 - ((i - 1) * 26))
        row.text = MakeText(row, "GameFontNormalSmall")
        row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row:SetScript("OnMouseDown", function(button) RaiseWindow(GetOwningWindow(button)) end)
        AddMouseWheelScroll(row, function()
            return GuildRadioFM.db, "playlistScroll", GuildRadioFM:GetPlaylistCount(), GetVisibleRowCount(frame.playlistList, 26, #frame.playlistRows)
        end, function() GuildRadioFM:UpdatePlaylistWindow() end)
        row:SetScript("OnClick", function(button)
            if button.playlistIndex then GuildRadioFM:SelectPlaylist(button.playlistIndex) end
        end)
        frame.playlistRows[i] = row
    end

    frame.songList = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.songList:SetPoint("TOPLEFT", frame.playlistList, "TOPRIGHT", 12, 0)
    frame.songList:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
    ApplyInset(frame.songList)
    frame.songRows = {}
    AddMouseWheelScroll(frame.songList, function()
        local playlist = GuildRadioFM:GetSelectedPlaylist()
        local entries = playlist and playlist.songs or {}
        return GuildRadioFM.db, "playlistSongScroll", #entries, GetVisibleRowCount(frame.songList, 26, #frame.songRows)
    end, function() GuildRadioFM:UpdatePlaylistWindow() end)

    for i = 1, 24 do
        local row = CreateFrame("Button", nil, frame.songList, "BackdropTemplate")
        row:SetHeight(24)
        row:SetPoint("TOPLEFT", frame.songList, "TOPLEFT", 4, -4 - ((i - 1) * 26))
        row:SetPoint("TOPRIGHT", frame.songList, "TOPRIGHT", -4, -4 - ((i - 1) * 26))
        row.text = MakeText(row, "GameFontNormalSmall")
        row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -74, 0)
        row:SetScript("OnMouseDown", function(button) RaiseWindow(GetOwningWindow(button)) end)
        row.removeButton = MakeButton(row, "Remove", 64, 20, function(button)
            if button:GetParent().entryIndex then GuildRadioFM:RemovePlaylistSong(button:GetParent().entryIndex) end
        end)
        row.removeButton:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        AddMouseWheelScroll(row, function()
            local playlist = GuildRadioFM:GetSelectedPlaylist()
            local entries = playlist and playlist.songs or {}
            return GuildRadioFM.db, "playlistSongScroll", #entries, GetVisibleRowCount(frame.songList, 26, #frame.songRows)
        end, function() GuildRadioFM:UpdatePlaylistWindow() end)
        row:SetScript("OnClick", function(button)
            if button.entryIndex then
                GuildRadioFM.db.playlistEntryIndex = button.entryIndex
                GuildRadioFM:UpdatePlaylistWindow()
            end
        end)
        row:SetScript("OnDoubleClick", function(button)
            if button.entryIndex then
                GuildRadioFM.db.playlistEntryIndex = button.entryIndex
                GuildRadioFM:PlayPlaylistEntry(button.entryIndex)
            end
        end)
        frame.songRows[i] = row
    end

    self:UpdatePlaylistWindow()
end

function GuildRadioFM:UpdatePlaylistWindow()
    if not self.playlistFrame or not self.db then return end
    local frame = self.playlistFrame
    local playlists = self:GetAllPlaylists()
    local selected = self.db.selectedPlaylistIndex or 1
    local visiblePlaylists = GetVisibleRowCount(frame.playlistList, 26, #frame.playlistRows)
    local visibleSongs = GetVisibleRowCount(frame.songList, 26, #frame.songRows)
    self.db.playlistScroll = ClampScrollOffset(self.db.playlistScroll, #playlists, visiblePlaylists)
    local playlistFirst = #playlists == 0 and 0 or (self.db.playlistScroll or 0) + 1
    local playlistLast = math.min(#playlists, (self.db.playlistScroll or 0) + visiblePlaylists)

    for i, row in ipairs(frame.playlistRows) do
        local playlistIndex = i + (self.db.playlistScroll or 0)
        local playlist = playlists[playlistIndex]
        if playlist and i <= visiblePlaylists then
            row.playlistIndex = playlistIndex
            row.text:SetText(playlist.name .. " (" .. tostring(#(playlist.songs or {})) .. ")" .. (playlist.runtime and " *" or ""))
            row:Show()
            if playlistIndex == selected then
                row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
                row:SetBackdropColor(HILITE[1], HILITE[2], HILITE[3], HILITE[4])
            else
                row:SetBackdrop(nil)
            end
        else
            row.playlistIndex = nil
            row:Hide()
        end
    end

    if #playlists == 0 then
        frame.playlistRows[1]:Show()
        frame.playlistRows[1].playlistIndex = nil
        frame.playlistRows[1].text:SetText("No playlists yet")
        frame.playlistRows[1]:SetBackdrop(nil)
    end

    local playlist = self:GetSelectedPlaylist()
    local entries = playlist and playlist.songs or {}
    self.db.playlistSongScroll = ClampScrollOffset(self.db.playlistSongScroll, #entries, visibleSongs)
    local songFirst = #entries == 0 and 0 or (self.db.playlistSongScroll or 0) + 1
    local songLast = math.min(#entries, (self.db.playlistSongScroll or 0) + visibleSongs)
    local playlistName = playlist and playlist.name or "No playlist"
    frame.statusText:SetText(playlistName .. " | Lists " .. playlistFirst .. "-" .. playlistLast .. " of " .. #playlists .. " | Songs " .. songFirst .. "-" .. songLast .. " of " .. #entries)
    for i, row in ipairs(frame.songRows) do
        local entryIndex = i + (self.db.playlistSongScroll or 0)
        local songIndex = entries[entryIndex]
        local song = songIndex and self:GetSong(songIndex)
        if song and i <= visibleSongs then
            row.entryIndex = entryIndex
            row.text:SetText(entryIndex .. ". " .. (song.title or ("Song " .. tostring(songIndex))))
            row:Show()
            if playlist and playlist.runtime then
                row.removeButton:Hide()
            else
                row.removeButton:Show()
            end
            if entryIndex == self.db.playlistEntryIndex then
                row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
                row:SetBackdropColor(HILITE[1], HILITE[2], HILITE[3], HILITE[4])
            else
                row:SetBackdrop(nil)
            end
        else
            row.entryIndex = nil
            row:Hide()
        end
    end

    if #entries == 0 then
        frame.songRows[1]:Show()
        frame.songRows[1].entryIndex = nil
        frame.songRows[1].text:SetText(playlist and "Right-click songs in Library to add them here." or "Create a playlist first.")
        frame.songRows[1].removeButton:Hide()
        frame.songRows[1]:SetBackdrop(nil)
    else
        for _, row in ipairs(frame.songRows) do
            if row.entryIndex then
                if playlist and playlist.runtime then row.removeButton:Hide() else row.removeButton:Show() end
            end
        end
    end
end

function GuildRadioFM:TogglePlaylistWindow()
    self:CreatePlaylistWindow()
    if self.playlistFrame:IsShown() then self.playlistFrame:Hide() else self.playlistFrame:Show() self:UpdatePlaylistWindow() end
end

function GuildRadioFM:CreateQueueWindow()
    if self.queueFrame then return end

    local frame = MakeWindow("queueFrame", "GuildRadioFMQueueFrame", "Current Queue", 520, 420)
    frame.statusText = MakeText(frame, "GameFontNormalSmall")
    frame.statusText:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -46)
    frame.statusText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -46)
    frame.statusText:SetTextColor(0.78, 0.72, 0.6)

    frame.clearButton = MakeButton(frame, "Clear Queue", 100, 24, function() GuildRadioFM:ClearQueue() end)
    frame.clearButton:SetPoint("TOPLEFT", frame.statusText, "BOTTOMLEFT", 0, -12)
    frame.nextButton = MakeButton(frame, "Play Next Preview", 124, 24, function() GuildRadioFM:PlayNextInQueue() end)
    frame.nextButton:SetPoint("LEFT", frame.clearButton, "RIGHT", 8, 0)
    frame.nextButton:Disable()
    AddTooltip(frame.nextButton, "Queue Preview", "Queue management is available. Automatic queue playback is under development.")
    AddTooltip(frame.clearButton, "Clear Queue", "Removes every song from the current queue.")

    frame.list = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.list:SetPoint("TOPLEFT", frame.clearButton, "BOTTOMLEFT", -2, -12)
    frame.list:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
    ApplyInset(frame.list)
    frame.rows = {}

    for i = 1, 14 do
        local row = CreateFrame("Frame", nil, frame.list, "BackdropTemplate")
        row:SetHeight(24)
        row:SetPoint("TOPLEFT", frame.list, "TOPLEFT", 4, -4 - ((i - 1) * 26))
        row:SetPoint("TOPRIGHT", frame.list, "TOPRIGHT", -4, -4 - ((i - 1) * 26))
        row.text = MakeText(row, "GameFontNormalSmall")
        row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -74, 0)
        row.removeButton = MakeButton(row, "Remove", 64, 20, function(button)
            local parent = button:GetParent()
            if parent and parent.queueIndex then GuildRadioFM:RemoveFromQueue(parent.queueIndex) end
        end)
        row.removeButton:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        frame.rows[i] = row
    end

    self:UpdateQueueWindow()
end

function GuildRadioFM:UpdateQueueWindow()
    if not self.queueFrame then return end
    local frame = self.queueFrame
    local queue = self.GetQueue and self:GetQueue() or {}
    frame.statusText:SetText("Songs queued: " .. tostring(#queue) .. " | Automatic queue playback under development.")
    if #queue == 0 then
        frame.clearButton:Disable()
        frame.nextButton:Disable()
    else
        frame.clearButton:Enable()
        frame.nextButton:Disable()
    end

    for i, row in ipairs(frame.rows) do
        local entry = queue[i]
        if entry then
            row.queueIndex = i
            row.text:SetText(i .. ". " .. tostring(entry.title or "Untitled") .. " - " .. tostring(entry.artist or "GuildRadioFM"))
            row.removeButton:Show()
            row:Show()
        else
            row.queueIndex = nil
            row:Hide()
        end
    end

    if #queue == 0 then
        frame.rows[1]:Show()
        frame.rows[1].queueIndex = nil
        frame.rows[1].text:SetText("Queue is empty.")
        frame.rows[1].removeButton:Hide()
    end
end

function GuildRadioFM:ToggleQueueWindow(show)
    self:CreateQueueWindow()
    self:UpdateQueueWindow()
    if show == true then
        self.queueFrame:Show()
    elseif show == false then
        self.queueFrame:Hide()
    elseif self.queueFrame:IsShown() then
        self.queueFrame:Hide()
    else
        self.queueFrame:Show()
    end
end

function GuildRadioFM:CreateSharingWindow()
    if self.sharingFrame then return end

    local frame = MakeWindow("sharingFrame", "GuildRadioFMSharingFrame", "Metadata Sharing", 540, 420)
    frame.statusText = MakeText(frame, "GameFontNormalSmall")
    frame.statusText:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -46)
    frame.statusText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -46)
    frame.statusText:SetTextColor(0.78, 0.72, 0.6)

    frame.shareButton = MakeButton(frame, "Share Metadata", 122, 24, function() GuildRadioFM:ShareCurrentSong() end)
    frame.shareButton:SetPoint("TOPLEFT", frame.statusText, "BOTTOMLEFT", 0, -12)
    AddTooltip(frame.shareButton, "Metadata Sharing", "Sends song metadata only. It does not transmit audio or sync playback.")
    frame.requestButton = MakeButton(frame, "Request Metadata", 132, 24, function() GuildRadioFM:RequestCurrentSong() end)
    frame.requestButton:SetPoint("LEFT", frame.shareButton, "RIGHT", 8, 0)
    AddTooltip(frame.requestButton, "Metadata Request", "Requests song metadata only. MP3 files are never transferred by the addon.")
    frame.clearButton = MakeButton(frame, "Clear", 70, 24, function() GuildRadioFM:ClearSharingInbox() end)
    frame.clearButton:SetPoint("LEFT", frame.requestButton, "RIGHT", 8, 0)

    frame.list = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.list:SetPoint("TOPLEFT", frame.shareButton, "BOTTOMLEFT", -2, -12)
    frame.list:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 18)
    ApplyInset(frame.list)
    frame.rows = {}

    for i = 1, 12 do
        local row = CreateFrame("Frame", nil, frame.list, "BackdropTemplate")
        row:SetHeight(26)
        row:SetPoint("TOPLEFT", frame.list, "TOPLEFT", 4, -4 - ((i - 1) * 28))
        row:SetPoint("TOPRIGHT", frame.list, "TOPRIGHT", -4, -4 - ((i - 1) * 28))
        row.text = MakeText(row, "GameFontNormalSmall")
        row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        frame.rows[i] = row
    end

    self:UpdateSharingWindow()
end

function GuildRadioFM:UpdateSharingWindow()
    if not self.sharingFrame then return end
    local frame = self.sharingFrame
    local inbox = self.GetSharingInbox and self:GetSharingInbox() or {}
    local channel = self.GetSharingChannel and self:GetSharingChannel() or nil
    frame.statusText:SetText("Metadata only | Channel: " .. tostring(channel or "none") .. "   Inbox: " .. tostring(#inbox))

    for i, row in ipairs(frame.rows) do
        local entry = inbox[i]
        if entry then
            local kind = entry.kind == "REQ" and "Request" or "Now Playing"
            row.text:SetText(i .. ". " .. kind .. " from " .. tostring(entry.sender or "Unknown") .. ": " .. tostring(entry.title or "Untitled") .. " - " .. tostring(entry.artist or "GuildRadioFM"))
            row:Show()
        else
            row:Hide()
        end
    end

    if #inbox == 0 then
        frame.rows[1]:Show()
        frame.rows[1].text:SetText("No shared metadata or requests yet.")
    end
end

function GuildRadioFM:ToggleSharingWindow(show)
    self:CreateSharingWindow()
    self:UpdateSharingWindow()
    if show == true then
        self.sharingFrame:Show()
    elseif show == false then
        self.sharingFrame:Hide()
    elseif self.sharingFrame:IsShown() then
        self.sharingFrame:Hide()
    else
        self.sharingFrame:Show()
    end
end

function GuildRadioFM:CreateSettingsWindow()
    if self.settingsFrame then return end

    local frame = MakeWindow("settingsFrame", "GuildRadioFMSettingsFrame", "Settings", 430, 360)
    frame.info = MakeText(frame, "GameFontNormalSmall")
    frame.info:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -46)
    frame.info:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -46)
    frame.info:SetText("Local-only player. Songs must be packaged inside GuildRadioFM\\Songs before WoW starts. Addons cannot upload songs, stream internet audio, read arbitrary files, or seek inside MP3s. Volume uses the global Dialog channel.")

    frame.volumeText = MakeText(frame, "GameFontNormal")
    frame.volumeText:SetPoint("TOPLEFT", frame.info, "BOTTOMLEFT", 0, -24)

    frame.volumeSlider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    frame.volumeSlider:SetPoint("TOPLEFT", frame.volumeText, "BOTTOMLEFT", 0, -12)
    frame.volumeSlider:SetWidth(240)
    frame.volumeSlider:SetMinMaxValues(0, 100)
    frame.volumeSlider:SetValueStep(1)
    frame.volumeSlider:SetObeyStepOnDrag(true)
    frame.volumeSlider:SetScript("OnValueChanged", function(_, value)
        if GuildRadioFM.suppressSettingsVolumeUpdate then return end
        GuildRadioFM:SetVolume(math.floor(value + 0.5))
    end)
    frame.volumeSlider.Low:SetText("0")
    frame.volumeSlider.High:SetText("100")
    frame.volumeSlider.Text:SetText("")

    frame.shuffleButton = MakeToggleButton(frame, "Shuffle", function() GuildRadioFM:ToggleShuffle() end)
    frame.shuffleButton:SetPoint("TOPLEFT", frame.volumeSlider, "BOTTOMLEFT", 0, -34)
    frame.repeatButton = MakeToggleButton(frame, "Repeat", function() GuildRadioFM:ToggleRepeat() end)
    frame.repeatButton:SetPoint("LEFT", frame.shuffleButton, "RIGHT", 8, 0)
    frame.autoNextButton = MakeToggleButton(frame, "Auto-next", function() GuildRadioFM:ToggleAutoNext() end)
    frame.autoNextButton:SetPoint("LEFT", frame.repeatButton, "RIGHT", 8, 0)
    frame.muteButton = MakeButton(frame, "Mute", 70, 24, function() GuildRadioFM:ToggleMute() end)
    frame.muteButton:SetPoint("TOPLEFT", frame.shuffleButton, "BOTTOMLEFT", 0, -12)

    frame.addSongsButton = MakeButton(frame, "Add Songs Help", 130, 24, function() GuildRadioFM:ToggleAddSongsWindow() end)
    frame.addSongsButton:SetPoint("LEFT", frame.muteButton, "RIGHT", 8, 0)

    self:UpdateSettingsWindow()
end

function GuildRadioFM:UpdateSettingsWindow()
    if not self.settingsFrame or not self.db then return end
    local frame = self.settingsFrame
    frame.volumeText:SetText("Dialog Volume: " .. tostring(self.db.muted and 0 or self.db.volume) .. "%")
    self.suppressSettingsVolumeUpdate = true
    frame.volumeSlider:SetValue(self.db.muted and 0 or self.db.volume)
    self.suppressSettingsVolumeUpdate = false
    frame.shuffleButton:SetText("Shuffle " .. (self.db.shuffle and "On" or "Off"))
    frame.repeatButton:SetText("Repeat " .. (self.db.repeatSong and "On" or "Off"))
    frame.autoNextButton:SetText("Auto " .. (self.db.autoNext and "On" or "Off"))
    frame.muteButton:SetText(self.db.muted and "Unmute" or "Mute")
end

function GuildRadioFM:ToggleSettingsWindow()
    self:CreateSettingsWindow()
    if self.settingsFrame:IsShown() then self.settingsFrame:Hide() else self.settingsFrame:Show() self:UpdateSettingsWindow() end
end

function GuildRadioFM:CreateAddSongsWindow()
    if self.addSongsFrame then return end

    local frame = MakeWindow("addSongsFrame", "GuildRadioFMAddSongsFrame", "Add Songs", 560, 420)
    frame.body = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.body:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -46)
    frame.body:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 44)
    ApplyInset(frame.body)

    frame.instructions = MakeText(frame.body, "GameFontNormalSmall")
    frame.instructions:SetPoint("TOPLEFT", frame.body, "TOPLEFT", 10, -10)
    frame.instructions:SetPoint("TOPRIGHT", frame.body, "TOPRIGHT", -10, -10)
    frame.instructions:SetSpacing(4)
    frame.instructions:SetText(
        "GuildRadioFM cannot upload songs from inside WoW. Add songs before launching or reloading the game.\n\n" ..
        "1. Copy MP3 files into:\n" ..
        "World of Warcraft\\_retail_\\Interface\\AddOns\\GuildRadioFM\\Songs\\\n\n" ..
        "2. Open SongList.lua in the GuildRadioFM folder.\n\n" ..
        "3. Add one line inside GuildRadioFMSongList for each song:\n" ..
        "{ id = \"guildradiofm:my-song\", title = \"My Song\", file = \"Interface\\\\AddOns\\\\GuildRadioFM\\\\Songs\\\\My Song.mp3\" },\n\n" ..
        "4. Save SongList.lua, then fully restart WoW or type /reload.\n\n" ..
        "Rules: file names must match exactly, including spaces. Keep the songs in this addon's Songs folder. Do not use D:\\ paths or internet links; WoW addons cannot read them.\n\n" ..
        "Lyrics: type /grfm lyrics test to test the Maxi Player lyric scroller. Album packs can register lyrics by song id.\n\n" ..
        "Secret Frequency: GuildRadioFM contains optional music-themed Easter eggs. They do not affect normal addon use."
    )

    frame.closeButton = MakeButton(frame, "Close", 80, 24, function() frame:Hide() end)
    frame.closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 14)
end

function GuildRadioFM:ToggleAddSongsWindow()
    self:CreateAddSongsWindow()
    if self.addSongsFrame:IsShown() then
        self.addSongsFrame:Hide()
    else
        self.addSongsFrame:Show()
    end
end

function GuildRadioFM:CreateHiddenFrequencyWindow()
    if self.hiddenFrequencyFrame then return end

    local frame = MakeWindow("hiddenFrequencyFrame", "GuildRadioFMHiddenFrequencyFrame", "The Hidden Frequency", 520, 360)
    frame.subtitle = MakeText(frame, "GameFontNormalSmall")
    frame.subtitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -46)
    frame.subtitle:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -46)
    frame.subtitle:SetText("Future transmission slots. Audio files are not included yet.")
    frame.subtitle:SetTextColor(0.78, 0.72, 0.6)

    frame.list = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.list:SetPoint("TOPLEFT", frame.subtitle, "BOTTOMLEFT", 0, -14)
    frame.list:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 50)
    ApplyInset(frame.list)

    frame.rows = {}
    for i = 1, 5 do
        local row = frame.list:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row:SetJustifyH("LEFT")
        row:SetPoint("LEFT", frame.list, "LEFT", 12, 0)
        row:SetPoint("RIGHT", frame.list, "RIGHT", -12, 0)
        row:SetPoint("TOP", frame.list, "TOP", 0, -12 - ((i - 1) * 34))
        frame.rows[i] = row
    end

    frame.closeButton = MakeButton(frame, "Close", 80, 24, function() frame:Hide() end)
    frame.closeButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 14)

    self:UpdateHiddenFrequencyWindow()
end

function GuildRadioFM:UpdateHiddenFrequencyWindow()
    local frame = self.hiddenFrequencyFrame
    if not frame then return end

    local playlist = self.GetHiddenFrequencyPlaylist and self:GetHiddenFrequencyPlaylist() or nil
    if not playlist then
        frame.subtitle:SetText("No hidden playlist data found.")
        for _, row in ipairs(frame.rows or {}) do row:SetText("") end
        return
    end

    frame.title:SetText(playlist.name or "The Hidden Frequency")
    frame.subtitle:SetText("Future transmission slots. Audio files are not included yet.")

    local songs = playlist.songs or {}
    for index, row in ipairs(frame.rows or {}) do
        local song = songs[index]
        if song then
            local state = song.locked and "LOCKED" or "UNLOCKED"
            row:SetText(index .. ". " .. (song.title or "Unknown Signal") .. "  |  " .. state)
            row:SetTextColor(song.locked and 0.56 or 1, song.locked and 0.50 or 0.88, song.locked and 0.40 or 0.58)
        else
            row:SetText("")
        end
    end
end

function GuildRadioFM:ToggleHiddenFrequencyWindow(show)
    self:CreateHiddenFrequencyWindow()
    self:UpdateHiddenFrequencyWindow()
    if show == true then
        self.hiddenFrequencyFrame:Show()
    elseif self.hiddenFrequencyFrame:IsShown() then
        self.hiddenFrequencyFrame:Hide()
    else
        self.hiddenFrequencyFrame:Show()
    end
end

function GuildRadioFM:GetMinimapAngle()
    self.db.minimap = self.db.minimap or { hide = false, angle = 225 }
    return tonumber(self.db.minimap.angle) or 225
end

function GuildRadioFM:PositionMinimapButton()
    if not self.minimapButton or not Minimap then return end
    local angle = math.rad(self:GetMinimapAngle())
    local radius = 80
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius
    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function GuildRadioFM:UpdateMinimapButton()
    if not self.minimapButton or not self.db then return end
    self.db.minimap = self.db.minimap or { hide = false, angle = 225 }
    if self.db.minimap.hide then
        self.minimapButton:Hide()
    else
        self.minimapButton:Show()
        self:PositionMinimapButton()
    end
    if self.optionsPanel and self.optionsPanel.minimapButton then
        self.optionsPanel.minimapButton:SetChecked(not self.db.minimap.hide)
    end
end

function GuildRadioFM:SetMinimapButtonShown(shown)
    self.db.minimap = self.db.minimap or { hide = false, angle = 225 }
    self.db.minimap.hide = not shown
    self:UpdateMinimapButton()
end

function GuildRadioFM:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end

    self.db.minimap = self.db.minimap or { hide = false, angle = 225 }
    local button = CreateFrame("Button", "GuildRadioFMMinimapButton", Minimap)
    self.minimapButton = button
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetTexture(ICON_TEXTURE)
    button.icon:SetSize(24, 24)
    button.icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    button.border:SetSize(54, 54)
    button.border:SetPoint("CENTER", button, "CENTER", 12, -12)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            GuildRadioFM:OpenOptionsPanel()
        else
            GuildRadioFM:ToggleMainWindow()
        end
    end)

    button:SetScript("OnEnter", function(selfButton)
        if not GameTooltip then return end
        GameTooltip:SetOwner(selfButton, "ANCHOR_LEFT")
        GameTooltip:SetText("GuildRadioFM", 1, 0.82, 0.25)
        GameTooltip:AddLine("Left-click: Open player", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Options", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move icon", 0.75, 0.75, 0.75)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)

    local function UpdateMinimapDrag()
        if not button.isDragging or not Minimap then return end
        local scale = UIParent and UIParent:GetEffectiveScale() or 1
        local cursorX, cursorY = GetCursorPosition()
        local centerX, centerY = Minimap:GetCenter()
        cursorX = cursorX / scale
        cursorY = cursorY / scale
        local deltaY = cursorY - centerY
        local deltaX = cursorX - centerX
        local angle = math.deg(math.atan2 and math.atan2(deltaY, deltaX) or math.atan(deltaY / math.max(0.001, deltaX)))
        GuildRadioFM.db.minimap.angle = angle
        GuildRadioFM:PositionMinimapButton()
    end

    button:SetScript("OnDragStart", function()
        button.isDragging = true
        button:SetScript("OnUpdate", UpdateMinimapDrag)
    end)

    button:SetScript("OnDragStop", function()
        button.isDragging = false
        button:SetScript("OnUpdate", nil)
    end)

    self:UpdateMinimapButton()
end

function GuildRadioFM:UpdateOptionsPanel()
    local panel = self.optionsPanel
    if not panel or not self.db then return end
    if panel.volumeText then panel.volumeText:SetText("Dialog Volume: " .. tostring(self.db.muted and 0 or self.db.volume) .. "%") end
    if panel.volumeSlider then
        self.suppressOptionsVolumeUpdate = true
        panel.volumeSlider:SetValue(self.db.muted and 0 or self.db.volume)
        self.suppressOptionsVolumeUpdate = false
    end
    if panel.shuffleButton then panel.shuffleButton:SetChecked(self.db.shuffle) end
    if panel.repeatButton then panel.repeatButton:SetChecked(self.db.repeatSong) end
    if panel.autoNextButton then panel.autoNextButton:SetChecked(self.db.autoNext) end
    if panel.muteButton then panel.muteButton:SetChecked(self.db.muted) end
    if panel.minimapButton then panel.minimapButton:SetChecked(not (self.db.minimap and self.db.minimap.hide)) end
end

function GuildRadioFM:BuildOptionsPanel()
    local panel = self.optionsPanel
    if not panel or panel.built then return end
    panel.built = true

    panel.logo = panel:CreateTexture(nil, "ARTWORK")
    panel.logo:SetTexture(ICON_TEXTURE)
    panel.logo:SetSize(72, 72)
    panel.logo:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -18)
    panel.logo:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.title:SetPoint("TOPLEFT", panel.logo, "TOPRIGHT", 14, -6)
    panel.title:SetText("GuildRadioFM")
    panel.title:SetTextColor(1, 0.82, 0.25)

    panel.version = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.version:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -6)
    panel.version:SetText("Core v" .. tostring(self.Version) .. " - local music library")
    panel.version:SetTextColor(0.78, 0.72, 0.6)

    panel.volumeText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.volumeText:SetPoint("TOPLEFT", panel.logo, "BOTTOMLEFT", 0, -24)

    panel.volumeSlider = CreateFrame("Slider", nil, panel, "OptionsSliderTemplate")
    panel.volumeSlider:SetPoint("TOPLEFT", panel.volumeText, "BOTTOMLEFT", 0, -12)
    panel.volumeSlider:SetWidth(260)
    panel.volumeSlider:SetMinMaxValues(0, 100)
    panel.volumeSlider:SetValueStep(1)
    panel.volumeSlider:SetObeyStepOnDrag(true)
    panel.volumeSlider.Low:SetText("0")
    panel.volumeSlider.High:SetText("100")
    panel.volumeSlider.Text:SetText("")
    panel.volumeSlider:SetScript("OnValueChanged", function(_, value)
        if GuildRadioFM.suppressOptionsVolumeUpdate then return end
        GuildRadioFM:SetVolume(math.floor(value + 0.5))
        GuildRadioFM:UpdateOptionsPanel()
    end)

    panel.shuffleButton = MakeCheckButton(panel, "Shuffle", function() GuildRadioFM:ToggleShuffle(); GuildRadioFM:UpdateOptionsPanel() end)
    panel.shuffleButton:SetPoint("TOPLEFT", panel.volumeSlider, "BOTTOMLEFT", 0, -28)
    panel.repeatButton = MakeCheckButton(panel, "Repeat current song", function() GuildRadioFM:ToggleRepeat(); GuildRadioFM:UpdateOptionsPanel() end)
    panel.repeatButton:SetPoint("TOPLEFT", panel.shuffleButton, "BOTTOMLEFT", 0, -6)
    panel.autoNextButton = MakeCheckButton(panel, "Auto-next", function() GuildRadioFM:ToggleAutoNext(); GuildRadioFM:UpdateOptionsPanel() end)
    panel.autoNextButton:SetPoint("TOPLEFT", panel.repeatButton, "BOTTOMLEFT", 0, -6)
    panel.muteButton = MakeCheckButton(panel, "Mute GuildRadioFM", function() GuildRadioFM:ToggleMute(); GuildRadioFM:UpdateOptionsPanel() end)
    panel.muteButton:SetPoint("TOPLEFT", panel.autoNextButton, "BOTTOMLEFT", 0, -6)
    panel.minimapButton = MakeCheckButton(panel, "Show minimap icon", function(button) GuildRadioFM:SetMinimapButtonShown(button:GetChecked()) end)
    panel.minimapButton:SetPoint("TOPLEFT", panel.muteButton, "BOTTOMLEFT", 0, -6)

    panel.openMainButton = MakeButton(panel, "Open Player", 110, 24, function() GuildRadioFM:ToggleMainWindow() end)
    panel.openMainButton:SetPoint("TOPLEFT", panel.minimapButton, "BOTTOMLEFT", 0, -18)
    panel.libraryButton = MakeButton(panel, "Library", 90, 24, function() GuildRadioFM:ToggleLibraryWindow() end)
    panel.libraryButton:SetPoint("LEFT", panel.openMainButton, "RIGHT", 8, 0)
    panel.playlistsButton = MakeButton(panel, "Playlists", 90, 24, function() GuildRadioFM:TogglePlaylistWindow() end)
    panel.playlistsButton:SetPoint("LEFT", panel.libraryButton, "RIGHT", 8, 0)
    panel.miniButton = MakeButton(panel, "Mini", 70, 24, function() GuildRadioFM:ToggleMiniWindow() end)
    panel.miniButton:SetPoint("LEFT", panel.playlistsButton, "RIGHT", 8, 0)

    panel.note = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.note:SetPoint("TOPLEFT", panel.openMainButton, "BOTTOMLEFT", 0, -18)
    panel.note:SetWidth(520)
    panel.note:SetJustifyH("LEFT")
    panel.note:SetText("GuildRadioFM is local-only. Songs must be packaged inside the addon or an optional song-pack addon. Playback uses WoW's Dialog channel.")
    panel.note:SetTextColor(0.78, 0.72, 0.6)
end

function GuildRadioFM:CreateOptionsPanel()
    if self.optionsPanel then return end

    local panel = CreateFrame("Frame", "GuildRadioFMOptionsPanel")
    self.optionsPanel = panel
    panel.name = "GuildRadioFM"
    panel:SetScript("OnShow", function()
        GuildRadioFM:BuildOptionsPanel()
        GuildRadioFM:UpdateOptionsPanel()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "GuildRadioFM")
        Settings.RegisterAddOnCategory(category)
        self.optionsCategory = category
    elseif _G["InterfaceOptions_AddCategory"] then
        _G["InterfaceOptions_AddCategory"](panel)
    end
end

function GuildRadioFM:OpenOptionsPanel()
    self:CreateOptionsPanel()
    if Settings and Settings.OpenToCategory and self.optionsCategory then
        local categoryID = self.optionsCategory.ID
        if not categoryID and self.optionsCategory.GetID then
            categoryID = self.optionsCategory:GetID()
        end
        if categoryID and pcall(Settings.OpenToCategory, categoryID) then
            return
        end
        self:ToggleSettingsWindow()
    elseif _G["InterfaceOptionsFrame_OpenToCategory"] then
        if not pcall(_G["InterfaceOptionsFrame_OpenToCategory"], self.optionsPanel) then
            self:ToggleSettingsWindow()
        end
    else
        self:ToggleSettingsWindow()
    end
end
