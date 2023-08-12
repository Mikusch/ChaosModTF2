#pragma semicolon 1
#pragma newdecls required

public bool Loudness_OnStart(ChaosEffect effect)
{
	AddNormalSoundHook(OnNormalSoundPlayed);
	
	return true;
}

public void Loudness_OnEnd(ChaosEffect effect)
{
	RemoveNormalSoundHook(OnNormalSoundPlayed);
}

static Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	for (int i = 0; i < 10; i++)
	{
		EmitSound(clients, numClients, sample, entity, SNDCHAN_STATIC, level, flags, volume, pitch);
	}
	
	return Plugin_Continue;
}
