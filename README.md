# InputPin

InputPin is a lightweight native macOS menu-bar application that keeps a selected audio input device as the system default. It uses AppKit and CoreAudio directly, with no third-party dependencies and no background polling.

## Requirements

- macOS 13 Ventura or newer
- Apple Command Line Tools (`xcode-select --install`)
- No full Xcode installation is required

## Build

```zsh
./Scripts/build.sh
```

The script creates an ad-hoc signed Universal application for both Apple Silicon and Intel:

```text
build/Release/InputPin.app
```

Run it with:

```zsh
open "build/Release/InputPin.app"
```

## Usage

- Click the microphone icon in the menu bar.
- Select an item under **Input Device**. Selecting a device also enables pinning and persists its CoreAudio UID.
- While **Pin Input** is enabled, InputPin restores the saved device if macOS changes the default input.
- If the pinned device is disconnected, InputPin keeps its UID and restores it after reconnect.
- Disable **Pin Input** to let macOS change the input without intervention.
- **Launch at Login** uses `SMAppService.mainApp`. Install `InputPin.app` in `/Applications` before enabling it for reliable registration.

InputPin never changes the default output device, records no audio, and requests no microphone permission.
