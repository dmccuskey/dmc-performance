# Changelog

## 1.2.0 (2026-09-29)

### Changed

- Markers are on by default, as they always were in practice: the default was the string `'false'`, which Lua counts as on. `OUTPUT_MARKERS = false` now turns them off without the `:BOOL` type too.
- `MEMORY_ACTIVE:BOOL = true` (and `MEMORY_ACTIVE:INT = 1000`) start the memory watch; typed values used to be ignored.
- `markTime()` without a name prints `(unnamed)` instead of raising an error.
- `markTimeDiff()` with a name that was never marked prints a warning and returns `nil` instead of raising an error. Otherwise it returns the time between the markers.
- `watchMemory()` stops the watch already running before it starts another, so `watchMemory( false )` always stops it.
- Rebuilt with dmc-corona-boot 1.6.0.

### Added

- `VERSION` in the table the module returns.
- Unit tests: `tests/run_unit.sh`, plain Lua 5.1.

### Removed

- The copy of `extend()`, which set the global `_extend`.

## 1.1.0

- `memoryMonitor()` prints a string argument as a label; updated for DMC-Corona-Library 2.0 (2015).
