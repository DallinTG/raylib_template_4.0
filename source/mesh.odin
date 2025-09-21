package game

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"
import fmt "core:fmt"
import "core:math"
import hm "handle_map_static"



tile_count:i32:chunck_size*chunck_size*5

chunck_mesh_data::struct{
    t_vertices      :[2*3*tile_count * 3]f32,
    t_texcoords     :[2*3*tile_count * 2]f32, 
    t_boneWeights   :[2*3*tile_count * 4]f32,
    t_normals       :[2*3*tile_count * 3]f32,
    t_colors        :[2*3*tile_count * 4]u8,
}
make_chunk::proc(w_map:^World_T_Map,cord:[2]int)->(ok:bool){

    chunck_hl,set_ok:=hm.set_new(&w_map.chuncks)
    if set_ok{
        ok=true
        chunck:=hm.get(&w_map.chuncks,chunck_hl)
        w_map.t_maps[cord]=chunck_hl
        mesh:=&chunck.mesh

        mesh.triangleCount = 2*tile_count
        mesh.vertexCount = mesh.triangleCount*3

        mesh_data:=&chunck.mesh_data

        mesh.vertices       = cast([^]f32)&mesh_data.t_vertices
        mesh.texcoords      = cast([^]f32)&mesh_data.t_texcoords
        mesh.boneWeights    = cast([^]f32)&mesh_data.t_boneWeights
        mesh.normals        = cast([^]f32)&mesh_data.t_normals
        mesh.colors         = cast([^]u8)&mesh_data.t_colors


        chunck.pos=cord

        
    }else{
        ok=false
        logg_err("make_chunk() has failed chunck buffer is problobly full ")
    }

    return
}


gen_mesh_tmap_from_tile::proc(
    t_map:^T_Map,
    t_data:[chunck_size][chunck_size][4]Tile,
    t_w_h:[2]f32=1,
    at_w:f32=cast(f32)g.atlas.width,
    at_h:f32=cast(f32)g.atlas.height,
    no_load_unload:bool=false,
){
    mesh:=&t_map.mesh
    mesh_data:=&t_map.mesh_data
    tile_count:i32:chunck_size*chunck_size*5
 
    mesh_data.t_vertices      ={}
    mesh_data.t_texcoords     ={}
    mesh_data.t_boneWeights   ={}
    mesh_data.t_normals       ={}
    mesh_data.t_colors        ={}

    tile_index:i32=0
    for row_data , row_x in t_data{
        for tiles , col_y in row_data {
            // t_rec:=atlas_textures[t_data[row_x][col_y][0].texture].rect
            for i in 0..<4{
               
                t_g_data:=&g.t_data[tiles[i].id]
                t_rec:=atlas_textures[t_g_data.tile_set[tiles[i].t_set_slot]].rect
                t_rec2:=atlas_textures[t_g_data.bg_tex].rect
                
                if t_g_data.id != 0 {
                    gen_single_tile_for_t_map(
                        mesh=mesh,
                        tile_index=tile_index,
                        t_rec=t_rec,
                        t_rec2=t_rec2,
                        t_w_h=t_w_h,

                        row_x=cast(i32)row_x,
                        col_y=cast(i32)col_y,
                        tint=rl.ColorFromNormalized(t_g_data.col),
                        z=t_g_data.z_offset,
                        at_w=at_w,
                        at_h=at_h,
                    )
                }
                
                tile_index+=1
            }
            t_g_data:=&g.t_data[tiles[0].id]
            t_rec:=atlas_textures[t_g_data.texture].rect
            t_rec2:=atlas_textures[t_g_data.bg_tex].rect
            if t_g_data.texture != nil {
                gen_single_tile_for_t_map(
                    mesh=mesh,
                    tile_index=tile_index,
                    t_rec=t_rec,
                    t_rec2=t_rec2,
                    t_w_h=t_w_h,
                    row_x=cast(i32)row_x,
                    col_y=cast(i32)col_y,
                    offset={-t_w_h.x/2,t_w_h.y/2},
                    tint=rl.ColorFromNormalized(t_g_data.col),
                    z=t_g_data.z_offset-.1,
                    at_w=at_w,
                    at_h=at_h,
                )
            }
            tile_index+=1
        }
    }
    // t_map.re_uplode_mesh = true
    // Upload mesh data from CPU (RAM) to GPU (VRAM) memory
    if !no_load_unload{
        rl.UploadMesh(mesh, false)
    }
}

