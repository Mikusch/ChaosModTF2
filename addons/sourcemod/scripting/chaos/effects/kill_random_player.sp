#pragma semicolon 1
#pragma newdecls required

public bool KillRandomPlayer_OnStart(ChaosEffect effect)
{
	int client = GetRandomPlayer();
	if (client == -1)
		return false;

	CPrintToChatAll("%s%t", g_stChatConfig.tag, "#Chaos_Effect_KillRandomPlayer_Killed", client);
	ForcePlayerSuicide(client, true);
	
	return true;
}
