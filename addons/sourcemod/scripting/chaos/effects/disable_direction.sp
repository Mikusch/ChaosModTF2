#pragma semicolon 1
#pragma newdecls required

static Dir_t g_nDirection;

public bool DisableDirection_OnStart(ChaosEffect effect)
{
	g_nDirection = view_as<Dir_t>(GetRandomInt(DIR_FWD, DIR_RIGHT));
	
	return true;
}

public Action DisableDirection_OnPlayerRunCmd(ChaosEffect effect, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if ((g_nDirection == DIR_FWD && vel[0] > 0.0) || (g_nDirection == DIR_BACK && vel[0] < 0.0))
		vel[0] = 0.0;
	else if ((g_nDirection == DIR_RIGHT && vel[1] > 0.0) || (g_nDirection == DIR_LEFT && vel[1] < 0.0))
		vel[1] = 0.0;
	else if ((g_nDirection == DIR_UP && vel[2] > 0.0) || (g_nDirection == DIR_DOWN && vel[2] < 0.0))
		vel[2] = 0.0;
	else
		return Plugin_Continue;
	
	return Plugin_Changed;
}
