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

ui_text_box::struct{
    str_builder:        strings.Builder,
    text_edit_state:    edit.State,
}
init_text_box::proc(t_box:^ui_text_box,settings:edit.Settings,){
    t_box.str_builder = strings.builder_make()
    edit.init(&t_box.text_edit_state,context.allocator,context.allocator)
    t_box.text_edit_state.settings=settings
}
destroy_text_box::proc(t_box:^ui_text_box){
    delete(t_box.str_builder.buf)
    edit.destroy(&t_box.text_edit_state)
}
defalt_text_box_settings::proc()->(s:edit.Settings){
    s.max_char = 100
    s.max_line_len = 20
    s.carit_color={255,255,255,255}
    s.blink_duration = .35
    s.get_clipboard =  get_clipboard
    s.set_clipboard =  set_clipboard
    s.do_syntax_highlig=true

    // s.set_up_index_overide
	// s.set_downe_index_overide
    return
}

ui_input_text_box::proc(t_box:^ui_text_box){
    state:=&t_box.text_edit_state
    builder:=&t_box.str_builder
  
    render_d:= &state.render_data
    settings:= &state.settings
    edit.begin_persistent(state,0,builder)


    render_d.blink_time += g.time.dt

    if render_d.blink_time > settings.blink_duration{
        render_d.blink_time = 0
        render_d.blink = !render_d.blink
    }

    text_box_do_imput(state)

    edit.end(state)
    if clay.UI()({
        id = clay.ID_LOCAL("edit_text_box",cast(u32)state.id),
        layout = {
            sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
            padding = ui_pading( 8, 8, 8, 8 ),
            childGap = ui_childGap(8),
            childAlignment={x=.Center,y=.Center,},
            layoutDirection=.TopToBottom,
        },  
        backgroundColor = h_col_l_2 ,
        
        border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
    }){
        // text_box_element:^text_box_element=new(text_box_element,context.temp_allocator)
        // text_box_element.s=state

        text_string:=strings.to_string(builder^)
        line_start:int
        line_end:int
        for &line_data in &state.line_data{
            line_start=line_end
            line_end+=line_data.width
            
            // fmt.print(line_data.width,"w",len(text_string),"length",line_start,"start",line_end,"end\n")
            line_data.carit_pos=-1
            line_data.state = state
            if state.selection.x >= line_start && state.selection.x <= line_end{
                line_data.carit_pos = state.selection.x - line_start
                line_data.has_carit=true
            }
            t_data:=t_config_medium(align=.Left,user_data=&line_data)
            t_data_hy:=t_config_medium(align=.Left,user_data=&line_data)
            t_data_hy.textColor = {255,255,0,255}
            t_data.wrapMode=.Newlines
            if len(text_string)>=line_end{
                offset:int
                if len(text_string)>0{ if text_string[line_end-1:line_end]=="\n"{

                    offset=1
                    if line_data.width == 1{
                        pading(t_data)
                        if line_data.carit_pos > 0{
                            line_data.has_carit=false 
                        }
                    }
                }}
                if line_start<=line_end-offset{
                    // clay.TextDynamic(text_string[line_start:line_end-offset],t_data)

                    if clay.UI()({
                        id = clay.ID_LOCAL("edit_text_line",cast(u32)state.id),
                        layout = {
                            sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
                            padding = ui_pading( 0, 0, 0, 0 ),
                            childGap = ui_childGap(0),
                            childAlignment={x=.Center,y=.Center,},
                            layoutDirection=.LeftToRight,
                        },  
                        backgroundColor = {0,0,0,0},
                        
                        // border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
                    }){
                        line_i:=0
                        bg_color:[4]f32={0,0,0,0}
                        for r ,i in text_string[line_start:line_end-offset]{
                            line_i=i+line_start
                            if len(state.rune_style)>line_i{
                                if state.rune_style[line_i] == {}{
                                    t_data.textColor = {255,255,255,255}
                                }else{
                                    t_data.textColor.x = cast(f32)state.rune_style[line_i].color.x
                                    t_data.textColor.y = cast(f32)state.rune_style[line_i].color.y
                                    t_data.textColor.z = cast(f32)state.rune_style[line_i].color.z
                                    t_data.textColor.w = cast(f32)state.rune_style[line_i].color.w
                                }
                            }
                            bg_color={0,0,0,0}
                            if line_i == state.selection.x&&!render_d.blink{
                                bg_color={255,255,255,255}
                            }
                            text_spasing(bg_color,cast(u32)state.id)
                            if state.selection.x-state.selection.y!=0&& state.selection.x > i && state.selection.y < i||state.selection.x < i && state.selection.y > i{
                                clay.TextDynamic(text_string[line_i:line_i+1],t_data_hy)
                            }else{
                                clay.TextDynamic(text_string[line_i:line_i+1],t_data)
                            }
                        }
                        line_i+=1
                        bg_color={0,0,0,0}
                        if line_i == state.selection.x&&!render_d.blink{
                            bg_color={255,255,255,255}
                        }
                        text_spasing(bg_color,cast(u32)state.id)
                    }
                }
            }else{
                pading(t_data)
            }
            if line_data.width == 0{
                pading(t_data)
            }
        }
    }
    pading::proc(t_data:^clay.TextElementConfig){
        clay.Text("\xC2\xA0",t_data)
    }
}
text_spasing::proc(bg_color:[4]f32={0,0,0,0},id:u32){
        if clay.UI()({
        id = clay.ID_LOCAL("edit_text_pading",id),
        layout = {
            sizing = { width = clay.SizingFit({}), height = clay.SizingGrow({}) },
            padding = ui_pading( 1, 1, 1, 1 ),
            childGap = ui_childGap(0),
            childAlignment={x=.Center,y=.Center,},
            layoutDirection=.LeftToRight,
        },  
        backgroundColor = bg_color,
    }){

    }
}

