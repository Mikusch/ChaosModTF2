#pragma semicolon 1
#pragma newdecls required

static Handle g_hSDKCallSetPausedForced;
static ConVar net_fakeloss;

public bool FakeCrash_Initialize(ChaosEffect effect)
{
	GameData gameconf;
	if (!Chaos_LoadGameData(gameconf))
		return false;

	StartPrepSDKCall(SDKCall_Engine);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "IVEngineServer::SetPausedForced");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	g_hSDKCallSetPausedForced = EndPrepSDKCall();
	delete gameconf;

	if (!g_hSDKCallSetPausedForced)
	{
		LogError("Failed to create SDKCall for IVEngineServer::SetPausedForced");
		return false;
	}

	net_fakeloss = FindConVar("net_fakeloss");

	return true;
}

public bool FakeCrash_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;

	// Fake crash already in progress
	if (IsEffectOfClassActive(effect.effect_class) || net_fakeloss.IntValue != 0)
		return false;

	float flMinDuration = effect.data.GetFloat("min_duration");
	float flMaxDuration = effect.data.GetFloat("max_duration");

	net_fakeloss.IntValue = 100;
	SetPausedForced(true);
	CreateTimer(GetRandomFloat(flMinDuration, flMaxDuration), Timer_EndFakeCrash, _, TIMER_FLAG_NO_MAPCHANGE);

	return true;
}

static void Timer_EndFakeCrash(Handle timer)
{
	SetPausedForced(false);
	net_fakeloss.IntValue = 0;
}

static void SetPausedForced(bool bPaused, float flDuration = -1.0)
{
	SDKCall(g_hSDKCallSetPausedForced, bPaused, flDuration);
}
