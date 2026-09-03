#pragma semicolon 1
#pragma newdecls required

public bool BurnPlayer_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	float flDuration = kv.GetFloat("duration");

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		if (!IsPlayerAlive(client))
			continue;

		TF2_IgnitePlayer(client, client, flDuration);
	}

	return true;
}
