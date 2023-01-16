#pragma semicolon 1
#pragma newdecls required

public bool RespawnAllDead_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (IsPlayerAlive(client))
			continue;
		
		TF2_RespawnPlayer(client);
	}
	
	return true;
}
