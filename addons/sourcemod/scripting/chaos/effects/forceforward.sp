#pragma semicolon 1
#pragma newdecls required

public Action ForceForward_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	vel[2] = 450.0;
	return Plugin_Changed;
}
