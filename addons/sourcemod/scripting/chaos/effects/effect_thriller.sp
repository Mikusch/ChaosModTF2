#pragma semicolon 1
#pragma newdecls required

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

public void Thriller_OnGameFrame(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2_AddCondition(client, TFCond_HalloweenThriller);
		
		if (!TF2_IsPlayerInCondition(client, TFCond_Taunting) && SDKCall_IsAllowedToTaunt(client))
		{
			FakeClientCommand(client, "taunt");
		}
	}
}
