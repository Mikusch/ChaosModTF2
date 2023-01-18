#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <tf2attributes>
#include <tf2_stocks>
#include <tf2items>
#include <tf2utils>
#include <cbasenpc>
#include <morecolors>

ArrayList g_hEffects;
Handle g_hTimerBarHudSync;
float g_flLastEffectActivateTime;
float g_flLastMetaEffectActivateTime;
float g_flLastEffectDisplayTime;
float g_flTimerBarDisplayTime;
bool g_bNoChaos;

ConVar sm_chaos_effect_cooldown;
ConVar sm_chaos_effect_interval;
ConVar sm_chaos_meta_effect_interval;
ConVar sm_chaos_meta_effect_chance;
ConVar sm_chaos_force_effect;

#include "chaos/data.sp"
#include "chaos/dhooks.sp"
#include "chaos/events.sp"
#include "chaos/sdkcalls.sp"
#include "chaos/shareddefs.sp"
#include "chaos/util.sp"

// Meta effects
#include "chaos/effects/meta/effect_effectduration.sp"
#include "chaos/effects/meta/effect_nochaos.sp"
#include "chaos/effects/meta/effect_timerspeed.sp"

// Regular effects
#include "chaos/effects/effect_addcond.sp"
#include "chaos/effects/effect_empty.sp"
#include "chaos/effects/effect_eternalscreams.sp"
#include "chaos/effects/effect_extremefog.sp"
#include "chaos/effects/effect_fakeclientcommand.sp"
#include "chaos/effects/effect_fov.sp"
#include "chaos/effects/effect_hidehud.sp"
#include "chaos/effects/effect_invertconvar.sp"
#include "chaos/effects/effect_killrandomplayer.sp"
#include "chaos/effects/effect_mannpower.sp"
#include "chaos/effects/effect_noclip.sp"
#include "chaos/effects/effect_randomizeskybox.sp"
#include "chaos/effects/effect_removehealthandammo.sp"
#include "chaos/effects/effect_removerandomentity.sp"
#include "chaos/effects/effect_removewearables.sp"
#include "chaos/effects/effect_respawnalldead.sp"
#include "chaos/effects/effect_screenoverlay.sp"
#include "chaos/effects/effect_setattribute.sp"
#include "chaos/effects/effect_setconvar.sp"
#include "chaos/effects/effect_setcustommodel.sp"
#include "chaos/effects/effect_sethealth.sp"
#include "chaos/effects/effect_setspeed.sp"
#include "chaos/effects/effect_showscoreboard.sp"
#include "chaos/effects/effect_shuffleclasses.sp"
#include "chaos/effects/effect_silence.sp"
#include "chaos/effects/effect_slowmotion.sp"
#include "chaos/effects/effect_teleportermalfunction.sp"
#include "chaos/effects/effect_thirdperson.sp"
#include "chaos/effects/effect_thriller.sp"
#include "chaos/effects/effect_truce.sp"
#include "chaos/effects/effect_watermark.sp"
#include "chaos/effects/effect_wheredideverythinggo.sp"

public Plugin myinfo =
{
	name = "[TF2] Chaos Mod",
	author = "Mikusch",
	description = "Chaos Mod for Team Fortress 2, heavily inspired by Chaos Mod V.",
	version = "1.0.0",
	url = "https://github.com/Mikusch/ChaosModTF2"
}

// --------------------------------------------------------------------------------------------------- //
// Public Forwards
// --------------------------------------------------------------------------------------------------- //

public void OnPluginStart()
{
	LoadTranslations("chaos.phrases");
	
	g_hEffects = new ArrayList(sizeof(ChaosEffect));
	g_hTimerBarHudSync = CreateHudSynchronizer();
	
	sm_chaos_effect_cooldown = CreateConVar("sm_chaos_effect_cooldown", "8", "Default cooldown between effects.");
	sm_chaos_effect_interval = CreateConVar("sm_chaos_effect_interval", "45", "Interval between each effect activation.");
	sm_chaos_meta_effect_interval = CreateConVar("sm_chaos_meta_effect_interval", "40", "Interval between each attempted meta effect activation.");
	sm_chaos_meta_effect_chance = CreateConVar("sm_chaos_meta_effect_chance", "0.01", "Chance for a meta effect to be activated every interval.");
	sm_chaos_force_effect = CreateConVar("sm_chaos_force_effect", "-1", "ID of the effect to force.");
	
	Events_Initialize();
	Data_Initialize();
	
	AddNormalSoundHook(NormalSHook_OnSoundPlayed);
	
	GameData gamedata = new GameData("chaos");
	if (gamedata)
	{
		DHooks_Initialize(gamedata);
		SDKCalls_Initialize(gamedata);
		delete gamedata;
	}
	else
	{
		LogError("Failed to find chaos gamedata");
	}
}

