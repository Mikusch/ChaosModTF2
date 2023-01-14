#pragma semicolon 1
#pragma newdecls required

public void Thriller_OnEnd()
{
	for (int client = 1; client<=MaxClients;client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2_RemoveCondition(client, TFCond_HalloweenThriller);
	}
}

public Action Thriller_OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	TF2_AddCondition(client, TFCond_HalloweenThriller);
	
	if (!TF2_IsPlayerInCondition(client, TFCond_Taunting) && SDKCall_IsAllowedToTaunt(client))
	{
		FakeClientCommand(client, "taunt");
	}
	
	return Plugin_Continue;
}
