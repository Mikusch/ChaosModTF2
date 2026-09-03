#pragma semicolon 1
#pragma newdecls required

static ConVar cl_forwardspeed;
static ConVar cl_backspeed;
static ConVar cl_sidespeed;
static ConVar cl_upspeed;

public bool ForceMove_Initialize(ChaosEffect effect)
{
	cl_forwardspeed = FindConVar("cl_forwardspeed");
	cl_backspeed = FindConVar("cl_backspeed");
	cl_sidespeed = FindConVar("cl_sidespeed");
	cl_upspeed = FindConVar("cl_upspeed");

	return true;
}

public void ForceMove_GetClaims(ChaosEffect effect, ArrayList claims)
{
	claims.PushString("player:movement");
}

public bool ForceMove_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	effect.state.SetValue("direction", kv.GetNum("direction", view_as<int>(DIR_FWD)));

	return true;
}

public Action ForceMove_OnPlayerRunCmd(ChaosEffect effect, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;

	int nValue;
	if (!effect.state.GetValue("direction", nValue))
		return Plugin_Continue;

	Dir_t nDirection = view_as<Dir_t>(nValue);

	switch (nDirection)
	{
		case DIR_FWD:	vel[0] = cl_forwardspeed.FloatValue;
		case DIR_BACK:	vel[0] = -cl_backspeed.FloatValue;
		case DIR_LEFT:	vel[1] = -cl_sidespeed.FloatValue;
		case DIR_RIGHT:	vel[1] = cl_sidespeed.FloatValue;
		case DIR_UP:	vel[2] = cl_upspeed.FloatValue;
		default: return Plugin_Continue;
	}

	return Plugin_Changed;
}
