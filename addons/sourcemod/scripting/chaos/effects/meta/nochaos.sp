#pragma semicolon 1
#pragma newdecls required

public bool NoChaos_OnStart(ChaosEffect effect)
{
	ExpireAllActiveEffects(true);
	
	// Request to pause timer
	g_bNoChaos = true;
	
	return true;
}

public void NoChaos_OnEnd(ChaosEffect effect)
{
	// Resume chaos
	g_bNoChaos = false;
	g_flLastEffectActivateTime = GetGameTime();
	g_flLastMetaEffectActivateTime = GetGameTime();
}
