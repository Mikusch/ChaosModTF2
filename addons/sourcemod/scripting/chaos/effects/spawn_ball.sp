#pragma semicolon 1
#pragma newdecls required

public bool SpawnBall_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	char szModel[PLATFORM_MAX_PATH];
	effect.data.GetString("model", szModel, sizeof(szModel));
	
	int client = GetRandomPlayer();
	if (client == -1)
		return false;
	
	float vecCenter[3];
	WorldSpaceCenter(client, vecCenter);
	
	float vecDropSpot[3];
	if (CanFindBallSpawnLocation(vecCenter, vecDropSpot))
	{
		int ball = CreateEntityByName("prop_soccer_ball");
		if (IsValidEntity(ball))
		{
			DispatchKeyValue(ball, "model", szModel);
			
			if (DispatchSpawn(ball))
			{
				TeleportEntity(ball, vecCenter);
				return true;
			}
		}
	}
	
	return false;
}

static bool CanFindBallSpawnLocation(const float vecSearchOrigin[3], float vecDropSpot[3])
{
	// Find clear space to drop the ball
	for (float flAngle = 0.0; flAngle < 2.0 * FLOAT_PI; flAngle += 0.2)
	{
		float vecForward[3];
		vecForward[0] = Cosine(flAngle);
		vecForward[1] = Sine(flAngle);
		
		const float ballRadius = 16.0;
		const float playerRadius = 20.0;
		
		float vecHullMins[3] = { -ballRadius, -ballRadius, -ballRadius };
		float vecHullMaxs[3] = { ballRadius, ballRadius, ballRadius };
		
		ScaleVector(vecForward, 1.2 * (playerRadius + ballRadius));
		AddVectors(vecSearchOrigin, vecForward, vecDropSpot);
		
		TR_TraceHull(vecDropSpot, vecDropSpot, vecHullMins, vecHullMaxs, MASK_PLAYERSOLID);
		
		if (!TR_DidHit())
		{
			return true;
		}
	}
	
	return false;
}
