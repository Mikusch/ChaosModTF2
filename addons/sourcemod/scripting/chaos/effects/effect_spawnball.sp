#pragma semicolon 1
#pragma newdecls required

public bool SpawnBall_OnStart(ChaosEffect effect)
{
	int ball = CreateEntityByName("prop_soccer_ball");
	if (IsValidEntity(ball))
	{
		DispatchKeyValue(ball, "model", "models/props_halloween/hwn_kart_ball01.mdl");
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
