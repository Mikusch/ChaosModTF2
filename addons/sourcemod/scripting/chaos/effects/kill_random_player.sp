#pragma semicolon 1
#pragma newdecls required

public bool KillRandomPlayer_OnStart(ChaosEffect effect)
{
	int client = GetRandomPlayer();
	if (client == -1)
		return false;
	
	ForcePlayerSuicide(client);
	return true;
}
