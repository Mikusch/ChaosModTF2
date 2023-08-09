#pragma semicolon 1
#pragma newdecls required

public bool Headshots_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SDKHook(client, SDKHook_TraceAttack, SDKHookCB_TraceAttack);
	}
	
	return true;
}

public void Headshots_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SDKUnhook(client, SDKHook_TraceAttack, SDKHookCB_TraceAttack);
	}
}

public void Headshots_OnClientPutInServer(ChaosEffect effect, int client)
{
	SDKHook(client, SDKHook_TraceAttack, SDKHookCB_TraceAttack);
}

static Action SDKHookCB_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	damagetype |= DMG_USE_HITLOCATIONS;
	return Plugin_Changed;
}
