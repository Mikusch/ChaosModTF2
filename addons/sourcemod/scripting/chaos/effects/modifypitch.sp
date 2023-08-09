#pragma semicolon 1
#pragma newdecls required

static int g_nPitch;

public bool ModifyPitch_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	AddNormalSoundHook(OnNormalSoundPlayed);
	AddAmbientSoundHook(OnAmbientSoundPlayed);
	
	g_nPitch = effect.data.GetNum("pitch");
	
	return true;
}

public void ModifyPitch_OnEnd(ChaosEffect effect)
{
	RemoveNormalSoundHook(OnNormalSoundPlayed);
	RemoveAmbientSoundHook(OnAmbientSoundPlayed);
}

static Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	pitch += g_nPitch;
	return Plugin_Changed;
}

static Action OnAmbientSoundPlayed(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	pitch += g_nPitch;
	return Plugin_Changed;
}
