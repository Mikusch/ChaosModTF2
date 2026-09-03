#pragma semicolon 1
#pragma newdecls required

public void TimerSpeed_GetClaims(ChaosEffect effect, ArrayList claims)
{
	claims.PushString("meta:timer_speed");
}

public bool TimerSpeed_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	if (kv.GetFloat("multiplier") <= 0.0)
	{
		LogError("Effect '%s': 'multiplier' must be greater than zero", effect.id);
		return false;
	}

	return true;
}

public void TimerSpeed_ModifyTimerSpeed(ChaosEffect effect, float &speed)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	speed *= kv.GetFloat("multiplier");
}
