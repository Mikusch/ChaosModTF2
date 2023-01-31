#pragma semicolon 1
#pragma newdecls required

static char g_aCatSounds[][] =
{
	"items/halloween/cat01.wav",
	"items/halloween/cat02.wav",
	"items/halloween/cat03.wav",
};

public void CattoGuns_OnMapStart(ChaosEffect effect)
{
	for (int i = 0; i < sizeof(g_aCatSounds); i++)
	{
		PrecacheSound(g_aCatSounds[i]);
	}
}

public Action CattoGuns_OnSoundPlayed(ChaosEffect effect, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (StrContains(sample, "weapons/") == -1)
		return Plugin_Continue;
	
	strcopy(sample, sizeof(sample), g_aCatSounds[GetRandomInt(0, sizeof(g_aCatSounds) - 1)]);
	return Plugin_Changed;
}
