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

static Handle g_hSDKCallPickUp;

public bool Jukebox_Initialize(ChaosEffect effect, GameData gameconf)
{
	if (!gameconf)
		return false;
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "CTFItem::PickUp");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	g_hSDKCallPickUp = EndPrepSDKCall();
	
	if (g_hSDKCallPickUp != null)
	{
		HookEvent("flagstatus_update", OnFlagStatusUpdate);
		return true;
	}
	else
	{
		return false;
	}
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
	int client = FindRadioRecipient();
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
			SDKCall(g_hSDKCallPickUp, flag, client, true);
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
	
	if (!IsEntityRadio(flag))
		return;
	
	int nFlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
	switch (nFlagStatus)
	{
		case TF_FLAGINFO_HOME:
		{
			RemoveEntity(flag);
		}
		case TF_FLAGINFO_STOLEN:
		{
			EmitSoundToAll(g_aSongs[GetRandomInt(0, sizeof(g_aSongs) - 1)], flag, SNDCHAN_STATIC, SNDLEVEL_SCREAMING);
		}
		case TF_FLAGINFO_DROPPED:
		{
			for (int i = 0; i < sizeof(g_aSongs); i++)
			{
				EmitSoundToAll(g_aSongs[i], flag, SNDCHAN_STATIC, SNDLEVEL_SCREAMING, SND_STOP);
			}
		}
	}
}

static int FindRadioRecipient()
{
	ArrayList hPlayers = new ArrayList();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		float vecOrigin[3];
		GetClientAbsOrigin(client, vecOrigin);
		
		if (TF2Util_IsPointInRespawnRoom(vecOrigin, client))
			continue;
		
		if (GetEntPropEnt(client, Prop_Send, "m_hItem") != -1)
			continue;
		
		hPlayers.Push(client);
	}
	
	if (!hPlayers.Length)
	{
		delete hPlayers;
		return -1;
	}
	
	int client = hPlayers.Get(GetRandomInt(0, hPlayers.Length - 1));
	delete hPlayers;
	
	return client;
}

static bool IsEntityRadio(int entity)
{
	char szClassname[64];
	if (!GetEntityClassname(entity, szClassname, sizeof(szClassname)) || !StrEqual(szClassname, "item_teamflag"))
		return false;
	
	char szName[64];
	return GetEntPropString(entity, Prop_Data, "m_iName", szName, sizeof(szName)) && StrEqual(szName, JUKEBOX_TARGETNAME);
}
