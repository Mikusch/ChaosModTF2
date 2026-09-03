#pragma semicolon 1
#pragma newdecls required

public bool NoChaos_OnStart(ChaosEffect effect)
{
	ExpireAllActiveEffects(true);
	Chaos_SetPaused(true);
	Chaos_StopTimers();

	return true;
}

public void NoChaos_OnEnd(ChaosEffect effect)
{
	Chaos_SetPaused(false);
	Chaos_StartTimers();
}
