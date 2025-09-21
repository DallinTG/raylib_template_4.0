#+feature dynamic-literals
package game

// import rl "vendor:raylib"
import "core:fmt"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"
import noise"core:math/noise"
import "core:time"

import "core:log"
import "core:mem"
import "core:math"
import "core:math/linalg"
import "core:strings"
import "core:thread"
import "core:encoding/cbor"

import hm"handle_map_static"


tile_overlap::0.02
TOL::tile_overlap
chunck_size::64
tile_size:f32:16

Tile_Map_Z::-50

world_save_location::"Saves"


chunck_handle :: distinct hm.Handle
World_T_Map::struct{
    save_location:string,
    t_maps:map[[2]int]chunck_handle,
    chuncks: hm.Handle_Map(T_Map, chunck_handle, 50),
    type:t_map_type,
}

Tile_Set::[16]Texture_Name
Tile_Set_Convering_Data::struct{
    neighbours:[4]bool,
    Sprite_number:u8,
}
F::false
T::true
tile_set_convering_dat:[16]Tile_Set_Convering_Data={
    {{F,F,T,F},15},
    {{F,T,F,T},1},
    {{T,F,T,T},7},
    {{F,F,T,T},9},
    {{T,F,F,T},14},
    {{F,T,T,T},10},
    {{T,T,T,T},6},
    {{T,T,T,F},2},
    {{F,T,F,F},13},
    {{T,T,F,F},3},
    {{T,T,F,T},5},
    {{T,F,T,F},11},
    {{F,F,F,F},12},
    {{F,F,F,T},8},
    {{F,T,T,F},4},
    {{T,F,F,F},0},
}

Tile::struct{
    // texture:Texture_Name,
    t_set_slot:u8,
    id:u32,
}
t_map_type::enum{
    blockes,
    background,
}

T_Map::struct{
    handle:chunck_handle,
    pos:[2]int,
    tiles:[chunck_size][chunck_size]Tile,
    display_t:[chunck_size][chunck_size][4]Tile,
    mesh:rl.Mesh,
    mesh_data:chunck_mesh_data,
    needs_to_be_rerendered:bool,
    needs_to_be_updated:bool,
    needs_to_be_unloaded:bool,
    

}

defalt_t_map:T_Map

Tile_G_Data::struct{ //this is the globl data for tiles
    id:u32,
    z_offset:f32,
    texture:Texture_Name,
    bg_tex:Texture_Name,
    tile_set:Tile_Set,
    col:[4]f32,
    col_overide:[4]f32,
    // str_id:string,
    display_name:string,
}

Tile_ID::enum u32{
    air = 0,
    dirt = #hash("dirt","adler32"),
    sand = #hash("sand","adler32"),
    whater = #hash("whater","adler32"),
}


world_gen_thread::proc(){
    	
    for g.run{
        if g.app_st.mode == .in_game{world_gen(&g.w_map)}
        time.sleep(10000000)
    }

}
world_gen::proc(w_map:^World_T_Map){

    pos_top_left:=rl.GetScreenToWorldRay({-100,-100},g.cam).position.xy
    pos_bot_right:=rl.GetScreenToWorldRay({cast(f32)g.window_info.w+100,cast(f32)g.window_info.h+100},g.cam).position.xy
    ch_pos_t:=t_pos_c_pos(world_pos_t_pos(pos_top_left))
    ch_pos_b:=t_pos_c_pos(world_pos_t_pos(pos_bot_right))
    rerender_chunckes:=false

    for x in ch_pos_t.x..=ch_pos_b.x {
        for y in ch_pos_t.y..=ch_pos_b.y {
            chunck:=get_chunck(w_map,{x,y})
            if chunck == nil{
                make_fill_t_map_chunk(w_map,{x,y})
            }
        }
    }

    chunck_iter := hm.make_iter(&w_map.chuncks)
	for chunck, h in hm.iter(&chunck_iter) {
        chunck:=hm.get(&w_map.chuncks,h)
        if chunck !=nil{
            if chunck.needs_to_be_updated{
                update_chunck(w_map,chunck)
            }
        }
    }
    unload_off_scr_maintain_chunks(w_map)
}

