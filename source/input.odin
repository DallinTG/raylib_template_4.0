package game

import rl "vendor:raylib"
import fmt"core:fmt"

event_data::struct{
    q:[dynamic]input_data,
    list:[input_e_id]input_event_data,
}
input_id::union{
    rl.MouseButton,
    rl.GamepadButton,
    rl.KeyboardKey,
    rl.GamepadAxis,
}

input_data::struct{
    id:input_id,
    pressed:bool,
    down:bool,
    released:bool,
   

}
input_e_id::enum{
    ui_debug,
    ui_l_c,
    ui_r_c,
    ui_m_c,
    ui_shift,
    ui_drag_l_c,
    ui_esc,
    ui_del,
    ui_back_space,
    ui_a_up,
    ui_a_down,
    ui_a_left,
    ui_a_right,
    ui_enter,
    ui_coppy,
    ui_cut,
    ui_past,
    ui_t_select_left,
    ui_t_select_right,
    ui_t_select_up,
    ui_t_select_down,
    ui_t_select_all,
    enter,
    pan_cam,
    jump,
    move_l,
    move_r,
    move_d,
    move_u,
    test,
    
}
input_event_data::struct{
    input:[max_key_combo]struct{
        data:input_data,
        // is_consumed:bool,
        consum_press:bool,
        consum_down:bool,
    }
}
max_key_combo::4
register_events::proc(){
    register_event(.jump,{{{data=               {id= rl.KeyboardKey.SPACE,          pressed= true ,down= false, released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_debug,{{{data=           {id= rl.KeyboardKey.F10,          pressed= true ,down= false, released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_l_c,{{{data=             {id= rl.MouseButton.LEFT,           pressed= true ,down= false, released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_r_c,{{{data=             {id= rl.MouseButton.RIGHT,          pressed= true ,down= false, released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_m_c,{{{data=             {id= rl.MouseButton.MIDDLE,         pressed= true ,down= false, released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.test,{{{data=               {id= rl.KeyboardKey.LEFT_SHIFT,     pressed= false,down= true , released= false}, consum_press= true , consum_down= true ,},{data= {id= rl.KeyboardKey.SPACE, pressed= true,down= false, released= false}, consum_press= true, consum_down= true,},{},{}}})
    register_event(.pan_cam,{{{data=            {id= rl.MouseButton.RIGHT,          pressed= false,down= true , released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_drag_l_c,{{{data=        {id= rl.MouseButton.LEFT,           pressed= false,down= true , released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_shift,{{{data=           {id= rl.KeyboardKey.LEFT_SHIFT,     pressed= false,down= true , released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_esc,{{{data=             {id= rl.KeyboardKey.ESCAPE,         pressed= true ,down= false, released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_back_space,{{{data=      {id= rl.KeyboardKey.BACKSPACE,      pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_del,{{{data=             {id= rl.KeyboardKey.DELETE,         pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_a_down,{{{data=          {id= rl.KeyboardKey.DOWN,           pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_a_up,{{{data=            {id= rl.KeyboardKey.UP,             pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_a_left,{{{data=          {id= rl.KeyboardKey.LEFT,           pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_a_right,{{{data=         {id= rl.KeyboardKey.RIGHT,          pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_enter,{{{data=           {id= rl.KeyboardKey.ENTER,          pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
    register_event(.ui_coppy,{{{data=           {id= rl.KeyboardKey.LEFT_CONTROL,   pressed= false ,down= true , released= false}, consum_press= true , consum_down= true ,},{data=       {id= rl.KeyboardKey.C,    pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{}}})
    register_event(.ui_past,{{{data=            {id= rl.KeyboardKey.LEFT_CONTROL,   pressed= false ,down= true , released= false}, consum_press= true , consum_down= true ,},{data=       {id= rl.KeyboardKey.V,    pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{}}})
    register_event(.ui_cut,{{{data=             {id= rl.KeyboardKey.LEFT_CONTROL,   pressed= false ,down= true , released= false}, consum_press= true , consum_down= true ,},{data=       {id= rl.KeyboardKey.X,    pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{}}})
    register_event(.ui_t_select_left,{{{data=   {id= rl.KeyboardKey.LEFT_SHIFT,     pressed= false ,down= true , released= false}, consum_press= true , consum_down= true ,},{data=       {id= rl.KeyboardKey.LEFT, pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{}}})
    register_event(.ui_t_select_right,{{{data=  {id= rl.KeyboardKey.LEFT_SHIFT,     pressed= false ,down= true , released= false}, consum_press= true , consum_down= true ,},{data=       {id= rl.KeyboardKey.RIGHT,pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{}}})
    register_event(.ui_t_select_up,{{{data=     {id= rl.KeyboardKey.LEFT_SHIFT,     pressed= false ,down= true , released= false}, consum_press= true , consum_down= true ,},{data=       {id= rl.KeyboardKey.UP,   pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{}}})
    register_event(.ui_t_select_down,{{{data=   {id= rl.KeyboardKey.LEFT_SHIFT,     pressed= false ,down= true , released= false}, consum_press= true , consum_down= true ,},{data=       {id= rl.KeyboardKey.DOWN, pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{}}})
    register_event(.ui_t_select_all,{{{data=    {id= rl.KeyboardKey.LEFT_CONTROL,   pressed= false ,down= true , released= false}, consum_press= true , consum_down= true ,},{data=       {id= rl.KeyboardKey.A, pressed= true ,down= true , released= false}, consum_press= true , consum_down= true ,},{},{}}})
    register_event(.enter,{{{data=              {id= rl.KeyboardKey.ENTER,          pressed= true ,down= false, released= false}, consum_press= true , consum_down= true ,},{},{},{}}})
}
register_event::proc(i_event:input_e_id,i_e_data:input_event_data){
    g.event.list[i_event] = i_e_data
}

is_input_event::proc(
    input_id        :input_e_id,
    always_consume_p:bool=false,
    always_consume_d:bool=false,
    never_consume_p :bool=false,
    never_consume_d :bool=false,
    require_p       :bool=false,
    require_d       :bool=false,
    require_r       :bool=false,
    ignore_p        :bool=false,
    ignore_d        :bool=false,
    ignore_r        :bool=false,
)->(ev:bool,){
    i_e_data:=&g.event.list[input_id].input
    is_good:[max_key_combo]bool
    ref:[4]^input_data
    for &event in &g.event.q {
        for i in 0..<max_key_combo{
            if i_e_data[i].data.id == nil &&i!=0{
                ref[i]= &event
                is_good[i]=true
            }else if i_e_data[i].data.id == event.id{

                ref[i]= &event
                is_good[i]=true
                if !ignore_p {if i_e_data[i].data.pressed  || require_p { if !event.pressed   {is_good[i] = false}}}
                if !ignore_d {if i_e_data[i].data.down     || require_d { if !event.down      {is_good[i] = false}}}
                if !ignore_r {if i_e_data[i].data.released || require_r { if !event.released  {is_good[i] = false}}}

            } 
        }
    }
    if is_good=={true,true,true,true}{
        for i in 0..<max_key_combo{
            if !never_consume_p{ if i_e_data[i].consum_press || always_consume_p{ref[i].pressed = false}}   
            if !never_consume_d{ if i_e_data[i].consum_down  || always_consume_d{ref[i].down    = false}}   
        }
        ev= true
    }
    return
}

maintain_input_info::proc(){
    maintain_input_q()
    
    add_key_press_to_event_q()
    add_mouse_button_press_to_event_q()


    add_key_press_to_event_q::proc(){
        t_input_data:input_data
        t_input_data.id=rl.GetKeyPressed()
        if t_input_data.id != .KEY_NULL{
            t_input_data.pressed = true
            t_input_data.down = rl.IsKeyDown(t_input_data.id.(rl.KeyboardKey))
            t_input_data.released = rl.IsKeyReleased(t_input_data.id.(rl.KeyboardKey))
            append(&g.event.q,t_input_data) 
            add_key_press_to_event_q()
        }
    }
    maintain_input_q::proc(){
        #reverse for &input ,i in &g.event.q{
            if input.id==nil{
                input.released = true
            }
            if input.released{
                unordered_remove(&g.event.q, i)
                
            }
            switch v in input.id {
            case rl.KeyboardKey:
                // input.pressed = rl.IsKeyPressed(t_input_data.id.(rl.KeyboardKey))
                input.pressed = false
                input.down = rl.IsKeyDown(input.id.(rl.KeyboardKey))
                input.released = rl.IsKeyUp(input.id.(rl.KeyboardKey))
            case rl.MouseButton:

                input.pressed = false
                input.down = rl.IsMouseButtonDown(input.id.(rl.MouseButton))
                input.released = rl.IsMouseButtonUp(input.id.(rl.MouseButton))


            case rl.GamepadButton:

            case rl.GamepadAxis:

            }
        }
    }
    add_mouse_button_press_to_event_q::proc(){
        // IsMouseButtonPressed 
        // IsMouseButtonDown    
        // IsMouseButtonReleased
        // IsMouseButtonUp   
        if rl.IsMouseButtonPressed(.BACK) {
            t_input_data:input_data
            t_input_data.id = rl.MouseButton.BACK
            t_input_data.pressed = true
            t_input_data.down = rl.IsMouseButtonDown(.BACK)
            t_input_data.released = rl.IsMouseButtonReleased(.BACK)
            append(&g.event.q,t_input_data) 
        }
        if rl.IsMouseButtonPressed(.EXTRA) {
            t_input_data:input_data
            t_input_data.id = rl.MouseButton.EXTRA
            t_input_data.pressed = true
            t_input_data.down = rl.IsMouseButtonDown(.EXTRA)
            t_input_data.released = rl.IsMouseButtonReleased(.EXTRA)
            append(&g.event.q,t_input_data) 
        }
        if rl.IsMouseButtonPressed(.FORWARD) {
            t_input_data:input_data
            t_input_data.id = rl.MouseButton.FORWARD
            t_input_data.pressed = true
            t_input_data.down = rl.IsMouseButtonDown(.FORWARD)
            t_input_data.released = rl.IsMouseButtonReleased(.FORWARD)
            append(&g.event.q,t_input_data) 
        }
        if rl.IsMouseButtonPressed(.LEFT) {
            t_input_data:input_data
            t_input_data.id = rl.MouseButton.LEFT
            t_input_data.pressed = true
            t_input_data.down = rl.IsMouseButtonDown(.LEFT)
            t_input_data.released = rl.IsMouseButtonReleased(.LEFT)
            append(&g.event.q,t_input_data) 
        }
        if rl.IsMouseButtonPressed(.MIDDLE) {
            t_input_data:input_data
            t_input_data.id = rl.MouseButton.MIDDLE
            t_input_data.pressed = true
            t_input_data.down = rl.IsMouseButtonDown(.MIDDLE)
            t_input_data.released = rl.IsMouseButtonReleased(.MIDDLE)
            append(&g.event.q,t_input_data) 
        }
        if rl.IsMouseButtonPressed(.RIGHT) {
            t_input_data:input_data
            t_input_data.id = rl.MouseButton.RIGHT
            t_input_data.pressed = true
            t_input_data.down = rl.IsMouseButtonDown(.RIGHT)
            t_input_data.released = rl.IsMouseButtonReleased(.RIGHT)
            append(&g.event.q,t_input_data) 
        }
        if rl.IsMouseButtonPressed(.SIDE) {
            t_input_data:input_data
            t_input_data.id = rl.MouseButton.SIDE
            t_input_data.pressed = true
            t_input_data.down = rl.IsMouseButtonDown(.SIDE)
            t_input_data.released = rl.IsMouseButtonReleased(.SIDE)
            append(&g.event.q,t_input_data) 
        }
    }
    
}
clean_up_event_data::proc(){
    delete(g.event.q)
}


do_inputs::proc(){
    check_cam_movements()
    check_paning()
    check_fov()
}

min_zoom::64
max_zoom::2048
// tile_size::16
check_fov::proc(){
    g.cam.fovy +=rl.GetMouseWheelMove()*tile_size*-2
    if g.cam.fovy < min_zoom {g.cam.fovy = min_zoom}
    // if g.cam.fovy > max_zoom {g.cam.fovy = max_zoom}
}

check_paning::proc(){

	if is_input_event(.pan_cam) {
        
		delta:rl.Vector2 = rl.GetMouseDelta()
		delta = (delta *(g.cam.fovy/cast(f32)g.window_info.h)*-1 )
		g.cam.position += {delta.x,delta.y,0}
		g.cam.target.x = g.cam.position.x
		g.cam.target.y = g.cam.position.y

	}
}


check_cam_movements::proc(){
   

}
