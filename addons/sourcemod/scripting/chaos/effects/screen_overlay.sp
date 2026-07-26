#pragma semicolon 1
#pragma newdecls required

public void ScreenOverlay_GetClaims(ChaosEffect effect, ArrayList claims)
{
	// One m_szScriptOverlayMaterial per player, so overlays cannot stack
	claims.PushString("player:overlay");
}

public void ScreenOverlay_OnMapStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	char szFilePath[PLATFORM_MAX_PATH];
	kv.GetString("material", szFilePath, sizeof(szFilePath));

	if (szFilePath[0] && Format(szFilePath, sizeof(szFilePath), "materials/%s.vmt", szFilePath))
		AddFileToDownloadsTable(szFilePath);

	kv.GetString("shader", szFilePath, sizeof(szFilePath));

	if (szFilePath[0] && Format(szFilePath, sizeof(szFilePath), "shaders/fxc/%s.vcs", szFilePath))
		AddFileToDownloadsTable(szFilePath);
}

public bool ScreenOverlay_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	char szMaterial[PLATFORM_MAX_PATH];
	kv.GetString("material", szMaterial, sizeof(szMaterial));

	if (!szMaterial[0])
		return false;

	int dspType = kv.GetNum("dsp", 0);

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
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	int dspType = kv.GetNum("dsp", 0);

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
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	char szMaterial[PLATFORM_MAX_PATH];
	kv.GetString("material", szMaterial, sizeof(szMaterial));

	SetEntPropString(client, Prop_Send, "m_szScriptOverlayMaterial", szMaterial);

	int dspType = kv.GetNum("dsp", 0);
	if (dspType != 0)
		ClientCommand(client, "dsp_player %d", dspType);
}
