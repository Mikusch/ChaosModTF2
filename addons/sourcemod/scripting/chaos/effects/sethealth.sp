#pragma semicolon 1
#pragma newdecls required

public bool SetHealth_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	int health = effect.data.GetNum("health");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetEntProp(client, Prop_Data, "m_iHealth", health);
	}
	
	return true;
}

public MRESReturn SetHealth_GetMaxHealthForBuffing(ChaosEffect effect, int player, int &health)
{
	health = effect.data.GetNum("health");
	return MRES_Supercede;
}
