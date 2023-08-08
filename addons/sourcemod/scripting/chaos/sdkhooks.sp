#pragma semicolon 1
#pragma newdecls required

void SDKHooks_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnClientTraceAttack);
}

void SDKHooks_OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_TraceAttack, OnClientTraceAttack);
}

static Action OnClientTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	Action nReturn = Plugin_Continue;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("TraceAttack");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(victim);
				Call_PushCellRef(attacker);
				Call_PushCellRef(inflictor);
				Call_PushFloatRef(damage);
				Call_PushCellRef(damagetype);
				Call_PushCellRef(ammotype);
				Call_PushCell(hitbox);
				Call_PushCell(hitgroup);
				
				Action nResult;
				if (Call_Finish(nResult) == SP_ERROR_NONE)
				{
					if (nResult > nReturn)
					{
						nReturn = nResult;
					}
				}
			}
		}
	}
	
	return nReturn;
}
