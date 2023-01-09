#pragma semicolon 1
#pragma newdecls required

public void KillRandomPlayer_OnStart()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		ForcePlayerSuicide(client);
	}
}
