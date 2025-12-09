#pragma semicolon 1
#pragma newdecls required

#define ENTITY_FLYING_BIRD_SPEED_MIN 200.0
#define ENTITY_FLYING_BIRD_SPEED_MAX 500.0

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
		WorldSpaceCenter(client, vecCenter);
		SpawnClientsideFlyingBird(vecCenter);
	}
}

static void SpawnClientsideFlyingBird(float vecSpawn[3])
{
	float flyAngle = GetRandomFloat(-FLOAT_PI, FLOAT_PI);
	float flyAngleRate = GetRandomFloat(-1.5, 1.5);
	float accelZ = GetRandomFloat(0.5, 2.0);
	float speed = GetRandomFloat(ENTITY_FLYING_BIRD_SPEED_MIN, ENTITY_FLYING_BIRD_SPEED_MAX);
	float flGlideTime = GetRandomFloat(0.25, 1.0);

	BfWrite bf = UserMessageToBfWrite(StartMessageAll("SpawnFlyingBird"));
		bf.WriteVecCoord(vecSpawn);
		bf.WriteFloat(flyAngle);
		bf.WriteFloat(flyAngleRate);
		bf.WriteFloat(accelZ);
		bf.WriteFloat(speed);
		bf.WriteFloat(flGlideTime);
	EndMessage();
}
