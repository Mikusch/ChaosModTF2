#pragma semicolon 1
#pragma newdecls required

static ConVar sv_friction;
static ConVar sm_chaos_effect_icephysics_friction;

static float flOldFriction;

public void IcePhysics_Initialize()
{
	sv_friction = FindConVar("sv_friction");
	
	sm_chaos_effect_icephysics_friction = CreateConVar("sm_chaos_effect_icephysics_friction", "0.5", "How much friction to apply.");
}

public void IcePhysics_OnStart()
{
	flOldFriction = sv_friction.FloatValue;
	sv_friction.FloatValue = sm_chaos_effect_icephysics_friction.FloatValue;
}

public void IcePhysics_OnEnd()
{
	sv_friction.FloatValue = flOldFriction;
}
