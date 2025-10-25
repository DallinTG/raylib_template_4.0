package game

import "core:math/rand"
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
import hm "handle_map_static"

t_box_handle:: distinct hm.Handle
max_text_boxes::50
tex_box_data::struct{
    t_boxes: hm.Handle_Map(ui_text_box, t_box_handle, max_text_boxes),
    curent_activ_box:t_box_handle,
}

ui_text_box::struct{
    handle:t_box_handle,
    name:string,
    str_builder:        strings.Builder,
    text_edit_state:    edit.State,
    rd_texture: rl.RenderTexture,
    element_declaration:proc(t_box:^ui_text_box)->(clay.ElementDeclaration),
}

init_text_box::proc(settings:edit.Settings,name:string="text_box")->(handle:t_box_handle){
    t_box:ui_text_box
    t_box.name = name
    t_box.str_builder = strings.builder_make()
    edit.init(&t_box.text_edit_state,context.allocator,context.allocator)
    t_box.text_edit_state.settings=settings
    
    // t_box.rd_texture=rl.LoadRenderTexture(1000, 1000)
    handle=hm.add(&g.tex_box_data.t_boxes,t_box)
    t_box_d :=hm.get(&g.tex_box_data.t_boxes,handle)
    t_box_d.text_edit_state.id  = cast(u64)handle.idx
    t_box_d.text_edit_state.gen = cast(u64)handle.gen
    t_box_d.element_declaration=get_defalt_text_box_element_declaration
    // if t_box_d.text_edit_state.styles.bracket_colors == {} {
    //     t_box_d.text_edit_state.styles.bracket_colors = edit.defalt_brackets_colors
    // }
    // if t_box_d.text_edit_state.styles.comment_colors == {} {
    //     t_box_d.text_edit_state.styles.comment_colors = edit.defalt_comment_colors
    // }
    return
}
get_defalt_text_box_element_declaration::proc(t_box:^ui_text_box)->(element_declaration:clay.ElementDeclaration){
    state:=&t_box.text_edit_state 
    element_declaration={
        
        layout = { 
            sizing = { width = clay.SizingFit({}), height = clay.SizingFit({max = 500}) },
            padding = ui_pading( 8, 8, 8, 8 ),
            childGap = ui_childGap(8),
            childAlignment={x=.Left,y=.Center,},
            layoutDirection=.TopToBottom,
        },  
        
        clip={vertical=true,childOffset = clay.GetScrollOffset(),},
        backgroundColor = h_col_l_2 ,
        
        border=ui_border(x=4,y=4,t=4,b=4,col=h_col_d_3),
    }
    return
}
destroy_text_box::proc(handle:t_box_handle){
    t_box:=hm.get(&g.tex_box_data.t_boxes,handle)
    delete(t_box.str_builder.buf)
    edit.destroy(&t_box.text_edit_state)
    rl.UnloadRenderTexture(t_box.rd_texture)
}
destroy_all_text_boxes::proc(){
    ent_iter := hm.make_iter(&g.tex_box_data.t_boxes)
	for e, h in hm.iter(&ent_iter) {
        destroy_text_box(h)
	}
}
maintain_textbox::proc(t_box:^ui_text_box){

    state:=&t_box.text_edit_state
    builder:=&t_box.str_builder
    render_d:= &state.render_data
    if g.tex_box_data.curent_activ_box==t_box.handle{
        t_box.text_edit_state.is_activ = true
    }else{
        t_box.text_edit_state.is_activ = false
    }
    element_declaration:=t_box.element_declaration(t_box)
    el_id:=clay.ID_LOCAL(t_box.name,cast(u32)state.id)
    
    if clay.UI(el_id)(
        element_declaration
    ){
        box_box:=clay.GetElementData(el_id).boundingBox
        if clay.Hovered(){
            if is_input_event(.ui_l_c,never_consume_d=true,never_consume_p=true){
                g.tex_box_data.curent_activ_box=t_box.handle
            }
        }
        
        text_string:=strings.to_string(builder^)
        line_start:int
        line_end:int
        text_bunch_count:=0
        
        for &line_data, line_c in &state.line_data{
            line_data.line_width=0
            line_start=line_end
            line_end+=line_data.char_count
        
            line_data.carit_pos=-1
            line_data.carit_w_pos=0

            l_box:clay.BoundingBox
            if state.selection.x >= line_start && state.selection.x <= line_end{
                line_data.carit_pos = state.selection.x - line_start
            }
            t_data_defalt:=&state.settings.styles.rune_
            // t_data_defalt.wrapMode=.Newlines
            
            if len(text_string)>=line_end{
                offset:int
                if len(text_string)>0{ if text_string[line_end-1:line_end]=="\n"{

                    offset=1
                    if line_data.char_count == 1{
                        pading(t_data_defalt)
                    }
                }}
                if line_start<=line_end-offset{
                    edit_text_line_id:=clay.ID_LOCAL(t_box.name,cast(u32)(line_c+1)*1000)
                    if clay.UI(edit_text_line_id)({
                        // id = edit_text_line_id,
                        layout = {
                            sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
                            padding = ui_pading( 0, 0, 0, 0 ),
                            childGap = ui_childGap(0),
                            childAlignment={x=.Left,y=.Center,},
                            layoutDirection=.LeftToRight,
                        },  
                        backgroundColor = {0,0,0,0},
                    }){
                        // line_str:string=[]
                        line_i:=0
                        start_bunch:int=line_start
                        end_bunch:int=line_end-offset
                        last_t_data:^edit.rune_style=t_data_defalt
                        t_data:^edit.rune_style=t_data_defalt
                        if len(state.rune_style)>0{
                            last_t_data=&state.rune_style[line_i]
                            t_data=&state.rune_style[line_i]
                        }
                        l_box=clay.GetElementData(edit_text_line_id).boundingBox
                        // line_data.line_width=l_box.width
                        line_data.line_hight=l_box.height
                        // line_data.line_x_pos=l_box.x
                        // line_data.line_y_pos=l_box.y                        
                        for r ,i in text_string[line_start:line_end-offset]{

                            line_i=i+line_start
                            t_data = &state.rune_style[line_i]

                            if t_data.next_t_bunch||line_i == state.selection.x{
                                do_text_bunch(state,&line_data,&text_string,start_bunch,line_i,last_t_data,&text_bunch_count) 
                                start_bunch=line_i
                                last_t_data=t_data
                            }
                            
                        }
                        if end_bunch >0{
                            do_text_bunch(state,&line_data,&text_string,start_bunch,end_bunch,t_data,&text_bunch_count)
                        }
                        line_i+=1
                        if line_data.carit_pos > -1{
                            text_cursor(state,{line_data.carit_w_pos,0},{2,line_data.line_hight},{255,255,255,255},cast(u32)state.id)
                        }
                    }
                }
            }else{
                pading(t_data_defalt)
            }
            if line_data.char_count == 0{
                pading(t_data_defalt)
            }
        }
    }
    pading::proc(t_data:^clay.TextElementConfig){
        clay.Text("\xC2\xA0",t_data)
    }
    do_text_bunch::proc(state:^edit.State,line_data:^edit.Line_Data,str:^string,start:int,end:int,t_data:^edit.rune_style,bunch_count:^int){
        render_d:= &state.render_data
        bunch_count^+=1
        m_str:=str[start:end]
        line_width_step:=measure_text_string(m_str,t_data).x//+cast(f32)t_data.letterSpacing

        if clay.UI(clay.ID_LOCAL("edit_text_bunch",cast(u32)bunch_count^))({
            layout = {
                sizing = { width = clay.SizingFit({}), height = clay.SizingFit({}) },
                padding = ui_pading( 0, cast(f32)t_data.letterSpacing, 0, 0 ),
                childGap = ui_childGap(0),
                childAlignment={x=.Left,y=.Center,},  
            },  
            backgroundColor = {0,0,0,0},
        }){
            if t_data.tag == .tab{
                size_of_space:=cast(i32)measure_text_string(" ",t_data).x
                mod:=math.mod_f32(line_data.line_width, cast(f32)size_of_space * cast(f32)state.settings.tab_size)
                space_px:=(cast(f32)size_of_space * cast(f32)state.settings.tab_size)-mod
                line_width_step = space_px +cast(f32)t_data.letterSpacing
                if clay.UI(clay.ID_LOCAL("tab_space",cast(u32)bunch_count^))({
                    layout = {
                        sizing = { width = clay.SizingFixed(space_px), height = clay.SizingFit({}) }, 
                    },  
                }){}
            }else{
                clay.TextDynamic(str[start:end],t_data)
            }
        }
        
        if line_data.carit_pos > -1 && end <= state.selection.x{
            line_data.carit_w_pos += line_width_step
           
        }
        line_data.line_width += line_width_step
    }
}

