package game

import "core:fmt"
import "core:math/linalg"
import "core:math"
import rl "vendor:raylib"
import noise"core:math/noise"
import clay "/clay-odin"
import "base:runtime"
import "core:c"
import "core:strconv"
import "core:hash"
import "core:os"
import "core:time"
import "core:path/filepath"
import "core:strings"
import edit"text_edit"
import "vendor:cgltf"
import "core:unicode/utf8"

ui_render_command:clay.ClayArray(clay.RenderCommand)

// Define some colors.


ui_setting_field_type::enum{
    color,
    number,
    scaler,
    t_f,
}
ui_settings_tab::enum{
    none,
    All,
    UI,
    Colors,
}


ui_pages::enum{
    start,
    mode_sulect,
    game,
    worlds,
    create_world,
    settings,
}
ui_page_data::struct{
    is_open:        bool,
    center_on_open: bool,
    id:             ui_pages,
    current_offset: [2]f32,
    center_offset:  [2]f32,
    curent_tab:     int,
    dec_proc:       proc(^ui_page_data),
    // str_builders:   [dynamic]strings.Builder,
    // text_edit_state:   [dynamic]edit.State,
    text_boxes:[dynamic]ui_text_box,
}

ui_state::struct{
    pages:[ui_pages]ui_page_data,
    world_saves_list:[]os.File_Info,
}
set_up_ui_pages::proc(){
    start:=&g.ui_st.pages[.start]
    start.id = .start
    start.dec_proc = ui_start_page
    start.is_open = true
    // start.text_boxes[0]=
    // append(&start.str_builders,strings.Builder{})
    // append(&start.text_edit_state,edit.State{})
    box_setings:=defalt_text_box_settings()
    assign_at       (&start.text_boxes,0, ui_text_box{})
    init_text_box   (&start.text_boxes[0],box_setings)
    start.text_boxes[0].text_edit_state.is_activ = true
    assign_at       (&start.text_boxes,1, ui_text_box{})
    init_text_box   (&start.text_boxes[1],box_setings)

    settings:=&g.ui_st.pages[.settings]
    settings.id = .settings
    settings.dec_proc = ui_settings_page
    settings.curent_tab = 1
    settings.is_open = false

    worlds:=&g.ui_st.pages[.worlds]
    worlds.id = .worlds
    worlds.dec_proc = ui_worlds_page
    worlds.curent_tab = 0
    worlds.is_open = false

}




// Layout config is just a struct that can be declared statically, or inline

error_handler :: proc "c" (errorData: clay.ErrorData) {
    // Do something with the error data.
}
init_clay_ui::proc(){
    min_memory_size: u32 = clay.MinMemorySize()
    g.ui_mem = make([^]u8, min_memory_size)
    arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(auto_cast min_memory_size, g.ui_mem)
    clay.Initialize(arena, { width = 720, height = 720 }, { handler = error_handler })
    // clay.SetMeasureTextFunction(measureText,nil)
    clay.SetMeasureTextFunction(measure_text,nil)
    // loadFont(FONT_ID_TITLE_56, 56, "resources/Calistoga-Regular.ttf")
    raylibFonts[1].font = rl.GetFontDefault()
    raylibFonts[1].fontId = 1
    raylibFonts[0].font = rl.GetFontDefault()
    raylibFonts[0].fontId = 1

    set_up_ui_pages()
    init_defalt_ui_settings()
}
clean_up_ui::proc(){
    free(g.ui_mem)
}
update_clay_ui::proc(){
    mouse_pos:= rl.GetMousePosition()
    is_mouse_down:=rl.IsMouseButtonDown(.LEFT)
    clay.SetPointerState(
        clay.Vector2 { mouse_pos.x, mouse_pos.y },
        is_mouse_down,
    )
    clay.UpdateScrollContainers(false, transmute(clay.Vector2)rl.GetMouseWheelMoveV(), rl.GetFrameTime())
    clay.SetLayoutDimensions({auto_cast g.window_info.w,auto_cast g.window_info.h})
    cash_settings_ui()
    ui_render_command = create_ui_layout()

}
t_size_m:f32=1


