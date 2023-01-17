#pragma semicolon 1
#pragma newdecls required

public bool ShuffleClasses_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TFClassType nClass = TF2_GetPlayerClass(client);
		
		if (nClass == TFClass_Unknown)
			continue;
		
		do
		{
			nClass = view_as<TFClassType>(GetRandomInt(view_as<int>(TFClass_Scout), view_as<int>(TFClass_Engineer)));
			TF2_SetPlayerClass(client, nClass);
		}
		while (TF2_GetPlayerClass(client) != nClass);
		
		// Update loadouts and stuff
		TF2_RegeneratePlayer(client);
	}
	
	return true;
}
