local frames = {}
local function noop() end
local function widget()
    local object = {scripts = {}}
    function object:SetScript(event, callback) self.scripts[event] = callback end
    function object:CreateTexture() return widget() end
    function object:CreateFontString() return widget() end
    function object:GetFrameLevel() return 1 end
    function object:GetWidth() return 500 end
    function object:GetHeight() return 500 end
    return setmetatable(object, {__index = function(_, key)
        if key ~= "Hover" and key:match("^[A-Z]") then return noop end
    end})
end
function CreateFrame()
    local frame = widget()
    frames[#frames + 1] = frame
    return frame
end

local shown, value, calls
GameTooltip = {
    SetOwner = noop,
    SetText = function(_, text)
        assert(type(text) == "string" and text ~= "", "Invalid tooltip text")
        calls = calls + 1
        value = text
    end,
    Show = function() shown = true end,
    Hide = function() shown = false end,
}

GuildRadioFM = {}
dofile("Skins.lua")
dofile("SkinRenderer.lua")
dofile("UI.lua")

local function upvalue(fn, name, seen)
    seen = seen or {}
    if seen[fn] then return end
    seen[fn] = true
    local i = 1
    while true do
        local key, value = debug.getupvalue(fn, i)
        if not key then return end
        if key == name then return value end
        if type(value) == "function" then
            local child = upvalue(value, name, seen)
            if child then return child end
        end
        i = i + 1
    end
end

local tip = assert(upvalue(GuildRadioFM.BuildPlaylistPage, "Tip"))
local makeIconButton = assert(upvalue(GuildRadioFM.BuildPlaylistPage, "IconButton"))

local function hover(frame, expected)
    calls, shown, value = 0, false, nil
    frame.scripts.OnEnter(frame)
    assert(calls == (expected and 1 or 0))
    assert(shown == (expected ~= nil) and value == expected)
    frame.scripts.OnLeave(frame)
    assert(not shown)
end
local function check(input, expected)
    local frame = widget()
    local transitions = {}
    frame.Hover = function(_, active) transitions[#transitions + 1] = active end
    tip(frame, input)
    hover(frame, expected)
    assert(#transitions == 2 and transitions[1] and transitions[2] == false)
end
check("Static", "Static")
check(function(frame) assert(frame.scripts); return "Dynamic" end, "Dynamic")
check(function() return nil end)
check(function() return false end)
check(function() return {} end)
check(function() return true end)
check(function() return 12 end)
check(function() return function() end end)
check("")
check(nil)
check(false)
check(12)
check({})
local disabled = makeIconButton(widget(), "close", 12, noop, function(self)
    if self.disabled then return "Unavailable" end
end)
disabled:SetDisabledLook(true)
hover(disabled, "Unavailable")

local selection
function GuildRadioFM:GetSelectedPlaylist() return selection end
local page = widget()
GuildRadioFM:BuildPlaylistPage(page)
hover(page.headHit)
selection = {name = "Read-only pack", runtime = true}
hover(page.headHit)
selection = {name = "My playlist"}
hover(page.headHit, "Click to rename")
print("PASS: tooltip types, cancellation, hover effects, disabled controls and actual playlist rename control")
