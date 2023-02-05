#pragma semicolon 1
#pragma newdecls required

public bool ScreenOverlay_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetScreenOverlayFromEffectData(effect, client);
	}
	
	return true;
}

public void ScreenOverlay_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		ClientCommand(client, "r_screenoverlay %s", "off");
	}
}

public void ScreenOverlay_OnClientPutInServer(ChaosEffect effect, int client)
{
	SetScreenOverlayFromEffectData(effect, client);
}

public void ScreenOverlay_OnConditionAdded(ChaosEffect effect, int client, TFCond condition)
{
	SetScreenOverlayFromEffectData(effect, client);
}

public void ScreenOverlay_OnConditionRemoved(ChaosEffect effect, int client, TFCond condition)
{
	SetScreenOverlayFromEffectData(effect, client);
}

static void SetScreenOverlayFromEffectData(ChaosEffect effect, int client)
{
	char szScreenOverlay[PLATFORM_MAX_PATH];
	effect.data.GetString("material", szScreenOverlay, sizeof(szScreenOverlay));
	
	ClientCommand(client, "r_screenoverlay %s", szScreenOverlay);
}