public void OnPluginEnd()
{
	ExpireAllActiveEffects(true);
}

public void OnMapStart()
{
	SetTimers(GetGameTime());
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
		{
			Function callback = effect.GetCallbackFunction("OnMapStart");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}
			
			g_hEffects.Set(i, 0.0, ChaosEffect::activate_time);
		}
	}
}

public void OnMapEnd()
{
	ExpireAllActiveEffects(true);
}

public void OnClientPutInServer(int client)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("OnClientPutInServer");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_Finish();
			}
		}
	}
}

public void OnGameFrame()
{
	// Show all active effects in HUD
	if (g_flLastEffectDisplayTime && g_flLastEffectDisplayTime + 0.1 <= GetGameTime())
	{
		g_flLastEffectDisplayTime = GetGameTime();
		
		DisplayActiveEffects();
	}
	
	ExpireAllActiveEffects();
	
	if (g_bNoChaos || GameRules_GetRoundState() < RoundState_Preround || GameRules_GetProp("m_bInWaitingForPlayers"))
		return;
	
	// Execute OnGameFrame callback
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("OnGameFrame");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}
		}
	}
	
	float flTimerSpeed = sm_chaos_effect_interval.FloatValue;
	
	// Check if a meta effect wants to modify the interval
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("ModifyTimerSpeed");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushFloatRef(flTimerSpeed);
				Call_Finish();
			}
		}
	}
	
	// Show interval progress bar
	if (g_flTimerBarDisplayTime && g_flTimerBarDisplayTime + 0.1 <= GetGameTime())
	{
		g_flTimerBarDisplayTime = GetGameTime();
		
		DisplayTimerBar(flTimerSpeed);
	}
	
	// Activate a new effect
	if (g_flLastEffectActivateTime && g_flLastEffectActivateTime + flTimerSpeed <= GetGameTime())
	{
		g_flLastEffectActivateTime = GetGameTime();
		
		int iForceId = sm_chaos_force_effect.IntValue;
		if (iForceId == INVALID_EFFECT_ID)
		{
			SelectRandomEffect();
		}
		else
		{
			int index = g_hEffects.FindValue(iForceId, ChaosEffect::id);
			if (index == -1)
			{
				LogError("Failed to force unknown effect '%d'", iForceId);
				return;
			}
			
			ChaosEffect effect;
			if (g_hEffects.GetArray(index, effect))
			{
				StartEffect(effect, true);
			}
		}
	}
	
	// Attempt to activate a new meta effect
	if (g_flLastMetaEffectActivateTime && g_flLastMetaEffectActivateTime + sm_chaos_meta_effect_interval.FloatValue <= GetGameTime())
	{
		g_flLastMetaEffectActivateTime = GetGameTime();
		
		// Meta effects randomly activate
		if (GetRandomFloat() <= sm_chaos_meta_effect_chance.FloatValue)
		{
			SelectRandomEffect(true);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("OnEntityCreated");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(entity);
				Call_PushString(classname);
				Call_Finish();
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	Action action = Plugin_Continue;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("OnPlayerRunCmd");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_PushCellRef(buttons);
				Call_PushCellRef(impulse);
				Call_PushArrayEx(vel, sizeof(vel), SM_PARAM_COPYBACK);
				Call_PushArrayEx(angles, sizeof(angles), SM_PARAM_COPYBACK);
				Call_PushCellRef(weapon);
				Call_PushCellRef(subtype);
				Call_PushCellRef(cmdnum);
				Call_PushCellRef(tickcount);
				Call_PushCellRef(seed);
				Call_PushArrayEx(mouse, sizeof(mouse), SM_PARAM_COPYBACK);
				
				Action ret;
				if (Call_Finish(ret) == SP_ERROR_NONE)
				{
					if (ret > action)
					{
						action = ret;
					}
				}
			}
		}
	}
	
	return action;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("OnConditionAdded");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_PushCell(condition);
				Call_Finish();
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("OnConditionRemoved");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_PushCell(condition);
				Call_Finish();
			}
		}
	}
}

public void TF2_OnWaitingForPlayersStart()
{
	SetTimers(0.0);
}

public void TF2_OnWaitingForPlayersEnd()
{
	SetTimers(GetGameTime());
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int itemDefIndex, Handle &item)
{
	Action action = Plugin_Continue;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("OnGiveNamedItem");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_PushString(classname);
				Call_PushCell(itemDefIndex);
				Call_PushCellRef(item);
				
				Action ret;
				if (Call_Finish(ret) == SP_ERROR_NONE)
				{
					if (ret > action)
					{
						action = ret;
					}
				}
			}
		}
	}
	
	return action;
}

