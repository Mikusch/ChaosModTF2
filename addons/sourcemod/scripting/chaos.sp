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
#include <tf_econ_data>
#include <cbasenpc>
#include <morecolors>

ConVar sm_chaos_enable;
ConVar sm_chaos_effect_cooldown;
ConVar sm_chaos_effect_interval;
ConVar sm_chaos_meta_effect_interval;
ConVar sm_chaos_meta_effect_chance;
ConVar sm_chaos_force_effect;

bool g_bEnabled;
bool g_bNoChaos;
ArrayList g_hEffects;
Handle g_hTimerBarHudSync;
float g_flLastEffectActivateTime;
float g_flLastMetaEffectActivateTime;
float g_flLastEffectDisplayTime;
float g_flTimerBarDisplayTime;

#include "chaos/data.sp"
#include "chaos/dhooks.sp"
#include "chaos/events.sp"
#include "chaos/sdkcalls.sp"
#include "chaos/shareddefs.sp"
#include "chaos/util.sp"

// Meta effects
#include "chaos/effects/meta/effectduration.sp"
#include "chaos/effects/meta/nochaos.sp"
#include "chaos/effects/meta/reinvokeeffects.sp"
#include "chaos/effects/meta/timerspeed.sp"

// Regular effects
#include "chaos/effects/addcond.sp"
#include "chaos/effects/birds.sp"
#include "chaos/effects/cattoguns.sp"
#include "chaos/effects/decompiled.sp"
#include "chaos/effects/disablerandomdirection.sp"
#include "chaos/effects/disassemblemap.sp"
#include "chaos/effects/earthquake.sp"
#include "chaos/effects/fakeclientcommand.sp"
#include "chaos/effects/fakecrash.sp"
#include "chaos/effects/fling.sp"
#include "chaos/effects/flipviewmodels.sp"
#include "chaos/effects/floorislava.sp"
#include "chaos/effects/forceforward.sp"
#include "chaos/effects/fov.sp"
#include "chaos/effects/giveitem.sp"
#include "chaos/effects/grantorremoveallupgrades.sp"
#include "chaos/effects/invertconvar.sp"
#include "chaos/effects/jumpjump.sp"
#include "chaos/effects/killrandomplayer.sp"
#include "chaos/effects/launchup.sp"
#include "chaos/effects/mannpower.sp"
#include "chaos/effects/modifypitch.sp"
#include "chaos/effects/nothing.sp"
#include "chaos/effects/removehealthandammo.sp"
#include "chaos/effects/removerandomentity.sp"
#include "chaos/effects/screenfade.sp"
#include "chaos/effects/screenoverlay.sp"
#include "chaos/effects/setattribute.sp"
#include "chaos/effects/setconvar.sp"
#include "chaos/effects/setcurrency.sp"
#include "chaos/effects/setcustommodel.sp"
#include "chaos/effects/sethealth.sp"
#include "chaos/effects/setspeed.sp"
#include "chaos/effects/showscoreboard.sp"
#include "chaos/effects/silence.sp"
#include "chaos/effects/slap.sp"
#include "chaos/effects/spawnball.sp"
#include "chaos/effects/teleportermalfunction.sp"
#include "chaos/effects/thriller.sp"
#include "chaos/effects/tiltedcamera.sp"
#include "chaos/effects/truce.sp"
#include "chaos/effects/watermark.sp"
#include "chaos/effects/wheredideverythinggo.sp"

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
	
	sm_chaos_enable = CreateConVar("sm_chaos_enable", "1", "Enable or disable the plugin.");
	sm_chaos_enable.AddChangeHook(ConVarChanged_ChaosEnable);
	
	sm_chaos_effect_cooldown = CreateConVar("sm_chaos_effect_cooldown", "20", "Default cooldown between effects.");
	sm_chaos_effect_interval = CreateConVar("sm_chaos_effect_interval", "45", "Interval between each effect activation.");
	sm_chaos_meta_effect_interval = CreateConVar("sm_chaos_meta_effect_interval", "40", "Interval between each attempted meta effect activation.");
	sm_chaos_meta_effect_chance = CreateConVar("sm_chaos_meta_effect_chance", "0.025", "Chance for a meta effect to be activated every interval.");
	sm_chaos_force_effect = CreateConVar("sm_chaos_force_effect", "", "ID of the effect to force.");
	
	g_hEffects = new ArrayList(sizeof(ChaosEffect));
	g_hTimerBarHudSync = CreateHudSynchronizer();
	
	Events_Initialize();
	Data_Initialize();
	
	GameData hGameData = new GameData("chaos");
	if (hGameData)
	{
		DHooks_Initialize(hGameData);
		SDKCalls_Initialize(hGameData);
		delete hGameData;
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

public void OnMapInit(const char[] mapName)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
		{
			Function fnCallback = effect.GetCallbackFunction("OnMapInit");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushString(mapName);
				Call_Finish();
			}
		}
	}
}

