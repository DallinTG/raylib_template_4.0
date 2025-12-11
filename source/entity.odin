#+feature dynamic-literals
package game
// import ecs "odin-ecs-main"
import "core:fmt"
import b2 "box2d"
import rl "vendor:raylib"
import hm "handle_map_static"
import "core:strings"
import "core:time"

max_entities::1024
Entity_Handle :: distinct hm.Handle


Entity :: struct {
	handle: Entity_Handle,
    type:Ent_Type,
    ph:Physics_Data,
    rd:Render_Data,
    id:u32,
}
Ent_Type::union{
    Player,
    Simp_Mob,
}
Player::struct{
    id:u32,

}
Simp_Mob::struct{
    id:u32,
}

Physics_Data::struct{
    pos:[2]f32,
    velocity:[2]f32,
}
Renderer_Types::enum{
    non,
    basic,
}
Render_Data::struct{
    renderer:Renderer_Types,
}

Ent_ID::enum u32{
    non     = 0,
    pig     = #hash("pig","murmur32"),
    cow     = #hash("cow","murmur32"),
    player  = #hash("player","murmur32"),
}
Entety_G_Data::struct{
    defalt_ent:Entity,
}


get_ent::proc(id:u32,call:=#caller_location)->(data:^Entety_G_Data){
    if &g.ent_data[id] == nil{
        fmt.print("error ent dos not exsist","id",id,cast(Ent_ID)id,"\n",call,"\n")
        // g.ent_data[id]={}
    }
    data=&g.ent_data[id] 
    return
}
reg_ent::proc(id:u32,data:Entety_G_Data,call:=#caller_location){
    ent:^Entety_G_Data
    if &g.ent_data[id] == nil{
        g.ent_data[id]={}
    }else{
        fmt.print("error ent allredy exsist","id",id,cast(Ent_ID)id,"\n",call,"\n")
    }
    ent^ = data
    ent.defalt_ent.id = id
    ent.defalt_ent.handle = {} 
}

init_ent_data::proc(){
    pig :Entety_G_Data={defalt_ent={
        type=Simp_Mob{},
        ph={},
        rd={},
        id={}
    }}
    reg_ent(cast(u32)Ent_ID.pig,pig)
}



do_entitys::proc(){
    ent_iter := hm.make_iter(&cur_map().entities)
	for e, h in hm.iter(&ent_iter) {
        switch ent in e.type {
        case Player:  fmt.println("player",ent.id)

        case Simp_Mob: fmt.println("simp_mob", ent.id)

        }
	}
}
add_simp_mob::proc(){
    // mob:=hm.add(&cur_map().entities,Entity{type=Simp_Mob{},rd={renderer=basic_entity_renderer}})
    mob:=hm.add(&cur_map().entities,Entity{type=Simp_Mob{},rd={.basic}})
}

save_entities_on_map::proc(w_map:^World_T_Map){
    w_cbor_marshal(  w_map.entities ,strings.concatenate({world_save_location,"/",g.st.world.name,"/","entities","/","entities"},context.temp_allocator))
}
lode_entities_on_map::proc(w_map:^World_T_Map, data:^hm.Handle_Map(Entity, Entity_Handle, max_entities)){
   load_cbor_unmarshal( data, strings.concatenate({world_save_location,"/",g.st.world.name,"/","entities","/","entities"},context.temp_allocator))
}

render_entitys::proc(){
    ent_iter := hm.make_iter(&cur_map().entities)
	for e, h in hm.iter(&ent_iter) {
        switch e.rd.renderer{
            case .non:

            case .basic:
            basic_entity_renderer(e)
        }
	}
}
basic_entity_renderer::proc(ent:^Entity){
    draw_by_id_3d(.Test_Path,{ent.ph.pos.x,ent.ph.pos.y,100,100},-11,{0,0},0,{255,255,255,255})
}