// An example function to create your layout tree
create_ui_layout :: proc() -> clay.ClayArray(clay.RenderCommand) {

    // g.st.overide_left_click=false

    clay.BeginLayout()

    if clay.UI()({
        id = clay.ID("outOuterContainer"),
        layout = {
            sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
            padding = { 16, 16, 16, 16 },
            childGap = 0,
            layoutDirection=.TopToBottom,
            childAlignment = {x=.Center,y=.Center,},
        },
        backgroundColor = { 0, 0, 0, 0 },
    
    }) 
    {
        do_all_ui_pages()
    }
    // Returns a list of render commands
    render_commands: clay.ClayArray(clay.RenderCommand) = clay.EndLayout()

    return render_commands
}
do_all_ui_pages::proc(){
    for &page in  &g.ui_st.pages{ 
        if page.dec_proc != nil{
            if page.is_open{
                page.dec_proc(&page)
            }
            if clay.PointerOver(clay.GetElementId(clay.MakeString(fmt.tprint(page.id)))){
                if is_input_event(.ui_l_c){
        
                }
            }
        }
    }
}



update_world_dir_list::proc(){
    f_handle,open_ok :=os.open(world_save_location)
    read_ok:os.Error
    if open_ok == nil{
        g.ui_st.world_saves_list,read_ok=os.read_dir(f_handle,0)
        if read_ok != nil {
            logg_err("update_world_dir_list() failed on read_dir()")
        }
        // fmt.print( g.ui_st.world_saves_list,"\n")
    }else{
        logg_err("update_world_dir_list() failed on os.open()")
    }
    os.close(f_handle)
    
}


//_________________Pages___________________________________________________

ui_worlds_page::proc(pd:^ui_page_data,){
    ui_do_b_box(pd)
    if clay.UI()({
        id = clay.ID(fmt.tprint(pd.id)),
        layout = {
            sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
            padding = ui_pading( 3, 3, 3, 3 ),
            childGap = ui_childGap(6),
            layoutDirection = .TopToBottom,
            childAlignment = {x=.Center,y=.Center,},

        },
        // floating={offset={math.round(pd.current_offset.x+pd.center_offset.x),math.round(pd.current_offset.y+pd.center_offset.y)},attachTo = .Parent},
        floating={offset={math.round(pd.center_offset.x),math.round(pd.center_offset.y)},attachTo = .Parent},
        // floating={attachTo = .Parent,clipTo=.AttachedParent,},
        backgroundColor = {},
    }){
        
        body_id:=clay.ID_LOCAL("worlds_body")
        if clay.UI()({
            id = body_id,
            layout = {
                sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
                padding = ui_pading( 10, 10, 10, 10 ),
                childGap = ui_childGap(5),
                layoutDirection=.TopToBottom,
            },
            // scroll={vertical=true},
            // clip={vertical=true,childOffset = clay.GetScrollOffset(),},
            // childOffset = clay.GetScrollOffset(),
            backgroundColor = col_l_1 ,
            border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
        }){

            ui_do_all_world_selection_tabs(pd)

            buton_box_id:=clay.ID_LOCAL("buton_box")
            if clay.UI()({
                id = buton_box_id,
                layout = {
                    sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
                    padding = ui_pading( 10, 10, 10, 10 ),
                    childGap = ui_childGap(10),
                    layoutDirection=.LeftToRight,
                },
                backgroundColor = {0,0,0,0},
            }){
                
                play_id:=clay.ID_LOCAL("Play")
                if clay.UI()({
                    id = play_id,
                    layout = {
                        sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
                        padding = ui_pading( 10, 10, 10, 10 ),
                        childGap = ui_childGap(0),
                        layoutDirection=.TopToBottom,
                    },
                    // scroll={vertical=true},
                    // clip={vertical=true,childOffset = clay.GetScrollOffset(),},
                    // childOffset = clay.GetScrollOffset(),
                    backgroundColor = h_col_d_2 if clay.Hovered() else col_l_1,
                    border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
                }){
                    clay.Text("Play",t_config_medium())
                    if clay.Hovered(){
                        if is_input_event(.ui_l_c){
                            g.st.world.name = g.ui_st.world_saves_list[pd.curent_tab].name
                            g.app_st.mode=.in_game
                            g.ui_st.pages[.worlds].is_open = false
                        }
                    }
                }
                new_world_id:=clay.ID_LOCAL("new_world")
                if clay.UI()({
                    id = new_world_id,
                    layout = {
                        sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
                        padding = ui_pading( 10, 10, 10, 10 ),
                        childGap = ui_childGap(0),
                        layoutDirection=.TopToBottom,
                    },
                    // scroll={vertical=true},
                    // clip={vertical=true,childOffset = clay.GetScrollOffset(),},
                    // childOffset = clay.GetScrollOffset(),
                    backgroundColor = h_col_d_2 if clay.Hovered() else col_l_1,
                    border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
                }){
                    clay.Text("New World",t_config_medium())
                }
            }
        }
    }
    if is_input_event(.ui_esc){
        g.ui_st.pages[.worlds].is_open = false
        g.ui_st.pages[.start].is_open = true
    }
}

