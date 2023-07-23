#pragma semicolon 1
#pragma newdecls required

public bool ReinvokeEffects_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	float flReinvokeTime = effect.data.GetFloat("time");
	
	bool bActivated = false;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect other;
		if (g_hEffects.GetArray(i, other) && !other.active)
		{
			if (other.meta)
				continue;
			
			if (other.activate_time == 0.0)
				continue;
			
			if (other.activate_time + other.current_duration + flReinvokeTime <= GetGameTime())
				continue;
			
			if (!ActivateEffect(other))
				continue;
			
			bActivated = true;
		}
	}
	
	return bActivated;
}
