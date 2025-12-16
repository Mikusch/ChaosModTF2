#pragma semicolon 1
#pragma newdecls required

public bool NoChaos_OnStart(ChaosEffect effect)
{
	ExpireAllActiveEffects(true);
	SetChaosPaused(true);
	StopChaosTimers();

	return true;
}

public void NoChaos_OnEnd(ChaosEffect effect)
{
	SetChaosPaused(false);
	StartChaosTimers();
}
