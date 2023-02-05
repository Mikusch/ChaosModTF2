#pragma semicolon 1
#pragma newdecls required

static float g_flNextBirdSpawnTime[MAXPLAYERS + 1];

public bool SpawnBirds_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		g_flNextBirdSpawnTime[client] = GetGameTime();
	}
	
	return true;
}

public void SpawnBirds_Update(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		if (g_flNextBirdSpawnTime[client] > GetGameTime())
			continue;
		
		g_flNextBirdSpawnTime[client] = GetGameTime() + GetRandomFloat(0.5, 1.0);
		
		float vecCenter[3];
		CBaseEntity(client).WorldSpaceCenter(vecCenter);
		SDKCall_SpawnClientsideFlyingBird(vecCenter);
	}
}
