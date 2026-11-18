# Reference addon review

Source inspection of the five supplied archives. Playback and compatibility claims below describe the shipped code and metadata.

| Reference | Playback, library and UI | Shared listening and compatibility |
| --- | --- | --- |
| EpicMusicPlayer 8.9 | `core/player.lua` selects PlayMusic or handled PlaySoundFile. Its playlist manager, full player, broker, OSD and separate game-music packs organize catalogs and controls. `core/musicevent.lua` is an entry point for situation-driven music. | The package includes AceComm and its throttle library. No GuildRadioFM-style rooms, host transfer or room queue were identified. Mainline and expansion-specific manifests use other interface numbers. |
| EpicMusicPlayer MP3 2.18.1 | `CustomMusic.lua` is a generated local playlist with filenames, title, artist, album and duration. It obtains the parent player through AceAddon and supplies metadata consumed by that player. | The companion delegates sound, controls and runtime behavior to EpicMusicPlayer. Its manifests target EpicMusicPlayer's client variants. Keep local GRFM pack IDs and registration independent of AceAddon. |
| MaliMusicPlayer 0.8.9 | `Library.lua` and `Player.lua` provide a local player with compact and tabbed views, background preferences and audio controls. A silence track suppresses default music as handled track audio plays on Music. | No room transport, remote queues or voting identified. Its TOC includes 16001. The Music-channel and silence-track approach would change how GRFM interacts with the client's music settings. |
| RatRadio 2.4.8 | `Player.lua` owns its local sound and tracks world/loading/cinematic transitions. Separate library, lyrics, themes and voting modules drive the player and UI. | `Party.lua` derives song position from a leader-owned session timeline. `PartyVote.lua` identifies session and round in vote messages. `Transport.lua` queues guarded whispers. Its 120105/120107 client assumptions, group-leader APIs and recovery semantics require independent Forever validation. |
| KalimdorZugZugRadio 1.5.0 | `Player.lua` uses PlayMusic and client-specific music catalogs. `Rules.lua` handles encounters, zones and context changes, while the library, settings and banner modules expose playback selection and status. | No room or voting transport identified in the shipped modules. TOC lists 16001 and 120105 and identifies MIT. FileDataIDs and context event behavior can differ between clients. |

## Implications for GuildRadioFM

- RatRadio's sound ownership and repeat-safe transition handling informed the 2.8.1 fix. GuildRadioFM continues to use its own sound handle and Wire protocol. A listener who misses the scheduled start waits for the next track.
- RatRadio's round identity is relevant to future shared voting work. GuildRadioFM already scopes requests by receiving host and passes the current Request Line queue during an accepted handoff.
- EpicMusicPlayer's metadata companion illustrates why playlists and local audio can ship separately. GuildRadioFM already has a pack registration API, stable local identifiers, and optional lyrics.
- Kalimdor's rules are a useful reference for future opt-in situational playback. Rules would need independent validation of Forever events and should respect a listener's room selection.

All observations come from the supplied versions. The candidate incorporates independently written changes and ships GuildRadioFM source, inherited art, and audio from the supplied GuildRadioFM archive.

## 2.8.1 RC2 source comparison

### EpicMusicPlayer 8.9

- `core/player.lua` switches between PlayMusic and handled PlaySoundFile on Ambience. `core/core.lua` cancels the previous entry timer and schedules one five-second world-entry action. If its PlayMusic backend was running, it replays the current song. Its handled backend follows the zone-entry path.
- `core/listmanagement.lua` separates queue, history and playlist selection, and copies artist and album when duplicating entries. GRFM now searches optional metadata and can reorder its persisted local queue without modifying playlists.
- `core/musicevent.lua` can select a configured boss playlist. Its profile, Ace dependencies and game-music catalogs belong to its own runtime. GRFM uses its existing UI and configuration.

### EpicMusicPlayer MP3 2.18.1

- `CustomMusic.lua` is a generator-produced catalog registered with the parent. It describes title, filename, artist, album and track length. Playback and zone behavior remain with EpicMusicPlayer.
- GRFM's equivalent remains its local pack API. Search spans title, artist, album and pack name. Invalid pack headers fail cleanly, while song files continue to come from the local installation.

### MaliMusicPlayer 0.8.9

- `Player.lua` gives one module ownership of the sound handle. It plays a silence file as game music and plays the selected track separately through PlaySoundFile. World loading gates the playback tick. When loading ends, it updates the clock and reapplies silence after a delay, without replaying the track in that handler. On PLAYER_LOGOUT it stops its handle and stops game music.
- GRFM retains its Dialog-channel handle and explicitly gates audio across overlapping loading and cinematic events. Its own stop and recovery paths avoid altering unrelated music.

### RatRadio 2.4.8

- `Transport.lua` resolves actual group members, chunks playlist/control messages, tracks receipts, and prioritizes STOP and READY. `Party.lua` derives the current track occurrence from a session epoch, while `PartyVote.lua` scopes votes to a session and round. A stalled tick past the allowed offset waits for the next occurrence.
- `Player.lua` flags loading, world and cinematic events and debounces local recovery. For a loading interruption in a party, it replays the interrupted song from the beginning and marks the current occurrence handled until the next shared boundary. `Core.lua` stops audio and clears temporary party playlists on PLAYER_LOGOUT. The in-memory ticker session disappears on reload.
- GRFM keeps its current guild protocol and packet bounds. The host computes a fresh start on each transmission attempt and only arms playback after successful submission. A timed-out request stays queued. Loading listeners preserve the room timeline and wait if they miss the boundary.

### KalimdorZugZugRadio 1.5.0

- `Core.lua` invalidates a cached map hierarchy on zone and world events. `Rules.lua` uses encounter events, combat, travel, resting and other player context to select music with delayed downgrades. `Player.lua` has separate playback, rules, and volume concerns. Its ability to select built-in music depends on client-specific catalog entries.
- GRFM used the context-gating idea for loading and cinematics. Automatic combat, travel and zone playlists remain outside this release. Such a mode would need explicit priority and interaction rules for an active guild room.
