#pragma semicolon 1
#pragma newdecls required

public Action Silence_OnSoundPlayed(ChaosEffect effect, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	// Refuse to play any sound
	return Plugin_Handled;
}
