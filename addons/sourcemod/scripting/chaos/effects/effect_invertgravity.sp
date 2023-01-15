#pragma semicolon 1
#pragma newdecls required

static ConVar sv_gravity;

public void InvertGravity_Initialize(ChaosEffect effect)
{
	sv_gravity = FindConVar("sv_gravity");
}

public bool InvertGravity_OnStart(ChaosEffect effect)
{
	sv_gravity.FloatValue = -sv_gravity.FloatValue;
	
	return true;
}

public void InvertGravity_OnEnd(ChaosEffect effect)
{
	sv_gravity.FloatValue = -sv_gravity.FloatValue;
}
