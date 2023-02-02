#pragma semicolon 1
#pragma newdecls required

void DHooks_Initialize(GameData hGameData)
{
	DHooks_CreateDynamicDetour(hGameData, "CTFPlayer::TeamFortress_CalculateMaxSpeed", _, DHookCallback_CalculateMaxSpeed_Post);
	DHooks_CreateDynamicDetour(hGameData, "CTFPlayer::GetMaxHealthForBuffing", _, DHookCallback_GetMaxHealthForBuffing_Post);
}

static void DHooks_CreateDynamicDetour(GameData hGameData, const char[] szName, DHookCallback fnCallbackPre = INVALID_FUNCTION, DHookCallback fnCallbackPost = INVALID_FUNCTION)
{
	DynamicDetour hDetour = DynamicDetour.FromConf(hGameData, szName);
	if (hDetour)
	{
		if (fnCallbackPre != INVALID_FUNCTION)
		{
			hDetour.Enable(Hook_Pre, fnCallbackPre);
		}
		
		if (fnCallbackPost != INVALID_FUNCTION)
		{
			hDetour.Enable(Hook_Post, fnCallbackPost);
		}
	}
	else
	{
		LogError("Failed to create detour setup handle: %s", szName);
	}
}

static MRESReturn DHookCallback_CalculateMaxSpeed_Post(int player, DHookReturn hReturn, DHookParam hParam)
{
	// Do not allow changing speed while the game wants to stop us
	if (hReturn.Value == 1.0)
		return MRES_Ignored;
	
	MRESReturn nReturn = MRES_Ignored;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("CalculateMaxSpeed");
			if (fnCallback != INVALID_FUNCTION)
			{
				float flSpeed = hReturn.Value;
				
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(player);
				Call_PushFloatRef(flSpeed);
				
				MRESReturn nResult;
				if (Call_Finish(nResult) == SP_ERROR_NONE)
				{
					hReturn.Value = flSpeed;
					
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

static MRESReturn DHookCallback_GetMaxHealthForBuffing_Post(int player, DHookReturn hReturn)
{
	MRESReturn nReturn = MRES_Ignored;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("GetMaxHealthForBuffing");
			if (fnCallback != INVALID_FUNCTION)
			{
				int iHealth = hReturn.Value;
				
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(player);
				Call_PushCellRef(iHealth);
				
				MRESReturn nResult;
				if (Call_Finish(nResult) == SP_ERROR_NONE)
				{
					hReturn.Value = iHealth;
					
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
