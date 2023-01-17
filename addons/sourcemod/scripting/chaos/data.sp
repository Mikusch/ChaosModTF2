#pragma semicolon 1
#pragma newdecls required

enum struct ChaosEffect
{
	// Effect data
	int id;
	char name[64];
	float duration;
	bool meta;
	int cooldown;
	char effect_class[64];
	KeyValues data;
	
	// Runtime data
	bool active;
	float activate_time;
	int cooldown_left;
	
	void Parse(KeyValues kv)
	{
		char szSection[64];
		if (kv.GetSectionName(szSection, sizeof(szSection)) && StringToIntEx(szSection, this.id))
		{
			kv.GetString("name", this.name, sizeof(this.name));
			this.duration = kv.GetFloat("duration", 30.0);
			this.meta = kv.GetNum("meta") != 0;
			this.cooldown = kv.GetNum("cooldown", sm_chaos_effect_cooldown.IntValue);
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
				
				Function callback = effect.GetCallbackFunction("ModifyEffectDuration");
				if (callback != INVALID_FUNCTION)
				{
					Call_StartFunction(null, callback);
					Call_PushArray(effect, sizeof(effect));
					Call_PushFloatRef(flDuration);
					Call_Finish();
				}
			}
		}
		
		return flDuration;
	}
}

void ParseConfig()
{
	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/chaos/effects.cfg");
	
	KeyValues kv = new KeyValues("effects");
	if (kv.ImportFromFile(file))
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				ChaosEffect effect;
				effect.Parse(kv);
				
				Function callback = effect.GetCallbackFunction("Initialize");
				if (callback != INVALID_FUNCTION)
				{
					Call_StartFunction(null, callback);
					Call_PushArray(effect, sizeof(effect));
					
					// If Initialize returns false, the effect is not added to our effects list
					bool bReturn;
					if (Call_Finish(bReturn) != SP_ERROR_NONE || !bReturn)
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
		LogError("Could not read from file '%s'", file);
	}
	delete kv;
	
	LogMessage("Registered %d effects", g_hEffects.Length);
}
