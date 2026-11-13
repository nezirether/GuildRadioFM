-- GuildRadioFM 2.3 interface: one window with tabs (Now Playing, Library, Playlists, Live, Settings),
-- a mini player, a now-playing toast, and the live invite card. Dark glass over the game's own
-- loading-screen art, WoW gold accent, Morpheus title,
-- custom art in Media/ (made by tools/make_art.py). No stock Blizzard button templates.
local R = GuildRadioFM
local MEDIA = "Interface\\AddOns\\GuildRadioFM\\Media\\"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local EMBLEM = MEDIA .. "GuildRadioFM_Emblem.tga"
local LOGO_FONT = "Fonts\\MORPHEUS.TTF"
-- the game's own loading-screen art, darkened, behind the window
local BACKDROPS = {
    { key = "kalimdor", label = "Kalimdor", path = "Interface\\Glues\\LoadingScreens\\LoadScreenKalimdor" },
    { key = "eastern", label = "Eastern Kingdoms", path = "Interface\\Glues\\LoadingScreens\\LoadScreenEasternKingdom" },
    { key = "none", label = "Plain" },
}
local ICON = MEDIA .. "GuildRadioFM_Icon.tga"
local ATLAS = MEDIA .. "GuildRadioFM_Icons.tga"
local TITLE_FONT = "Fonts\\FRIZQT__.TTF"
local BODY_FONT = "Fonts\\ARIALN.TTF"

local C = {
    bg = { 0.035, 0.031, 0.027, 0.97 },
    shade = { 0.02, 0.018, 0.015, 0.8 },
    surface = { 0.06, 0.054, 0.047, 0.78 },
    raised = { 0.13, 0.115, 0.095, 0.95 },
    line = { 1, 1, 1, 0.07 },
    text = { 0.96, 0.94, 0.9, 1 },
    dim = { 0.66, 0.62, 0.55, 1 },
    faint = { 0.45, 0.42, 0.37, 1 },
    acc = { 1, 0.78, 0.3, 1 },
    acc2 = { 0.45, 0.9, 0.55, 1 },
    live = { 1, 0.3, 0.38, 1 },
}
local ICONS = { prev = 0, play = 1, stop = 2, next = 3, heart = 4, heartline = 5, shuffle = 6, ["repeat"] = 7,
    volume = 8, mute = 9, plus = 10, close = 11, up = 12, down = 13, minus = 14, live = 15 }

-- ---------- primitives ----------
local function Tex(parent, layer, c, a)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(WHITE)
    t:SetVertexColor(c[1], c[2], c[3], a or c[4] or 1)
    return t
end

local function Fill(frame, c, a)
    local t = Tex(frame, "BACKGROUND", c, a)
    t:SetAllPoints()
    return t
end

local function Outline(frame, c, a)
    c = c or C.line
    local edges = {}
    for i, e in ipairs({ { "TOPLEFT", "TOPRIGHT", nil, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", nil, 1 }, { "TOPLEFT", "BOTTOMLEFT", 1, nil }, { "TOPRIGHT", "BOTTOMRIGHT", 1, nil } }) do
        local t = Tex(frame, "BORDER", c, a)
        t:SetPoint(e[1]); t:SetPoint(e[2])
        if e[3] then t:SetWidth(e[3]) end
        if e[4] then t:SetHeight(e[4]) end
        edges[i] = t
    end
    return edges
end

local function Text(parent, size, c, font, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(font or BODY_FONT, size or 13, "")
    c = c or C.text
    fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    return fs
end

local function SetColor(fs, c) fs:SetTextColor(c[1], c[2], c[3], c[4] or 1) end

local function Icon(parent, name, size, layer)
    local t = parent:CreateTexture(nil, layer or "ARTWORK")
    t:SetTexture(ATLAS)
    t:SetSize(size, size)
    local i = ICONS[name] or 0
    t:SetTexCoord(i / 16, (i + 1) / 16, 0, 1)
    t.SetIcon = function(selfT, n) local k = ICONS[n] or 0; selfT:SetTexCoord(k / 16, (k + 1) / 16, 0, 1) end
    return t
end

local function Tip(frame, text)
    frame:SetScript("OnEnter", function(selfF)
        if selfF.Hover then selfF:Hover(true) end
        local tip = type(text) == "function" and text(selfF) or text
        if tip and GameTooltip then
            GameTooltip:SetOwner(selfF, "ANCHOR_TOP")
            GameTooltip:SetText(tip, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function(selfF)
        if selfF.Hover then selfF:Hover(false) end
        if GameTooltip then GameTooltip:Hide() end
    end)
end

-- icon-only button; :SetActive(true) tints it violet
local function IconButton(parent, name, size, onClick, tip, box)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(box or size + 10, box or size + 10)
    b.icon = Icon(b, name, size)
    b.icon:SetPoint("CENTER")
    b.active = false
    function b:Paint(h)
        local c = self.active and C.acc or (h and C.text or C.dim)
        if self.disabled then c = C.faint end
        self.icon:SetVertexColor(c[1], c[2], c[3], 1)
    end
    function b:Hover(h) self:Paint(h) end
    function b:SetActive(on) self.active = on and true or false; self:Paint(false) end
    function b:SetDisabledLook(off) self.disabled = off; self:Paint(false) end
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(selfB, mouse)
        if selfB.justDragged then selfB.justDragged = false; return end
        if not selfB.disabled then onClick(selfB, mouse) end
    end)
    Tip(b, tip)
    b:Paint(false)
    return b
end

-- let a drag that starts on a button move the whole window instead of clicking the button
local function DragThrough(btn, frame, store)
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(selfB) selfB.justDragged = true; frame:StartMoving() end)
    btn:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); R:SaveWindow(frame, store()) end)
end

-- text button: "primary" = violet fill, "ghost" = quiet surface
local function TextButton(parent, label, width, height, onClick, style)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height or 26)
    b.style = style or "ghost"
    b.bg = Fill(b, C.raised)
    b.edge = Outline(b, C.line)
    b.label = Text(b, 12, C.text, BODY_FONT, "CENTER")
    b.label:SetPoint("CENTER")
    b.label:SetText(label)
    function b:Paint(h)
        local c, tc
        if self.style == "primary" then c, tc = C.acc, { 0.05, 0.04, 0.09, 1 }
        elseif self.style == "danger" then c, tc = C.live, { 0.08, 0.02, 0.03, 1 }
        else c, tc = C.raised, C.text end
        local lift = h and 0.08 or 0
        self.bg:SetVertexColor(math.min(1, c[1] + lift), math.min(1, c[2] + lift), math.min(1, c[3] + lift), self.disabled and 0.4 or 1)
        SetColor(self.label, self.disabled and C.faint or tc)
        for _, e in ipairs(self.edge) do e:SetAlpha(self.style == "ghost" and 1 or 0) end
    end
    function b:Hover(h) self:Paint(h) end
    function b:SetLabel(t) self.label:SetText(t) end
    function b:SetStyle(s) self.style = s; self:Paint(false) end
    function b:SetDisabledLook(off) self.disabled = off; self:Paint(false) end
    b:SetScript("OnClick", function(selfB, ...) if not selfB.disabled then onClick(selfB, ...) end end)
    Tip(b, nil)
    b:Paint(false)
    return b
end

-- small pill toggle (filters, open/closed)
local function Pill(parent, label, onClick)
    local b = TextButton(parent, label, 10, 22, onClick, "ghost")
    b.label:SetFont(BODY_FONT, 11, "")
    b:SetWidth(b.label:GetStringWidth() + 22)
    function b:SetOn(on)
        self.on = on
        self.bg:SetVertexColor(on and C.acc[1] * 0.35 or C.raised[1], on and C.acc[2] * 0.35 or C.raised[2], on and C.acc[3] * 0.4 or C.raised[3], 1)
        SetColor(self.label, on and C.text or C.dim)
    end
    local paint = b.Paint
    function b:Paint(h) paint(self, h); if self.on ~= nil then self:SetOn(self.on) end end
    return b
end

local function Switch(parent, onClick)
    local s = CreateFrame("Button", nil, parent)
    s:SetSize(34, 18)
    s.track = Fill(s, C.raised)
    Outline(s, C.line)
    s.knob = Tex(s, "ARTWORK", C.dim)
    s.knob:SetSize(12, 12)
    function s:SetOn(on)
        self.on = on
        self.knob:ClearAllPoints()
        self.knob:SetPoint(on and "RIGHT" or "LEFT", on and -3 or 3, 0)
        local k = on and C.text or C.dim
        self.knob:SetVertexColor(k[1], k[2], k[3], 1)
        local t = on and C.acc or C.raised
        self.track:SetVertexColor(t[1], t[2], t[3], 1)
    end
    s:SetScript("OnClick", function(selfS) onClick(not selfS.on) end)
    s:SetOn(false)
    return s
end

local function Search(parent, width, placeholder, onChange)
    local box = CreateFrame("EditBox", nil, parent)
    box:SetSize(width, 26)
    box:SetAutoFocus(false)
    box:SetFont(BODY_FONT, 13, "")
    box:SetTextColor(C.text[1], C.text[2], C.text[3])
    box:SetTextInsets(10, 10, 0, 0)
    Fill(box, C.surface)
    box.edge = Outline(box, C.line)
    box.hint = Text(box, 13, C.faint)
    box.hint:SetPoint("LEFT", 10, 0)
    box.hint:SetText(placeholder)
    box:SetScript("OnEscapePressed", function(selfB) selfB:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(selfB) selfB:ClearFocus() end)
    box:SetScript("OnEditFocusGained", function(selfB) for _, e in ipairs(selfB.edge) do e:SetVertexColor(C.acc[1], C.acc[2], C.acc[3], 0.7) end end)
    box:SetScript("OnEditFocusLost", function(selfB) for _, e in ipairs(selfB.edge) do e:SetVertexColor(1, 1, 1, 0.07) end end)
    box:SetScript("OnTextChanged", function(selfB)
        local t = selfB:GetText() or ""
        if t == "" then selfB.hint:Show() else selfB.hint:Hide() end
        if onChange then onChange(t) end
    end)
    return box
end

-- thin horizontal slider (0-100)
local function Slider(parent, width, onChange)
    local s = CreateFrame("Frame", nil, parent)
    s:SetSize(width, 16)
    s:EnableMouse(true)
    s.track = Tex(s, "BACKGROUND", C.raised)
    s.track:SetPoint("LEFT"); s.track:SetPoint("RIGHT"); s.track:SetHeight(4)
    s.fill = Tex(s, "ARTWORK", C.acc)
    s.fill:SetPoint("LEFT", s.track, "LEFT"); s.fill:SetHeight(4)
    s.knob = Tex(s, "OVERLAY", C.text)
    s.knob:SetSize(10, 10)
    function s:SetValue(v)
        v = math.max(0, math.min(100, v or 0))
        self.value = v
        local w = self:GetWidth() * v / 100
        self.fill:SetWidth(math.max(0.01, w))
        self.knob:ClearAllPoints()
        self.knob:SetPoint("CENTER", self.track, "LEFT", w, 0)
    end
    local function track()
        local x = GetCursorPosition() / s:GetEffectiveScale()
        local v = math.floor((x - s:GetLeft()) / s:GetWidth() * 100 + 0.5)
        v = math.max(0, math.min(100, v))
        if v ~= s.value then s:SetValue(v); onChange(v) end
    end
    s:SetScript("OnMouseDown", function(selfS) selfS.dragging = true; track() end)
    s:SetScript("OnMouseUp", function(selfS) selfS.dragging = false end)
    s:SetScript("OnUpdate", function(selfS) if selfS.dragging then track() end end)
    s:SetValue(50)
    return s
end

local function Wheel(frame, fn)
    frame:EnableMouseWheel(true)
    frame:SetScript("OnMouseWheel", function(_, d) fn(d) end)
