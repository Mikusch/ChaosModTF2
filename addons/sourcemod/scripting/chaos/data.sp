#pragma semicolon 1
#pragma newdecls required

#define EFFECT_MAX_CLAIM_LENGTH	96
#define EFFECT_MAX_CLAIMS		16

enum
{
	ChaosCb_Initialize = 0,
	ChaosCb_GetClaims,
	ChaosCb_OnMapStart,
	ChaosCb_OnStart,
	ChaosCb_OnStartPost,
	ChaosCb_OnEnd,
	ChaosCb_Update,
	ChaosCb_OnClientPutInServer,
	ChaosCb_OnPlayerSpawn,
	ChaosCb_OnPlayerSpawnPost,
	ChaosCb_OnPostInventoryApplication,
	ChaosCb_OnRoundStart,
	ChaosCb_OnEntityCreated,
	ChaosCb_OnEntityDestroyed,
	ChaosCb_OnPlayerRunCmd,
	ChaosCb_OnConditionAdded,
	ChaosCb_OnConditionRemoved,
	ChaosCb_ModifyTimerSpeed,
	ChaosCb_ModifyEffectDuration,
	ChaosCb_ModifyEffectName,

	ChaosCb_Count
};

static const char g_szCallbackNames[ChaosCb_Count][] =
{
	"Initialize",
	"GetClaims",
	"OnMapStart",
	"OnStart",
	"OnStartPost",
	"OnEnd",
	"Update",
	"OnClientPutInServer",
	"OnPlayerSpawn",
	"OnPlayerSpawnPost",
	"OnPostInventoryApplication",
	"OnRoundStart",
	"OnEntityCreated",
	"OnEntityDestroyed",
	"OnPlayerRunCmd",
	"OnConditionAdded",
	"OnConditionRemoved",
	"ModifyTimerSpeed",
	"ModifyEffectDuration",
	"ModifyEffectName"
};

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
	ArrayList claims;
	KeyValues data;
	char data_string[2048];
	StringMap state;
	Function callbacks[ChaosCb_Count];

	// Runtime data
	bool active;
	float activate_time;
	float end_time;
	int cooldown_left;
	float current_duration;
	float next_update_time;
	float next_script_update_time;

	void Parse(KeyValues kv)
	{
		if (!kv.GetSectionName(this.id, sizeof(this.id)))
			return;

		kv.GetString("name", this.name, sizeof(this.name));
		this.enabled = kv.GetNum("enabled", true) != 0;
		this.duration = kv.GetFloat("duration");
		this.cooldown = kv.GetNum("cooldown", -1);
		this.meta = kv.GetNum("meta") != 0;
		kv.GetString("effect_class", this.effect_class, sizeof(this.effect_class));
		kv.GetString("script_file", this.script_file, sizeof(this.script_file));
		kv.GetString("data", this.data_string, sizeof(this.data_string));
		kv.GetString("start_sound", this.start_sound, sizeof(this.start_sound));
		kv.GetString("end_sound", this.end_sound, sizeof(this.end_sound));

		// Accept backticks for quotes like RunScriptCode does
		ReplaceString(this.data_string, sizeof(this.data_string), "`", "\"");

		this.claims = ParseClaims(kv);

		if (kv.JumpToKey("data", false))
		{
			if (kv.GotoFirstSubKey(false))
			{
				kv.GoBack();

				this.data = new KeyValues("data");
				this.data.Import(kv);
			}
			kv.GoBack();
		}

		this.state = new StringMap();
	}

	void Close()
	{
		delete this.claims;
		delete this.data;
		delete this.state;
	}

	int ResolveCallbacks()
	{
		int nResolved = 0;

		for (int cb = 0; cb < ChaosCb_Count; cb++)
		{
			this.callbacks[cb] = INVALID_FUNCTION;

			if (!this.effect_class[0])
				continue;

			char szFunctionName[128];
			FormatEx(szFunctionName, sizeof(szFunctionName), "%s_%s", this.effect_class, g_szCallbackNames[cb]);

			this.callbacks[cb] = GetFunctionByName(null, szFunctionName);
			if (this.callbacks[cb] != INVALID_FUNCTION)
				nResolved++;
		}

		return nResolved;
	}

	Function GetCallback(int cb)
	{
		return this.callbacks[cb];
	}

	KeyValues OpenData()
	{
		if (this.data)
			this.data.Rewind();

		return this.data;
	}

	bool GetDisplayName(char[] szName, int iMaxLength, int client = 0)
	{
		// This callback only applies to the current effect
		Function fnCallback = this.GetCallback(ChaosCb_ModifyEffectName);
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
		return TranslationPhraseExists(this.name) ? (FormatEx(szName, iMaxLength, "%T", this.name, client) != 0) : (strcopy(szName, iMaxLength, this.name) != 0);
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

ProgressBarConfig g_stEffectBarConfig;
ProgressBarConfig g_stTimerBarConfig;

static ArrayList ParseClaims(KeyValues kv)
{
	char szValue[EFFECT_MAX_CLAIMS * EFFECT_MAX_CLAIM_LENGTH];
	kv.GetString("claims", szValue, sizeof(szValue));

	if (!szValue[0])
		return null;

	ArrayList hList = new ArrayList(ByteCountToCells(EFFECT_MAX_CLAIM_LENGTH));

	char buffers[EFFECT_MAX_CLAIMS][EFFECT_MAX_CLAIM_LENGTH];
	int num = ExplodeString(szValue, ",", buffers, sizeof(buffers), sizeof(buffers[]));

	for (int i = 0; i < num; i++)
	{
		TrimString(buffers[i]);

		if (buffers[i][0])
			hList.PushString(buffers[i]);
	}

	if (!hList.Length)
	{
		delete hList;
		return null;
	}

	return hList;
}

bool Data_InitializeEffects()
{
	char szFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szFilePath, sizeof(szFilePath), "configs/chaos/effects.cfg");

	StringMap hInitializedClasses = new StringMap();

	KeyValues kv = new KeyValues("effects");
	if (!kv.ImportFromFile(szFilePath))
	{
		delete kv;
		delete hInitializedClasses;

		SetFailState("Could not read from file '%s'", szFilePath);
		return false;
	}

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			ChaosEffect effect;
			effect.Parse(kv);

			if (!effect.id[0])
			{
				LogError("Skipping effect with an empty ID");
				effect.Close();
				continue;
			}

			if (FindEffectIndexById(effect.id) != -1)
			{
				LogError("Effect '%s' has duplicate ID '%s', skipping...", effect.name, effect.id);
				effect.Close();
				continue;
			}

			if (!effect.effect_class[0] && !effect.script_file[0])
			{
				LogError("Effect '%s' declares neither 'effect_class' nor 'script_file', skipping...", effect.id);
				effect.Close();
				continue;
			}

			// Always resolve, script-only effects still need an initialized callback table
			int nResolved = effect.ResolveCallbacks();

			if (effect.effect_class[0] && nResolved == 0)
			{
				LogError("Effect '%s': effect_class '%s' resolves no '%s_<callback>' function - typo? Skipping...", effect.id, effect.effect_class, effect.effect_class);
				effect.Close();
				continue;
			}

			// Only call Initialize once per effect class
			if (effect.effect_class[0] && !hInitializedClasses.ContainsKey(effect.effect_class))
			{
				Function fnCallback = effect.GetCallback(ChaosCb_Initialize);
				if (fnCallback != INVALID_FUNCTION)
				{
					Call_StartFunction(null, fnCallback);
					Call_PushArray(effect, sizeof(effect));

					// If Initialize throws or returns false, effects using this class are not added
					bool bReturn;
					if (Call_Finish(bReturn) != SP_ERROR_NONE || !bReturn)
					{
						LogError("Failed to initialize effect class '%s', its effects will be unavailable", effect.effect_class);
						hInitializedClasses.SetValue(effect.effect_class, false);

						effect.Close();
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
				{
					effect.Close();
					continue;
				}
			}

			Claims_Resolve(effect);

			int nIndex = g_hEffects.PushArray(effect);
			g_hEffectIndexById.SetValue(effect.id, nIndex);
		}
		while (kv.GotoNextKey(false));
		kv.GoBack();
	}
	kv.GoBack();

	LogMessage("Registered %d effects", g_hEffects.Length);

	delete kv;
	delete hInitializedClasses;
	return true;
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