ui_start_page::proc(pd:^ui_page_data,){
    
    // ui_do_b_box(pd)
    // if clay.UI()({
    //     id = clay.ID(fmt.tprint(pd.id)),
    //     layout = {
    //         sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
    //         padding = ui_pading( 3, 3, 3, 3 ),
    //         childGap = ui_childGap(6),
    //         layoutDirection = .TopToBottom,
    //         childAlignment = {x=.Center,y=.Center,},

    //     },
    //     // floating={offset={math.round(pd.current_offset.x+pd.center_offset.x),math.round(pd.current_offset.y+pd.center_offset.y)},attachTo = .Parent},
    //     floating={offset={math.round(pd.center_offset.x),math.round(pd.center_offset.y)},attachTo = .Parent},
    //     // floating={attachTo = .Parent,clipTo=.AttachedParent,},
    //     backgroundColor = {},
    // }){
        
    //     body_id:=clay.ID_LOCAL("play")
    //     if clay.UI()({
    //         id = body_id,
    //         layout = {
    //             sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
    //             padding = ui_pading( 10, 10, 10, 10 ),
    //             childGap = ui_childGap(0),
    //             layoutDirection=.TopToBottom,
    //         },
    //         // scroll={vertical=true},
    //         // clip={vertical=true,childOffset = clay.GetScrollOffset(),},
    //         // childOffset = clay.GetScrollOffset(),
    //         backgroundColor = h_col_d_2 if clay.Hovered() else col_l_1,
    //         border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
    //     }){

    //         clay.Text("Play",t_config_medium())
    //         if clay.Hovered(){if is_input_event(.ui_l_c){
    //             update_world_dir_list()
    //             g.ui_st.pages[.start].is_open = false
    //             g.ui_st.pages[.worlds].is_open = true
    //         }}
    //     }
    //     settings_id:=clay.ID_LOCAL("Settings")
    //     if clay.UI()({
    //         id = settings_id,
    //         layout = {
    //             sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
    //             padding = ui_pading( 10, 10, 10, 10 ),
    //             childGap = ui_childGap(0),
    //             layoutDirection=.TopToBottom,
    //         },
    //         // scroll={vertical=true},
    //         // clip={vertical=true,childOffset = clay.GetScrollOffset(),},
    //         // childOffset = clay.GetScrollOffset(),
    //         backgroundColor = h_col_d_2 if clay.Hovered() else col_l_1,
    //         border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
    //     }){

    //         clay.Text("Settings",t_config_medium())
    //         if clay.Hovered(){if is_input_event(.ui_l_c){
    //             g.ui_st.pages[.settings].is_open = true
    //         }}
    //     }
        
    // }
    ui_input_text_box(&pd.text_boxes[1])
    ui_input_text_box(&pd.text_boxes[0])
}

