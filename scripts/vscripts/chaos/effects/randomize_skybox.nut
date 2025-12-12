local skynames =
[
	"sky_dustbowl_01",
	"sky_granary_01",
	"sky_gravel_01",
	"sky_well_01",
	"sky_tf2_04",
	"sky_hydro_01",
	"sky_badlands_01",
	"sky_goldrush_01",
	"sky_trainyard_01",
	"sky_night_01",
	"sky_alpinestorm_01",
	"sky_morningsnow_01",
	"sky_nightfall_01",
	"sky_harvest_01",
	"sky_harvest_night_01",
	"sky_upward",
	"sky_stormfront_01",
	"sky_halloween",
	"sky_halloween_night_01",
	"sky_halloween_night2014_01",
	"sky_island_01",
	"sky_rainbow_01"
]

function ChaosEffect_OnStart()
{
	local sky, sv_skyname = Convars.GetStr("sv_skyname");
	do
	{
		sky = skynames[RandomInt(0, skynames.len() - 1)]
	}
	while (sky == sv_skyname)
	
	SetSkyboxTexture(sky)
}