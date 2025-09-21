package game

import rl "vendor:raylib"
import "core:fmt"
// import "core:math"
// import "core:fmt"

img_ani_name::union{
    Texture_Name,
    Animation_Name,
}

particle :: struct{
    origin_offset:[2]f32,
    pos:[3]f32,
    velocity:[3]f32,
    force:[3]f32,
    w_h:[2]f32,
    w_h_shift:[2]f32,
    rot:f32,
    rot_shift:f32,
    life:f32,
    max_life:f32,
    img:img_ani_name,
    tint:[4]f32,
    tint_shift:[4]f32,
    callback:proc(particle:^particle),
    destroy_callback:proc(particle:^particle),
}
max_particles:int:10000
all_particle_data::struct{
    data:[max_particles]particle,
    p_count:int,
}

add_particle::proc(particle:particle){
    if g.st.particle.p_count < max_particles-1{
        g.st.particle.data[g.st.particle.p_count] = particle
        g.st.particle.p_count += 1
    }
}
remove_particle::proc(p_index:int){
    if g.st.particle.data[p_index].destroy_callback !=nil{
        g.st.particle.data[p_index].destroy_callback(&g.st.particle.data[p_index])
    }
    g.st.particle.data[p_index] = g.st.particle.data[g.st.particle.p_count-1]
    if g.st.particle.p_count>0{
        g.st.particle.p_count -=1
    }
}
calc_particles::proc(){
    // fmt.print(g.st.particle.p_count,"\n")
    if g.time.is_60h_this_frame {
        if g.st.particle.p_count > 0{
            for i in 0..<g.st.particle.p_count {
                g.st.particle.data[i].life -= frame_langth
                if g.st.particle.data[i].callback != nil{
                    g.st.particle.data[i].callback(&g.st.particle.data[i])
                }else{
                    bace_calc_particle(&g.st.particle.data[i])
                }
                if g.st.particle.data[i].life<0{
                    remove_particle(i)
                }
            }
        }
    }
}
bace_calc_particle::proc(particle:^particle){
    particle.velocity += (particle.force * frame_langth)
    particle.pos += (particle.velocity * frame_langth)
    particle.rot += (particle.rot_shift * frame_langth)
    particle.w_h += (particle.w_h_shift * frame_langth)
}

draw_particles::proc(){

    if g.st.particle.p_count > 0{
        for i in 0..<g.st.particle.p_count {
            part := &g.st.particle.data[i]
            draw_image(
                name = part.img,
                dest = {part.pos.x,part.pos.y,part.w_h.x,part.w_h.y},
                z = part.pos.z,
                origin ={part.w_h.x/2+part.origin_offset.x,part.w_h.y/2+part.origin_offset.y},
                rot = part.rot,
                tint = rl.ColorFromNormalized(part.tint),
            )
        }
    }
}

particles_stuff::proc(particle:^particle){
    bace_calc_particle(particle)

    particle.tint = lerp_colors({1,1,1,1},{0,0,0,0},particle.life/particle.max_life)
    
}
part_gen_info::struct{
    doo:bool,
    part_c:i32,

    particle:particle,
}