public void OnMapStart()
{
	g_flLastEffectDisplayTime = GetGameTime();
	
	// Initialize VScript system
	SetVariantString("chaos");
	AcceptEntityInput(0, "RunScriptFile");
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
		{
			Function fnCallback = effect.GetCallbackFunction("OnMapStart");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}
			
			// Reset their activation time
			g_hEffects.Set(i, 0.0, ChaosEffect::activate_time);
		}
	}
}

public void OnMapEnd()
{
	ExpireAllActiveEffects(true);
}

public void OnConfigsExecuted()
{
	if (g_bEnabled != sm_chaos_enable.BoolValue)
	{
		TogglePlugin(sm_chaos_enable.BoolValue);
	}
}

public void OnClientPutInServer(int client)
{
	if (!g_bEnabled)
		return;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("OnClientPutInServer");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_Finish();
			}
		}
	}
}

public void OnGameFrame()
{
	if (!g_bEnabled)
		return;
	
	// Show all active effects in HUD
	if (g_flLastEffectDisplayTime && g_flLastEffectDisplayTime + 0.1 <= GetGameTime())
	{
		g_flLastEffectDisplayTime = GetGameTime();
		
		DisplayActiveEffects();
	}
	
	ExpireAllActiveEffects();
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("Update");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}
		}
	}
	
	SetVariantString("Chaos_UpdateEffects");
	AcceptEntityInput(0, "CallScriptFunction");
	
	if (g_bNoChaos || GameRules_GetRoundState() < RoundState_RoundRunning || GameRules_GetRoundState() > RoundState_Stalemate || GameRules_GetProp("m_bInWaitingForPlayers"))
		return;
	
	float flTimerSpeed = sm_chaos_effect_interval.FloatValue;
	
	// Check if a meta effect wants to modify the interval
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("ModifyTimerSpeed");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
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
		
		char szForceId[64];
		sm_chaos_force_effect.GetString(szForceId, sizeof(szForceId));
		
		if (!szForceId[0])
		{
			SelectRandomEffect();
		}
		else
		{
			int nIndex = g_hEffects.FindString(szForceId);
			if (nIndex == -1)
			{
				LogError("Failed to force unknown effect with ID '%s'", szForceId);
			}
			else
			{
				ChaosEffect effect;
				if (g_hEffects.GetArray(nIndex, effect))
				{
					if (!ActivateEffect(effect, true))
					{
						LogError("Failed to force effect '%T'", effect.name, LANG_SERVER);
					}
				}
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
	if (!g_bEnabled)
		return;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("OnEntityCreated");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(entity);
				Call_PushString(classname);
				Call_Finish();
			}
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	if (!g_bEnabled)
		return;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("OnEntityDestroyed");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(entity);
				Call_Finish();
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!g_bEnabled)
		return Plugin_Continue;
	
	Action nReturn = Plugin_Continue;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("OnPlayerRunCmd");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
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
				
				Action nResult;
				if (Call_Finish(nResult) == SP_ERROR_NONE)
				{
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

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (!g_bEnabled)
		return;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("OnConditionAdded");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
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
	if (!g_bEnabled)
		return;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("OnConditionRemoved");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
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
	if (!g_bEnabled)
		return;
	
	SetChaosTimers(0.0);
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int itemDefIndex, Handle &item)
{
	if (!g_bEnabled)
		return Plugin_Continue;
	
	Action nReturn = Plugin_Continue;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("OnGiveNamedItem");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushCell(client);
				Call_PushString(classname);
				Call_PushCell(itemDefIndex);
				Call_PushCellRef(item);
				
				Action nResult;
				if (Call_Finish(nResult) == SP_ERROR_NONE)
				{
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

// --------------------------------------------------------------------------------------------------- //
// Plugin Functions
// --------------------------------------------------------------------------------------------------- //

void TogglePlugin(bool bEnable)
{
	g_bEnabled = bEnable;
	
	DHooks_Toggle(bEnable);
	Events_Toggle(bEnable);
	
	if (bEnable)
	{
		SetChaosTimers(GetGameTime());
		
		AddNormalSoundHook(NormalSHook_OnSoundPlayed);
		AddAmbientSoundHook(AmbientSHook_OnSoundPlayed);
	}
	else
	{
		SetChaosTimers(0.0);
		ExpireAllActiveEffects(true);
		
		RemoveNormalSoundHook(NormalSHook_OnSoundPlayed);
		RemoveAmbientSoundHook(AmbientSHook_OnSoundPlayed);
	}
}

void SelectRandomEffect(bool bMeta = false)
{
	// Sort effects based on their cooldown
	g_hEffects.SortCustom(SortFuncADTArray_SortChaosEffectsByCooldown);
	
	// Go through all effects until we find a valid one 
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.enabled)
		{
			// Filter by meta effects
			if (effect.meta != bMeta)
				continue;
			
			// Skip already activate effects or effects still on cooldown
			if (effect.active || effect.cooldown_left > 0)
				continue;
			
			if (!effect.IsCompatibleWithActiveEffects())
				continue;
			
			if (ActivateEffect(effect))
				return;
		}
	}
	
	LogError("Failed to find valid effect to activate");
}

