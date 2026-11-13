GuildRadioFM v1.0.0

GuildRadioFM is a local-library-only World of Warcraft addon.

Put packaged music files here:
World of Warcraft/_retail_/Interface/AddOns/GuildRadioFM/Songs/

Then list them in SongList.lua with title, file, and optional duration entries.

Easy importer:
- Open "GuildRadioFM Song Importer.html" in Chrome or Edge.
- Choose the GuildRadioFM addon folder when asked.
- Pick one or more MP3 files.
- The importer copies them into Songs and updates SongList.lua.
- Restart WoW or type /reload after importing.

Adding your own songs:
1. Close WoW or return to the character screen.
2. Copy MP3 files into:
   World of Warcraft/_retail_/Interface/AddOns/GuildRadioFM/Songs/
3. Open SongList.lua in the GuildRadioFM folder.
4. Add one line inside GuildRadioFMSongList for each song:
   { title = "My Song", file = "Interface\\AddOns\\GuildRadioFM\\Songs\\My Song.mp3" },
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

Commands:
/grfm
/grfm play
/grfm stop
/grfm next
/grfm back
/grfm library
/grfm favorites
/grfm playliked
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
- Right-click a song in Liked view to remove it from liked songs.
- The Unlike button removes the current song from liked songs.
- /grfm favorites opens the library in Liked view.
- Play Liked or /grfm playliked plays only liked songs; Next and Back stay inside liked songs.
- A small now-playing toast appears when playback starts.

Playlist controls:
- Single-click a playlist song to select it.
- Double-click a playlist song to play it.
- Play starts the selected playlist song.
