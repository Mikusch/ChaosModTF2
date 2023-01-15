#pragma semicolon 1
#pragma newdecls required

void Events_Initialize()
{
	HookEvent("player_spawn", EventHook_PlayerSpawn);
}

static void EventHook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("OnPlayerSpawn");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_Finish();
			}
		}
	}
}
