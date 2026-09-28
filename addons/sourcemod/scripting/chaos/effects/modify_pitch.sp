#pragma semicolon 1
#pragma newdecls required

public void ModifyPitch_GetClaims(ChaosEffect effect, ArrayList claims)
{
	claims.PushString("player:sound");
}

public bool ModifyPitch_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	AddNormalSoundHook(OnNormalSoundPlayed);
	AddAmbientSoundHook(OnAmbientSoundPlayed);

	effect.state.SetValue("pitch", kv.GetNum("pitch"));
	
	return true;
}

public void ModifyPitch_OnEnd(ChaosEffect effect)
{
	RemoveNormalSoundHook(OnNormalSoundPlayed);
	RemoveAmbientSoundHook(OnAmbientSoundPlayed);
}

static Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	ChaosEffect effect;
	if (!GetActiveEffectByClass("ModifyPitch", effect))
		return Plugin_Continue;

	int nPitch;
	if (!effect.state.GetValue("pitch", nPitch))
		return Plugin_Continue;

	pitch += nPitch;
	return Plugin_Changed;
}

static Action OnAmbientSoundPlayed(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	ChaosEffect effect;
	if (!GetActiveEffectByClass("ModifyPitch", effect))
		return Plugin_Continue;

	int nPitch;
	if (!effect.state.GetValue("pitch", nPitch))
		return Plugin_Continue;

	pitch += nPitch;
	return Plugin_Changed;
}
