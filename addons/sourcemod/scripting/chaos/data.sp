#pragma semicolon 1
#pragma newdecls required

#define EFFECT_MAX_TAG_LENGTH	64
#define EFFECT_MAX_TAGS			8

enum struct ChaosEffect
{
	// Static data (read-only)
	char id[64];
	char name[64];
	bool enabled;
	float duration;
	int cooldown;
	bool meta;
	char effect_class[64];
	char script_file[PLATFORM_MAX_PATH];
	char start_sound[PLATFORM_MAX_PATH];
	char end_sound[PLATFORM_MAX_PATH];
	ArrayList tags;
	KeyValues data;
	char data_string[2048];
	
	// Runtime data
	bool active;
	float activate_time;
	int cooldown_left;
	float current_duration;
	float next_update_time;
	float next_script_update_time;
	
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
			kv.GetString("data", this.data_string, sizeof(this.data_string));
			kv.GetString("start_sound", this.start_sound, sizeof(this.start_sound));
			kv.GetString("end_sound", this.end_sound, sizeof(this.end_sound));
			
			char tags[EFFECT_MAX_TAG_LENGTH * EFFECT_MAX_TAGS];
			kv.GetString("tags", tags, sizeof(tags));
			if (tags[0])
			{
				this.tags = new ArrayList(ByteCountToCells(EFFECT_MAX_TAG_LENGTH));
				
				char buffers[EFFECT_MAX_TAGS][EFFECT_MAX_TAG_LENGTH];
				int num = ExplodeString(tags, ",", buffers, sizeof(buffers), sizeof(buffers[]));
				for (int i = 0; i < num; i++)
				{
					this.tags.PushString(buffers[i]);
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
			return INVALID_FUNCTION;
		
		char szFunctionName[64];
		Format(szFunctionName, sizeof(szFunctionName), "%s_%s", this.effect_class, szKey);
		return GetFunctionByName(hPlugin, szFunctionName);
	}
	
	bool GetDisplayName(char[] szName, int iMaxLength, int client = 0)
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
				if (TranslationPhraseExists(szName))
					Format(szName, iMaxLength, "%T", szName, client);

				return true;
			}
		}
		
		// Attempt to translate, or return the phrase as-is if it doesn't exist in translations
		return TranslationPhraseExists(this.name) ? Format(szName, iMaxLength, "%T", this.name, client) : strcopy(szName, iMaxLength, this.name);
	}
	
	bool IsCompatibleWithActiveEffects()
	{
		if (!this.tags)
			return true;
		
		int nLength = g_hEffects.Length;
		for (int i = 0; i < nLength; i++)
		{
			if (!g_hEffects.Get(i, ChaosEffect::active))
				continue;
			
			ChaosEffect effect;
			if (g_hEffects.GetArray(i, effect))
			{
				if (StrEqual(effect.id, this.id))
					continue;
				
				if (!effect.tags)
					continue;
				
				for (int j = 0; j < effect.tags.Length; j++)
				{
					char tag[EFFECT_MAX_TAG_LENGTH];
					if (effect.tags.GetString(j, tag, sizeof(tag)) && this.tags.FindString(tag) != -1)
						return false;
				}
			}
		}
		
		return true;
	}
}

enum struct ProgressBarConfig
{
	int num_blocks;
	char filled[64];
	char empty[64];
	int color[4];
	float x;
	float y;
	
	void Parse(KeyValues kv)
	{
		this.num_blocks = kv.GetNum("num_blocks");
		kv.GetString("empty", this.empty, sizeof(this.empty));
		kv.GetString("filled", this.filled, sizeof(this.filled));
		kv.GetColor4("color", this.color);
		this.x = kv.GetFloat("x", -1.0);
		this.y = kv.GetFloat("y", -1.0);
	}
}

bool Data_InitializeEffects()
{
	char szFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFilePath, sizeof(szFilePath), "configs/chaos/effects.cfg");

	bool bSuccess = true;
	StringMap hInitializedClasses = new StringMap();

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
					LogError("Effect '%T' has duplicate ID '%s', skipping...", effect.name, LANG_SERVER, effect.id);
					continue;
				}

				// Only call Initialize once per effect class
				if (effect.effect_class[0] && !hInitializedClasses.ContainsKey(effect.effect_class))
				{
					Function fnCallback = effect.GetCallbackFunction("Initialize");
					if (fnCallback != INVALID_FUNCTION)
					{
						Call_StartFunction(null, fnCallback);
						Call_PushArray(effect, sizeof(effect));

						// If Initialize throws or returns false, effects using this class are not added
						bool bReturn;
						if (Call_Finish(bReturn) != SP_ERROR_NONE || !bReturn)
						{
							LogMessage("Failed to initialize effect class '%s'", effect.effect_class);
							hInitializedClasses.SetValue(effect.effect_class, false);
							continue;
						}
					}

					hInitializedClasses.SetValue(effect.effect_class, true);
				}
				else if (effect.effect_class[0])
				{
					// Check if this effect class failed to initialize previously
					bool bInitialized;
					if (hInitializedClasses.GetValue(effect.effect_class, bInitialized) && !bInitialized)
						continue;
				}

				g_hEffects.PushArray(effect);
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();

		LogMessage("Registered %d effects", g_hEffects.Length);
	}
	else
	{
		SetFailState("Could not read from file '%s'", szFilePath);
		bSuccess = false;
	}

	delete hInitializedClasses;
	return bSuccess;
}

void Data_Initialize()
{
	char szFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFilePath, sizeof(szFilePath), "configs/chaos/visuals.cfg");
	
	KeyValues kv = new KeyValues("visuals");
	if (kv.ImportFromFile(szFilePath))
	{
		if (kv.JumpToKey("timer_bar"))
		{
			g_stTimerBarConfig.Parse(kv);
		}
		kv.GoBack();
		
		if (kv.JumpToKey("effect_bar"))
		{
			g_stEffectBarConfig.Parse(kv);
		}
		kv.GoBack();
	}
	else
	{
		SetFailState("Could not read from file '%s'", szFilePath);
	}
	delete kv;
}
