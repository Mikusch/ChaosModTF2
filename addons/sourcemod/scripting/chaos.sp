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
#include <vscript>
#include <morecolors>

#define PLUGIN_VERSION	"2.0.0"

ConVar sm_chaos_enabled;
ConVar sm_chaos_effect_cooldown;
ConVar sm_chaos_effect_interval;
ConVar sm_chaos_meta_effect_interval;
ConVar sm_chaos_meta_effect_chance;
ConVar sm_chaos_effect_update_interval;

bool g_bEnabled;
bool g_bPaused;
ArrayList g_hEffects;
Handle g_hTimerBarHudSync;
float g_flTimeElapsed;
float g_flMetaTimeElapsed;
float g_flLastEffectDisplayTime;
float g_flTimerBarDisplayTime;
char g_szForceEffectId[64];

ProgressBarConfig g_stEffectBarConfig;
ProgressBarConfig g_stTimerBarConfig;

#include "chaos/data.sp"
#include "chaos/events.sp"
#include "chaos/shareddefs.sp"
#include "chaos/util.sp"

// Meta effects
#include "chaos/effects/meta/effect_duration.sp"
#include "chaos/effects/meta/multi_effect.sp"
#include "chaos/effects/meta/no_chaos.sp"
#include "chaos/effects/meta/reinvoke_effects.sp"
#include "chaos/effects/meta/timer_speed.sp"

// Regular effects
#include "chaos/effects/add_attribute.sp"
#include "chaos/effects/add_cond.sp"
#include "chaos/effects/burn_player.sp"
#include "chaos/effects/decompiled.sp"
#include "chaos/effects/disable_direction.sp"
#include "chaos/effects/disassemble_map.sp"
#include "chaos/effects/drunk.sp"
#include "chaos/effects/earthquake.sp"
#include "chaos/effects/enable_all_holidays.sp"
#include "chaos/effects/fake_crash.sp"
#include "chaos/effects/fall_damage.sp"
#include "chaos/effects/flip_viewmodels.sp"
#include "chaos/effects/force_jump.sp"
#include "chaos/effects/force_move.sp"
#include "chaos/effects/give_item.sp"
#include "chaos/effects/grant_or_remove_all_upgrades.sp"
#include "chaos/effects/headshots.sp"
#include "chaos/effects/identity_theft.sp"
#include "chaos/effects/invert_convar.sp"
#include "chaos/effects/kill_random_player.sp"
#include "chaos/effects/loudness.sp"
#include "chaos/effects/mann_in_the_machine.sp"
#include "chaos/effects/modify_pitch.sp"
#include "chaos/effects/no_transmit.sp"
#include "chaos/effects/nothing.sp"
#include "chaos/effects/randomize_weapon_order.sp"
#include "chaos/effects/remove_pickups.sp"
#include "chaos/effects/remove_random_entity.sp"
#include "chaos/effects/resize_player.sp"
#include "chaos/effects/screen_fade.sp"
#include "chaos/effects/screen_overlay.sp"
#include "chaos/effects/set_convar.sp"
#include "chaos/effects/set_custom_model.sp"
#include "chaos/effects/set_fov.sp"
#include "chaos/effects/set_max_health.sp"
#include "chaos/effects/show_scoreboard.sp"
#include "chaos/effects/silence.sp"
#include "chaos/effects/slap.sp"
#include "chaos/effects/spawn_ball.sp"
#include "chaos/effects/spawn_birds.sp"
#include "chaos/effects/step_size.sp"
#include "chaos/effects/time_scale.sp"
#include "chaos/effects/truce.sp"
#include "chaos/effects/watermark.sp"

public Plugin myinfo =
{
	name = "[TF2] Chaos Mod",
	author = "Mikusch",
	description = "Chaos Mod for Team Fortress 2, heavily inspired by Chaos Mod V.",
	version = PLUGIN_VERSION,
	url = "https://github.com/Mikusch/ChaosModTF2"
}

