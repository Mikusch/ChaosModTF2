IncludeScript("chaos_util")

flags <- {}

songs <-
[
	")*music/cossack_sandvich.wav",
	")*music/mannrobics.wav",
	")*music/bump_in_the_night.wav",
	")*music/misfortune_teller.wav",
	")*misc/halloween/hwn_dance_loop.wav",
	")*music/fortress_reel_loop.wav",
	")*music/conga_sketch_167bpm_01-04.wav"
]
foreach(i, song in songs)
	PrecacheSound(song)

function ChaosEffect_OnStart()
{
	local flag = Entities.CreateByClassname("item_teamflag")
	flag.KeyValueFromString("flag_model", "models/props_lab/citizenradio.mdl")
	flag.KeyValueFromInt("teamnum", TEAM_UNASSIGNED)
	flag.KeyValueFromString("classname", "prop_dynamic_override")
	flag.DispatchSpawn()
	flag.KeyValueFromString("classname", "item_teamflag")
	flag.AddEFlags(EFL_KILLME)
	flags[flag] <- true

	EmitSoundEx({ entity = flag, channel = CHAN_STATIC, sound_name = songs[RandomInt(0, songs.len() - 1)], sound_level = 90})
}

function Chaos_OnGameEvent_scorestats_accumulated_update(params)
{
	foreach (i, flag in flags)
	{
		flag.RemoveEFlags(EFL_KILLME)
		printl(flag)
	}
}

Chaos_CollectEventCallbacks(this)