#pragma semicolon 1
#pragma newdecls required

static ConVar mp_friendlyfire;

public void FriendlyFire_Initialize()
{
	mp_friendlyfire = FindConVar("mp_friendlyfire");
}

public bool FriendlyFire_CanActivate()
{
	// Don't activate this effect if friendly fire is already active
	return !mp_friendlyfire.BoolValue;
}

public void FriendlyFire_OnStart()
{
	mp_friendlyfire.BoolValue = true;
}

public void FriendlyFire_OnEnd()
{
	mp_friendlyfire.BoolValue = false;
}
