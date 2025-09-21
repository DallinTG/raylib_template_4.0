package assets_builder

import "core:fmt"
import "core:os"
import "core:strings"
import "core:path/slashpath"
import "core:hash"


dir_path_to_file_infos :: proc(path: string) -> []os.File_Info {
	d, derr := os.open(path, os.O_RDONLY)
	if derr != 0 {
		fmt.print(os.get_current_directory(),"\n")
		fmt.print("\n |path| ",path,"\n")
		panic("open failed")
	}
	defer os.close(d)

	{
		file_info, ferr := os.fstat(d)
		defer os.file_info_delete(file_info)

		if ferr != 0 {
			panic("stat failed")
		}
		if !file_info.is_dir {
			panic("not a directory")
		}
	}

	file_infos, _ := os.read_dir(d, -1)
	return file_infos
}

main :: proc() {
	f, _ := os.open("../imbed_assets.odin", os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
	defer os.close(f)

	fmt.fprintln(f, "package game")
	fmt.fprintln(f, "")
	// fmt.fprintln(f, `import "core:hash"`)

	//fmt.fprintln(f, "EmbedAssets :: #config(EmbedAssets, true)")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "asset :: struct {")
	fmt.fprintln(f, "\tpath: string,")
	// fmt.fprintln(f, "\tpath_hash: u64,")
	fmt.fprintln(f, "\tdata: []u8,")
	fmt.fprintln(f, "\tinfo: cstring,")
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	// texture_paths := make([dynamic]string, context.temp_allocator)
	//texture_info_paths := make([dynamic]string, context.temp_allocator)
	// level_paths := make([dynamic]string, context.temp_allocator)
	font_paths := make([dynamic]string, context.temp_allocator)
	shader_paths := make([dynamic]string, context.temp_allocator)
	sound_paths := make([dynamic]string, context.temp_allocator)
	music_paths := make([dynamic]string, context.temp_allocator)
	// tile_map_paths := make([dynamic]string, context.temp_allocator)
	// world_map_paths := make([dynamic]string, context.temp_allocator)

	fmt.print(" 5 ")
	
	//root folder files
	// {
	// 	file_infos := dir_path_to_file_infos(".")
	// 	for fi in file_infos {
	// 		if strings.has_suffix(fi.name, ".cat_level") {
	// 			append(&level_paths, fi.name)
	// 		} else if strings.has_suffix(fi.name, ".ttf") {
	// 			append(&font_paths, fi.name)
	// 		} else if strings.has_suffix(fi.name, ".fs") {
	// 			append(&shader_paths, fi.name)
	// 		}
	// 	}
	// }
	
	// textures
	// {
	// 	file_infos := dir_path_to_file_infos("../../assets/textures")
	// 	for fi in file_infos {
	// 		if strings.has_suffix(fi.name, ".png") {
	// 			append(&texture_paths, fmt.tprintf("textures/%s", fi.name))
	// 		}
	// 	}
	// }

	{
		file_infos := dir_path_to_file_infos("../../assets/shaders")
		for fi in file_infos {
			if strings.has_suffix(fi.name, ".fs") {
				append(&shader_paths, fmt.tprintf("shaders/%s", fi.name))
			}
			if strings.has_suffix(fi.name, ".vs") {
				append(&shader_paths, fmt.tprintf("shaders/%s", fi.name))
			}
		}
	}

		{
		file_infos := dir_path_to_file_infos("../../assets/fonts")
		for fi in file_infos {
			if strings.has_suffix(fi.name, ".ttf") {
				append(&font_paths, fmt.tprintf("fonts/%s", fi.name))
			}
		}
	}

	fmt.print(" 4 ")

	// object art

	// {
	// 	file_infos := dir_path_to_file_infos("object_art")
	// 	for fi in file_infos {
	// 		if strings.has_suffix(fi.name, ".png") {
	// 			append(&texture_paths, fmt.tprintf("object_art/%s", fi.name))
	// 		}
	// 	}
	// }

	//sounds
	{
		file_infos := dir_path_to_file_infos("../../assets/sounds")
		for fi in file_infos {
		 	if strings.has_suffix(fi.name, ".wav") {
				append(&sound_paths, fmt.tprintf("sounds/%s", fi.name))
			}
		}
	}

	// music
	{
		file_infos := dir_path_to_file_infos("../../assets/music")
		for fi in file_infos {
		 	if strings.has_suffix(fi.name, ".mp3") {
				append(&music_paths, fmt.tprintf("music/%s", fi.name))
			}
		}
	}
	// t_maps
	// {
	// 	file_infos := dir_path_to_file_infos("../../assets/tile_maps")
	// 	for fi in file_infos {
	// 	 	if strings.has_suffix(fi.name, ".tmap") {
	// 			append(&tile_map_paths, fmt.tprintf("tile_maps/%s", fi.name))
	// 		}
	// 	}
	// }

	fmt.print(" 3 ")


	asset_name :: proc(path: string) -> string {
		return fmt.tprintf("%s", strings.to_lower(slashpath.name(slashpath.base(path)), context.temp_allocator))
	}

	// fmt.fprintln(f, "texture_names :: enum {")
	// fmt.fprint(f, "none,\n")
	// for p in texture_paths {
	// 	fmt.fprintf(f, "\t%s,\n", asset_name(p))
	// }
	// fmt.fprintln(f, "}")
	// fmt.fprintln(f, "")

	fmt.fprintln(f, "font_names :: enum {")
	for p in font_paths {
		fmt.fprintf(f, "\t%s,\n", asset_name(p))
	}
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "shader_names :: enum {")
	for p in shader_paths {
		fmt.fprintf(f, "\t%s,\n", asset_name(p))
	}
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "sound_names :: enum {")
	fmt.fprint(f, "\tnone,\n")
	for p in sound_paths {
		fmt.fprintf(f, "\t%s,\n", asset_name(p))
	}
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	fmt.fprintln(f, "music_names :: enum {")
	fmt.fprint(f, "\tnone,\n")
	for p in music_paths {
		fmt.fprintf(f, "\t%s,\n", asset_name(p))
	}
	fmt.fprintln(f, "}")
	fmt.fprintln(f, "")

	// fmt.fprintln(f, "tile_map_names :: enum {")
	// fmt.fprint(f, "\tnone,\n")
	// for p in tile_map_paths {
	// 	fmt.fprintf(f, "\t%s,\n", asset_name(p))
	// }
	// fmt.fprintln(f, "}")
	// fmt.fprintln(f, "")

	// fmt.fprintln(f, "world_map_names :: enum {")
	// fmt.fprint(f, "\tnone,\n")
	// for p in world_map_paths {
	// 	fmt.fprintf(f, "\t%s,\n", asset_name(p))
	// }
	// fmt.fprintln(f, "}")
	// fmt.fprintln(f, "")

	fmt.print(" 2 ")

	emit_asset_list :: proc(f: os.Handle, list_name: string, type: string, paths: [dynamic]string, embed: bool, include_none: bool, include_ext_dat: bool=false) {
		fmt.fprintf(f, "\t%s := [%s]asset {{\n", list_name, type)

		if include_none {
			fmt.fprint(f, "\t\t.none = {},\n")
		}

		if embed {
			if include_ext_dat {
				for p in paths {
					p2 := strings.split(p,".")[0]
					p_temp :=[]string {p2,".txt"}
					p2 = strings.concatenate(p_temp[:])
					
					// fmt.fprintf(f, "\t\t.%s = {{ path = \"%s\",  data = #load(\"%s\"),info = #load(\"%s\",cstring) or_else #load(\"textures/default.txt\", cstring), }},\n", asset_name(p), p, p,p2)
					//fmt.print(strings.split(p,"."))
					// fmt.print(p2)
					// fmt.print("   ")
				}
			}else{
				for p in paths {
					if strings.has_suffix(p, ".fs") || strings.has_suffix(p, ".vs"){
						fmt.fprintf(f, "\t\t.%s = {{ path = \"%s\",  info = #load(\"../assets/%s\",cstring), }},\n", asset_name(p), p, p)
					}else{
						fmt.fprintf(f, "\t\t.%s = {{ path = \"%s\",  data = #load(\"../assets/%s\"), }},\n", asset_name(p), p, p)
					}
				}
			}
			
		} 
		// else {
		// 	for p in paths {
		// 		fmt.fprintf(f, "\t\t.%s = {{ path = \"%s\", path_hash = %v, },\n", asset_name(p), p, hash.murmur64a(transmute([]byte)(p)))
		// 	}
		// }
		fmt.fprintln(f, "\t}")
	}

	// fmt.fprintln(f, "when EmbedAssets {")
	// emit_asset_list(f, "all_raw_textures", "texture_names", texture_paths, true, true, true)
	// fmt.fprintln(f, "")
	// emit_asset_list(f, "all_levels", "LevelName", level_paths, true, false)
	// fmt.fprintln(f, "")
	emit_asset_list(f, "all_fonts", "font_names", font_paths, true, false)
	fmt.fprintln(f, "")
	emit_asset_list(f, "all_shaders", "shader_names", shader_paths, true, false)
	fmt.fprintln(f, "")
	emit_asset_list(f, "all_sounds", "sound_names", sound_paths, true, true)
	fmt.fprintln(f, "")
	emit_asset_list(f, "all_music", "music_names", music_paths, true, true)
	fmt.fprintln(f, "")
	// emit_asset_list(f, "all_tile_maps", "tile_map_names", tile_map_paths, true, true)
	// fmt.fprintln(f, "")
	// emit_asset_list(f, "all_world_map", "world_map_names", world_map_paths, true, true)
	// fmt.fprintln(f, "")
	// fmt.fprintln(f, "} else {")
	// emit_asset_list(f, "all_textures", "TextureName", texture_paths, false, true)
	// fmt.fprintln(f, "")
	// emit_asset_list(f, "all_levels", "LevelName", level_paths, false, false)
	// fmt.fprintln(f, "")
	// emit_asset_list(f, "all_fonts", "FontName", font_paths, false, false)
	// fmt.fprintln(f, "")
	// emit_asset_list(f, "all_shaders", "ShaderName", shader_paths, false, false)
	// fmt.fprintln(f, "")
	// emit_asset_list(f, "all_sounds", "SoundName", sound_paths, false, true)
	// fmt.fprintln(f, "")
	// emit_asset_list(f, "all_music", "MusicName", music_paths, false, true)
	// fmt.fprintln(f, "")
	// fmt.fprintln(f, "}")


	fmt.print(" 1 ")
}

// EntityTypesFilename :: "entity_types.cat_entity_types"
// DialoguesFilename :: "dialogues.cat_dialogues"