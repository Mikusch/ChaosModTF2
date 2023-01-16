#pragma semicolon 1
#pragma newdecls required

public bool ScreenOverlay_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	char szScreenOverlay[64];
	effect.data.GetString("material", szScreenOverlay, sizeof(szScreenOverlay));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		ClientCommand(client, "r_screenoverlay %s", szScreenOverlay);
	}
	
	return true;
}

public void ScreenOverlay_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		ClientCommand(client, "r_screenoverlay \"\"");
	}
}

public void ScreenOverlay_OnClientPutInServer(ChaosEffect effect, int client)
{
	char szScreenOverlay[64];
	effect.data.GetString("material", szScreenOverlay, sizeof(szScreenOverlay));
	
	ClientCommand(client, "r_screenoverlay %s", szScreenOverlay);
}
