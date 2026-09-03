#pragma semicolon 1
#pragma newdecls required

public void SetFOV_GetClaims(ChaosEffect effect, ArrayList claims)
{
	claims.PushString("player:fov");
}

public bool SetFOV_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	int iFOV = kv.GetNum("fov");

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		SetFOV(client, iFOV);
	}

	return true;
}

public void SetFOV_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		SetDefaultFOV(client);
	}
}

public void SetFOV_OnPlayerSpawn(ChaosEffect effect, int client)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	SetFOV(client, kv.GetNum("fov"));
}

public void SetFOV_OnConditionRemoved(ChaosEffect effect, int client, TFCond condition)
{
	if (condition != TFCond_Zoomed && condition != TFCond_Teleporting && condition != TFCond_HalloweenKartDash)
		return;

	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	SetFOV(client, kv.GetNum("fov"));
}

static void SetFOV(int client, int iFOV)
{
	SetEntProp(client, Prop_Send, "m_iFOV", iFOV);
	SetEntProp(client, Prop_Send, "m_iDefaultFOV", iFOV);
}

static void SetDefaultFOV(int client)
{
	char szFOV[32];
	if (GetClientInfo(client, "fov_desired", szFOV, sizeof(szFOV)))
	{
		SetFOV(client, StringToInt(szFOV));
	}
}
