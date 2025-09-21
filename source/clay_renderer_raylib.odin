package game

import "base:sanitizer"
import clay "/clay-odin"
import "core:math"
import "core:strings"
import rl"vendor:raylib"
import "base:runtime"
import "core:fmt"
import "core:c"
import edit"text_edit"

RaylibFont :: struct {
    fontId: u16,
    font:   rl.Font,
}
custom_element::union{
    text_box_element,
}
text_box_element::struct{
    s:^edit.State,
    line_width:int,
    carit_pos:int,
}

clayColorToRaylibColor :: proc(color: clay.Color) -> rl.Color {
    return rl.Color{cast(u8)color.r, cast(u8)color.g, cast(u8)color.b, cast(u8)color.a}
}


raylibFonts := [10]RaylibFont{}

measure_text :: proc "c" (text: clay.StringSlice, config: ^clay.TextElementConfig, userData: rawptr) -> clay.Dimensions {
    // Measure string size for Font
    context = runtime.default_context()
    textSize: clay.Dimensions = {0, 0}

    maxTextWidth: f32 = 0
    lineTextWidth: f32 = 0

    textHeight := cast(f32)config.fontSize


    fontToUse := raylibFonts[config.fontId].font
    // fontToUse := raylibFonts[0].font

    for i in 0 ..< int(text.length) {
        if (text.chars[i] == '\n') {
            maxTextWidth = max(maxTextWidth, lineTextWidth)
            lineTextWidth = 0
            continue
        }
        index := cast(i32)text.chars[i] - 32
        if (fontToUse.glyphs[index].advanceX != 0) {
            lineTextWidth += cast(f32)fontToUse.glyphs[index].advanceX
        } else {
            lineTextWidth += (fontToUse.recs[index].width + cast(f32)fontToUse.glyphs[index].offsetX)
        }
    }
    text_ := string(text.baseChars[:text.length])
    cloned := strings.clone_to_cstring(text_, context.temp_allocator)
    lineTextWidth = rl.MeasureTextEx(fontToUse,cloned,auto_cast config.fontSize,auto_cast config.letterSpacing).x +rl.MeasureTextEx(fontToUse,".",auto_cast config.fontSize,auto_cast config.letterSpacing).x
    // lineTextWidth+= cast(f32)(config.letterSpacing*cast(u16)text.length)
    maxTextWidth = max(maxTextWidth, lineTextWidth)
    textSize.width = maxTextWidth
    textSize.height = textHeight

    return textSize
}
clay_color_to_rl_color :: proc(color: clay.Color) -> rl.Color {
    return {u8(color.r), u8(color.g), u8(color.b), u8(color.a)}
}
color_to_clay_color :: proc(color: [4]u8) -> clay.Color {
    return {f32(color.r), f32(color.g), f32(color.b), f32(color.a)}
}


