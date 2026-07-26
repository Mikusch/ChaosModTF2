#pragma semicolon 1
#pragma newdecls required

#define MAX_EVENT_NAME_LENGTH	32

static ArrayList g_hEvents;

enum struct EventData
{
	char szName[MAX_EVENT_NAME_LENGTH];
	EventHook fnCallback;
	EventHookMode nMode;
}

void Events_Initialize()
{
	g_hEvents = new ArrayList(sizeof(EventData));

	Events_AddEvent("player_spawn", EventHook_PlayerSpawn);
	Events_AddEvent("post_inventory_application", EventHook_PostInventoryApplication);
	Events_AddEvent("arena_round_start", EventHook_ArenaRoundStart);
	Events_AddEvent("teamplay_round_start", EventHook_TeamplayRoundStart);
	Events_AddEvent("teamplay_round_active", EventHook_TeamplayRoundActive);
}

void Events_Toggle(bool bEnable)
{
	for (int i = 0; i < g_hEvents.Length; i++)
	{
		EventData data;
		if (g_hEvents.GetArray(i, data))
		{
			if (bEnable)
				HookEvent(data.szName, data.fnCallback, data.nMode);
			else
				UnhookEvent(data.szName, data.fnCallback, data.nMode);
		}
	}
}

static void Events_AddEvent(const char[] szName, EventHook fnCallback, EventHookMode nMode = EventHookMode_Post)
{
	Event event = CreateEvent(szName, true);
	if (event)
	{
		event.Cancel();

		EventData data;
		strcopy(data.szName, sizeof(data.szName), szName);
		data.fnCallback = fnCallback;
		data.nMode = nMode;

		g_hEvents.PushArray(data);
	}
	else
	{
		LogError("Failed to create event: %s", szName);
	}
}

static void Events_DispatchClientCallback(int cb, int client)
{
	// Snapshot, a callback may expire or activate an effect while we are dispatching
	ArrayList hActive = g_hActiveEffects.Clone();

	int nLength = hActive.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(hActive.Get(i), effect) || !effect.active)
			continue;

		Function fnCallback = effect.GetCallback(cb);
		if (fnCallback == INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_PushCell(client);
		Call_Finish();
	}

	delete hActive;
}

static void EventHook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	Events_DispatchClientCallback(ChaosCb_OnPlayerSpawn, client);

	RequestFrame(Frame_PlayerSpawnPost, userid);
}

static void Frame_PlayerSpawnPost(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return;

	Events_DispatchClientCallback(ChaosCb_OnPlayerSpawnPost, client);
}

static void EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	Events_DispatchClientCallback(ChaosCb_OnPostInventoryApplication, GetClientOfUserId(event.GetInt("userid")));
}

static void EventHook_ArenaRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Chaos_SetTimers(GetGameTime());
}

static void EventHook_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Chaos_SetTimers(-1.0);

	// Snapshot, a callback may expire or activate an effect while we are dispatching
	ArrayList hActive = g_hActiveEffects.Clone();

	int nLength = hActive.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(hActive.Get(i), effect) || !effect.active)
			continue;

		Function fnCallback = effect.GetCallback(ChaosCb_OnRoundStart);
		if (fnCallback == INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_Finish();
	}

	delete hActive;
}

static void EventHook_TeamplayRoundActive(Event event, const char[] name, bool dontBroadcast)
{
	Chaos_SetTimers(GetGameTime());
}
