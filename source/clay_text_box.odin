package game

import "core:text/scanner"
import clay "/clay-odin"
import "base:runtime"
import "core:c"
import "core:fmt"
import "core:hash"
import "core:math"
import "core:math/linalg"
import noise "core:math/noise"
import "core:math/rand"
import "core:os"
import "core:path/filepath"
import "core:strconv"
import "core:strings"
import "core:time"
import "core:unicode/utf8"
import hm "handle_map_static"
import edit "text_edit"
import "vendor:cgltf"
import rl "vendor:raylib"

t_box_handle :: distinct hm.Handle
max_text_boxes :: 50
tex_box_data :: struct {
	t_boxes:          hm.Handle_Map(ui_text_box, t_box_handle, max_text_boxes),
	curent_activ_box: t_box_handle,
}

ui_text_box :: struct {
	handle:              t_box_handle,
	name:                string,
	str_builder:         strings.Builder,
	text_edit_state:     edit.State,
	rd_texture:          rl.RenderTexture,
	element_declaration: proc(t_box: ^ui_text_box) -> clay.ElementDeclaration,
}

init_text_box :: proc(
	settings: edit.Settings,
	name: string = "text_box",
) -> (
	handle: t_box_handle,
) {
	t_box: ui_text_box
	t_box.name = name
	t_box.str_builder = strings.builder_make()
	edit.init(&t_box.text_edit_state, context.allocator, context.allocator)
	t_box.text_edit_state.settings = settings

	// t_box.rd_texture=rl.LoadRenderTexture(1000, 1000)
	handle = hm.add(&g.tex_box_data.t_boxes, t_box)
	t_box_d := hm.get(&g.tex_box_data.t_boxes, handle)
	t_box_d.text_edit_state.id = cast(u64)handle.idx
	t_box_d.text_edit_state.gen = cast(u64)handle.gen
	t_box_d.element_declaration = get_defalt_text_box_element_declaration
	// if t_box_d.text_edit_state.styles.bracket_colors == {} {
	//     t_box_d.text_edit_state.styles.bracket_colors = edit.defalt_brackets_colors
	// }
	// if t_box_d.text_edit_state.styles.comment_colors == {} {
	//     t_box_d.text_edit_state.styles.comment_colors = edit.defalt_comment_colors
	// }
	return
}
get_defalt_text_box_element_declaration :: proc(t_box: ^ui_text_box,) -> (element_declaration: clay.ElementDeclaration,) {
	state := &t_box.text_edit_state
	element_declaration = {
		layout = {
			sizing = {width = clay.SizingFit({}), height = clay.SizingFit({max = 500})},
			padding = ui_pading(8, 8, 8, 8),
			childGap = ui_childGap(0),
			childAlignment = {x = .Left, y = .Center},
			layoutDirection = .TopToBottom,
		},
		clip = {vertical = true, childOffset = clay.GetScrollOffset()},
		backgroundColor = h_col_l_2,
		border = ui_border(x = 4, y = 4, t = 4, b = 4, col = h_col_d_3),
	}
	return
}
destroy_text_box :: proc(handle: t_box_handle) {
	t_box := hm.get(&g.tex_box_data.t_boxes, handle)
	delete(t_box.str_builder.buf)
	edit.destroy(&t_box.text_edit_state)
	rl.UnloadRenderTexture(t_box.rd_texture)
}
destroy_all_text_boxes :: proc() {
	ent_iter := hm.make_iter(&g.tex_box_data.t_boxes)
	for e, h in hm.iter(&ent_iter) {
		destroy_text_box(h)
	}
}
maintain_textbox :: proc(t_box: ^ui_text_box) {

	state := &t_box.text_edit_state
	builder := &t_box.str_builder
	render_d := &state.render_data
	if g.tex_box_data.curent_activ_box == t_box.handle {
		t_box.text_edit_state.is_activ = true
	} else {
		t_box.text_edit_state.is_activ = false
	}
	// element_declaration:=t_box.element_declaration(t_box)
	el_id := clay.ID_LOCAL(t_box.name, cast(u32)state.id)

	if clay.UI(el_id)(t_box.element_declaration(t_box)) {
		box_box := clay.GetElementData(el_id).boundingBox
		if clay.Hovered() {
			if is_input_event(.ui_l_c, never_consume_d = true, never_consume_p = true) {
				g.tex_box_data.curent_activ_box = t_box.handle
			}
		}

		text_string := strings.to_string(builder^)
		line_start: int
		line_end: int
		text_bunch_count := 0

		for &line_data, line_c in &state.line_data {
			line_data.line_width = 0
			line_start = line_end
			line_end += line_data.char_count

			line_data.carit_pos = -1
			line_data.carit_w_pos = 0

			l_box: clay.BoundingBox
			if state.selection.x >= line_start && (state.selection.x < line_end) ||
			   (state.selection.x <= line_end && state.selection.x == len(text_string)) {
				line_data.carit_pos = state.selection.x - line_start
			}
			t_data_defalt := &state.settings.styles.rune_
			if len(text_string) >= line_end {
				offset: int
				if len(text_string) > 0 {
					if text_string[line_end - 1:line_end] == "\n" {
						offset = 1
					}
				}
				if line_start <= line_end - offset {
					edit_text_line_id := clay.ID_LOCAL(t_box.name, cast(u32)(line_c + 1) * 1000)
					if clay.UI(edit_text_line_id)(
					{
						layout = {
							sizing = {width = clay.SizingGrow({}), height = clay.SizingFit({})},
							// padding = ui_pading(state.styles.line_pading.x, state.styles.line_pading.y, 	state.styles.line_pading.z, state.styles.line_pading.w),
							padding = ui_pading(state.styles.line_pading.x, state.styles.line_pading.y,0,0), //{z, w} is 0 becus pading is added in the text buch 
							childGap = ui_childGap(0),
							childAlignment = {x = .Left, y = .Center},
							layoutDirection = .LeftToRight,
						},
						border = state.styles.cursor_lin_outline if line_data.carit_pos>-1 else {},
						backgroundColor = {0, 0, 0, 0},
					},
					) {
						line_i := 0
						start_bunch: int = line_start
						end_bunch: int = line_end - offset
						last_t_data: ^edit.rune_style = t_data_defalt
						t_data: ^edit.rune_style = t_data_defalt

						if len(state.rune_style) > 0 {
							last_t_data = &state.rune_style[line_i]
							t_data = &state.rune_style[line_i]
						}
						l_box = clay.GetElementData(edit_text_line_id).boundingBox
						line_data.line_hight = l_box.height
						line_data.line_x_pos = l_box.x
						line_data.line_y_pos = l_box.y
						handle_mouse_interactions(state,text_string,line_data,line_start,line_end)

						for r, i in text_string[line_start:line_end - offset] {
							line_i = i + line_start
							t_data = &state.rune_style[line_i]
							if t_data.next_t_bunch{
								do_text_bunch(
									state,
									&line_data,
									text_string,
									start_bunch,
									line_i,
									last_t_data,
									&text_bunch_count,
								)
								start_bunch = line_i
								last_t_data = t_data
							}
						}
						if end_bunch > 0 {
							do_text_bunch(state,&line_data,text_string,start_bunch,end_bunch,t_data,&text_bunch_count,)
						}
						line_i += 1
						if line_data.carit_pos > -1 {
							text_cursor(
								state,
								{pos_of_rune(state,line_data.carit_pos+line_start,text_string), 0},
								{2, line_data.line_hight},
								{255, 255, 255, 255},
								cast(u32)state.id,
							)
						}
					}
				}
			} else {
				pading(t_data_defalt)
			}
			if line_data.char_count == 0 {
				pading(t_data_defalt)
			}
			maintain_selection_highlighting(state,text_string ,{-box_box.x,-box_box.y},&line_data,line_start,line_end)
		}
		do_highlighting(state)
	}
	pading :: proc(t_data: ^clay.TextElementConfig) {
		clay.Text("\xC2\xA0", t_data)
	}
	do_text_bunch :: proc(
		state: ^edit.State,
		line_data: ^edit.Line_Data,
		str: string,
		start: int,
		end: int,
		t_data: ^edit.rune_style,
		bunch_count: ^int,
	) {
		if start == end {return}
		if t_data.tag == .ignore {return}
		render_d := &state.render_data
		bunch_count^ += 1
		m_str := str[start:end]
		line_width_step := measure_text_string(m_str, t_data).x //+cast(f32)t_data.letterSpacing
		bg_col:=&t_data.background_col
		if clay.UI(clay.ID_LOCAL("edit_text_bunch", cast(u32)bunch_count^))(
		{
			layout = {
				sizing = {width = clay.SizingFit({}), height = clay.SizingGrow({})},
				padding = ui_pading(
					0,
					cast(f32)t_data.letterSpacing,
					state.styles.line_pading.z if !(t_data.tag == .tab) else 0,
					state.styles.line_pading.w if !(t_data.tag == .tab) else 0,
				),
				// padding = ui_pading(0, cast(f32)t_data.letterSpacing, 0, 0),

				childGap = ui_childGap(0),
				childAlignment = {x = .Left, y = .Center},
			},
			backgroundColor = cast([4]f32){cast(f32)bg_col.x,cast(f32)bg_col.y,cast(f32)bg_col.z,cast(f32)bg_col.w,},
		},
		) {
			if t_data.tag == .tab {
				// size_of_space := cast(i32)measure_text_string(" ", t_data).x
				// mod := math.mod_f32(line_data.line_width,cast(f32)size_of_space * cast(f32)state.settings.tab_size,)
	
				// // if mod == cast(f32)size_of_space * cast(f32)state.settings.tab_size {mod = 0}
				// space_px := (cast(f32)size_of_space * cast(f32)state.settings.tab_size) - mod
				// line_width_step = space_px + cast(f32)t_data.letterSpacing

				space_px:=size_of_rune(state,'\t',t_data,line_data.line_width )
				line_width_step = space_px + cast(f32)t_data.letterSpacing

				if clay.UI(clay.ID_LOCAL("tab_space", cast(u32)bunch_count^))({	
					layout = {
						sizing = {width = clay.SizingFixed(space_px), height = clay.SizingGrow({})},
						padding = ui_pading(0, 0, state.styles.line_pading.z, state.styles.line_pading.w),
					},
					border = state.styles.tabs_indicators,
					// backgroundColor = {255,255,255,255,},
				}) {}
			} else {
				clay.TextDynamic(str[start:end], t_data)
			}
		}

		// if line_data.carit_pos > -1 {
		// 	if end <= state.selection.x {
		// 		line_data.carit_w_pos += line_width_step + state.styles.line_pading.x
		// 	} else {
		// 		if start <= state.selection.x {
		// 			line_data.carit_w_pos += measure_text_string(str[start:state.selection.x], t_data).x +state.styles.line_pading.x
		// 		}
		// 	}
		// }
		line_data.line_width += line_width_step

	}
	maintain_selection_highlighting :: proc(
		s: ^edit.State,
		str: string,
		offset: [2]f32,
		ld:^edit.Line_Data,
		lin_start:int,
		lin_end:int,
	) {
		if !edit.has_selection(s) {return}
		// edit.sorted_selection(s)
		tsx:=s.selection.x
		tsy:=s.selection.y
		did_swop:bool
		if s.selection.x > s.selection.y{
			did_swop = true
		}
		if !did_swop{
			if lin_end<=tsx{return}
			if lin_start>=tsy{return}
		}else{
			if lin_end<=tsy{return}
			if lin_start>=tsx{return}
		}
		lin_end_offset:int=1
		if lin_end >= len(str) {lin_end_offset=0}
		pos_of_x_ru:=math.abs(pos_of_rune(s,clamp(tsx,lin_start,lin_end-lin_end_offset),str))
		pos_of_y_ru:=math.abs(pos_of_rune(s,clamp(tsy,lin_start,lin_end-lin_end_offset),str))
		lin_w: f32 =math.abs(pos_of_y_ru - pos_of_x_ru)
		lin_x: f32 =ld.line_x_pos+pos_of_x_ru
		if did_swop {lin_x =ld.line_x_pos+pos_of_y_ru}
		lin_y: f32 =ld.line_y_pos
		lin_h: f32 =ld.line_hight

		append(
			&s.highlighting,
			edit.highlighting_data {
				xy = {lin_x+offset.x,lin_y+offset.y},
				wh = {lin_w, lin_h},
				color = s.styles.selection_col,
			},
		)
	}
}
handle_mouse_interactions::proc(s:^edit.State,str:string,ld:edit.Line_Data,lin_start:int,lin_end:int){
	if clay.Hovered() {
		if is_input_event(.ui_l_c) {
			mous_pos := rl.GetMousePosition()
			new_sel:=lin_start +size_to_rune_count(s,str[lin_start:lin_end],s.rune_style[lin_start:lin_end],mous_pos.x - ld.line_x_pos,)
			s.selection.x = new_sel
			s.selection.y = new_sel
			s.highlighting_ref_pos = new_sel
		}
		if is_input_event(.ui_l_c_d) {
			mous_pos := rl.GetMousePosition()
			new_sel:=lin_start +size_to_rune_count(s,str[lin_start:lin_end],s.rune_style[lin_start:lin_end],mous_pos.x - ld.line_x_pos,)
			if new_sel <= s.highlighting_ref_pos {
				s.selection.x = new_sel
			}
			if new_sel >= s.highlighting_ref_pos{
				s.selection.y = new_sel
			}
		} 
	}
}