maintain_chunks::proc(w_map:^World_T_Map){
    chunck_iter := hm.make_iter(&w_map.chuncks)
	for chunck, h in hm.iter(&chunck_iter) {
        chunck:=hm.get(&w_map.chuncks,h)
        if chunck !=nil{
            if chunck.needs_to_be_rerendered{
                un_load_mesh(&chunck.mesh)
                rl.UploadMesh(&chunck.mesh, false)
                w_cbor_marshal(chunck.tiles,strings.concatenate({fmt.tprint(world_save_location),"/",g.st.world.name,"/",fmt.tprint(w_map.type),"/",fmt.tprint(w_map.type),"_",fmt.tprint(chunck.pos)},context.temp_allocator))
                chunck.needs_to_be_rerendered = false
            }
            if chunck.needs_to_be_unloaded{
                w_cbor_marshal(chunck.tiles,strings.concatenate({fmt.tprint(world_save_location),"/",g.st.world.name,"/",fmt.tprint(w_map.type),"/",fmt.tprint(w_map.type),"_",fmt.tprint(chunck.pos)},context.temp_allocator))
                unload_chunk(w_map,chunck.pos)
            }
        }
    }
}
update_chunck::proc(w_map:^World_T_Map,t_map:^T_Map){
    if t_map != nil{
        re_calc_chunk(t_map)
        gen_mesh_tmap_from_tile(t_map=t_map,t_data=t_map.display_t,t_w_h={tile_size,tile_size},no_load_unload=true)
        t_map.needs_to_be_updated = false
        t_map.needs_to_be_rerendered = true
    }
}
unload_off_scr_maintain_chunks::proc(w_map:^World_T_Map){
    pos_top_left:=rl.GetScreenToWorldRay({-100,-100},g.cam).position.xy
    pos_bot_right:=rl.GetScreenToWorldRay({cast(f32)g.window_info.w+100,cast(f32)g.window_info.h+100},g.cam).position.xy
    ch_pos_t:=t_pos_c_pos(world_pos_t_pos(pos_top_left))
    ch_pos_b:=t_pos_c_pos(world_pos_t_pos(pos_bot_right))
    for pos,i in &w_map.t_maps {
        if ch_pos_t.x-1>pos.x||ch_pos_t.y-1>pos.y||ch_pos_b.x+1<pos.x||ch_pos_b.y+1<pos.y{
            fmt.print(pos,"\n")
            chunck:=get_chunck(w_map,pos)
            if chunck !=nil{
                chunck.needs_to_be_unloaded = true
            }
        }
    }
}
unload_chunk::proc(w_map:^World_T_Map,pos:[2]int,){
    chunck:=get_chunck(w_map,pos)
    mesh:=chunck.mesh
    un_load_mesh(&chunck.mesh)
    hm.remove(&w_map.chuncks,get_chunck_ha(w_map,pos))
    delete_key(&w_map.t_maps,pos)
    chunck.needs_to_be_unloaded = false
}
re_render_all_chuncks_on_screan::proc(w_map:^World_T_Map){
    pos_top_left:=rl.GetScreenToWorldRay({-100,-100},g.cam).position.xy
    pos_bot_right:=rl.GetScreenToWorldRay({cast(f32)g.window_info.w+100,cast(f32)g.window_info.h+100},g.cam).position.xy
    ch_pos_t:=t_pos_c_pos(world_pos_t_pos(pos_top_left))
    ch_pos_b:=t_pos_c_pos(world_pos_t_pos(pos_bot_right))
    for x in ch_pos_t.x..=ch_pos_b.x {
        for y in ch_pos_t.y..=ch_pos_b.y {
            chunck:=get_chunck(&g.w_map,{x,y})
            if chunck != nil{
                chunck.needs_to_be_rerendered = true
            }
        }
    }
}
draw_all_chunks::proc(){
    pos_top_left:=rl.GetScreenToWorldRay({0,0},g.cam).position.xy
    pos_bot_right:=rl.GetScreenToWorldRay({cast(f32)g.window_info.w,cast(f32)g.window_info.h},g.cam).position.xy
    ch_pos_t:=t_pos_c_pos(world_pos_t_pos(pos_top_left))
    ch_pos_b:=t_pos_c_pos(world_pos_t_pos(pos_bot_right))

    for x in ch_pos_t.x..=ch_pos_b.x {
        for y in ch_pos_t.y..=ch_pos_b.y {
            chunck:=get_chunck(&g.w_map,{x,y})
            if chunck != nil{
                draw_t_map_chunk(chunck)
            }
        }
    }
}