ui_settings_page::proc(pd:^ui_page_data,){
    ui_do_b_box(pd)
    if is_input_event(.ui_esc){pd.is_open = false}
    if clay.UI()({
        id = clay.ID(fmt.tprint(pd.id)),
        layout = {
            sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
            padding = ui_pading( 3, 3, 3, 3 ),
            childGap = ui_childGap(6),
            layoutDirection = .TopToBottom,

        },
        floating={offset={math.round(pd.current_offset.x+pd.center_offset.x),math.round(pd.current_offset.y+pd.center_offset.y)},attachTo = .Parent},
        backgroundColor = {},
    }){ 
        if clay.UI()({
            id = clay.ID_LOCAL("top_bar"),
            layout = {
                sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
                padding = ui_pading( 10, 10, 10, 10 ),
                childGap = ui_childGap(16),
                childAlignment={x=.Center,y=.Center,},
            },
            backgroundColor = col_l_1,
            border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
        }){
            clay.Text("Settings",t_config_small())
            
            if clay.UI()({
                id = clay.ID_LOCAL("top_bar_spacer"),
                layout = {
                    sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
                    padding = ui_pading( 0, 0, 0, 0 ),
                    childGap = ui_childGap(16),
                },
                backgroundColor = {0,0,0,0},
                // border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
            }){
                
            }
            ui_x_button(pd)
            ui_do_drag_bar(pd)
        }
        

        body_id:=clay.ID_LOCAL("body")
        if clay.UI()({
            id = body_id,
            layout = {
                sizing = { width = clay.SizingFit({}), height = clay.SizingFit({min=300,max=cast(f32)g.window_info.h*0.75}) },
                padding = ui_pading( 10, 10, 10, 10 ),
                childGap = ui_childGap(0),
                layoutDirection=.TopToBottom,
            },
            // scroll={vertical=true},
            clip={vertical=true,childOffset = clay.GetScrollOffset(),},
            // childOffset = clay.GetScrollOffset(),
            backgroundColor = col_l_1,
            border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
        }){
            body_box:=clay.GetElementData(body_id).boundingBox
            // fmt.print(body_box,"\n")
            if clay.UI()({
                id = clay.ID_LOCAL("tabs box"),
                layout = {
                    sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
                    padding =  ui_pading( 10, 10, 10, 10 ),
                    childGap = ui_childGap(16),
                    layoutDirection=.LeftToRight,
                    
                },
                border=ui_border(b=2,col=h_col_d_1),
                // scroll={horizontal=true},
                backgroundColor = {0,0,0,0},
            }){
                for tab in ui_settings_tab{
                    if tab != .none{
                        if clay.UI()({
                            id = clay.ID_LOCAL("tab box",cast(u32)tab),
                            layout = {
                                sizing = { width = clay.SizingFit({min=50,max=300}), height = clay.SizingFit({}) },
                                padding =  ui_pading( 10, 10, 10, 10 ),
                                childGap = ui_childGap(0),
                                layoutDirection=.LeftToRight,
                                childAlignment={
                                    x=.Center,
                                    y=.Center,
                                },
                                
                    
                            },
                            
                            // scroll={horizontal=true},
                            backgroundColor = h_col_d_2 if clay.Hovered() else col_l_1 if cast(ui_settings_tab)pd.curent_tab!=tab else h_col_d_3 ,
                            border=ui_border(x=3,y=3,t=3,b=3,col=h_col_d_3),
                        }){

                            if clay.Hovered(){
                                if is_input_event(.ui_l_c){
                                    pd.curent_tab= cast(int)tab
                                }
                            }
                            clay.TextDynamic(fmt.tprint(tab),t_config_small())
                        }
                    }
                }
            }




            index:=0
            // for setting_key ,&data in &g.settings.data{
            for &setting_key in &g.settings.sorted_keys{
                data:=&g.settings.data[hash.adler32(transmute([]u8)setting_key)]
                index+=1
                if cast(ui_settings_tab)pd.curent_tab in data.tab||cast(ui_settings_tab)pd.curent_tab == .All{
                    settings_box_id:=clay.ID_LOCAL("setting box",cast(u32)index)
                    if clay.UI()({//settings box
                        id = settings_box_id,
                        layout = {
                            sizing = { width = clay.SizingGrow({}), height = clay.SizingGrow({}) },
                            padding =  ui_pading( 4, 4, 4, 4 ),
                            childGap = ui_childGap(16),
                            childAlignment={x=.Center,y=.Center,},
                        },
                        backgroundColor = {0,0,0,0},
                        border=ui_border(b=2,col=h_col_d_3),
                        
                    }){
                        b_box:=clay.GetElementData(settings_box_id).boundingBox
                        if b_box.y+b_box.height-1> body_box.y{//This is for spacing for when a element gets disablud for not beeding showne this is janke butt is huge for proformance//! i hope to find somthing better
                            clay.TextDynamic(data.display_name,t_config_small())
                            if clay.UI()({//spacer box
                                id = clay.ID_LOCAL("spacer box",cast(u32)index),
                                layout = {
                                    sizing = { width = clay.SizingGrow({}), height = clay.SizingFit({}) },
                                    padding = ui_pading( 4, 4, 4, 4 ),
                                    childGap = ui_childGap(16),
                                },
                                backgroundColor = {0,0,0,0},
                            }){

                            }
                            
                            if clay.UI()({//spacer box
                                id = clay.ID_LOCAL("interactibl settings box",cast(u32)index),
                                layout = {
                                    sizing = { width = clay.SizingGrow({}), height = clay.SizingFit({}) },
                                    padding = ui_pading( 4, 4, 4, 4) ,
                                    childGap = ui_childGap(16),
                                    childAlignment={x=.Right,y=.Center},
                                },
                                
                                backgroundColor = {0,0,0,0},
                            }){
                                ui_increment_setting_by_tab(id=cast(u32)index,setting_data=data)
                            }
                            
                            if b_box.y > body_box.y+body_box.height{ //this hides things off screane saving masivly on preformance
                                break
                            }
                        }else{//This is for spacing for when a element gets disablud for not beeding showne this is janke butt is huge for proformance
                            if clay.UI()({//spacer box
                                id = clay.ID_LOCAL("spacer box",cast(u32)index),
                                layout = {
                                    sizing = { width = clay.SizingGrow({}), height = clay.SizingFit({}) },
                                    padding = ui_pading( 8, 8, 8, 8 ),
                                    childGap = ui_childGap(16),
                                },
                                backgroundColor = {0,0,0,0},
                            }){
                                clay.Text("W",t_config_small())
                            }
                        }
                    }
                }
            }
        }
    }
}