text_cursor :: proc(
	state: ^edit.State,
	pos: [2]f32,
	size: [2]f32,
	bg_color: [4]f32 = {0, 0, 0, 0},
	id: u32,
) {
	render_d := &state.render_data
	if !render_d.blink && state.is_activ && !edit.has_selection(state){
		render_d.draw_cursor_tf = true
		if clay.UI(clay.ID_LOCAL("edit_text_cursor", id))(
		{
			// id = clay.ID_LOCAL("edit_text_cursor",id),
			layout = {
				sizing = {width = clay.SizingFixed(size.x), height = clay.SizingFixed(size.y)},
				padding = ui_pading(1, 1, 1, 1),
				childGap = ui_childGap(0),
				childAlignment = {x = .Center, y = .Center},
				layoutDirection = .LeftToRight,
			},
			floating = {attachTo = .Parent, offset = pos, clipTo = .AttachedParent ,pointerCaptureMode = .Passthrough},
			backgroundColor = bg_color,
		},
		) {

		}
	}
}
do_highlighting :: proc(s: ^edit.State) {
	hil_ings := &s.highlighting
	for &hil, i in hil_ings {
		if clay.UI(clay.ID_LOCAL("text_highlighting", cast(u32)i))(
		{
			layout = {
				sizing = {width = clay.SizingFixed(hil.wh.x), height = clay.SizingFixed(hil.wh.y)},
				padding = ui_pading(1, 1, 1, 1),
				childGap = ui_childGap(0),
				childAlignment = {x = .Center, y = .Center},
				layoutDirection = .LeftToRight,
			},
			// floating = { attachTo = .Parent ,offset=hil.xy,clipTo=.AttachedParent ,pointerCaptureMode = .Passthrough},
			floating = {attachTo = .Parent, offset = hil.xy ,pointerCaptureMode = .Passthrough},
			backgroundColor = hil.color,
		},
		) {

		}
	}
	clear(hil_ings)
}
size_to_rune_count :: proc(
	s: ^edit.State,
	str: string,
	sty_ar: []edit.rune_style,
	pos: f32,
) -> (
	count: int,
) {
	str_size: f32
	ru_space_px: f32
	did_brake: bool
	for ru, i in str {
		count = i
		str_size+=size_of_rune(s,ru,&sty_ar[i],str_size)
		if str_size >= pos + (ru_space_px / 2) {
			did_brake = true
			break
		}
	}
	if len(str) - 1 > 0 {
		if !did_brake && str[len(str) - 1] != '\n' {
			count += 1
		}
	}
	return
}
size_of_rune :: proc(s: ^edit.State, ru: rune, ru_sty: ^edit.rune_style,ru_pos:f32=0) -> (str_size: f32) {
	// str_size: f32
	ru_space_px: f32
	did_brake: bool

	// count=i
	if ru_sty.tag == .ignore {return {}}
	if ru_sty.tag == .tab {
		size_of_space := cast(i32)measure_text_rune(' ', &ru_sty.tc).x
		size_of_tab:=(cast(f32)size_of_space+ cast(f32)ru_sty.letterSpacing) * cast(f32)s.settings.tab_size
		mod := math.mod_f32(cast(f32)ru_pos,size_of_tab,)
		// if mod == cast(f32)size_of_space * cast(f32)s.settings.tab_size {mod = 0}
		ru_space_px = size_of_tab - mod
		str_size += ru_space_px //+ cast(f32)ru_sty.letterSpacing

	} else {
		ru_space_px = measure_text_rune(ru, &ru_sty.tc).x //+ cast(f32)t_data.letterSpacing
		str_size += ru_space_px
	}
	return
}
pos_of_rune::proc(s:^edit.State,pos:int,full_str:string)->(str_size:f32){
	lin_index:=edit.get_line_index(s,pos)
	lin_start_pos:=edit.get_lin_start_pos(s,lin_index)

	for ru,i in full_str[lin_start_pos:pos]{
		str_size+=size_of_rune(s,ru,&s.rune_style[lin_start_pos+i],str_size) 
	} 
	str_size += s.styles.line_pading.x
	return
}