un_load_mesh::proc(mesh:^rl.Mesh){
    if mesh.vaoId != 0 {
        rlgl.UnloadVertexArray(mesh.vaoId)
        if (mesh.vboId != nil) {
            for i:=0 ; i < 9; i+=1 {
                rlgl.UnloadVertexBuffer(mesh.vboId[i])
            }
        }
        mesh.vaoId = 0
    }
}

un_load_all_t_maps_meshes::proc(w_map:^World_T_Map){
    // delete(w_map.chunck_unload_q)
    // delete(w_map.chunck_update_q)
    // delete(w_map.chunck_upload_q)
}


gen_single_tile_for_t_map::proc(
    mesh:^rl.Mesh,
    tile_index:i32,
    t_rec:Rect,
    t_rec2:Rect,
    row_x:i32,
    col_y:i32,
    offset:[2]f32={0,0},
    tint:rl.Color={255,255,255,255},
    t_w_h:[2]f32=1,
    z:f32=0,
    at_w:f32=cast(f32)g.atlas.width,
    at_h:f32=cast(f32)g.atlas.height
){

    mesh.vertices[0+(18*tile_index)] = 0*t_w_h.x+(cast(f32)row_x*t_w_h.x)-TOL+offset.x
    mesh.vertices[1+(18*tile_index)] = 0*t_w_h.y+(cast(f32)col_y*t_w_h.y)-TOL+offset.y
    mesh.vertices[2+(18*tile_index)] = z

    mesh.normals[0+(18*tile_index)] = 0
    mesh.normals[1+(18*tile_index)] = 0
    mesh.normals[2+(18*tile_index)] = 1

    mesh.texcoords[0+(+12*tile_index)] = t_rec.x/at_w
    mesh.texcoords[1+(+12*tile_index)] = t_rec.y/at_h

    mesh.boneWeights[0+(+24*tile_index)] = t_rec2.x     
    mesh.boneWeights[1+(+24*tile_index)] = t_rec2.y     
    mesh.boneWeights[2+(+24*tile_index)] = t_rec2.width 
    mesh.boneWeights[3+(+24*tile_index)] = t_rec2.height


    mesh.colors[0+(24*tile_index)]=tint.r
    mesh.colors[1+(24*tile_index)]=tint.g
    mesh.colors[2+(24*tile_index)]=tint.b
    mesh.colors[3+(24*tile_index)]=tint.a

 


    // bot_left
    mesh.vertices[3+(18*tile_index)] = 0*t_w_h.x+(cast(f32)row_x*t_w_h.x)-TOL+offset.x
    mesh.vertices[4+(18*tile_index)] = 1*t_w_h.y+(cast(f32)col_y*t_w_h.y)+TOL+offset.y
    mesh.vertices[5+(18*tile_index)] = z

    mesh.normals[3+(18*tile_index)] = 0
    mesh.normals[4+(18*tile_index)] = 0
    mesh.normals[5+(18*tile_index)] = 1

    mesh.texcoords[2+(+12*tile_index)] = t_rec.x/at_w
    mesh.texcoords[3+(+12*tile_index)] = (t_rec.y+t_rec.height)/at_h


    mesh.boneWeights[4+(+24*tile_index)] = t_rec2.x     
    mesh.boneWeights[5+(+24*tile_index)] = t_rec2.y     
    mesh.boneWeights[6+(+24*tile_index)] = t_rec2.width 
    mesh.boneWeights[7+(+24*tile_index)] = t_rec2.height

    mesh.colors[4+(24*tile_index)]=tint.r
    mesh.colors[5+(24*tile_index)]=tint.g
    mesh.colors[6+(24*tile_index)]=tint.b
    mesh.colors[7+(24*tile_index)]=tint.a

    // top_right
    mesh.vertices[6+(18*tile_index)] = 1*t_w_h.x+(cast(f32)row_x*t_w_h.x)+TOL+offset.x
    mesh.vertices[7+(18*tile_index)] = 0*t_w_h.y+(cast(f32)col_y*t_w_h.y)-TOL+offset.y
    mesh.vertices[8+(18*tile_index)] = z
    mesh.normals[6+(18*tile_index)] = 0
    mesh.normals[7+(18*tile_index)] = 0
    mesh.normals[8+(18*tile_index)] = 1

    mesh.texcoords[4+(+12*tile_index)] = (t_rec.x+t_rec.width)/at_w
    mesh.texcoords[5+(+12*tile_index)] = t_rec.y/at_h

    mesh.boneWeights[8+(+24*tile_index)] = t_rec2.x     
    mesh.boneWeights[9+(+24*tile_index)] = t_rec2.y     
    mesh.boneWeights[10+(+24*tile_index)] = t_rec2.width 
    mesh.boneWeights[11+(+24*tile_index)] = t_rec2.height

    mesh.colors[8+(24*tile_index)]=tint.r
    mesh.colors[9+(24*tile_index)]=tint.g
    mesh.colors[10+(24*tile_index)]=tint.b
    mesh.colors[11+(24*tile_index)]=tint.a


    //try 2 -----------------------------------------
        // bot_right
    mesh.vertices[0+9+(18*tile_index)] = 1*t_w_h.x+(cast(f32)row_x*t_w_h.x)+TOL+offset.x
    mesh.vertices[1+9+(18*tile_index)] = 1*t_w_h.y+(cast(f32)col_y*t_w_h.y)+TOL+offset.y
    mesh.vertices[2+9+(18*tile_index)] = z
    mesh.normals[0+9+(18*tile_index)] = 0
    mesh.normals[1+9+(18*tile_index)] = 0
    mesh.normals[2+9+(18*tile_index)] = 1

    mesh.texcoords[0+6+(+12*tile_index)] = (t_rec.x+t_rec.width)/at_w
    mesh.texcoords[1+6+(+12*tile_index)] = (t_rec.y+t_rec.height)/at_h

    mesh.boneWeights[0+12+(+24*tile_index)] = t_rec2.x     
    mesh.boneWeights[1+12+(+24*tile_index)] = t_rec2.y     
    mesh.boneWeights[2+12+(+24*tile_index)] = t_rec2.width 
    mesh.boneWeights[3+12+(+24*tile_index)] = t_rec2.height

    mesh.colors[0+12+(24*tile_index)]=tint.r
    mesh.colors[1+12+(24*tile_index)]=tint.g
    mesh.colors[2+12+(24*tile_index)]=tint.b
    mesh.colors[3+12+(24*tile_index)]=tint.a

    // top_right
    mesh.vertices[3+9+(18*tile_index)] = 1*t_w_h.x+(cast(f32)row_x*t_w_h.x)+TOL+offset.x
    mesh.vertices[4+9+(18*tile_index)] = 0*t_w_h.y+(cast(f32)col_y*t_w_h.y)-TOL+offset.y
    mesh.vertices[5+9+(18*tile_index)] = z
    mesh.normals[3+9+(18*tile_index)] = 0
    mesh.normals[4+9+(18*tile_index)] = 0
    mesh.normals[5+9+(18*tile_index)] = 1

    mesh.texcoords[2+6+(+12*tile_index)] = (t_rec.x+t_rec.width)/at_w
    mesh.texcoords[3+6+(+12*tile_index)] = t_rec.y/at_h

    mesh.boneWeights[4+12+(+24*tile_index)] = t_rec2.x     
    mesh.boneWeights[5+12+(+24*tile_index)] = t_rec2.y     
    mesh.boneWeights[6+12+(+24*tile_index)] = t_rec2.width 
    mesh.boneWeights[7+12+(+24*tile_index)] = t_rec2.height

    mesh.colors[4+12+(24*tile_index)]=tint.r
    mesh.colors[5+12+(24*tile_index)]=tint.g
    mesh.colors[6+12+(24*tile_index)]=tint.b
    mesh.colors[7+12+(24*tile_index)]=tint.a

    // bot_left
    mesh.vertices[6+9+(18*tile_index)] = 0*t_w_h.x+(cast(f32)row_x*t_w_h.x)-TOL+offset.x
    mesh.vertices[7+9+(18*tile_index)] = 1*t_w_h.y+(cast(f32)col_y*t_w_h.y)+TOL+offset.y
    mesh.vertices[8+9+(18*tile_index)] = z
    mesh.normals[6+9+(18*tile_index)] = 0
    mesh.normals[7+9+(18*tile_index)] = 0
    mesh.normals[8+9+(18*tile_index)] = 1

    mesh.texcoords[4+6+(+12*tile_index)] = t_rec.x/at_w
    mesh.texcoords[5+6+(+12*tile_index)] = (t_rec.y+t_rec.height)/at_h

    mesh.boneWeights[8+12+(+24*tile_index)] = t_rec2.x     
    mesh.boneWeights[9+12+(+24*tile_index)] = t_rec2.y     
    mesh.boneWeights[10+12+(+24*tile_index)] = t_rec2.width 
    mesh.boneWeights[11+12+(+24*tile_index)] = t_rec2.height


    mesh.colors[8+12+(24*tile_index)]=tint.r
    mesh.colors[9+12+(24*tile_index)]=tint.g
    mesh.colors[10+12+(24*tile_index)]=tint.b
    mesh.colors[11+12+(24*tile_index)]=tint.a
}


