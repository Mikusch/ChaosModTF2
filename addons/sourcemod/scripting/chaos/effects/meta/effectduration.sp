#pragma semicolon 1
#pragma newdecls required

public bool EffectDuration_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	float flMult = effect.data.GetFloat("multiplier");
	
	// Modify durations of all currently active effects
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect other;
		if (g_hEffects.GetArray(i, other))
		{
			if (StrEqual(other.id, effect.id))
				continue;
			
			g_hEffects.Set(i, other.current_duration * flMult, ChaosEffect::current_duration);
		}
	}
	
	return true;
}

public void EffectDuration_ModifyEffectDuration(ChaosEffect effect, float &duration)
{
	float flMult = effect.data.GetFloat("multiplier");
	duration *= flMult;
}
