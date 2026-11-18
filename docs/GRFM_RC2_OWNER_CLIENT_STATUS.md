# GuildRadioFM 2.8.1 RC2 owner-reported in-game status

Recorded 2026-11-18 from the owner's initial WoW Forever interface 16001 audit.

| Owner-reported result | Count |
| --- | --- |
| Features confirmed working | 33 |
| Features not yet tested | 17 |
| Confirmed broken | 0 |

No Lua errors or FPS issues were reported. These are owner-provided client results. The exact installed source commit and ZIP hash were not supplied with the report, so the results are attributed to the named 2.8.1 RC2 candidate. The frozen candidate ZIP in outputs has SHA-256 a4cec91952bc5fdb6fa0a239d0d71107da484ad0cd40494e85bd3f862db7ce6c.

## Confirmed working by owner

Basic playback, single-track playback during normal use, automatic advancement, library/search/custom song packs, playlist creation/editing, favorites, live room creation/joining, shared playback with approximately synchronized starts, selection of all thirteen skins, skin persistence/previews, mini-player, scaling, buttons/tooltips, normal stability and saved settings.

## Still unverified in the client

Recovery after reload and zoning, instance portal/cinematic recovery, playlist rename/persistence, queue reorder, room chat, Request Line/voting, host transfer, live reconnect after reload and missing-track behavior.

The owner reported seventeen untested features in total and provided the grouped areas above. The execution checklist below expands those areas into seventeen focused scenarios. It is a proposed test plan rather than the original feature-by-feature inventory.

## Release boundary

Keep the RC2 candidate frozen. Preserve confirmed behavior. Playback and network changes require reproduced evidence. Continue visual changes only on the separate UI branch. Merge and release remain pending critical recovery and multiplayer test results.

## Focused client checklist

Use two guild clients with the same RC2 build for multiplayer cases. Back up SavedVariables and record client build, addon version, tester, date, actual outcome and first Lua error. Enable Lua errors before testing. Leave the outcome blank until executed.

| # | Scenario | Expected observation | Result |
| --- | --- | --- | --- |
| 1 | Solo playback, reload, immediately select a different song | Old audio stops and only the newly selected track plays | Pending |
| 2 | Tuned listener reloads while host keeps playing | Remembered host can be rediscovered; listener waits for next start when late | Pending |
| 3 | Live host reloads and reopens the room | Teardown audio stops, room can reopen, listeners can follow rediscovery | Pending |
| 4 | Solo playback crosses a loading-screen zone transition | Playback recovers once with one audible track | Pending |
| 5 | Listener crosses a loading screen | Missed start waits for the next host song; no independent next-track jump | Pending |
| 6 | Host crosses a loading screen | No overlapping local sound; listeners retain the current room timeline | Pending |
| 7 | Enter and leave an instance portal while a song is audible | No stuck/duplicate audio through successive transitions | Pending |
| 8 | Cinematic or movie begins and ends during playback | Record actual RC2 behavior and audio continuity; repeat separately on UI candidate | Pending |
| 9 | Rename a user playlist through its actual rename control | Name updates with no Lua error | Pending |
| 10 | Reload after creating, editing and renaming a playlist | Playlist name, entries and order persist | Pending |
| 11 | Move local queue entry 2 to 1 with movequeue | Visible queue and subsequent playback follow the new order | Pending |
| 12 | Chat in two simultaneously open rooms | Message reaches only the selected room's participants | Pending |
| 13 | Request an installed track as listener | Correct host receives one Request Line entry | Pending |
| 14 | Two listeners vote and one repeats its vote | Count increases once per voter; duplicate vote is ignored | Pending |
| 15 | Offer, accept and decline host transfer | Accepted transfer preserves room/queue; declined transfer preserves original host | Pending |
| 16 | Listener lacks the host's selected local MP3 | Clear missing-track status, no incorrect local track, later available track can play | Pending |
| 17 | Disconnect host, wait for timeout, then reconnect and reopen | Listener stops following stale host state and can rediscover reopened room | Pending |

Actual audio recovery and multiplayer behavior in these cases remain unverified. Simulations are recorded separately in the existing test reports.
