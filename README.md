# MacPad

A lightweight, native macOS notepad app built with SwiftUI and AppKit.

## Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Building from Source](#building-from-source)
- [License](#license)

## Features

- **New, Open & Save As**: Create new documents, open existing files, and save anywhere. Supports both plain-text and RTF.
- **Monospaced Text Editor**: Clean editing experience with monospaced font and smooth scrolling.
- **Light & Dark Mode**: Toggle instantly and retain preference across launches.
- **Smart Placeholder UI**: Shows a prompt and version info when empty, disappears on typing.

## Installation

1. Download the [latest release](https://github.com/anthonyhana04/MacPad/releases).
2. Unzip the downloaded file.
3. Drag **MacPad.app** into your **Applications** folder (or any location you prefer).
4. Launch from Spotlight or Finder.

## Usage

- **New** (`Cmd+N`): Create a new file.
- **Open** (`Cmd+O`): Open an existing file.
- **Save As** (`Cmd or Shift+S`): Save current document under a new name or location.
- **Toggle Theme**: Click the sun/moon icon in the toolbar.

## Building from Source

**Requirements:**
- Xcode 16.1+
- Swift 5.8+
- macOS 13+

```bash
git clone https://github.com/anthonyhana04/MacPad.git
cd MacPad
open MacPad.xcodeproj
# Build & Run in Xcode
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
