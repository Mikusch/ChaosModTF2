#pragma semicolon 1
#pragma newdecls required

static ConVar sv_gravity;

public void InvertGravity_Initialize()
{
	sv_gravity = FindConVar("sv_gravity");
}

public void InvertGravity_OnStart()
{
	sv_gravity.FloatValue = -sv_gravity.FloatValue;
}

public void InvertGravity_OnEnd()
{
	sv_gravity.FloatValue = -sv_gravity.FloatValue;
}
