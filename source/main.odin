/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
      pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g` global
      variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

// import "core:fmt"
// import "core:math/linalg"
import rl "vendor:raylib"
import "core:thread"

PIXEL_WINDOW_HEIGHT :: 720

seeds::struct{
	bace:i64,
	ore:i64,
	height:i64
}

platforme::enum{
	desktop,
	web,
}

Game_Memory :: struct {
	cam:			rl.Camera,
	run: 			bool,
	t_data:			map[u32]Tile_G_Data,
	w_map:			World_T_Map,
	using as:		assets,
	using st:		state,
	using app_st:	app_state,
	ui_st:			ui_state,
	time:			time_stuff,
	defalt:			defalt,
	settings:		settings,
	platforme:		platforme,
	using b2_data:	b2_world_data,
	window_info:	window_info,
	ui_mem:			[^]u8,
	event:			event_data,
	thread_pool:	thread.Pool,
	world_gen_thread:^thread.Thread,
	
}

g: ^Game_Memory

@(export)
game_update :: proc() {
	update()
	draw()
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE,.FULLSCREEN_MODE})
	rl.InitWindow(720, 720, "Orbital")

	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(0)
	rl.SetTraceLogLevel(.ALL)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
	g = new(Game_Memory)

	g^ = Game_Memory {
		run = true,

		// You can put textures, sounds and music in the `assets` folder. Those
		// files will be part any release or web build.
		// player_texture = rl.LoadTexture("assets/textures/round_cat.png"),
	}
	// t_maps := make(map[[2]int]tile_map,)
	// g.st.game_map.tile_maps =&t_maps
	when ODIN_ARCH == .wasm32{
		g.platforme = .web
	}
	game_hot_reloaded(g)
	init()
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g.run
}

@(export)
game_shutdown :: proc() {
	cleanup_game()
	free(g)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g = (^Game_Memory)(mem)

	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside
	// `g`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
