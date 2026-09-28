#pragma semicolon 1
#pragma newdecls required

static DynamicDetour g_hDetourGetMaxHealthForBuffing;

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

	int nHealth = kv.GetNum("health");
	
	if (!g_hDetourGetMaxHealthForBuffing.Enable(Hook_Pre, OnGetMaxHealthForBuffing))
		return false;
	
	effect.state.SetValue("health", nHealth);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetEntProp(client, Prop_Data, "m_iHealth", nHealth);
	}
	
	return true;
}

public void SetMaxHealth_OnEnd(ChaosEffect effect)
{
	g_hDetourGetMaxHealthForBuffing.Disable(Hook_Pre, OnGetMaxHealthForBuffing);
}

static MRESReturn OnGetMaxHealthForBuffing(int player, DHookReturn hReturn)
{
	ChaosEffect effect;
	if (!GetActiveEffectByClass("SetMaxHealth", effect))
		return MRES_Ignored;
	
	int nHealth;
	if (!effect.state.GetValue("health", nHealth))
		return MRES_Ignored;
	
	hReturn.Value = nHealth;
	return MRES_Supercede;
}
