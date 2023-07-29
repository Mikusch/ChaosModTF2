#pragma semicolon 1
#pragma newdecls required

public bool ForceForward_OnStart(ChaosEffect effect)
{
	return effect.data != null;
}

public Action ForceForward_OnPlayerRunCmd(ChaosEffect effect, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	vel[0] = effect.data.GetFloat("velocity");
	return Plugin_Changed;
}
