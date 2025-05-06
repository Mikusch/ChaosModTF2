#pragma semicolon 1
#pragma newdecls required

static DynamicDetour g_hDetourGetMaxHealthForBuffing;
static int g_nMaxHealth;

public bool SetHealth_Initialize(ChaosEffect effect, GameData gameconf)
{
	if (!gameconf)
		return false;
	
	if (!g_hDetourGetMaxHealthForBuffing)
		g_hDetourGetMaxHealthForBuffing = DynamicDetour.FromConf(gameconf, "CTFPlayer::GetMaxHealthForBuffing");
	
	return g_hDetourGetMaxHealthForBuffing != null;
}

public bool SetHealth_OnStart(ChaosEffect effect)
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

public void SetHealth_OnEnd(ChaosEffect effect)
{
	g_hDetourGetMaxHealthForBuffing.Disable(Hook_Pre, OnGetMaxHealthForBuffing);
}

static MRESReturn OnGetMaxHealthForBuffing(int player, DHookReturn hReturn)
{
	hReturn.Value = g_nMaxHealth;
	return MRES_Supercede;
}
