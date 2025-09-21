package game

import "core:fmt"
import "core:math/linalg"
import "core:math"
import "core:math/rand"
import "base:runtime"
import rl "vendor:raylib"
import noise"core:math/noise"
import clay "/clay-odin"
import "core:log"
import "core:thread"



mat:rl.Material

init::proc(){
	init_thred_pool()
	rl.InitAudioDevice()
	init_clay_ui()
	init_sounds()
	init_shaders()
	init_atlases()
	init_box_2d()
	init_global_animations()
	init_defalts()
	init_tile_data(&g.t_data)
	register_events()

	log_system_info()

	// g.world.name="test_world"
	
	// rl.SetTargetFPS(10)
	g.cam.position = {0,0,-50}
	g.cam.target = {0,0,0}
	
	g.cam.projection=.ORTHOGRAPHIC
	g.cam.up = {0,-1,0}

	mat= rl.LoadMaterialDefault()
	mat.shader=g.as.shaders.bace
	temp:[2]f32={cast(f32)g.atlas.width,cast(f32)g.atlas.height}
	rl.SetShaderValueV(g.as.shaders.bace,rl.GetShaderLocation(g.as.shaders.bace,"at_size"),cast(rawptr)(&temp),.VEC2,1)
	mat.maps[rl.MaterialMapIndex.ALBEDO].texture=g.atlas
	mat.maps[rl.MaterialMapIndex.ALBEDO].color = {255,255,255,255}


	g.world_gen_thread=thread.create_and_start(world_gen_thread,context)
	
	// rand.reset(rand.uint64()+cast(u64)(rl.GetTime()*100000000000))
}





update :: proc() {
	free_all(context.temp_allocator)
	maintain_input_info()
	maintain_window_info()
	maintain_timers()
	update_global_animations()
	calc_particles()
	sim_box_2d()
	manage_sound_bytes()
	update_song()
	update_clay_ui()
	do_inputs()
	if g.app_st.mode == .in_game{
		maintain_chunks(&g.w_map)
		game_update_tick()
	}
}
game_update_tick::proc(){

	if is_input_event(.ui_l_c){


		pos := rl.GetScreenToWorldRay(rl.GetMousePosition(),g.cam).position.xy 
		fmt.print(pos,"\n")
		// log_all_pos(pos)
		c_pos:=t_pos_c_pos(world_pos_t_pos(pos))
		chunck:=get_chunck(&g.w_map,c_pos)
		l_pos:=t_pos_l_pos(world_pos_t_pos(pos))
		set_tile_in_tile_map(chunck,l_pos,Tile{id = cast(u32)Tile_ID.sand})
		
		// fmt.print(l_pos_g_pos(get_t_map(&w_map,c_pos),t_pos_l_pos(world_pos_t_pos(pos))),"l_pos to g_pos \n")
		// re_render_chunk(get_t_map(&g.w_map,c_pos))
		// re_render_all_chuncks_on_screan(&g.w_map)
	}

	if is_input_event(.jump){
		fmt.print("jump1\n")
	}
	if is_input_event(.jump){
		fmt.print("jump2\n")
	}
	if is_input_event(.move_l){
		fmt.print("no\n")
	}
}


draw :: proc() {
	// fmt.print("asdasdhkjasdf\nwaffles\nhi\n\n")
        
	rl.BeginDrawing()
	rl.ClearBackground({0, 5, 30,255})
	rl.BeginMode3D(g.cam)//g.cam
	rl.BeginShaderMode(g.as.shaders.bace)


	rl.BeginBlendMode(.ADDITIVE)
	draw_particles()
	rl.EndBlendMode()

	draw_all_chunks()

	rl.EndShaderMode()
	rl.EndMode3D()

	rl.BeginMode2D(ui_camera())

	clay_raylib_render(&ui_render_command)
	rl.EndMode2D()

	rl.DrawFPS(10,10)
	rl.EndDrawing()
}

cleanup_game::proc(){
	g.run = false
	clean_up_ui()
	clean_up_tile_data()
	thread.join(g.world_gen_thread)
	thread.destroy(g.world_gen_thread)
	un_load_all_t_maps(&g.w_map)
	clean_up_event_data()
	clean_up_ui_data()
	clean_up_thread_pool()

}


ui_camera :: proc() -> rl.Camera2D {
	return {
		// zoom = f32(rl.GetScreenHeight())/PIXEL_WINDOW_HEIGHT,
		zoom = 1
	}
}