end

-- fixed-row list; render(row, item, n) fills a row, items() returns the array
local function List(parent, rowH, nRows, build, render, items, scrollKey)
    local list = CreateFrame("Frame", nil, parent)
    list.rows = {}
    local function scroll(d)
        R.db[scrollKey] = (R.db[scrollKey] or 0) - d
        list:Refresh()
    end
    for i = 1, nRows do
        local row = CreateFrame("Button", nil, list)
        row:SetHeight(rowH)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * rowH)
        row:SetPoint("TOPRIGHT", 0, -(i - 1) * rowH)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row.hl = Fill(row, C.text, 0)
        row.mark = Tex(row, "ARTWORK", C.acc)
        row.mark:SetPoint("TOPLEFT"); row.mark:SetPoint("BOTTOMLEFT"); row.mark:SetWidth(2)
        row.mark:Hide()
        function row:Hover(h) self.hl:SetAlpha(h and 0.045 or (self.selected and 0.03 or 0)) end
        row.wheel = scroll
        Wheel(row, scroll)
        build(row)
        list.rows[i] = row
    end
    Wheel(list, scroll)
    function list:Refresh()
        local data = items() or {}
        local off = math.max(0, math.min(R.db[scrollKey] or 0, #data - nRows))
        R.db[scrollKey] = off
        for i, row in ipairs(self.rows) do
            local item = data[i + off]
            row.item = item
            row.selected = false
            row.mark:Hide()
            if item then render(row, item, i + off); row:Show() else row:Hide() end
            row:Hover(false)
        end
        if #data == 0 and self.empty then
            local row = self.rows[1]
            row.item = nil
            self.empty(row)
            row:Show()
        end
        self.count = #data
    end
    return list
end

local function Eyebrow(parent, text)
    local fs = Text(parent, 10, C.faint, BODY_FONT)
    fs:SetText(string.upper(text))
    return fs
end

local function Fmt(sec)
    sec = math.max(0, math.floor(sec or 0))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function EB() return R.Live end

-- ---------- main window ----------
local TABS = { { "now", "Now Playing" }, { "library", "Library" }, { "playlists", "Playlists" }, { "live", "Live" }, { "settings", "Settings" } }
local W, H = 640, 452          -- design size; shown scaled (db.scale, default 0.8)

function R:CreateMainWindow()
    if self.mainFrame then return end
    local f = CreateFrame("Frame", "GuildRadioFMMainFrame", UIParent)
    self.mainFrame = f
    f:SetSize(W, H)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(selfF) selfF:StopMovingOrSizing(); R:SaveWindow(selfF, R.db.window) end)
    local w = self.db.window or {}
    f:SetPoint(w.point or "CENTER", UIParent, w.relativePoint or "CENTER", w.x or 0, w.y or 0)
    Fill(f, C.bg)
    f.art = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.art:SetAllPoints()
    f.shade = Tex(f, "BACKGROUND", C.shade)
    f.shade:SetDrawLayer("BACKGROUND", 2)
    f.shade:SetAllPoints()
    f.headShade = Tex(f, "BACKGROUND", { 0, 0, 0 }, 0.45)
    f.headShade:SetDrawLayer("BACKGROUND", 3)
    f.headShade:SetPoint("TOPLEFT"); f.headShade:SetPoint("TOPRIGHT"); f.headShade:SetHeight(88)
    Outline(f, C.acc, 0.25)
    if UISpecialFrames then table.insert(UISpecialFrames, "GuildRadioFMMainFrame") end

    -- header
    f.emblem = f:CreateTexture(nil, "ARTWORK")
    f.emblem:SetTexture(EMBLEM)
    f.emblem:SetSize(38, 38)
    f.emblem:SetPoint("TOPLEFT", 14, -10)
    f.logo = Text(f, 26, C.acc, LOGO_FONT)
    f.logo:SetShadowColor(0, 0, 0, 1)
    f.logo:SetShadowOffset(1, -1)
    f.logo:SetPoint("LEFT", f.emblem, "RIGHT", 10, 1)
    f.logo:SetText("GuildRadio")
    f.logoFM = Text(f, 11, C.dim, TITLE_FONT)
    f.logoFM:SetPoint("BOTTOMLEFT", f.logo, "BOTTOMRIGHT", 5, 4)
    f.logoFM:SetText("FM")
    f.close = IconButton(f, "close", 14, function() f:Hide() end, nil)
    f.close:SetPoint("TOPRIGHT", -8, -10)
    f.miniBtn = TextButton(f, "Mini player", 82, 22, function() R:ToggleMiniWindow() end, "ghost")
    f.miniBtn.label:SetFont(BODY_FONT, 11, "")
    f.miniBtn:SetPoint("RIGHT", f.close, "LEFT", -6, 0)
    f.headLive = Text(f, 11, C.live, BODY_FONT, "RIGHT")
    f.headLive:SetPoint("RIGHT", f.miniBtn, "LEFT", -10, 0)

    -- tabs
    f.tabs = {}
    local x = 18
    for _, t in ipairs(TABS) do
        local key, label = t[1], t[2]
        local b = CreateFrame("Button", nil, f)
        b.label = Text(b, 13, C.dim, BODY_FONT, "CENTER")
        b.label:SetText(label)
        b.label:SetPoint("CENTER")
        b:SetSize(b.label:GetStringWidth() + 20, 30)
        b:SetPoint("TOPLEFT", x, -58)
        x = x + b:GetWidth() + 4
        b.bar = Tex(b, "ARTWORK", C.acc)
        b.bar:SetPoint("BOTTOMLEFT", 8, 0); b.bar:SetPoint("BOTTOMRIGHT", -8, 0); b.bar:SetHeight(2)
        if key == "live" then
            b.dot = Tex(b, "OVERLAY", C.live)
            b.dot:SetSize(6, 6)
            b.dot:SetPoint("LEFT", b.label, "RIGHT", 4, 4)
            b.dot:Hide()
        end
        function b:Hover(h) if R.db.tab ~= key then SetColor(self.label, h and C.text or C.dim) end end
        Tip(b, nil)
        b:SetScript("OnClick", function() R:ShowTab(key) end)
        f.tabs[key] = b
    end
    local sep = Tex(f, "BORDER", C.line)
    sep:SetPoint("TOPLEFT", 0, -88); sep:SetPoint("TOPRIGHT", 0, -88); sep:SetHeight(1)

    f.pages = {}
    for _, t in ipairs(TABS) do
        local p = CreateFrame("Frame", nil, f)
        p:SetPoint("TOPLEFT", 18, -102)
        p:SetPoint("BOTTOMRIGHT", -18, 16)
        p:Hide()
        f.pages[t[1]] = p
    end
    self:BuildNowPage(f.pages.now)
    self:BuildLibraryPage(f.pages.library)
    self:BuildPlaylistPage(f.pages.playlists)
    self:BuildLivePage(f.pages.live)
    self:BuildSettingsPage(f.pages.settings)

    local acc = 0
    f:SetScript("OnUpdate", function(_, el)
        acc = acc + el
        if acc < 0.1 then return end
        acc = 0
        R:UpdateProgress()
    end)
    self:AddScaleGrip(f, "scale")
    f:SetScale(self.db.scale or 0.8)
    self:ApplyBackdrop()
    f:Hide()
    self:ShowTab(self.db.tab or "now", true)
end

-- scale around the top-left corner so the window stays put while it grows or shrinks
function R:SetFrameScale(frame, key, scale)
    scale = math.max(0.5, math.min(1.4, scale))
    local old = frame:GetScale()
    local left, top = frame:GetLeft(), frame:GetTop()
    frame:SetScale(scale)
    if left and top then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * old / scale, top * old / scale)
    end
    self.db[key] = scale
    local store = frame == self.miniFrame and self.db.miniWindow or self.db.window
    self:SaveWindow(frame, store)
end

