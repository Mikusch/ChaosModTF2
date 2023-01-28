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
		
		if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == 0)
		{
			TF2_IgnitePlayer(client, client);
		}
	}
}
