# Cap (Raycast)

Fire off a Cap recording with your preset settings and get the share link on your
clipboard, without touching the Cap UI.

Drives the `cap-cli` binary bundled inside Cap.app, so anything the CLI can capture this
extension can capture.

## The command

**Record a Cap** — one no-view command that toggles. Nothing running, it starts an
instant recording with your preset. Something running, it stops, waits for the upload
and puts the `cap.so/s/…` link on your clipboard. Bind it to a hotkey; that is the whole
extension.

## Defaults

Out of the box: primary screen, microphone + system audio on, share link copied to the
clipboard. All of it is editable in Raycast's extension preferences.

The microphone is matched by name (substring, case-insensitive). **Leave the field blank
to record without it** — that is the off switch. A name that matches nothing aborts the
recording rather than quietly dropping the mic.

## No camera

Instant mode has no camera track — not through the CLI, and not in Cap.app either. An
app-made instant recording contains exactly `content/display` and `content/audio`, same
as this extension's. Your face gets into an app recording because Cap Desktop floats a
camera preview window on screen and the _screen_ capture picks it up.

There is no GUI here, so there is no window, so there is no face. `cap record start`
accepts `--camera` in instant mode and silently ignores it; the only thing that flag can
drive is the `camera.mp4` that studio recordings write. The extension no longer offers a
Camera preference rather than pretend otherwise.

For a face, either bind Cap Desktop's own `startInstantRecording` hotkey (Cap's settings,
unset by default) or record studio and export.

## Instant mode

Recordings upload while you make them, which is what makes a link available the moment
you stop. That requires being signed in to Cap Desktop; check with
`cap-cli auth status --json`. If the upload never registers a link the recording is
still on disk, and the extension reveals it in Finder instead.

## Permissions

macOS attributes capture to the process that spawns the CLI, so Cap's own permissions do
not cover a Raycast-launched recording. **Raycast** needs its own grants, in System
Settings › Privacy & Security:

- **Screen & System Audio Recording** — without it, recordings fail with `declined TCCs`.
- **Microphone** — without it, `cap targets` returns no mics, so there is nothing for
  the Microphone preference to match.

Restart Raycast after granting any of them. The extension recognises each failure and
says which permission is missing rather than showing the raw error.

## Install

```sh
cd ~/workspace/dotfiles/raycast/cap
npm install
npm run dev     # registers the extension with Raycast; Ctrl-C once the command appears
```

`npm run dev` leaves it installed as a local development extension. Re-run it after
pulling changes.

## Notes

- Recordings are written to `~/Movies/Cap Recordings` by default, one `.cap` project per
  recording, even though instant mode also uploads them.
- `cap record status` keeps stale failed sessions around; the extension only treats a
  session as live when it is both `alive` and `recording`, so a past failure never blocks
  a new recording.
