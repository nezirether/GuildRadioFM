local function noop() end
local function widget(parent)
    local w={scripts={},points={},width=680,height=480,text="",visible=true,parent=parent}
    function w:SetPoint(...) self.points[#self.points+1]={...} end
    function w:ClearAllPoints() self.points={} end
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
    function w:SetFont(path,size) self.fontPath,self.fontSize=path,size end
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
r:SetSkin("trogdor")
local f=r.mainFrame
assert(r.miniFrame:GetHeight()==86 and r.miniFrame.title.fontSize==20)
assert(r.miniFrame.eyebrow.fontSize==14 and r.miniFrame.play:GetWidth()==36)
for _,binding in ipairs(r.SkinRenderer.surfaces) do
    if binding.frame==r.miniFrame then assert(binding.role~="outer") end
end
assert(f:GetWidth()==1040 and f:GetHeight()==620 and #f.navOrder==6)
assert(f.pages.now.points[1][4]==216 and f.pages.now.points[2][4]==-308)
r:SetFrameScale(f,"scale",1.4)
assert(f:GetScale()*1064<=env.UIParent:GetWidth()+0.001)
r:ShowTab("now")
for i=1,10 do assert(r:AddToQueue(i)) end
local queue=f.queuePanel
assert(queue.rows[1].index==1)
queue.scripts.OnMouseWheel(queue,-3)
assert(queue.rows[1].index==4)
queue.rows[2].scripts.OnClick(queue.rows[2])
local title=r:GetQueue()[5].title
queue.up.scripts.OnClick(queue.up,"LeftButton")
assert(r:GetQueue()[4].title==title)
queue.rows[2].remove.scripts.OnClick(queue.rows[2].remove,"LeftButton")
assert(#r:GetQueue()==9)
f.footer.play.scripts.OnClick(f.footer.play,"LeftButton")
assert(r.db.isPlaying)
f.footer.play.scripts.OnClick(f.footer.play,"LeftButton")
assert(not r.db.isPlaying)
r:ShowTab("settings")
local settings=f.pages.settings
assert(#settings.settingRows==10)
for _,row in ipairs(settings.settingRows) do
    assert(row:GetHeight()==70 and row.label.fontSize==18 and row.description.fontSize==14)
    assert(row.toggle:GetWidth()==76 and row.toggle:GetHeight()==32)
end
settings.scroll(-3)
assert(settings.scrollOffset>0)
settings.scroll(100)
assert(settings.scrollOffset==0)
r:ShowTab("library")
assert(not queue:IsShown())
r:ShowTab("now")
assert(queue:IsShown())
print("PASS: Signature layout regions, viewport fit, queue scrolling/reorder/removal and footer playback")
print("PASS: mocked full player and mini-player creation, six screens, 13 skins, scales and long title")
