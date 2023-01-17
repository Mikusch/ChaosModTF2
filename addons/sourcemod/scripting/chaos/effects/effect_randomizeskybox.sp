#pragma semicolon 1
#pragma newdecls required

static char g_szSkyNames[][] = 
{
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
	"sky_rainbow_01", 
};

static ConVar sv_skyname;

public bool RandomizeSkybox_Initialize(ChaosEffect effect)
{
	sv_skyname = FindConVar("sv_skyname");
	
	return true;
}

public bool RandomizeSkybox_OnStart(ChaosEffect effect)
{
	char szSkyname[PLATFORM_MAX_PATH];
	sv_skyname.GetString(szSkyname, sizeof(szSkyname));
	
	char szNewSkyname[PLATFORM_MAX_PATH];
	do
	{
		strcopy(szNewSkyname, sizeof(szNewSkyname), g_szSkyNames[GetRandomInt(0, sizeof(g_szSkyNames) - 1)]);
	}
	while (StrEqual(szSkyname, szNewSkyname));
	
	sv_skyname.SetString(szNewSkyname, true);
	
	return true;
}
