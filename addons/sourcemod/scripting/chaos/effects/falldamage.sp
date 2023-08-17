#pragma semicolon 1
#pragma newdecls required

static float g_flMultiplier;

public bool FallDamage_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	g_flMultiplier = effect.data.GetFloat("multiplier");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
	}
	
	return true;
}

public void FallDamage_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
	}
}

public void FallDamage_OnClientPutInServer(ChaosEffect effect, int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

static Action OnPlayerTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (damagetype & DMG_FALL)
	{
		damage *= g_flMultiplier;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