// --------------------------------------------------------------------------------------------------- //
// Public Forwards
// --------------------------------------------------------------------------------------------------- //

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("chaos.phrases");
	
	CreateConVar("sm_chaos_version", PLUGIN_VERSION, "Plugin version.", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	sm_chaos_enabled = CreateConVar("sm_chaos_enabled", "1", "Enable or disable the plugin.");
	sm_chaos_enabled.AddChangeHook(ConVarChanged_ChaosEnable);
	sm_chaos_effect_cooldown = CreateConVar("sm_chaos_effect_cooldown", "60", "Default cooldown between effects.", _, true, 0.0);
	sm_chaos_effect_interval = CreateConVar("sm_chaos_effect_interval", "30", "Interval between each effect activation, in seconds.");
	sm_chaos_meta_effect_interval = CreateConVar("sm_chaos_meta_effect_interval", "12", "Interval between each attempted meta effect activation, in seconds.");
	sm_chaos_meta_effect_chance = CreateConVar("sm_chaos_meta_effect_chance", ".0075", "Chance for a meta effect to be activated every interval, in percent.", _, true, 0.0, true, 100.0);
	sm_chaos_effect_update_interval = CreateConVar("sm_chaos_effect_update_interval", ".1", "Interval at which effect update functions should be called, in seconds.");
	
	RegAdminCmd("sm_chaos_setnexteffect", ConCmd_SetNextEffect, ADMFLAG_CHEATS, "Sets the next effect.");
	RegAdminCmd("sm_chaos_forceeffect", ConCmd_ForceEffect, ADMFLAG_CHEATS, "Immediately forces an effect to start.");
	
	g_hEffects = new ArrayList(sizeof(ChaosEffect));
	g_hTimerBarHudSync = CreateHudSynchronizer();
	
	Data_Initialize();
	Events_Initialize();
}

public void OnPluginEnd()
{
	ExpireAllActiveEffects(true);
}

public void VScript_OnScriptVMInitialized()
{
	static bool bInitialized = false;

	if (bInitialized)
		return;

	bInitialized = Data_InitializeEffects();
}

public void OnMapStart()
{
	g_flLastEffectDisplayTime = GetGameTime();
	
	// Initialize VScript system
	ServerCommand("script_execute %s", "chaos");
	
	if (VScript_IsScriptVMInitialized())
		VScript_OnScriptVMInitialized();
	
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
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
	if (g_bEnabled != sm_chaos_enabled.BoolValue)
	{
		TogglePlugin(sm_chaos_enabled.BoolValue);
	}
}

public void OnClientPutInServer(int client)
{
	if (!g_bEnabled)
		return;
	
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
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
	
	float flCurTime = GetGameTime();
	float flDefaultUpdateInterval = sm_chaos_effect_update_interval.FloatValue;
	
	// Show all active effects in HUD
	if (g_flLastEffectDisplayTime && g_flLastEffectDisplayTime + 0.1 <= flCurTime)
	{
		g_flLastEffectDisplayTime = flCurTime;
		
		DisplayActiveEffects();
	}
	
	ExpireAllActiveEffects();
	
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
		{
			// Update SourcePawn effect
			if (effect.next_update_time <= flCurTime)
			{
				Function fnCallback = effect.GetCallbackFunction("Update");
				if (fnCallback != INVALID_FUNCTION)
				{
					Call_StartFunction(null, fnCallback);
					Call_PushArray(effect, sizeof(effect));
					
					float flUpdateInterval;
					if (Call_Finish(flUpdateInterval) == SP_ERROR_NONE)
					{
						if (flUpdateInterval == 0.0)
							flUpdateInterval = flDefaultUpdateInterval;
						
						g_hEffects.Set(i, flCurTime + flUpdateInterval, ChaosEffect::next_update_time);
					}
				}
			}
			
			// Update VScript effect
			if (effect.next_script_update_time <= flCurTime)
			{
				if (effect.script_file[0])
				{
					VScriptExecute hExecute = new VScriptExecute(HSCRIPT_RootTable.GetValue("Chaos_UpdateEffect"));
					hExecute.SetParamString(1, FIELD_CSTRING, effect.id);
					if (hExecute.Execute() != SCRIPT_ERROR)
					{
						float flUpdateInterval;
						if (hExecute.ReturnType == FIELD_VOID)
							flUpdateInterval = flDefaultUpdateInterval;
						else
							flUpdateInterval = float(hExecute.ReturnValue);
						
						g_hEffects.Set(i, flCurTime + flUpdateInterval, ChaosEffect::next_script_update_time);
					}

					delete hExecute;
				}
			}
		}
	}

	// Only run during an active round
	RoundState nRoundState = GameRules_GetRoundState();
	if (g_bPaused || (nRoundState != RoundState_RoundRunning && nRoundState != RoundState_Stalemate) || GameRules_GetProp("m_bInWaitingForPlayers") || GameRules_GetProp("m_bInSetup"))
		return;

	float flTimerSpeed = GetGameFrameTime();

	// Meta effects tick independently
	g_flMetaTimeElapsed += flTimerSpeed;

	// Check if a meta effect wants to modify the interval
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;

		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
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

	g_flTimeElapsed += flTimerSpeed;

	// Show interval progress bar
	if (g_flTimerBarDisplayTime > 0.0 && g_flTimerBarDisplayTime + 0.1 <= flCurTime)
	{
		g_flTimerBarDisplayTime = flCurTime;

		DisplayTimerBar();
	}

	// Activate a new effect
	float flEffectInterval = sm_chaos_effect_interval.FloatValue;
	if (flEffectInterval > 0.0 && g_flTimeElapsed >= flEffectInterval)
	{
		g_flTimeElapsed = 0.0;

		if (!g_szForceEffectId[0])
		{
			SelectRandomEffect();
		}
		else
		{
			if (!ActivateEffectById(g_szForceEffectId, true))
			{
				LogError("Failed to force effect id '%s'", g_szForceEffectId);
			}

			// Clear out forced effect
			g_szForceEffectId[0] = EOS;
		}
	}

	// Attempt to activate a new meta effect
	float flMetaEffectInterval = sm_chaos_meta_effect_interval.FloatValue;
	if (flMetaEffectInterval > 0.0 && g_flMetaTimeElapsed >= flMetaEffectInterval)
	{
		g_flMetaTimeElapsed = 0.0;

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
	
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
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
	
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
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
	
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
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
	
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
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
	
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
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
	
	StopChaosTimers();
}

