#pragma semicolon 1
#pragma newdecls required

static ConVar net_fakeloss;

public bool FakeCrash_Initialize(ChaosEffect effect)
{
	if (!SDKCalls_CanSetPausedForced())
		return false;

	net_fakeloss = FindConVar("net_fakeloss");

	return true;
}

public bool FakeCrash_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	// Fake crash already in progress
	if (net_fakeloss.IntValue != 0)
		return false;

	float flMinDuration = kv.GetFloat("min_duration");
	float flMaxDuration = kv.GetFloat("max_duration");

	net_fakeloss.IntValue = 100;
	SetPausedForced(true);
	CreateTimer(GetRandomFloat(flMinDuration, flMaxDuration), Timer_EndFakeCrash, _, TIMER_FLAG_NO_MAPCHANGE);

	return true;
}

static void Timer_EndFakeCrash(Handle timer)
{
	SetPausedForced(false);
	net_fakeloss.IntValue = 0;
}
