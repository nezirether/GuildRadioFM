-- Noyze Komplaynt song pack. The files ship inside the addon (Songs\Noyze Komplaynt\),
-- so everyone tuned in to a DJ set has the same tracks.
local folder = "Interface\\AddOns\\GuildRadioFM\\Songs\\Noyze Komplaynt\\"

GuildRadioFM.RegisterSongPack({
    packId = "noyze-komplaynt",
    packName = "Noyze Komplaynt",
    playlistName = "Noyze Komplaynt",
    songs = {
        { title = "Lost in the Music", artist = "Noyze Komplaynt", file = folder .. "Lost in the Music.mp3", duration = 143 },
    },
})
