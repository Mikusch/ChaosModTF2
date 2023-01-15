#pragma semicolon 1
#pragma newdecls required

public bool MidgetMercenaries_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2Attrib_AddCustomPlayerAttribute(client, "torso scale", 0.0);
	}
	
	HookEvent("player_spawn", EventHook_PlayerSpawn);
	
	return true;
}

public void MidgetMercenaries_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2Attrib_RemoveCustomPlayerAttribute(client, "torso scale");
	}
}

static void EventHook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TF2Attrib_AddCustomPlayerAttribute(client, "torso scale", 0.0);
}