// --------------------------------------------------------------------------------------------------- //
// Plugin Functions
// --------------------------------------------------------------------------------------------------- //

void SelectRandomEffect(bool bMeta = false)
{
	// Sort effects based on their cooldown
	g_hEffects.SortCustom(SortFuncADTArray_SortChaosEffectsByCooldown);
	
	// Go through all effects until we find a valid one 
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
		{
			// Filter by meta effects
			if (effect.meta != bMeta)
				continue;
			
			// Skip already activate effects or effects still on cooldown (meta effects have no cooldowns)
			if (effect.active || (!effect.meta && effect.cooldown_left > 0))
				continue;
			
			if (StartEffect(effect))
				break;
		}
	}
}

bool StartEffect(ChaosEffect effect, bool bForce = false)
{
	int index = g_hEffects.FindValue(effect.id, ChaosEffect::id);
	if (index == -1)
	{
		LogError("Failed to start unknown effect with id '%d'", effect.id);
		return false;
	}
	
	// Run OnStart callback
	Function callback = effect.GetCallbackFunction("OnStart");
	if (callback != INVALID_FUNCTION)
	{
		Call_StartFunction(null, callback);
		Call_PushArray(effect, sizeof(effect));
		
		// If OnStart returns false, do not start the effect
		bool bReturn;
		if (Call_Finish(bReturn) != SP_ERROR_NONE || !bReturn)
		{
			if (bForce)
			{
				// If force failed, try expiring other effects of the same class
				ExpireActiveEffectsOfClass(effect.effect_class, true);
				
				// Re-run OnStart callback
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				if (Call_Finish(bReturn) != SP_ERROR_NONE || !bReturn)
				{
					ThrowError("Failed to force-enable effect '%T'", effect.name, LANG_SERVER);
					return false;
				}
			}
			else
			{
				LogMessage("Skipped effect '%T' because 'OnStart' callback returned false.", effect.name, LANG_SERVER);
				return false;
			}
		}
	}
	
	LogMessage("Successfully activated effect '%T'.", effect.name, LANG_SERVER);
	EmitGameSoundToAll("CYOA.NodeActivate");
	CPrintToChatAll("%s %t", PLUGIN_TAG, "#Chaos_Effect_Activated", effect.name);
	
	// One-shot effects are never set to active state
	if (effect.duration)
	{
		effect.active = true;
	}
	
	effect.cooldown_left = effect.cooldown;
	effect.activate_time = GetGameTime();
	
	g_hEffects.SetArray(index, effect);
	
	// Lower cooldown of all other effects
	for (int j = 0; j < g_hEffects.Length; j++)
	{
		if (g_hEffects.Get(j, ChaosEffect::id) == effect.id)
			continue;
		
		// Meta effects have no cooldowns
		if (effect.meta)
			continue;
		
		// Never lower cooldown below 0
		int cooldown = Max(0, g_hEffects.Get(j, ChaosEffect::cooldown_left) - 1);
		g_hEffects.Set(j, cooldown, ChaosEffect::cooldown_left);
	}
	
	return true;
}

void DisplayTimerBar(float flInterval)
{
	SetHudTextParams(-1.0, 0.075, 0.1, 147, 32, 252, 255);
	
	float flEndTime = g_flLastEffectActivateTime + flInterval;
	float flRatio = (GetGameTime() - g_flLastEffectActivateTime) / (flEndTime - g_flLastEffectActivateTime);
	
	char szProgressBar[64];
	for (int i = 0; i < 100; i += 5)
	{
		if (i == 0)
			continue;
		
		if (flRatio * 100 >= i)
		{
			Format(szProgressBar, sizeof(szProgressBar), "█%s", szProgressBar);
		}
		else
		{
			Format(szProgressBar, sizeof(szProgressBar), "%s▒", szProgressBar);
		}
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		ShowSyncHudText(client, g_hTimerBarHudSync, szProgressBar);
	}
}

