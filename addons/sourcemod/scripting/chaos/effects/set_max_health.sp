#pragma semicolon 1
#pragma newdecls required

static DynamicDetour g_hDetourGetMaxHealthForBuffing;
static int g_nMaxHealth;

public bool SetMaxHealth_Initialize(ChaosEffect effect)
{
	g_hDetourGetMaxHealthForBuffing = DHooks_CreateDetour("CTFPlayer::GetMaxHealthForBuffing");
	return g_hDetourGetMaxHealthForBuffing != null;
}

public void SetMaxHealth_GetClaims(ChaosEffect effect, ArrayList claims)
{
	claims.PushString("player:max_health");
}

public bool SetMaxHealth_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	g_nMaxHealth = kv.GetNum("health");
	
	if (!g_hDetourGetMaxHealthForBuffing.Enable(Hook_Pre, OnGetMaxHealthForBuffing))
		return false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetEntProp(client, Prop_Data, "m_iHealth", g_nMaxHealth);
	}
	
	return true;
}

public void SetMaxHealth_OnEnd(ChaosEffect effect)
{
	g_hDetourGetMaxHealthForBuffing.Disable(Hook_Pre, OnGetMaxHealthForBuffing);
}

static MRESReturn OnGetMaxHealthForBuffing(int player, DHookReturn hReturn)
{
	hReturn.Value = g_nMaxHealth;
	return MRES_Supercede;
}
