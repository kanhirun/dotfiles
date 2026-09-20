# narrate — asciinema with a voice track

A cast is a few kilobytes of JSON and the text in it stays selectable. A screen
recording of the same session is megabytes of pixels. `narrate` keeps the cast
and adds narration beside it, rather than giving both up for an MP4.

```sh
narrate check          # is the microphone actually reaching ffmpeg?
narrate rec   demo     # record the terminal
narrate voice demo     # play it back and talk over it
narrate build demo     # encode the audio, write index.html
```

Output lands in `~/Recordings/casts/<name>/` (`$NARRATE_DIR`): `session.cast`,
`voice.m4a`, `index.html`.

Requires `brew install ffmpeg`. asciinema itself is already in the Brewfile.

## Why three steps and not one

You could record the terminal and the microphone at the same time. Don't:

- **Talking while typing is the hard part of a screencast**, and doing both
  live means one fluffed sentence costs the whole take.
- **The microphone does not start when you ask it to.** macOS powers the mic
  down when idle, and a cold start costs 2–5 seconds — warm, it is instant.
  The delay is not a constant you can subtract.

Narrating over `asciinema play` removes both problems. The cast is finished and
fixed, the voice can be redone as many times as it takes, and — because
`narrate` starts the recorder and the playback itself — the gap between them is
something it can measure rather than guess.

## How the lead is measured

`voice` records raw PCM at a known rate with `-flush_packets 1`. That makes the
file's size a sample-accurate clock: at 48 kHz mono 16-bit, every second of
captured audio is exactly 96,000 bytes. Whatever has been written at the instant
playback begins *is* the lead-in, so it comes off the front.

This is measurement, not estimation, which is why the arming delay drops out.
Tested against a stub recorder with delays of 0.3s, 2s and 4s, the trimmed
track matched a six-second cast to within 12 ms in every case.

`$NARRATE_AUDIO_OFFSET` nudges the result in seconds if narration lands
consistently early or late on your hardware. It should not be needed.

## The things that break sync

The player's own clock comes from `AudioContext.getOutputTimestamp()` once an
audio track is present — the terminal follows the audio hardware, so playback
adds no drift of its own. Recording-side drift, between the sound card's crystal
and the system clock, is tens of milliseconds over twenty minutes. Neither is
worth correcting. These are:

- **`--idle-time-limit`.** It does not rewrite the file; it writes a number into
  the header that the *player* applies, compressing gaps at playback time. The
  audio is not compressed with them, so everything after the first long pause
  slides. `build` refuses a cast whose header carries it.
- **`speed` other than 1.** The player never sets `playbackRate`, so the audio
  runs at 1× against a terminal that doesn't. The generated page pins `speed: 1`.
- **`ctrl+\` during `narrate rec`.** asciinema binds it to pause capture. Cast
  time stops, the world doesn't. (Note this collides with the `<C-\>` terminal
  toggle in `nvim/`.)
- **Serving the audio from another origin.** The player sets
  `crossOrigin="anonymous"` unconditionally, so the host must send CORS headers
  even where a bare `<audio>` tag would have been fine. Seeking additionally
  needs HTTP range support. Keeping the audio next to the page avoids both.

## Publishing to asciinema.org instead

asciinema.org stores an audio *URL*, never the audio — that has been the
maintainer's position since 2015. Host the file yourself with CORS and range
requests, then:

```sh
asciinema upload session.cast --audio-url https://…/voice.m4a
```

`--audio-url` needs CLI ≥ 3.2.0 and is changelog-only — it appears in no manual
page. The same field exists in a recording's settings in the web UI.
