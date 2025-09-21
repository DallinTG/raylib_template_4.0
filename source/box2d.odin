package game

import rl "vendor:raylib"
import fmt "core:fmt"

// import "core:math"
import b2 "box2d"

b2_world_data::struct{
    box_2d_world_id:b2.WorldId,
    world_grav:f32,
    time_step :f32,
    sub_step_count:i32,
    lengthUnitsPerMeter :f32,
}

// box_2d_world_id :b2.WorldId
// world_grav:f32:9.8
// time_step :f32= 1
// sub_step_count :i32= 4

// lengthUnitsPerMeter :f32: 128.0


init_box_2d::proc(){
    g.b2_data.time_step=1
    g.b2_data.lengthUnitsPerMeter = 128.0
    g.b2_data.sub_step_count = 10
    g.b2_data.world_grav=9.8
    b2.SetLengthUnitsPerMeter(g.lengthUnitsPerMeter)


    box_2d_world_def :b2.WorldDef = b2.DefaultWorldDef()
    box_2d_world_def.gravity.y = g.world_grav * g.lengthUnitsPerMeter

    // box_2d_world_def.workerCount = 4;
    // box_2d_world_def.enqueueTask = myAddTaskFunction
    // box_2d_world_def.finishTask = myFinishTaskFunction
    // box_2d_world_def.userTaskContext = &myTaskSystem

    g.box_2d_world_id = b2.CreateWorld(box_2d_world_def)


    
}
sim_box_2d::proc(){
    ndt:=g.time.dt
    if ndt > 0.1 {ndt = 0}
    b2.World_Step(g.box_2d_world_id, ndt*g.time_step, g.sub_step_count)
}

cleanup_box_2d::proc(){
    b2.DestroyWorld(g.box_2d_world_id)
}

// create_static_tile::proc(pos:[2]i32) -> (body_id:b2.BodyId,shape_id:b2.ShapeId){
//     body_def : b2.BodyDef = b2.DefaultBodyDef()
//     body_def.type = .staticBody
//     body_def.position = {cast(f32)pos.x*t_map_t_size+(cast(f32)t_map_t_size/2),cast(f32)pos.y*t_map_t_size+(cast(f32)t_map_t_size/2)}

//     shape_def :b2.ShapeDef = b2.DefaultShapeDef()
//     shape_def.density = 4.0
//     shape_def.friction = 0.3
//     shape_def.restitution = .3

//     body_id = b2.CreateBody(box_2d_world_id, body_def)
//     shape_id = b2.CreatePolygonShape(body_id, shape_def, b2.MakeBox(t_map_t_size/2, t_map_t_size/2))
//     return body_id,shape_id
// }