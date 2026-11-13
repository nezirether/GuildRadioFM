local GOLD = { 0.86, 0.66, 0.24, 1 }
local DARK = { 0.035, 0.03, 0.025, 0.96 }
local DARKER = { 0.015, 0.012, 0.01, 0.98 }
local HILITE = { 0.22, 0.16, 0.06, 0.9 }
local ICON_TEXTURE = "Interface\\AddOns\\GuildRadioFM\\Media\\GuildRadioFM_Icon.tga"

-- Dark panels, gold trim, no stream/share UI.
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

local RaiseWindow

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

function RaiseWindow(frame)
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

local function MakeResizeGrip(frame, saved)
    frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(260, 80, 900, 760) end

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
        if GuildRadioFM.RefreshAll then GuildRadioFM:RefreshAll() end
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

    local frame = MakeWindow("mainFrame", "GuildRadioFMMainFrame", "GuildRadioFM", 420, 270)
    frame.songText = MakeText(frame, "GameFontHighlight")
    frame.songText:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -46)
    frame.songText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -18, -46)

    frame.progressText = MakeText(frame, "GameFontNormalSmall")
    frame.progressText:SetPoint("TOPLEFT", frame.songText, "BOTTOMLEFT", 0, -8)
    frame.progressText:SetPoint("TOPRIGHT", frame.songText, "BOTTOMRIGHT", 0, -8)

    frame.stateText = MakeText(frame, "GameFontNormalSmall")
    frame.stateText:SetPoint("TOPLEFT", frame.progressText, "BOTTOMLEFT", 0, -8)
    frame.stateText:SetPoint("TOPRIGHT", frame.progressText, "BOTTOMRIGHT", 0, -8)

    local controls = CreateFrame("Frame", nil, frame, "BackdropTemplate")
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

    frame.libraryButton = MakeButton(frame, "Library", 78, 24, function() GuildRadioFM:ToggleLibraryWindow() end)
    frame.libraryButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 18)
    frame.playlistButton = MakeButton(frame, "Playlists", 82, 24, function() GuildRadioFM:TogglePlaylistWindow() end)
    frame.playlistButton:SetPoint("LEFT", frame.libraryButton, "RIGHT", 8, 0)
    frame.miniButton = MakeButton(frame, "Mini", 62, 24, function() GuildRadioFM:ToggleMiniWindow() end)
    frame.miniButton:SetPoint("LEFT", frame.playlistButton, "RIGHT", 8, 0)
    frame.settingsButton = MakeButton(frame, "Settings", 82, 24, function() GuildRadioFM:ToggleSettingsWindow() end)
    frame.settingsButton:SetPoint("LEFT", frame.miniButton, "RIGHT", 8, 0)

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
end

function GuildRadioFM:ToggleMainWindow()
    self:CreateMainWindow()
    if self.mainFrame:IsShown() then self.mainFrame:Hide() else self.mainFrame:Show() self:UpdateMainWindow() end
end

function GuildRadioFM:CreateMiniWindow()
    if self.miniFrame then return end

    local frame = MakeWindow("miniFrame", "GuildRadioFMMiniFrame", "GRFM", 420, 138)
    if frame.SetResizeBounds then frame:SetResizeBounds(360, 128, 760, 240) end
    if frame:GetWidth() < 360 or frame:GetHeight() < 128 then frame:SetSize(420, 138) end

    frame.songText = MakeText(frame, "GameFontHighlightSmall")
    frame.songText:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -34)
    frame.songText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -34)

    frame.sourceText = MakeText(frame, "GameFontDisableSmall")
    frame.sourceText:SetPoint("TOPLEFT", frame.songText, "BOTTOMLEFT", 0, -4)
    frame.sourceText:SetPoint("TOPRIGHT", frame.songText, "BOTTOMRIGHT", 0, -4)

    frame.backButton = MakeButton(frame, "<", 34, 22, function() GuildRadioFM:Back() end)
    frame.backButton:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 12)
    frame.playButton = MakeButton(frame, "Play", 50, 22, function() GuildRadioFM:Play() end)
    frame.playButton:SetPoint("LEFT", frame.backButton, "RIGHT", 6, 0)
    frame.stopButton = MakeButton(frame, "Stop", 50, 22, function() GuildRadioFM:Stop() end)
    frame.stopButton:SetPoint("LEFT", frame.playButton, "RIGHT", 6, 0)
    frame.nextButton = MakeButton(frame, ">", 34, 22, function() GuildRadioFM:Next() end)
    frame.nextButton:SetPoint("LEFT", frame.stopButton, "RIGHT", 6, 0)
    frame.likeButton = MakeButton(frame, "Like", 54, 22, function() GuildRadioFM:ToggleFavorite() end)
    frame.likeButton:SetPoint("LEFT", frame.nextButton, "RIGHT", 6, 0)
    frame.muteButton = MakeButton(frame, "Mute", 54, 22, function() GuildRadioFM:ToggleMute() end)
    frame.muteButton:SetPoint("LEFT", frame.likeButton, "RIGHT", 6, 0)

    frame.volumeText = MakeText(frame, "GameFontNormalSmall")
    frame.volumeText:SetPoint("BOTTOMLEFT", frame.backButton, "TOPLEFT", 0, 10)

    frame.volumeSlider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    frame.volumeSlider:SetPoint("LEFT", frame.volumeText, "RIGHT", 10, 0)
    frame.volumeSlider:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
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
    if self.db and self.db.playFromPlaylist and playlist then
        source = playlist.name
    elseif self.db and self.db.playFromFavorites then
        source = "Liked"
    end
    frame.songText:SetText((self:IsFavorite() and "* " or "") .. self:GetCurrentTitle())
    frame.sourceText:SetText(source .. "  |  " .. self:GetProgressText())
    frame.likeButton:SetText(self:IsFavorite() and "Liked" or "Like")
    frame.muteButton:SetText(self.db and self.db.muted and "Unmute" or "Mute")
    frame.volumeText:SetText(tostring(self.db and (self.db.muted and 0 or self.db.volume) or 0) .. "%")
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

