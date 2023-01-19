#pragma semicolon 1
#pragma newdecls required

public bool SpawnBall_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	char szModel[PLATFORM_MAX_PATH];
	effect.data.GetString("model", szModel, sizeof(szModel));
	
	int ball = CreateEntityByName("prop_soccer_ball");
	if (IsValidEntity(ball))
	{
		DispatchKeyValue(ball, "model", szModel);
		DispatchSpawn(ball);
		
		int client = GetRandomPlayer();
		if (client == -1)
		{
			RemoveEntity(ball);
			return false;
		}
		
		float vecCenter[3];
		CBaseEntity(client).WorldSpaceCenter(vecCenter);
		
		TeleportEntity(ball, vecCenter);
		return true;
	}
	
	return false;
}
