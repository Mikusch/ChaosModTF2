#pragma semicolon 1
#pragma newdecls required

public float Slap_Update(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		if (!IsPlayerAlive(client))
			continue;

		SlapPlayer(client, 0);
	}

	return GetRandomFloat(1.0, 2.0);
}
