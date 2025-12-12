#pragma semicolon 1
#pragma newdecls required

public Action ForceJump_OnPlayerRunCmd(ChaosEffect effect, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
		return Plugin_Continue;
	
	buttons |= IN_JUMP;
	SetEntProp(client, Prop_Data, "m_nOldButtons", GetEntProp(client, Prop_Data, "m_nOldButtons") & ~IN_JUMP);
	
	return Plugin_Changed;
}