void DisplayActiveEffects()
{
	// Sort effects based on their cooldown
	g_hEffects.SortCustom(SortFuncADTArray_SortChaosEffectsByActivationTime);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		char szMessage[MAX_USER_MSG_DATA - 1];
		
		// Go through all effects until we find a valid one 
		for (int i = 0; i < g_hEffects.Length; i++)
		{
			ChaosEffect effect;
			if (g_hEffects.GetArray(i, effect) && effect.activate_time)
			{
				char szLine[128];
				
				// Expiring effects stay on screen while active
				if (effect.active)
				{
					float flEndTime = effect.activate_time + effect.GetEffectDuration();
					float flRatio = (GetGameTime() - effect.activate_time) / (flEndTime - effect.activate_time);
					
					char szProgressBar[64];
					for (int j = 10; j < 100; j += 10)
					{
						if (i == 0)
							continue;
						
						if (flRatio * 100 >= j)
						{
							Format(szProgressBar, sizeof(szProgressBar), "%s▒", szProgressBar);
						}
						else
						{
							Format(szProgressBar, sizeof(szProgressBar), "█%s", szProgressBar);
						}
					}
					
					Format(szLine, sizeof(szLine), "%T %s", effect.name, client, szProgressBar);
				}
				// One-shot effects stay on screen for 60 seconds
				else if (effect.duration == 0 && GetGameTime() - effect.activate_time <= 60.0)
				{
					Format(szLine, sizeof(szLine), "%T", effect.name, client);
				}
				
				// -2 to include null terminators
				if (szLine[0] && strlen(szMessage) + strlen(szLine) < MAX_USER_MSG_DATA - 2)
				{
					Format(szMessage, sizeof(szMessage), "%s\n%s", szMessage, szLine);
				}
			}
		}
		
		PrintKeyHintText(client, szMessage);
	}
}

void ExpireActiveEffectsOfClass(const char[] szEffectClass, bool bForce = false)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && StrEqual(effect.effect_class, szEffectClass) && effect.active)
		{
			// Check if the effect actually expired
			if (!bForce && effect.activate_time + effect.GetEffectDuration() > GetGameTime())
				continue;
			
			Function callback = effect.GetCallbackFunction("OnEnd");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}
			
			effect.active = false;
			g_hEffects.SetArray(i, effect);
		}
	}
}

void ExpireAllActiveEffects(bool bForce = false)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			// Check if the effect actually expired
			if (!bForce && effect.activate_time + effect.GetEffectDuration() > GetGameTime())
				continue;
			
			Function callback = effect.GetCallbackFunction("OnEnd");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}
			
			effect.active = false;
			g_hEffects.SetArray(i, effect);
		}
	}
}

/*
 * Returns true if the given effect class is currently active.
 */
bool IsEffectOfClassActive(const char[] szEffectClass)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && StrEqual(szEffectClass, effect.effect_class) && effect.active)
		{
			return true;
		}
	}
	
	return false;
}

/*
 * Returns true if the given key value pair was found in active effects with the given class.
 */
bool FindKeyValuePairInActiveEffects(const char[] szEffectClass, const char[] szKey, const char[] szValue)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && StrEqual(effect.effect_class, szEffectClass) && effect.active && effect.data)
		{
			KeyValues kv = new KeyValues("data");
			kv.Import(effect.data);
			
			// Horribly slow and inefficient, but we'll survive
			if (FindKeyValuePairInKeyValues(kv, szKey, szValue))
			{
				delete kv;
				return true;
			}
			
			delete kv;
		}
	}
	
	return false;
}

/**
 * Returns true if the given effect is already active, but only if the given key was found in its 'data' section.
 * If you already have the key, it is significantly faster to call 'FindKeyValuePairInActiveEffects' directly.
 */
bool IsEffectWithKeyAlreadyActive(ChaosEffect effect, const char[] szKey)
{
	KeyValues kv = new KeyValues("data");
	kv.Import(effect.data);
	
	// Grab the value, then check if we can find it in active effects
	char szValue[64];
	if (GetValueForKeyInKeyValues(kv, szKey, szValue, sizeof(szValue)) && FindKeyValuePairInActiveEffects(effect.effect_class, szKey, szValue))
	{
		delete kv;
		return true;
	}
	
	return false;
}

static void SetTimers(float flTime)
{
	g_flLastEffectActivateTime = flTime;
	g_flLastMetaEffectActivateTime = flTime;
	g_flLastEffectDisplayTime = flTime;
	g_flTimerBarDisplayTime = flTime;
}

static Action NormalSHook_OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	Action action = Plugin_Continue;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("OnSoundPlayed");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushArrayEx(clients, sizeof(clients), SM_PARAM_COPYBACK);
				Call_PushCellRef(numClients);
				Call_PushStringEx(sample, sizeof(sample), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCellRef(entity);
				Call_PushCellRef(channel);
				Call_PushCellRef(volume);
				Call_PushCellRef(level);
				Call_PushCellRef(pitch);
				Call_PushCellRef(flags);
				Call_PushStringEx(soundEntry, sizeof(soundEntry), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCellRef(seed);
				
				Action ret;
				if (Call_Finish(ret) == SP_ERROR_NONE)
				{
					if (ret > action)
					{
						action = ret;
					}
				}
			}
		}
	}
	
	return action;
}
