#pragma semicolon 1
#pragma newdecls required

static ConVar sv_stepsize;
static float g_flStepSize;

public bool StepSize_Initialize(ChaosEffect effect)
{
	sv_stepsize = FindConVar("sv_stepsize");
	
	return true;
}

public bool StepSize_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	g_flStepSize = effect.data.GetFloat("stepsize");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", g_flStepSize);
	}
	
	return true;
}

public void StepSize_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", sv_stepsize.FloatValue);
	}
}

public void StepSize_OnPlayerSpawn(ChaosEffect effect, int client)
{
	SetEntPropFloat(client, Prop_Send, "m_flStepSize", g_flStepSize);
}
