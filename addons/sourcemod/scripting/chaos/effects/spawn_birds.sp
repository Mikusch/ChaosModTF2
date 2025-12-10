#pragma semicolon 1
#pragma newdecls required

#define ENTITY_FLYING_BIRD_MODEL	"models/props_forest/dove.mdl"

#define ENTITY_FLYING_BIRD_SPEED_MIN	200.0
#define ENTITY_FLYING_BIRD_SPEED_MAX	500.0

static float g_flNextBirdSpawnTime[MAXPLAYERS + 1];

public bool SpawnBirds_OnStart(ChaosEffect effect)
{
	PrecacheModel(ENTITY_FLYING_BIRD_MODEL);

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

		float vecPos[3], vecOrigin[3], vecCenter[3];
		GetClientAbsOrigin(client, vecOrigin);
		WorldSpaceCenter(client, vecCenter);
		AddVectors(vecOrigin, vecCenter, vecPos);
		ScaleVector(vecPos, 0.5);

		float vecRandom[3];
		vecRandom[2] = GetRandomFloat(-10.0, 20.0);
		AddVectors(vecPos, vecRandom, vecPos);

		SpawnClientsideFlyingBird(vecPos);
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
