#pragma semicolon 1
#pragma newdecls required

enum struct ChaosEffect
{
	// Effect data
	int id;
	char name[64];
	float duration;
	int cooldown;
	bool meta;
	char effect_class[64];
	KeyValues data;
	
	// Runtime data
	bool active;
	float activate_time;
	int cooldown_left;
	
	void Parse(KeyValues kv)
	{
		char section[64];
		if (kv.GetSectionName(section, sizeof(section)) && StringToIntEx(section, this.id))
		{
			kv.GetString("name", this.name, sizeof(this.name));
			this.duration = kv.GetFloat("duration");
			this.cooldown = kv.GetNum("cooldown", sm_chaos_effect_cooldown.IntValue);
			this.meta = kv.GetNum("meta") != 0;
			kv.GetString("effect_class", this.effect_class, sizeof(this.effect_class), "InvalidEffect");
			
			if (kv.JumpToKey("data", false))
			{
				this.data = new KeyValues("data");
				this.data.Import(kv);
				kv.GoBack();
			}
		}
	}
	
	Function GetCallbackFunction(const char[] szKey, Handle hPlugin = null)
	{
		char szFunctionName[64];
		Format(szFunctionName, sizeof(szFunctionName), "%s_%s", this.effect_class, szKey);
		return GetFunctionByName(hPlugin, szFunctionName);
	}
	
	float GetEffectDuration()
	{
		float flDuration = this.duration;
		
		// Check if any active effect wants to modify our duration
		for (int i = 0; i < g_hEffects.Length; i++)
		{
			ChaosEffect effect;
			if (g_hEffects.GetArray(i, effect) && effect.active)
			{
				// Don't modify our own duration
				if (effect.id == this.id)
					continue;
				
				Function fnCallback = effect.GetCallbackFunction("ModifyEffectDuration");
				if (fnCallback != INVALID_FUNCTION)
				{
					Call_StartFunction(null, fnCallback);
					Call_PushArray(effect, sizeof(effect));
					Call_PushFloatRef(flDuration);
					Call_Finish();
				}
			}
		}
		
		return flDuration;
	}
}

void Data_Initialize()
{
	char szFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFilePath, sizeof(szFilePath), "configs/chaos/effects.cfg");
	
	KeyValues kv = new KeyValues("effects");
	if (kv.ImportFromFile(szFilePath))
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				ChaosEffect effect;
				effect.Parse(kv);
				
				if (g_hEffects.FindValue(effect.id) != -1)
				{
					LogError("The effect '%s' has duplicate ID (%d), skipping...", effect.name, LANG_SERVER, effect.id);
					continue;
				}
				
				Function fnCallback = effect.GetCallbackFunction("Initialize");
				if (fnCallback != INVALID_FUNCTION)
				{
					Call_StartFunction(null, fnCallback);
					Call_PushArray(effect, sizeof(effect));
					
					// If Initialize throws, the effect is not added to our list
					if (Call_Finish() != SP_ERROR_NONE)
					{
						continue;
					}
				}
				
				g_hEffects.PushArray(effect);
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
	else
	{
		LogError("Could not read from file '%s'", szFilePath);
	}
	delete kv;
	
	LogMessage("Registered %d effects", g_hEffects.Length);
}
