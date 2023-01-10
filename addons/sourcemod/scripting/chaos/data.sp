#pragma semicolon 1
#pragma newdecls required

enum struct ChaosEffect
{
	// Static data
	int id;
	char name[64];
	float duration;
	int cooldown;
	StringMap callbacks;
	
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
			
			if (kv.JumpToKey("callbacks", false))
			{
				this.callbacks = new StringMap();
				if (kv.GotoFirstSubKey(false))
				{
					do
					{
						char key[64], value[64];
						kv.GetSectionName(key, sizeof(key));
						kv.GetString(NULL_STRING, value, sizeof(value));
						this.callbacks.SetString(key, value);
					}
					while (kv.GotoNextKey(false));
					kv.GoBack();
				}
				kv.GoBack();
			}
		}
	}
	
	Function GetCallbackFunction(const char[] key, Handle plugin = null)
	{
		char name[64];
		if (this.callbacks && this.callbacks.GetString(key, name, sizeof(name)))
		{
			Function callback = GetFunctionByName(plugin, name);
			if (callback == INVALID_FUNCTION)
			{
				LogError("Unable to find callback function '%s' for '%s'", name, key);
			}
			
			return callback;
		}
		
		// No callbacks specified on item
		return INVALID_FUNCTION;
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
					Call_Finish();
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
