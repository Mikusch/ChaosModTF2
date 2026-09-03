#pragma semicolon 1
#pragma newdecls required

public void EffectDuration_GetClaims(ChaosEffect effect, ArrayList claims)
{
	claims.PushString("meta:effect_duration");
}

public bool EffectDuration_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	float flMult = kv.GetFloat("multiplier");
	if (flMult <= 0.0)
	{
		LogError("Effect '%s': 'multiplier' must be greater than zero", effect.id);
		return false;
	}

	float flCurTime = GetGameTime();

	int nLength = g_hActiveEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		int nIndex = g_hActiveEffects.Get(i);

		ChaosEffect other;
		if (!g_hEffects.GetArray(nIndex, other))
			continue;

		if (StrEqual(other.id, effect.id) || !other.duration)
			continue;

		float flRemaining = other.end_time - flCurTime;
		if (flRemaining <= 0.0)
			continue;

		other.end_time = flCurTime + flRemaining * flMult;
		other.current_duration = other.end_time - other.activate_time;

		g_hEffects.SetArray(nIndex, other);
	}

	return true;
}

public void EffectDuration_ModifyEffectDuration(ChaosEffect effect, float &duration)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	float flMult = kv.GetFloat("multiplier");
	if (flMult > 0.0)
		duration *= flMult;
}
