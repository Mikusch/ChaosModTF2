#pragma semicolon 1
#pragma newdecls required

static Handle g_hSDKCallSpawnClientsideFlyingBird;
static float g_flNextBirdSpawnTime[MAXPLAYERS + 1];

public bool SpawnBirds_Initialize(ChaosEffect effect)
{
	GameData gameconf = new GameData("chaos/birds");
	if (!gameconf)
		return false;

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "SpawnClientsideFlyingBird");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	g_hSDKCallSpawnClientsideFlyingBird = EndPrepSDKCall();

	delete gameconf;
	return g_hSDKCallSpawnClientsideFlyingBird != null;
}

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
		WorldSpaceCenter(client, vecCenter);
		SDKCall(g_hSDKCallSpawnClientsideFlyingBird, vecCenter);
	}
}
