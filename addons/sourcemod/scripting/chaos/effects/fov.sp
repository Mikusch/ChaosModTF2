#pragma semicolon 1
#pragma newdecls required

public bool SetFOV_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	int iFOV = effect.data.GetNum("fov");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntProp(client, Prop_Send, "m_iFOV", iFOV);
		SetEntProp(client, Prop_Send, "m_iDefaultFOV", iFOV);
	}
	
	return true;
}

public void SetFOV_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		char szFOV[64];
		if (GetClientInfo(client, "fov_desired", szFOV, sizeof(szFOV)))
		{
			int iFOV = StringToInt(szFOV);
			SetEntProp(client, Prop_Send, "m_iFOV", iFOV);
			SetEntProp(client, Prop_Send, "m_iDefaultFOV", iFOV);
		}
	}
}

public void SetFOV_OnPlayerSpawn(ChaosEffect effect, int client)
{
	int iFOV = effect.data.GetNum("fov");
	
	SetEntProp(client, Prop_Send, "m_iFOV", iFOV);
	SetEntProp(client, Prop_Send, "m_iDefaultFOV", iFOV);
}
