#pragma semicolon 1
#pragma newdecls required

public bool Fling_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		float vecVelocity[3];
		vecVelocity[0] = GetRandomFloat(-1000.0, 1000.0);
		vecVelocity[1] = GetRandomFloat(-1000.0, 1000.0);
		vecVelocity[2] = GetRandomFloat(500.0, 1000.0);
		
		TeleportEntity(client, .velocity = vecVelocity);
	}
	
	return true;
}
