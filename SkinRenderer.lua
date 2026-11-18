-- Descriptor renderer for legacy texture APIs. No client NineSlice dependency.
local R = GuildRadioFM
local Renderer = {surfaces = {}, icons = {}, emblems = {}, assets = {}}
R.SkinRenderer = Renderer
R.SkinIconNames = {"play", "pause", "stop", "prev", "next", "shuffle", "repeat", "volume",
    "mute", "library", "playlists", "queue", "live", "settings", "search", "heart",
    "heartline", "chat", "request", "vote", "close", "back", "minimize", "expand",
    "plus", "minus", "up", "down", "music", "microphone", "room", "check"}
local legacyIcons = {prev=0, play=1, pause=2, stop=2, next=3, heart=4, heartline=5,
    shuffle=6, ["repeat"]=7, volume=8, mute=9, plus=10, close=11, up=12, down=13,
    minus=14, live=15, library=15, playlists=10, queue=10, settings=6, search=15,
    chat=15, request=10, vote=4, back=0, minimize=14, expand=12, music=15, microphone=15,
    room=15, check=10}
local iconIndex = {}
for i, name in ipairs(R.SkinIconNames) do iconIndex[name] = i - 1 end
local MEDIA = "Interface\\AddOns\\GuildRadioFM\\Media\\"
local states = {normal=true, hover=true, pressed=true, selected=true, disabled=true}
local modes = {stretch=true, contain=true, tile=true, three=true, nine=true}

local function positive(number)
    return type(number) == "number" and number > 0 and number < math.huge
end

local function validDescriptor(d)
    if type(d) ~= "table" or type(d.path) ~= "string" or d.path == "" or
        not positive(d.width) or not positive(d.height) or not modes[d.mode or "stretch"] then return false end
    local uv = d.uv or {0, 1, 0, 1}
    for i=1,4 do if type(uv[i]) ~= "number" or uv[i] ~= uv[i] or uv[i] < 0 or uv[i] > 1 then return false end end
    if uv[1] >= uv[2] or uv[3] >= uv[4] then return false end
    local inset = d.insets or {0,0,0,0}
    for i=1,4 do if type(inset[i]) ~= "number" or inset[i] ~= inset[i] or inset[i] < 0 or inset[i] == math.huge then return false end end
    if inset[1]+inset[2] >= (uv[2]-uv[1])*d.width or
        inset[3]+inset[4] >= (uv[4]-uv[3])*d.height then return false end
    for name, state in pairs(d.states or {}) do
        if not states[name] or type(state) ~= "table" or state.states or not validDescriptor(state) then return false end
    end
    return true
end

local loadTexture

function R.RegisterSkinAssets(key, assets)
    if not R.SkinByKey[key] or type(assets) ~= "table" then return false end
    for _, d in pairs(assets.surfaces or {}) do
        if not validDescriptor(d) then return false end
    end
    local icons = assets.icons
    local emblem = assets.emblem
    if emblem then
        if not validDescriptor(emblem) or
            (emblem.width ~= 256 and emblem.width ~= 512) or
            (emblem.height ~= 256 and emblem.height ~= 512) then return false end
        local bounds = emblem.bounds
        if type(bounds) ~= "table" or #bounds ~= 4 then return false end
        for i=1,4 do
            local limit = (i == 1 or i == 3) and emblem.width or emblem.height
            if type(bounds[i]) ~= "number" or bounds[i] ~= bounds[i] or bounds[i] < 0 or bounds[i] > limit then return false end
        end
        if bounds[1] >= bounds[3] or bounds[2] >= bounds[4] then return false end
    end
    if icons then
        if type(icons.path) ~= "string" or icons.width ~= 512 or icons.height ~= 256 or
            icons.cell ~= 64 or icons.columns ~= 8 then return false end
        for name, path in pairs(icons.states or {}) do
            if not states[name] or type(path) ~= "string" then return false end
        end
    end
    Renderer.assets[key] = assets
    return true
end

-- Draw only reviewed transparent emblems. Legacy circular crests are retired.
-- Alpha bounds determine the painted aspect independently of the square source.
function Renderer:PaintEmblem(binding)
    local skin = binding.skin or R:GetActiveSkin().key
    local asset = self.assets[skin]
    local emblem = asset and asset.emblem
    local texture = binding.texture
    if not emblem or not loadTexture(texture, emblem.path) then
        texture:Hide()
        binding.available = false
        return false
    end
    local layout = R.SkinByKey[skin].emblemLayout[binding.context]
    local box = emblem.bounds
    local paintedWidth, paintedHeight = box[3]-box[1], box[4]-box[2]
    local scale = math.min(layout.width/paintedWidth, layout.height/paintedHeight)
    texture:ClearAllPoints()
    texture:SetPoint(layout.anchor, binding.parent, layout.anchor, layout.x, layout.y)
    texture:SetSize(paintedWidth*scale,paintedHeight*scale)
    texture:SetTexCoord(box[1]/emblem.width,box[3]/emblem.width,box[2]/emblem.height,box[4]/emblem.height)
    texture:SetVertexColor(1,1,1,1)
    texture:Show()
    binding.available = true
    return true
end

