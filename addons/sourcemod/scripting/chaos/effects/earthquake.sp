#pragma semicolon 1
#pragma newdecls required

#define EARTHQUAKE_AMPLITUDE 15.0
#define EARTHQUAKE_FREQUENCY 150.0

static ChaosEffect g_hEffect;

public void Earthquake_OnStartPost(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1)
			UTIL_ScreenShake(client, SHAKE_START, EARTHQUAKE_AMPLITUDE, EARTHQUAKE_FREQUENCY, effect.current_duration);

		SDKHook(client, SDKHook_GroundEntChangedPost, OnGroundEntChangedPost);
	}
}

public void Earthquake_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1)
			UTIL_ScreenShake(client, SHAKE_STOP, EARTHQUAKE_AMPLITUDE, EARTHQUAKE_FREQUENCY, effect.current_duration);

		SDKUnhook(client, SDKHook_GroundEntChangedPost, OnGroundEntChangedPost);
	}
}

public void Earthquake_Update(ChaosEffect effect)
{
	// Update cached effect for use in GroundEntChanged hook
	g_hEffect = effect;
}

public void Earthquake_OnClientPutInServer(ChaosEffect effect, int client)
{
	SDKHook(client, SDKHook_GroundEntChangedPost, OnGroundEntChangedPost);
}

static void OnGroundEntChangedPost(int client)
{
	float flDuration = g_hEffect.activate_time + g_hEffect.current_duration - GetGameTime();
	UTIL_ScreenShake(client, GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1 ? SHAKE_START : SHAKE_STOP, EARTHQUAKE_AMPLITUDE, EARTHQUAKE_FREQUENCY, flDuration);
}
