#pragma semicolon 1
#pragma newdecls required

public bool Noclip_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		CBaseEntity(client).SetMoveType(MOVETYPE_NOCLIP);
	}
	
	return true;
}

public void Noclip_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		CBaseEntity(client).SetMoveType(MOVETYPE_WALK);
	}
}

public void Noclip_OnPlayerSpawn(ChaosEffect effect, int client)
{
	CBaseEntity(client).SetMoveType(MOVETYPE_NOCLIP);
}
