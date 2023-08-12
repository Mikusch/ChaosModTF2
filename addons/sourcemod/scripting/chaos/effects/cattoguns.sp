#pragma semicolon 1
#pragma newdecls required

static char g_aCatSounds[][] =
{
	"items/halloween/cat01.wav",
	"items/halloween/cat02.wav",
	"items/halloween/cat03.wav",
};

public bool CattoGuns_OnStart(ChaosEffect effect)
{
	AddNormalSoundHook(OnNormalSoundPlayed);
	
	return true;
}

public void CattoGuns_OnEnd(ChaosEffect effect)
{
	RemoveNormalSoundHook(OnNormalSoundPlayed);
}

static Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	int start = StrContains(sample, "weapons/");
	if (start == -1)
		return Plugin_Continue;
	
	// Make sure to keep sound chars intact
	strcopy(sample, start + 1, sample);
	StrCat(sample, sizeof(sample), g_aCatSounds[GetRandomInt(0, sizeof(g_aCatSounds) - 1)]);
	
	PrecacheSound(sample);
	
	return Plugin_Changed;
}
