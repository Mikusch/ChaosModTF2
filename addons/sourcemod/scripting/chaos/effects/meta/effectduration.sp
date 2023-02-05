#pragma semicolon 1
#pragma newdecls required

public bool EffectDuration_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	return true;
}

public void EffectDuration_ModifyEffectDuration(ChaosEffect effect, float &duration)
{
	float flMult = effect.data.GetFloat("multiplier");
	duration *= flMult;
}
