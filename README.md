# dmc-performance

Time the parts of a Solar2D (formerly Corona SDK) app and watch its memory, from the console.

dmc-performance prints time markers, the time between them, and the Lua and texture memory in use, once or at an interval:

```lua
local Perf = require 'dmc_corona.dmc_performance'

Perf.markTime( 'start' )
-- ... load the level ...
Perf.markTime( 'level loaded' )  --> MARK    : level loaded:  182.4  (T:1234.5)

Perf.watchMemory( 1000 )         --> M: 412.67  T: 0.34   every second
```

## Features

- Time markers: the milliseconds since the last marker, and between any two
- A memory monitor: Lua memory in KB and texture memory in MB, every frame or every so many milliseconds
- Turn markers off and the memory monitor on from `dmc_corona.cfg`, without changing code
- One file, no plugins needed; MIT licensed

## Quick Start

The following code will get you up and running in about 10 minutes in the Solar2D Simulator on macOS or Windows. It times how long making 300 text objects takes, then watches the memory drop when they're removed.

Prerequisites: the [Solar2D](https://solar2d.com/) Simulator and a copy of this repository (`git clone https://github.com/dmccuskey/dmc-performance.git`, or download the ZIP from GitHub).

### 1. Copy the Library into Your Project

Copy these from this repository into the root of your project folder:

```text
dmc_corona_boot.lua     loader for the DMC libraries
dmc_corona.cfg          configuration
dmc_corona/             dmc-performance
```

**Going further:** keep the libraries in a subfolder, or combine several DMC libraries ([dmc-corona-boot Configuration](https://github.com/dmccuskey/dmc-corona-boot/blob/master/docs/configuration.md)).

### 2. Time Some Work

Create `main.lua` in the project folder:

```lua
local Perf = require 'dmc_corona.dmc_performance'

Perf.markTime( 'start' )

local labels = {}
for i = 1, 300 do
	labels[i] = display.newText( i, math.random( display.contentWidth ), math.random( display.contentHeight ), native.systemFont, 24 )
end

Perf.markTime( 'labels made' )
```

Open the project in the Simulator. The screen fills with numbers, and the console shows (your times will differ):

```text
MARK    : Application Started:  (T:47.297)
MARK    : start:  0  (T:47.297)
MARK    : labels made:  8.156  (T:55.453)
```

If the console shows `module 'dmc_corona.dmc_performance' not found` instead, `dmc_corona/` is missing from the root of the project folder.

Each marker prints the milliseconds since the one before, and `T`, the time since the app started (`system.getTimer()`). The first marker also prints `Application Started`. Making the labels took about 8 ms.

### 3. Watch the Memory

Add this to the end of `main.lua`:

```lua
Perf.watchMemory( 1000 )

timer.performWithDelay( 2500, function()
	for i = 1, #labels do labels[i]:removeSelf() end
	labels = nil
	Perf.markTime( 'labels removed' )
	Perf.markTimeDiff( 'labels removed', 'start' )
end )

timer.performWithDelay( 5500, function()
	Perf.watchMemory( false )
	print( "stopped" )
end )
```

The Simulator restarts the app when the file is saved. After two and a half seconds the numbers disappear, and after five and a half the memory lines stop. The console shows, after the first markers:

```text
M: 412.677734375  T: 0.34656143188477
M: 412.646484375  T: 0.34656143188477
MARK    : labels removed:  2531.43899  (T:2586.892)
MARK <d>: labels removed <=> start  <d> 2539.59499
M: 361.5537109375  T: 0
M: 347.4912109375  T: 0
M: 347.4912109375  T: 0
stopped
```

`M` is the Lua memory in KB, `T` the texture memory in MB (text objects are drawn as textures). `markTimeDiff()` gives the time between two named markers, in either order.

**Going further:** turn the markers off, or watch memory from the start of the app, in `dmc_corona.cfg` ([Configuration](#configuration)).

To update, copy `dmc_corona_boot.lua` and `dmc_corona/` again from the newer version. Keep your own `dmc_corona.cfg` if you have changed it.

## Reference

`require 'dmc_corona.dmc_performance'` returns the module. Times are in milliseconds, from `system.getTimer()`, rounded to 5 decimals.

### `Perf.markTime( marker, params )`

Records the time under the name `marker` and prints the time since the last marker:

```text
MARK    : <marker>:  <ms since the last marker>  (T:<ms since the app started>)
```

The first call also prints `Application Started`. `params` is optional:

| param | default | effect |
|---|---|---|
| `print` | `true` | `false` records the marker without printing it |
| `reset` | `false` | `true` starts from this marker: the time printed is 0 |

Nothing is printed when `OUTPUT_MARKERS` is off. A marker name used twice keeps the later time.

### `Perf.markTimeDiff( marker1, marker2 )`

Prints the time between two recorded markers, as a positive number:

```text
MARK <d>: <marker1> <=> <marker2>  <d> <ms>
```

### `Perf.watchMemory( value )`

Starts or stops printing the memory in use (`Perf.memoryMonitor()`):

| value | effect |
|---|---|
| `true` | every frame |
| a number | every that many milliseconds |
| `false` | stops the watch |

### `Perf.memoryMonitor( label )`

Runs a full garbage collection, then prints the memory in use once: `M: <Lua memory in KB>  T: <texture memory in MB>`. A string `label` is printed on the line before.

## Configuration

The `[DMC_PERFORMANCE]` section of `dmc_corona.cfg` (see [dmc-corona-boot Configuration](https://github.com/dmccuskey/dmc-corona-boot/blob/master/docs/configuration.md) for the file's format):

| key | values | default | effect |
|---|---|---|---|
| `OUTPUT_MARKERS:BOOL` | `true`, `false` | on | whether `markTime()` and `markTimeDiff()` print. Only `OUTPUT_MARKERS:BOOL = false` turns them off: without the `:BOOL` type, `false` is read as a string, which counts as on |
| `MEMORY_ACTIVE` | `true`, a number, `false` | `false` | starts `watchMemory()` with this value when the module loads: every frame, or every that many milliseconds. Write it without a type (`MEMORY_ACTIVE = 1000`, or `MEMORY_ACTIVE:INT = 1000`): `MEMORY_ACTIVE:BOOL = true` does nothing |

The `dmc_corona.cfg` in this repository turns the markers on and leaves the memory watch off:

```ini
[DMC_PERFORMANCE]
OUTPUT_MARKERS:BOOL = true
-- MEMORY_ACTIVE = 1000
```

## Known Issues

- **Markers print unless turned off with the `:BOOL` type**: the default is the string `'false'`, which Lua counts as true. See [Configuration](#configuration).
- **`MEMORY_ACTIVE:BOOL = true` doesn't start the watch**: only the strings `true` and `false` and numbers are understood.
- `markTime()` without a name raises an error (`bad argument #2 to 'sformat'`) when it prints.
- `markTimeDiff()` with a name that was never marked raises an error (`attempt to perform arithmetic on local 't1'`).
- Calling `watchMemory()` with a number while a watch runs starts a second watch, and `watchMemory( false )` then stops only the second.
- The memory monitor runs a full garbage collection each time: every frame, it slows the app down and frees memory that would otherwise still be counted.
- `dmc_performance.lua` sets the global `_extend` (its copy of `Utils.extend()` declares the inner function without `local`).
- Its version (`1.1.0`) isn't available to code.

## Development

Only `dmc_corona/dmc_performance.lua` is written in this repository; it needs no other module. `dmc_corona_boot.lua` is a generated copy from [dmc-corona-boot](https://github.com/dmccuskey/dmc-corona-boot); fix it there, then rebuild. The copy is made by Snakemake from sibling checkouts (`../dmc-corona-boot`, `../DMC-Corona-Library` for the shared rules). From this repository's root folder:

```sh
snakemake --cores 1 build_all
```

dmc-performance has no tests. The Quick Start is the check that it works in Solar2D.

## License

dmc-performance is released under the [MIT License](LICENSE).
