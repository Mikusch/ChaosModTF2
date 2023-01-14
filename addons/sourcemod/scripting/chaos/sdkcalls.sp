#pragma newdecls required
#pragma semicolon 1

static Handle g_hSDKCall_IsAllowedToTaunt;

void SDKCalls_Initialize(GameData gamedata)
{
	g_hSDKCall_IsAllowedToTaunt = PrepSDKCall_IsAllowedToTaunt(gamedata);
}

static Handle PrepSDKCall_IsAllowedToTaunt(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::IsAllowedToTaunt");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogError("Failed to create SDKCall: CTFPlayer::IsAllowedToTaunt");
	
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
