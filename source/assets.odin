package game


// import "core:strings"
// import "core:strconv"
import "core:fmt"
// import "core:sort"
// import "core:slice"
import rl "vendor:raylib"

ATLAS_DATA :: #load("../assets/atlases/atlas.png")

assets::struct{
    sounds:[sound_names]rl.Sound,
    sound_aliases:[dynamic]sound_byte,
    atlas:rl.Texture2D,
    shaders:shaders,
    animations:animations,
    music:[4]rl.Music,
    cur_music:rl.Music,

}
shaders::struct{
    bace:rl.Shader,
}



init_sounds::proc(){
    for sound,i in all_sounds{
        if i != sound_names.none{
            // if i != sound_names.factorionvibe{
                g.as.sounds[i] = rl.LoadSoundFromWave(rl.LoadWaveFromMemory(".wav",&sound.data[0],cast(i32)(len(all_sounds[i].data))))
            // }
        }
    }
    g.as.music[3] = rl.LoadMusicStreamFromMemory(".mp3",cast(rawptr)&all_music[.corruption].data[0],cast(i32)(len(all_music[.corruption].data)))
    g.as.music[2] = rl.LoadMusicStreamFromMemory(".mp3",cast(rawptr)&all_music[.gothamlicious].data[0],cast(i32)(len(all_music[.gothamlicious].data)))
    g.as.music[1] = rl.LoadMusicStreamFromMemory(".mp3",cast(rawptr)&all_music[.i_can_feel_it_coming].data[0],cast(i32)(len(all_music[.i_can_feel_it_coming].data)))
    g.as.music[0] = rl.LoadMusicStreamFromMemory(".mp3",cast(rawptr)&all_music[.space_fighter_loop].data[0],cast(i32)(len(all_music[.space_fighter_loop].data)))
}

init_shaders::proc(){
    
    g.as.shaders.bace = rl.LoadShaderFromMemory(all_shaders[.bace_web_vs].info,all_shaders[.bace_web_fs].info)
    if g.platforme ==.desktop {
        g.as.shaders.bace = rl.LoadShaderFromMemory(all_shaders[.bace_vs].info,all_shaders[.bace_fs].info)
    }


}
init_atlases::proc(){
    atlas_image := rl.LoadImageFromMemory(".png", raw_data(ATLAS_DATA), i32(len(ATLAS_DATA)))
    
	g.as.atlas = rl.LoadTextureFromImage(atlas_image)
	rl.UnloadImage(atlas_image)
    // rl.SetTextureFilter(g.assets.atlas,.BILINEAR)

}
