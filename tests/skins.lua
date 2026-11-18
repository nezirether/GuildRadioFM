local function widget(width, height)
    local object = {width=width or 200, height=height or 80, visible=true, scripts={}, textures={}}
    function object:GetWidth() return self.width end
    function object:GetHeight() return self.height end
    function object:SetSize(w,h) self.width,self.height=w,h end
    function object:SetTexture(path) self.path=path; return path ~= "missing.tga" end
    function object:SetTexCoord(...) self.uv={...} end
    function object:SetVertexColor(...) self.color={...} end
    function object:ClearAllPoints() end
    function object:SetPoint(...) self.point={...} end
    function object:Show() self.visible=true end
    function object:Hide() self.visible=false end
    function object:HookScript(event, fn) self.scripts[event]=fn end
    function object:CreateTexture()
        local texture=widget()
        self.textures[#self.textures+1]=texture
        return texture
    end
    return object
end

GuildRadioFM={db={skin="trogdor"}}
dofile("Skins.lua")
dofile("SkinRenderer.lua")
local R, renderer=GuildRadioFM,GuildRadioFM.SkinRenderer
local function art(mode, path)
    return {path=path or "test.tga",width=256,height=128,mode=mode,insets={16,16,8,8}}
end
local fallback=widget()
local frame=widget(200,80)
local binding=renderer:Bind(frame,"button",fallback)
assert(fallback.visible)
local normal=art("nine")
normal.states={hover=art("nine","hover.tga"),pressed=art("nine","pressed.tga"),
    disabled=art("nine","disabled.tga"),selected=art("nine","selected.tga")}
local icon=widget()
local iconBinding=renderer:BindIcon(icon,"play")
for _,skin in ipairs(R.SkinList) do
    assert(R.RegisterSkinAssets(skin.key,{surfaces={button=normal},icons={path=skin.key..".tga",
        width=512,height=256,columns=8,cell=64,states={hover="hover-icons.tga"}}}))
    R.db.skin=skin.key
    renderer:Refresh()
    assert(not fallback.visible and #binding.parts==9)
    assert(binding.parts[1].width==16 and binding.parts[1].height==8)
    assert(binding.parts[5].width==168 and binding.parts[5].height==64)
    for _,state in ipairs({"hover","pressed","selected","disabled","normal"}) do
        binding:SetState(state)
        assert(binding.parts[1].path==(state=="normal" and "test.tga" or state..".tga"))
    end
    for _,name in ipairs(R.SkinIconNames) do
        iconBinding:SetIcon(name)
        assert(icon.path==skin.key..".tga" and #icon.uv==4)
        assert(icon.uv[1]>=0 and icon.uv[2]<=1 and icon.uv[3]>=0 and icon.uv[4]<=1)
        assert(math.abs((icon.uv[2]-icon.uv[1])*512-63)<0.001)
    end
    iconBinding:SetState("hover")
    assert(icon.path=="hover-icons.tga")
    iconBinding:SetState("normal")
end

R.db.skin="trogdor"
local saved=R.db.skin
R.previewSkin="alliance"
renderer:Refresh()
assert(R.db.skin==saved and icon.path=="alliance.tga")
R.previewSkin=nil
renderer:Refresh()
assert(icon.path=="trogdor.tga")
for _,scale in ipairs({0.5,0.8,1,1.4}) do
    frame.width,frame.height=200*scale,80*scale
    frame.scripts.OnSizeChanged()
    assert(binding.parts[1].width==16 and binding.parts[1].height==8)
end
local before=renderer.assets.trogdor
assert(not R.RegisterSkinAssets("trogdor",{surfaces={button={path="x",width=0,height=10}}}))
assert(renderer.assets.trogdor==before)
assert(not R.RegisterSkinAssets("unknown",{}))

R.RegisterSkinAssets("trogdor",{surfaces={button=art("nine","missing.tga")},
    icons={path="missing.tga",width=512,height=256,columns=8,cell=64}})
renderer:Refresh()
assert(fallback.visible and not binding.parts[1].visible)
assert(icon.path:match("GuildRadioFM_Icons.tga$"))
for _,mode in ipairs({"contain","tile","three","stretch"}) do
    R.RegisterSkinAssets("trogdor",{surfaces={button=art(mode)}})
    frame.width,frame.height=300,100
    renderer:Refresh()
    assert(not fallback.visible)
    if mode=="contain" then
        assert(binding.parts[1].width==200 and binding.parts[1].height==100)
    elseif mode=="three" then
        assert(binding.parts[1].width==16 and binding.parts[1].height==100)
    end
end
R.db.skin="future-skin"
renderer:Refresh()
assert(R.db.skin=="future-skin" and R:GetActiveSkin().key=="classic")
local emblemTexture = widget()
local emblemBinding = renderer:BindEmblem(frame, emblemTexture, "main")
assert(not emblemTexture.visible and not emblemBinding.available)
for _, skin in ipairs(R.SkinList) do
    R.db.skin = skin.key
    assert(R.RegisterSkinAssets(skin.key,{emblem={path="emblem.tga",width=512,height=512,
        mode="contain",bounds={100,20,400,480}}}))
    renderer:Refresh()
    assert(emblemTexture.visible and emblemBinding.available)
    assert(math.abs(emblemTexture.width/emblemTexture.height-300/460)<0.00001)
    local layout=skin.emblemLayout.main
    assert(emblemTexture.width<=layout.width and emblemTexture.height<=layout.height)
    local picker=skin.emblemLayout.picker
    assert(picker.height<=40 and picker.y-picker.height>=-46)
    assert(emblemTexture.uv[1]==100/512 and emblemTexture.uv[2]==400/512)
end
assert(not R.RegisterSkinAssets("trogdor",{emblem={path="x",width=128,height=128,bounds={0,0,128,128}}}))
assert(not R.RegisterSkinAssets("trogdor",{emblem={path="x",width=512,height=512,bounds={400,0,100,512}}}))
R.db.skin="trogdor"
R.RegisterSkinAssets("trogdor",{emblem={path="missing.tga",width=512,height=512,bounds={10,10,500,500}}})
renderer:Refresh()
assert(not emblemTexture.visible and not emblemBinding.available)
-- Load the actual supplied original after synthetic failure scenarios.
dofile("SkinAssets.lua")
R.db.skin="trogdor"
renderer:Refresh()
assert(emblemBinding.available and emblemTexture.visible)
assert(emblemTexture.path:match("trogdor.*emblem.tga$"))
assert(math.abs(emblemTexture.width/emblemTexture.height-1)<0.00001)
print("PASS: 13 emblem viewports, painted aspect, transparent padding, picker safe zone and rejected legacy fallback")
print("PASS: 13 skin descriptors, 32 icon regions, states, geometry, resize, missing assets and saved preferences")
