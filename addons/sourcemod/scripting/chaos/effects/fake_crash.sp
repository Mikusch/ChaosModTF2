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
	// Fake crash already in progress
	if (net_fakeloss.IntValue)
		return false;

	net_fakeloss.IntValue = 100;
	SDKCall(g_hSDKCallSetPausedForced, true, GetRandomFloat(6.0, 12.0));

	// Server doesn't tick when paused, so the next frame happens after unpausing
	RequestFrame(Frame_StopFakeCrash);

	return true;
}

static void Frame_StopFakeCrash()
{
	net_fakeloss.IntValue = 0;
}
