-- GuildRadioFM Live: listen together + the Request Line, built on Nez's radio.
--
-- Nothing is streamed. Every player runs the same shared clock (the server's clock, refined to
-- frame precision). The DJ schedules each song to start at an exact moment ~1 second ahead and
-- tells the guild; every tuned-in player starts their own packaged copy at that same moment.
-- Someone who tunes in mid-song starts at the next join point (a pre-cut copy of the song that
-- begins 30, 60, 90... seconds in, see JoinPoints.lua), landing exactly in time with everyone.
--
-- Several guildmates can be live at once; listeners pick a set. A DJ can pass the set to one of
-- their listeners ("Pass host"): the queue moves with it and everyone tuned in follows the new host
-- without the music stopping.
--
-- Request Line rules: 5 open requests per guest, a repeat
-- request counts as a vote, unplayed 3+ minutes jumps above newer ones, then votes, then oldest.
-- The window lives in UI.lua (Live tab); this file is the engine.

local R = GuildRadioFM
local EB = { djs = {}, queue = {}, listeners = {}, listenerFull = {}, remoteBy = {}, remote = { list = {}, open = true }, peers = {}, invited = {}, chatLog = {}, classOf = {} }
R.Live = EB

local PREFIX = "GRFM_EB"
local LEAD = 1.2          -- seconds between the DJ pressing play and everyone starting together
local LATE_SLACK = 0.12   -- a listener this late still starts from the top (inaudible)
local JOIN_PREP = 0.6     -- a join point needs at least this much notice
local MAX_OPEN = 5
EB.OVERDUE = 180
local DJ_TIMEOUT = 95
local HEARTBEAT = 30

-- ---------- shared clock ----------
-- GetServerTime() is whole seconds; watching the exact frame it ticks over gives the sub-second phase.
local clockOffset, lastSec, lastFrameTime
function EB.Now()
    if clockOffset then return GetTime() + clockOffset end
    return (GetServerTime and GetServerTime() or time()) + 0.5
end
local function Calibrate()
    local s = GetServerTime and GetServerTime()
    local t = GetTime()
    if not s then return end
    if lastSec and s ~= lastSec and lastFrameTime then
        local est = s - (t + lastFrameTime) / 2     -- the tick happened between the last frame and this one
        if not clockOffset or math.abs(est - clockOffset) > 1 then clockOffset = est
        else clockOffset = clockOffset * 0.8 + est * 0.2 end
    end
    lastSec, lastFrameTime = s, t
end
EB.IsClockReady = function() return clockOffset ~= nil end
local Now = EB.Now

local function Short(name) return name and (string.match(name, "^([^-]+)") or name) or "?" end
local function Me() return UnitName("player") end
EB.Short = Short

local function Send(msg, channel, target)
    if channel == "GUILD" and not IsInGuild() then return end
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(PREFIX, msg, channel, target)
    elseif SendAddonMessage then
        SendAddonMessage(PREFIX, msg, channel, target)
    end
end

-- song <-> wire key: title, lowercased, minus the characters the protocol uses
local function KeyOf(song)
    if not song then return nil end
    local k = string.lower(song.title or song.file or "")
    k = string.gsub(k, "[~:,|]", "")
    return k
end
EB.KeyOf = KeyOf

function EB:IndexOfKey(key)
    for i, song in ipairs(R.songs or {}) do
        if KeyOf(song) == key then return i, song end
    end
end

function EB:TitleOf(key)
    local _, song = self:IndexOfKey(key)
    return song and song.title or key
end

local function Fmt(t) return string.format("%.3f", t) end

-- every live DJ hosts a named room ("Healmode's Room" unless renamed)
local function Clean(s) return (string.gsub(s or "", "[~|,:]", "")) end
function EB:RoomName()
    local n = R.db.eb.roomName
    if not n or n == "" then n = (UnitName("player") or "My") .. "'s Room" end
    return Clean(n)