init_tile_data::proc(t_data:^map[u32]Tile_G_Data){
    for id in Tile_ID{
        data:=get_reg_tile(cast(u32)id)
        data.id = cast(u32)id
        data.col={1,1,1,1}
        // if id != nil{
        //     data.str_id = fmt.tprint(id)
        // }
    }
    dirt:=get_reg_tile(cast(u32)Tile_ID.dirt)
    dirt.col={1,1,1,1}
    dirt.tile_set=gen_t_set_from_t_0(.Template_Tile_0)
    // dirt.texture= .Test_Path
    dirt.bg_tex=.Bg_Repeat_Tex
    dirt.z_offset = -11

    sand:=get_reg_tile(cast(u32)Tile_ID.sand)
    // sand.texture= .Bg_Repeat_Tex
    sand.tile_set=gen_t_set_from_t_0(.Template_Tile_0)
    // sand.bg_tex=.Test_Path
    sand.z_offset = -11
    sand.col={0,1,0,1}




}
gen_t_set_from_t_0::proc(t_0:Texture_Name)->(t_set:[16]Texture_Name){
    x:=0
    for &t in &t_set{
        str:=fmt.tprint(t_0)
        str2,ok:=strings.replace_all(str,"0",fmt.tprint(x),context.temp_allocator)
        t = string_to_enum(str2,Texture_Name)
        if ok {
            t_set[x]=t
        }
        x+=1
    }
    return
}
get_reg_tile::proc(id:u32)->(data:^Tile_G_Data){
    if &g.t_data[id] == nil{
        g.t_data[id]={}
    }
    data=&g.t_data[id] 
    return
}
clean_up_tile_data::proc(){
    for data_key in &g.t_data {
        // if g.t_data[data_key].str_id !=nil{
        //     delete(g.t_data[data_key].str_id)
        // }
    }
    delete(g.t_data)
}
get_chunck_ha::proc(w_map:^World_T_Map,cord:[2]int)->(ha:chunck_handle){
    ha=w_map.t_maps[cord]
    return

}

get_chunck::proc(w_map:^World_T_Map,cord:[2]int)->(t_map:^T_Map){
    t_map=hm.get(&w_map.chuncks,w_map.t_maps[cord])
    return

}

make_fill_t_map_chunk::proc(w_map:^World_T_Map,cord:[2]int){
    make_ok:=make_chunk(w_map,cord)
    if make_ok{
        chunck:=get_chunck(&g.w_map,cord)
        t_data_suc:=load_cbor_unmarshal(&chunck.tiles,strings.concatenate({fmt.tprint(world_save_location),"/",g.st.world.name,"/",fmt.tprint(w_map.type),"/",fmt.tprint(w_map.type),"_",fmt.tprint(cord)},context.temp_allocator))
        if !t_data_suc{
            fill_t_map_chunk(chunck)
        }
        chunck.needs_to_be_updated = true
        left_chunck:=get_chunck(&g.w_map,cord+{-1,0})
        if left_chunck!=nil{
            left_chunck.needs_to_be_updated = true
        }
        down_chunck:=get_chunck(&g.w_map,cord+{0,-1})
        if down_chunck!=nil{
            down_chunck.needs_to_be_updated = true
        }
        l_down_chunck:=get_chunck(&g.w_map,cord+{-1,-1})
        if l_down_chunck!=nil{
            l_down_chunck.needs_to_be_updated = true
        }
    }
}
un_load_all_t_maps::proc(w_map:^World_T_Map){
    un_load_all_t_maps_meshes(w_map)
    delete(w_map.t_maps)
}