ui_do_drag_bar::proc(pd:^ui_page_data,){
    if clay.Hovered(){
        if is_input_event(.ui_drag_l_c){
            delta:=rl.GetMouseDelta()
            pd.current_offset+=delta
            // ui_do_b_box(pd,delta)
        }
    }
}
ui_do_b_box::proc(pd:^ui_page_data,){
    b_box:=clay.GetElementData(clay.GetElementId(clay.MakeString(fmt.tprint(pd.id)))).boundingBox
    if b_box.x<0{
        // pd.current_offset.x-=b_box.x
        pd.current_offset.x = 0 - pd.center_offset.x + 0.0001
    }
    if cast(f32)g.window_info.w> b_box.width{
        if b_box.x+b_box.width > cast(f32)g.window_info.w{
            // pd.current_offset.x-=b_box.x+b_box.width-cast(f32)g.window_info.w
            pd.current_offset.x=cast(f32)g.window_info.w-b_box.width-pd.center_offset.x-1
        }
    }
    
    if b_box.y<0{
        // pd.current_offset.y-=b_box.y 
        pd.current_offset.y = 0 - pd.center_offset.y + 0.0001
    }
    if cast(f32)g.window_info.h> b_box.height{
        if b_box.y+b_box.height > cast(f32)g.window_info.h{
            // pd.current_offset.y-=b_box.y+b_box.height-cast(f32)g.window_info.h
            pd.current_offset.y=cast(f32)g.window_info.h-b_box.height-pd.center_offset.y-0.0001
        } 
    }
    pd.center_offset={cast(f32)(g.window_info.w/2)-(b_box.width/2),cast(f32)(g.window_info.h/2)-(b_box.height/2),}
}
ui_do_all_world_selection_tabs::proc(pd:^ui_page_data){
    for &save_info,tab in &g.ui_st.world_saves_list{
        if save_info.is_dir{
            if clay.UI()({
                id = clay.ID_LOCAL("world_selection_tab",cast(u32)tab),
                layout = {
                    sizing = { width = clay.SizingGrow({}), height = clay.SizingFit({}) },
                    padding = ui_pading( 4, 4, 4, 4 ),
                    childGap = ui_childGap(16),
                    childAlignment={x=.Center,y=.Center,},
                    layoutDirection=.TopToBottom,
                },  
                backgroundColor = h_col_l_2 if clay.Hovered() else {0,0,0,0} if pd.curent_tab!=tab else h_col_l_1,
                
                border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
            }){
                clay.TextDynamic(save_info.name,t_config_medium(align=.Left))
                year, month, day:=time.date(save_info.creation_time)
                clay.TextDynamic(fmt.tprint("Created On::",fmt.tprint(year, month, day)),t_config_small(align=.Right))
                if clay.Hovered(){ if is_input_event(.ui_l_c){pd.curent_tab=tab}}
            }
        }
    }
}
ui_x_button::proc(pd:^ui_page_data){
    if clay.UI()({
        id = clay.ID_LOCAL("x"),
        layout = {
            sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
            padding = ui_pading( 4, 4.1, 2, 4 ),
            childGap = ui_childGap(16),
            childAlignment={x=.Center,y=.Center,},
            
        },
        backgroundColor = col_l_1,
        
        border=ui_border(x=2,y=2,t=2,b=2,col=h_col_d_3),
    }){
        clay.Text("x",t_config_small(align=.Center))
        if clay.Hovered(){
            if is_input_event(.ui_l_c){
                pd.is_open =false
            }
        }
    }
}
ui_increment_setting_by_tab::proc(id:u32,setting_data:^setting_info){
    ic_by:=setting_data.increment_by



     switch &v in &setting_data.data {
         
        case f32:
            if clay.Hovered(){
                if is_input_event(.ui_shift){
                    ic_by*=10
                }
            }
            ui_increment_button(id=id,name="i d button",v=&v,i=-ic_by,display="<")
            clay.TextDynamic(fmt.tprint(v),t_config_small())
            ui_increment_button(id=id,name="i up button",v=&v,i=ic_by,display=">")
        case clay.Color:
            if clay.Hovered(){
                if is_input_event(.ui_shift){
                    ic_by*=8
                }
            }
            if clay.UI()({//spacer box
                id = clay.ID_LOCAL("color settings box",id),
                layout = {
                    sizing = { width = clay.SizingGrow({}), height = clay.SizingFit({}) },
                    padding = ui_pading( 4, 4, 4, 4 ),
                    childGap = ui_childGap(4),
                    childAlignment={x=.Right,y=.Center},
                },
                border=ui_border(x=2,y=2,t=2,b=2,col=h_col_d_3),
                backgroundColor = v,
            }){ 
            swap_text_col:bool=true
            if is_dark_mode { swap_text_col= !swap_text_col}
            if v.r+v.g+v.b>255*3/2{
                swap_text_col= !swap_text_col
            }
            ui_increment_button(id=id,name="i rd button",v=&v.r,i=-ic_by,display="<",max=255,min=0)
            clay.Text("R:",t_config_small(swap_text_col))
            clay.TextDynamic(fmt.tprint(v.r),t_config_small(swap_text_col))
            ui_increment_button(id=id,name="i rup button",v=&v.r,i=ic_by,display=">",max=255,min=0)

            ui_increment_button(id=id,name="i gd button",v=&v.g,i=-ic_by,display="<",max=255,min=0)
            clay.Text("G:",t_config_small(swap_text_col))
            clay.TextDynamic(fmt.tprint(v.g),t_config_small(swap_text_col))
            ui_increment_button(id=id,name="i gup button",v=&v.g,i=ic_by,display=">",max=255,min=0)

            ui_increment_button(id=id,name="i bd button",v=&v.b,i=-ic_by,display="<",max=255,min=0)
            clay.Text("B:",t_config_small(swap_text_col))
            clay.TextDynamic(fmt.tprint(v.b),t_config_small(swap_text_col))
            ui_increment_button(id=id,name="i bup button",v=&v.b,i=ic_by,display=">",max=255,min=0)

            ui_increment_button(id=id,name="i ad button",v=&v.a,i=-ic_by,display="<",max=255,min=0)
            clay.Text("A:",t_config_small(swap_text_col))
            clay.TextDynamic(fmt.tprint(v.a),t_config_small(swap_text_col))
            ui_increment_button(id=id,name="i aup button",v=&v.a,i=ic_by,display=">",max=255,min=0)
            }
        case bool:
            ui_TF_button(id,v=&v)
     }


}
ui_TF_button::proc(id:u32,v:^bool){
    should_update_settings:bool=false
    if clay.UI()({
        id = clay.ID_LOCAL("tf",id),
        layout = {
            sizing = ui_fixed_size(32,32),
            padding = ui_pading(4, 4, 4, 4 ),
            childGap = ui_childGap(8),
            childAlignment={x=.Center,y=.Center},
        },
        border=ui_border(x=2,y=2,t=2,b=2,col=h_col_d_3),
        backgroundColor = h_col_d_1 if !clay.Hovered() else h_col_d_3,
    }){
        if clay.Hovered(){
            if is_input_event(.ui_l_c){
                v^=!v^
                should_update_settings = true
            }
        }
        if v^{
            if clay.UI()({
                id = clay.ID_LOCAL("tf_in",id),
                layout = {
                    sizing = ui_fixed_size(30,30),
                    padding = ui_pading(4, 4, 4, 4 ),
                    childGap = ui_childGap(8),
                    childAlignment={x=.Center,y=.Center},
                },
                border=ui_border(x=2,y=2,t=2,b=2,col=h_col_d_3),
                backgroundColor = h_col_d_2 if !clay.Hovered() else h_col_d_3,
            }){}
        }
        if !v^{
            if clay.UI()({
                id = clay.ID_LOCAL("tf_in",id),
                layout = {
                    sizing = ui_fixed_size(30,30),
                    padding = ui_pading(4, 4, 4, 4 ),
                    childGap = ui_childGap(8),
                    childAlignment={x=.Center,y=.Center},
                },
                backgroundColor = col_l_2 if !clay.Hovered() else col_l_3,
            }){
                
            }
        }
    }
    if should_update_settings{save_settings()}
}

