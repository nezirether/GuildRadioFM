# GuildRadioFM recovery candidate

The repair starts from v2.6.3 (`29df14b552c57c6846b37117484eab60381063ea`).
The v0.6.4 reference is `b81cc3675fdca903622e1ac4ab938c0c441a1891`.
That revision's TOC lists five split legacy modules absent from its tree. Local
copies of Lyrics, HiddenFrequency and Queue supplied additional behavioral
reference. The two ZIPs named in the brief were unavailable for direct comparison.

| Feature | v0.6.4 reference | v2.6.3 baseline | 2.7.0-rc.1 |
| --- | --- | --- | --- |
| Local playback and library | Flat code and split-module TOC | Local Dialog-channel audio, favorites, playlists and song packs | Preserves those controls, checks the active sound handle and reports missing files |
| Lyrics and hidden tracks | Legacy local modules | No equivalent lyrics/secret-frequency flow | Timestamped pack lyrics and persistent unlocks for tracks flagged by packs. No embedded lyric library or new hidden audio |
| Queue | Legacy local Queue module | Room Request Line | Restores a persistent solo queue alongside the separate room request queue |
| Seek and sharing | Legacy TOC lists missing Seek and Sharing modules | Indexed pre-cut files and live metadata | Preserves local pre-cuts and room metadata. Arbitrary seek and legacy sharing behavior remain unverified |
| Live rooms and DJs | No equivalent verified | Multiple host rooms, invitations, transfers and local synchronized copies | Versioned transport, bounded/throttled traffic, playback ordering and heartbeat reconciliation |
| Chat and Request Line | No equivalent verified | Room chat, request votes and DJ management | Host relays chat only to current members. Request snapshots preserve voter identities across an accepted transfer |
| Settings and UI | Local player controls | Scalable window, mini-player, tabs and settings | Preserves these surfaces with scorched iron, bronze and crimson art, plus queue and lyric controls |

## Regression report

- Tooltip callbacks returning nil or false could fall back to the callback
  itself. Explicit evaluation and a nonempty-string guard fix the rename-hover
  crash. Hover and OnLeave cleanup still run.
- Initialization keeps valid playlists, favorites, unlocks and unknown fields.
  Unexpected values are retained under `recoveryValues`. Future schema
  versions are left intact. Reset applies to scalar settings and retains
  library and queue data.
- A stale sound completion event cannot advance a replacement sound. A loading
  screen without an eligible pre-cut keeps the live DJ timeline and local audio
  resumes on the next track. Solo playback may restart at the beginning.
- The transport checks guild roster identity, frame size, protocol version and
  sequence order. Protocol 3 requires the candidate on each room participant's
  client. Room chat and requests depend on guild roster availability.
- Host timeout stops the listener's old playback and remembers the host for
  reconnection. The host must reopen the room. Automatic host election, separate
  moderator roles and acknowledged host transfer are not implemented. Transfer
  waits for local transport acceptance, which does not guarantee delivery.
- Built-in volume controls explicitly change WoW's Dialog channel. Mute stops
  addon audio. The optional background playback setting uses a global WoW CVar.
- License and release status of locally held audio were outside the Git change.
  The test ZIP includes the 15 local stock tracks. Noyze Komplaynt pack MP3s
  and pre-cut audio are absent and may be supplied with their matching installed
  packs. Song definitions and existing pre-cut metadata are retained.

## Verification

From the addon source directory, run `lua5.1 tests/tooltips.lua` and
`lua5.1 tests/recovery.lua`. Both passed under an embedded Lua 5.1 runtime.
The first constructs the actual playlist page on mocked frames. The second
simulates four guild members at different message delays and uses mocked audio
handles and a shared server clock. It covers migration, locks, queue, lyrics,
packs, room switching, chat isolation, stale and oversized packets, throttling,
missing song metadata, voting and transfer, plus host loss and reopen. TOC
files, Lua syntax and packaged media were also checked statically.

## WoW Forever checklist

1. Back up the addon and its SavedVariables. Install into a test client
   AddOns directory, keeping custom songs and separately installed packs.
2. Confirm Interface 16001 loads with script errors enabled. Open all five
   tabs and hover the rename button with no playlist, a read-only pack and a
   normal playlist. Verify drag, scaling, mini-player and font fit.
3. Check local track starts, stop, mute, volume, progression, zone changes
   and background playback. Test a missing MP3 and a silent/invalid file.
4. Migrate a copy of real SavedVariables. Check playlists, favorites, queue,
   track references, pack registration, lyrics and hidden-track filtering.
5. With at least three guild accounts, open two rooms and start the same
   locally installed track on host and listener. Check late join with
   matching pre-cuts and with absent pre-cuts, then confirm next-track recovery.
6. Exercise invites, room-specific chat, duplicate votes, request approval,
   host transfer, host disconnect/reopen, reload and mixed protocol builds.
7. Repeat playback in the background and across zone transitions. Verify
   unrelated WoW audio settings and check layout at your normal UI scale.

No WoW client was launched for this candidate.
