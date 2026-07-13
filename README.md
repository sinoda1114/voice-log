# Voice Log

Voice Log is a small macOS menu bar app that provides a text destination for macOS Dictation and saves the resulting text as local Markdown history.

## Daily Use

When Voice Log is running, use the shortcut configured in Settings to open a new focused input window. The default is `Option + F5`. This shortcut is meant for starting a dictation capture flow, not for opening settings or the history window.

Voice Log does not control macOS Dictation directly. Use your macOS Dictation shortcut after the input window appears.

## Build

```sh
swift build
```

To create a menu-bar-style app bundle with no Dock icon:

```sh
scripts/build-app.sh
```

## Run

```sh
swift run VoiceLog
```

Saved logs are stored in `~/Documents/VoiceLog` by default.
