#pragma semicolon 1
#pragma newdecls required

public bool NoChaos_OnStart(ChaosEffect effect)
{
	ExpireAllActiveEffects(true);
	
	// Request to pause timer
	g_bNoChaos = true;
	SetChaosTimers(0.0);
	
	return true;
}

public void NoChaos_OnEnd(ChaosEffect effect)
{
	// Resume chaos
	g_bNoChaos = false;
	SetChaosTimers(GetGameTime());
}