end
function EB:SetRoomName(name)
    name = Clean(strtrim and strtrim(name or "") or name or "")
    R.db.eb.roomName = name ~= "" and string.sub(name, 1, 32) or nil
    if self.live then self:Heartbeat() end
end

local function Changed()
    if R.UpdateLive then R:UpdateLive() end
    if R.UpdateMinimapButton then R:UpdateMinimapButton() end
end

-- ---------- join points ----------
-- GuildRadioFMJoins[key] = { step = 30, points = { 30, 60, ... }, dir = "Interface\\AddOns\\...\\" }
function EB:JoinPoint(key, position)
    local j = GuildRadioFMJoins and GuildRadioFMJoins[key]
    if not j then return nil end
    for _, p in ipairs(j.points) do
        if p >= position + JOIN_PREP then return p, j.dir .. p .. ".mp3" end
    end
end

-- ---------- scheduled playback ----------
-- R:Play() runs Nez's normal logic; PlayLocalTrack is caught and held until the scheduled moment.
local schedule        -- { at = sharedTime, offset = seconds into the song, file = override }
local pending         -- the held sound, fired from OnUpdate
local origPlay, origStop, origAdvance, origLocal = R.Play, R.Stop, R.AdvanceAfterTrackEnd, R.PlayLocalTrack

function R:PlayLocalTrack(song)
    if schedule then
        if self.soundHandle then StopSound(self.soundHandle); self.soundHandle = nil end
        pending = { at = schedule.at + (schedule.offset or 0), song = song, file = schedule.file }
        return
    end
    return origLocal(self, song)
end

local function FirePending()
    local p = pending
    pending = nil
    if p.file then
        local copy = {}
        for k, v in pairs(p.song) do copy[k] = v end
        copy.file = p.file
        origLocal(R, copy)
    else
        origLocal(R, p.song)
    end
end

-- start song `index` so that position 0 is at shared time `startAt`, joining `offset` seconds in
local function ScheduledPlay(index, startAt, offset, file)
    schedule = { at = startAt, offset = offset, file = file }
    EB.remotePlaying = true
    origPlay(R, index)
    EB.remotePlaying = false
    schedule = nil
    -- progress clock counts from the song's real start, so everyone's timer reads the same
    R.startedAt = GetTime() + (startAt - Now())
    R.durationAdvanceStartedAt = nil
end

function EB:JoiningIn()
    return pending and math.max(0, pending.at - Now()) or nil
end

-- ---------- DJ side ----------
function EB:SortQueue()
    local t = Now()
    local od = self.OVERDUE
    table.sort(self.queue, function(a, b)
        local ao, bo = t - a.at >= od, t - b.at >= od
        if ao ~= bo then return ao end
        if ao then return a.at < b.at end
        if a.votes ~= b.votes then return a.votes > b.votes end
        return a.at < b.at
    end)
end

function EB:BroadcastQueue()
    if not self.live then return end
    Send("QS~" .. self:QueuePayload(), "GUILD")
    Changed()
end

function EB:Reply(sender, text)
    if Short(sender) == Me() then R:Print(text) else Send("RR~" .. text, "WHISPER", sender) end
end

