#pragma semicolon 1
#pragma newdecls required

void DHooks_Initialize(GameData gamedata)
{
	DHooks_CreateDynamicDetour(gamedata, "CTFPlayer::TeamFortress_CalculateMaxSpeed", _, DHookCallback_CalculateMaxSpeed_Post);
}

static void DHooks_CreateDynamicDetour(GameData gamedata, const char[] name, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if (detour)
	{
		if (callbackPre != INVALID_FUNCTION)
			detour.Enable(Hook_Pre, callbackPre);
		
		if (callbackPost != INVALID_FUNCTION)
			detour.Enable(Hook_Post, callbackPost);
	}
	else
	{
		LogError("Failed to create detour setup handle for %s", name);
	}
}

static MRESReturn DHookCallback_CalculateMaxSpeed_Post(int player, DHookReturn hReturn)
{
	// Do not allow changing speed while completely to a halt
	if (hReturn.Value == 1.0)
		return MRES_Ignored;
	
	MRESReturn nReturn = MRES_Ignored;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("CalculateMaxSpeed");
			if (callback != INVALID_FUNCTION)
			{
				float flSpeed = hReturn.Value;
				
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(player);
				Call_PushFloatRef(flSpeed);
				
				MRESReturn nCallbackReturn;
				if (Call_Finish(nCallbackReturn) == SP_ERROR_NONE)
				{
					hReturn.Value = flSpeed;
					
					if (nCallbackReturn > nReturn)
					{
						nReturn = nCallbackReturn;
					}
				}
			}
		}
	}
	
	return nReturn;
}
