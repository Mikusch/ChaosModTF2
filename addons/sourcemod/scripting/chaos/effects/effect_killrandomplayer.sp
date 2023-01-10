#pragma semicolon 1
#pragma newdecls required

public void KillRandomPlayer_OnStart()
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
	
	if (players.Length)
	{
		int client = players.Get(GetRandomInt(0, players.Length - 1));
		ForcePlayerSuicide(client);
	}
	
	delete players;
}
