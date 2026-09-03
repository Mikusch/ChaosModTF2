#pragma semicolon 1
#pragma newdecls required

public bool ReinvokeEffects_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	float reinvoke_time = kv.GetFloat("reinvoke_time");
	
	bool bActivated = false;
	
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect other;
		if (g_hEffects.GetArray(i, other))
		{
			if (other.meta)
				continue;
			
			if (other.activate_time == 0.0)
				continue;
			
			if (other.activate_time + other.current_duration + reinvoke_time <= GetGameTime())
				continue;
			
			if (!ActivateEffectById(other.id))
				continue;
			
			bActivated = true;
		}
	}
	
	return bActivated;
}
