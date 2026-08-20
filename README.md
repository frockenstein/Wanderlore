# Wanderlore

An iOS audio tour that narrates whatever you’re walking or driving past.

Start a tour. As you move, Wanderlore finds the nearest Wikipedia article, asks Claude to rewrite the intro as a short spoken story, and reads it aloud. The phone can stay locked — GPS and audio keep going in the background.

Personal project, not shipped. iOS 17+, SwiftUI.

## How it works

```
GPS move  →  Wikipedia geosearch  →  article extract  →  Claude rewrite  →  on-device TTS
```

1. Core Location fires when you’ve traveled past the mode’s movement threshold.
2. Wikipedia Geosearch returns nearby articles, nearest first. Already-narrated pages are skipped for the rest of the session.
3. The article’s intro extract is sent to Claude Haiku, which returns 2–3 storyteller sentences.
4. `AVSpeechSynthesizer` speaks it on-device (no cloud TTS, works offline once the text is in).

A new location update cancels any in-flight fetch so you always hear the place you’re at now, not the one you just left.

## Modes

| Mode | For | Movement threshold | Search radius |
|---|---|---|---|
| **Walking** (`wander`) | streets, trails | ~150 ft / 46 m | 150 m |
| **Driving** (`journey`) | road trips | ~500 ft / 152 m | 402 m |

Mode is locked while a tour is running so thresholds don’t change mid-pipeline.

## Setup

You need Xcode 15.4+ and an [Anthropic API key](https://console.anthropic.com/).

```bash
git clone https://github.com/frockenstein/Wanderlore.git
cd Wanderlore
cp Secrets.xcconfig.example Secrets.xcconfig
```

Paste the key into `Secrets.xcconfig`:

```
CLAUDE_API_KEY = sk-ant-api03-...
```

Open `Wanderlore.xcodeproj`, select a physical iPhone, and Run. Location permission is requested on first Start. A real device is the right target — background GPS and locked-phone audio don’t behave like the simulator.

`Secrets.xcconfig` is gitignored. Don’t put the key in the shared Xcode scheme.

## Settings

- **Narrator voice** — English `AVSpeechSynthesisVoice`s installed on the device
- **Lower other audio while narrating** — duck music/podcasts, or mix on top
- **Interest filters** — History, Architecture, Nature, Military, Notable People. Toggles are stored; they do **not** filter Wikipedia results yet.

Session history (map of narrated spots) lives in memory for the current launch only.

## Layout

```
Wanderlore/
  App/            App entry, splash overlay, shared AppState
  Core/           Location, Wikipedia, Claude, TTS
  Features/       Main screen, settings, history map
  Models/         TourMode, filters, visited locations
  Utilities/      Config (API key resolution)
```

`MainViewModel` owns the GPS → Wikipedia → Claude → TTS loop. Views observe it; they don’t talk to the services directly.

XcodeGen (`project.yml`) can regenerate the project file. The committed `.xcodeproj` is what you open day to day.

## Status

Working: walking/driving tours, background location, TTS ducking, session map, splash, voice picker.

Not yet: interest-filter wiring, persisted history, a backend so the Anthropic key isn’t in the app binary.
