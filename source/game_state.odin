package game

import "core:fmt"
import "core:math"
import "core:math/rand"
import b2 "box2d"
import rl "vendor:raylib"
import "base:runtime"
import clay "/clay-odin"
import "core:sort"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:hash"




state::struct{
    world:world_state,
	particle:all_particle_data,
	rand_number:f32,
}
world_state::struct{
    name:string,
}
settings::struct{
	data:map[u32]setting_info,
    sorted_keys:[dynamic]string,
}
setting_info::struct{
    display_name:string,
    temp_string:[100]u8,
	tab:bit_set[ui_settings_tab],
    type:ui_setting_field_type,
    data:setting_data,
    defalt_data:setting_data,
    increment_by:f32,
	hide_setting:bool,
}
setting_data::union{
    f32,
    clay.Color,
    bool,
}
app_mode::enum{
    starting_menu,
    loading,
    in_game,
}
app_state::struct{
    mode:app_mode,
}
reg_update_setting::proc(data:setting_info){
	settings:=&g.settings.data
    hash_id:=hash.adler32(transmute([]u8)data.display_name)
    if &settings[hash_id] !=nil{
        delete(settings[hash_id].display_name)
    }
    settings[hash_id]=data

}
get_setting::proc(id:string)->(data:^setting_info){
	settings:=&g.settings.data
	data=&settings[hash.adler32(transmute([]u8)id)]
	return
}

clean_up_ui_data::proc(){
    clean_up_settings_data()
    for f_info in g.ui_st.world_saves_list{
        delete(f_info.fullpath)
        // delete(f_info.name)
    }
    delete(g.ui_st.world_saves_list)
}


clean_up_settings_data::proc(){
    for key ,&data in &g.settings.data {
        if &data.display_name != nil{
            delete(data.display_name)
            // delete(key)
        }
    }
	delete(g.settings.data)
    delete(g.settings.sorted_keys)
}

