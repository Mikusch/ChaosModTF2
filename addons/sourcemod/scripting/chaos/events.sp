#pragma semicolon 1
#pragma newdecls required

void Events_Initialize()
{
	HookEvent("player_spawn", EventHook_PlayerSpawn);
	HookEvent("post_inventory_application", EventHook_PostInventoryApplication);
	HookEvent("arena_round_start", EventHook_ArenaRoundStart);
	HookEvent("teamplay_round_start", EventHook_TeamplayRoundStart);
	HookEvent("teamplay_round_active", EventHook_TeamplayRoundActive);
}

static void EventHook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
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
}

static void EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
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
	SetChaosTimers(0.0);
}

static void EventHook_TeamplayRoundActive(Event event, const char[] name, bool dontBroadcast)
{
	SetChaosTimers(GetGameTime());
}
