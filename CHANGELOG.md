# Changelog

## 0.0.2 - 2026-08-15

### Performance
- Memoize tag-name to highlight-group lookups to avoid re-hashing on every redraw.
- Replace linear filetype scanning with a hash set for O(1) checks.

### Fixes
- Clear per-buffer state on `BufDelete` so recycled buffer numbers are not highlighted incorrectly.

## 0.0.1 - 2026-05-24

### Features
- Initial release of rainbow TSX tag highlighting for Neovim.
- Highlight JSX opening, closing, and self-closing tag names with Tree-sitter.
- Render only visible ranges through ephemeral extmarks for lightweight redraws.
- Support stable name-based colors, visible-order sequence colors, intrinsic tag filtering, default RainbowDelimiter links, and buffer enable/disable/toggle commands.
