// by pokemonpasta

#pragma semicolon 1
#pragma newdecls required

public void MultiEffect_GetClaims(ChaosEffect effect, ArrayList claims)
{
	claims.PushString("meta:multi_effect");
}

public bool MultiEffect_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	int nNumEffects = kv.GetNum("effect_count");
	if (nNumEffects < 1)
		return false;

	float flNextEffectDelay = (effect.current_duration - 0.1) / float(nNumEffects); // n effects over m seconds
	if (flNextEffectDelay <= 0.0)
		return false;

	effect.state.SetValue("effect_count", nNumEffects);
	effect.state.SetValue("activated_effects", 0);
	effect.state.SetValue("timer", CreateTimer(flNextEffectDelay, Timer_NextEffect, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE));

	return true;
}

static Action Timer_NextEffect(Handle timer)
{
	ChaosEffect effect;
	if (!GetActiveEffectByClass("MultiEffect", effect))
		return Plugin_Stop;

	Handle hTimer;
	if (!effect.state.GetValue("timer", hTimer) || hTimer != timer)
		return Plugin_Stop;

	SelectRandomEffect(false); // Don't allow meta effects within the multi

	int nNumEffects, nActivatedEffects;
	effect.state.GetValue("effect_count", nNumEffects);
	effect.state.GetValue("activated_effects", nActivatedEffects);
	effect.state.SetValue("activated_effects", ++nActivatedEffects);

	if (nActivatedEffects < nNumEffects)
		return Plugin_Continue;

	return Plugin_Stop;
}