// --------------------------------------------------------------------------------------------------- //
// Plugin Functions
// --------------------------------------------------------------------------------------------------- //

void TogglePlugin(bool bEnable)
{
	Events_Toggle(bEnable);
	
	if (bEnable)
	{
		StartChaosTimers();
	}
	else
	{
		StopChaosTimers();
		ExpireAllActiveEffects(true);
	}
	
	g_bEnabled = bEnable;
}

bool SelectRandomEffect(bool bMeta = false)
{
	// Sort effects based on their cooldown
	g_hEffects.SortCustom(SortFuncADTArray_SortChaosEffectsByCooldown);
	
	// Go through all effects until we find a valid one 
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
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
			
			if (ActivateEffectById(effect.id))
				return true;
		}
	}
	
	LogError("Failed to find valid effect to activate");
	return false;
}

bool ActivateEffectById(const char[] szEffectId, bool bForce = false)
{
	int nIndex = g_hEffects.FindString(szEffectId);
	if (nIndex == -1)
	{
		LogError("Failed to find effect with ID '%s'", szEffectId);
		return false;
	}
	
	ChaosEffect effect;
	if (!g_hEffects.GetArray(nIndex, effect))
	{
		return false;
	}
	
	if (bForce)
	{
		ForceExpireEffect(effect, true);
	}
	
	if (effect.active)
	{
		LogError("Effect '%s' is already active!", effect.id);
		return false;
	}
	
	if (!effect.IsCompatibleWithActiveEffects())
	{
		LogMessage("Skipped '%s' because it's incompatible with other active effects", effect.id);
		return false;
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
			LogMessage("Skipped '%s' because the 'OnStart' callback returned false", effect.id);
			return false;
		}
	}
	
	if (effect.script_file[0])
	{
		VScriptExecute hExecute = new VScriptExecute(HSCRIPT_RootTable.GetValue("Chaos_StartEffect"));
		hExecute.SetParamString(1, FIELD_CSTRING, effect.id);
		hExecute.SetParamString(2, FIELD_CSTRING, effect.script_file);
		hExecute.SetParam(3, FIELD_FLOAT, effect.duration);
		hExecute.SetParamString(4, FIELD_CSTRING, effect.data_string);
		hExecute.Execute();
		bool bReturn = hExecute.ReturnValue;
		delete hExecute;

		if (!bReturn)
		{
			LogMessage("Skipped '%s' because the 'OnStart' script function returned false", effect.id);
			return false;
		}
	}
	
	// One-shot effects are never set to active state
	if (effect.duration)
	{
		effect.active = true;
	}
	
	effect.cooldown_left = effect.cooldown;
	effect.current_duration = effect.duration;
	effect.activate_time = GetGameTime();
	effect.next_update_time = GetGameTime();
	effect.next_script_update_time = GetGameTime();
	
	// Check if any active effect wants to modify the duration
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect other;
		if (g_hEffects.GetArray(i, other))
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
	for (int i = 0; i < nLength; i++)
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
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		char szName[64];
		if (!effect.GetDisplayName(szName, sizeof(szName), client))
			continue;

		SendCustomHudNotificationCustom(client, szName, "ico_notify_flag_moving_alt");
	}
	
	// For effects that need to access properties set after successful activation
	fnCallback = effect.GetCallbackFunction("OnStartPost");
	if (fnCallback != INVALID_FUNCTION)
	{
		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_Finish();
	}
	
	LogMessage("Activated effect '%s'", effect.id);
	
	return true;
}

