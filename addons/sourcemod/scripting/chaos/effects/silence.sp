#pragma semicolon 1
#pragma newdecls required

public bool Silence_OnStart(ChaosEffect effect)
{
	AddNormalSoundHook(OnNormalSoundPlayed);
	AddAmbientSoundHook(OnAmbientSoundPlayed);
	
	return true;
}

public void Silence_OnEnd(ChaosEffect effect)
{
	RemoveNormalSoundHook(OnNormalSoundPlayed);
	RemoveAmbientSoundHook(OnAmbientSoundPlayed);
}

static Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	return Plugin_Handled;
}

static Action OnAmbientSoundPlayed(char sample[PLATFORM_MAX_PATH], int& entity, float& volume, int& level, int& pitch, float pos[3], int& flags, float& delay)
{
	return Plugin_Handled;
}
