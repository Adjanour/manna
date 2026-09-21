# bernard.scripture

An [Omarchy](https://omarchy.org/) shell plugin that shows a daily scripture verse in the bar.

## Features

- Fetches a verse of the day from Bible Gateway (with OurManna fallback)
- Displays the reference in the bar; click to open a polished panel
- Panel shows the verse as a blockquote with accent rule, attribution, and version pill
- Copy verse to clipboard or open the full passage in your browser
- Refreshes hourly; right-click the bar icon to force a refresh
- Middle-click sends a desktop notification

## Install

```bash
omarchy plugin clone bernard.scripture
```

This copies the plugin to `~/.config/omarchy/plugins/bernard.scripture/` and activates it. Edits hot-reload on save.

## Requirements

- [scripture](https://github.com/Adjanour/scripture) CLI on `~/.local/bin/scripture`
- Omarchy shell (Quickshell)

## Configuration

The plugin reads no settings. The verse source and caching are handled by the `scripture` CLI.

## License

MIT
