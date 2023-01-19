#pragma semicolon 1
#pragma newdecls required

public void PlayerGlow_OnGameFrame(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
	}
}

public void PlayerGlow_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", false);
	}
}