clay_raylib_render :: proc(render_commands: ^clay.ClayArray(clay.RenderCommand), allocator := context.temp_allocator) {

    for i in 0 ..< render_commands.length {
        render_command := clay.RenderCommandArray_Get(render_commands, i)
        bounds := render_command.boundingBox


        switch render_command.commandType {
        case .None: // None
        case .Text:
            config := render_command.renderData.text

            text := string(config.stringContents.chars[:config.stringContents.length])

            // Raylib uses C strings instead of Odin strings, so we need to clone
            // Assume this will be freed elsewhere since we default to the temp allocator
            cstr_text := strings.clone_to_cstring(text, allocator)
            font := raylibFonts[config.fontId].font
            rl.DrawTextEx(font, cstr_text, {bounds.x, bounds.y}, f32(config.fontSize), f32(config.letterSpacing), clay_color_to_rl_color(config.textColor))
            
            if render_command.userData != nil{
                line_data:^edit.Line_Data=cast(^edit.Line_Data)render_command.userData
                state:^edit.State=line_data.state
                // line_index:=edit.get_line_index_vis(state,state.selection.x)
                // line_start:=edit.get_line_start_pos(state,line_index)
                line_width:=line_data.width
                // line_pos:=state.selection.x-line_start

                if line_data.show_debug_data {
                    rl.DrawRectanglePro({bounds.x, bounds.y, bounds.width, bounds.height},{0,0},0,{255,255,255,25})
                }
                if line_data.carit_pos >-1 && len(text)>=line_data.carit_pos{
                    text_to_carit:=text[:line_data.carit_pos] 
                    cstr_text_to_carit := strings.clone_to_cstring(text_to_carit, allocator)
                    size_to_carit :=rl.MeasureTextEx(font,cstr_text_to_carit ,cast(f32)config.fontSize,cast(f32)config.letterSpacing)
                    if line_data.show_debug_data {
                        rl.DrawRectanglePro({bounds.x, bounds.y, bounds.width, bounds.height},{0,0},0,{255,0,0,50})
                        if line_data.has_carit{
                            rl.DrawRectanglePro({bounds.x+size_to_carit.x, bounds.y, cast(f32)render_command.renderData.text.letterSpacing, bounds.height},{0,0},0,{255,0,0,255})
                        }
                    }
                    if line_data.has_carit&& !state.blink && state.is_activ{
                        rl.DrawRectanglePro({bounds.x+size_to_carit.x, bounds.y, cast(f32)render_command.renderData.text.letterSpacing, bounds.height},{0,0},0,cast(rl.Color)(state.carit_color))
                    }
                }
            }
        case .Image:
            config := render_command.renderData.image
            tint := config.backgroundColor
            if tint == 0 {
                tint = {255, 255, 255, 255}
            }

            imageTexture := (^rl.Texture2D)(config.imageData)
            rl.DrawTextureEx(imageTexture^, {bounds.x, bounds.y}, 0, bounds.width / f32(imageTexture.width), clay_color_to_rl_color(tint))
        case .ScissorStart:
            rl.BeginScissorMode(i32(math.round(bounds.x)), i32(math.round(bounds.y)), i32(math.round(bounds.width)), i32(math.round(bounds.height)))
        case .ScissorEnd:
            rl.EndScissorMode()
        case .Rectangle:
            config := render_command.renderData.rectangle
            if config.cornerRadius.topLeft > 0 {
                radius: f32 = (config.cornerRadius.topLeft * 2) / min(bounds.width, bounds.height)
                draw_rect_rounded(bounds.x, bounds.y, bounds.width, bounds.height, radius, config.backgroundColor)
            } else {
                draw_rect(bounds.x, bounds.y, bounds.width, bounds.height, config.backgroundColor)
            }
        case .Border:
            config := render_command.renderData.border
            // Left border
            if config.width.left > 0 {
                draw_rect(
                    bounds.x,
                    bounds.y + config.cornerRadius.topLeft,
                    f32(config.width.left),
                    bounds.height - config.cornerRadius.topLeft - config.cornerRadius.bottomLeft,
                    config.color,
                )
            }
            // Right border
            if config.width.right > 0 {
                draw_rect(
                    bounds.x + bounds.width - f32(config.width.right),
                    bounds.y + config.cornerRadius.topRight,
                    f32(config.width.right),
                    bounds.height - config.cornerRadius.topRight - config.cornerRadius.bottomRight,
                    config.color,
                )
            }
            // Top border
            if config.width.top > 0 {
                draw_rect(
                    bounds.x + config.cornerRadius.topLeft,
                    bounds.y,
                    bounds.width - config.cornerRadius.topLeft - config.cornerRadius.topRight,
                    f32(config.width.top),
                    config.color,
                )
            }
            // Bottom border
            if config.width.bottom > 0 {
                draw_rect(
                    bounds.x + config.cornerRadius.bottomLeft,
                    bounds.y + bounds.height - f32(config.width.bottom),
                    bounds.width - config.cornerRadius.bottomLeft - config.cornerRadius.bottomRight,
                    f32(config.width.bottom),
                    config.color,
                )
            }

            // Rounded Borders
            if config.cornerRadius.topLeft > 0 {
                draw_arc(
                    bounds.x + config.cornerRadius.topLeft, 
                    bounds.y + config.cornerRadius.topLeft,
                    config.cornerRadius.topLeft - f32(config.width.top),
                    config.cornerRadius.topLeft,
                    180,
                    270,
                    config.color,
                )
            }
            if config.cornerRadius.topRight > 0 {
                draw_arc(
                    bounds.x + bounds.width - config.cornerRadius.topRight,
                    bounds.y + config.cornerRadius.topRight,
                    config.cornerRadius.topRight - f32(config.width.top),
                    config.cornerRadius.topRight,
                    270,
                    360,
                    config.color,
                )
            }
            if config.cornerRadius.bottomLeft > 0 {
                draw_arc(
                    bounds.x + config.cornerRadius.bottomLeft,
                    bounds.y + bounds.height - config.cornerRadius.bottomLeft,
                    config.cornerRadius.bottomLeft - f32(config.width.top),
                    config.cornerRadius.bottomLeft,
                    90,
                    180,
                    config.color,
                )
            }
            if config.cornerRadius.bottomRight > 0 {
                draw_arc(
                    bounds.x + bounds.width - config.cornerRadius.bottomRight, 
                    bounds.y + bounds.height - config.cornerRadius.bottomRight,
                    config.cornerRadius.bottomRight - f32(config.width.bottom),
                    config.cornerRadius.bottomRight,
                    0.1,
                    90,
                    config.color,
                )
            }
        case clay.RenderCommandType.Custom:
            cust_el :=cast(^custom_element)render_command.userData
            switch v in cust_el {
                case text_box_element: 

            }
                
            
            // Implement custom element rendering here
        }
    }
}

// Helper procs, mainly for repeated conversions

@(private = "file")
draw_arc :: proc(x, y: f32, inner_rad, outer_rad: f32,start_angle, end_angle: f32, color: clay.Color){
    rl.DrawRing(
        {math.round(x),math.round(y)},
        math.round(inner_rad),
        outer_rad,
        start_angle,
        end_angle,
        10,
        clay_color_to_rl_color(color),
    )
}

@(private = "file")
draw_rect :: proc(x, y, w, h: f32, color: clay.Color) {
    rl.DrawRectangle(
        i32(math.round(x)), 
        i32(math.round(y)), 
        i32(math.round(w)), 
        i32(math.round(h)), 
        clay_color_to_rl_color(color)
    )
}

@(private = "file")
draw_rect_rounded :: proc(x,y,w,h: f32, radius: f32, color: clay.Color){
    rl.DrawRectangleRounded({x,y,w,h},radius,8,clay_color_to_rl_color(color))
}