ui_fixed_size::proc(x,y:f32)->(sizing:clay.Sizing){
    sizing = { width = clay.SizingFixed(x*cast(c.float)ui_m) , height = clay.SizingFixed(y*cast(c.float)ui_m) }
    return sizing
}
ui_pading::proc(x,y,t,b:f32)->(pading:clay.Padding){

    pading = { cast(u16)(x*ui_m) , cast(u16)(y*ui_m) ,cast(u16)(t*ui_m),cast(u16)(b*ui_m)}
    return pading
}
ui_border::proc(x:f32=0,y:f32=0,t:f32=0,b:f32=0,col:clay.Color)->(border:clay.BorderElementConfig){
    border={color=col,width={left=cast(u16)(x*ui_m),right=cast(u16)(y*ui_m),top=cast(u16)(t*ui_m),bottom=cast(u16)(b*ui_m)}}
    return 
}
// border={color=h_col_d_3,width={left=2,right=2,top=2,bottom=2}},
ui_childGap::proc(gap:f32)->(c_gap:u16){
    c_gap = cast(u16)(gap*ui_m)
    return c_gap
}
t_config_small::proc(is_dark:bool=false,is_hl:bool=false, align: clay.TextAlignment=.Left,user_data:rawptr=nil) -> (tc:^clay.TextElementConfig) {

    col_1:clay.Color
    col_2:clay.Color
    if !is_dark{
        col_1=text_d_col_1
        col_2=text_d_col_1
        if is_hl{
            col_1=h_text_d_col_1
            col_2=h_text_d_col_1
        }
    }else{
        col_1=text_l_col_1
        col_2=text_l_col_1
        if is_hl{
            col_1=h_text_l_col_1
            col_2=h_text_l_col_1
        }
    }
    tc=clay.TextConfig({fontId=0,fontSize=font_size_s,letterSpacing=cast(u16)(2*fs_m),textColor = col_1,textAlignment=align,userData=user_data})
    return
}
t_config_medium::proc(is_dark:bool=false,is_hl:bool=false,align: clay.TextAlignment=.Left,user_data:rawptr=nil) -> (tc:^clay.TextElementConfig) {

    col_1:clay.Color
    col_2:clay.Color
    if !is_dark{
        col_1=text_d_col_1
        col_2=text_d_col_1
        if is_hl{
            col_1=h_text_d_col_1
            col_2=h_text_d_col_1
        }
    }else{
        col_1=text_l_col_1
        col_2=text_l_col_1
        if is_hl{
            col_1=h_text_l_col_1
            col_2=h_text_l_col_1
        }
    }
    tc=clay.TextConfig({fontId=0,fontSize=font_size_m,letterSpacing=cast(u16)(2*fs_m),textColor = col_1,textAlignment=align,userData=user_data})
    return
}
t_config_big::proc(is_dark:bool=false,is_hl:bool=false,align: clay.TextAlignment=.Left,user_data:rawptr=nil) -> (tc:^clay.TextElementConfig) {

    col_1:clay.Color
    col_2:clay.Color
    if !is_dark{
        col_1=text_d_col_1
        col_2=text_d_col_1
        if is_hl{
            col_1=h_text_d_col_1
            col_2=h_text_d_col_1
        }
    }else{
        col_1=text_l_col_1
        col_2=text_l_col_1
        if is_hl{
            col_1=h_text_l_col_1
            col_2=h_text_l_col_1
        }
    }
    tc=clay.TextConfig({fontId=0,fontSize=font_size_b,letterSpacing=cast(u16)(2*fs_m),textColor = col_1,textAlignment=align,userData=user_data})
    return
}

ui_increment_button::proc(
    name:string,
    id:u32,
    v:^f32,
    i:f32,
    display:string=" ",
    max:f32=10000,
    min:f32=-10000,
){
    should_update_settings:bool=false
    if clay.UI()({
        id = clay.ID_LOCAL(name,id),
        layout = {
            sizing = { width = clay.SizingFit({}), height = clay.SizingGrow({}) },
            padding = ui_pading( 4, 4, 4, 4 ),
            childGap = ui_childGap(8),
            childAlignment={x=.Center,y=.Center},
        },
        border=ui_border(x=2,y=2,t=2,b=2,col=h_col_d_3),
        backgroundColor = h_col_d_1 if !clay.Hovered() else h_col_d_3,
    }){
        clay.TextDynamic(display,t_config_small(true))
        if clay.Hovered(){

            if is_input_event(.ui_l_c){
                v^ += i
                should_update_settings=true
            }
            if is_input_event(.ui_r_c){
                v^ -= i
                should_update_settings=true
            }
            if v^<min{v^=max}
            if v^>max{v^=min}
        }
    }
    if should_update_settings{save_settings()}
}




