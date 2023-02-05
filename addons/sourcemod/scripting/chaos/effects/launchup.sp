#pragma semicolon 1
#pragma newdecls required

public bool LaunchUp_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		TeleportEntity(client, .velocity = { 0.0, 0.0, 1000.0 } );
	}
	
	return true;
}
