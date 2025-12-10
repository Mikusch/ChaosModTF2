#pragma semicolon 1
#pragma newdecls required

public bool SetCustomModel_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	char szModel[PLATFORM_MAX_PATH];
	effect.data.GetString("model", szModel, sizeof(szModel));
	
	if (!FileExists(szModel, true, "GAME") && !FileExists(szModel, true, "MOD"))
		return false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetVariantString(szModel);
		AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
	}
	
	return true;
}

public void SetCustomModel_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}
}

public void SetCustomModel_OnPlayerSpawn(ChaosEffect effect, int client)
{
	char szModel[PLATFORM_MAX_PATH];
	effect.data.GetString("model", szModel, sizeof(szModel));
	
	SetVariantString(szModel);
	AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
}
