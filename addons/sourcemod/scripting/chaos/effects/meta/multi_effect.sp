// by pokemonpasta

#pragma semicolon 1
#pragma newdecls required

static int g_iNumEffects;
static int g_iActivatedEffects;

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
	float flNextEffectDelay = 10.0 / float(g_iNumEffects); // n effects over 10 seconds

	CreateTimer(flNextEffectDelay, Timer_NextEffect, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

	return true;
}

static Action Timer_NextEffect(Handle timer)
{
	SelectRandomEffect(false); // Don't allow meta effects within the multi

	if (++g_iActivatedEffects < g_iNumEffects)
		return Plugin_Continue;

	return Plugin_Stop;
}
