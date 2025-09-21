package game

import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"
import "core:math"

Rect :: rl.Rectangle

draw_by_id_2d::proc(
    texture_name:Texture_Name,
    dest:Rect,
    origin:rl.Vector2={0,0},
    rot:f32=0,
    tint:rl.Color={255,255,255,255},
    atlas:rl.Texture2D=g.as.atlas
){
    rl.DrawTexturePro(atlas, atlas_textures[texture_name].rect, dest, origin, rot, tint)
}
draw_by_id_3d::proc(
    texture_name:Texture_Name,
    dest:Rect,
    z:f32=0,
    origin:rl.Vector2={0,0},
    rot:f32=0,
    tint:rl.Color={255,255,255,255},
    atlas:rl.Texture2D=g.as.atlas
){
    draw_texture_3d(atlas, atlas_textures[texture_name].rect, dest, z,origin, rot, tint)
}
draw_animation::proc(
    animation_name:Animation_Name,
    dest:Rect,
    z:f32=0,
    origin:rl.Vector2={0,0},
    rot:f32=0,
    tint:rl.Color={255,255,255,255},
    atlas:rl.Texture2D=g.as.atlas
){
    draw_texture_3d(atlas, atlas_textures[g.as.animations.global[animation_name].current_frame].rect, dest, z,origin, rot, tint)
}
draw_image::proc(
    name:img_ani_name,
    dest:Rect,
    z:f32=0,
    origin:rl.Vector2={0,0},
    rot:f32=0,
    tint:rl.Color={255,255,255,255},
    atlas:rl.Texture2D=g.as.atlas
){
    switch id in name{
        case Animation_Name: draw_texture_3d(atlas, atlas_textures[g.as.animations.global[id].current_frame].rect, dest, z,origin, rot, tint)        
        case Texture_Name: draw_texture_3d(atlas, atlas_textures[id].rect, dest, z,origin, rot, tint)
        // case tile_set_names:draw_texture_3d(atlas, atlas_textures[defalt_tile_sets[id].img].rect, dest, z,origin, rot, defalt_tile_sets[id].tint)    
   
    }
}

Draw3DBillboardRec::proc( camera:rl.Camera, texture:rl.Texture2D, source:rl.Rectangle, position_:rl.Vector3, size:rl.Vector2,  tint:rl.Color){
    position:=position_
    rlgl.PushMatrix()

    // get the camera view matrix
    mat: =rl.MatrixInvert(rl.MatrixLookAt(camera.position, camera.target, camera.up))
    // peel off just the rotation
    quat: = rl.QuaternionFromMatrix(mat)
    mat = rl.QuaternionToMatrix(quat)

    // apply just the rotation
    mat_temp:[16]f32 = rl.MatrixToFloatV(mat)
    rlgl.MultMatrixf(raw_data(&mat_temp))

    // translate backwards in the inverse rotated matrix to put the item where it goes in world space
    position = rl.Vector3Transform(position, rl.MatrixInvert(mat))
    rlgl.Translatef(position.x, position.y, position.z)

    // draw the billboard
    width:f32 = size.x / 2
    height:f32 = size.y / 2

    rlgl.CheckRenderBatchLimit(6)

    rlgl.SetTexture(texture.id)

    // draw quad
    rlgl.Begin(rlgl.QUADS)
    rlgl.Color4ub(tint.r, tint.g, tint.b, tint.a)
    // Front Face
    rlgl.Normal3f(0.0, 0.0, 1.0)               // Normal Pointing Towards Viewer

    rlgl.TexCoord2f(source.x / cast(f32)texture.width, (source.y + source.height) / cast(f32)texture.height)
    rlgl.Vertex3f(-width, -height, 0)  // Bottom Left Of The Texture and Quad
    
    rlgl.TexCoord2f((source.x + source.width) / cast(f32)texture.width, (source.y + source.height) / cast(f32)texture.height)
    rlgl.Vertex3f(+width, -height, 0)  // Bottom Right Of The Texture and Quad
   
    rlgl.TexCoord2f((source.x + source.width) / cast(f32)texture.width, source.y / cast(f32)texture.height)
    rlgl.Vertex3f(+width, +height, 0)  // Top Right Of The Texture and Quad

    rlgl.TexCoord2f(source.x / cast(f32)texture.width, source.y / cast(f32)texture.height)
    rlgl.Vertex3f(-width, +height, 0)  // Top Left Of The Texture and Quad

    rlgl.End()
    rlgl.SetTexture(0)
    rlgl.PopMatrix()
}