function EB:HandleRequest(sender, key)
    if not self.live then return self:Reply(sender, "I'm not live right now.") end
    if not R.db.eb.open then return self:Reply(sender, "Requests are closed right now.") end
    if not self:IndexOfKey(key) then return self:Reply(sender, "That song isn't in my library.") end
    if R.db.eb.blocked[key] then return self:Reply(sender, "That one is on the do-not-play list.") end
    local who = Short(sender)
    for _, q in ipairs(self.queue) do
        if q.key == key then
            if q.by[who] then return self:Reply(sender, "You already asked for " .. self:TitleOf(key) .. ".") end
            q.by[who] = true
            q.votes = q.votes + 1
            self:Reply(sender, "Vote added: " .. self:TitleOf(key) .. " (" .. q.votes .. ").")
            return self:BroadcastQueue()
        end
    end
    local mine = 0
    for _, q in ipairs(self.queue) do if q.owner == who then mine = mine + 1 end end
    if mine >= MAX_OPEN then return self:Reply(sender, "You have " .. MAX_OPEN .. " open requests. Wait for one to play.") end
    self.queue[#self.queue + 1] = { key = key, owner = who, by = { [who] = true }, votes = 1, at = Now() }
    self:Reply(sender, "Requested: " .. self:TitleOf(key) .. ".")
    self:BroadcastQueue()
end

function EB:DropFromQueue(key)
    for i = #self.queue, 1, -1 do
        if self.queue[i].key == key then table.remove(self.queue, i) end
    end
end

function EB:PlayTopRequest()
    self:SortQueue()
    while self.queue[1] do
        local q = table.remove(self.queue, 1)
        local index = self:IndexOfKey(q.key)
        if index and not R.db.eb.blocked[q.key] then
            R:Print("Request from " .. q.owner .. ": " .. self:TitleOf(q.key))
            R:Play(index)
            return true
        end
    end
    self:BroadcastQueue()
    return false
end

function EB:Decline(key, block)
    self:DropFromQueue(key)
    if block then
        R.db.eb.blocked[key] = true
        R:Print(self:TitleOf(key) .. " is on the do-not-play list. /grfm unblock clears it.")
    end
    self:BroadcastQueue()
end

function EB:Heartbeat()
    if not self.live then return end
    local song = R.db.isPlaying and R:GetCurrentSong() or nil
    local count = 0
    local t = Now()
    for name, seen in pairs(self.listeners) do
        if t - seen > DJ_TIMEOUT then self.listeners[name] = nil else count = count + 1 end
    end
    self.listenerCount = count
    Send("LV~" .. (song and KeyOf(song) or "") .. "~" .. Fmt(self.songStart or 0) .. "~" .. count .. "~" .. self:RoomName(), "GUILD")
end

function EB:GoLive()
    if not IsInGuild() then return R:Print("Join a guild to go live.") end
    if self.tuned then self:TuneOut(true) end
    self.live = true
    self.queue = {}
    self.listeners = {}
    self.listenerCount = 0
    self:ClearChat()
    self:AddChat(nil, self:RoomName() .. " is open.", true)
    if not R.db.isPlaying then self.songStart = 0 end
    R:Print(self:RoomName() .. " is open. Invite guildmates from the Live tab.")
    self:Heartbeat()
    self:BroadcastQueue()
end

function EB:EndSet()
    if not self.live then return end
    self.live = false
    Send("END", "GUILD")
    R:Print("Room closed.")
    Changed()
end

function EB:Announce()
    if not self.live then return end
    local song = R.db.isPlaying and R:GetCurrentSong()
    if SendChatMessage and IsInGuild() then
        SendChatMessage(self:RoomName() .. " is open on GuildRadioFM" .. (song and (", playing " .. song.title) or "") .. ". Type /grfm tune to listen.", "GUILD")
    end
    Send("INV~" .. self:RoomName(), "GUILD")
end

-- ---------- listener side ----------
function EB:CurrentDJ()
    local best
    local t = Now()
    for name, d in pairs(self.djs) do
        if t - d.seen > DJ_TIMEOUT then self.djs[name] = nil
        elseif not best or d.seen > best.seen then best = d end
    end
    return best
end

-- every live set, most listeners first
function EB:LiveSets()
    self:CurrentDJ()
    local out = {}
    for _, d in pairs(self.djs) do out[#out + 1] = d end
    table.sort(out, function(a, b)
        if (a.count or 0) ~= (b.count or 0) then return (a.count or 0) > (b.count or 0) end
        return a.name < b.name
    end)
    return out
end

-- the set whose Request Line we show: the one we're tuned to, else the one we picked, else the busiest
function EB:FocusDJ()
    if self.tuned and self.djs[self.tuned] then return self.djs[self.tuned] end
    if self.focus and self.djs[self.focus] then return self.djs[self.focus] end
    return self:LiveSets()[1]
end

function EB:RemoteList()
    local d = self:FocusDJ()
    local r = d and self.remoteBy[d.full]
    return r and r.list or {}
end

function EB:RemotePlay(key, songStart)
    local index, song = self:IndexOfKey(key)
    if not index then
        self.missing = key
        R:Print("You don't have \"" .. key .. "\". Ask the DJ for the latest GuildRadioFM.")
        return Changed()
    end
    self.missing = nil
    local position = Now() - songStart
    if position <= LATE_SLACK then
        self.waiting = false
        ScheduledPlay(index, songStart, 0)
    else
        local point, file = self:JoinPoint(key, position)
        local duration = tonumber(song.duration) or 0
        if point and (duration == 0 or point < duration - 5) then
            self.waiting = false
            ScheduledPlay(index, songStart, point, file)
        else
            if R.db.isPlaying or pending then pending = nil; origStop(R) end
            self.waiting = true
        end
    end
    Changed()
end

function EB:TuneIn(dj)
    if type(dj) == "string" then dj = self.djs[dj] end
    dj = dj or self:FocusDJ()
    if not dj then return R:Print("Nobody is live right now.") end
    if self.live then self:EndSet() end
    pending = nil
    origStop(R)
    if self.tuned ~= dj.full then self:ClearChat() end
    self.tuned = dj.full
    self:AddChat(nil, "You joined " .. (dj.room or (dj.name .. "'s Room")) .. ".", true)
    Send("TU", "WHISPER", dj.full)
    R:Print("Tuned in to " .. dj.name .. ".")
    if dj.key ~= "" and (dj.start or 0) > 0 then self:RemotePlay(dj.key, dj.start) else self.waiting = true; Changed() end
end

function EB:TuneOut(quiet)
    if not self.tuned then return end
    Send("TO", "WHISPER", self.tuned)
    if not quiet then R:Print("Tuned out of " .. Short(self.tuned) .. ".") end
    self.tuned = nil
    self.waiting = false
    pending = nil
    Changed()
end

function EB:Request(key)
    local focus = self:FocusDJ()
    local target = self.live and Me() or self.tuned or (focus and focus.full)
    if not target then return R:Print("Nobody is live to take requests.") end
    if Short(target) == Me() then return self:HandleRequest(Me(), key) end
    Send("RQ~" .. key, "WHISPER", target)
end

function EB:Requested(key)
    local list = self.live and self.queue or self:RemoteList()
    for _, q in ipairs(list or {}) do if q.key == key then return true end end
end

function EB:QueuePayload(limit)
    self:SortQueue()
    local parts, len = {}, 0
    for _, q in ipairs(self.queue) do
        local item = q.key .. ":" .. q.votes .. ":" .. math.floor(q.at) .. ":" .. Short(q.owner)
        if len + #item + 1 > (limit or 230) then break end
        parts[#parts + 1] = item
        len = len + #item + 1
    end
    return (R.db.eb.open and "1" or "0") .. "~" .. table.concat(parts, ",")
end

function EB:ParseQueue(payload)
    local list = {}
    for item in string.gmatch(payload or "", "[^,]+") do
        local key, votes, at, owner = string.match(item, "^(.-):(%d+):(%d+):(.*)$")
        if key then list[#list + 1] = { key = key, votes = tonumber(votes), at = tonumber(at), owner = owner } end
    end
    return list
end

-- ---------- passing the set to someone else ----------
function EB:ListenerNames()
    local out = {}
    for name in pairs(self.listeners) do out[#out + 1] = name end
    table.sort(out)
    return out
end

function EB:OfferHost(name)
    if not self.live then return end
    local full = self.listenerFull[name]
    if not full or not self.listeners[name] then return R:Print(name .. " isn't tuned in.") end
    self.offerTo = name
    self.offerAt = Now()
    Send("HOF", "WHISPER", full)
    R:Print("Asked " .. name .. " to host the room.")
    Changed()
end

function EB:AnswerHandoff(yes)
    if not self.tuned then return end
    Send(yes and "HAC" or "HDN", "WHISPER", self.tuned)
end

-- old host: send the queue to the new host, tell the guild, then keep listening to them
function EB:CompleteHandoff(newFull)
    local name = Short(newFull)
    -- one message carries the new host and the queue, so they can't arrive out of order
    Send("HO~" .. newFull .. "~" .. self:QueuePayload(200), "GUILD")
    self.live = false
    self.offerTo = nil
    self.queue = {}
    local d = { full = newFull, name = name, key = "", start = 0, count = 0, seen = Now() }
    local song = R.db.isPlaying and R:GetCurrentSong()
    if song then d.key, d.start = KeyOf(song), self.songStart or 0 end
    self.djs[newFull] = d
    self.tuned = newFull          -- the song already playing carries on; we now follow the new host
    Send("TU", "WHISPER", newFull)
    R:Print(name .. " is the host now. You're still tuned in.")
    Changed()
end

-- everyone else: follow the set to its new host
function EB:OnHandoff(oldFull, newFull, inherit)
    local old = self.djs[oldFull]
    self.djs[oldFull] = nil
    self.remoteBy[oldFull] = nil
    if Short(newFull) == Me() then
        if self.tuned ~= oldFull then return end
        self.tuned = nil
        self.live = true
        self.listeners, self.listenerFull, self.listenerCount = {}, {}, 0
        self.queue = {}
        if inherit then
            R.db.eb.open = inherit.open
            for _, q in ipairs(inherit.list) do
                self.queue[#self.queue + 1] = { key = q.key, owner = q.owner, by = { [q.owner] = true }, votes = q.votes, at = q.at }
            end
        end
        self.songStart = old and old.start or 0
        self.waiting = false
        R:Print(Short(oldFull) .. " made you the host. You're on air.")
        self:Heartbeat()
        self:BroadcastQueue()
    else
        local d = self.djs[newFull] or { full = newFull, name = Short(newFull) }
        d.seen = Now()
        if old then d.key, d.start, d.count = old.key, old.start, old.count end
        self.djs[newFull] = d
        if self.tuned == oldFull then
            self.tuned = newFull
            Send("TU", "WHISPER", newFull)
            R:Print(Short(newFull) .. " is hosting now. Still in sync.")
        end
    end
    Changed()
end

-- ---------- inviting guildmates ----------
-- ask who in the guild runs GuildRadioFM (they whisper back "ME"), so invites can pop a card for them
function EB:FindPeers()
    Send("WHO", "GUILD")
    if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() elseif GuildRoster then GuildRoster() end
end

-- online guildmates: { full, name, level, class, zone, hasRadio }
function EB:OnlineGuildmates()
    local out = {}
    if not IsInGuild() or not GetNumGuildMembers then return out end
    local me = Me()
    for i = 1, GetNumGuildMembers() do
        local full, _, _, level, class, zone, _, _, online = GetGuildRosterInfo(i)
        if full and online and Short(full) ~= me then
            out[#out + 1] = { full = full, name = Short(full), level = level or 0, class = class or "", zone = zone or "", hasRadio = self.peers[Short(full)] }
        end
    end
    table.sort(out, function(a, b)
        if (a.hasRadio and 1 or 0) ~= (b.hasRadio and 1 or 0) then return a.hasRadio and true or false end
        return a.name < b.name
    end)
    return out
end

-- invite one guildmate: a Tune in card if they have GuildRadioFM, otherwise a plain whisper
function EB:InviteOne(full)
    if not self.live then self:GoLive() end
    if not self.live then return end
    local name = Short(full)
    if self.peers[name] then
        Send("INV~" .. self:RoomName(), "WHISPER", full)
    elseif SendChatMessage then
        SendChatMessage("Come hang in " .. self:RoomName() .. " on GuildRadioFM. Get GuildRadioFM from the guild, then type /grfm tune.", "WHISPER", nil, full)
    end
    self.invited[name] = Now()
    R:Print("Invited " .. name .. " to " .. self:RoomName() .. ".")
    Changed()
end

-- ---------- room chat ----------
-- Only people in the room see it: messages go out tagged with the host's name and everyone else
-- ignores them. The last 50 lines are kept until you leave the room.
local CHAT_MAX = 50
function EB:RoomHost()
    if self.live then return Me() end
    if self.tuned then return Short(self.tuned) end
end

function EB:AddChat(who, text, system)
    local log = self.chatLog
    log[#log + 1] = { who = who, text = text, system = system, at = Now() }
    while #log > CHAT_MAX do table.remove(log, 1) end
    if not system and R.db.eb.chatInChat ~= false and who ~= Me() then
        local room = self.live and self:RoomName() or ((self.djs[self.tuned or ""] or {}).room or "Room")
        print("|cffffb030[" .. room .. "]|r " .. self:ColorName(who) .. ": " .. text)
    end
    Changed()
end

function EB:ClearChat() self.chatLog = {} end

function EB:ColorName(name)
    local cf = self.classOf[name]
    if not cf and GetNumGuildMembers then
        for i = 1, GetNumGuildMembers() do
            local full, _, _, _, _, _, _, _, _, _, classFile = GetGuildRosterInfo(i)
            if full and classFile then self.classOf[Short(full)] = classFile end
        end
        cf = self.classOf[name]
    end
    local c = cf and RAID_CLASS_COLORS and RAID_CLASS_COLORS[cf]
    if c then return string.format("|cff%02x%02x%02x%s|r", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5), name) end
    return "|cffffd200" .. name .. "|r"
end

function EB:SendChat(text)
    text = string.gsub(text or "", "|", "")
    text = strtrim and strtrim(text) or text
    if text == "" then return end
    local host = self:RoomHost()
    if not host then return R:Print("Open a room or tune into one to chat.") end
    text = string.sub(text, 1, 200)
    Send("CH~" .. host .. "~" .. text, "GUILD")
    self:AddChat(Me(), text)
end

-- ---------- wire ----------
local function Split(msg)
    local out = {}
    for part in string.gmatch(msg .. "~", "([^~]*)~") do out[#out + 1] = part end
    return out
end

function EB:OnMessage(msg, channel, sender)
    if Short(sender) == Me() then return end
    self.peers[Short(sender)] = true
    local chatHost, chatText = string.match(msg, "^CH~([^~]*)~(.*)$")
    if chatHost then
        if chatHost == self:RoomHost() then self:AddChat(Short(sender), chatText) end
        return
    end
    local f = Split(msg)
    local op = f[1]
    if op == "NP" or op == "LV" then
        local d = self.djs[sender] or { full = sender, name = Short(sender) }
        d.room = d.room or (Short(sender) .. "'s Room")
        local isNew = not self.djs[sender]
        self.djs[sender] = d
        d.seen = Now()
        if op == "NP" then
            d.key, d.start = f[2] or "", tonumber(f[3]) or Now()
            if self.tuned == sender then self:RemotePlay(d.key, d.start) end
        else
            d.key, d.start, d.count = f[2] or "", tonumber(f[3]) or 0, tonumber(f[4]) or 0
            if f[5] and f[5] ~= "" then d.room = f[5] end
            if self.tuned == sender then Send("TU", "WHISPER", sender) end
        end
        if isNew and not self.tuned and not self.live and not self.handingOff then R:Print(d.name .. " opened " .. d.room .. " on GuildRadioFM. /grfm tune to listen.") end
        Changed()
    elseif op == "INV" then
        self.peers[Short(sender)] = true
        if not self.tuned and not self.live and R.ShowInvite then R:ShowInvite(Short(sender), f[2] ~= "" and f[2] or nil) end
    elseif op == "ST" then
        local d = self.djs[sender]
        if d then d.key = ""; d.start = 0 end
        if self.tuned == sender then pending = nil; origStop(R); self.waiting = true end
        Changed()
    elseif op == "END" then
        self.djs[sender] = nil
        if self.tuned == sender then
            R:Print(Short(sender) .. " closed the room.")
            self.tuned = nil
            self.waiting = false
        end
        Changed()
    elseif op == "WHO" then
        Send("ME", "WHISPER", sender)
        self.peers[Short(sender)] = true
    elseif op == "ME" then
        self.peers[Short(sender)] = true
        Changed()
    elseif op == "HI" then
        self.peers[Short(sender)] = true
        if self.live then self:Heartbeat(); self:BroadcastQueue() end
    elseif op == "TU" then
        if self.live then
            if not self.listeners[Short(sender)] then self:AddChat(nil, Short(sender) .. " joined.", true) end
            self.listeners[Short(sender)] = Now(); self.listenerFull[Short(sender)] = sender
        end
    elseif op == "TO" then
        if self.live and self.listeners[Short(sender)] then self:AddChat(nil, Short(sender) .. " left.", true) end
        self.listeners[Short(sender)] = nil
    elseif op == "HOF" then
        -- our DJ wants to hand us the set
        if self.tuned == sender and R.ShowHandoff then R:ShowHandoff(Short(sender)) end
    elseif op == "HAC" then
        if self.live and self.offerTo == Short(sender) then self:CompleteHandoff(sender) end
    elseif op == "HDN" then
        if self.offerTo == Short(sender) then self.offerTo = nil; R:Print(Short(sender) .. " passed on hosting.") ; Changed() end
    elseif op == "HO" then
        self:OnHandoff(sender, f[2] or "", { open = f[3] == "1", list = self:ParseQueue(f[4]) })
    elseif op == "RQ" then
        self:HandleRequest(sender, f[2] or "")
    elseif op == "RR" then
        R:Print(Short(sender) .. ": " .. (f[2] or ""))
    elseif op == "QS" then
        local d = self.djs[sender]
        if d then d.seen = Now() end
        self.remoteBy[sender] = { open = f[2] == "1", list = self:ParseQueue(f[3]) }
        self.remote = self.remoteBy[sender]
        Changed()
    end
end

-- ---------- hooks into Nez's player ----------
function R:Play(index)
    if EB.remotePlaying then return origPlay(self, index) end
    if EB.tuned then EB:TuneOut() end
    if EB.live then
        local startAt = Now() + LEAD
        schedule = { at = startAt, offset = 0 }
        origPlay(self, index)
        schedule = nil
        if self.db.isPlaying then
            self.startedAt = GetTime() + LEAD
            self.durationAdvanceStartedAt = nil
            local song = self:GetCurrentSong()
            EB.songStart = startAt
            EB:DropFromQueue(KeyOf(song))
            Send("NP~" .. KeyOf(song) .. "~" .. Fmt(startAt), "GUILD")
            EB:BroadcastQueue()
        end
        return
    end
    pending = nil
    return origPlay(self, index)
end

function R:Stop(fromDJ)
    if EB.tuned and not fromDJ then EB:TuneOut() end
    pending = nil
    origStop(self)
    if EB.live then EB.songStart = 0; Send("ST", "GUILD"); Changed() end
end

function R:AdvanceAfterTrackEnd()
    if EB.tuned then
        -- listeners wait for the DJ's next song instead of skipping ahead on their own
        self.soundHandle = nil
        self.db.isPlaying = false
        self.startedAt = nil
        self:RefreshAll()
        return
    end
    if EB.live and self.db.isPlaying and not self.db.repeatSong then
        self.soundHandle = nil
        if #EB.queue > 0 and EB:PlayTopRequest() then return end
        return self:Next()     -- a live set keeps going even with auto-next off
    end
    return origAdvance(self)
end

-- the song-end timer must not fire while a held song hasn't started yet
local origTick = R.HandlePlaybackTick
function R:HandlePlaybackTick()
    if pending then return end
    return origTick(self)
end

-- ---------- loading screens ----------
-- WoW cuts every sound on a loading screen (entering or leaving an instance). Afterwards, pick the song
-- back up where it would be now: in a room, rejoin the DJ in sync; alone, start the next 30-second join
-- cut of the same song (or restart it if it has none), so the timer and the music still line up.
function EB:ResumeAfterLoading()
    if not R.db or not R.db.isPlaying or not R.startedAt then return end
    if self.tuned then
        local d = self.djs[self.tuned]
        if d and d.key ~= "" and (d.start or 0) > 0 then self:RemotePlay(d.key, d.start) end
        return
    end
    local song, index = R:GetCurrentSong()
    if not song then return end
    local songStart = Now() - (GetTime() - R.startedAt)
    local position = Now() - songStart
    local duration = tonumber(song.duration) or 0
    if duration > 0 and position >= duration - 2 then return end   -- it was ending anyway; the song-end timer moves on
    local point, file = self:JoinPoint(KeyOf(song), position)
    if point and (duration == 0 or point < duration - 5) then
        ScheduledPlay(index, songStart, point, file)
        if self.live then self.songStart = songStart end
        R:Print("Back from the loading screen: " .. (song.title or "the song") .. " picks up in " .. math.ceil(songStart + point - Now()) .. "s.")
    else
        local live = self.live
        self.live = false            -- restart quietly; listeners' copies were never interrupted
        ScheduledPlay(index, Now() + 0.2, 0)
        self.live = live
        if live then self.songStart = Now() + 0.2 end
    end
end

-- ---------- events ----------
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("CHAT_MSG_ADDON")
ev:RegisterEvent("PLAYER_LOGOUT")
ev:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
    if event == "PLAYER_LOGIN" then
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
            C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
        elseif RegisterAddonMessagePrefix then
            RegisterAddonMessagePrefix(PREFIX)
        end
        R.db.eb = R.db.eb or { open = true, blocked = {} }
        R.db.eb.blocked = R.db.eb.blocked or {}
        C_Timer.After(5, function() Send("HI", "GUILD") end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- prefix = isInitialLogin, msg = isReloadingUi; only a real loading screen mid-session cut the sound
        if not prefix and not msg then C_Timer.After(0.5, function() EB:ResumeAfterLoading() end) end
    elseif event == "CHAT_MSG_ADDON" then
        if prefix == PREFIX and msg and sender then EB:OnMessage(msg, channel, sender) end
    elseif event == "PLAYER_LOGOUT" then
        if EB.live then Send("END", "GUILD") end
        if EB.tuned then Send("TO", "WHISPER", EB.tuned) end
    end
end)

local beat = 0
ev:SetScript("OnUpdate", function(_, elapsed)
    Calibrate()
    if pending and Now() >= pending.at then FirePending(); Changed() end
    beat = beat + elapsed
    if beat < HEARTBEAT then return end
    beat = 0
    EB:Heartbeat()
    if EB.live then EB:BroadcastQueue() end
    if EB.offerTo and Now() - (EB.offerAt or 0) > 30 then
        R:Print(EB.offerTo .. " didn't answer. You're still the host.")
        EB.offerTo = nil
    end
    if EB.tuned and not EB.djs[EB.tuned] then
        R:Print("Lost the DJ. Tuned out.")
        EB.tuned = nil
    end
    EB:CurrentDJ()
    Changed()
end)
