#pragma semicolon 1
#pragma newdecls required

static DynamicDetour g_hDetourCalculateMaxSpeed;
static float g_flMaxSpeed;

public bool SetSpeed_Initialize(ChaosEffect effect, GameData gameconf)
{
	if (!gameconf)
		return false;
	
	g_hDetourCalculateMaxSpeed = DynamicDetour.FromConf(gameconf, "CTFPlayer::TeamFortress_CalculateMaxSpeed");
	
	return g_hDetourCalculateMaxSpeed != null;
}

public bool SetSpeed_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	g_flMaxSpeed = effect.data.GetFloat("speed");
	
	if (!g_hDetourCalculateMaxSpeed.Enable(Hook_Pre, OnCalculateMaxSpeed))
		return false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2Util_UpdatePlayerSpeed(client);
	}
	
	return true;
}

public void SetSpeed_OnEnd(ChaosEffect effect)
{
	g_hDetourCalculateMaxSpeed.Disable(Hook_Pre, OnCalculateMaxSpeed);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2Util_UpdatePlayerSpeed(client);
	}
}

static MRESReturn OnCalculateMaxSpeed(int player, DHookReturn hReturn, DHookParam hParam)
{
	if (hReturn.Value <= 1.0)
		return MRES_Ignored;
	
	hReturn.Value = g_flMaxSpeed;
	
	return MRES_Supercede;
}
