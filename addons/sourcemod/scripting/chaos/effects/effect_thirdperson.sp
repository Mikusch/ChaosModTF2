#pragma semicolon 1
#pragma newdecls required

static Handle g_hThirdPersonTimer[MAXPLAYERS + 1];

public bool ThirdPerson_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
	
	return true;
}

public void ThirdPerson_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		
		// Cancel any timers still going
		g_hThirdPersonTimer[client] = null;
	}
}

public void ThirdPerson_OnPlayerSpawn(ChaosEffect effect, int client)
{
	// We have to delay this or it won't work
	g_hThirdPersonTimer[client] = CreateTimer(0.1, Timer_SetForcedTauntCam, GetClientUserId(client));
}

static Action Timer_SetForcedTauntCam(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return Plugin_Continue;
	
	if (g_hThirdPersonTimer[client] != timer)
		return Plugin_Continue;
	
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
	
	return Plugin_Continue;
}
