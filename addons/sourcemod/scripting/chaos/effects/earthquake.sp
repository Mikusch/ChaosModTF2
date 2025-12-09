#pragma semicolon 1
#pragma newdecls required

enum ShakeCommand_t
{
	SHAKE_START = 0,		// Starts the screen shake for all players within the radius.
	SHAKE_STOP,				// Stops the screen shake for all players within the radius.
	SHAKE_AMPLITUDE,		// Modifies the amplitude of an active screen shake for all players within the radius.
	SHAKE_FREQUENCY,		// Modifies the frequency of an active screen shake for all players within the radius.
	SHAKE_START_RUMBLEONLY,	// Starts a shake effect that only rumbles the controller, no screen effect.
	SHAKE_START_NORUMBLE,	// Starts a shake that does NOT rumble the controller.
};

static ChaosEffect g_hEffect;

public void Earthquake_OnStartPost(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1)
			Shake(client, SHAKE_START, effect.current_duration);
		
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
			Shake(client, SHAKE_STOP, effect.current_duration);
		
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
	Shake(client, GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1 ? SHAKE_START : SHAKE_STOP, flDuration);
}

static void Shake(int client, ShakeCommand_t eCommand, float flDuration)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Shake", client));
		bf.WriteByte(view_as<int>(eCommand));	// shake command (SHAKE_START, STOP, FREQUENCY, AMPLITUDE)
		bf.WriteFloat(15.0);					// shake magnitude/amplitude
		bf.WriteFloat(150.0);					// shake noise frequency
		bf.WriteFloat(flDuration);				// shake lasts this long
	EndMessage();
}
