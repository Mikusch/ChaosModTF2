#pragma semicolon 1
#pragma newdecls required

static Dir_t g_nDirection;

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

public bool ForceMove_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;

	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;

	g_nDirection = view_as<Dir_t>(effect.data.GetNum("direction", DIR_FWD));

	return true;
}

public Action ForceMove_OnPlayerRunCmd(ChaosEffect effect, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;

	switch (g_nDirection)
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
