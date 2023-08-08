#pragma semicolon 1
#pragma newdecls required

static ArrayList g_hDynamicDetours;

enum struct DetourData
{
	DynamicDetour hDetour;
	DHookCallback fnCallbackPre;
	DHookCallback fnCallbackPost;
}

void DHooks_Initialize(GameData hGameConf)
{
	g_hDynamicDetours = new ArrayList(sizeof(DetourData));
	
	DHooks_AddDynamicDetour(hGameConf, "CTFPlayer::TeamFortress_CalculateMaxSpeed", _, DHookCallback_CalculateMaxSpeed_Post);
	DHooks_AddDynamicDetour(hGameConf, "CTFPlayer::GetMaxHealthForBuffing", _, DHookCallback_GetMaxHealthForBuffing_Post);
}

void DHooks_Toggle(bool bEnable)
{
	for (int i = 0; i < g_hDynamicDetours.Length; i++)
	{
		DetourData data;
		if (g_hDynamicDetours.GetArray(i, data) > 0)
		{
			if (data.fnCallbackPre != INVALID_FUNCTION)
			{
				if (bEnable)
					data.hDetour.Enable(Hook_Pre, data.fnCallbackPre);
				else
					data.hDetour.Disable(Hook_Pre, data.fnCallbackPre);
			}
			
			if (data.fnCallbackPost != INVALID_FUNCTION)
			{
				if (bEnable)
					data.hDetour.Enable(Hook_Post, data.fnCallbackPost);
				else
					data.hDetour.Disable(Hook_Post, data.fnCallbackPost);
			}
		}
	}
}

static void DHooks_AddDynamicDetour(GameData gamedata, const char[] szName, DHookCallback fnCallbackPre = INVALID_FUNCTION, DHookCallback fnCallbackPost = INVALID_FUNCTION)
{
	DynamicDetour hDetour = DynamicDetour.FromConf(gamedata, szName);
	if (hDetour)
	{
		DetourData data;
		data.hDetour = hDetour;
		data.fnCallbackPre = fnCallbackPre;
		data.fnCallbackPost = fnCallbackPost;
		
		g_hDynamicDetours.PushArray(data);
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
