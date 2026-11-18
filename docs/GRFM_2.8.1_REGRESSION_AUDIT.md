# GuildRadioFM 2.8.1 regression audit

## Baseline

- GitHub main: 29df14b552c57c6846b37117484eab60381063ea (2.6.3).
- GitHub recovery: 843f722b0eb937348a529ca23e2764e521ad548b (2.7.0-rc.1).
- Supplied 2.8.0-rc.2 TEST SHA-256: 79f7c663ef5c487dd1ecfd8852a6101f5e9dfe2a34dcf7cf77d9d9b0c9b7c6a7.
- The ZIP build note references the recovery commit as its ancestor. The archive carries additional skin code, 13 skin choices and a mini-player Previous button. The adjacent 2.7.0-rc.4 archive has Previous but lacks the newer skins. The imported RC2 tracked snapshot is 1156834. The package supplies the original audio separately.
- The historical project path was unavailable. Development uses a fresh checkout on grfm/2.8.1. The original archives were read only.

## Initial findings

| Area | Finding |
| --- | --- |
| Tooltip crash | RC2 already evaluates callbacks explicitly and requires a nonempty string. The other SetText sites use a skin name and a literal label. Retain the existing guard and run the tooltip regression suite against RC2. |
| Scheduled playback | A listener can queue an on-time start, then cross a long frame or load before dispatch. Dispatch currently plays from the beginning even after the acceptable late window. |
| Local file failure | A matching title with a bad local path reaches PlaySoundFile, which clears playback but leaves the listener without the waiting/missing state. |
| Room state | A stopped room heartbeat can leave stale missing-track status. Request and reply handlers need sender checks consistent with room chat. |
| Existing coverage | Both inherited Lua 5.1 suites passed on the recovery branch before the RC2 import. The packaged RC2 does not include the Python suite named by its build note. |
| Player/UI | RC2 preserves the queue, favorites, editable playlists, lyrics, Secret Frequency, packs, and mini-player controls. Audibility, OS background audio, layout and actual loading transitions require Forever. |

## Audio transition report

Existing playback could orphan a sound handle in two ways. The live loading path discarded it while assuming the client had stopped the sound. Duration-based advancement also cleared the handle before starting the next track, even when the file outlasted its listed duration. UI teardown sent room messages but did not stop the current sound. The candidate stops its owned handle on teardown and world transitions, gates playback while loading, and stops the handle before duration-based advancement.

After a real load, solo playback can restart the same selection once. Room playback retains its timeline and waits for a future scheduled start if the current boundary passed. A previously orphaned handle from an older running build is outside the candidate's handle ownership. Live hosts still reopen their room manually after a disconnect or reload.

## RC2 findings and fixes

- RC1 assigned the Now Playing timestamp before transport submission. A blocked send could consume the entire lead. RC2 assigns the start on submission attempt, arms it on success, and honors the existing queue, limits, and retries. The announcement expires after eight seconds.
- A Request Line item used to be removed at selection time. RC2 consumes it when the announcement is submitted, so a send failure leaves it available.
- Host handoff now retains the advertised room name in memory. The new host's saved personal room name is used again for independently opened rooms.
- Metadata searches now work in the library and playlist picker. Locked Secret Frequency tracks stay out of the picker until they are available.
- A world-entry event could precede completion of the loading screen. RC2 waits for known loading and cinematic blocks to clear.
