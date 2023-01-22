#pragma semicolon 1
#pragma newdecls required

public bool TiltedCamera_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		TeleportEntity(client, .angles = { 0.0, 0.0, 90.0 } );
	}
	
	return true;
}

public void TiltedCamera_OnGameFrame(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		float vecPunchAngleVel[3];
		vecPunchAngleVel[2] = FLT_MAX;
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", vecPunchAngleVel);
	}
}

public void TiltedCamera_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetEntPropVector(client, Prop_Send, "m_vecPunchAngleVel", { 0.0, 0.0, 0.0 } );
		TeleportEntity(client, .angles = { 0.0, 0.0, 0.0 } );
	}
}
