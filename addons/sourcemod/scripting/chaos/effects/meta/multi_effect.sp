// by pokemonpasta

#pragma semicolon 1
#pragma newdecls required

static int g_iNumEffects;
static int g_iActivatedEffects;
static Handle g_hTimer;

public bool MultiEffect_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;

	// Only allow one active at a time
	if (IsEffectOfClassActive(effect.effect_class))
		return false;

	g_iNumEffects = effect.data.GetNum("effect_count");
	if (g_iNumEffects < 1)
		return false;

	g_iActivatedEffects = 0;
	float flNextEffectDelay = (effect.duration - 0.1) / float(g_iNumEffects); // n effects over m seconds

	g_hTimer = CreateTimer(flNextEffectDelay, Timer_NextEffect, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	return true;
}

public void MultiEffect_OnEnd(ChaosEffect effect)
{
	g_hTimer = null;
}

static Action Timer_NextEffect(Handle timer)
{
	if (g_hTimer != timer)
		return Plugin_Stop;

	SelectRandomEffect(false); // Don't allow meta effects within the multi

	if (++g_iActivatedEffects < g_iNumEffects)
		return Plugin_Continue;

	return Plugin_Stop;
}
