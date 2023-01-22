#pragma semicolon 1
#pragma newdecls required

static ConVar sv_stepsize;

public void StepSize_Initialize(ChaosEffect effect)
{
	sv_stepsize = FindConVar("sv_stepsize");
}

public bool StepSize_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetEntPropFloat(client, Prop_Data, "m_flStepSize", 0.0);
	}
	
	return true;
}

public void StepSize_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetEntPropFloat(client, Prop_Data, "m_flStepSize", sv_stepsize.FloatValue);
	}
}

public void StepSize_OnPlayerSpawn(ChaosEffect effect, int client)
{
	SetEntPropFloat(client, Prop_Data, "m_flStepSize", 0.0);
}
