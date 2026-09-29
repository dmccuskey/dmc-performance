--====================================================================--
-- tests/dmc_performance_spec.lua
--
-- Unit tests for dmc-performance, using Luna Test.
-- Run with tests/run_unit.sh
--
-- Solar2D's system, timer and Runtime are stand-ins here: the clock
-- moves only when a test sets it, and timers and listeners are
-- recorded, not run
--====================================================================--


module(..., package.seeall)



--====================================================================--
--== Setup


local MODULE = 'dmc_corona.dmc_performance'

local clock, timers, listeners, output
local cfgFile = 'dmc_corona.cfg'
local _print = print

-- stand-ins for the Solar2D globals the module uses
package.preload.json = function() return require 'dkjson' end

_G.system = {
	ResourceDirectory=newproxy(),
	getTimer=function() return clock end,
	getInfo=function() return 0 end,
	pathForFile=function( name ) return './'..cfgFile end,
}

_G.timer = {
	performWithDelay=function( delay, f, n )
		local t = { delay=delay, f=f }
		timers[ #timers+1 ] = t
		return t
	end,
	cancel=function( t ) t.cancelled = true end,
}

_G.Runtime = {
	addEventListener=function( self, name, f )
		listeners[ #listeners+1 ] = f
	end,
	removeEventListener=function( self, name, f )
		for i=#listeners,1,-1 do
			if listeners[i]==f then table.remove( listeners, i ) end
		end
	end,
}

-- load()
-- a fresh copy of the module, with this [DMC_PERFORMANCE] config;
-- nil for no config at all: the boot loader reads dmc_corona.cfg
--
local function load( config )
	package.loaded[ MODULE ] = nil
	package.loaded[ 'dmc_corona_boot' ] = nil
	_G.__dmc_corona = nil
	if config then
		_G.__dmc_corona = { dmc_corona={}, dmc_performance=config }
	end
	return require( MODULE )
end

-- run( f )
-- call f, returning what it printed, one line per entry
--
local function run( f )
	output = {}
	_G.print = function( ... )
		local t = {}
		for i=1,select( '#', ... ) do t[i] = tostring( (select( i, ... )) ) end
		output[ #output+1 ] = table.concat( t, '\t' )
	end
	local ok, err = pcall( f )
	_G.print = _print
	assert( ok, err )
	return output
end

function setup()
	clock, timers, listeners = 0, {}, {}
end



--====================================================================--
--== Tests


function test_module()
	local Perf = load( {} )
	assert_equal( 'table', type( Perf ) )
	assert_equal( '1.2.0', Perf.VERSION )
	assert_equal( 'function', type( Perf.markTime ) )
	assert_equal( 'function', type( Perf.markTimeDiff ) )
	assert_equal( 'function', type( Perf.watchMemory ) )
	assert_equal( 'function', type( Perf.memoryMonitor ) )
end

function test_no_global_extend()
	load( {} )
	assert_nil( rawget( _G, '_extend' ) )
end

function test_mark_time()
	local Perf = load( {} )
	local out = run( function()
		clock = 10 ; Perf.markTime( 'start' )
		clock = 18.5 ; Perf.markTime( 'done' )
	end )
	assert_equal( 3, #out )
	assert_equal( 'MARK    : Application Started:  (T:10)', out[1] )
	assert_equal( 'MARK    : start:  0  (T:10)', out[2] )
	assert_equal( 'MARK    : done:  8.5  (T:18.5)', out[3] )
end

function test_mark_time_params()
	local Perf = load( {} )
	local out = run( function()
		clock = 10 ; Perf.markTime( 'a' )
		clock = 20 ; Perf.markTime( 'b', { print=false } )
		clock = 25 ; Perf.markTime( 'c', { reset=true } )
	end )
	assert_equal( 3, #out )
	assert_equal( 'MARK    : c:  0  (T:25)', out[3] )
end

-- the default was the string 'false', which counts as on
function test_markers_on_by_default()
	local Perf = load( {} )
	local out = run( function() Perf.markTime( 'a' ) end )
	assert_equal( 2, #out )
end

function test_markers_off()
	for _, v in ipairs( { false, 'false' } ) do
		local Perf = load( { output_markers=v } )
		local out = run( function()
			Perf.markTime( 'a' ) ; Perf.markTime( 'b' )
			Perf.markTimeDiff( 'a', 'b' )
		end )
		assert_equal( 0, #out )
	end
end

function test_markers_on()
	for _, v in ipairs( { true, 'true' } ) do
		local Perf = load( { output_markers=v } )
		local out = run( function() Perf.markTime( 'a' ) end )
		assert_equal( 2, #out )
	end
end

-- the boot loader reads the repository's dmc_corona.cfg
function test_config_file()
	local Perf = load( nil )
	local out = run( function() Perf.markTime( 'a' ) end )
	assert_equal( 2, #out )
	assert_equal( 0, #timers + #listeners )
end

-- the types from the boot loader's parser: MEMORY_ACTIVE:BOOL = true
-- used to be ignored
function test_config_types()
	cfgFile = 'tests/typed.cfg'
	local Perf = load( nil )
	cfgFile = 'dmc_corona.cfg'
	assert_equal( 1, #listeners )
	local out = run( function() Perf.markTime( 'a' ) end )
	assert_equal( 0, #out )
end

-- used to raise "bad argument #2 to 'sformat'"
function test_mark_time_unnamed()
	local Perf = load( {} )
	local out = run( function() Perf.markTime() end )
	assert_equal( 'MARK    : (unnamed):  0  (T:0)', out[2] )
end

function test_mark_time_diff()
	local Perf = load( {} )
	local d
	local out = run( function()
		clock = 10 ; Perf.markTime( 'a' )
		clock = 42.25 ; Perf.markTime( 'b' )
		d = Perf.markTimeDiff( 'a', 'b' )
	end )
	assert_equal( 32.25, d )
	assert_equal( 'MARK <d>: a <=> b  <d> 32.25', out[4] )
end

-- used to raise "attempt to perform arithmetic on local 't1'"
function test_mark_time_diff_unknown()
	local Perf = load( {} )
	local d
	local out = run( function()
		Perf.markTime( 'a' )
		d = Perf.markTimeDiff( 'a', 'nope' )
	end )
	assert_nil( d )
	assert_match( "no marker named 'nope'", out[3] )
end

function test_memory_monitor()
	local Perf = load( {} )
	local out = run( function() Perf.memoryMonitor( 'label' ) end )
	assert_equal( 'label', out[1] )
	assert_match( '^M: [%d%.]+  T: 0$', out[2] )
end

function test_watch_memory_frames()
	local Perf = load( {} )
	Perf.watchMemory( true )
	assert_equal( 1, #listeners )
	Perf.watchMemory( false )
	assert_equal( 0, #listeners )
end

function test_watch_memory_interval()
	local Perf = load( {} )
	Perf.watchMemory( 1000 )
	assert_equal( 1, #timers )
	assert_equal( 1000, timers[1].delay )
	Perf.watchMemory( false )
	assert_true( timers[1].cancelled )
end

-- a second watch used to leave the first running, out of reach
function test_watch_memory_replaces()
	local Perf = load( {} )
	Perf.watchMemory( 1000 )
	Perf.watchMemory( 500 )
	assert_true( timers[1].cancelled )
	Perf.watchMemory( true )
	assert_true( timers[2].cancelled )
	assert_equal( 1, #listeners )
	Perf.watchMemory( false )
	assert_equal( 0, #listeners )
end

-- MEMORY_ACTIVE:BOOL = true used to be ignored
function test_memory_active()
	for _, v in ipairs( { true, 'true' } ) do
		setup()
		load( { memory_active=v } )
		assert_equal( 1, #listeners )
	end
	for _, v in ipairs( { 1000, '1000' } ) do
		setup()
		load( { memory_active=v } )
		assert_equal( 1000, timers[1].delay )
	end
	for _, v in ipairs( { false, 'false' } ) do
		setup()
		load( { memory_active=v } )
		assert_equal( 0, #timers + #listeners )
	end
end
