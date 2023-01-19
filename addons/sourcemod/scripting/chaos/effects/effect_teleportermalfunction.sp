#pragma semicolon 1
#pragma newdecls required

static float g_flNextTeleportTime;

public bool TeleporterMalfunction_OnStart(ChaosEffect effect)
{
	if (!TheNavMesh.IsLoaded())
		return false;
	
	g_flNextTeleportTime = GetGameTime();
	
	return true;
}

public void TeleporterMalfunction_OnGameFrame(ChaosEffect effect)
{
	if (g_flNextTeleportTime <= GetGameTime())
	{
		g_flNextTeleportTime = GetGameTime() + GetRandomFloat(4.0, 6.0);
		
		ArrayList hAreas = new ArrayList();
		
		for (int i = 0; i < TheNavAreas.Length; i++)
		{
			hAreas.Push(TheNavAreas.Get(i));
		}
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (!IsPlayerAlive(client))
				continue;
			
			int nIndex = GetRandomInt(0, hAreas.Length - 1);
			CNavArea area = hAreas.Get(nIndex);
			if (!area)
				continue;
			
			if (area.IsBlocked(GetClientTeam(client)))
				continue;
			
			hAreas.Erase(nIndex);
			
			float vecCenter[3];
			area.GetCenter(vecCenter);
			
			TeleportEntity(client, vecCenter);
		}
		
		delete hAreas;
	}
}
