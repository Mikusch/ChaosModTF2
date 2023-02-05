#pragma semicolon 1
#pragma newdecls required

public void FloorIsLava_Update(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		if (!TF2_IsPlayerInCondition(client, TFCond_OnFire) && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == 0)
		{
			TF2_IgnitePlayer(client, client, 3.0);
		}
	}
}