text_cursor::proc(state:^edit.State,pos:[2]f32,size:[2]f32,bg_color:[4]f32={0,0,0,0},id:u32){
    render_d:= &state.render_data
    if !render_d.blink && state.is_activ{
        render_d.draw_cursor_tf = true
        if clay.UI(clay.ID_LOCAL("edit_text_cursor",id),)({
            // id = clay.ID_LOCAL("edit_text_cursor",id),
            layout = {
                sizing = { width = clay.SizingFixed(size.x), height = clay.SizingFixed(size.y) },
                padding = ui_pading( 1, 1, 1, 1 ),
                childGap = ui_childGap(0),
                childAlignment={x=.Center,y=.Center,},
                layoutDirection=.LeftToRight,
            },  
            floating = { attachTo = .Parent ,offset=pos},
            backgroundColor = bg_color,
        }){

        }
    }
}

defalt_text_box_settings::proc()->(s:edit.Settings){
    s.max_char = 0
    s.max_line_len = 200
    s.carit_color={255,255,255,255}
    s.blink_duration = .35
    s.tab_size = 4
    s.get_clipboard =  get_clipboard
    s.set_clipboard =  set_clipboard
    s.do_syntax_highlig=true

    sty:=& s.styles

    // sty.rune_=t_config_small()^
    sty.rune_.fontId=0
    sty.rune_.fontSize=16
    sty.rune_.letterSpacing=2
    sty.rune_.lineHeight = 16
    sty.rune_.textColor = {255,255,255,255}
    sty.rune_.wrapMode = .None
    sty_cc:=&sty.comment_colors

    sty.strings               = sty.rune_
    sty.bace_key_word         = sty.rune_
    sty.important_key_word    = sty.rune_
    sty.important_v2_key_word = sty.rune_
    sty.bace_type             = sty.rune_

    sty.strings.textColor               = {133, 69, 20,255}
    sty.bace_key_word.textColor         = {16, 34, 196,255}
    sty.important_key_word.textColor    = {134, 29, 209,255}
    sty.important_v2_key_word.textColor = {133, 12, 24,255}
    sty.bace_type.textColor             = {58, 201, 36,255}
    sty.tab = edit.defalt_tab_style

    sty.comment_colors = edit.defalt_comment_colors

    for &bracket,i in &sty.bracket_colors{
        defalt_bd:=edit.defalt_brackets_colors
        bracket=defalt_bd[i]
    }

    merge_all_rune_settings(sty)



    // s.set_up_index_overide
	// s.set_downe_index_overide
    return
}
merge_all_rune_settings::proc(sty:^edit.style){
    
    sty_cc:=&sty.comment_colors
    merge_defalt_rune_settings(&sty.rune_,&sty_cc.TODO)
    merge_defalt_rune_settings(&sty.rune_,&sty_cc.and)
    merge_defalt_rune_settings(&sty.rune_,&sty_cc.at)
    merge_defalt_rune_settings(&sty.rune_,&sty_cc.defalt)
    merge_defalt_rune_settings(&sty.rune_,&sty_cc.dollar)
    merge_defalt_rune_settings(&sty.rune_,&sty_cc.error)
    merge_defalt_rune_settings(&sty.rune_,&sty_cc.pointer)
    merge_defalt_rune_settings(&sty.rune_,&sty_cc.question)
    merge_defalt_rune_settings(&sty.rune_,&sty_cc.warning)

    merge_defalt_rune_settings(&sty.rune_,&sty.strings)
    merge_defalt_rune_settings(&sty.rune_,&sty.bace_key_word)
    merge_defalt_rune_settings(&sty.rune_,&sty.important_key_word)
    merge_defalt_rune_settings(&sty.rune_,&sty.important_v2_key_word)
    merge_defalt_rune_settings(&sty.rune_,&sty.bace_type)
    merge_defalt_rune_settings(&sty.rune_,&sty.tab)

    

    for &bracket,i in &sty.bracket_colors{
        defalt_bd:=edit.defalt_brackets_colors
        bracket=defalt_bd[i]
        merge_defalt_rune_settings(&sty.rune_,&bracket)
    }
}
merge_defalt_rune_settings::proc(bace_r:^clay.TextElementConfig,over_r:^clay.TextElementConfig){
    if over_r.fontId            == 0  {over_r.fontId         = bace_r.fontId}
    if over_r.fontSize          == 0  {over_r.fontSize       = bace_r.fontSize}
    if over_r.letterSpacing     == 0  {over_r.letterSpacing  = bace_r.letterSpacing}
    if over_r.lineHeight        == 0  {over_r.lineHeight     = bace_r.lineHeight}
    if over_r.textColor         == {} {over_r.textColor      = bace_r.textColor}
    if over_r.userData          ==nil {over_r.userData       = bace_r.userData}
    over_r.wrapMode       = bace_r.wrapMode
    over_r.textAlignment  = bace_r.textAlignment
    // if over_r.wrapMode          !=nil{over_r.wrapMode       = bace_r.wrapMode}
    // if over_r.textAlignment     != .Left {over_r.textAlignment  = bace_r.textAlignment}
}

ui_input_text_box::proc(t_box:^ui_text_box){
    state:=&t_box.text_edit_state
    builder:=&t_box.str_builder
  
    render_d:= &state.render_data
    settings:= &state.settings
    edit.begin_persistent(state,0,builder)
    // state.styles.rune_=t_config_small()^
    // merge_all_rune_settings(&state.styles)

    render_d.blink_time += g.time.dt

    if render_d.blink_time > settings.blink_duration{
        render_d.blink_time = 0
        render_d.blink = !render_d.blink
    }
    if state.is_activ{
        text_box_do_imput(state)
    }
    edit.end(state)
    maintain_textbox(t_box)
  
}


text_box_do_imput::proc(state:^edit.State,){
    render_d:= &state.render_data
    if state.is_activ{
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
    if is_input_event(.ui_tab,   always_consume_d=true,){
        // edit.perform_command(state,.)
        edit.input_rune(state,9)
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