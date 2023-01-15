#pragma semicolon 1
#pragma newdecls required

public bool RemoveWearables_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		for (int wbl = TF2Util_GetPlayerWearableCount(client) - 1; wbl >= 0; --wbl)
		{
			int wearable = TF2Util_GetPlayerWearable(client, wbl);
			if (wearable == -1)
				continue;
			
			TF2_RemoveWearable(client, wearable);
		}
	}
	
	return true;
}
