#pragma semicolon 1
#pragma newdecls required

static Handle g_hSDKCallIsAllowedToTaunt;

public bool Thriller_Initialize(ChaosEffect effect, GameData gameconf)
{
	if (!gameconf)
		return false;
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "CTFPlayer::IsAllowedToTaunt");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	g_hSDKCallIsAllowedToTaunt = EndPrepSDKCall();
	
	return g_hSDKCallIsAllowedToTaunt != null;
}

public void Thriller_Update(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2_AddCondition(client, TFCond_HalloweenThriller);
		
		if (!TF2_IsPlayerInCondition(client, TFCond_Taunting) && SDKCall(g_hSDKCallIsAllowedToTaunt, client))
		{
			FakeClientCommand(client, "taunt");
		}
	}
}

public void Thriller_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2_RemoveCondition(client, TFCond_HalloweenThriller);
		TF2_RemoveCondition(client, TFCond_Taunting);
	}
}