bool ActivateEffect(ChaosEffect effect, bool bForce = false)
{
	int nIndex = g_hEffects.FindString(effect.id);
	if (nIndex == -1)
	{
		LogError("Failed to activate unknown effect with id '%s'", effect.id);
		return false;
	}
	
	if (effect.active)
	{
		if (bForce)
		{
			ForceExpireEffect(effect);
		}
		else
		{
			ThrowError("Failed to activate effect '%T' because it is already active", effect.name, LANG_SERVER);
		}
	}
	
	Function fnCallback = effect.GetCallbackFunction("OnStart");
	if (fnCallback != INVALID_FUNCTION)
	{
		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		
		// If OnStart returns false, do not start the effect
		bool bReturn;
		if (Call_Finish(bReturn) != SP_ERROR_NONE || !bReturn)
		{
			LogMessage("Skipped effect '%T' because 'OnStart' callback returned false", effect.name, LANG_SERVER);
			return false;
		}
	}
	
	if (effect.script_file[0])
	{
		char str[64];
		Format(str, sizeof(str), "Chaos_StartEffect(\"%s\", %f)", effect.script_file, effect.duration);
		SetVariantString(str);
		AcceptEntityInput(0, "RunScriptCode");
	}
	
	// One-shot effects are never set to active state
	if (effect.duration)
	{
		effect.active = true;
	}
	
	effect.cooldown_left = effect.cooldown;
	effect.current_duration = effect.duration;
	effect.activate_time = GetGameTime();
	
	// Check if any active effect wants to modify the duration
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect other;
		if (g_hEffects.GetArray(i, other) && other.active)
		{
			if (StrEqual(other.id, effect.id))
				continue;
			
			fnCallback = other.GetCallbackFunction("ModifyEffectDuration");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(other, sizeof(other));
				Call_PushFloatRef(effect.current_duration);
				Call_Finish();
			}
		}
	}
	
	g_hEffects.SetArray(nIndex, effect);
	
	// Lower cooldown of all other effects
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect other;
		if (g_hEffects.GetArray(i, other))
		{
			if (StrEqual(other.id, effect.id))
				continue;
			
			if (other.active)
				continue;
			
			// Only meta effects can lower meta cooldowns
			if (other.meta != effect.meta)
				continue;
			
			// Never lower cooldown below 0
			g_hEffects.Set(i, Max(0, other.cooldown_left - 1), ChaosEffect::cooldown_left);
		}
	}
	
	EmitGameSoundToAll("CYOA.NodeActivate");
	
	if (effect.start_sound[0])
	{
		PlayStaticSound(effect.start_sound);
	}
	
	char szName[64];
	if (effect.GetName(szName, sizeof(szName)) && szName[0])
	{
		PrintCenterTextAll("%t", "#Chaos_Effect_Activated", szName);
	}
	
	LogMessage("Successfully activated effect '%T'", effect.name, LANG_SERVER);
	
	return true;
}

