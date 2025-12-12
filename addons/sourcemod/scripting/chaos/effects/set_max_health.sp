#pragma semicolon 1
#pragma newdecls required

static DynamicDetour g_hDetourGetMaxHealthForBuffing;
static int g_nMaxHealth;

public bool SetMaxHealth_Initialize(ChaosEffect effect)
{
	g_hDetourGetMaxHealthForBuffing = Chaos_CreateDetour("CTFPlayer::GetMaxHealthForBuffing");
	return g_hDetourGetMaxHealthForBuffing != null;
}

public bool SetMaxHealth_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	g_nMaxHealth = effect.data.GetNum("health");
	
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
