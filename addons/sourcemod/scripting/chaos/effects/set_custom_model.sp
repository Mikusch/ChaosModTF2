#pragma semicolon 1
#pragma newdecls required

public void SetCustomModel_GetClaims(ChaosEffect effect, ArrayList claims)
{
	claims.PushString("player:model");
}

public bool SetCustomModel_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	char szModel[PLATFORM_MAX_PATH];
	kv.GetString("model", szModel, sizeof(szModel));

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
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	char szModel[PLATFORM_MAX_PATH];
	kv.GetString("model", szModel, sizeof(szModel));

	SetVariantString(szModel);
	AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
}
