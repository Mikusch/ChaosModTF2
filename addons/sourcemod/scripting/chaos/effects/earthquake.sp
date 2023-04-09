#pragma semicolon 1
#pragma newdecls required

public void Earthquake_Update(ChaosEffect effect)
{
	int total = 0;
	int[] clients = new int[MaxClients];
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
			continue;
		
		clients[total++] = client;
	}
	
	BfWrite bf = UserMessageToBfWrite(StartMessage("Shake", clients, total));
	bf.WriteByte(0);
	bf.WriteFloat(10.0);
	bf.WriteFloat(150.0);
	bf.WriteFloat(1.0);
	EndMessage();
}
