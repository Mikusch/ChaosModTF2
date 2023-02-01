#pragma semicolon 1
#pragma newdecls required

public bool ModifyPitch_OnStart(ChaosEffect effect)
{
	if (IsEffectOfClassActive(effect.effect_class))
		return false;
	
	if (!effect.data)
		return false;
	
	return true;
}

public Action ModifyPitch_OnNormalSoundPlayed(ChaosEffect effect, int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	pitch = effect.data.GetNum("pitch");
	return Plugin_Changed;
}

public Action ModifyPitch_OnAmbientSoundPlayed(ChaosEffect effect, char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	pitch = effect.data.GetNum("pitch");
	return Plugin_Changed;
}
