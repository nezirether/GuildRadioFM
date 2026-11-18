local clock, flights, clients = 100, {}, {}
local roster = {"Ash Maul", "Mire Fang", "Cinder Scout", "Rook Fire"}
local serverEpoch = 1700000000
local function noop() end

local function newClient(name, database, noSongs)
    local frames, timers, active = {}, {}, {}
    local handle, starts = 0, 0
    local client
    local localOffset = name == "Mire Fang" and 7.347 or 0
    local env = setmetatable({
        GuildRadioFMDB = database,
        SlashCmdList = {},
        GetTime = function() return clock + localOffset end,
        GetServerTime = function() return serverEpoch + math.floor(clock) end,
        UnitName = function() return name end,
        GetUnitName = function() return name end,
        IsInGuild = function() return true end,
        GetGuildInfo = function() return "Keepers of Trogdor" end,
        GetNumGuildMembers = function() return #roster end,
        GetGuildRosterInfo = function(i) return roster[i], nil, nil, nil, nil, nil, nil, nil, true end,
        C_Timer = {After=function(delay, fn)
            timers[#timers + 1] = {due=clock+delay, run=fn}
        end},
        Print = noop,
        print = noop,
        PlaySoundFile = function(file)
            if client.failAudio then return false end
            assert(not next(active), name .. " started overlapping audio")
            handle, starts = handle + 1, starts + 1
            active[handle] = file
            client.lastAudioStart = clock
            return true, handle
        end,
        StopSound = function(id) active[id] = nil end,
        CreateFrame = function()
            local f = {events={}, scripts={}}
            function f:RegisterEvent(event) self.events[event] = true end
            function f:SetScript(script, fn) self.scripts[script] = fn end
            frames[#frames + 1] = f
            return f
        end,
    }, {__index=_G})
    env.C_ChatInfo = {RegisterAddonMessagePrefix=noop, SendAddonMessage=function(prefix, packet, channel, target)
        assert(#packet <= 255 and prefix == "GRFM_EB")
        flights[#flights + 1] = {due=clock+(name=="Ash Maul" and 0.65 or 0.1),
            from=name, packet=packet, channel=channel, target=target}
        return 0
    end}
    env._G = env
    for line in io.lines("GuildRadioFM.toc") do
        if line:match("%.lua$") then setfenv(assert(loadfile(line)),env)() end
    end
    local r = env.GuildRadioFM
    r.CreateMinimapButton, r.CreateOptionsPanel, r.ShowNowPlayingToast = noop, noop, noop
    if noSongs then env.GuildRadioFMSongList = {}; r.songPacks = {} end
    r.ShowHandoff = noop
    r:Initialize()
    client={env=env, r=r, eb=r.Live, frames=frames, active=active, timers=timers,
        starts=function() return starts end}
    function client:event(event, ...)
        for _, f in ipairs(self.frames) do
            if f.events[event] then f.scripts.OnEvent(f,event,...) end
        end
    end
    clients[name]=client
    for _,frame in ipairs(frames) do
        if frame.events.PLAYER_LOGIN then frame.scripts.OnEvent(frame,"PLAYER_LOGIN") end
    end
    return client
end

local function advance(seconds)
    local untilTime=clock+seconds
    while clock < untilTime do
        clock=clock+0.05
        local i=1
        while i<=#flights do
            local f=flights[i]
            if f.due<=clock then
                table.remove(flights,i)
                for name,c in pairs(clients) do
                    if name~=f.from and (not f.target or f.target==name) then
                        c.eb:OnMessage(f.packet,f.channel,f.from)
                    end
                end
            else i=i+1 end
        end
        for _,c in pairs(clients) do
            for i=#c.timers,1,-1 do
                local timer=c.timers[i]
                if timer.due<=clock then
                    table.remove(c.timers,i)
                    timer.run()
                end
            end
            for _,f in ipairs(c.frames) do
                if f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.05) end
            end
        end
    end
end

local a=newClient("Ash Maul",{favorites={[1]=true}, playlists={{name="Saved list",songs={1,2}}},
    secretFrequencyUnlocked=true, unknown={kept=true}, queue={{title="Arrested in Stormwind"}}})
local b=newClient("Mire Fang",{favorites="broken",playlists={false},untouched="present"})
assert(not b.r.db.secretFrequencyUnlocked)
b.r:TuneFrequency("1138")
assert(b.r.db.secretFrequencyUnlocked)
local c=newClient("Cinder Scout",{})
local d=newClient("Rook Fire",{},true)
advance(1)
assert(a.r.db.schemaVersion==1 and a.r.db.favorites[1] and a.r.db.playlists[1].songs[2]==2)
assert(a.r.db.secretFrequencyUnlocked and a.r.db.unknown.kept)
assert(type(b.r.db.favorites)=="table" and b.r.db.recoveryValues[1].favorites=="broken")
assert(b.r.db.recoveryValues[1]["playlists.1"]==false and b.r.db.untouched=="present")
assert(a.r:PlayNextInQueue() and #a.r:GetQueue()==0 and a.r:GetCurrentTitle()=="Arrested in Stormwind")
a.r:RegisterLyrics("Arrested in Stormwind","[00:00]First\n[00:02.50]Second")
assert(a.r:CurrentLyric()=="First")
advance(2.7)
assert(a.r:CurrentLyric()=="Second")
a.r:Stop()
a.r:Reset()
assert(a.r.db.playlists[1].name=="Saved list" and a.r.db.favorites[1])
assert(a.r.AddSong({id="custom:one",title="Custom one",file="one.mp3"}))
assert(a.r.AddSong({id="custom:two",title="Custom two",file="two.mp3"}))
assert(a.r.songIndexById["custom:one"] and a.r.songIndexById["custom:two"])

-- Two hosts can advertise independent rooms.
a.eb:GoLive()
c.eb:GoLive()
advance(1)
assert(b.eb.djs["Ash Maul"] and b.eb.djs["Cinder Scout"])
b.eb:TuneIn("Ash Maul")
d.eb:TuneIn("Ash Maul")
advance(1)
assert(a.eb.listenerCount==0 or a.eb.listeners["Mire Fang"])
assert(a.eb.listenerFull["Mire Fang"]=="Mire Fang" and a.eb.listenerFull["Rook Fire"]=="Rook Fire")
b.eb:SendChat("room only")
advance(2)
assert(b.eb.chatLog[#b.eb.chatLog].text=="room only")
assert(d.eb.chatLog[#d.eb.chatLog].text=="room only")
assert(c.eb.chatLog[#c.eb.chatLog].text~="room only")
local chatCount=#a.eb.chatLog
a.eb:OnMessage("3~1700000100000~70~CH~not a listener","WHISPER","Cinder Scout")
a.eb:OnMessage("3~1700000100000~71~CH~outsider","WHISPER","Outside Player")
assert(#a.eb.chatLog==chatCount)
a.eb:OnMessage("3~1700000100000~72~LV~~not-a-time","GUILD","Mire Fang")
assert(not a.eb.djs["Mire Fang"])

a.r:Play(1)
advance(2)
assert(a.r.soundHandle and b.r.soundHandle)
assert(math.abs(a.lastAudioStart-b.lastAudioStart)<0.15)
assert(d.eb.missing and not d.r.db.isPlaying)
local sameStart=b.r.startedAt
a.eb:Heartbeat()
advance(1)
assert(b.r.startedAt==sameStart, "heartbeat replayed a song")
local key=a.eb.KeyOf(a.r:GetSong(2))
b.eb:Request(key)
d.eb:Request(key)
advance(2)
assert(a.eb.queue[1].votes==2)
d.eb:Request(key)
advance(1)
assert(a.eb.queue[1].votes==2)
a.eb:OfferHost("Mire Fang")
advance(1)
b.eb:AnswerHandoff(true)
advance(3)
assert(not a.eb.live and b.eb.live and a.eb.tuned=="Mire Fang")
assert(b.eb.queue[1] and b.eb.queue[1].votes==2)
d.eb:Request(key)
advance(1)
assert(b.eb.queue[1].votes==2, "vote was duplicated after host transfer")
b.eb:EndSet()
advance(1)
assert(not a.eb.tuned and not a.r.soundHandle)

c.eb:EndSet()
c.eb:GoLive()
advance(2)
b.eb:TuneIn("Cinder Scout")
advance(1)
assert(b.eb.tuned=="Cinder Scout")
local cdb=c.r.db
clients["Cinder Scout"]=nil
advance(125)
assert(not b.eb.tuned and b.r.db.eb.lastRoomHost=="Cinder Scout")
c=newClient("Cinder Scout",cdb)
c.eb:GoLive()
advance(2)
assert(b.eb.tuned=="Cinder Scout", "listener did not resume its previous room")

-- A reloaded listener waits for the next song if there is no local join cut.
c.r:Play(1)
advance(2)
assert(b.r.soundHandle)
local previous = b
previous:event("PLAYER_LOGOUT")
assert(not next(previous.active))
b = newClient("Mire Fang", previous.r.db)
b:event("PLAYER_ENTERING_WORLD", false, true)
advance(7)
assert(b.eb.tuned=="Cinder Scout" and b.eb.waiting and not b.r.soundHandle)
c.r:Play(2)
advance(0.35)
assert(b.eb:JoiningIn())
b:event("PLAYER_LEAVING_WORLD")
b:event("LOADING_SCREEN_ENABLED")
advance(2)
b:event("PLAYER_ENTERING_WORLD")
b:event("LOADING_SCREEN_DISABLED")
advance(1)
assert(b.eb.waiting and not b.r.soundHandle)
b.failAudio = true
c.r:Play(1)
advance(3)
assert(b.eb.waiting and b.eb.missing and not b.r.soundHandle)
c.r:Stop()
advance(2)
assert(b.eb.waiting and not b.eb.missing)
b.failAudio = false
-- An invalid handoff must not consume the playback stream's sequence.
c.r:Play(1)
advance(2)
b.eb:OnMessage("3~"..c.r.db.eb.wireEpoch.."~999999~HO~Outside Player~1~","GUILD","Cinder Scout")
c:event("PLAYER_LEAVING_WORLD")
assert(not next(c.active))
advance(1)
c:event("PLAYER_ENTERING_WORLD")
advance(1)
assert(not c.r.soundHandle and b.r.soundHandle)
c.r:Play(2)
advance(2)
assert(c.r.soundHandle and b.r.soundHandle and b.r:GetCurrentTitle()==c.r:GetCurrentTitle())
b.eb:TuneOut()
advance(2)

-- Two completion events resume once. The duration fallback stops the old
-- sound even when the file would keep playing, then the next song can start.
b.r:Play(1)
local before = b.starts()
b:event("PLAYER_LEAVING_WORLD")
b:event("LOADING_SCREEN_ENABLED")
assert(not next(b.active))
advance(2)
b:event("PLAYER_ENTERING_WORLD")
b:event("LOADING_SCREEN_DISABLED")
advance(2)
assert(b.starts()==before+1 and b.r.soundHandle)
local old = b.r.soundHandle
b.r.startedAt = b.env.GetTime() - b.r:GetCurrentSong().duration
b.r:HandlePlaybackTick()
assert(not b.active[old])
b.r:Play(2)
assert(b.r.soundHandle)
b:event("PLAYER_LOGOUT")
assert(not next(b.active))
advance(2)
assert(not next(b.active))
b = newClient("Mire Fang", b.r.db)

local future={schemaVersion=99,keep=true}
local f=newClient("Future Client",future)
assert(f.env.GuildRadioFMDB==future and not f.r.db and future.keep)
local wire=b.r.Wire
assert(not wire.Send("GRFM_EB",string.rep("x",221),"GUILD",nil,serverEpoch+clock))
wire.Clear()
advance(5)
local sentBefore=#flights
for i=1,15 do assert(wire.Send("GRFM_EB","HI","GUILD",nil,serverEpoch+clock)) end
assert(#flights-sentBefore<=8, "burst exceeded the transport limit")
wire.Clear()
assert(wire.Accept("A","GUILD","test",10,2))
assert(not wire.Accept("A","GUILD","test",10,2))
assert(not wire.Accept("A","GUILD","test",9,9))
assert(wire.Accept("A","GUILD","test",11,1))
print("PASS: migration, playlist and favorite storage, song packs, queued playback, lyrics, multiple rooms, scoped chat, stale ordering, missing songs, voting, host transfer, reconnect, and exclusive audio across reloads and loading screens")
