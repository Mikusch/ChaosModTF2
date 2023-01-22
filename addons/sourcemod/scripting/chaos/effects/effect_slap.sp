#pragma semicolon 1
#pragma newdecls required

static float g_flNextSlapTime;

public bool Slap_OnStart(ChaosEffect effect)
{
	g_flNextSlapTime = GetGameTime();
	
	return true;
}

public void Slap_OnGameFrame(ChaosEffect effect)
{
	if (g_flNextSlapTime <= GetGameTime())
	{
		g_flNextSlapTime = GetGameTime() + GetRandomFloat(1.0, 2.0);
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (!IsPlayerAlive(client))
				continue;
			
			SlapPlayer(client, 0);
		}
	}
}
