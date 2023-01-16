
#pragma semicolon 1
#pragma newdecls required

public bool SetSpeed_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
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
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2Util_UpdatePlayerSpeed(client);
	}
}

public MRESReturn SetSpeed_CalculateMaxSpeed(ChaosEffect effect, int player, float &speed)
{
	speed = effect.data.GetFloat("speed");
	return MRES_Supercede;
}