Draw3DBillboardRec_DIR::proc( texture:rl.Texture2D, source:rl.Rectangle, position:rl.Vector3, size:rl.Vector2,  tint:rl.Color){

    rlgl.PushMatrix()

    // get the camera view matrix
    // mat: =rl.MatrixInvert(rl.MatrixLookAt(camera.position, camera.target, camera.up))
    // peel off just the rotation
    // quat: = rl.QuaternionFromMatrix(mat)
    // mat = rl.QuaternionToMatrix(quat)

    // apply just the rotation
    // mat_temp:[16]f32 = rl.MatrixToFloatV(mat)
    // rlgl.MultMatrixf(raw_data(&mat_temp))

    // translate backwards in the inverse rotated matrix to put the item where it goes in world space
    // position = rl.Vector3Transform(position, rl.MatrixInvert(mat))
    rlgl.Translatef(position.x, position.y, position.z)

    // draw the billboard
    width:f32 = size.x / 2
    height:f32 = size.y / 2

    rlgl.CheckRenderBatchLimit(6)

    rlgl.SetTexture(texture.id)

    // draw quad
    rlgl.Begin(rlgl.QUADS)
        rlgl.Color4ub(tint.r, tint.g, tint.b, tint.a)
        // Front Face
        rlgl.Normal3f(0.0, 0.0, 1.0)               // Normal Pointing Towards Viewer

        rlgl.TexCoord2f(source.x / cast(f32)texture.width, (source.y + source.height) / cast(f32)texture.height)
        rlgl.Vertex3f(-width, -height, 0)  // Bottom Left Of The Texture and Quad
        
        rlgl.TexCoord2f((source.x + source.width) / cast(f32)texture.width, (source.y + source.height) / cast(f32)texture.height)
        rlgl.Vertex3f(+width, -height, 0)  // Bottom Right Of The Texture and Quad
    
        rlgl.TexCoord2f((source.x + source.width) / cast(f32)texture.width, source.y / cast(f32)texture.height)
        rlgl.Vertex3f(+width, +height, 0)  // Top Right Of The Texture and Quad

        rlgl.TexCoord2f(source.x / cast(f32)texture.width, source.y / cast(f32)texture.height)
        rlgl.Vertex3f(-width, +height, 0)  // Top Left Of The Texture and Quad

    rlgl.End()
    rlgl.SetTexture(0)
    rlgl.PopMatrix()
}


draw_texture_3d::proc(texture:rl.Texture2D ,source:rl.Rectangle ,dest:rl.Rectangle,z:f32=0 ,origin:rl.Vector2={0,0} ,rotation:f32,tint:rl.Color = {255,255,255,255}) {
    dest_:=dest
    source_:=source
    // Check if texture is valid
    if (texture.id > 0) {
        width :f32= cast(f32)texture.width
        height :f32= cast(f32)texture.height

        flipX:bool = false

        if (source_.width < 0) { 
            flipX = true
            source_.width *= -1
        }
        if (source_.height < 0) {source_.y -= source_.height}

        if (dest_.width < 0) {dest_.width *= -1}
        if (dest_.height < 0) {dest_.height *= -1}

        topLeft:rl.Vector2
        topRight:rl.Vector2
        bottomLeft:rl.Vector2
        bottomRight:rl.Vector2

        // Only calculate rotation if needed
        if (rotation == 0.0) {
            x:f32 = dest_.x - origin.x
            y:f32 = dest_.y - origin.y
            topLeft = { x, y }
            topRight = { x + dest_.width, y }
            bottomLeft = { x, y + dest_.height }
            bottomRight= { x + dest_.width, y + dest_.height }
        } else {
            sinRotation:f32 = math.sin(rotation*rl.DEG2RAD)
            cosRotation:f32 = math.cos(rotation*rl.DEG2RAD)
        
            x:f32 = dest_.x
            y:f32 = dest_.y
            dx:f32 = -origin.x
            dy:f32 = -origin.y

            topLeft.x = x + dx*cosRotation - dy*sinRotation
            topLeft.y = y + dx*sinRotation + dy*cosRotation

            topRight.x = x + (dx + dest_.width)*cosRotation - dy*sinRotation
            topRight.y = y + (dx + dest_.width)*sinRotation + dy*cosRotation

            bottomLeft.x = x + dx*cosRotation - (dy + dest_.height)*sinRotation
            bottomLeft.y = y + dx*sinRotation + (dy + dest_.height)*cosRotation

            bottomRight.x = x + (dx + dest_.width)*cosRotation - (dy + dest_.height)*sinRotation
            bottomRight.y = y + (dx + dest_.width)*sinRotation + (dy + dest_.height)*cosRotation
        }

        rlgl.SetTexture(texture.id)
        rlgl.Begin(rlgl.QUADS)

            rlgl.Color4ub(tint.r, tint.g, tint.b, tint.a)
            rlgl.Normal3f(0.0, 0.0, 1.0)                        // Normal vector pointing towards viewer

            // Top-left corner for texture and quad
            if (flipX) {rlgl.TexCoord2f((source_.x + source_.width)/width, source_.y/height)}
            else {rlgl.TexCoord2f(source_.x/width, source_.y/height)}
            rlgl.Vertex3f(topLeft.x, topLeft.y,z)

            // Bottom-left corner for texture and quad
            if (flipX) {rlgl.TexCoord2f((source_.x + source_.width)/width, (source_.y + source_.height)/height)}
            else {rlgl.TexCoord2f(source_.x/width, (source_.y + source_.height)/height)}
            rlgl.Vertex3f(bottomLeft.x, bottomLeft.y,z)

            // Bottom-right corner for texture and quad
            if (flipX) {rlgl.TexCoord2f(source_.x/width, (source_.y + source_.height)/height)}
            else {rlgl.TexCoord2f((source_.x + source_.width)/width, (source_.y + source_.height)/height)}
            rlgl.Vertex3f(bottomRight.x, bottomRight.y,z)

            // Top-right corner for texture and quad
            if (flipX) {rlgl.TexCoord2f(source_.x/width, source_.y/height)}
            else {rlgl.TexCoord2f((source_.x + source_.width)/width, source_.y/height)}
            rlgl.Vertex3f(topRight.x, topRight.y,z)

        rlgl.End()
        rlgl.SetTexture(0)
    }
}




