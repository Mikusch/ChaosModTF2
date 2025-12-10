#pragma semicolon 1
#pragma newdecls required

public bool ResizePlayer_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;

	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;

	float flScale = effect.data.GetFloat("scale", 1.0);
	float flChangeDuration = effect.data.GetFloat("change_duration");

	if (flScale == 1.0)
		return false;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetModelScale(client, flScale, flChangeDuration);
		TF2Attrib_AddCustomPlayerAttribute(client, "voice pitch scale", 1.0 / flScale);
	}

	return true;
}

public void ResizePlayer_OnPlayerSpawn(ChaosEffect effect, int client)
{
	float flScale = effect.data.GetFloat("scale", 1.0);
	float flChangeDuration = effect.data.GetFloat("change_duration");
	
	SetModelScale(client, flScale, flChangeDuration);
	TF2Attrib_AddCustomPlayerAttribute(client, "voice pitch scale", 1.0 / flScale);
}

public void ResizePlayer_OnEnd(ChaosEffect effect)
{
	float flChangeDuration = effect.data.GetFloat("change_duration");

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetModelScale(client, 1.0, flChangeDuration);
		TF2Attrib_RemoveCustomPlayerAttribute(client, "voice pitch scale");
	}
}

static void SetModelScale(int client, float scale, float change_duration = 0.0)
{
	float vecScale[3];
	vecScale[0] = scale;
	vecScale[1] = change_duration;

	SetVariantVector3D(vecScale);
	AcceptEntityInput(client, "SetModelScale");
}