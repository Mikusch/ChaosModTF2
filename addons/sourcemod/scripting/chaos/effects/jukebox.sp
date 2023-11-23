#pragma semicolon 1
#pragma newdecls required

#define JUKEBOX_TARGETNAME	"chaos_jukebox"
#define JUKEBOX_MODEL		"models/props_lab/citizenradio.mdl"

static char g_aSongs[][] =
{
	")*music/cossack_sandvich.wav",
	")*music/mannrobics.wav",
	")*music/bump_in_the_night.wav",
	")*music/misfortune_teller.wav",
	")*misc/halloween/hwn_dance_loop.wav",
	")*music/fortress_reel_loop.wav",
	")*music/conga_sketch_167bpm_01-04.wav"
};

public bool Jukebox_Initialize(ChaosEffect effect, GameData gameconf)
{
	// This hook can remain throughout the entire plugin lifetime
	HookEvent("flagstatus_update", OnFlagStatusUpdate);
	
	return true;
}

public void Jukebox_OnMapStart(ChaosEffect effect)
{
	PrecacheModel(JUKEBOX_MODEL);
	
	for (int i = 0; i < sizeof(g_aSongs); i++)
	{
		PrecacheSound(g_aSongs[i]);
	}
}

public bool Jukebox_OnStart(ChaosEffect effect)
{
	int client = GetRandomPlayer();
	if (client == -1)
		return false;
	
	float vecOrigin[3], angRotation[3];
	GetClientAbsOrigin(client, vecOrigin);
	GetClientAbsAngles(client, angRotation);
	
	int flag = CreateEntityByName("item_teamflag");
	if (IsValidEntity(flag))
	{
		DispatchKeyValue(flag, "targetname", JUKEBOX_TARGETNAME);
		DispatchKeyValueVector(flag, "origin", vecOrigin);
		DispatchKeyValueVector(flag, "angles", angRotation);
		DispatchKeyValue(flag, "flag_paper", "headphone_notes");
		
		if (DispatchSpawn(flag))
		{
			SetEntityModel(flag, JUKEBOX_MODEL);
			EmitSoundToAll(g_aSongs[GetRandomInt(0, sizeof(g_aSongs) - 1)], flag, SNDCHAN_STATIC, SNDLEVEL_SCREAMING);
			return true;
		}
	}
	
	return false;
}

public void Jukebox_OnEntityDestroyed(ChaosEffect effect, int entity)
{
	if (!IsEntityRadio(entity))
		return;
	
	for (int i = 0; i < sizeof(g_aSongs); i++)
	{
		EmitSoundToAll(g_aSongs[i], entity, SNDCHAN_STATIC, SNDLEVEL_SCREAMING, SND_STOP);
	}
}

static void OnFlagStatusUpdate(Event event, const char[] name, bool dontBroadcast)
{
	int flag = event.GetInt("entindex");
	
	if (IsEntityRadio(flag) && GetEntProp(flag, Prop_Send, "m_nFlagStatus") == TF_FLAGINFO_HOME)
		RemoveEntity(flag);
}

static bool IsEntityRadio(int entity)
{
	char szClassname[64];
	if (!GetEntityClassname(entity, szClassname, sizeof(szClassname)) || !StrEqual(szClassname, "item_teamflag"))
		return false;
	
	char szName[64];
	return GetEntPropString(entity, Prop_Data, "m_iName", szName, sizeof(szName)) && StrEqual(szName, JUKEBOX_TARGETNAME);
}
