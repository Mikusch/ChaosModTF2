#pragma newdecls required
#pragma semicolon 1

static Handle g_hSDKCall_IsAllowedToTaunt;

void SDKCalls_Initialize(GameData hGameData)
{
	g_hSDKCall_IsAllowedToTaunt = PrepSDKCall_IsAllowedToTaunt(hGameData);
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

bool SDKCall_IsAllowedToTaunt(int player)
{
	if (g_hSDKCall_IsAllowedToTaunt)
	{
		return SDKCall(g_hSDKCall_IsAllowedToTaunt, player);
	}
	
	return false;
}
