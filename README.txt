GuildRadioFM v0.6.4

GuildRadioFM is a local-library-only World of Warcraft addon.

Put packaged music files here:
World of Warcraft/_retail_/Interface/AddOns/GuildRadioFM/Songs/

Then list them in SongList.lua with title, file, and optional duration entries.
Duration is required for auto-advance, progress, and seek behavior. The importer attempts to detect it automatically.

Easy importer:
- Open "GuildRadioFM Song Importer.html" in Chrome or Edge.
- Choose the GuildRadioFM addon folder when asked.
- Pick one or more MP3 files.
- The importer copies them into Songs and updates SongList.lua.
- The importer attempts to read MP3 duration automatically.
- Restart WoW or type /reload after importing.

Adding your own songs:
1. Close WoW or return to the character screen.
2. Copy MP3 files into:
   World of Warcraft/_retail_/Interface/AddOns/GuildRadioFM/Songs/
3. Open SongList.lua in the GuildRadioFM folder.
4. Add one line inside GuildRadioFMSongList for each song:
   { id = "guildradiofm:my-song", title = "My Song", file = "Interface\\AddOns\\GuildRadioFM\\Songs\\My Song.mp3", duration = 142.35 },
5. Save SongList.lua.
6. Fully restart WoW or type /reload.

Important:
- The file name in SongList.lua must match the MP3 file name exactly.
- Do not use D:\ paths, Downloads paths, Spotify links, YouTube links, or internet URLs.
- WoW only sees files packaged inside Interface/AddOns/GuildRadioFM.
- In-game upload is not possible in a normal WoW addon.

Notes:
- WoW addons can only play files packaged inside the addon folder.
- WoW addons cannot access arbitrary user files.
- Playback uses PlaySoundFile(track.file, "Dialog").
- Volume changes the global WoW Dialog channel.
- MP3 seeking is not available to addons.
- Lyrics v2 displays synced lyric lines in the Maxi Player.
- Album packs can register timed-table lyrics or LRC-style lyric text without editing the core addon.
- Queue v1 adds a lightweight Current Queue panel for future shared listening, guild DJ, and desktop companion features.
- Seek Controls v1 adds restart, skip-display controls, and a seek bar framework. WoW still cannot truly seek inside MP3 playback.
- Sharing v1 adds addon-message song metadata sharing and broadcast requests for party, raid, instance, or guild channels.

Lyrics test:
1. Install or update the addon, then restart WoW or type /reload.
2. Type /grfm lyrics test.
3. The Maxi Player opens and scrolls through built-in test lyrics.
4. Type /grfm lyrics status to check whether the current track has registered lyrics.

Secret Frequency:
GuildRadioFM contains optional music-themed Easter eggs. They do not affect normal addon use.

Queue:
1. Open the library with /grfm library.
2. Click a song once to select it.
3. Click Play Song to play it now, or Add To Queue to place it in Current Queue.
4. Open Current Queue with /grfm queue or the Queue button.
5. Remove individual queued songs with Remove, or clear the list with Clear Queue.
6. Play Next is framework-only. It prints the next queued song name and removes it from the queue for testing.

Seek Controls:
1. Play a song.
2. Use Restart to restart the current track.
3. Use -10 or +10 to move the displayed track position.
4. Drag the seek bar to update the displayed track position.
5. Slash commands also work:
   /grfm restart
   /grfm seek 60
   /grfm seek +10
   /grfm seek -10

Important seek limitation:
WoW's PlaySoundFile API does not support true MP3 seeking. These controls update GuildRadioFM's progress and lyric timing framework now, and prepare the addon for future real seeking through a desktop companion.

Sharing:
1. Join a party, raid, instance group, or guild.
2. Play or select a song.
3. Type /grfm share or click Share in the Maxi Player.
4. Other GuildRadioFM users in the channel can receive the shared song metadata.
5. Type /grfm request to broadcast a request for the current song.
6. Open the sharing inbox with /grfm requests.
7. Check status with /grfm share status.

Important sharing limitation:
GuildRadioFM can share song titles, artists, IDs, file paths, versions, and request metadata through WoW addon messages. It cannot send MP3 files, stream audio, or make another player hear your local playback.

Album-pack lyrics example:
GuildRadioFM.RegisterSongPack({
    packId = "my-album",
    packName = "My Album",
    songs = {
        {
            id = "my-album:first-song",
            title = "First Song",
            file = "Interface\\AddOns\\MyAlbum\\Songs\\First Song.mp3",
            duration = 180,
            lyrics = {
                { time = 0.0, text = "First lyric line" },
                { time = 5.2, text = "Second lyric line" },
                { time = 9.8, text = "Third lyric line" },
            },
        },
        {
            id = "my-album:lrc-song",
            title = "LRC Song",
            file = "Interface\\AddOns\\MyAlbum\\Songs\\LRC Song.mp3",
            duration = 120,
            lyrics = "[00:00.00]First lyric line\n[00:05.20]Second lyric line\n[00:09.80]Third lyric line",
        },
    },
    lyrics = {
        ["my-album:pack-level-song"] = {
            { time = 0.0, text = "First lyric line" },
            { time = 5.2, text = "Second lyric line" },
            { time = 9.8, text = "Third lyric line" },
        },
    },
})

Commands:
/grfm
/grfm play
/grfm stop
/grfm next
/grfm back
/grfm library
/grfm favorites
/grfm playliked
/grfm queue
/grfm queue status
/grfm queue clear
/grfm lyrics test
/grfm lyrics status
/grfm playlists
/grfm mini
/grfm settings
/grfm addsongs
/grfm shuffle
/grfm repeat
/grfm mute
/grfm autonext
/grfm favorite
/grfm unlike
/grfm volume 50
/grfm v 50
/grfm song 1
/grfm reset
/grfm help

Playlists:
- Open Playlists with /grfm playlists or the Playlists button.
- Create a playlist with the name box and New button.
- Open Library and right-click a song to add it to the selected playlist.
- Click a playlist song to play it.
- Selecting a playlist makes Play, Next, Back, and auto-next stay inside that playlist.
- Up and Down move the selected playlist song.
- Clear empties the selected playlist.
- Use Remove to take a song out of a playlist.
- Delete removes the selected playlist.

Mini player:
- Shows current song, source, playback progress, volume, mute, and like state.
- Like marks the current song as a local favorite.
- Unlike removes the current song from favorites.
- Liked songs are marked with * in the mini player and library.

Library:
- All shows every local song.
- Liked shows only favorited songs.
- Click a song once to select it.
- Use Play Song to play the selected song.
- Use Add To Queue to add the selected song to Current Queue.
- Right-click a song in Liked view to remove it from liked songs.
- The Unlike button removes the current song from liked songs.
- /grfm favorites opens the library in Liked view.
- Play Liked or /grfm playliked plays only liked songs; Next and Back stay inside liked songs.
- A small now-playing toast appears when playback starts.

Playlist controls:
- Single-click a playlist song to select it.
- Double-click a playlist song to play it.
- Play starts the selected playlist song.