text_box_do_imput::proc(state:^edit.State,){
    render_d:= &state.render_data
    if state.is_activ{
        fmt.print("waffles\n")
    new_rune:=rl.GetCharPressed()
    for new_rune != 0{
        edit.input_rune(state,new_rune)
        new_rune=rl.GetCharPressed()
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_back_space,   always_consume_d=true,){
        edit.perform_command(state,.Backspace)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_del,          always_consume_d=true,){
        edit.perform_command(state,.Delete)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_a_left,       always_consume_d=true,){
        edit.perform_command(state,.Left)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_a_right,      always_consume_d=true,){
        edit.perform_command(state,.Right)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_a_up,         always_consume_d=true,){
        edit.perform_command(state,.Up)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_a_down,       always_consume_d=true,){
        edit.perform_command(state,.Down)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_enter,        always_consume_d=true,){
        edit.perform_command(state,.New_Line)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_coppy,        always_consume_d=true,){
        edit.perform_command(state,.Copy)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_past,        always_consume_d=true,){
        edit.perform_command(state,.Paste)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_cut,        always_consume_d=true,){
        edit.perform_command(state,.Cut)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_t_select_left,always_consume_d=true,){
        edit.perform_command(state,.Select_Left)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_t_select_right,always_consume_d=true,){
        edit.perform_command(state,.Select_Right)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_t_select_up,always_consume_d=true,){
        edit.perform_command(state,.Select_Up)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_t_select_down,always_consume_d=true,){
        edit.perform_command(state,.Select_Down)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    if is_input_event(.ui_t_select_all,always_consume_d=true,){
        edit.perform_command(state,.Select_All)
        state.repeat_cool_down=-edit.repeat_cool_down_time*2
        render_d.blink=false
        render_d.blink_time=0
    }
    
    // fmt.print(strings.to_string(state.builder^),"\n")
    state.repeat_cool_down += g.time.dt
    if state.repeat_cool_down <-5 {state.repeat_cool_down = 0}
    if state.repeat_cool_down > edit.repeat_cool_down_time{
        if is_input_event(.ui_back_space,   ignore_p=true,){
            edit.perform_command(state,.Backspace)
            state.repeat_cool_down=edit.repeat_cool_down_time/2
            render_d.blink=false
            render_d.blink_time=0
        }
        if is_input_event(.ui_del,          ignore_p=true,){
            edit.perform_command(state,.Delete)
            state.repeat_cool_down=edit.repeat_cool_down_time/2
            render_d.blink=false
            render_d.blink_time=0
        }
        if is_input_event(.ui_a_left,       ignore_p=true,){
            edit.perform_command(state,.Left)
            state.repeat_cool_down=edit.repeat_cool_down_time/2
            render_d.blink=false
            render_d.blink_time=0
        }
        if is_input_event(.ui_a_right,      ignore_p=true,){
            edit.perform_command(state,.Right)
            state.repeat_cool_down=edit.repeat_cool_down_time/2
            render_d.blink=false
            render_d.blink_time=0
        }
        if is_input_event(.ui_a_up,         ignore_p=true,){
            edit.perform_command(state,.Up)
            state.repeat_cool_down=-edit.repeat_cool_down_time/2
            render_d.blink=false
            render_d.blink_time=0
        }
        if is_input_event(.ui_a_down,       ignore_p=true,){
            edit.perform_command(state,.Down)
            state.repeat_cool_down=-edit.repeat_cool_down_time/2
            render_d.blink=false
            render_d.blink_time=0
        }
        if is_input_event(.ui_enter,        ignore_p=true,){
            edit.perform_command(state,.New_Line) 
            state.repeat_cool_down=0
            render_d.blink=false
            render_d.blink_time=0
        }
    }
    }

}

get_clipboard::proc(user_data: rawptr) -> (text: string, ok: bool){
    c_str:=rl.GetClipboardText()
	str:=strings.clone_from_cstring(c_str)
	// delete_cstring(c_str)
	text=str
	ok=true
	return
}
set_clipboard:: proc(user_data: rawptr, text: string) -> (ok: bool){
	new_string:=strings.clone_to_cstring(text)
    rl.SetClipboardText(new_string)	
	// delete_cstring(new_string)
	return true
}