#pragma semicolon 1
#pragma newdecls required

public bool ScreenFade_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	int clr[4];
	effect.data.GetColor4("color", clr);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		UTIL_ScreenFade(client, clr, 0.0, 0.0, FFADE_OUT | FFADE_STAYOUT);
	}
	
	return true;
}

public void ScreenFade_OnEnd(ChaosEffect effect)
{
	int clr[4];
	effect.data.GetColor4("color", clr);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		UTIL_ScreenFade(client, clr, 0.0, 0.0, FFADE_IN | FFADE_PURGE);
	}
}

public void ScreenFade_OnPlayerSpawn(ChaosEffect effect, int client)
{
	int clr[4];
	effect.data.GetColor4("color", clr);
	
	UTIL_ScreenFade(client, clr, 0.0, 0.0, FFADE_OUT | FFADE_STAYOUT);
}
