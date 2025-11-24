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
		
		if (TF2_IsPlayerInCondition(client, TFCond_Zoomed))
			continue;
		
		SetFOV(iFOV);
	}
	
	return true;
}

public void SetFOV_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_IsPlayerInCondition(client, TFCond_Zoomed))
			continue;
		
		SetDefaultFOV(client);
	}
}

public void SetFOV_OnPlayerSpawn(ChaosEffect effect, int client)
{
	SetFOV(effect.data.GetNum("fov"));
}

public void SetFOV_OnConditionAdded(ChaosEffect effect, int client, TFCond condition)
{
	if (condition == TFCond_Zoomed)
	{
		SetDefaultFOV(client);
	}
}

public void SetFOV_OnConditionRemoved(ChaosEffect effect, int client, TFCond condition)
{
	if (condition == TFCond_Zoomed)
	{
		SetFOV(effect.data.GetNum("fov"));
	}
}

static void SetFOV(int client)
{
	SetEntProp(client, Prop_Send, "m_iFOV", iFOV);
	SetEntProp(client, Prop_Send, "m_iDefaultFOV", iFOV);
}

static void SetDefaultFOV(int client)
{
	char szFOV[32];
	if (GetClientInfo(client, "fov_desired", szFOV, sizeof(szFOV)))
	{
		SetFOV(StringToInt(szFOV));
	}
}
