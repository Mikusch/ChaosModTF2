#pragma semicolon 1
#pragma newdecls required

#define ENTITY_FLYING_BIRD_MODEL	"models/props_forest/dove.mdl"

#define ENTITY_FLYING_BIRD_SPEED_MIN	200.0
#define ENTITY_FLYING_BIRD_SPEED_MAX	500.0

public bool SpawnBirds_OnStart(ChaosEffect effect)
{
	PrecacheModel(ENTITY_FLYING_BIRD_MODEL);

	float flNextBirdSpawnTime[MAXPLAYERS + 1];
	for (int client = 1; client <= MaxClients; client++)
	{
		flNextBirdSpawnTime[client] = GetGameTime();
	}

	effect.state.SetArray("next_bird_spawn_time", flNextBirdSpawnTime, sizeof(flNextBirdSpawnTime));

	return true;
}

public void SpawnBirds_Update(ChaosEffect effect)
{
	float flNextBirdSpawnTime[MAXPLAYERS + 1];
	if (!effect.state.GetArray("next_bird_spawn_time", flNextBirdSpawnTime, sizeof(flNextBirdSpawnTime)))
		return;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		if (!IsPlayerAlive(client))
			continue;

		if (flNextBirdSpawnTime[client] > GetGameTime())
			continue;

		flNextBirdSpawnTime[client] = GetGameTime() + GetRandomFloat(0.5, 1.0);

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

	effect.state.SetArray("next_bird_spawn_time", flNextBirdSpawnTime, sizeof(flNextBirdSpawnTime));
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
