#pragma semicolon 1
#pragma newdecls required

public Action Silence_OnNormalSoundPlayed(ChaosEffect effect, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	return Plugin_Handled;
}

public Action Silence_OnAmbientSoundPlayed(ChaosEffect effect, char sample[PLATFORM_MAX_PATH], int& entity, float& volume, int& level, int& pitch, float pos[3], int& flags, float& delay)
{
	return Plugin_Handled;
}