fill_t_map_chunk::proc(t_map:^T_Map){
    for &row in &t_map.tiles{
        for &tile in &row{
            // tile.texture = .Test_Path
            tile.id = cast(u32)Tile_ID.dirt
        }
    }
    // re_render_chunk(t_map)
}


// re_render_chunk::proc(t_map:^T_Map){
//     if t_map !=nil{
//         re_calc_chunk(t_map)
//         gen_mesh_tmap_from_tile(t_map,t_map.display_t,{tile_size,tile_size})
//     }else{
//         fmt.print("tmap is nil")
//     }
// }


re_calc_chunk::proc(t_map:^T_Map){
    if t_map !=nil{
        cord_x:int=0
        cord_y:int=0
        for &row in &t_map.tiles{
            for &tile in &row{
                // tile:=&t_map.tiles[cast(int)(x/tile_size)][cast(int)(y/tile_size)]
                g_pos:=l_pos_g_pos(t_map,{cord_x,cord_y})
                display_t:=get_display_t_g_cord(g_pos,&g.w_map)
                tile:=get_tile_g_cord(g_pos,&g.w_map)

                
                if tile != nil{
                    display_t[2]=tile^
                    display_t[2].t_set_slot=get_tile_set_slot(tile.id,g_pos)
                }
                tile=get_tile_g_cord(g_pos+{1,0},&g.w_map)
                if tile != nil{
                    display_t[3]=tile^
                    display_t[3].t_set_slot=get_tile_set_slot(tile.id,g_pos)
                }
                tile=get_tile_g_cord(g_pos+{0,1},&g.w_map)
                if tile != nil{
                    display_t[0]=tile^
                    display_t[0].t_set_slot=get_tile_set_slot(tile.id,g_pos)
                }
                tile=get_tile_g_cord(g_pos+{1,1},&g.w_map)
                if tile != nil{
                    display_t[1]=tile^
                    display_t[1].t_set_slot=get_tile_set_slot(tile.id,g_pos)
                }


                cord_x+=1
            }
            cord_y+=1
            cord_x=0
        }
    }else{
        fmt.print("tmap is nil",#line)
    }
}
get_tile_set_slot::proc(id:u32,cord:[2]int)->(slot:u8){
    neighbours:[4]bool
    c_tile:=get_tile_g_cord(cord,&g.w_map)
    if c_tile!=nil{
        if c_tile.id == id{
            neighbours[2]=true
        }
    }
    c_tile=get_tile_g_cord(cord+{1,0},&g.w_map)
    if c_tile!=nil{
        if c_tile.id == id{
            neighbours[3]=true
        }
    }
    c_tile=get_tile_g_cord(cord+{0,1},&g.w_map)
    if c_tile!=nil{
        if c_tile.id == id{
            neighbours[0]=true
        }
    }
    c_tile=get_tile_g_cord(cord+{1,1},&g.w_map)
    if c_tile!=nil{
        
        if c_tile.id == id{
            neighbours[1]=true
        }
    }
    for data in tile_set_convering_dat{
        if data.neighbours == neighbours{
            slot=data.Sprite_number
            return
        }
    }
    slot=12
    return slot
}


draw_t_map_chunk::proc(t_map:^T_Map,ofset:[3]f32=0,){
    if t_map != nil{
        mat4:rl.Matrix=1
        mat4= mat4 * cast(rl.Matrix)linalg.matrix4_translate_f32(
                {
                    (cast(f32)t_map.pos.x*tile_size*cast(f32)chunck_size)+ofset.x,
                    (cast(f32)t_map.pos.y*tile_size*cast(f32)chunck_size)+ofset.y,
                    ofset.z
                }
            )
        rl.DrawMesh(t_map.mesh,mat,mat4)
    }else{
        fmt.print("draw chunk invalid t_map is nil")
    }
}
// insert_t_map_w_map::proc(w_map:^World_T_Map,t_map:^T_Map){
//     w_map.t_maps[t_map.pos]=t_map
// }
// get_t_map::proc(w_map:^World_T_Map,cord:[2]int)->(t_map:^T_Map){
//     if &w_map.t_maps[cord] != nil{
//         t_map=w_map.t_maps[cord]

//         return
//     }else{
//         t_map = nil

//         return 
//     }
// }





world_pos_t_pos::proc(pos:[2]f32)->(t_pos:[2]int){
    n_pos:=pos
    if n_pos.x<0{
        n_pos.x-=tile_size
    }
    if n_pos.y<0{
        n_pos.y-=tile_size
    }
    t_pos=({cast(int)(n_pos.x+tile_size/2),cast(int)(n_pos.y+tile_size/2)}/cast(int)tile_size)
    return t_pos
}
t_pos_l_pos::proc(t_pos:[2]int)->(l_pos:[2]int){
    n_pos:=t_pos
    if n_pos.x<0{
        n_pos.x+=1
        l_pos.x = (n_pos.x%chunck_size) +chunck_size-1
        l_pos.x = abs(l_pos.x)
    }else{
        l_pos.x = n_pos.x%chunck_size
    }

    if n_pos.y<0{
        n_pos.y+=1
        l_pos.y = (n_pos.y%chunck_size) +chunck_size-1
        l_pos.y = abs(l_pos.y)
    }else{
        l_pos.y = n_pos.y%chunck_size
    }

    return l_pos
}
t_pos_c_pos::proc(t_pos:[2]int)->(g_pos:[2]int){
    n_pos:=t_pos
    if n_pos.x<0{
        n_pos.x-=chunck_size-1
        // g_pos.x = n_pos.x/tile_map_size
    }
    if n_pos.y<0{
        n_pos.y-=chunck_size-1
        // g_pos.y = n_pos.y/tile_map_size
    }
    g_pos=n_pos/chunck_size
    return g_pos
}
l_pos_g_pos::proc(t_map:^T_Map,pos:[2]int,)->(w_pos:[2]int){
    offset:=t_map.pos*chunck_size
    w_pos=offset+pos
    return
}

get_tile_g_cord::proc(cord:[2]int,w_map:^World_T_Map)->(tile:^Tile){
    t_map:=get_chunck(w_map,t_pos_c_pos(cord))
    if t_map == nil{
        return nil
    }
    cord:=t_pos_l_pos(cord)
    tile = &t_map.tiles[cord.x][cord.y]
    return 
}
get_display_t_g_cord::proc(cord:[2]int,w_map:^World_T_Map)->(tile:^[4]Tile){
    t_map:=get_chunck(w_map,t_pos_c_pos(cord))
    if t_map == nil{
        return nil
    }
    cord:=t_pos_l_pos(cord)
    tile = &t_map.display_t[cord.x][cord.y]
    return 
}

set_tile_in_tile_map::proc(t_map:^T_Map,pos:[2]int,tile:Tile={id=0}){
    if t_map !=nil{
        cord:=t_pos_l_pos(pos)
        t_map.tiles[cord.x][cord.y] = tile
        t_map.needs_to_be_updated = true
    }   
}



log_all_pos::proc(pos:[2]f32){
    fmt.print("[\n",pos,"w pos \n",world_pos_t_pos(pos),"t pos \n",t_pos_l_pos(world_pos_t_pos(pos)),"l pos \n",t_pos_c_pos(world_pos_t_pos(pos)),"c pos\n","]\n",)
}