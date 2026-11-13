GuildRadioFM Changelog

v2.4.2 - GuildRadioFM Live

Live sets (Live tab, /grfm live):
- Go live and DJ for the guild. Everyone tuned in starts each song at the same moment: every client runs the
  server clock refined to frame precision, and the DJ schedules each song about a second ahead, so chat lag
  does not matter. Nothing is streamed; each player's own packaged copy plays.
- Tune in mid-song and you join at the next 30-second mark (pre-cut copies in Songs/_join, built by
  tools/make_joins.py; listed in JoinPoints.lua).
- Several DJs can be live at once; listeners pick a set.
- Pass host: hand the set to a listener (they accept on a card); the queue and everyone tuned in follow,
  the music never stops. /grfm pass <name>.
- Request Line: request a song or vote for one. 5 open requests each; waiting 3+ minutes goes first, then
  votes, then oldest. DJ: click to play, right-click to decline, shift-right-click to block for the set.
- Invite posts one line in guild chat and shows guildmates a Tune in card.
- Commands: /grfm live, /grfm dj, /grfm invite, /grfm pass <name>, /grfm endset, /grfm tune, /grfm tuneout, /grfm unblock

Interface:
- One window with tabs (Now Playing, Library, Playlists, Live, Settings) replaces the separate windows.
- Gold Morpheus title and rune emblem, dark glass over the game's own loading-screen art (Kalimdor,
  Eastern Kingdoms or plain), custom icon set (Media/, built by tools/make_art.py).
- Opens at 80% size; drag the corner grip or use Settings > Size (50-140%). Mini player, now-playing pop-up.

Compliance:
- The signature is a plain-text credit (Blizzard add-on policy: no obfuscated code).

v2.1.2 - Forever build (catch-up commit)

v0.6.4 - Ketho API Audit Repair Pass

- Hardened Retail Options panel opening with a safe fallback to the in-addon Settings window.
- Added resize-bound fallbacks for clients that expose older resize APIs.
- Guarded StopSound calls so stale sound handles cannot throw Lua errors.
- Sharing now confirms addon-message prefix registration before sending metadata, with tolerant Retail/legacy handling.
- Wrapped addon-message sends so bad channels or API failures report cleanly instead of erroring.

v0.6.3 - Tiny Mini Player

- Reduced the Mini Player again for combat-friendly placement.
- Tightened Mini Player button sizes, spacing, labels, and volume slider padding.
- Clamps previously oversized Mini Player saved dimensions down to the smaller layout.

v0.6.2 - Compact Mini Player

- Reduced the Mini Player default size.
- Compacted Mini Player spacing, buttons, status labels, and volume text.
- Clamps previously saved oversized Mini Player dimensions down to the compact layout on first open.

v0.6.1 - Loading Screen Playback Hotfix

- Stops active local playback when logging out, leaving world, or entering a loading screen.
- Clears stale sound handles during initialization and before starting a new track.
- Reduces cases where multiple tracks can overlap after reloads or loading screens.

v0.6.0 - Sharing and Broadcast Requests

- Added GuildRadioFM addon-message sharing prefix.
- Added now-playing metadata sharing for party, raid, instance, or guild channels.
- Added broadcast request messages for the current song.
- Added Sharing Requests inbox window.
- Added /grfm share, /grfm request, /grfm requests, and /grfm share status.
- Added Share button to the Maxi Player.
- Preserved v0.5.0 Seek Controls and v0.4.0 Queue System behavior.
- Note: sharing sends metadata only. WoW addons cannot transfer MP3 files or force another client to play audio.

v0.5.0 - Seek Controls

- Added seek-control framework for current-track elapsed time.
- Added Restart, -10, +10, and seek bar controls to the Maxi Player.
- Added /grfm restart and /grfm seek commands.
- Added single-line lyric display to the Mini Player.
- Preserved v0.4.0 Queue System behavior.
- Preserved Lyrics, Hidden Frequency, playlists, and local playback behavior.
- Note: WoW cannot truly seek inside MP3 playback through PlaySoundFile; v0.5.0 prepares the UI/framework for future companion-backed seeking.

v0.4.0 - Queue System

- Migrated GuildRadioFM to Semantic Versioning.
- Established GuildRadioFM.Version as the Lua source of truth.
- Keeps the Queue System release aligned with the new roadmap version v0.4.0.
- No gameplay, playback, lyrics, playlist, queue, or Hidden Frequency behavior changed in this migration.

Historical Version Migration

- v2.1.2 Hidden Frequency Vol. 1 is now v0.2.0.
- v2.2.0 Lyrics Polish is now v0.3.0.
- v2.3.0 Queue System is now v0.4.0.
