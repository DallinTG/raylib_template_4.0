package game

import rl "vendor:raylib"
import "core:math"
import "core:math/rand"
import "core:fmt"

import "base:builtin"
import "base:runtime"
import "core:encoding/json"
import "core:encoding/cbor"
import "core:os"
import "core:time"
import "core:strings"
import "core:thread"

time_stuff::struct{
    dt:f32,
    dt_60h:f32,
    is_60h_this_frame:bool,
    frame_count_60h:i32,
    frame_count:uint,

}
window_info::struct{
    w:i32,
    h:i32,
}

frame_langth::0.016666  
maintain_timers::proc(){
    
    g.time.dt = rl.GetFrameTime()
    g.time.dt_60h += rl.GetFrameTime()
    g.time.frame_count+=1
    if g.time.is_60h_this_frame == true{
        g.time.is_60h_this_frame = false
        // g.time.dt_60h =0.0  
        g.time.dt_60h -=frame_langth   
    }
    if g.time.dt_60h >frame_langth{
        g.time.is_60h_this_frame = true
        g.time.frame_count_60h+=1
    }
}
lerp_colors::proc(c1:[4]f32,c2:[4]f32,m:f32)->(f_color:[4]f32){
    f_color ={ math.lerp(c1.r,c2.r,m),math.lerp(c1.g,c2.g,m),math.lerp(c1.b,c2.b,m),math.lerp(c1.a,c2.a,m)}
    return
}











maintain_window_info::proc(){
    g.window_info.h=rl.GetScreenHeight()  
    g.window_info.w=rl.GetScreenWidth()
    
    g.cam.fovy = cast(f32) g.window_info.h


}

get_distance::proc(pos_1,pos_2:[2]f32)->(dist:f32){
    dist=math.sqrt((pos_1.x-pos_2.x)*(pos_1.x-pos_2.x)+(pos_1.y-pos_2.y)*(pos_1.y-pos_2.y))
    return
}
animate_to_target_v2 :: proc(value: ^[2]f32, target: [2]f32, delta_t: f32, rate :f32= 15.0, good_enough:f32= 0.001)
{
	animate_to_target_f32(&value.x, target.x, delta_t, rate, good_enough)
	animate_to_target_f32(&value.y, target.y, delta_t, rate, good_enough)
}

animate_to_target_f32 :: proc(value: ^f32, target: f32, delta_t: f32, rate:f32= 15.0, good_enough:f32= 0.001) -> bool
{
	value^ += (target - value^) * (1.0 - math.pow_f32(2.0, -rate * delta_t));
	if almost_equals(value^, target, good_enough)
	{
		value^ = target;
		return true; // reached
	}
	return false;
}

almost_equals :: proc(a: f32, b: f32, epsilon: f32 = 0.001) -> bool
{
	return abs(a - b) <= epsilon;
}
// get_distance::proc(pos1,pos2:[2]f32)->(dist:f32){
//     dist=math.sqrt((pos1.x-pos2.x)*(pos1.x-pos2.x)+(pos1.y-pos2.y)*(pos1.y-pos2.y))
//     return
// }

string_to_enum::proc(str:string,$T:typeid)->(enum_name:T){
    for enum_, i in  T {
        if fmt.tprint(enum_) == str{
            return enum_
        }
    }
    return nil
}

normalise_vec::proc(vec:[2]f32)->(norm_vec:[2]f32){
	

	mag:=mag_vec(vec)
	if mag > 0{
		norm_vec={vec.x/mag,vec.y/mag}
	}else{
		norm_vec={0,0}
	}
	return
}
mag_vec::proc(vec:[2]f32)->(mag:f32){
	mag=math.sqrt(vec.x*vec.x+vec.y*vec.y)
	return
}
system_info::struct{
    ODIN_OS:      runtime.Odin_OS_Type,
    ODIN_ARCH:    runtime.Odin_Arch_Type,
    ODIN_ENDIAN:  runtime.Odin_Endian_Type,
    ODIN_VENDOR:  string,
    ODIN_VERSION: string,
    ODIN_ROOT:    string,
    ODIN_DEBUG:   bool,
    last_time_played:string,
}
log_system_info::proc(path:string="logs/odin_info.json"){
    info:system_info = {
        ODIN_OS, 
        ODIN_ARCH, 
        ODIN_ENDIAN, 
        ODIN_VENDOR, 
        ODIN_VERSION, 
        ODIN_ROOT, 
        ODIN_DEBUG,
        fmt.tprint(time.date(time.now()))
		
    }
    w_json_marshal(info,path)

}