void DisplayTimerBar(float flInterval)
{
	SetHudTextParams(-1.0, 0.075, 0.1, 147, 32, 252, 255);
	
	float flEndTime = g_flLastEffectActivateTime + flInterval;
	float flRatio = (GetGameTime() - g_flLastEffectActivateTime) / (flEndTime - g_flLastEffectActivateTime);
	
	int iFilledBlocks = RoundToNearest(flRatio * TIMER_BAR_NUM_BLOCKS);
	int iEmptyBlocks = TIMER_BAR_NUM_BLOCKS - iFilledBlocks;
	
	char szProgressBar[64];
	for (int i = 0; i < iFilledBlocks; i++)
	{
		StrCat(szProgressBar, sizeof(szProgressBar), TIMER_BAR_CHAR_FILLED);
	}
	for (int i = 0; i < iEmptyBlocks; i++)
	{
		StrCat(szProgressBar, sizeof(szProgressBar), TIMER_BAR_CHAR_EMPTY);
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
			if (g_hEffects.GetArray(i, effect))
			{
				if (effect.activate_time == 0.0)
					continue;
				
				char szName[64];
				if (!effect.GetName(szName, sizeof(szName)) || !szName[0])
					continue;
				
				char szLine[128];
				
				// Expiring effects stay on screen while active
				if (effect.active)
				{
					float flEndTime = effect.activate_time + effect.current_duration;
					float flRatio = (GetGameTime() - effect.activate_time) / (flEndTime - effect.activate_time);
					
					int iEmptyBlocks = RoundToNearest(flRatio * EFFECT_BAR_NUM_BLOCKS);
					int iFilledBlocks = EFFECT_BAR_NUM_BLOCKS - iEmptyBlocks;
					
					char szProgressBar[64];
					for (int j = 0; j < iFilledBlocks; j++)
					{
						StrCat(szProgressBar, sizeof(szProgressBar), EFFECT_BAR_CHAR_FILLED);
					}
					for (int j = 0; j < iEmptyBlocks; j++)
					{
						StrCat(szProgressBar, sizeof(szProgressBar), EFFECT_BAR_CHAR_EMPTY);
					}
					
					Format(szLine, sizeof(szLine), "%T %s", szName, client, szProgressBar);
				}
				// One-shot effects stay on screen for 60 seconds
				else if (!effect.duration && GetGameTime() - effect.activate_time <= 60.0)
				{
					Format(szLine, sizeof(szLine), "%T", szName, client);
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

void ExpireAllActiveEffects(bool bForce = false)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			if (effect.activate_time == 0.0)
				continue;
			
			// Check if the effect actually expired
			if (!bForce && effect.activate_time + effect.current_duration > GetGameTime())
				continue;
			
			ForceExpireEffect(effect);
		}
	}
}

void ForceExpireEffect(ChaosEffect effect)
{
	int nIndex = g_hEffects.FindString(effect.id);
	if (nIndex == -1)
	{
		LogError("Failed to expire unknown effect with id '%s'", effect.id);
		return;
	}
	
	g_hEffects.Set(nIndex, false, ChaosEffect::active);
	
	Function fnCallback = effect.GetCallbackFunction("OnEnd");
	if (fnCallback != INVALID_FUNCTION)
	{
		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_Finish();
	}
	
	if (effect.script_file[0])
	{
		char str[64];
		Format(str, sizeof(str), "Chaos_EndEffect(\"%s\")", effect.script_file);
		SetVariantString(str);
		AcceptEntityInput(0, "RunScriptCode");
	}
	
	if (effect.start_sound[0])
	{
		StopStaticSound(effect.start_sound);
	}
	
	if (effect.end_sound[0])
	{
		PlayStaticSound(effect.end_sound);
	}
}

/**
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

/**
 * Returns true if the given key was found in active effects with the given class.
 */
bool FindKeyInActiveEffects(const char[] szEffectClass, const char[] szKey)
{
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && StrEqual(effect.effect_class, szEffectClass) && effect.active && effect.data)
		{
			KeyValues kv = new KeyValues("data");
			kv.Import(effect.data);
			
			// Horribly slow and inefficient, but we'll survive
			if (FindKeyInKeyValues(kv, szKey))
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

void SetChaosTimers(float flTime)
{
	g_flLastEffectActivateTime = flTime;
	g_flLastMetaEffectActivateTime = flTime;
	g_flTimerBarDisplayTime = flTime;
}

static void ConVarChanged_ChaosEnable(ConVar convar, const char[] oldValue, const char[] newValue)
{
	TogglePlugin(convar.BoolValue);
}

static Action NormalSHook_OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	Action nReturn = Plugin_Continue;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("OnNormalSoundPlayed");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
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
				
				Action nResult;
				if (Call_Finish(nResult) == SP_ERROR_NONE)
				{
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

static Action AmbientSHook_OnSoundPlayed(char sample[PLATFORM_MAX_PATH], int& entity, float& volume, int& level, int& pitch, float pos[3], int& flags, float& delay)
{
	Action nReturn = Plugin_Continue;
	
	for (int i = 0; i < g_hEffects.Length; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && effect.active)
		{
			Function fnCallback = effect.GetCallbackFunction("OnAmbientSoundPlayed");
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_PushStringEx(sample, sizeof(sample), SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
				Call_PushCellRef(entity);
				Call_PushCellRef(volume);
				Call_PushCellRef(level);
				Call_PushCellRef(pitch);
				Call_PushArrayEx(pos, sizeof(pos), SM_PARAM_COPYBACK);
				Call_PushCellRef(flags);
				Call_PushFloatRef(delay);
				
				Action nResult;
				if (Call_Finish(nResult) == SP_ERROR_NONE)
				{
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
