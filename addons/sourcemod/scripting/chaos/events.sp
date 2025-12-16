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

static void EventHook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;

		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
		{
			Function fnCallback = effect.GetCallbackFunction("OnPlayerSpawn");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_Finish();
			}
		}
	}

	RequestFrame(Frame_PlayerSpawnPost, userid);
}

static void Frame_PlayerSpawnPost(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return;

	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;

		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
		{
			Function fnCallback = effect.GetCallbackFunction("OnPlayerSpawnPost");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_Finish();
			}
		}
	}
}

static void EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
		{
			Function fnCallback = effect.GetCallbackFunction("OnPostInventoryApplication");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_Finish();
			}
		}
	}
}

static void EventHook_ArenaRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	SetChaosTimers(GetGameTime());
}

static void EventHook_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	SetChaosTimers(-1.0);

	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
		{
			Function fnCallback = effect.GetCallbackFunction("OnRoundStart");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}
		}
	}
}

static void EventHook_TeamplayRoundActive(Event event, const char[] name, bool dontBroadcast)
{
	SetChaosTimers(GetGameTime());
}