defalt_text_box_settings :: proc() -> (s: edit.Settings) {
	s.max_char = 0
	s.max_line_len = 200
	s.carit_color = {255, 255, 255, 255}
	s.blink_duration = .35
	s.tab_size = 4
	s.get_clipboard = get_clipboard
	s.set_clipboard = set_clipboard
	s.do_syntax_highlig = true
	s.auto_tab_on_new_lin = true

	sty := &s.styles

	// sty.rune_=t_config_small()^
	sty.rune_.fontId = 0
	sty.rune_.fontSize = 16
	sty.rune_.letterSpacing = 2
	sty.rune_.lineHeight = 16
	sty.rune_.textColor = {255, 255, 255, 255}
	sty.rune_.wrapMode = .None
	sty.rune_.background_col = {0,0,0,0}
	sty_cc := &sty.comment_colors

	sty.strings = sty.rune_
	sty.bace_key_word = sty.rune_
	sty.important_key_word = sty.rune_
	sty.important_v2_key_word = sty.rune_
	sty.bace_type = sty.rune_
	sty.line_pading = {5,5,5,5}

	sty.strings.textColor = {133, 69, 20, 255}
	sty.bace_key_word.textColor = {16, 34, 196, 255}
	sty.important_key_word.textColor = {134, 29, 209, 255}
	sty.important_v2_key_word.textColor = {133, 12, 24, 255}
	sty.bace_type.textColor = {58, 201, 36, 255}
	sty.background_col = {0,0,0,0}
	sty.tab = edit.defalt_tab_style

	sty.selection_col = 	{255,255,255,55}
	sty.tabs_indicators = 	{color={255,255,255,25},width={left = 1, right = 0, top = 0, bottom = 0}}
	sty.cursor_lin_outline ={color={255,255,255,50},width={left = 0, right = 0, top = 2, bottom = 2}}

	sty.comment_colors = edit.defalt_comment_colors

	for &bracket, i in &sty.bracket_colors {
		defalt_bd := edit.defalt_brackets_colors
		bracket = defalt_bd[i]
	}

	merge_all_rune_settings(sty)


	// s.set_up_index_overide
	// s.set_downe_index_overide
	return
}
merge_all_rune_settings :: proc(sty: ^edit.style) {

	sty_cc := &sty.comment_colors
	merge_defalt_rune_settings(&sty.rune_, &sty_cc.TODO)
	merge_defalt_rune_settings(&sty.rune_, &sty_cc.and)
	merge_defalt_rune_settings(&sty.rune_, &sty_cc.at)
	merge_defalt_rune_settings(&sty.rune_, &sty_cc.defalt)
	merge_defalt_rune_settings(&sty.rune_, &sty_cc.dollar)
	merge_defalt_rune_settings(&sty.rune_, &sty_cc.error)
	merge_defalt_rune_settings(&sty.rune_, &sty_cc.pointer)
	merge_defalt_rune_settings(&sty.rune_, &sty_cc.question)
	merge_defalt_rune_settings(&sty.rune_, &sty_cc.warning)

	merge_defalt_rune_settings(&sty.rune_, &sty.strings)
	merge_defalt_rune_settings(&sty.rune_, &sty.bace_key_word)
	merge_defalt_rune_settings(&sty.rune_, &sty.important_key_word)
	merge_defalt_rune_settings(&sty.rune_, &sty.important_v2_key_word)
	merge_defalt_rune_settings(&sty.rune_, &sty.bace_type)
	merge_defalt_rune_settings(&sty.rune_, &sty.tab)


	for &bracket, i in &sty.bracket_colors {
		defalt_bd := edit.defalt_brackets_colors
		bracket = defalt_bd[i]
		merge_defalt_rune_settings(&sty.rune_, &bracket)
	}
}
merge_defalt_rune_settings :: proc(
	bace_r: ^clay.TextElementConfig,
	over_r: ^clay.TextElementConfig,
) {
	if over_r.fontId == 0 {over_r.fontId = bace_r.fontId}
	if over_r.fontSize == 0 {over_r.fontSize = bace_r.fontSize}
	if over_r.letterSpacing == 0 {over_r.letterSpacing = bace_r.letterSpacing}
	if over_r.lineHeight == 0 {over_r.lineHeight = bace_r.lineHeight}
	if over_r.textColor == {} {over_r.textColor = bace_r.textColor}
	if over_r.userData == nil {over_r.userData = bace_r.userData}
	over_r.wrapMode = bace_r.wrapMode
	over_r.textAlignment = bace_r.textAlignment
	// if over_r.wrapMode          !=nil{over_r.wrapMode       = bace_r.wrapMode}
	// if over_r.textAlignment     != .Left {over_r.textAlignment  = bace_r.textAlignment}
}

