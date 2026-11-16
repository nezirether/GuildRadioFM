local clock, flights, clients = 100, {}, {}
local roster = {"Ash Maul", "Mire Fang", "Cinder Scout", "Rook Fire"}
local serverEpoch = 1700000000
local function noop() end

local function newClient(name, database, noSongs)
    local frames = {}
    local env = setmetatable({
        GuildRadioFMDB = database,
        SlashCmdList = {},
        GetTime = function() return clock end,
        GetServerTime = function() return serverEpoch + math.floor(clock) end,
        UnitName = function() return name end,
        GetUnitName = function() return name end,
        IsInGuild = function() return true end,
        GetGuildInfo = function() return "Keepers of Trogdor" end,
        GetNumGuildMembers = function() return #roster end,
        GetGuildRosterInfo = function(i) return roster[i], nil, nil, nil, nil, nil, nil, nil, true end,
        C_Timer = {After=noop},
        Print = noop,
        print = noop,
        PlaySoundFile = function() return true, 7 end,
        StopSound = noop,
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
        flights[#flights + 1] = {due=clock+(name=="Ash Maul" and 0.25 or 0.1),
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
    local client={env=env, r=r, eb=r.Live, frames=frames}
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
            for _,f in ipairs(c.frames) do
                if f.events.PLAYER_LOGIN then f.scripts.OnUpdate(f,0.05) end
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
assert(math.abs(a.r.startedAt-b.r.startedAt)<0.2)
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
print("PASS: migration, playlist and favorite storage, song packs, queued playback, lyrics, multiple rooms, scoped chat, stale ordering, missing songs, request voting, and host transfer")
