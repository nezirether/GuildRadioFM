-- GuildRadioFM skin registry. Pure data plus lookups; UI.lua applies a skin.
--
-- A skin is a palette (the same keys as UI.lua's colour table), tints for the shared
-- Kit.tga parts (frame metal, tabs, Live DJ badge) and four small textures of its own:
--   <key>_banner.tga 512x64   header and mini-player scene
--   <key>_tile.tga   128x128  seamless background, tiled behind the window
--   <key>_crest.tga  128x128  emblem (Now Playing, mini player, pop-up cards)
--   <key>_decor.tga  128x64   Now Playing flourish
-- Banners, tiles, flourishes and most crests are cut from the owner's concept sheet by
-- tools/import_concept.py; tools/make_skins.py makes the shared kit and fallback crests.
local R = GuildRadioFM

local MEDIA = "Interface\\AddOns\\GuildRadioFM\\Media\\"
local DIR = MEDIA .. "Skins\\"

R.SKIN_DEFAULT = "classic"
R.SKIN_KIT = DIR .. "Kit.tga"
-- pixel regions inside the 256x256 Kit.tga (mirrors KIT in tools/make_skins.py)
R.SKIN_KIT_REGIONS = {
    corner = { 0, 0, 64, 64 },
    edgeH = { 64, 0, 256, 16 },
    edgeV = { 0, 64, 16, 256 },
    button = { 64, 16, 256, 48 },
    tab = { 64, 48, 256, 80 },
    badge = { 64, 80, 192, 112 },
    disc = { 192, 80, 256, 144 },
    glow = { 128, 144, 192, 208 },
    rule = { 16, 224, 256, 240 },
    shine = { 16, 240, 256, 256 },
}

function R.KitCoords(name)
    local r = R.SKIN_KIT_REGIONS[name]
    if not r then return 0, 1, 0, 1 end
    return r[1] / 256, r[3] / 256, r[2] / 256, r[4] / 256
end

local MORPHEUS, FRIZ = "Fonts\\MORPHEUS.TTF", "Fonts\\FRIZQT__.TTF"

-- palette shorthand: { bg, shade, surface, raised, line, text, dim, faint, acc, acc2, live }
local function P(t)
    return {
        bg = t.bg, shade = t.shade or { 0.02, 0.02, 0.02, 0.55 }, surface = t.surface, raised = t.raised,
        line = t.line, text = t.text, dim = t.dim, faint = t.faint, acc = t.acc, acc2 = t.acc2, live = t.live,
    }
end

local function A(key, extra)
    local a = {
        banner = DIR .. key .. "_banner.tga",
        tile = DIR .. key .. "_tile.tga",
        crest = DIR .. key .. "_crest.tga",
        decor = DIR .. key .. "_decor.tga",
    }
    for k, v in pairs(extra or {}) do a[k] = v end
    return a
end

R.SkinList = {
    { key = "trogdor", name = "Trogdor", tag = "Signature", blurb = "Keepers of Trogdor: fire-breathing dragon, lava stone, charred iron.",
      art = A("trogdor"), font = MORPHEUS,
      metal = { 0.62, 0.42, 0.26 }, tab = { 0.8, 0.14, 0.06 }, tabOff = { 0.24, 0.1, 0.07 }, badge = { 0.66, 0.1, 0.05 }, bevel = 0.85, tileAlpha = 0.8,
      palette = P { bg = { 0.04, 0.025, 0.02, 0.97 }, shade = { 0.02, 0.01, 0.01, 0.62 }, surface = { 0.09, 0.04, 0.03, 0.9 }, raised = { 0.28, 0.07, 0.04, 0.98 },
        line = { 0.85, 0.42, 0.16, 0.5 }, text = { 0.98, 0.93, 0.86, 1 }, dim = { 0.76, 0.62, 0.52, 1 }, faint = { 0.52, 0.42, 0.35, 1 },
        acc = { 1, 0.62, 0.2, 1 }, acc2 = { 1, 0.85, 0.35, 1 }, live = { 1, 0.3, 0.18, 1 } } },
    { key = "alliance", name = "Alliance", blurb = "Royal blue and gold heraldry.",
      art = A("alliance"), font = MORPHEUS,
      metal = { 0.86, 0.68, 0.3 }, tab = { 0.14, 0.32, 0.74 }, tabOff = { 0.1, 0.14, 0.27 }, badge = { 0.13, 0.3, 0.7 }, bevel = 0.8, tileAlpha = 0.6,
      palette = P { bg = { 0.03, 0.05, 0.1, 0.97 }, surface = { 0.06, 0.09, 0.18, 0.9 }, raised = { 0.1, 0.18, 0.38, 0.98 },
        line = { 0.85, 0.7, 0.32, 0.5 }, text = { 0.95, 0.95, 1, 1 }, dim = { 0.7, 0.74, 0.84, 1 }, faint = { 0.46, 0.5, 0.6, 1 },
        acc = { 0.98, 0.8, 0.36, 1 }, acc2 = { 0.45, 0.75, 1, 1 }, live = { 0.45, 0.72, 1, 1 } } },
    { key = "horde", name = "Horde", blurb = "Spiked iron and war-red cloth.",
      art = A("horde"), font = MORPHEUS,
      metal = { 0.44, 0.42, 0.41 }, tab = { 0.68, 0.08, 0.06 }, tabOff = { 0.17, 0.12, 0.11 }, badge = { 0.62, 0.06, 0.05 }, bevel = 0.85, tileAlpha = 0.7,
      palette = P { bg = { 0.04, 0.03, 0.03, 0.97 }, surface = { 0.1, 0.05, 0.04, 0.9 }, raised = { 0.28, 0.05, 0.04, 0.98 },
        line = { 0.65, 0.18, 0.12, 0.55 }, text = { 0.96, 0.92, 0.88, 1 }, dim = { 0.72, 0.64, 0.58, 1 }, faint = { 0.5, 0.44, 0.4, 1 },
        acc = { 0.98, 0.3, 0.2, 1 }, acc2 = { 1, 0.6, 0.32, 1 }, live = { 1, 0.26, 0.2, 1 } } },
    { key = "undercity", name = "Undercity", blurb = "Crypt stone, plague green, violet gloom.",
      art = A("undercity"), font = MORPHEUS,
      metal = { 0.5, 0.45, 0.56 }, tab = { 0.26, 0.56, 0.12 }, tabOff = { 0.14, 0.1, 0.18 }, badge = { 0.3, 0.6, 0.12 }, bevel = 0.8, tileAlpha = 0.65,
      palette = P { bg = { 0.03, 0.03, 0.04, 0.97 }, surface = { 0.06, 0.07, 0.06, 0.9 }, raised = { 0.14, 0.08, 0.2, 0.98 },
        line = { 0.45, 0.85, 0.25, 0.45 }, text = { 0.92, 0.96, 0.88, 1 }, dim = { 0.64, 0.72, 0.6, 1 }, faint = { 0.42, 0.48, 0.4, 1 },
        acc = { 0.55, 0.95, 0.25, 1 }, acc2 = { 0.72, 0.48, 0.96, 1 }, live = { 0.55, 1, 0.3, 1 } } },
    { key = "org", name = "Org", blurb = "Red earth, timber and tusk.",
      art = A("org"), font = MORPHEUS,
      metal = { 0.58, 0.4, 0.25 }, tab = { 0.72, 0.15, 0.07 }, tabOff = { 0.26, 0.12, 0.07 }, badge = { 0.7, 0.14, 0.07 }, bevel = 0.85, tileAlpha = 0.65,
      palette = P { bg = { 0.06, 0.03, 0.02, 0.97 }, surface = { 0.14, 0.06, 0.04, 0.9 }, raised = { 0.36, 0.1, 0.05, 0.98 },
        line = { 0.85, 0.45, 0.2, 0.5 }, text = { 0.98, 0.92, 0.84, 1 }, dim = { 0.76, 0.62, 0.5, 1 }, faint = { 0.52, 0.42, 0.34, 1 },
        acc = { 1, 0.55, 0.22, 1 }, acc2 = { 1, 0.78, 0.4, 1 }, live = { 1, 0.3, 0.2, 1 } } },
    { key = "stormwind", name = "Stormwind", blurb = "White stone keep under a blue sky.",
      art = A("stormwind"), font = MORPHEUS,
      metal = { 0.88, 0.75, 0.42 }, tab = { 0.18, 0.38, 0.8 }, tabOff = { 0.14, 0.18, 0.3 }, badge = { 0.16, 0.36, 0.78 }, bevel = 0.8, tileAlpha = 0.55,
      palette = P { bg = { 0.05, 0.07, 0.12, 0.97 }, surface = { 0.08, 0.11, 0.2, 0.9 }, raised = { 0.16, 0.24, 0.45, 0.98 },
        line = { 0.9, 0.78, 0.45, 0.5 }, text = { 0.97, 0.97, 1, 1 }, dim = { 0.74, 0.78, 0.88, 1 }, faint = { 0.5, 0.54, 0.64, 1 },
        acc = { 1, 0.85, 0.45, 1 }, acc2 = { 0.55, 0.8, 1, 1 }, live = { 0.45, 0.75, 1, 1 } } },
    { key = "thunderbluff", name = "Thunder Bluff", blurb = "Tanned hide, totem teal, feathers.",
      art = A("thunderbluff"), font = MORPHEUS,
      metal = { 0.62, 0.46, 0.3 }, tab = { 0.1, 0.48, 0.46 }, tabOff = { 0.26, 0.18, 0.11 }, badge = { 0.1, 0.5, 0.48 }, bevel = 0.85, tileAlpha = 0.6,
      palette = P { bg = { 0.07, 0.05, 0.03, 0.97 }, surface = { 0.16, 0.11, 0.07, 0.9 }, raised = { 0.3, 0.2, 0.12, 0.98 },
        line = { 0.3, 0.75, 0.7, 0.5 }, text = { 0.98, 0.94, 0.86, 1 }, dim = { 0.78, 0.7, 0.58, 1 }, faint = { 0.55, 0.48, 0.4, 1 },
        acc = { 0.38, 0.88, 0.82, 1 }, acc2 = { 1, 0.78, 0.4, 1 }, live = { 0.35, 0.9, 0.85, 1 } } },
    { key = "darnassus", name = "Darnassus", blurb = "Moonlit violet boughs and silver.",
      art = A("darnassus"), font = MORPHEUS,
      metal = { 0.62, 0.57, 0.76 }, tab = { 0.44, 0.24, 0.7 }, tabOff = { 0.16, 0.11, 0.24 }, badge = { 0.44, 0.24, 0.7 }, bevel = 0.75, tileAlpha = 0.6,
      palette = P { bg = { 0.05, 0.03, 0.08, 0.97 }, surface = { 0.09, 0.06, 0.15, 0.9 }, raised = { 0.24, 0.14, 0.38, 0.98 },
        line = { 0.75, 0.6, 1, 0.45 }, text = { 0.96, 0.94, 1, 1 }, dim = { 0.76, 0.72, 0.86, 1 }, faint = { 0.52, 0.48, 0.62, 1 },
        acc = { 0.82, 0.66, 1, 1 }, acc2 = { 0.6, 0.95, 0.75, 1 }, live = { 0.82, 0.6, 1, 1 } } },
    { key = "ironforge", name = "Iron Forge", blurb = "Mountain stone and forge fire.",
      art = A("ironforge"), font = MORPHEUS,
      metal = { 0.54, 0.52, 0.5 }, tab = { 0.76, 0.36, 0.08 }, tabOff = { 0.2, 0.17, 0.14 }, badge = { 0.72, 0.32, 0.06 }, bevel = 0.85, tileAlpha = 0.65,
      palette = P { bg = { 0.05, 0.045, 0.04, 0.97 }, surface = { 0.1, 0.09, 0.08, 0.9 }, raised = { 0.22, 0.17, 0.13, 0.98 },
        line = { 0.95, 0.6, 0.2, 0.45 }, text = { 0.98, 0.94, 0.88, 1 }, dim = { 0.76, 0.7, 0.62, 1 }, faint = { 0.52, 0.48, 0.42, 1 },
        acc = { 1, 0.66, 0.22, 1 }, acc2 = { 1, 0.85, 0.45, 1 }, live = { 1, 0.42, 0.15, 1 } } },
    { key = "bloodmoon", name = "Blood Moon", blurb = "Crimson sky over black spires.",
      art = A("bloodmoon"), font = MORPHEUS,
      metal = { 0.38, 0.32, 0.34 }, tab = { 0.7, 0.04, 0.08 }, tabOff = { 0.18, 0.05, 0.07 }, badge = { 0.7, 0.04, 0.08 }, bevel = 0.85, tileAlpha = 0.7,
      palette = P { bg = { 0.05, 0.01, 0.02, 0.97 }, surface = { 0.1, 0.02, 0.03, 0.9 }, raised = { 0.3, 0.03, 0.05, 0.98 },
        line = { 0.8, 0.1, 0.15, 0.5 }, text = { 0.98, 0.9, 0.9, 1 }, dim = { 0.76, 0.6, 0.62, 1 }, faint = { 0.52, 0.4, 0.42, 1 },
        acc = { 1, 0.24, 0.26, 1 }, acc2 = { 1, 0.52, 0.5, 1 }, live = { 1, 0.2, 0.25, 1 } } },
    { key = "sleek", name = "Sleek", blurb = "Dark glass with neon edges.",
      art = A("sleek"), font = FRIZ,
      metal = { 0.36, 0.42, 0.55 }, tab = { 0.12, 0.45, 0.95 }, tabOff = { 0.1, 0.12, 0.17 }, badge = { 0.55, 0.25, 0.85 }, bevel = 0.35, tileAlpha = 0.7,
      palette = P { bg = { 0.03, 0.035, 0.05, 0.97 }, surface = { 0.06, 0.07, 0.1, 0.9 }, raised = { 0.12, 0.14, 0.2, 0.98 },
        line = { 0.35, 0.55, 1, 0.4 }, text = { 0.95, 0.97, 1, 1 }, dim = { 0.66, 0.7, 0.8, 1 }, faint = { 0.44, 0.48, 0.58, 1 },
        acc = { 0.3, 0.75, 1, 1 }, acc2 = { 0.75, 0.45, 1, 1 }, live = { 0.8, 0.42, 1, 1 } } },
    { key = "classic", name = "Classic", tag = "Default", blurb = "Burned parchment, bronze and gold.",
      art = A("classic", { crest = MEDIA .. "GuildRadioFM_Emblem.tga" }), font = MORPHEUS,
      metal = { 0.74, 0.58, 0.36 }, tab = { 0.72, 0.42, 0.12 }, tabOff = { 0.26, 0.2, 0.14 }, badge = { 0.72, 0.42, 0.12 }, bevel = 0.8, tileAlpha = 0.45,
      palette = P { bg = { 0.09, 0.07, 0.05, 0.97 }, surface = { 0.17, 0.13, 0.09, 0.9 }, raised = { 0.32, 0.24, 0.15, 0.98 },
        line = { 0.85, 0.68, 0.38, 0.5 }, text = { 0.98, 0.95, 0.88, 1 }, dim = { 0.8, 0.72, 0.6, 1 }, faint = { 0.58, 0.5, 0.42, 1 },
        acc = { 1, 0.78, 0.3, 1 }, acc2 = { 0.5, 0.9, 0.55, 1 }, live = { 1, 0.32, 0.36, 1 } } },
    { key = "retail", name = "Retail", blurb = "Twilight navy with a gold sweep.",
      art = A("retail"), font = MORPHEUS,
      metal = { 0.82, 0.66, 0.3 }, tab = { 0.16, 0.32, 0.78 }, tabOff = { 0.1, 0.13, 0.26 }, badge = { 0.18, 0.36, 0.8 }, bevel = 0.75, tileAlpha = 0.6,
      palette = P { bg = { 0.03, 0.04, 0.1, 0.97 }, surface = { 0.06, 0.08, 0.18, 0.9 }, raised = { 0.12, 0.16, 0.36, 0.98 },
        line = { 0.55, 0.7, 1, 0.45 }, text = { 0.96, 0.97, 1, 1 }, dim = { 0.72, 0.76, 0.9, 1 }, faint = { 0.48, 0.52, 0.66, 1 },
        acc = { 0.98, 0.8, 0.36, 1 }, acc2 = { 0.5, 0.75, 1, 1 }, live = { 0.45, 0.7, 1, 1 } } },
}

R.SkinByKey = {}
for i, s in ipairs(R.SkinList) do
    s.index = i
    R.SkinByKey[s.key] = s
end

-- lenient lookup: key, display name, or name without spaces ("thunder bluff", "ThunderBluff", "iron forge")
function R:FindSkin(name)
    if type(name) ~= "string" then return nil end
    local want = string.gsub(string.lower(name), "[%s_%-]", "")
    for _, s in ipairs(self.SkinList) do
        if s.key == want or string.gsub(string.lower(s.name), "[%s_%-]", "") == want then return s end
    end
end

-- the saved skin, or the default when the saved key is unknown (kept untouched for newer builds)
function R:GetActiveSkin()
    local key = self.previewSkin or (self.db and self.db.skin)
    return self.SkinByKey[key] or self.SkinByKey[self.SKIN_DEFAULT]
end
