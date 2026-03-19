# TinyCSV

A minimal, fast CSV editor for macOS.

![macOS](https://img.shields.io/badge/macOS-26%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Three-panel layout** — file sidebar, editor, and table preview
- **Syntax highlighting** — commas, quotes, and field structure
- **Live preview** — spreadsheet-style table rendered as you type
- **Directory browsing** — navigate folders, subdirectories, and files
- **Quick open** — fuzzy file finder (Cmd+P)
- **Auto-save** — saves as you type with dirty-file indicators
- **Find & replace** — native macOS find bar (Cmd+F)
- **Tab support** — multiple files in tabs
- **Line numbers** — optional gutter with current line highlight
- **Word wrap** — toggle with Opt+Z
- **Font size control** — Cmd+/Cmd- to adjust, Cmd+0 to reset
- **Light & dark mode** — follows system appearance
- **Status bar** — row count, column count, file size
- **Open from Finder** — double-click `.csv` or `.tsv` files to open in TinyCSV
- **On-device AI** — Cmd+K to ask questions about your data (CoreML, fully offline)

## Requirements

- macOS 26.0+
- Xcode 26+ (to build)

## Build

```bash
xcodebuild clean build \
  -project TinyCSV.xcodeproj \
  -scheme TinyCSV \
  -configuration Release \
  -derivedDataPath /tmp/tinybuild/tinycsv \
  CODE_SIGN_IDENTITY="-"

cp -R /tmp/tinybuild/tinycsv/Build/Products/Release/TinyCSV.app /Applications/
```

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Cmd+N | New file |
| Cmd+O | Open folder |
| Cmd+S | Save |
| Cmd+P | Quick open |
| Cmd+F | Find |
| Cmd+K | AI assistant |
| Opt+Z | Toggle word wrap |
| Opt+P | Toggle preview |
| Opt+L | Toggle line numbers |
| Cmd+= / Cmd+- | Font size |
| Cmd+0 | Reset font size |

## Tech

Built with SwiftUI, NSTextView, and TinyKit.

## License

MIT
