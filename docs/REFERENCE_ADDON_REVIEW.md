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