init_defalt_ui_settings::proc(){

    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Light 1"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{141, 188, 224, 255,},
        defalt_data=clay.Color{141, 188, 224, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Light 2"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{121, 166, 201, 255,},
        defalt_data=clay.Color{121, 166, 201, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Light 3"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{102, 150, 186, 255,},
        defalt_data=clay.Color{102, 150, 186, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Dark 1"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{0, 28, 48, 255,},
        defalt_data=clay.Color{0, 28, 48, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Dark 2"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{2, 35, 59, 255,},
        defalt_data=clay.Color{2, 35, 59, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Dark 3"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{4, 46, 77, 255,},
        defalt_data=clay.Color{4, 46, 77, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Hilight Light 1"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{66, 135, 245, 255,},
        defalt_data=clay.Color{66, 135, 245, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Hilight Light 2"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{31, 30, 99, 255,},
        defalt_data=clay.Color{31, 30, 99, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Hilight Light 3"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{56, 115, 209, 255,},
        defalt_data=clay.Color{56, 115, 209, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Hilight Dark 1"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{6, 16, 56, 255,},
        defalt_data=clay.Color{6, 16, 56, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Hilight Dark 2"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{14, 26, 77, 255,},
        defalt_data=clay.Color{14, 26, 77, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Color Hilight Dark 3"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{20, 35, 97, 255,},
        defalt_data=clay.Color{20, 35, 97, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Text Color Light 1"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{201, 200, 219, 255,},
        defalt_data=clay.Color{201, 200, 219, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Text Color Light 2"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{169, 168, 189, 255,},
        defalt_data=clay.Color{169, 168, 189, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Text Color Dark 1"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{7, 7, 8, 255,},
        defalt_data=clay.Color{7, 7, 8, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Text Color Dark 2"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{23, 23, 26, 255,},
        defalt_data=clay.Color{23, 23, 26, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Text Color Light Hilight 1"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{66, 56, 255,255,},
        defalt_data=clay.Color{66, 56, 255,255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Text Color Light Hilight 2"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{50, 42, 201, 255,},
        defalt_data=clay.Color{50, 42, 201, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Text Color Dark Hilight 1"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{4, 1, 48,255,},
        defalt_data=clay.Color{4, 1, 48,255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Text Color Dark Hilight 2"),
        tab={.UI,.Colors,},
        type=.color,
        data=clay.Color{7, 2, 77, 255,},
        defalt_data=clay.Color{7, 2, 77, 255,},
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Font Size Big"),
        tab={.UI,},
        type=.number,
        data=64,
        defalt_data=64,
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Font Size Medium"),
        tab={.UI,},
        type=.number,
        data=32,
        defalt_data=32,
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Font Size Small"),
        tab={.UI,},
        type=.number,
        data=16,
        defalt_data=16,
        increment_by=1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Font Size Multiplier"),
        tab={.UI,},
        type=.scaler,
        data=1,
        defalt_data=1,
        increment_by=.1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Size Multiplier"),
        tab={.UI,},
        type=.scaler,
        data=1,
        defalt_data=1,
        increment_by=.1,
        hide_setting=false,
    })
    reg_update_setting(data={
        display_name=fmt.aprint("UI Dark Mode"),
        tab={.UI,},
        type=.t_f,
        data=true,
        defalt_data=true,
        increment_by=1,
        hide_setting=false,

    })
    load_settings()
    sort_settings_keys()
    // save_settings()
}
load_settings::proc(){
    // clear(&g.settings.data)
    // load_json_unmarshal(&g.settings.data,path="settings/settings.json")

    temp_settings:map[u32]setting_info

    load_json_unmarshal(&temp_settings,path="settings/settings.json")
    for key ,data in temp_settings{
        reg_update_setting(data)
    }
    delete(temp_settings)

}
save_settings::proc(){
    w_json_marshal(g.settings.data,"settings/settings.json")
}

ui_m:f32
fs_m:f32

font_size_s:u16
font_size_m:u16
font_size_b:u16
    
text_l_col_1:clay.Color
text_l_col_2:clay.Color
text_d_col_1:clay.Color
text_d_col_2:clay.Color

h_text_l_col_1:clay.Color
h_text_l_col_2:clay.Color
h_text_d_col_1:clay.Color
h_text_d_col_2:clay.Color

col_l_1:clay.Color
col_l_2:clay.Color
col_l_3:clay.Color
col_d_1:clay.Color
col_d_2:clay.Color
col_d_3:clay.Color

h_col_l_1:clay.Color
h_col_l_2:clay.Color
h_col_l_3:clay.Color
h_col_d_1:clay.Color
h_col_d_2:clay.Color
h_col_d_3:clay.Color

is_dark_mode:bool

cash_settings_ui::proc(){
    is_dark_mode=get_setting("UI Dark Mode").data.(bool)

    ui_m=get_setting("UI Size Multiplier").data.(f32)
    fs_m=get_setting("UI Font Size Multiplier").data.(f32)

    font_size_s=cast(u16)(get_setting("UI Font Size Small").data.(f32)*fs_m)
    font_size_m=cast(u16)(get_setting("UI Font Size Medium").data.(f32)*fs_m)
    font_size_b=cast(u16)(get_setting("UI Font Size Big").data.(f32)*fs_m)
    if !is_dark_mode{
        text_l_col_1=get_setting("UI Text Color Light 1").data.(clay.Color)
        text_l_col_2=get_setting("UI Text Color Light 2").data.(clay.Color)
        text_d_col_1=get_setting("UI Text Color Dark 1").data.(clay.Color)
        text_d_col_2=get_setting("UI Text Color Dark 2").data.(clay.Color)

        h_text_l_col_1=get_setting("UI Text Color Light Hilight 1").data.(clay.Color)
        h_text_l_col_2=get_setting("UI Text Color Light Hilight 2").data.(clay.Color)
        h_text_d_col_1=get_setting("UI Text Color Dark Hilight 1").data.(clay.Color)
        h_text_d_col_2=get_setting("UI Text Color Dark Hilight 2").data.(clay.Color)

        col_l_1=get_setting("UI Color Light 1").data.(clay.Color)
        col_l_2=get_setting("UI Color Light 2").data.(clay.Color)
        col_l_3=get_setting("UI Color Light 3").data.(clay.Color)

        col_d_1=get_setting("UI Color Dark 1").data.(clay.Color)
        col_d_2=get_setting("UI Color Dark 2").data.(clay.Color)
        col_d_3=get_setting("UI Color Dark 3").data.(clay.Color)

        h_col_l_1=get_setting("UI Color Hilight Light 1").data.(clay.Color)
        h_col_l_2=get_setting("UI Color Hilight Light 2").data.(clay.Color)
        h_col_l_3=get_setting("UI Color Hilight Light 3").data.(clay.Color)

        h_col_d_1=get_setting("UI Color Hilight Dark 1").data.(clay.Color)
        h_col_d_2=get_setting("UI Color Hilight Dark 2").data.(clay.Color)
        h_col_d_3=get_setting("UI Color Hilight Dark 3").data.(clay.Color)
    }
    if is_dark_mode{
        text_d_col_1=get_setting("UI Text Color Light 1").data.(clay.Color)
        text_d_col_2=get_setting("UI Text Color Light 2").data.(clay.Color)
        text_l_col_1=get_setting("UI Text Color Dark 1").data.(clay.Color)
        text_l_col_2=get_setting("UI Text Color Dark 2").data.(clay.Color)

        h_text_d_col_1=get_setting("UI Text Color Light Hilight 1").data.(clay.Color)
        h_text_d_col_2=get_setting("UI Text Color Light Hilight 2").data.(clay.Color)
        h_text_l_col_1=get_setting("UI Text Color Dark Hilight 1").data.(clay.Color)
        h_text_l_col_2=get_setting("UI Text Color Dark Hilight 2").data.(clay.Color)

        col_d_1=get_setting("UI Color Light 1").data.(clay.Color)
        col_d_2=get_setting("UI Color Light 2").data.(clay.Color)
        col_d_3=get_setting("UI Color Light 3").data.(clay.Color)

        col_l_1=get_setting("UI Color Dark 1").data.(clay.Color)
        col_l_2=get_setting("UI Color Dark 2").data.(clay.Color)
        col_l_3=get_setting("UI Color Dark 3").data.(clay.Color)

        h_col_d_1=get_setting("UI Color Hilight Light 1").data.(clay.Color)
        h_col_d_2=get_setting("UI Color Hilight Light 2").data.(clay.Color)
        h_col_d_3=get_setting("UI Color Hilight Light 3").data.(clay.Color)

        h_col_l_1=get_setting("UI Color Hilight Dark 1").data.(clay.Color)
        h_col_l_2=get_setting("UI Color Hilight Dark 2").data.(clay.Color)
        h_col_l_3=get_setting("UI Color Hilight Dark 3").data.(clay.Color)
    }
}

sort_settings_keys::proc(){
    clear(&g.settings.sorted_keys)
    for k, d in g.settings.data {
        append(&g.settings.sorted_keys, d.display_name);
    }
    
    slice.sort_by(g.settings.sorted_keys[:], proc(a, b: string) -> bool {
        return alphabetical_comp(a,b,0)
    })
}
string_less_proc :: proc(a, b: string) -> bool {
	return a < b;
}
alphabetical_comp::proc(a, b: string,index:int) -> bool{
    if len(a)>index||len(a)>index{
        av:= a[0:index+1]
        bv:= b[0:index+1]
        // fmt.print("{a}",a[0:index+1],"\n")
        // fmt.print("{b}",b[0:index+1],"\n")
        if av == bv{
            return alphabetical_comp(a,b,index+1)
        }
        return av < bv
    }
    return true
}