-- drag the bottom-right corner to resize (scales the whole window, text and all)
function R:AddScaleGrip(frame, key)
    local g = CreateFrame("Button", nil, frame)
    g:SetSize(16, 16)
    g:SetPoint("BOTTOMRIGHT", -2, 2)
    g.lines = {}
    for i = 1, 3 do
        local t = Tex(g, "OVERLAY", C.dim)
        t:SetSize(2, 2)
        t:SetPoint("BOTTOMRIGHT", -2 - (i - 1) * 4, 2)
        local u = Tex(g, "OVERLAY", C.dim)
        u:SetSize(2, 2)
        u:SetPoint("BOTTOMRIGHT", -2, 2 + (i - 1) * 4)
        g.lines[#g.lines + 1] = t; g.lines[#g.lines + 1] = u
    end
    local d = Tex(g, "OVERLAY", C.dim); d:SetSize(2, 2); d:SetPoint("BOTTOMRIGHT", -6, 6); g.lines[#g.lines + 1] = d
    function g:Hover(h)
        local c = h and C.acc or C.dim
        for _, t in ipairs(self.lines) do t:SetVertexColor(c[1], c[2], c[3], 1) end
    end
    Tip(g, "Drag to resize")
    local st
    g:SetScript("OnMouseDown", function()
        local x = GetCursorPosition()
        st = { x = x, scale = frame:GetScale(), width = frame:GetWidth() * frame:GetEffectiveScale() }
    end)
    g:SetScript("OnMouseUp", function() st = nil; R:RefreshAll() end)
    g:SetScript("OnUpdate", function()
        if not st then return end
        local x = GetCursorPosition()
        local want = st.scale * (st.width + (x - st.x)) / st.width
        if math.abs(want - frame:GetScale()) > 0.005 then R:SetFrameScale(frame, key, want) end
    end)
    return g
end

function R:ApplyBackdrop()
    local f = self.mainFrame
    if not f then return end
    local choice = self.db.backdrop or "kalimdor"
    local path
    for _, b in ipairs(BACKDROPS) do if b.key == choice then path = b.path end end
    if path then
        f.art:SetTexture(path)
        -- loading screens are 4:3; trim top and bottom to the window's shape
        local cut = (1 - (4 / 3) / (W / H)) / 2
        f.art:SetTexCoord(0, 1, cut, 1 - cut)
        f.art:Show()
        f.shade:SetAlpha(1)
    else
        f.art:Hide()
        f.shade:SetAlpha(0)
    end
end

function R:ShowTab(key, quiet)
    self:CreateMainWindow()
    local f = self.mainFrame
    if not f.pages[key] then key = "now" end
    self.db.tab = key
    for k, p in pairs(f.pages) do if k == key then p:Show() else p:Hide() end end
    for k, b in pairs(f.tabs) do
        SetColor(b.label, k == key and C.text or C.dim)
        if k == key then b.bar:Show() else b.bar:Hide() end
    end
    if not quiet then f:Show() end
    self:RefreshAll()
end

function R:ToggleTab(key)
    self:CreateMainWindow()
    if self.mainFrame:IsShown() and self.db.tab == key then self.mainFrame:Hide() else self:ShowTab(key) end
end

function R:ToggleMainWindow()
    self:CreateMainWindow()
    if self.mainFrame:IsShown() then self.mainFrame:Hide() else self:ShowTab(self.db.tab or "now") end
end
function R:ToggleLibraryWindow() self:ToggleTab("library") end
function R:TogglePlaylistWindow() self:ToggleTab("playlists") end
function R:ToggleSettingsWindow() self:ToggleTab("settings") end
function R:ToggleAddSongsWindow() self:ToggleTab("settings") end
function R:ToggleLiveWindow() self:ToggleTab("live") end

local function PageShown(key)
    local f = R.mainFrame
    return f and f:IsShown() and f.pages[key]:IsShown()
end

-- what's going on, in one line, for eyebrows and the mini player
function R:StatusLine()
    local eb = EB()
    if eb and eb.live then return "ON AIR", C.live end
    if eb and eb.tuned then return "TUNED IN  ·  " .. string.upper(eb.Short(eb.tuned)), C.acc2 end
    if self.db.isPlaying then
        if self.db.playFromPlaylist then
            local p = self:GetSelectedPlaylist()
            return "PLAYLIST  ·  " .. string.upper(p and p.name or ""), C.faint
        elseif self.db.playFromFavorites then return "LIKED SONGS", C.faint end
        return "NOW PLAYING", C.faint
    end
    return "STOPPED", C.faint
end

-- ---------- Now Playing ----------
function R:BuildNowPage(p)
    local art = CreateFrame("Frame", nil, p)
    art:SetSize(170, 170)
    art:SetPoint("TOPLEFT", 0, -6)
    Fill(art, C.surface)
    Outline(art, C.line)
    art.glow = art:CreateTexture(nil, "ARTWORK")
    art.glow:SetTexture(EMBLEM)
    art.glow:SetSize(128, 128)
    art.glow:SetPoint("CENTER", 0, 6)
    art.badge = Text(art, 10, C.live, BODY_FONT, "CENTER")
    art.badge:SetPoint("BOTTOM", 0, 10)
    p.art = art
    local t = 0
    art:SetScript("OnUpdate", function(_, el)
        t = t + el
        local a = R.db.isPlaying and (0.8 + 0.2 * math.sin(t * 2.4)) or 0.45
        art.glow:SetAlpha(a)
    end)

    local x = 196
    p.eyebrow = Eyebrow(p, "Now playing")
    p.eyebrow:SetPoint("TOPLEFT", x, -14)
    p.title = Text(p, 22, C.acc, TITLE_FONT)
    p.title:SetShadowColor(0, 0, 0, 1)
    p.title:SetShadowOffset(1, -1)
    p.title:SetPoint("TOPLEFT", x, -32)
    p.title:SetPoint("RIGHT", p, "RIGHT", 0, 0)
    p.sub = Text(p, 13, C.dim)
    p.sub:SetPoint("TOPLEFT", p.title, "BOTTOMLEFT", 0, -8)
    p.sub:SetPoint("RIGHT", p, "RIGHT", 0, 0)

    p.bar = CreateFrame("Frame", nil, p)
    p.bar:SetPoint("TOPLEFT", x, -102)
    p.bar:SetPoint("RIGHT", p, "RIGHT", 0, 0)
    p.bar:SetHeight(4)
    Fill(p.bar, C.raised)
    p.barFill = Tex(p.bar, "ARTWORK", C.acc)
    p.barFill:SetPoint("TOPLEFT"); p.barFill:SetPoint("BOTTOMLEFT")
    p.elapsed = Text(p, 11, C.dim)
    p.elapsed:SetPoint("TOPLEFT", p.bar, "BOTTOMLEFT", 0, -6)
    p.total = Text(p, 11, C.dim, BODY_FONT, "RIGHT")
    p.total:SetPoint("TOPRIGHT", p.bar, "BOTTOMRIGHT", 0, -6)

    -- transport
    local mid = CreateFrame("Frame", nil, p)
    mid:SetSize(250, 50)
    mid:SetPoint("TOP", p.bar, "BOTTOM", 0, -24)
    p.shuffle = IconButton(mid, "shuffle", 16, function() R:ToggleShuffle() end, "Shuffle")
    p.prev = IconButton(mid, "prev", 18, function() R:Back() end, "Previous")
    p.play = CreateFrame("Button", nil, mid)
    p.play:SetSize(50, 50)
    p.play.bg = Fill(p.play, C.acc)
    p.play.icon = Icon(p.play, "play", 22)
    p.play.icon:SetPoint("CENTER", 1, 0)
    p.play.icon:SetVertexColor(0.05, 0.04, 0.09)
    function p.play:Hover(h) self.bg:SetVertexColor(C.acc[1] + (h and 0.08 or 0), C.acc[2] + (h and 0.08 or 0), math.min(1, C.acc[3]), 1) end
    Tip(p.play, nil)
    p.play:SetScript("OnClick", function() if R.db.isPlaying then R:Stop() else R:Play() end end)
    p.next = IconButton(mid, "next", 18, function() R:Next() end, "Next")
    p["repeat"] = IconButton(mid, "repeat", 16, function() R:ToggleRepeat() end, "Repeat this song")
    p.play:SetPoint("CENTER")
    p.prev:SetPoint("RIGHT", p.play, "LEFT", -14, 0)
    p.shuffle:SetPoint("RIGHT", p.prev, "LEFT", -12, 0)
    p.next:SetPoint("LEFT", p.play, "RIGHT", 14, 0)
    p["repeat"]:SetPoint("LEFT", p.next, "RIGHT", 12, 0)

    -- like + volume
    p.like = IconButton(p, "heartline", 16, function() R:ToggleFavorite() end, "Like")
    p.like:SetPoint("TOPLEFT", p.bar, "BOTTOMLEFT", -6, -96)
    p.vol = IconButton(p, "volume", 16, function() R:ToggleMute() end, "Mute")
    p.vol:SetPoint("LEFT", p.like, "RIGHT", 10, 0)
    p.volume = Slider(p, 150, function(v) R.suppressVolumeUpdate = true; R:SetVolume(v); R.suppressVolumeUpdate = false end)
    p.volume:SetPoint("LEFT", p.vol, "RIGHT", 4, 0)
    p.volText = Text(p, 11, C.dim)
    p.volText:SetPoint("LEFT", p.volume, "RIGHT", 10, 0)

    -- live banner
    p.banner = CreateFrame("Frame", nil, p)
    p.banner:SetPoint("BOTTOMLEFT", 0, 0)
    p.banner:SetPoint("BOTTOMRIGHT", 0, 0)
    p.banner:SetHeight(46)
    Fill(p.banner, C.surface)
    Outline(p.banner, C.line)
    p.banner.icon = Icon(p.banner, "live", 18)
    p.banner.icon:SetPoint("LEFT", 14, 0)
    p.banner.icon:SetVertexColor(C.live[1], C.live[2], C.live[3])
    p.banner.text = Text(p.banner, 13, C.text)
    p.banner.text:SetPoint("LEFT", p.banner.icon, "RIGHT", 10, 0)
    p.banner.btn = TextButton(p.banner, "Tune in", 92, 26, function()
        local eb = EB()
        if eb.tuned then eb:TuneOut() else eb:TuneIn() end
    end, "primary")
    p.banner.btn:SetPoint("RIGHT", -10, 0)
    p.banner.text:SetPoint("RIGHT", p.banner.btn, "LEFT", -10, 0)
end

function R:UpdateNowPage()
    if not PageShown("now") then return end
    local p = self.mainFrame.pages.now
    local song, index = self:GetCurrentSong()
    local eyebrow, ec = self:StatusLine()
    p.eyebrow:SetText(eyebrow)
    SetColor(p.eyebrow, ec)
    p.title:SetText(song and song.title or "No songs yet")
    local eb = EB()
    local sub
    if eb and eb.missing then sub = "You don't have this song. Get the latest GuildRadioFM from your DJ."
    elseif eb and eb.waiting then sub = "Tuned in. You'll join at the next song."
    elseif eb and eb:JoiningIn() then sub = string.format("Joining in %ds, right in time with the room", math.ceil(eb:JoiningIn()))
    else
        sub = song and (song.artist or (song.id and string.match(song.id, "^noyze") and "Noyze Komplaynt") or "Guild library") or "Add songs in SongList.lua"
        if song then sub = sub .. "  ·  " .. index .. " of " .. self:GetSongCount() end
    end
    p.sub:SetText(sub)
    p.play.icon:SetIcon(self.db.isPlaying and "stop" or "play")
    p.shuffle:SetActive(self.db.shuffle)
    p["repeat"]:SetActive(self.db.repeatSong)
    local liked = index and self:IsFavorite(index)
    p.like.icon:SetIcon(liked and "heart" or "heartline")
    p.like:SetActive(liked)
    p.vol.icon:SetIcon(self.db.muted and "mute" or "volume")
    if not p.volume.dragging then p.volume:SetValue(self.db.muted and 0 or self.db.volume) end
    p.volText:SetText(self.db.muted and "muted" or (tostring(self.db.volume) .. "%"))
    p.art.badge:SetText(eb and eb.live and "ON AIR" or (eb and eb.tuned and "LIVE" or ""))

    local dj = eb and eb:CurrentDJ()
    if eb and (eb.tuned or (dj and not eb.live)) then
        local d = eb.tuned and eb.djs[eb.tuned] or dj
        local name = d and d.name or eb.Short(eb.tuned)
        local count = d and d.count or 0
        p.banner.text:SetText(eb.tuned and ("In " .. (d and d.room or (name .. "'s Room")) .. "  ·  " .. count .. " tuned in") or ((d and d.room or (name .. "'s Room")) .. " is open  ·  " .. count .. " tuned in"))
        p.banner.btn:SetLabel(eb.tuned and "Tune out" or "Tune in")
        p.banner.btn:SetStyle(eb.tuned and "ghost" or "primary")
        p.banner:Show()
    else
        p.banner:Hide()
    end
    self:UpdateProgress()
end

function R:SongPosition()
    local song = self:GetCurrentSong()
    if not self.db.isPlaying or not song or not self.startedAt then return 0, tonumber(song and song.duration) or 0 end
    local d = tonumber(song.duration) or 0
    local e = GetTime() - self.startedAt
    if d > 0 then e = math.min(e, d) end
    return math.max(0, e), d
end

function R:UpdateProgress()
    local e, d = self:SongPosition()
    if PageShown("now") then
        local p = self.mainFrame.pages.now
        local w = p.bar:GetWidth() or 0
        p.barFill:SetWidth(math.max(0.01, d > 0 and w * e / d or 0))
        p.elapsed:SetText(Fmt(e))
        p.total:SetText(d > 0 and Fmt(d) or "")
        local eb = EB()
        if eb and eb:JoiningIn() then p.sub:SetText(string.format("Joining in %ds, right in time with the set", math.ceil(eb:JoiningIn()))) end
    end
    if self.miniFrame and self.miniFrame:IsShown() then
        local m = self.miniFrame
        m.barFill:SetWidth(math.max(0.01, d > 0 and m:GetWidth() * e / d or 0))
    end
end

-- ---------- Library ----------
function R:GetFilteredSongs()
    local filter = string.lower(self.db.search or "")
    local view = self.db.libraryView or "all"
    local rows = {}
    for index, song in ipairs(self.songs or {}) do
        local title = string.lower(song.title or "")
        local matchesView = view ~= "favorites" or self:IsFavorite(index)
        local matchesFilter = filter == "" or string.find(title, filter, 1, true)
        if matchesView and matchesFilter then rows[#rows + 1] = { index = index, song = song } end
    end
    return rows
end

function R:BuildLibraryPage(p)
    p.search = Search(p, 230, "Search songs", function(t) R.db.search = t; R.db.libraryScroll = 0; R:UpdateLibraryWindow() end)
    p.search:SetPoint("TOPLEFT", 0, 0)
    p.all = Pill(p, "All", function() R:SetLibraryView("all") end)
    p.all:SetPoint("LEFT", p.search, "RIGHT", 10, 0)
    p.liked = Pill(p, "Liked", function() R:SetLibraryView("favorites") end)
    p.liked:SetPoint("LEFT", p.all, "RIGHT", 6, 0)
    p.playLiked = TextButton(p, "Play liked", 86, 22, function() R:PlayFavoriteEntry(1) end, "ghost")
    p.playLiked.label:SetFont(BODY_FONT, 11, "")
    p.playLiked:SetPoint("LEFT", p.liked, "RIGHT", 6, 0)
    p.count = Text(p, 11, C.faint, BODY_FONT, "RIGHT")
    p.count:SetPoint("RIGHT", p, "TOPRIGHT", 0, -13)

    local holder = CreateFrame("Frame", nil, p)
    holder:SetPoint("TOPLEFT", 0, -38)
    holder:SetPoint("BOTTOMRIGHT", 0, 0)
    Fill(holder, C.surface)
    Outline(holder, C.line)
    p.list = List(holder, 28, 10, function(row)
        row.num = Text(row, 11, C.faint, BODY_FONT, "RIGHT")
        row.num:SetPoint("LEFT", 6, 0); row.num:SetWidth(22)
        row.title = Text(row, 13, C.text)
        row.title:SetPoint("LEFT", 38, 0)
        row.dur = Text(row, 11, C.faint, BODY_FONT, "RIGHT")
        row.req = IconButton(row, "live", 14, function(b) EB():Request(EB().KeyOf(b:GetParent().item.song)) end,
            function() local eb = EB(); return eb.live and "Add to your Request Line" or "Request in the room" end, 26)
        row.add = IconButton(row, "plus", 12, function(b) R:AddSongToSelectedPlaylist(b:GetParent().item.index) end,
            function() local pl = R:GetSelectedPlaylist(); return pl and not pl.runtime and ("Add to " .. pl.name) or "Make a playlist first" end, 26)
        row.like = IconButton(row, "heartline", 13, function(b) R:ToggleFavorite(b:GetParent().item.index) end, "Like", 26)
        row.like:SetPoint("RIGHT", -6, 0)
        row.add:SetPoint("RIGHT", row.like, "LEFT", 0, 0)
        row.req:SetPoint("RIGHT", row.add, "LEFT", 0, 0)
        row.dur:SetPoint("RIGHT", row.req, "LEFT", -6, 0)
        row.title:SetPoint("RIGHT", row.dur, "LEFT", -8, 0)
        for _, b in ipairs({ row.req, row.add, row.like }) do Wheel(b, row.wheel) end
        row:SetScript("OnClick", function(selfRow, mouse)
            if not selfRow.item then return end
            if mouse == "RightButton" then R:AddSongToSelectedPlaylist(selfRow.item.index) else R:PlaySong(selfRow.item.index) end
        end)
        Tip(row, nil)
    end, function(row, item)
        local current = item.index == R.db.currentIndex and R.db.isPlaying
        row.num:SetText(item.index)
        row.title:SetText(item.song.title or "Untitled")
        SetColor(row.title, current and C.acc or C.text)
        row.dur:SetText(item.song.duration and Fmt(item.song.duration) or "")
        local liked = R:IsFavorite(item.index)
        row.like.icon:SetIcon(liked and "heart" or "heartline")
        row.like:SetActive(liked)
        local eb = EB()
        local someoneLive = eb and (eb.live or eb.tuned or eb:CurrentDJ())
        if someoneLive then
            row.req:Show()
            row.req:SetActive(eb:Requested(eb.KeyOf(item.song)))
        else row.req:Hide() end
        row.add:Show(); row.like:Show()
        if current then row.mark:Show() end
    end, function() return R:GetFilteredSongs() end, "libraryScroll")
    p.list:SetPoint("TOPLEFT", 1, -1)
    p.list:SetPoint("BOTTOMRIGHT", -1, 1)
    p.list.empty = function(row)
        row.num:SetText(""); row.dur:SetText(""); row.req:Hide(); row.add:Hide(); row.like:Hide()
        row.title:SetText(R:GetSongCount() == 0 and "No songs yet. See Settings for how to add them." or "Nothing matches.")
        SetColor(row.title, C.faint)
    end
end

function R:UpdateLibraryWindow()
    if not PageShown("library") then return end
    local p = self.mainFrame.pages.library
    local view = self.db.libraryView or "all"
    p.all:SetOn(view == "all")
    p.liked:SetOn(view == "favorites")
    p.list:Refresh()
    p.count:SetText(p.list.count .. (p.list.count == 1 and " song" or " songs"))
end

-- ---------- Playlists ----------
function R:BuildPlaylistPage(p)
    local left = CreateFrame("Frame", nil, p)
    left:SetPoint("TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", 0, 0)
    left:SetWidth(200)
    Fill(left, C.surface)
    Outline(left, C.line)
    p.lists = List(left, 30, 9, function(row)
        row.name = Text(row, 13, C.text)
        row.name:SetPoint("LEFT", 12, 0)
        row.n = Text(row, 11, C.faint, BODY_FONT, "RIGHT")
        row.n:SetPoint("RIGHT", -10, 0)
        row.name:SetPoint("RIGHT", row.n, "LEFT", -6, 0)
        row:SetScript("OnClick", function(selfRow) if selfRow.item then R:SelectPlaylist(selfRow.item.i) end end)
        Tip(row, nil)
    end, function(row, item)
        row.name:SetText(item.pl.name)
        row.n:SetText(#(item.pl.songs or {}))
        local sel = item.i == R.db.selectedPlaylistIndex
        row.selected = sel
        SetColor(row.name, sel and C.text or C.dim)
        if sel then row.mark:Show() end
    end, function()
        local out = {}
        for i, pl in ipairs(R:GetAllPlaylists()) do out[i] = { i = i, pl = pl } end
        return out
    end, "playlistScroll")
    p.lists:SetPoint("TOPLEFT", 1, -1)
    p.lists:SetPoint("BOTTOMRIGHT", -1, 40)
    p.lists.empty = function(row) row.name:SetText("No playlists yet"); SetColor(row.name, C.faint); row.n:SetText("") end
    p.newName = Search(left, 150, "New playlist", nil)
    p.newName:SetPoint("BOTTOMLEFT", 6, 7)
    p.newName:SetScript("OnEnterPressed", function(selfB) R:CreatePlaylist(selfB:GetText()); selfB:SetText(""); selfB:ClearFocus() end)
    p.newBtn = IconButton(left, "plus", 13, function() R:CreatePlaylist(p.newName:GetText()); p.newName:SetText("") end, "Create playlist", 30)
    p.newBtn:SetPoint("LEFT", p.newName, "RIGHT", 4, 0)

    local right = CreateFrame("Frame", nil, p)
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 14, 0)
    right:SetPoint("BOTTOMRIGHT", 0, 0)
    p.head = Text(right, 18, C.text, TITLE_FONT)
    p.head:SetPoint("TOPLEFT", 2, -4)
    p.headSub = Text(right, 11, C.faint)
    p.headSub:SetPoint("TOPLEFT", p.head, "BOTTOMLEFT", 0, -5)
    p.del = TextButton(right, "Delete", 62, 24, function() R:DeleteSelectedPlaylist() end, "ghost")
    p.del:SetPoint("TOPRIGHT", 0, 0)
    p.clear = TextButton(right, "Clear", 56, 24, function() R:ClearSelectedPlaylist() end, "ghost")
    p.clear:SetPoint("RIGHT", p.del, "LEFT", -6, 0)
    p.playAll = TextButton(right, "Play", 64, 24, function() R:PlayPlaylistEntry(R.db.playlistEntryIndex or 1) end, "primary")
    p.playAll:SetPoint("RIGHT", p.clear, "LEFT", -6, 0)
    p.addBtn = TextButton(right, "Add songs", 78, 24, function() p.adding = not p.adding; R.db.pickScroll = 0; R:UpdatePlaylistWindow() end, "ghost")
    p.addBtn:SetPoint("RIGHT", p.playAll, "LEFT", -6, 0)
    p.head:SetPoint("RIGHT", p.addBtn, "LEFT", -8, 0)
    p.headSub:SetPoint("RIGHT", p.addBtn, "LEFT", -8, 0)

    -- click the playlist name to rename it
    p.rename = CreateFrame("EditBox", nil, right)
    p.rename:SetFont(TITLE_FONT, 16, "")
    p.rename:SetTextColor(C.text[1], C.text[2], C.text[3])
    p.rename:SetAutoFocus(false)
    p.rename:SetMaxLetters(40)
    p.rename:SetSize(170, 24)
    p.rename:SetPoint("TOPLEFT", 0, -2)
    Fill(p.rename, C.raised)
    p.rename:Hide()
    p.rename:SetScript("OnEnterPressed", function(selfB)
        local pl = R:GetSelectedPlaylist()
        local name = strtrim and strtrim(selfB:GetText() or "") or (selfB:GetText() or "")
        if pl and not pl.runtime and name ~= "" then pl.name = name end
        selfB:ClearFocus(); selfB:Hide(); R:RefreshAll()
    end)
    p.rename:SetScript("OnEscapePressed", function(selfB) selfB:ClearFocus(); selfB:Hide() end)
    p.headHit = CreateFrame("Button", nil, right)
    p.headHit:SetPoint("TOPLEFT", p.head, "TOPLEFT")
    p.headHit:SetPoint("BOTTOMRIGHT", p.head, "BOTTOMRIGHT")
    function p.headHit:Hover(h)
        local pl = R:GetSelectedPlaylist()
        if pl and not pl.runtime then SetColor(p.head, h and C.acc or C.text) end
    end
    Tip(p.headHit, function() local pl = R:GetSelectedPlaylist(); return pl and not pl.runtime and "Click to rename" or nil end)
    p.headHit:SetScript("OnClick", function()
        local pl = R:GetSelectedPlaylist()
        if not pl or pl.runtime then return end
        p.rename:SetText(pl.name or "")
        p.rename:Show(); p.rename:SetFocus(); p.rename:HighlightText()
    end)

    -- "Add songs": the whole library with a + on each row, adds straight to this playlist
    local pick = CreateFrame("Frame", nil, right)
    p.pick = pick
    pick:SetPoint("TOPLEFT", 0, -46)
    pick:SetPoint("BOTTOMRIGHT", 0, 0)
    pick:SetFrameLevel(right:GetFrameLevel() + 5)
    Fill(pick, C.surface)
    Outline(pick, C.line)
    pick.search = Search(pick, 200, "Search songs", function() R.db.pickScroll = 0; R:UpdatePlaylistWindow() end)
    pick.search:SetPoint("TOPLEFT", 6, -6)
    pick.hint = Text(pick, 11, C.faint, BODY_FONT, "RIGHT")
    pick.hint:SetPoint("TOPRIGHT", -10, -12)
    pick.hint:SetText("+ adds to this playlist")
    local pickBox = CreateFrame("Frame", nil, pick)
    pickBox:SetPoint("TOPLEFT", 1, -38)
    pickBox:SetPoint("BOTTOMRIGHT", -1, 1)
    p.pickList = List(pickBox, 26, 9, function(row)
        row.title = Text(row, 13, C.text)
        row.title:SetPoint("LEFT", 12, 0)
        row.add = IconButton(row, "plus", 12, function(b)
            local it = b:GetParent().item
            if it then R:AddSongToSelectedPlaylist(it.index) end
        end, "Add to this playlist", 26)
        row.add:SetPoint("RIGHT", -6, 0)
        row.state = Text(row, 11, C.faint, BODY_FONT, "RIGHT")
        row.state:SetPoint("RIGHT", row.add, "LEFT", -4, 0)
        row.title:SetPoint("RIGHT", row.state, "LEFT", -6, 0)
        Wheel(row.add, row.wheel)
        row:SetScript("OnClick", function(selfRow) if selfRow.item then R:AddSongToSelectedPlaylist(selfRow.item.index) end end)
        Tip(row, nil)
    end, function(row, item)
        row.title:SetText(item.song.title or "Untitled")
        local n = 0
        local pl = R:GetSelectedPlaylist()
        for _, idx in ipairs(pl and pl.songs or {}) do if idx == item.index then n = n + 1 end end
        row.state:SetText(n > 0 and ("in playlist" .. (n > 1 and (" x" .. n) or "")) or "")
        SetColor(row.title, n > 0 and C.dim or C.text)
    end, function()
        local needle = string.lower(pick.search:GetText() or "")
        local out = {}
        for i, song in ipairs(R.songs or {}) do
            if needle == "" or string.find(string.lower(song.title or ""), needle, 1, true) then out[#out + 1] = { index = i, song = song } end
        end
        return out
    end, "pickScroll")
    p.pickList:SetPoint("TOPLEFT", 0, 0)
    p.pickList:SetPoint("BOTTOMRIGHT", 0, 0)
    pick:Hide()

    local holder = CreateFrame("Frame", nil, right)
    holder:SetPoint("TOPLEFT", 0, -46)
    holder:SetPoint("BOTTOMRIGHT", 0, 0)
    Fill(holder, C.surface)
    Outline(holder, C.line)
    p.songs = List(holder, 28, 10, function(row)
        row.num = Text(row, 11, C.faint, BODY_FONT, "RIGHT")
        row.num:SetPoint("LEFT", 6, 0); row.num:SetWidth(20)
        row.title = Text(row, 13, C.text)
        row.title:SetPoint("LEFT", 34, 0)
        row.rm = IconButton(row, "minus", 12, function(b) R:RemovePlaylistSong(b:GetParent().item.e) end, "Remove", 26)
        row.rm:SetPoint("RIGHT", -6, 0)
        row.down = IconButton(row, "down", 12, function(b) R:MovePlaylistSong(b:GetParent().item.e, 1) end, "Move down", 26)
        row.down:SetPoint("RIGHT", row.rm, "LEFT", 0, 0)
        row.up = IconButton(row, "up", 12, function(b) R:MovePlaylistSong(b:GetParent().item.e, -1) end, "Move up", 26)
        row.up:SetPoint("RIGHT", row.down, "LEFT", 0, 0)
        row.title:SetPoint("RIGHT", row.up, "LEFT", -6, 0)
        for _, b in ipairs({ row.rm, row.down, row.up }) do Wheel(b, row.wheel) end
        row:SetScript("OnClick", function(selfRow)
            if not selfRow.item then return end
            R.db.playlistEntryIndex = selfRow.item.e
            R:UpdatePlaylistWindow()
        end)
        row:SetScript("OnDoubleClick", function(selfRow) if selfRow.item then R:PlayPlaylistEntry(selfRow.item.e) end end)
        Tip(row, nil)
    end, function(row, item)
        row.num:SetText(item.e)
        row.title:SetText(item.song.title or "Untitled")
        local sel = item.e == R.db.playlistEntryIndex
        row.selected = sel
        local playing = R.db.isPlaying and R.db.playFromPlaylist and sel
        SetColor(row.title, playing and C.acc or C.text)
        if sel then row.mark:Show() end
        local fixed = item.runtime
        for _, b in ipairs({ row.rm, row.down, row.up }) do if fixed then b:Hide() else b:Show() end end
    end, function()
        local pl = R:GetSelectedPlaylist()
        local out = {}
        for e, idx in ipairs(pl and pl.songs or {}) do
            local song = R:GetSong(idx)
            if song then out[#out + 1] = { e = e, song = song, runtime = pl.runtime } end
        end
        return out
    end, "playlistSongScroll")
    p.songs:SetPoint("TOPLEFT", 1, -1)
    p.songs:SetPoint("BOTTOMRIGHT", -1, 1)
    p.songs.empty = function(row)
        row.num:SetText(""); row.rm:Hide(); row.down:Hide(); row.up:Hide()
        local pl = R:GetSelectedPlaylist()
        row.title:SetText(pl and (pl.runtime and "This song pack is empty." or "Empty. Click Add songs above.") or "Create a playlist on the left.")
        SetColor(row.title, C.faint)
    end
end

function R:UpdatePlaylistWindow()
    if not PageShown("playlists") then return end
    local p = self.mainFrame.pages.playlists
    local pl = self:GetSelectedPlaylist()
    p.head:SetText(pl and pl.name or "Playlists")
    p.headSub:SetText(pl and ((#(pl.songs or {})) .. " songs" .. (pl.runtime and "  ·  song pack" or "")) or "Make one with the box on the left")
    local fixed = not pl or pl.runtime
    p.del:SetDisabledLook(fixed)
    p.clear:SetDisabledLook(fixed)
    p.playAll:SetDisabledLook(not pl or #(pl.songs or {}) == 0)
    if fixed then p.adding = false end
    p.addBtn:SetDisabledLook(fixed)
    p.addBtn:SetLabel(p.adding and "Done" or "Add songs")
    p.addBtn:SetStyle(p.adding and "primary" or "ghost")
    if p.adding then p.pick:Show(); p.pickList:Refresh() else p.pick:Hide() end
    p.lists:Refresh()
    p.songs:Refresh()
end

-- ---------- Live sets ----------
function R:BuildLivePage(p)
    local card = CreateFrame("Frame", nil, p)
    card:SetPoint("TOPLEFT", 0, 0)
    card:SetPoint("TOPRIGHT", 0, 0)
    card:SetHeight(70)
    Fill(card, C.surface)
    Outline(card, C.line)
    card.icon = Icon(card, "live", 28)
    card.icon:SetPoint("LEFT", 16, 0)
    card.title = Text(card, 16, C.text, TITLE_FONT)
    card.title:SetPoint("TOPLEFT", 58, -16)
    card.sub = Text(card, 12, C.dim)
    card.sub:SetPoint("TOPLEFT", card.title, "BOTTOMLEFT", 0, -6)
    card.main = TextButton(card, "Open room", 96, 28, function()
        local eb = EB()
        if eb.live then eb:EndSet() else eb:GoLive() end
    end, "primary")
    card.main:SetPoint("RIGHT", -14, 0)
    card.tune = TextButton(card, "Tune in", 86, 28, function()
        local eb = EB()
        if eb.tuned then eb:TuneOut() else eb:TuneIn() end
    end, "ghost")
    card.tune:SetPoint("RIGHT", card.main, "LEFT", -8, 0)
    card.invite = TextButton(card, "Invite", 66, 28, function(b) R:ToggleInviteMenu(b) end, "ghost")
    card.invite:SetPoint("RIGHT", card.main, "LEFT", -8, 0)
    -- room name: click it (host only) to rename
    card.rename = CreateFrame("EditBox", nil, card)
    card.rename:SetFont(TITLE_FONT, 16, "")
    card.rename:SetTextColor(C.text[1], C.text[2], C.text[3])
    card.rename:SetAutoFocus(false)
    card.rename:SetMaxLetters(32)
    card.rename:SetHeight(22)
    card.rename:SetPoint("TOPLEFT", 58, -12)
    card.rename:SetWidth(220)
    Fill(card.rename, C.raised)
    card.rename:Hide()
    card.rename:SetScript("OnEnterPressed", function(selfB) EB():SetRoomName(selfB:GetText()); selfB:ClearFocus(); selfB:Hide(); R:UpdateLive() end)
    card.rename:SetScript("OnEscapePressed", function(selfB) selfB:ClearFocus(); selfB:Hide(); R:UpdateLive() end)
    card.titleHit = CreateFrame("Button", nil, card)
    card.titleHit:SetPoint("TOPLEFT", card.title, "TOPLEFT")
    card.titleHit:SetPoint("BOTTOMRIGHT", card.title, "BOTTOMRIGHT")
    function card.titleHit:Hover(h) if EB().live then SetColor(card.title, h and C.acc or C.text) end end
    Tip(card.titleHit, function() return EB().live and "Click to rename your room" or nil end)
    card.titleHit:SetScript("OnClick", function()
        if not EB().live then return end
        card.rename:SetText(EB():RoomName())
        card.rename:Show()
        card.rename:SetFocus()
        card.rename:HighlightText()
    end)
    card.pass = TextButton(card, "Pass host", 82, 28, function(b) R:TogglePassMenu(b) end, "ghost")
    card.pass:SetPoint("RIGHT", card.invite, "LEFT", -6, 0)
    -- other live sets, as pills under the title
    card.sets = {}
    for i = 1, 3 do
        local pill = Pill(card, "Room", function(b) local eb = EB(); if b.full then eb.focus = b.full; eb:TuneIn(b.full) end end)
        pill:Hide()
        card.sets[i] = pill
    end
    card.title:SetPoint("RIGHT", card, "RIGHT", -290, 0)
    card.sub:SetPoint("RIGHT", card, "RIGHT", -290, 0)
    p.card = card
    local pulse = 0
    card:SetScript("OnUpdate", function(_, el)
        pulse = pulse + el
        local eb = EB()
        if eb and (eb.live or eb.tuned) then card.icon:SetAlpha(0.65 + 0.35 * math.sin(pulse * 4)) else card.icon:SetAlpha(1) end
    end)

    local colW = (W - 36 - 14) / 2
    -- request line (left)
    p.qHead = Eyebrow(p, "Request line")
    p.qHead:SetPoint("TOPLEFT", 0, -88)
    p.next = Pill(p, "Play next", function() if not EB():PlayTopRequest() then R:Print("No requests waiting.") end end)
    p.next:SetPoint("TOPLEFT", colW - 150, -82)
    p.open = Pill(p, "Closed", function() R.db.eb.open = not R.db.eb.open; EB():BroadcastQueue() end)
    p.open:SetPoint("LEFT", p.next, "RIGHT", 6, 0)
    local qh = CreateFrame("Frame", nil, p)
    qh:SetPoint("TOPLEFT", 0, -108)
    qh:SetPoint("BOTTOMLEFT", 0, 22)
    qh:SetWidth(colW)
    Fill(qh, C.surface)
    Outline(qh, C.line)
    p.q = List(qh, 28, 7, function(row)
        row.n = Text(row, 11, C.faint, BODY_FONT, "RIGHT")
        row.n:SetPoint("LEFT", 4, 0); row.n:SetWidth(16)
        row.title = Text(row, 13, C.text)
        row.title:SetPoint("TOPLEFT", 28, -3)
        row.who = Text(row, 10, C.faint)
        row.who:SetPoint("BOTTOMLEFT", 28, 3)
        row.meta = Text(row, 11, C.dim, BODY_FONT, "RIGHT")
        row.meta:SetPoint("RIGHT", -10, 0)
        row.title:SetPoint("RIGHT", row.meta, "LEFT", -6, 0)
        row:SetScript("OnClick", function(selfRow, mouse)
            local eb = EB()
            if not selfRow.item then return end
            if eb.live then
                if mouse == "RightButton" then eb:Decline(selfRow.item.key, IsShiftKeyDown())
                else
                    local index = eb:IndexOfKey(selfRow.item.key)
                    if index then R:Play(index) end
                end
            else
                eb:Request(selfRow.item.key)
            end
        end)
        Tip(row, function() return EB().live and "Click: play now   Right-click: decline   Shift+right-click: never play" or "Click to vote" end)
    end, function(row, item, n)
        local eb = EB()
        local age = eb.Now() - item.at
        row.n:SetText(n)
        row.title:SetText(eb:TitleOf(item.key))
        row.who:SetText(item.owner or "")
        local late = age >= eb.OVERDUE
        local wait = age < 60 and "now" or (math.floor(age / 60) .. "m")
        row.meta:SetText((late and "|cffffb030" or "") .. item.votes .. (item.votes == 1 and " vote" or " votes") .. "  ·  " .. wait .. (late and "|r" or ""))
    end, function()
        local eb = EB()
        if eb.live then eb:SortQueue(); return eb.queue end
        return eb:RemoteList()
    end, "liveQueueScroll")
    p.q:SetPoint("TOPLEFT", 1, -1)
    p.q:SetPoint("BOTTOMRIGHT", -1, 1)
    p.q.empty = function(row)
        row.n:SetText(""); row.who:SetText(""); row.meta:SetText("")
        local eb = EB()
        row.title:SetText((eb.live or eb.tuned or eb:CurrentDJ()) and "No requests yet." or "Requests show up here during a set.")
        SetColor(row.title, C.faint)
    end
    p.qFoot = Text(p, 10, C.faint)
    p.qFoot:SetPoint("BOTTOMLEFT", 0, 4)
    p.qFoot:SetText("5 requests each  ·  3+ min waiting goes first, then votes")

    -- right column: room chat or requests
    p.rHead = Eyebrow(p, "")
    p.rHead:SetPoint("TOPLEFT", colW + 14, -88)
    p.chatPill = Pill(p, "Room chat", function() R.db.liveRight = "chat"; R:UpdateLive() end)
    p.chatPill:SetPoint("TOPLEFT", colW + 14, -82)
    p.reqPill = Pill(p, "Request a song", function() R.db.liveRight = "requests"; R:UpdateLive() end)
    p.reqPill:SetPoint("LEFT", p.chatPill, "RIGHT", 4, 0)
    p.rSearch = Search(p, colW, "Search", function() R.db.liveLibScroll = 0; R:UpdateLive() end)
    p.rSearch:SetPoint("TOPLEFT", colW + 14, -104)
    local rh = CreateFrame("Frame", nil, p)
    p.rh = rh
    rh:SetPoint("TOPLEFT", colW + 14, -136)
    rh:SetPoint("BOTTOMRIGHT", 0, 22)
    Fill(rh, C.surface)
    Outline(rh, C.line)
    p.r = List(rh, 26, 6, function(row)
        row.title = Text(row, 13, C.text)
        row.title:SetPoint("LEFT", 12, 0)
        row.state = Text(row, 11, C.faint, BODY_FONT, "RIGHT")
        row.state:SetPoint("RIGHT", -10, 0)
        row.title:SetPoint("RIGHT", row.state, "LEFT", -6, 0)
        row:SetScript("OnClick", function(selfRow) if selfRow.item then EB():Request(EB().KeyOf(selfRow.item)) end end)
        Tip(row, nil)
    end, function(row, song)
        local eb = EB()
        local key = eb.KeyOf(song)
        row.title:SetText(song.title or key)
        if R.db.eb.blocked[key] then row.state:SetText("blocked"); SetColor(row.state, C.faint)
        elseif eb:Requested(key) then row.state:SetText("requested"); SetColor(row.state, C.acc)
        else row.state:SetText("request"); SetColor(row.state, C.dim) end
    end, function()
        local needle = string.lower(p.rSearch:GetText() or "")
        local out = {}
        for _, song in ipairs(R.songs or {}) do
            if needle == "" or string.find(string.lower(song.title or ""), needle, 1, true) then out[#out + 1] = song end
        end
        return out
    end, "liveLibScroll")
    p.r:SetPoint("TOPLEFT", 1, -1)
    p.r:SetPoint("BOTTOMRIGHT", -1, 1)
    p.rFoot = Text(p, 10, C.faint, BODY_FONT, "RIGHT")
    p.rFoot:SetPoint("BOTTOMRIGHT", 0, 4)

    -- room chat: parchment-style lines, class-colored names, one input line
    local ch = CreateFrame("Frame", nil, p)
    p.chat = ch
    ch:SetPoint("TOPLEFT", colW + 14, -108)
    ch:SetPoint("BOTTOMRIGHT", 0, 22)
    Fill(ch, C.surface)
    Outline(ch, C.line)
    ch.lines = {}
    ch.offset = 0
    local LINES = 8
    for i = 1, LINES do
        local fs = Text(ch, 12, C.text)
        fs:SetPoint("TOPLEFT", 8, -6 - (i - 1) * 19)
        fs:SetPoint("RIGHT", ch, "RIGHT", -8, 0)
        ch.lines[i] = fs
    end
    Wheel(ch, function(d) ch.offset = math.max(0, ch.offset + d); R:UpdateLive() end)
    ch.input = CreateFrame("EditBox", nil, ch)
    ch.input:SetHeight(24)
    ch.input:SetPoint("BOTTOMLEFT", 1, 1)
    ch.input:SetPoint("BOTTOMRIGHT", -1, 1)
    ch.input:SetFont(BODY_FONT, 13, "")
    ch.input:SetTextColor(C.text[1], C.text[2], C.text[3])
    ch.input:SetTextInsets(8, 8, 0, 0)
    ch.input:SetAutoFocus(false)
    ch.input:SetMaxLetters(200)
    Fill(ch.input, C.raised)
    ch.input.hint = Text(ch.input, 12, C.faint)
    ch.input.hint:SetPoint("LEFT", 8, 0)
    ch.input.hint:SetText("Say something to the room")
    ch.input:SetScript("OnTextChanged", function(selfB) if (selfB:GetText() or "") == "" then selfB.hint:Show() else selfB.hint:Hide() end end)
    ch.input:SetScript("OnEnterPressed", function(selfB) EB():SendChat(selfB:GetText()); selfB:SetText(""); ch.offset = 0 end)
    ch.input:SetScript("OnEscapePressed", function(selfB) selfB:ClearFocus() end)
end

function R:UpdateChat()
    if not PageShown("live") then return end
    local p = self.mainFrame.pages.live
    local ch = p.chat
    local eb = EB()
    local log = eb.chatLog
    local n = #ch.lines
    ch.offset = math.min(ch.offset, math.max(0, #log - n))
    local first = math.max(1, #log - n + 1 - ch.offset)
    for i, fs in ipairs(ch.lines) do
        local e = log[first + i - 1]
        if e and (first + i - 1) <= #log - ch.offset then
            if e.system then fs:SetText("|cff8c826f" .. e.text .. "|r")
            else fs:SetText(eb:ColorName(e.who) .. "|cffbdb6a6:|r " .. e.text) end
        else
            fs:SetText("")
        end
    end
    if #log == 0 then ch.lines[1]:SetText(eb:RoomHost() and "|cff8c826fNo messages yet.|r" or "|cff8c826fOpen a room or tune into one to chat.|r") end
end

function R:UpdateLive()
    local eb = EB()
    if not eb or not self.db then return end
    local dj = eb:CurrentDJ()
    local f = self.mainFrame
    if f then
        local someone = eb.live or eb.tuned or dj
        if someone then f.tabs.live.dot:Show() else f.tabs.live.dot:Hide() end
        f.headLive:SetText(eb.live and ("ON AIR  ·  " .. (eb.listenerCount or 0) .. " listening") or (eb.tuned and "TUNED IN" or (dj and (string.upper(dj.name) .. " IS LIVE") or "")))
    end
    if self.UpdateMiniWindow then self:UpdateMiniWindow() end
    if self.UpdateNowPage then self:UpdateNowPage() end
    if not PageShown("live") then return end
    local p = f.pages.live
    local card = p.card
    local song = self.db.isPlaying and self:GetCurrentSong()
    if eb.live then
        card.icon:SetVertexColor(C.live[1], C.live[2], C.live[3])
        card.title:SetText(eb:RoomName())
        card.sub:SetText("On air" .. (song and ("  ·  " .. song.title) or "") .. "  ·  " .. (eb.listenerCount or 0) .. " tuned in  ·  requests " .. (self.db.eb.open and "open" or "closed") .. (song and "" or "  ·  play a song to start"))
    elseif eb.tuned then
        local d = eb.djs[eb.tuned]
        card.icon:SetVertexColor(C.acc2[1], C.acc2[2], C.acc2[3])
        card.title:SetText((d and d.room or (eb.Short(eb.tuned) .. "'s Room")) .. (d and d.key ~= "" and ("  ·  " .. eb:TitleOf(d.key)) or ""))
        local j = eb:JoiningIn()
        card.sub:SetText(eb.missing and "|cffffb030You don't have this song. Get the latest GuildRadioFM from the DJ.|r"
            or (j and string.format("Joining in %ds, in time with everyone", math.ceil(j)))
            or (eb.waiting and "You'll join at the next song" or ((d and d.count or 0) .. " tuned in  ·  in sync")))
    elseif dj then
        dj = eb:FocusDJ() or dj
        card.icon:SetVertexColor(C.live[1], C.live[2], C.live[3])
        local n = #eb:LiveSets()
        card.title:SetText(n > 1 and (n .. " rooms open, pick one") or ((dj.room or dj.name) .. (dj.key ~= "" and ("  ·  " .. eb:TitleOf(dj.key)) or "")))
        card.sub:SetText("Hosted by " .. dj.name .. "  ·  " .. (dj.count or 0) .. " tuned in. Tune in to hear it in sync.")
    else
        card.icon:SetVertexColor(C.faint[1], C.faint[2], C.faint[3])
        card.title:SetText("No rooms open")
        card.sub:SetText("Open a room, invite guildmates, and everyone in it hears the same moment.")
    end
    -- several sets live: show them as pills (not while you're the host)
    local sets = eb:LiveSets()
    local px = 58
    for i, pill in ipairs(card.sets) do
        local d = sets[i]
        if d and not eb.live and #sets > 1 then
            pill.full = d.full
            pill:SetLabel((d.room or d.name) .. "  ·  " .. (d.count or 0))
            pill:SetWidth(pill.label:GetStringWidth() + 22)
            pill:SetOn(eb.tuned == d.full)
            pill:ClearAllPoints()
            pill:SetPoint("TOPLEFT", card, "TOPLEFT", px, -40)
            px = px + pill:GetWidth() + 4
            pill:Show()
        else
            pill:Hide()
        end
    end
    if not eb.live and #sets > 1 then card.sub:Hide() else card.sub:Show() end
    if eb.live then
        card.pass:Show()
        card.pass:SetLabel(eb.offerTo and ("Asking " .. eb.offerTo) or "Pass host")
        card.pass:SetWidth(eb.offerTo and 110 or 82)
        card.pass:SetDisabledLook(#eb:ListenerNames() == 0 and not eb.offerTo)
    else
        card.pass:Hide()
        if self.passMenu then self.passMenu:Hide() end
    end
    card.main:SetLabel(eb.live and "Close room" or "Open room")
    card.main:SetStyle(eb.live and "danger" or "primary")
    card.tune:SetLabel(eb.tuned and "Tune out" or "Tune in")
    card.invite:Show()
    card.invite:ClearAllPoints()
    if eb.live then card.tune:Hide(); card.invite:SetPoint("RIGHT", card.main, "LEFT", -8, 0)
    else
        card.tune:Show()
        card.invite:SetPoint("RIGHT", card.tune, "LEFT", -6, 0)
        card.tune:SetDisabledLook(not (dj or eb.tuned))
    end
    if eb.live then p.next:Show(); p.open:Show(); p.open:SetLabel(self.db.eb.open and "Open" or "Closed"); p.open:SetOn(self.db.eb.open)
    else p.next:Hide(); p.open:Hide() end
    p.q:Refresh()
    local view = self.db.liveRight or "chat"
    p.chatPill:SetOn(view == "chat")
    p.reqPill:SetOn(view == "requests")
    if view == "chat" then
        p.chat:Show(); p.rSearch:Hide(); p.rh:Hide()
        p.rFoot:SetText("Only people in this room see it")
        self:UpdateChat()
    else
        p.chat:Hide(); p.rSearch:Show(); p.rh:Show()
        p.r:Refresh()
        p.rFoot:SetText(eb.live and "Click to add to your line" or ((eb.tuned or dj) and "Click to request" or ""))
    end
end

-- pick a listener to take over the set
function R:TogglePassMenu(anchor)
    local eb = EB()
    if eb.offerTo then return end
    if not self.passMenu then
        local m = CreateFrame("Frame", nil, self.mainFrame)
        m:SetFrameLevel(self.mainFrame:GetFrameLevel() + 20)
        m:SetWidth(170)
        Fill(m, C.bg)
        Outline(m, C.acc, 0.35)
        m:EnableMouse(true)
        m.head = Eyebrow(m, "Make host")
        m.head:SetPoint("TOPLEFT", 10, -8)
        m.rows = {}
        for i = 1, 8 do
            local r = CreateFrame("Button", nil, m)
            r:SetHeight(24)
            r:SetPoint("TOPLEFT", 4, -22 - (i - 1) * 24)
            r:SetPoint("TOPRIGHT", -4, -22 - (i - 1) * 24)
            r.hl = Fill(r, C.text, 0)
            r.label = Text(r, 13, C.text)
            r.label:SetPoint("LEFT", 8, 0)
            function r:Hover(h) self.hl:SetAlpha(h and 0.06 or 0) end
            Tip(r, nil)
            r:SetScript("OnClick", function(selfR) m:Hide(); EB():OfferHost(selfR.name) end)
            m.rows[i] = r
        end
        self.passMenu = m
    end
    local m = self.passMenu
    if m:IsShown() then m:Hide(); return end
    local names = eb:ListenerNames()
    for i, r in ipairs(m.rows) do
        if names[i] then r.name = names[i]; r.label:SetText(names[i]); r:Show() else r:Hide() end
    end
    m:SetHeight(30 + math.min(#names, 8) * 24)
    m:ClearAllPoints()
    m:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
    m:Show()
end

-- invite guildmates to your room: whole guild, or pick people (online now)
function R:ToggleInviteMenu(anchor)
    local eb = EB()
    if not self.inviteMenu then
        local m = CreateFrame("Frame", nil, self.mainFrame)
        m:SetFrameLevel(self.mainFrame:GetFrameLevel() + 20)
        m:SetWidth(260)
        Fill(m, C.bg)
        Outline(m, C.acc, 0.35)
        m:EnableMouse(true)
        m.head = Eyebrow(m, "Invite to your room")
        m.head:SetPoint("TOPLEFT", 10, -8)
        m.rows = {}
        m.offset = 0
        for i = 1, 11 do
            local r = CreateFrame("Button", nil, m)
            r:SetHeight(24)
            r:SetPoint("TOPLEFT", 4, -22 - (i - 1) * 24)
            r:SetPoint("TOPRIGHT", -4, -22 - (i - 1) * 24)
            r.hl = Fill(r, C.text, 0)
            r.label = Text(r, 13, C.text)
            r.label:SetPoint("LEFT", 8, 0)
            r.meta = Text(r, 10, C.faint, BODY_FONT, "RIGHT")
            r.meta:SetPoint("RIGHT", -8, 0)
            r.label:SetPoint("RIGHT", r.meta, "LEFT", -6, 0)
            function r:Hover(h) self.hl:SetAlpha(h and 0.06 or 0) end
            Tip(r, nil)
            r:SetScript("OnClick", function(selfR)
                if selfR.everyone then EB():Announce(); if not EB().live then EB():GoLive(); EB():Announce() end; m:Hide()
                elseif selfR.full then EB():InviteOne(selfR.full); R:FillInviteMenu() end
            end)
            Wheel(r, function(d) m.offset = math.max(0, m.offset - d); R:FillInviteMenu() end)
            m.rows[i] = r
        end
        Wheel(m, function(d) m.offset = math.max(0, m.offset - d); R:FillInviteMenu() end)
        self.inviteMenu = m
    end
    local m = self.inviteMenu
    if m:IsShown() then m:Hide(); return end
    if self.passMenu then self.passMenu:Hide() end
    eb:FindPeers()
    m.offset = 0
    m:ClearAllPoints()
    m:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
    m:Show()
    self:FillInviteMenu()
    if C_Timer and C_Timer.After then C_Timer.After(1.5, function() if m:IsShown() then R:FillInviteMenu() end end) end
end

function R:FillInviteMenu()
    local m = self.inviteMenu
    if not m or not m:IsShown() then return end
    local eb = EB()
    local mates = eb:OnlineGuildmates()
    local items = { { everyone = true } }
    for _, g in ipairs(mates) do items[#items + 1] = g end
    m.offset = math.min(m.offset, math.max(0, #items - #m.rows))
    local shown = 0
    for i, r in ipairs(m.rows) do
        local it = items[i + m.offset]
        r.everyone, r.full = nil, nil
        if it then
            shown = shown + 1
            if it.everyone then
                r.everyone = true
                r.label:SetText("Whole guild")
                SetColor(r.label, C.acc)
                r.meta:SetText(#mates .. " online  ·  posts in guild chat")
            else
                r.full = it.full
                local invited = eb.invited[it.name] and (eb.Now() - eb.invited[it.name] < 120)
                r.label:SetText(it.name)
                SetColor(r.label, invited and C.faint or C.text)
                r.meta:SetText(invited and "invited" or (it.level .. "  ·  " .. it.zone .. (it.hasRadio and "  ·  has radio" or "")))
            end
            r:Show()
        else
            r:Hide()
        end
    end
    if #mates == 0 then
        m.rows[2]:Show()
        m.rows[2].label:SetText(IsInGuild() and "Nobody else is online" or "Join a guild to invite people")
        SetColor(m.rows[2].label, C.faint)
        m.rows[2].meta:SetText("")
        shown = 2
    end
    m:SetHeight(30 + shown * 24)
end

-- ---------- Settings ----------
function R:BuildSettingsPage(p)
    local rows = {
        { "Shuffle", function() return R.db.shuffle end, function() R:ToggleShuffle() end },
        { "Repeat the current song", function() return R.db.repeatSong end, function() R:ToggleRepeat() end },
        { "Play the next song automatically", function() return R.db.autoNext end, function() R:ToggleAutoNext() end },
        { "Mute", function() return R.db.muted end, function() R:ToggleMute() end },
        { "Minimap icon", function() return not (R.db.minimap and R.db.minimap.hide) end, function(on) R:SetMinimapButtonShown(on) end },
        { "Keep playing when tabbed out", function() return R.db.bgSound ~= false end, function(on) R.db.bgSound = on; R:ApplyBackgroundSound(); R:RefreshAll() end },
        { "Room chat in the chat window", function() return R.db.eb.chatInChat ~= false end, function(on) R.db.eb.chatInChat = on; R:RefreshAll() end },
        { "Mini player", function() return R.miniFrame and R.miniFrame:IsShown() end, function(on) R:ShowMini(on) end },
        { "Now-playing pop-up", function() return R.db.toast ~= false end, function(on) R.db.toast = on; R:RefreshAll() end },
        { "Live invites from the guild", function() return R.db.invites ~= false end, function(on) R.db.invites = on; R:RefreshAll() end },
    }
    p.switches = {}
    local colW = (W - 36 - 24) / 2
    for i, r in ipairs(rows) do
        local col = (i - 1) % 2
        local line = math.floor((i - 1) / 2)
        local holder = CreateFrame("Frame", nil, p)
        holder:SetSize(colW, 34)
        holder:SetPoint("TOPLEFT", col * (colW + 24), -line * 38)
        Fill(holder, C.surface)
        Outline(holder, C.line)
        local label = Text(holder, 13, C.text)
        label:SetPoint("LEFT", 14, 0)
        label:SetText(r[1])
        local s = Switch(holder, function(on) r[3](on) end)
        s:SetPoint("RIGHT", -12, 0)
        s.get = r[2]
        p.switches[i] = s
    end
    local y = -math.ceil(#rows / 2) * 38 - 6
    p.sizeLabel = Eyebrow(p, "Size")
    p.sizeLabel:SetPoint("TOPLEFT", 0, y - 4)
    p.size = Slider(p, 160, function(v) R:SetFrameScale(R.mainFrame, "scale", 0.5 + v / 100 * 0.9) end)
    p.size:SetPoint("TOPLEFT", 70, y - 2)
    p.sizeText = Text(p, 11, C.dim)
    p.sizeText:SetPoint("LEFT", p.size, "RIGHT", 10, 0)
    p.bgLabel = Eyebrow(p, "Background")
    p.bgLabel:SetPoint("TOPLEFT", 296, y - 4)
    p.bgPills = {}
    local px = 370
    for _, b in ipairs(BACKDROPS) do
        local pill = Pill(p, b.label, function() R.db.backdrop = b.key; R:ApplyBackdrop(); R:UpdateSettingsWindow() end)
        pill:SetPoint("TOPLEFT", px, y + 1)
        px = px + pill:GetWidth() + 4
        pill.key = b.key
        p.bgPills[#p.bgPills + 1] = pill
    end
    y = y - 30
    p.volLabel = Eyebrow(p, "Volume")
    p.volLabel:SetPoint("TOPLEFT", 0, y - 4)
    p.volume = Slider(p, 260, function(v) R.suppressVolumeUpdate = true; R:SetVolume(v); R.suppressVolumeUpdate = false end)
    p.volume:SetPoint("TOPLEFT", 70, y - 2)
    p.volText = Text(p, 11, C.dim)
    p.volText:SetPoint("LEFT", p.volume, "RIGHT", 10, 0)
    p.volNote = Text(p, 11, C.faint)
    p.volNote:SetPoint("LEFT", p.volText, "RIGHT", 14, 0)
    p.volNote:SetText("uses WoW's Dialog channel")

    p.addHead = Eyebrow(p, "Adding songs")
    p.addHead:SetPoint("TOPLEFT", 0, y - 38)
    p.add = Text(p, 12, C.dim)
    p.add:SetWordWrap(true)
    p.add:SetJustifyV("TOP")
    p.add:SetPoint("TOPLEFT", 0, y - 54)
    p.add:SetPoint("RIGHT", p, "RIGHT", 0, 0)
    p.add:SetSpacing(3)
    p.add:SetText("Put MP3s in GuildRadioFM\\Songs, list them in SongList.lua (or use the Song Importer), then /reload. Rooms need everyone on the same songs: share one GuildRadioFM zip with the guild.")

    p.credits = Text(p, 11, C.faint)
    p.credits:SetPoint("BOTTOMLEFT", 0, 0)
    p.credits:SetText("GuildRadioFM by Nez  ·  live sets by Noyze Komplaynt  ·  v" .. tostring(R.version))
end

function R:UpdateSettingsWindow()
    if not PageShown("settings") then return end
    local p = self.mainFrame.pages.settings
    for _, s in ipairs(p.switches) do s:SetOn(s.get() and true or false) end
    if not p.size.dragging then p.size:SetValue(((self.db.scale or 0.8) - 0.5) / 0.9 * 100) end
    p.sizeText:SetText(math.floor((self.db.scale or 0.8) * 100 + 0.5) .. "%")
    for _, pill in ipairs(p.bgPills) do pill:SetOn((self.db.backdrop or "kalimdor") == pill.key) end
    if not p.volume.dragging then p.volume:SetValue(self.db.muted and 0 or self.db.volume) end
    p.volText:SetText(self.db.muted and "muted" or (tostring(self.db.volume) .. "%"))
end

function R:UpdateMainWindow()
    self:UpdateLive()
end

-- ---------- mini player ----------
function R:CreateMiniWindow()
    if self.miniFrame then return end
    local m = CreateFrame("Frame", "GuildRadioFMMiniFrame", UIParent)
    self.miniFrame = m
    m:SetSize(300, 52)
    m:SetFrameStrata("MEDIUM")
    m:SetClampedToScreen(true)
    m:SetMovable(true)
    m:EnableMouse(true)
    m:RegisterForDrag("LeftButton")
    m:SetScript("OnDragStart", m.StartMoving)
    m:SetScript("OnDragStop", function(selfM) selfM:StopMovingOrSizing(); R:SaveWindow(selfM, R.db.miniWindow) end)
    local w = self.db.miniWindow or {}
    m:SetPoint(w.point or "CENTER", UIParent, w.relativePoint or "CENTER", w.x or 0, w.y or -180)
    Fill(m, C.bg)
    Outline(m, C.line)
    m.icon = m:CreateTexture(nil, "ARTWORK")
    m.icon:SetTexture(EMBLEM)
    m.icon:SetSize(32, 32)
    m.icon:SetPoint("LEFT", 10, 1)
    m.play = IconButton(m, "play", 14, function() if R.db.isPlaying then R:Stop() else R:Play() end end, nil, 26)
    m.next = IconButton(m, "next", 12, function() R:Next() end, "Next", 24)
    m.close = IconButton(m, "close", 10, function() R:ShowMini(false) end, nil, 20)
    m.close:SetPoint("TOPRIGHT", -2, -2)
    m.close:SetAlpha(0)
    m.open = IconButton(m, "up", 10, function() R:ShowTab(R.db.tab or "now") end, "Open the full player", 20)
    m.open:SetPoint("TOPRIGHT", m.close, "TOPLEFT", 0, 0)
    m.next:SetPoint("RIGHT", -44, -1)
    m.play:SetPoint("RIGHT", m.next, "LEFT", -2, 0)
    m.eyebrow = Text(m, 9, C.faint)
    m.eyebrow:SetPoint("TOPLEFT", 50, -10)
    m.title = Text(m, 13, C.acc, TITLE_FONT)
    m.title:SetPoint("TOPLEFT", 50, -23)
    m.title:SetPoint("RIGHT", m.play, "LEFT", -6, 0)
    m.eyebrow:SetPoint("RIGHT", m.play, "LEFT", -6, 0)
    m.barFill = Tex(m, "OVERLAY", C.acc)
    m.barFill:SetPoint("BOTTOMLEFT", 0, 0)
    m.barFill:SetHeight(2)
    m:SetScript("OnMouseUp", function(_, b) if b == "RightButton" then R:ToggleMainWindow() end end)
    -- grab it anywhere, buttons included; the close button only shows while the mouse is over the player
    for _, b in ipairs({ m.play, m.next, m.close, m.open }) do DragThrough(b, m, function() return R.db.miniWindow end) end
    local hoverAcc = 0
    m.hoverWatch = CreateFrame("Frame", nil, m)
    m.hoverWatch:SetScript("OnUpdate", function(_, el)
        hoverAcc = hoverAcc + el
        if hoverAcc < 0.05 then return end
        hoverAcc = 0
        local over = m:IsMouseOver()
        m.close:SetAlpha(over and 1 or 0)
        m.open:SetAlpha(over and 1 or 0.5)
    end)
    local acc = 0
    m:SetScript("OnUpdate", function(_, el) acc = acc + el; if acc > 0.1 then acc = 0; R:UpdateProgress() end end)
    m.grip = self:AddScaleGrip(m, "miniScale")
    m.grip:SetSize(12, 12)
    m:SetScale(self.db.miniScale or 0.9)
    m:Hide()
end

function R:ShowMini(on)
    self:CreateMiniWindow()
    self.db.miniShown = on and true or false
    if on then self.miniFrame:Show() else self.miniFrame:Hide() end
    self:UpdateMiniWindow()
    if self.UpdateSettingsWindow then self:UpdateSettingsWindow() end
end

function R:ToggleMiniWindow()
    self:CreateMiniWindow()
    self:ShowMini(not self.miniFrame:IsShown())
end

function R:UpdateMiniWindow()
    local m = self.miniFrame
    if not m or not m:IsShown() then return end
    local song = self:GetCurrentSong()
    local eyebrow, ec = self:StatusLine()
    m.eyebrow:SetText(eyebrow)
    SetColor(m.eyebrow, ec)
    m.title:SetText(song and song.title or "No songs")
    m.play.icon:SetIcon(self.db.isPlaying and "stop" or "play")
end

-- ---------- now-playing toast + live invite card ----------
local function Card(name, width)
    local t = CreateFrame("Frame", name, UIParent)
    t:SetSize(width, 52)
    t:SetFrameStrata("DIALOG")
    t:SetPoint("TOP", UIParent, "TOP", 0, -110)
    Fill(t, C.bg)
    Outline(t, C.line)
    t.accent = Tex(t, "ARTWORK", C.acc)
    t.accent:SetPoint("TOPLEFT"); t.accent:SetPoint("BOTTOMLEFT"); t.accent:SetWidth(2)
    t.icon = t:CreateTexture(nil, "ARTWORK")
    t.icon:SetTexture(EMBLEM)
    t.icon:SetSize(32, 32)
    t.icon:SetPoint("LEFT", 12, 0)
    t.eyebrow = Text(t, 9, C.faint)
    t.eyebrow:SetPoint("TOPLEFT", 52, -11)
    t.title = Text(t, 14, C.text)
    t.title:SetPoint("TOPLEFT", 52, -24)
    t.title:SetPoint("RIGHT", -12, 0)
    t:SetAlpha(0)
    t:Hide()
    t:SetScript("OnUpdate", function(selfT, el)
        selfT.life = (selfT.life or 0) + el
        local life, hold = selfT.life, selfT.hold or 3
        local a = life < 0.25 and life / 0.25 or (life > hold and math.max(0, 1 - (life - hold) / 0.4) or 1)
        selfT:SetAlpha(a)
        if life > hold + 0.4 then selfT:Hide() end
    end)
    return t
end

function R:CreateToast()
    if self.toastFrame then return end
    self.toastFrame = Card("GuildRadioFMToastFrame", 300)
end

function R:ShowNowPlayingToast(song)
    if self.db and self.db.toast == false then return end
    if self.inviteFrame and self.inviteFrame:IsShown() then return end
    self:CreateToast()
    local t = self.toastFrame
    local eyebrow, ec = self:StatusLine()
    t.eyebrow:SetText(eyebrow == "STOPPED" and "NOW PLAYING" or eyebrow)
    SetColor(t.eyebrow, ec)
    t.title:SetText(song and song.title or self:GetCurrentTitle())
    t.life, t.hold = 0, 3
    t:Show()
end

function R:ShowInvite(name, room)
    if self.db and self.db.invites == false then return end
    if not self.inviteFrame then
        local t = Card("GuildRadioFMInviteFrame", 340)
        t.accent:SetVertexColor(C.live[1], C.live[2], C.live[3])
        t:EnableMouse(true)
        t.btn = TextButton(t, "Tune in", 74, 26, function() t:Hide(); EB():TuneIn() end, "primary")
        t.btn:SetPoint("RIGHT", -30, 0)
        t.x = IconButton(t, "close", 10, function() t:Hide() end, nil, 20)
        t.x:SetPoint("RIGHT", -6, 0)
        t.title:SetPoint("RIGHT", t.btn, "LEFT", -8, 0)
        self.inviteFrame = t
    end
    local t = self.inviteFrame
    t.eyebrow:SetText("LIVE ON GUILDRADIOFM")
    SetColor(t.eyebrow, C.live)
    t.title:SetText(name .. " invited you to " .. (room or (name .. "'s Room")))
    t.life, t.hold = 0, 14
    t:Show()
end

function R:ShowHandoff(from)
    if not self.handoffFrame then
        local t = Card("GuildRadioFMHandoffFrame", 380)
        t:EnableMouse(true)
        t.yes = TextButton(t, "Take over", 80, 26, function() t:Hide(); EB():AnswerHandoff(true) end, "primary")
        t.no = TextButton(t, "No thanks", 76, 26, function() t:Hide(); EB():AnswerHandoff(false) end, "ghost")
        t.no:SetPoint("RIGHT", -10, 0)
        t.yes:SetPoint("RIGHT", t.no, "LEFT", -6, 0)
        t.title:SetPoint("RIGHT", t.yes, "LEFT", -8, 0)
        self.handoffFrame = t
    end
    local t = self.handoffFrame
    t.eyebrow:SetText("HOST THE ROOM")
    SetColor(t.eyebrow, C.acc)
    t.title:SetText(from .. " wants you to host")
    t.life, t.hold = 0, 25
    t:Show()
end

-- ---------- minimap button ----------
function R:GetMinimapAngle()
    self.db.minimap = self.db.minimap or { hide = false, angle = 225 }
    return tonumber(self.db.minimap.angle) or 225
end

function R:PositionMinimapButton()
    if not self.minimapButton or not Minimap then return end
    local angle = math.rad(self:GetMinimapAngle())
    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * 80, math.sin(angle) * 80)
end

function R:UpdateMinimapButton()
    if not self.minimapButton or not self.db then return end
    self.db.minimap = self.db.minimap or { hide = false, angle = 225 }
    if self.db.minimap.hide then self.minimapButton:Hide() else self.minimapButton:Show(); self:PositionMinimapButton() end
    local eb = EB()
    if self.minimapButton.dot then
        if eb and (eb.live or eb.tuned or eb:CurrentDJ()) then self.minimapButton.dot:Show() else self.minimapButton.dot:Hide() end
    end
end

function R:SetMinimapButtonShown(shown)
    self.db.minimap = self.db.minimap or { hide = false, angle = 225 }
    self.db.minimap.hide = not shown
    self:UpdateMinimapButton()
    self:UpdateSettingsWindow()
end

function R:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end
    self.db.minimap = self.db.minimap or { hide = false, angle = 225 }
    local b = CreateFrame("Button", "GuildRadioFMMinimapButton", Minimap)
    self.minimapButton = b
    b:SetSize(32, 32)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetTexture(ICON)
    b.icon:SetSize(30, 30)
    b.icon:SetPoint("CENTER")
    b.dot = Tex(b, "OVERLAY", C.live)
    b.dot:SetSize(7, 7)
    b.dot:SetPoint("TOPRIGHT", -3, -3)
    b.dot:Hide()
    b:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then R:ToggleMiniWindow() else R:ToggleMainWindow() end
    end)
    b:SetScript("OnEnter", function(selfB)
        if not GameTooltip then return end
        GameTooltip:SetOwner(selfB, "ANCHOR_LEFT")
        GameTooltip:SetText("GuildRadioFM", C.acc[1], C.acc[2], C.acc[3])
        local song = R.db.isPlaying and R:GetCurrentSong()
        if song then GameTooltip:AddLine(song.title, 1, 1, 1) end
        GameTooltip:AddLine("Click: open   Right-click: mini player   Drag: move", 0.6, 0.62, 0.66)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    b:SetScript("OnDragStart", function() b.isDragging = true end)
    b:SetScript("OnDragStop", function() b.isDragging = false end)
    b:SetScript("OnUpdate", function()
        if not b.isDragging or not Minimap then return end
        local scale = Minimap:GetEffectiveScale()
        local cx, cy = GetCursorPosition()
        local mx, my = Minimap:GetCenter()
        local dx, dy = cx / scale - mx, cy / scale - my
        R.db.minimap.angle = math.deg(math.atan2 and math.atan2(dy, dx) or math.atan(dy, dx))
        R:PositionMinimapButton()
    end)
    self:UpdateMinimapButton()
    if self.db.miniShown then self:ShowMini(true) end
end

-- ---------- Interface Options entry ----------
function R:UpdateOptionsPanel() end

function R:CreateOptionsPanel()
    if self.optionsPanel then return end
    local panel = CreateFrame("Frame", "GuildRadioFMOptionsPanel")
    self.optionsPanel = panel
    panel.name = "GuildRadioFM"
    panel:SetScript("OnShow", function(selfP)
        if selfP.built then return end
        selfP.built = true
        local logo = Text(selfP, 30, C.acc, LOGO_FONT)
        logo:SetPoint("TOPLEFT", 16, -16)
        logo:SetText("GuildRadio FM")
        local note = Text(selfP, 13, C.dim)
        note:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 4, -12)
        note:SetText("Everything lives in the GuildRadioFM window.")
        local open = TextButton(selfP, "Open GuildRadioFM", 150, 28, function() R:ShowTab("settings") end, "primary")
        open:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -14)
    end)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "GuildRadioFM")
        Settings.RegisterAddOnCategory(category)
        self.optionsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

function R:OpenOptionsPanel()
    self:ShowTab("settings")
end
