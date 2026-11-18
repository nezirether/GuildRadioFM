GuildRadioFM Changelog

## 2.8.1-rc.1

- Stop GuildRadioFM's active sound when leaving the world, opening a loading screen, or tearing down the UI for /reload.
- Suspend scheduled starts and duration advancement during world transitions. Coalesce world and loading-screen completion events, and restart a solo selection at most once while keeping its playlist or favorites context.
- Stop an active handle before duration-based advancement. An MP3 that runs longer than its library entry can no longer overlap the next track through this path.
- Keep a live room's timeline during a loading screen. Hosts and listeners who miss the start wait for the next scheduled song.
- Ignore server-clock samples across long frames. Surface local audio failures as unavailable tracks and clear the missing-track status when the host stops.
- Validate request and handoff fields before accepting their sequence, and require the matching listener identity for leave messages.
- Retain the safe RC2 tooltip callback logic and expand its regression cases with the skin module loaded.
- Add headless coverage for asymmetric latency, local file errors, reload cleanup and overlapping-audio regressions. See the test report for Forever checks still pending.

## 2.8.0-rc.2 - mini player

- Mini player: Previous button immediately left of Play/Stop (same Back action as the main window).
  It is a standard skinned icon button, so it follows every skin's colours and hover, and it drags the
  mini player like the other buttons.
- Mini player: slightly stronger dimming on the right so the controls stay readable over busy banners.
- No changes to skins' textures, audio, Live DJ rooms or saved settings.

## 2.8.0-rc.1 - skins

- New Skins tab with 13 skins: Trogdor (signature), Alliance, Horde, Undercity, Org, Stormwind,
  Thunder Bluff, Darnassus, Iron Forge, Blood Moon, Sleek, Classic (default) and Retail.
- Each skin has its own header banner, tiled background, crest and Now Playing flourish, plus tints for
  the shared forged frame corners, tab plates, button bevels, play disc and Live DJ badge (Media/Skins/Kit.tga).
- Skin art (banners, backgrounds, Now Playing flourishes and most crests) is cut from the owner's GRFM skin
  concept sheet by tools/import_concept.py. Faction emblems in the Alliance, Horde and Stormwind strips are
  covered with the skin's own crest. Banner art sits above the tab row so it is never hidden behind tabs.
- Trogdor signature skin: the concept's fire-breathing dragon banner, lava-stone background, dragon-head crest,
  flame flourish, charred-iron and bronze trim.
- Hover a skin card for a live preview of the whole addon; click to keep it. /grfm skins, /grfm skin <name>.
  The choice is saved in GuildRadioFMDB.skin; an unknown saved skin is left untouched and Classic is shown.
- Live DJ badge (forged pill + microphone) in the header tab row and on the Now Playing crest.
- Mini player shows the skin banner, crest and trim. Pop-up cards use the skin crest.
- Settings > Background "Forge" is now "Skin" (same saved key), so existing choices carry over.
- Join points are disabled in code as well as data: late listeners always wait for the next song.
- Removed unused GuildRadioFM_Forge.tga, GuildRadioFM_ForgeHeader.tga and GuildRadioFM_Icon.png.
- Added tests/ (headless Lua 5.1 suite) and tools/make_skins.py, tools/preview_skins.py.
- In-game testing remains required.

## 2.7.0-rc.3 - slim audio rollback (UI work baseline)

- Remove offset audio join points; late listeners now wait for the next song.
- Preserve the existing functioning Live DJ Rooms, standard synchronized song starts, and all original packaged audio.
- No additional audio segments or generator are included.
- In-game testing remains required.

## 2.7.0-rc.1

- Fix playlist rename and unavailable-control tooltip errors.
- Add a versioned room protocol with throttling, scoping and replay checks.
- Restore the solo queue, pack lyrics and Secret Frequency unlocks.
- Preserve existing user data during schema migration and restyle the player
  with original TGA textures.
- See RECOVERY.md for test coverage, compatibility and live verification.

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