ui_input_text_box :: proc(t_box: ^ui_text_box) {
	state := &t_box.text_edit_state
	builder := &t_box.str_builder

	render_d := &state.render_data
	settings := &state.settings
	edit.begin_persistent(state, cast(u64)t_box.handle.idx, builder)
	// state.styles.rune_=t_config_small()^
	// merge_all_rune_settings(&state.styles)

	render_d.blink_time += g.time.dt

	if render_d.blink_time > settings.blink_duration {
		render_d.blink_time = 0
		render_d.blink = !render_d.blink
	}

	if state.is_activ {
		text_box_do_imput(state)
	}
	edit.end(state)
	maintain_textbox(t_box)


}


text_box_do_imput :: proc(state: ^edit.State) {
	render_d := &state.render_data
	if state.is_activ {
		new_rune := rl.GetCharPressed()
		for new_rune != 0 {
			edit.input_rune(state, new_rune)
			new_rune = rl.GetCharPressed()
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_back_space, always_consume_d = true) {
			edit.perform_command(state, .Backspace)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_tab, always_consume_d = true) {
			// edit.perform_command(state,.)
			edit.input_rune(state, 9)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0

		}
		if is_input_event(.ui_del, always_consume_d = true) {
			edit.perform_command(state, .Delete)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_t_select_left, always_consume_d = true) {
			edit.perform_command(state, .Select_Left)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_t_select_right, always_consume_d = true) {
			edit.perform_command(state, .Select_Right)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		// if is_input_event(.ui_move_lin_up, always_consume_d = true) {
		// 	edit.perform_command(state, .move_line_up)
		// 	state.repeat_cool_down = -edit.repeat_cool_down_time * 2
		// 	render_d.blink = false
		// 	render_d.blink_time = 0
		// }
		if is_input_event(.ui_t_select_up, always_consume_d = true) {
			edit.perform_command(state, .Select_Up)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_t_select_down, always_consume_d = true) {
			edit.perform_command(state, .Select_Down)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_t_select_all, always_consume_d = true) {
			edit.perform_command(state, .Select_All)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_a_left, always_consume_d = true) {
			edit.perform_command(state, .Left)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		} 
		if is_input_event(.ui_a_right, always_consume_d = true) {
			edit.perform_command(state, .Right)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_a_up, always_consume_d = true) {
			edit.perform_command(state, .Up)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_a_down, always_consume_d = true) {
			edit.perform_command(state, .Down)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_enter, always_consume_d = true) {
			edit.perform_command(state, .New_Line)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_coppy, always_consume_d = true) {
			edit.perform_command(state, .Copy)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_past, always_consume_d = true) {
			edit.perform_command(state, .Paste)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}
		if is_input_event(.ui_cut, always_consume_d = true) {
			edit.perform_command(state, .Cut)
			state.repeat_cool_down = -edit.repeat_cool_down_time * 2
			render_d.blink = false
			render_d.blink_time = 0
		}

		state.repeat_cool_down += g.time.dt
		if state.repeat_cool_down < -5 {state.repeat_cool_down = 0}
		if state.repeat_cool_down > edit.repeat_cool_down_time {
			if is_input_event(.ui_back_space, ignore_p = true) {
				edit.perform_command(state, .Backspace)
				state.repeat_cool_down = edit.repeat_cool_down_time / 2
				render_d.blink = false
				render_d.blink_time = 0
			}
			if is_input_event(.ui_del, ignore_p = true) {
				edit.perform_command(state, .Delete)
				state.repeat_cool_down = edit.repeat_cool_down_time / 2
				render_d.blink = false
				render_d.blink_time = 0
			}
			if is_input_event(.ui_t_select_left, ignore_p = true) {
				edit.perform_command(state, .Select_Left)
				state.repeat_cool_down = edit.repeat_cool_down_time / 2
				render_d.blink = false
				render_d.blink_time = 0
			}
			if is_input_event(.ui_t_select_right, ignore_p = true) {
				edit.perform_command(state, .Select_Right)
				state.repeat_cool_down = edit.repeat_cool_down_time / 2
				render_d.blink = false
				render_d.blink_time = 0
			}
			if is_input_event(.ui_t_select_up, ignore_p = true) {
				edit.perform_command(state, .Select_Up)
				state.repeat_cool_down = edit.repeat_cool_down_time / 2
				render_d.blink = false
				render_d.blink_time = 0
			}
			if is_input_event(.ui_t_select_down, ignore_p = true) {
				edit.perform_command(state, .Select_Down)
				state.repeat_cool_down = edit.repeat_cool_down_time / 2
				render_d.blink = false
				render_d.blink_time = 0
			}
			if is_input_event(.ui_a_left, ignore_p = true) {
				edit.perform_command(state, .Left)
				state.repeat_cool_down = edit.repeat_cool_down_time / 2
				render_d.blink = false
				render_d.blink_time = 0
			}
			if is_input_event(.ui_a_right, ignore_p = true) {
				edit.perform_command(state, .Right)
				state.repeat_cool_down = edit.repeat_cool_down_time / 2
				render_d.blink = false
				render_d.blink_time = 0
			}
			if is_input_event(.ui_a_up, ignore_p = true) {
				edit.perform_command(state, .Up)
				state.repeat_cool_down = -edit.repeat_cool_down_time / 2
				render_d.blink = false
				render_d.blink_time = 0
			}
			if is_input_event(.ui_a_down, ignore_p = true) {
				edit.perform_command(state, .Down)
				state.repeat_cool_down = -edit.repeat_cool_down_time / 2
				render_d.blink = false
				render_d.blink_time = 0
			}
			if is_input_event(.ui_enter, ignore_p = true) {
				edit.perform_command(state, .New_Line)
				state.repeat_cool_down = 0
				render_d.blink = false
				render_d.blink_time = 0
			}
		}
	}
}

get_clipboard :: proc(user_data: rawptr) -> (text: string, ok: bool) {
	c_str := rl.GetClipboardText()
	str := strings.clone_from_cstring(c_str)
	// delete_cstring(c_str)
	text = str
	ok = true
	return
}
set_clipboard :: proc(user_data: rawptr, text: string) -> (ok: bool) {
	new_string := strings.clone_to_cstring(text)
	rl.SetClipboardText(new_string)
	// delete_cstring(new_string)
	return true
}