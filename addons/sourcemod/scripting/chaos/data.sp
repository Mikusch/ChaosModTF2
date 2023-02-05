#pragma semicolon 1
#pragma newdecls required

enum struct ChaosEffect
{
	// Static data
	char id[64];
	char name[64];
	bool enabled;
	float duration;
	float chance;
	int cooldown;
	bool meta;
	char effect_class[64];
	char script_file[PLATFORM_MAX_PATH];
	char start_sound[PLATFORM_MAX_PATH];
	char end_sound[PLATFORM_MAX_PATH];
	ArrayList incompatible_with;
	KeyValues data;
	
	// Runtime data
	bool active;
	float activate_time;
	int cooldown_left;
	
	void Parse(KeyValues kv)
	{
		if (kv.GetSectionName(this.id, sizeof(this.id)))
		{
			kv.GetString("name", this.name, sizeof(this.name));
			this.enabled = kv.GetNum("enabled", true) != 0;
			this.duration = kv.GetFloat("duration");
			this.cooldown = kv.GetNum("cooldown", sm_chaos_effect_cooldown.IntValue);
			this.meta = kv.GetNum("meta") != 0;
			kv.GetString("effect_class", this.effect_class, sizeof(this.effect_class));
			kv.GetString("script_file", this.script_file, sizeof(this.script_file));
			kv.GetString("start_sound", this.start_sound, sizeof(this.start_sound));
			kv.GetString("end_sound", this.end_sound, sizeof(this.end_sound));
			
			char incompatible_with[512];
			kv.GetString("incompatible_with", incompatible_with, sizeof(incompatible_with));
			if (incompatible_with[0])
			{
				this.incompatible_with = new ArrayList(64);
				
				char buffers[8][64];
				int num = ExplodeString(incompatible_with, ",", buffers, sizeof(buffers), sizeof(buffers[]));
				for (int i = 0; i < num; i++)
				{
					this.incompatible_with.PushString(buffers[i]);
				}
			}
			
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
		if (!this.effect_class[0])
		{
			return INVALID_FUNCTION;
		}
		
		char szFunctionName[64];
		Format(szFunctionName, sizeof(szFunctionName), "%s_%s", this.effect_class, szKey);
		return GetFunctionByName(hPlugin, szFunctionName);
	}
	
	bool GetName(char[] szName, int iMaxLength)
	{
		// This callback only applies to the current effect
		Function fnCallback = this.GetCallbackFunction("ModifyEffectName");
		if (fnCallback != INVALID_FUNCTION)
		{
			Call_StartFunction(null, fnCallback);
			Call_PushArray(this, sizeof(this));
			Call_PushStringEx(szName, iMaxLength, SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(iMaxLength);
			
			bool bReturn;
			if (Call_Finish(bReturn) == SP_ERROR_NONE && bReturn)
			{
				return bReturn;
			}
		}
		
		return strcopy(szName, iMaxLength, this.name) != 0;
	}
	
	float GetDuration()
	{
		float flDuration = this.duration;
		
		// Check if any active effect wants to modify our duration
		for (int i = 0; i < g_hEffects.Length; i++)
		{
			ChaosEffect effect;
			if (g_hEffects.GetArray(i, effect) && effect.active)
			{
				// Don't modify our own duration
				if (StrEqual(effect.id, this.id))
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
	
	bool IsCompatibleWithActiveEffects()
	{
		if (!this.incompatible_with)
			return true;
		
		for (int i = 0; i < g_hEffects.Length; i++)
		{
			ChaosEffect effect;
			if (g_hEffects.GetArray(i, effect) && effect.active)
			{
				if (StrEqual(effect.id, this.id))
					continue;
				
				if (this.incompatible_with.FindString(effect.id) == -1)
					continue;
				
				return false;
			}
		}
		
		return true;
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
				
				if (g_hEffects.FindString(effect.id) != -1)
				{
					LogError("Effect '%s' has duplicate ID '%s', skipping...", effect.name, LANG_SERVER, effect.id);
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
