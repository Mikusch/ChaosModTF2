#pragma semicolon 1
#pragma newdecls required

public void ScreenFade_GetClaims(ChaosEffect effect, ArrayList claims)
{
	// Whichever fade ends first sends FFADE_PURGE and clears the other
	claims.PushString("player:screenfade");
}

public bool ScreenFade_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	int clr[4];
	kv.GetColor4("color", clr);
	
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
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	int clr[4];
	kv.GetColor4("color", clr);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		UTIL_ScreenFade(client, clr, 0.0, 0.0, FFADE_IN | FFADE_PURGE);
	}
}

public void ScreenFade_OnPlayerSpawn(ChaosEffect effect, int client)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	int clr[4];
	kv.GetColor4("color", clr);
	
	UTIL_ScreenFade(client, clr, 0.0, 0.0, FFADE_OUT | FFADE_STAYOUT);
}
