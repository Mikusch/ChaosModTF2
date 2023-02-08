#pragma semicolon 1
#pragma newdecls required

static ConVar net_fakeloss;
static Handle g_hFakeCrashTimer;

public void FakeCrash_Initialize(ChaosEffect effect)
{
	net_fakeloss = FindConVar("net_fakeloss");
}

public bool FakeCrash_OnStart(ChaosEffect effect)
{
	// Fake crash already in progress
	if (net_fakeloss.IntValue || g_hFakeCrashTimer)
		return false;
	
	net_fakeloss.IntValue = 100;
	g_hFakeCrashTimer = CreateTimer(GetRandomFloat(6.0, 12.0), Timer_StopFakeCrash);
	
	return true;
}

static Action Timer_StopFakeCrash(Handle timer)
{
	if (g_hFakeCrashTimer != timer)
		return Plugin_Continue;
	
	net_fakeloss.IntValue = 0;
	g_hFakeCrashTimer = null;
	
	return Plugin_Continue;
}
