#pragma semicolon 1
#pragma newdecls required

public bool ScreenOverlay_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	char szMaterial[PLATFORM_MAX_PATH];
	effect.data.GetString("material", szMaterial, sizeof(szMaterial));

	if (!szMaterial[0])
		return false;

	int dspType = effect.data.GetNum("dsp", 0);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
			
		SetEntPropString(client, Prop_Send, "m_szScriptOverlayMaterial", szMaterial);

		if (dspType != 0)
			ClientCommand(client, "dsp_player %d", dspType);
	}
	
	return true;
}

public void ScreenOverlay_OnEnd(ChaosEffect effect)
{
	int dspType = effect.data.GetNum("dsp", 0);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntPropString(client, Prop_Send, "m_szScriptOverlayMaterial", "");

		if (dspType != 0)
			ClientCommand(client, "dsp_player %d", 0);
	}
}

public void ScreenOverlay_OnPlayerSpawn(ChaosEffect effect, int client)
{
	char szMaterial[PLATFORM_MAX_PATH];
	effect.data.GetString("material", szMaterial, sizeof(szMaterial));

	SetEntPropString(client, Prop_Send, "m_szScriptOverlayMaterial", szMaterial);

	int dspType = effect.data.GetNum("dsp", 0);
	if (dspType != 0)
		ClientCommand(client, "dsp_player %d", effect.data.GetNum("dsp", 0));
}

public void ScreenOverlay_OnMapStart(ChaosEffect effect)
{
	if (!effect.data)
		return;
	
	char szFilePath[PLATFORM_MAX_PATH];
	effect.data.GetString("material", szFilePath, sizeof(szFilePath));

	if (szFilePath[0] && Format(szFilePath, sizeof(szFilePath), "materials/%s.vmt", szFilePath))
		AddFileToDownloadsTable(szFilePath);

	effect.data.GetString("shader", szFilePath, sizeof(szFilePath));
	
	if (szFilePath[0] && Format(szFilePath, sizeof(szFilePath), "shaders/fxc/%s.vcs", szFilePath))
		AddFileToDownloadsTable(szFilePath);
}