function GuildRadioFM:CreateLibraryWindow()
    if self.libraryFrame then return end

    local frame = MakeWindow("libraryFrame", "GuildRadioFMLibraryFrame", "Local Library", 520, 520)
    frame.allButton = MakeButton(frame, "All", 54, 22, function() GuildRadioFM:SetLibraryView("all") end)
    frame.allButton:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -44)
    frame.favoriteButton = MakeButton(frame, "Liked", 64, 22, function() GuildRadioFM:SetLibraryView("favorites") end)
    frame.favoriteButton:SetPoint("LEFT", frame.allButton, "RIGHT", 8, 0)
    frame.playLikedButton = MakeButton(frame, "Play Liked", 88, 22, function() GuildRadioFM:PlayFavoriteEntry(1) end)
    frame.playLikedButton:SetPoint("LEFT", frame.favoriteButton, "RIGHT", 8, 0)
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

    frame.list = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.list:SetPoint("TOPLEFT", frame.searchBox, "BOTTOMLEFT", -2, -12)
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
                GuildRadioFM:PlaySong(button.songIndex)
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
        local matchesView = view ~= "favorites" or self:IsFavorite(index)
        local matchesFilter = filter == "" or string.find(title, filter, 1, true) or string.find(file, filter, 1, true)
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
    if self.db.libraryView == "favorites" then
        frame.unlikeButton:Show()
    else
        frame.unlikeButton:Hide()
    end
    local firstVisible = #rows == 0 and 0 or (self.db.libraryScroll or 0) + 1
    local lastVisible = math.min(#rows, (self.db.libraryScroll or 0) + visibleRows)
    frame.countText:SetText(firstVisible .. "-" .. lastVisible .. " of " .. #rows)

    for i, row in ipairs(frame.rows) do
        local item = rows[i + (self.db.libraryScroll or 0)]
        if item and i <= visibleRows then
            row.songIndex = item.index
            row.text:SetText((self:IsFavorite(item.index) and "* " or "") .. item.index .. ". " .. (item.song.title or item.song.file or "Untitled"))
            row:Show()
            if item.index == self.db.currentIndex then
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
        frame.rows[1].text:SetText(self:GetSongCount() == 0 and "No songs listed in SongList.lua." or "No songs match this view.")
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
        "{ title = \"My Song\", file = \"Interface\\\\AddOns\\\\GuildRadioFM\\\\Songs\\\\My Song.mp3\" },\n\n" ..
        "4. Save SongList.lua, then fully restart WoW or type /reload.\n\n" ..
        "Rules: file names must match exactly, including spaces. Keep the songs in this addon's Songs folder. Do not use D:\\ paths or internet links; WoW addons cannot read them."
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

    button:SetScript("OnDragStart", function()
        button.isDragging = true
    end)

    button:SetScript("OnDragStop", function()
        button.isDragging = false
    end)

    button:SetScript("OnUpdate", function()
        if not button.isDragging or not Minimap then return end
        local scale = UIParent and UIParent:GetEffectiveScale() or 1
        local cursorX, cursorY = GetCursorPosition()
        local centerX, centerY = Minimap:GetCenter()
        cursorX = cursorX / scale
        cursorY = cursorY / scale
        local deltaY = cursorY - centerY
        local deltaX = cursorX - centerX
        local angle = math.deg(math.atan2 and math.atan2(deltaY, deltaX) or math.atan(deltaY, deltaX))
        GuildRadioFM.db.minimap.angle = angle
        GuildRadioFM:PositionMinimapButton()
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
    panel.version:SetText("Core v" .. tostring(self.version) .. " - local music library")
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
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

function GuildRadioFM:OpenOptionsPanel()
    self:CreateOptionsPanel()
    if Settings and Settings.OpenToCategory and self.optionsCategory then
        Settings.OpenToCategory(self.optionsCategory.ID or self.optionsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
    else
        self:ToggleSettingsWindow()
    end
end