w_json_marshal :: proc(data:any ,path:string) {
	json_data, err := json.marshal(data, {
		// Adds indentation etc
		pretty         = true,

		// Output enum member names instead of numeric value.
		use_enum_names = true,
	})

	if err != nil {
		fmt.eprintfln("Unable to marshal JSON: %v", err)
		os.exit(1)
	}

	// fmt.println("JSON:")
	// fmt.printfln("%s", json_data)
	// fmt.printfln("Writing: %s", path)

    // make_d_error:=os.make_directory(path[:strings.last_index_any(path,"/")])

    // if make_d_error != nil {fmt.print(make_d_error,"\n")}
    make_full_directory(path)
	werr := os.write_entire_file_or_err(path, json_data)

	if werr != nil {
		fmt.eprintfln("Unable to write file: %v", werr)
		os.exit(1)
	}
	delete(json_data)

	// fmt.println("Done")
}

w_cbor_marshal :: proc(data:any ,path:string) {

	cbor_data, err := cbor.marshal(data)

	if err != nil {
		fmt.eprintfln("Unable to marshal cbor: %v", err)
		os.exit(1)
	}

	// new_path:=path[:strings.last_index_any(path,"/")]
    // make_d_error:=os.make_directory(new_path)
    // if make_d_error != nil {fmt.print(make_d_error,"\n")}
	
    make_full_directory(path)
	werr := os.write_entire_file_or_err(path, cbor_data)

	if werr != nil {
		fmt.eprintfln("Unable to write file: %v", werr)
		// fmt.print(cbor_data,"\n")
		os.exit(1)
	}
	delete(cbor_data)
}
make_full_directory::proc(path:string){
	last_index:=strings.last_index_any(path,"/")
	if last_index != -1{
		new_path:=path[:last_index]
		make_full_directory(new_path)
		make_d_error:=os.make_directory(new_path)
    	if make_d_error != nil {fmt.print(make_d_error,"\n")}
	}

}


Game_Settings :: struct {
	window_width: i32,
	window_height: i32,
	window_title: string,
	rendering_api: string,
	renderer_settings: struct{
		msaa: bool,
		depth_testing: bool,
	},
}

load_json_unmarshal :: proc(in_data: ^$T,path:string,){
	// Load in your json file!
	data, ok := os.read_entire_file_from_filename(path)
	if !ok {
		fmt.eprintln("Failed to load the json file!")
		return
	}
	defer delete(data) // Free the memory at the end

	unmarshal_err := json.unmarshal(data, in_data)
	if unmarshal_err != nil {
		fmt.eprintln("Failed to unmarshal the json file!")
		return
	}
	// fmt.eprintf("Result %v\n", in_data)

}
load_cbor_unmarshal :: proc(in_data: ^$T,path:string,)->(suc:bool){
	// Load in your json file!
	data, ok := os.read_entire_file_from_filename(path)
	if !ok {
		fmt.eprintln("Failed to load the cbor file!")
		return false
	}
	defer delete(data) // Free the memory at the end

	unmarshal_err := cbor.unmarshal(data, in_data)
	if unmarshal_err != nil {
		fmt.eprintln("Failed to unmarshal the cbor file!")
		return false
	}
	// fmt.eprintf("Result %v\n", in_data)
	return true
}

init_thred_pool::proc(){
	thread.pool_init(&g.thread_pool,context.allocator,3)
	thread.pool_start(&g.thread_pool)
}
clean_up_thread_pool::proc(){
	thread.pool_finish(&g.thread_pool)
	thread.pool_shutdown(&g.thread_pool)
	thread.pool_destroy(&g.thread_pool)
}
logg_type::enum{
	Info,
	Meseg,
	Warning,
	Err,
}

logg:: proc(data:string,type:logg_type, location := #caller_location) {
	fmt.print("[",type,"]",data,"Location",location,"\n")
}
logg_err:: proc(data:string, location := #caller_location) {
	logg(data=data,type=.Err,location=location)
}