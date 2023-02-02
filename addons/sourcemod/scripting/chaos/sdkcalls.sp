#pragma newdecls required
#pragma semicolon 1

static Handle g_hSDKCall_IsAllowedToTaunt;
static Handle g_hSDKCall_PostInventoryApplication;
static Handle g_hSDKCall_SpawnClientsideFlyingBird;

void SDKCalls_Initialize(GameData hGameData)
{
	g_hSDKCall_IsAllowedToTaunt = PrepSDKCall_IsAllowedToTaunt(hGameData);
	g_hSDKCall_PostInventoryApplication = PrepSDKCall_PostInventoryApplication(hGameData);
	g_hSDKCall_SpawnClientsideFlyingBird = PrepSDKCall_SpawnClientsideFlyingBird(hGameData);
}

static Handle PrepSDKCall_IsAllowedToTaunt(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::IsAllowedToTaunt");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle hCall = EndPrepSDKCall();
	if (!hCall)
		LogError("Failed to create SDKCall: CTFPlayer::IsAllowedToTaunt");
	
	return hCall;
}

static Handle PrepSDKCall_PostInventoryApplication(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTFPlayer::PostInventoryApplication");
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayer::PostInventoryApplication");
	
	return call;
}

static Handle PrepSDKCall_SpawnClientsideFlyingBird(GameData hGameData)
{
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "SpawnClientsideFlyingBird");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: SpawnClientsideFlyingBird");
	
	return call;
}

bool SDKCall_IsAllowedToTaunt(int player)
{
	if (g_hSDKCall_IsAllowedToTaunt)
	{
		return SDKCall(g_hSDKCall_IsAllowedToTaunt, player);
	}
	
	return false;
}

void SDKCall_PostInventoryApplication(int player)
{
	if (g_hSDKCall_PostInventoryApplication)
	{
		SDKCall(g_hSDKCall_PostInventoryApplication, player);
	}
}

void SDKCall_SpawnClientsideFlyingBird(const float vecSpawn[3])
{
	if (g_hSDKCall_SpawnClientsideFlyingBird)
	{
		SDKCall(g_hSDKCall_SpawnClientsideFlyingBird, vecSpawn);
	}
}
