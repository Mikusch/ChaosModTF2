#pragma semicolon 1
#pragma newdecls required

static ConVar sv_stepsize;

public bool StepSize_Initialize(ChaosEffect effect)
{
	sv_stepsize = FindConVar("sv_stepsize");

	return true;
}

public void StepSize_GetClaims(ChaosEffect effect, ArrayList claims)
{
	claims.PushString("player:step_size");
}

public bool StepSize_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	float flStepSize = kv.GetFloat("stepsize");
	effect.state.SetValue("stepsize", flStepSize);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		SetEntPropFloat(client, Prop_Send, "m_flStepSize", flStepSize);
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
	float flStepSize;
	if (!effect.state.GetValue("stepsize", flStepSize))
		return;

	SetEntPropFloat(client, Prop_Send, "m_flStepSize", flStepSize);
}
