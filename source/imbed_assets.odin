package game


asset :: struct {
	path: string,
	data: []u8,
	info: cstring,
}

font_names :: enum {
	calistoga_regular,
	quicksand_semibold,
}

shader_names :: enum {
	bace_fs,
	bace_vs,
	bace_web_fs,
	bace_web_vs,
}

sound_names :: enum {
	none,
	eat,
	explosion,
	no_1,
	no_2,
	penswipe,
	pickupcoin,
	place,
	small_thud,
	s_click,
	s_nu,
	s_paper_swipe,
	s_pop,
	s_thud,
	s_ts,
	s_woo,
	thruster_1,
	thruster_2,
	wa_wa,
	woosh,
}

music_names :: enum {
	none,
	corruption,
	gothamlicious,
	i_can_feel_it_coming,
	space_fighter_loop,
}

	all_fonts := [font_names]asset {
		.calistoga_regular = { path = "fonts/Calistoga_Regular.ttf",  data = #load("../assets/fonts/Calistoga_Regular.ttf"), },
		.quicksand_semibold = { path = "fonts/Quicksand_Semibold.ttf",  data = #load("../assets/fonts/Quicksand_Semibold.ttf"), },
	}

	all_shaders := [shader_names]asset {
		.bace_fs = { path = "shaders/bace_fs.fs",  info = #load("../assets/shaders/bace_fs.fs",cstring), },
		.bace_vs = { path = "shaders/bace_vs.vs",  info = #load("../assets/shaders/bace_vs.vs",cstring), },
		.bace_web_fs = { path = "shaders/bace_web_fs.fs",  info = #load("../assets/shaders/bace_web_fs.fs",cstring), },
		.bace_web_vs = { path = "shaders/bace_web_vs.vs",  info = #load("../assets/shaders/bace_web_vs.vs",cstring), },
	}

	all_sounds := [sound_names]asset {
		.none = {},
		.eat = { path = "sounds/eat.wav",  data = #load("../assets/sounds/eat.wav"), },
		.explosion = { path = "sounds/explosion.wav",  data = #load("../assets/sounds/explosion.wav"), },
		.no_1 = { path = "sounds/no_1.wav",  data = #load("../assets/sounds/no_1.wav"), },
		.no_2 = { path = "sounds/no_2.wav",  data = #load("../assets/sounds/no_2.wav"), },
		.penswipe = { path = "sounds/penswipe.wav",  data = #load("../assets/sounds/penswipe.wav"), },
		.pickupcoin = { path = "sounds/pickupCoin.wav",  data = #load("../assets/sounds/pickupCoin.wav"), },
		.place = { path = "sounds/place.wav",  data = #load("../assets/sounds/place.wav"), },
		.small_thud = { path = "sounds/small_thud.wav",  data = #load("../assets/sounds/small_thud.wav"), },
		.s_click = { path = "sounds/S_Click.wav",  data = #load("../assets/sounds/S_Click.wav"), },
		.s_nu = { path = "sounds/S_NU.wav",  data = #load("../assets/sounds/S_NU.wav"), },
		.s_paper_swipe = { path = "sounds/S_Paper_Swipe.wav",  data = #load("../assets/sounds/S_Paper_Swipe.wav"), },
		.s_pop = { path = "sounds/S_POP.wav",  data = #load("../assets/sounds/S_POP.wav"), },
		.s_thud = { path = "sounds/S_Thud.wav",  data = #load("../assets/sounds/S_Thud.wav"), },
		.s_ts = { path = "sounds/S_TS.wav",  data = #load("../assets/sounds/S_TS.wav"), },
		.s_woo = { path = "sounds/S_woo.wav",  data = #load("../assets/sounds/S_woo.wav"), },
		.thruster_1 = { path = "sounds/thruster_1.wav",  data = #load("../assets/sounds/thruster_1.wav"), },
		.thruster_2 = { path = "sounds/thruster_2.wav",  data = #load("../assets/sounds/thruster_2.wav"), },
		.wa_wa = { path = "sounds/wa_wa.wav",  data = #load("../assets/sounds/wa_wa.wav"), },
		.woosh = { path = "sounds/woosh.wav",  data = #load("../assets/sounds/woosh.wav"), },
	}

	all_music := [music_names]asset {
		.none = {},
		.corruption = { path = "music/Corruption.mp3",  data = #load("../assets/music/Corruption.mp3"), },
		.gothamlicious = { path = "music/Gothamlicious.mp3",  data = #load("../assets/music/Gothamlicious.mp3"), },
		.i_can_feel_it_coming = { path = "music/I_Can_Feel_it_Coming.mp3",  data = #load("../assets/music/I_Can_Feel_it_Coming.mp3"), },
		.space_fighter_loop = { path = "music/Space_Fighter_Loop.mp3",  data = #load("../assets/music/Space_Fighter_Loop.mp3"), },
	}

