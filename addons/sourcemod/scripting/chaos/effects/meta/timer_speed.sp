#pragma semicolon 1
#pragma newdecls required

public bool TimerSpeed_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	return true;
}

public void TimerSpeed_ModifyTimerSpeed(ChaosEffect effect, float &flTimerSpeed)
{
	float flMult = effect.data.GetFloat("multiplier");
	flTimerSpeed *= flMult;
}
