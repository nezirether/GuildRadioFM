-- Supplied concept artwork, sampled as atlas regions. All playback text remains live.
local R = GuildRadioFM
local DIR = "Interface\\AddOns\\GuildRadioFM\\Media\\Signature\\"
local function region(file, canvasW, canvasH, x,y,w,h, mode, inset, borderOnly)
    return {path=DIR..file..".tga",width=canvasW,height=canvasH,
        uv={x/canvasW,(x+w)/canvasW,y/canvasH,(y+h)/canvasH},
        mode=mode or "contain",insets=inset,borderOnly=borderOnly}
end
local function signature(x,y,w,h,mode,inset,borderOnly)
    return region("signature",2048,1024,x,y,w,h,mode,inset,borderOnly)
end
R.SignatureHeaders = {}
for _, skin in ipairs(R.SkinList) do
    local existing=R.SkinRenderer.assets[skin.key] or {}
    local surfaces=existing.surfaces or {}
    if skin.key=="trogdor" then
        surfaces.header=signature(0,0,1672,246)
    else
        surfaces.header={path=skin.art.banner,width=512,height=64,mode="contain"}
    end
    R.SignatureHeaders[skin.key]=surfaces.header
    if skin.key=="trogdor" then
        surfaces.outer=signature(0,0,1672,941,"nine",{32,32,32,28},true)
        surfaces.panel=signature(1151,415,474,365,"nine",{15,15,15,15},true)
        surfaces.tab=signature(30,350,292,65,"nine",{22,28,9,9},true)
        surfaces.button=signature(536,666,148,94,"nine",{25,25,16,16},true)
        surfaces.transport=surfaces.button
        surfaces.progressTrack=signature(450,603,605,23,"nine",{10,10,6,6},true)
        surfaces.progressFill=signature(469,608,220,9,"stretch")
        surfaces.mini=signature(630,550,256,40,"tile")
        if skin.key=="trogdor" then surfaces.background=surfaces.mini end
    end
    existing.surfaces=surfaces
    assert(R.RegisterSkinAssets(skin.key,existing))
end
