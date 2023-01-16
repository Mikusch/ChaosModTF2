#pragma semicolon 1
#pragma newdecls required

enum struct ChaosEffect
{
	// Effect data
	int id;
	char name[64];
	float duration;
	int cooldown;
	char effect_class[64];
	KeyValues data;
	
	// Runtime data
	bool active;
	Handle timer;
	float activate_time;
	int cooldown_left;
	
	void Parse(KeyValues kv)
	{
		char section[64];
		if (kv.GetSectionName(section, sizeof(section)) && StringToIntEx(section, this.id))
		{
			kv.GetString("name", this.name, sizeof(this.name));
			this.duration = kv.GetFloat("duration", 30.0);
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
	
	Function GetCallbackFunction(const char[] key, Handle plugin = null)
	{
		char name[64];
		Format(name, sizeof(name), "%s_%s", this.effect_class, key);
		return GetFunctionByName(plugin, name);
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
				
				g_effects.PushArray(effect);
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
}
