#pragma semicolon 1
#pragma newdecls required

public bool ScreenOverlay_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	return true;
}

public void ScreenOverlay_Update(ChaosEffect effect)
{
	char szScreenOverlay[PLATFORM_MAX_PATH];
	effect.data.GetString("material", szScreenOverlay, sizeof(szScreenOverlay));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntPropString(client, Prop_Send, "m_szScriptOverlayMaterial", szScreenOverlay);
	}
}

public void ScreenOverlay_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntPropString(client, Prop_Send, "m_szScriptOverlayMaterial", "");
	}
}
