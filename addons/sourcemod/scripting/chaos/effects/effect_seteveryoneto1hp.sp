#pragma semicolon 1
#pragma newdecls required

public void SetEveryoneTo1HP_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetEntProp(client, Prop_Data, "m_iHealth", 1);
	}
}
