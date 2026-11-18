local function noop() end
local function widget(parent)
    local w={scripts={},width=680,height=480,text="",visible=true,parent=parent}
    function w:SetScript(name,fn) self.scripts[name]=fn end
    function w:HookScript(name,fn)
        local old=self.scripts[name]
        self.scripts[name]=function(...) if old then old(...) end; fn(...) end
    end
    function w:SetSize(x,y) self.width,self.height=x,y end
    function w:SetWidth(x) self.width=x end
    function w:SetHeight(y) self.height=y end
    function w:GetWidth() return self.width end
    function w:GetHeight() return self.height end
    function w:SetText(value) self.text=tostring(value or "") end
    function w:GetText() return self.text end
    function w:GetStringWidth() return #self.text*6 end
    function w:GetFrameLevel() return 1 end
    function w:GetParent() return self.parent end
    function w:GetPoint() return "CENTER",nil,"CENTER",0,0 end
    function w:GetEffectiveScale() return self.scale or 1 end
    function w:SetScale(value) self.scale=value end
    function w:GetScale() return self.scale or 1 end
    function w:Show() self.visible=true end
    function w:Hide() self.visible=false end
    function w:IsShown() return self.visible end
    function w:CreateTexture() return widget(self) end
    function w:CreateFontString() return widget(self) end
    function w:SetTexture(path) self.path=path; return true end
    function w:IsMouseOver() return false end
    return setmetatable(w,{__index=function(_,key)
        if key:match("^[A-Z]") then return noop end
    end})
end
local env=setmetatable({
    GuildRadioFMDB={},SlashCmdList={},UIParent=widget(),UISpecialFrames={},
    GetTime=function() return 100 end,GetServerTime=function() return 1700000100 end,
    UnitName=function() return "Tester" end,GetUnitName=function() return "Tester" end,
    IsInGuild=function() return true end,GetGuildInfo=function() return "Test Guild" end,
    GetNumGuildMembers=function() return 0 end,
    GetCVar=function() return "1" end,SetCVar=noop,
    GetCursorPosition=function() return 0,0 end,
    C_Timer={After=noop},print=noop,
    CreateFrame=function(_,_,parent) return widget(parent) end,
    PlaySoundFile=function() return true,1 end,StopSound=noop,
}, {__index=_G})
env._G=env
for line in io.lines("GuildRadioFM.toc") do
    if line:match("%.lua$") then setfenv(assert(loadfile(line)),env)() end
end
local r=env.GuildRadioFM
r.CreateMinimapButton,r.CreateOptionsPanel=noop,noop
r:Initialize()
r:CreateMainWindow()
r:CreateMiniWindow()
for _,skin in ipairs(r.SkinList) do
    local surfaces = {}
    for _,role in ipairs({"background","header","crest","decor","outer","panel","tab",
        "button","transport","progressTrack","progressFill","volumeTrack","volumeFill",
        "volumeThumb","badge","queueRow","mini"}) do
        surfaces[role]={path=skin.key.."-"..role..".tga",width=256,height=256,mode="nine",
            insets={8,8,8,8}}
    end
    assert(r.RegisterSkinAssets(skin.key,{surfaces=surfaces,
        emblem={path=skin.key.."-emblem.tga",width=512,height=512,mode="contain",bounds={80,20,420,480}},
        icons={path=skin.key.."-icons.tga",width=512,height=256,cell=64,columns=8}}))
    r:SetSkin(skin.key)
    for _,tab in ipairs({"now","library","playlists","live","skins","settings"}) do
        r:ShowTab(tab)
        r:RefreshAll()
    end
    for _,scale in ipairs({0.5,0.8,1,1.4}) do
        r.mainFrame:SetScale(scale)
        r.miniFrame:SetScale(scale)
        r:RefreshAll()
    end
end
r.songs[1].title=string.rep("Long song title ",20)
r:RefreshAll()
assert(r.db.skin=="retail")
print("PASS: mocked full player and mini-player creation, six screens, 13 skins, scales and long title")
