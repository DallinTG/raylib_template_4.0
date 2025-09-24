package build

import os2 "core:os/os2"
import "core:c/libc"
import "core:fmt"
import "base:runtime"

platforms::enum{
    descktop,
    web,
}
comp_flags::enum{
    descktop_debug,
    descktop_release,
    web_release,
    web_debug,
}
// comp_flag_str:: #config(comp_flag, "web_debug")
// comp_flag_str:: #config(comp_flag, "descktop_release")
comp_flag_str:: #config(comp_flag, "descktop_debug")
do_asset_bulder:: #config(do_asset_bulder,true)
do_atlas_bulder:: #config(do_atlas_bulder,true)
run_or_build::#config(run_or_build, "run")
comp_flag:comp_flags
starting_dir:string
cer_dir:string
out_dir:string
commands:[dynamic]string

main :: proc() {
    append(&commands,"odin",run_or_build)
    comp_flag=string_to_enum(comp_flag_str,comp_flags)

    {
        dir,err:=os2.get_working_directory(context.allocator)
        starting_dir=dir
    }

    if do_asset_bulder{
        run_program_w(desc={working_dir=fmt.tprintf("%s/source/asset_bulder",starting_dir),command={"odin","run","."}},name="asset bulder")
    }
    if do_atlas_bulder{
        run_program_w(desc={working_dir=fmt.tprintf("%s/source/atlas_builder",starting_dir),command={"odin","run","."}},name="atlas_bulder")
    }
    switch comp_flag {
        case .descktop_debug:
            out_dir="build/debug"
            cer_dir="source/main"
            fmt.print(ODIN_OS,"= os\n")
            when ODIN_OS == .Windows {
                append(&commands,cer_dir,fmt.tprintf("-out:%s/game_debug.exe",out_dir))
            }
            when ODIN_OS == .Linux {
	            append(&commands,cer_dir,fmt.tprintf("-out:%s/game_debug",out_dir),"__NV_PRIME_RENDER_OFFLOAD=1", "__GLX_VENDOR_LIBRARY_NAME=nvidia")
            }
            append(&commands,"-debug")
            run_program_w(desc={working_dir=starting_dir,command=commands[:]},name=fmt.tprint(comp_flag))

        case .descktop_release:
            out_dir="build/release"
            cer_dir="source/main"
            when ODIN_OS == .Windows {
                append(&commands,cer_dir,fmt.tprintf("-out:%s/game_release.exe",out_dir),"-no-bounds-check","-o:speed","-subsystem:windows")
            }
            when ODIN_OS == .Linux {
                append(&commands,cer_dir,fmt.tprintf("-out:%s/game_release",out_dir),"-no-bounds-check","-o:speed")
            }
            run_program(desc={working_dir=starting_dir,command=commands[:]},name=fmt.tprint(comp_flag))
        case .web_release:
        case .web_debug:
            run_program_w(desc={command={"build_web.bat"}},name=fmt.tprint(comp_flag))
    }
    fmt.print(commands,"\n")
    
    // run_program_w({working_dir=cer_dir,command={"odin", "run", ".", "-define:FOO=true"}})
    fmt.print("build progrm finished\n")
}


run_program_w::proc(
    desc:os2.Process_Desc,
    name:string="unkone"
){
    fmt.printf("starting (%s) \n",name)
    state, stdout, stderr, err:=os2.process_exec(desc,context.allocator)
    if err != nil {
        fmt.eprintln("Unable to launch process (",name,") because of:", err)
        return
    }
    fmt.println(string(stdout), string(stderr))
    fmt.printf("finished (%s) \n",name)
    return
}

run_program::proc(
    desc:os2.Process_Desc,
    name:string="unkone"
){
    fmt.printf("starting (%s) \n",name)
    p, err :=os2.process_start(desc)
    if err != nil {
        fmt.eprintln("Unable to launch process(",name,") because of:", err)
    }
    return
}
run_program_get_p_err::proc(
    desc:os2.Process_Desc,
    name:string="unkone"
) -> (p:os2.Process, err:os2.Error){
    fmt.printf("starting (%s) \n",name)
    p, err =os2.process_start(desc)
    if err != nil {
        fmt.eprintln("Unable to launch process(",name,") because of:", err)
    }
    return
}


string_to_enum::proc(str:string,$T:typeid)->(enum_name:T){
    for enum_, i in  T {
        if fmt.tprint(enum_) == str{
            return enum_
        }
    }
    return nil
}