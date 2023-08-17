#pragma semicolon 1
#pragma newdecls required

public Action Drunk_OnPlayerRunCmd(ChaosEffect effect, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if (GetRandomInt(0, 1) == 0)
	{
		angles[1] = GetRandomFloat(-180.0, 180.0);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
