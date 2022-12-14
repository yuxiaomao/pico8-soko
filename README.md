# Pico8-Soko : pico-8 based sokoban

Play online at: [https://yuxiaomao.github.io/pico8-soko]

Learning project

## Implemented features
- Read level data (16x16) from pico-8 map editor
  - Configure `mn.lvmax` to adjust number of levels read (1-32)
- Support multiple sprite for wall (set flag 1)
- Level selection in main menu
- Button and doors
  - 1 button works for multiples doors of the same color
- Undo moves in level

## Build
In pico-8:
- binary
  - `export -i 11 -s 4 -f soko.bin`
- html
  - use ctrl+7 to capture an label
  - `export -f soko.html`

## Development tools
- pico-8 on Linux
- gedit text editor
