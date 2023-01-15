#pragma semicolon 1
#pragma newdecls required

public bool KillRandomPlayer_OnStart(ChaosEffect effect)
{
	ArrayList players = new ArrayList();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		players.Push(client);
	}
	
	if (!players.Length)
	{
		delete players;
		return false;
	}
	
	// Fuck this guy in particular
	int client = players.Get(GetRandomInt(0, players.Length - 1));
	ForcePlayerSuicide(client);
	
	return true;
}
