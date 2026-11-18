# GuildRadioFM 2.8.1 RC1 test report

Run from repository root using Python with lupa installed.

```text
python tests/run_tests.py
```

## Executed

- Lua 5.1 compilation of all 12 TOC modules and both Lua test files. The test harness loads the actual TOC in order and verifies interface 16001.
- Four independent mocked clients with shared server time, a 7.347-second local clock offset, 100/650 ms outbound delays, and 50 ms simulation steps. Actual mocked audio calls across two clients fall within 150 ms in the scheduled-start scenario.
- Parallel rooms, sender rejection and chat isolation, queue and duplicate votes, accepted handoff, spoofed handoff, disconnect timeout, reload/reconnect, and explicit host reopening.
- Missing library entries, local PlaySoundFile rejection, stopped-room cleanup, and waiting after a missed boundary.
- Audio overlap checks across listener and solo reload teardown, paired loading events, host zoning, and duration expiry. The audio mock keeps a sound active until explicitly stopped.
- SavedVariables migration and future schema handling, playlist and favorites storage, song registration, queue and lyrics, and tooltip rendering with the real skin helpers and playlist rename control.

## Forever verification pending

- With a track audible, run /reload, immediately start another track, then repeat across an instance portal or another zone with a loading screen. Confirm playback stops on departure and only one track is audible after recovery. Repeat with auto-next and a file longer than its listed duration.
- Repeat as host and listener. Exercise real roster and addon-message behavior, handoff, packet congestion, and network delay beyond the host's scheduling lead. Measure audible synchronization with two Forever clients.
- Check the actual sound handle and finish event behavior, volume and background audio, theme assets, mini-player dragging and controls, playlist editing, pop-up layout and scaling.
- Test song-pack installation and real local MP3 files. Interface metadata and the audio mock establish no live-client compatibility result.

## RC2 results

Both Lua 5.1 suites passed again. Added coverage for transport rejection followed by retry after the original scheduling lead, superseding an unsent track, bounded timeout, Request Line retention after timeout, and synchronized mock audio starts after retry. Also checked room-name preservation on host transfer, overlapping loading and cinematic events, malformed pack headers, metadata search through the library, and local queue reordering through the slash command.

Live tests still need to exercise actual C_ChatInfo return values and listener receipt, loading/cinematic event order, audio devices, and UI layout. A successful API submission establishes no per-listener acknowledgment. The fixed scheduling lead remains 1.2 seconds from transmission, so listeners who receive it too late wait for the next start.

## Owner's initial Forever audit

The owner reports 33 working features, 17 untested and 0 confirmed broken, with no reported Lua errors or FPS issues on interface 16001. GRFM_RC2_OWNER_CLIENT_STATUS.md records the confirmed areas and a focused client checklist. Recovery and critical multiplayer edge cases remain pending. This owner report applies to the named RC2 candidate and does not establish visual acceptance of the separate UI builds.