void DisplayTimerBar()
{
	SetHudTextParams(g_stTimerBarConfig.x, g_stTimerBarConfig.y, 0.1, g_stTimerBarConfig.color[0], g_stTimerBarConfig.color[1], g_stTimerBarConfig.color[2], g_stTimerBarConfig.color[3]);
	
	float flRatio = g_flTimeElapsed / sm_chaos_effect_interval.FloatValue;
	
	int iNumBlocks = g_stTimerBarConfig.num_blocks;
	int iFilledBlocks = RoundToNearest(flRatio * iNumBlocks);
	int iEmptyBlocks = iNumBlocks - iFilledBlocks;
	
	char szProgressBar[64];
	for (int i = 0; i < iFilledBlocks; i++)
	{
		StrCat(szProgressBar, sizeof(szProgressBar), g_stTimerBarConfig.filled);
	}
	for (int i = 0; i < iEmptyBlocks; i++)
	{
		StrCat(szProgressBar, sizeof(szProgressBar), g_stTimerBarConfig.empty);
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
	// Sort effects by activation time
	g_hEffects.SortCustom(SortFuncADTArray_SortChaosEffectsByActivationTime);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		// KeyHintText has a 1 byte param
		char szMessage[MAX_USER_MSG_DATA - 1];

		// Go through all effects until we find a valid one 
		int nLength = g_hEffects.Length;
		for (int i = 0; i < nLength; i++)
		{
			ChaosEffect effect;
			if (g_hEffects.GetArray(i, effect))
			{
				if (effect.activate_time == 0.0)
					continue;
				
				char szName[64];
				if (!effect.GetDisplayName(szName, sizeof(szName), client))
					continue;
				
				bool bPhraseExists = TranslationPhraseExists(szName);
				
				char szLine[128];
				
				// Expiring effects stay on screen while active
				if (effect.active)
				{
					float flEndTime = effect.activate_time + effect.current_duration;
					float flRatio = (GetGameTime() - effect.activate_time) / (flEndTime - effect.activate_time);
					
					int iNumBlocks = g_stEffectBarConfig.num_blocks;
					int iEmptyBlocks = RoundToNearest(flRatio * iNumBlocks);
					int iFilledBlocks = iNumBlocks - iEmptyBlocks;
					
					char szProgressBar[64];
					for (int j = 0; j < iFilledBlocks; j++)
					{
						StrCat(szProgressBar, sizeof(szProgressBar), g_stEffectBarConfig.filled);
					}
					for (int j = 0; j < iEmptyBlocks; j++)
					{
						StrCat(szProgressBar, sizeof(szProgressBar), g_stEffectBarConfig.empty);
					}
					
					Format(szLine, sizeof(szLine), bPhraseExists ? "%s %T" : "%s %s", szProgressBar, szName, client);
				}
				// One-shot effects stay on screen for some time
				else if (!effect.duration && GetGameTime() - effect.activate_time <= ONESHOT_EFFECT_DISPLAY_TIME)
				{
					Format(szLine, sizeof(szLine), bPhraseExists ? "%T" : "%s", szName, client);
				}
				
				// -1 accounts for newline
				if (szLine[0] && strlen(szMessage) + strlen(szLine) < sizeof(szMessage) - 1)
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
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
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

void ForceExpireEffect(ChaosEffect effect, bool bExpireAllTags = false)
{
	int nIndex = g_hEffects.FindString(effect.id);
	if (nIndex == -1)
	{
		LogError("Failed to expire unknown effect with id '%s'", effect.id);
		return;
	}
	
	// Expire the current effect
	if (effect.active)
	{
		effect.active = false;
		g_hEffects.SetArray(nIndex, effect);
		
		Function fnCallback = effect.GetCallbackFunction("OnEnd");
		if (fnCallback != INVALID_FUNCTION)
		{
			Call_StartFunction(null, fnCallback);
			Call_PushArray(effect, sizeof(effect));
			Call_Finish();
		}
		
		if (effect.script_file[0])
		{
			VScriptExecute hExecute = new VScriptExecute(HSCRIPT_RootTable.GetValue("Chaos_EndEffect"));
			hExecute.SetParamString(1, FIELD_CSTRING, effect.id);
			hExecute.Execute();
			delete hExecute;
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
	
	// Expire all other effects matching this tag
	if (bExpireAllTags && effect.tags)
	{
		int nLength = g_hEffects.Length;
		for (int i = 0; i < nLength; i++)
		{
			if (!g_hEffects.Get(i, ChaosEffect::active))
				continue;
			
			ChaosEffect other;
			if (g_hEffects.GetArray(i, other))
			{
				if (StrEqual(other.id, effect.id))
					continue;
				
				if (!other.tags)
					continue;
				
				for (int j = 0; j < effect.tags.Length; j++)
				{
					char tag[EFFECT_MAX_TAG_LENGTH];
					if (effect.tags.GetString(j, tag, sizeof(tag)) && other.tags.FindString(tag) != -1)
						ForceExpireEffect(other);
				}
			}
		}
	}
}

/**
 * Returns true if the given effect class is currently active.
 */
bool IsEffectOfClassActive(const char[] szEffectClass)
{
	ChaosEffect effect;
	return GetActiveEffectByClass(szEffectClass, effect);
}

/**
 * Retrieves the active effect with the given class.
 */
bool GetActiveEffectByClass(const char[] szEffectClass, ChaosEffect effect)
{
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;

		if (g_hEffects.GetArray(i, effect) && StrEqual(szEffectClass, effect.effect_class))
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
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		if (!g_hEffects.Get(i, ChaosEffect::data))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && StrEqual(effect.effect_class, szEffectClass))
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
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		if (!g_hEffects.Get(i, ChaosEffect::data))
			continue;
		
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && StrEqual(effect.effect_class, szEffectClass))
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
 * Returns true if the given key was found in the given section in active effects with the given class.
 */
bool FindKeyInSectionInActiveEffects(const char[] szEffectClass, const char[] szSection, const char[] szKey)
{
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;

		if (!g_hEffects.Get(i, ChaosEffect::data))
			continue;

		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect) && StrEqual(effect.effect_class, szEffectClass))
		{
			KeyValues kv = new KeyValues("data");
			kv.Import(effect.data);

			if (FindKeyInSectionInKeyValues(kv, szSection, szKey))
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
	g_flTimeElapsed = 0.0;
	g_flMetaTimeElapsed = 0.0;

	g_flTimerBarDisplayTime = flTime;
}

void StartChaosTimers()
{
	SetChaosTimers(GetGameTime());
}

void StopChaosTimers()
{
	SetChaosTimers(-1.0);
}

void SetChaosPaused(bool bPaused)
{
	g_bPaused = bPaused;
}

static void ConVarChanged_ChaosEnable(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_bEnabled != convar.BoolValue)
	{
		TogglePlugin(convar.BoolValue);
	}
}

static Action ConCmd_SetNextEffect(int client, int args)
{
	if (!g_bEnabled)
		return Plugin_Continue;
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_chaos_setnexteffect <id>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, g_szForceEffectId, sizeof(g_szForceEffectId));
	
	int nIndex = g_hEffects.FindString(g_szForceEffectId);
	if (nIndex == -1)
	{
		CReplyToCommand(client, "%t", "#Chaos_Effect_NotFound", g_szForceEffectId);
	}
	else
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(nIndex, effect))
		{
			CReplyToCommand(client, "%t", "#Chaos_Effect_SetNextEffect_Success", effect.name);
		}
	}
	
	return Plugin_Handled;
}

static Action ConCmd_ForceEffect(int client, int args)
{
	if (!g_bEnabled)
		return Plugin_Continue;
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_chaos_forceeffect <id>");
		return Plugin_Handled;
	}
	
	char szEffectId[64];
	GetCmdArg(1, szEffectId, sizeof(szEffectId));
	
	int nIndex = g_hEffects.FindString(szEffectId);
	if (nIndex == -1)
	{
		CReplyToCommand(client, "%t", "#Chaos_Effect_NotFound", szEffectId);
	}
	else
	{
		ActivateEffectById(szEffectId, true);
	}
	
	return Plugin_Handled;
}