function Renderer:BindEmblem(parent, texture, context, skin)
    local binding = {parent=parent,texture=texture,context=context,skin=skin}
    self.emblems[#self.emblems+1] = binding
    self:PaintEmblem(binding)
    return binding
end

loadTexture = function(texture, path)
    local ok, loaded = pcall(texture.SetTexture, texture, path)
    return ok and loaded ~= false
end

local function hideParts(binding)
    for _, t in ipairs(binding.parts) do t:Hide() end
end

-- Extending edges and centers keep corners at their logical pixel size.
function Renderer:Paint(binding)
    hideParts(binding)
    if binding.enabled and not binding.enabled() then return end
    local skin = R:GetActiveSkin()
    local assets = self.assets[skin.key]
    local d = assets and assets.surfaces and assets.surfaces[binding.role]
    d = d and ((d.states and d.states[binding.state]) or d)
    if not d then
        if binding.fallback then binding.fallback:Show() end
        return
    end
    local width, height = binding.frame:GetWidth(), binding.frame:GetHeight()
    if not positive(width) or not positive(height) then return end
    local uv = d.uv or {0,1,0,1}
    local mode = d.mode or "stretch"
    local inset = d.insets or {0,0,0,0}
    local l,r,t,b = inset[1],inset[2],inset[3],inset[4]
    local used, failed = 0, false
    local function piece(x,y,w,h,u1,u2,v1,v2)
        if w <= 0 or h <= 0 then return end
        used = used+1
        local texture = binding.parts[used]
        if not texture then
            texture = binding.frame:CreateTexture(nil, binding.layer or "ARTWORK", nil, binding.sublevel or 0)
            binding.parts[used] = texture
        end
        if not loadTexture(texture, d.path) then failed = true; return end
        texture:ClearAllPoints()
        texture:SetPoint("TOPLEFT", binding.frame, "TOPLEFT", x, -y)
        texture:SetSize(w,h)
        texture:SetTexCoord(u1,u2,v1,v2)
        texture:SetVertexColor(1,1,1,1)
        texture:Show()
    end
    if mode == "nine" or mode == "three" then
        if mode == "three" then t,b = 0,0 end
        -- Shrink corners uniformly only for controls smaller than the cap pair.
        local scale = math.min(1, width / math.max(1,l+r), height / math.max(1,t+b))
        local xs = {0,l*scale,width-r*scale,width}
        local ys = {0,t*scale,height-b*scale,height}
        local us = {uv[1],uv[1]+l/d.width,uv[2]-r/d.width,uv[2]}
        local vs = {uv[3],uv[3]+t/d.height,uv[4]-b/d.height,uv[4]}
        for row=1,3 do
            for col=1,3 do
                piece(xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row],
                    us[col],us[col+1],vs[row],vs[row+1])
            end
        end
    elseif mode == "tile" then
        local tw,th = d.width*(uv[2]-uv[1]),d.height*(uv[4]-uv[3])
        for y=0,height-0.001,th do
            for x=0,width-0.001,tw do
                local w,h = math.min(tw,width-x),math.min(th,height-y)
                piece(x,y,w,h,uv[1],uv[1]+w/d.width,uv[3],uv[3]+h/d.height)
            end
        end
    elseif mode == "contain" then
        local aspect = d.width*(uv[2]-uv[1])/(d.height*(uv[4]-uv[3]))
        local w,h = width,width/aspect
        if h > height then w,h = height*aspect,height end
        piece((width-w)/2,(height-h)/2,w,h,uv[1],uv[2],uv[3],uv[4])
    else
        piece(0,0,width,height,uv[1],uv[2],uv[3],uv[4])
    end
    if failed then hideParts(binding) end
    if binding.fallback then
        if failed then binding.fallback:Show() else binding.fallback:Hide() end
    end
end

function Renderer:Bind(frame, role, fallback, layer, sublevel)
    local binding = {frame=frame,role=role,fallback=fallback,parts={},state="normal",
        layer=layer,sublevel=sublevel}
    self.surfaces[#self.surfaces+1] = binding
    function binding:SetState(state)
        self.state = states[state] and state or "normal"
        Renderer:Paint(self)
    end
    if frame.HookScript then frame:HookScript("OnSizeChanged", function() Renderer:Paint(binding) end) end
    self:Paint(binding)
    return binding
end

function Renderer:PaintIcon(binding)
    local assets = self.assets[R:GetActiveSkin().key]
    local icons = assets and assets.icons
    local texture = binding.texture
    local index = iconIndex[binding.name] or iconIndex.music
    if icons and loadTexture(texture, (icons.states and icons.states[binding.state]) or icons.path) then
        local col,row = index % 8,math.floor(index/8)
        -- Half-pixel UV inset prevents adjacent cell bleed.
        texture:SetTexCoord((col*64+0.5)/512,((col+1)*64-0.5)/512,
            (row*64+0.5)/256,((row+1)*64-0.5)/256)
        texture.customSkinIcon = true
        texture:SetVertexColor(1,1,1,1)
        return true
    end
    texture.customSkinIcon = false
    loadTexture(texture, MEDIA.."GuildRadioFM_Icons.tga")
    local legacy = legacyIcons[binding.name] or 15
    texture:SetTexCoord(legacy/16,(legacy+1)/16,0,1)
    return false
end

function Renderer:BindIcon(texture, name)
    local binding = {texture=texture,name=name,state="normal"}
    self.icons[#self.icons+1] = binding
    function binding:SetState(state)
        self.state = states[state] and state or "normal"
        return Renderer:PaintIcon(self)
    end
    function binding:SetIcon(value)
        self.name = value
        return Renderer:PaintIcon(self)
    end
    self:PaintIcon(binding)
    return binding
end

function Renderer:Refresh()
    for _, binding in ipairs(self.surfaces) do self:Paint(binding) end
    for _, binding in ipairs(self.icons) do self:PaintIcon(binding) end
    for _, binding in ipairs(self.emblems) do self:PaintEmblem(binding) end
end
