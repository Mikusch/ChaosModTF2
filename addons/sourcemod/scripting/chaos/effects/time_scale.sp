#pragma semicolon 1
#pragma newdecls required

static ConVar host_timescale;
static ConVar sv_cheats;

static float g_flOldTimescale;
static float g_flCurrentTimescale;

public bool TimeScale_Initialize(ChaosEffect effect)
{
	host_timescale = FindConVar("host_timescale");
	sv_cheats = FindConVar("sv_cheats");

	return true;
}

public bool TimeScale_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;

	if (IsEffectOfClassActive(effect.effect_class))
		return false;

	float flTimescale = effect.data.GetFloat("timescale", 1.0);

	if (host_timescale.FloatValue == flTimescale)
		return false;

	g_flOldTimescale = host_timescale.FloatValue;
	g_flCurrentTimescale = flTimescale;
	host_timescale.FloatValue = flTimescale;

	host_timescale.AddChangeHook(OnTimescaleChanged);
	sv_cheats.AddChangeHook(OnCheatsChanged);

	AddNormalSoundHook(OnNormalSoundPlayed);
	AddAmbientSoundHook(OnAmbientSoundPlayed);

	ReplicateCheatsToClients("1");

	return true;
}

public void TimeScale_OnEnd(ChaosEffect effect)
{
	host_timescale.RemoveChangeHook(OnTimescaleChanged);
	sv_cheats.RemoveChangeHook(OnCheatsChanged);
	host_timescale.FloatValue = g_flOldTimescale;

	RemoveNormalSoundHook(OnNormalSoundPlayed);
	RemoveAmbientSoundHook(OnAmbientSoundPlayed);

	// Replicate current server value back to clients
	char szValue[512];
	sv_cheats.GetString(szValue, sizeof(szValue));
	ReplicateCheatsToClients(szValue);
}

public void TimeScale_OnClientPutInServer(ChaosEffect effect, int client)
{
	ReplicateCheatsToClient(client, "1");
}

static void OnTimescaleChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	host_timescale.RemoveChangeHook(OnTimescaleChanged);
	host_timescale.FloatValue = g_flCurrentTimescale;
	host_timescale.AddChangeHook(OnTimescaleChanged);

	g_flOldTimescale = StringToFloat(newValue);
}

static void OnCheatsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	// Allow clients to react to the initial change first
	RequestFrame(RequestFrameCallback_ReplicateCheats);
}

public void RequestFrameCallback_ReplicateCheats()
{
	ReplicateCheatsToClients("1");
}

static Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	pitch = RoundToNearest(pitch * g_flCurrentTimescale);
	return Plugin_Changed;
}

static Action OnAmbientSoundPlayed(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
	pitch = RoundToNearest(pitch * g_flCurrentTimescale);
	return Plugin_Changed;
}

static void ReplicateCheatsToClient(int client, const char[] szValue)
{
	if (IsFakeClient(client))
		SetFakeClientConVar(client, "sv_cheats", szValue);
	else
		sv_cheats.ReplicateToClient(client, szValue);
}

static void ReplicateCheatsToClients(const char[] szValue)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		ReplicateCheatsToClient(client, szValue);
	}
}
