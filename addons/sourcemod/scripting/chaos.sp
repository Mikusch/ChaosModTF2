#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <tf2attributes>
#include <tf2_stocks>
#include <tf2items>
#include <tf_econ_data>
#include <vscript>
#include <morecolors>

#define PLUGIN_VERSION	"2.1.0"

ConVar sm_chaos_enabled;
ConVar sm_chaos_effect_cooldown;
ConVar sm_chaos_effect_interval;
ConVar sm_chaos_meta_effect_interval;
ConVar sm_chaos_meta_effect_chance;
ConVar sm_chaos_effect_update_interval;
ConVar sm_chaos_debug;

bool g_bEnabled;
bool g_bPaused;
ArrayList g_hEffects;
StringMap g_hEffectIndexById;
ArrayList g_hDisplayOrder;
StringMap g_hActiveClaims;
ArrayList g_hActiveEffects;
Handle g_hTimerBarHudSync;
float g_flTimeElapsed;
float g_flMetaTimeElapsed;
float g_flLastEffectDisplayTime;
float g_flTimerBarDisplayTime;
char g_szForceEffectId[64];
ScriptCall g_hUpdateEffect;
ScriptCall g_hStartEffect;
ScriptCall g_hEndEffect;

#include "chaos/data.sp"
#include "chaos/events.sp"
#include "chaos/shareddefs.sp"
#include "chaos/util.sp"
#include "chaos/claims.sp"
#include "chaos/sdkcalls.sp"
#include "chaos/dhooks.sp"

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
	sm_chaos_enabled.AddChangeHook(ConVarChanged_Enabled);
	sm_chaos_effect_cooldown = CreateConVar("sm_chaos_effect_cooldown", "60", "Default effect cooldown, counted in subsequent effect activations.", _, true, 0.0);
	sm_chaos_effect_interval = CreateConVar("sm_chaos_effect_interval", "30", "Interval between each effect activation, in seconds.");
	sm_chaos_meta_effect_interval = CreateConVar("sm_chaos_meta_effect_interval", "12", "Interval between each attempted meta effect activation, in seconds.");
	sm_chaos_meta_effect_chance = CreateConVar("sm_chaos_meta_effect_chance", ".0075", "Probability that a meta effect activates on each meta interval, as a fraction.", _, true, 0.0, true, 1.0);
	sm_chaos_effect_update_interval = CreateConVar("sm_chaos_effect_update_interval", ".1", "Interval at which effect update functions should be called, in seconds.");
	sm_chaos_debug = CreateConVar("sm_chaos_debug", "0", "Log effect activation and refusal decisions.");

	RegAdminCmd("sm_chaos_setnexteffect", ConCmd_SetNextEffect, ADMFLAG_CHEATS, "Sets the next effect.");
	RegAdminCmd("sm_chaos_forceeffect", ConCmd_ForceEffect, ADMFLAG_CHEATS, "Immediately forces an effect to start.");
	RegAdminCmd("sm_chaos_list", ConCmd_List, ADMFLAG_GENERIC, "Lists effects with their state, cooldown and remaining time.");
	RegAdminCmd("sm_chaos_expire", ConCmd_Expire, ADMFLAG_CHEATS, "Expires a single active effect.");

	g_hEffects = new ArrayList(sizeof(ChaosEffect));
	g_hEffectIndexById = new StringMap();
	g_hDisplayOrder = new ArrayList();
	g_hActiveEffects = new ArrayList();
	g_hActiveClaims = new StringMap();
	g_hTimerBarHudSync = CreateHudSynchronizer();

	Data_Initialize();
	Events_Initialize();
	SDKCalls_Initialize();

	g_hUpdateEffect = new ScriptCall("Chaos_UpdateEffect", ScriptField_Variant, ScriptField_String);
	g_hStartEffect = new ScriptCall("Chaos_StartEffect", ScriptField_Bool, ScriptField_String, ScriptField_String, ScriptField_Float, ScriptField_String);
	g_hEndEffect = new ScriptCall("Chaos_EndEffect", ScriptField_Void, ScriptField_String);

	Data_InitializeEffects();
}

public void OnPluginEnd()
{
	ExpireAllActiveEffects(true);
}

public void OnMapStart()
{
	g_flLastEffectDisplayTime = 0.0;

	// Initialize VScript system
	ServerCommand("script_execute %s", "chaos");

	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(i, effect))
		{
			Function fnCallback = effect.GetCallback(ChaosCb_OnMapStart);
			if (fnCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}

			effect.active = false;
			effect.activate_time = 0.0;
			effect.end_time = 0.0;
			g_hEffects.SetArray(i, effect);

			if (effect.state)
			{
				effect.state.Clear();
			}
		}
	}

	g_hActiveClaims.Clear();
	g_hActiveEffects.Clear();
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

	int nLength = g_hActiveEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(g_hActiveEffects.Get(i), effect))
			continue;

		Function fnCallback = effect.GetCallback(ChaosCb_OnClientPutInServer);
		if (fnCallback == INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_PushCell(client);
		Call_Finish();
	}
}

public void OnGameFrame()
{
	if (!g_bEnabled)
		return;

	float flCurTime = GetGameTime();
	float flDefaultUpdateInterval = sm_chaos_effect_update_interval.FloatValue;

	ExpireAllActiveEffects();

	// Show all active effects in HUD
	if (g_flLastEffectDisplayTime + 0.1 <= flCurTime)
	{
		g_flLastEffectDisplayTime = flCurTime;

		DisplayActiveEffects();
	}

	// Length is re-read every step, an update callback may expire an effect
	for (int i = 0; i < g_hActiveEffects.Length; i++)
	{
		int nIndex = g_hActiveEffects.Get(i);

		ChaosEffect effect;
		if (!g_hEffects.GetArray(nIndex, effect))
			continue;

		// Update SourcePawn effect
		if (effect.next_update_time <= flCurTime)
		{
			Function fnCallback = effect.GetCallback(ChaosCb_Update);
			if (fnCallback != INVALID_FUNCTION)
			{
				// Reschedule up-front so a callback that throws can't be retried every frame
				g_hEffects.Set(nIndex, flCurTime + flDefaultUpdateInterval, ChaosEffect::next_update_time);

				Call_StartFunction(null, fnCallback);
				Call_PushArray(effect, sizeof(effect));

				float flUpdateInterval;
				if (Call_Finish(flUpdateInterval) == SP_ERROR_NONE)
				{
					g_hEffects.Set(nIndex, flCurTime + GetEffectUpdateInterval(flUpdateInterval, flDefaultUpdateInterval), ChaosEffect::next_update_time);
				}
			}
		}

		// Update VScript effect
		if (effect.script_file[0] && effect.next_script_update_time <= flCurTime)
		{
			// Reschedule up-front so a script error can't be retried every frame
			g_hEffects.Set(nIndex, flCurTime + flDefaultUpdateInterval, ChaosEffect::next_script_update_time);

			if (g_hUpdateEffect.Execute(effect.id) == ScriptStatus_Done)
			{
				float flUpdateInterval = g_hUpdateEffect.IsReturnNull() ? 0.0 : g_hUpdateEffect.GetReturnFloat();

				g_hEffects.Set(nIndex, flCurTime + GetEffectUpdateInterval(flUpdateInterval, flDefaultUpdateInterval), ChaosEffect::next_script_update_time);
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
	int nActive = g_hActiveEffects.Length;
	for (int i = 0; i < nActive; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(g_hActiveEffects.Get(i), effect))
			continue;

		Function fnCallback = effect.GetCallback(ChaosCb_ModifyTimerSpeed);
		if (fnCallback == INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_PushFloatRef(flTimerSpeed);
		Call_Finish();
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
			char szForced[sizeof(g_szForceEffectId)];
			strcopy(szForced, sizeof(szForced), g_szForceEffectId);

			g_szForceEffectId[0] = EOS;

			char szReason[192];
			if (!ActivateEffectById(szForced, true, szReason, sizeof(szReason)))
			{
				LogError("Failed to force effect id '%s': %s", szForced, szReason);
			}
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

	int nLength = g_hActiveEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(g_hActiveEffects.Get(i), effect))
			continue;

		Function fnCallback = effect.GetCallback(ChaosCb_OnEntityCreated);
		if (fnCallback == INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_PushCell(entity);
		Call_PushString(classname);
		Call_Finish();
	}
}

public void OnEntityDestroyed(int entity)
{
	if (!g_bEnabled)
		return;

	int nLength = g_hActiveEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(g_hActiveEffects.Get(i), effect))
			continue;

		Function fnCallback = effect.GetCallback(ChaosCb_OnEntityDestroyed);
		if (fnCallback == INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_PushCell(entity);
		Call_Finish();
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!g_bEnabled)
		return Plugin_Continue;

	Action nReturn = Plugin_Continue;

	int nLength = g_hActiveEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(g_hActiveEffects.Get(i), effect))
			continue;

		Function fnCallback = effect.GetCallback(ChaosCb_OnPlayerRunCmd);
		if (fnCallback == INVALID_FUNCTION)
			continue;

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

	return nReturn;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (!g_bEnabled)
		return;

	int nLength = g_hActiveEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(g_hActiveEffects.Get(i), effect))
			continue;

		Function fnCallback = effect.GetCallback(ChaosCb_OnConditionAdded);
		if (fnCallback == INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_PushCell(client);
		Call_PushCell(condition);
		Call_Finish();
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (!g_bEnabled)
		return;

	int nLength = g_hActiveEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(g_hActiveEffects.Get(i), effect))
			continue;

		Function fnCallback = effect.GetCallback(ChaosCb_OnConditionRemoved);
		if (fnCallback == INVALID_FUNCTION)
			continue;

		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_PushCell(client);
		Call_PushCell(condition);
		Call_Finish();
	}
}

public void TF2_OnWaitingForPlayersStart()
{
	if (!g_bEnabled)
		return;

	Chaos_StopTimers();
}

// --------------------------------------------------------------------------------------------------- //
// Plugin Functions
// --------------------------------------------------------------------------------------------------- //

static void TogglePlugin(bool bEnable)
{
	Events_Toggle(bEnable);

	if (bEnable)
	{
		Chaos_StartTimers();
	}
	else
	{
		Chaos_StopTimers();
		ExpireAllActiveEffects(true);
	}

	g_bEnabled = bEnable;
}

int FindEffectIndexById(const char[] szEffectId)
{
	int nIndex;
	return (g_hEffectIndexById && g_hEffectIndexById.GetValue(szEffectId, nIndex)) ? nIndex : -1;
}

bool GetEffectById(const char[] szEffectId, ChaosEffect effect)
{
	int nIndex = FindEffectIndexById(szEffectId);
	return nIndex != -1 && g_hEffects.GetArray(nIndex, effect) != 0;
}

bool SelectRandomEffect(bool bMeta = false)
{
	ArrayList hPool = new ArrayList();

	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(i, effect))
			continue;

		if (!effect.enabled)
			continue;

		// Filter by meta effects
		if (effect.meta != bMeta)
			continue;

		// Skip already active effects or effects still on cooldown
		if (effect.active || effect.cooldown_left > 0)
			continue;

		char szReason[192];
		if (Claims_FindConflict(effect, szReason, sizeof(szReason)))
			continue;

		hPool.Push(i);
	}

	while (hPool.Length)
	{
		int nEntry = GetRandomInt(0, hPool.Length - 1);

		char szId[64];
		g_hEffects.GetString(hPool.Get(nEntry), szId, sizeof(szId), ChaosEffect::id);

		hPool.Erase(nEntry);

		if (ActivateEffectById(szId))
		{
			delete hPool;
			return true;
		}
	}

	delete hPool;

	LogError("Failed to find valid effect to activate");
	return false;
}

bool ActivateEffectById(const char[] szEffectId, bool bForce = false, char[] szReason = "", int iMaxLength = 0)
{
	SetRefusalReason(szReason, iMaxLength, "unknown reason");

	int nIndex = FindEffectIndexById(szEffectId);
	if (nIndex == -1)
	{
		SetRefusalReason(szReason, iMaxLength, "no effect with that ID");
		LogError("Failed to find effect with ID '%s'", szEffectId);
		return false;
	}

	ChaosEffect effect;
	if (!g_hEffects.GetArray(nIndex, effect))
	{
		return false;
	}

	if (!effect.enabled && !bForce)
	{
		SetRefusalReason(szReason, iMaxLength, "effect is disabled");
		return false;
	}

	if (effect.active)
	{
		if (!bForce)
		{
			SetRefusalReason(szReason, iMaxLength, "effect is already active");
			return false;
		}

		ForceExpireEffect(effect);
	}

	if (!bForce)
	{
		char szConflict[192];
		if (Claims_FindConflict(effect, szConflict, sizeof(szConflict)))
		{
			SetRefusalReason(szReason, iMaxLength, "%s", szConflict);
			LogDebug("Skipped '%s' because %s", effect.id, szConflict);
			return false;
		}
	}
	else
	{
		// Tear conflicts down first, or their 'OnEnd' undoes what this effect is about to write
		ExpireConflictingEffects(effect);
	}

	effect.activate_time = GetGameTime();
	effect.current_duration = effect.duration;

	int nLength = g_hEffects.Length;

	// Check if any active effect wants to modify the duration
	if (effect.duration)
	{
		int nActive = g_hActiveEffects.Length;
		for (int i = 0; i < nActive; i++)
		{
			int nOther = g_hActiveEffects.Get(i);
			if (nOther == nIndex)
				continue;

			ChaosEffect other;
			if (!g_hEffects.GetArray(nOther, other))
				continue;

			Function fnModify = other.GetCallback(ChaosCb_ModifyEffectDuration);
			if (fnModify == INVALID_FUNCTION)
				continue;

			Call_StartFunction(null, fnModify);
			Call_PushArray(other, sizeof(other));
			Call_PushFloatRef(effect.current_duration);
			Call_Finish();
		}

		if (effect.current_duration <= 0.0)
		{
			effect.current_duration = effect.duration;
		}
	}

	effect.end_time = effect.activate_time + effect.current_duration;

	Function fnCallback = effect.GetCallback(ChaosCb_OnStart);
	if (fnCallback != INVALID_FUNCTION)
	{
		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));

		bool bReturn;
		int nError = Call_Finish(bReturn);

		if (nError != SP_ERROR_NONE)
		{
			SetRefusalReason(szReason, iMaxLength, "the 'OnStart' callback aborted");
			LogError("Effect '%s': the 'OnStart' callback aborted with SourcePawn error %d", effect.id, nError);
			return false;
		}

		if (!bReturn)
		{
			SetRefusalReason(szReason, iMaxLength, "the 'OnStart' callback returned false");
			LogDebug("Skipped '%s' because the 'OnStart' callback returned false", effect.id);
			return false;
		}
	}

	if (effect.script_file[0])
	{
		bool bReturn = g_hStartEffect.Execute(effect.id, effect.script_file, effect.current_duration, effect.data_string) == ScriptStatus_Done && g_hStartEffect.GetReturnBool();
		if (!bReturn)
		{
			SetRefusalReason(szReason, iMaxLength, "the 'OnStart' script function returned false");
			LogDebug("Skipped '%s' because the 'OnStart' script function returned false", effect.id);

			Function fnEnd = effect.GetCallback(ChaosCb_OnEnd);
			if (fnEnd != INVALID_FUNCTION)
			{
				Call_StartFunction(null, fnEnd);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}

			if (effect.state)
			{
				effect.state.Clear();
			}

			return false;
		}
	}

	// One-shot effects are never set to active state
	if (effect.duration)
	{
		effect.active = true;
	}

	effect.cooldown_left = effect.cooldown >= 0 ? effect.cooldown : sm_chaos_effect_cooldown.IntValue;
	effect.next_update_time = effect.activate_time;
	effect.next_script_update_time = effect.activate_time;

	g_hEffects.SetArray(nIndex, effect);

	// One-shots deliberately opt out of cleanup, so they never hold claims either
	if (effect.active)
	{
		Claims_Register(effect);

		if (g_hActiveEffects.FindValue(nIndex) == -1)
			g_hActiveEffects.Push(nIndex);
	}

	// Lower cooldown of all other effects
	for (int i = 0; i < nLength; i++)
	{
		if (i == nIndex)
			continue;

		if (g_hEffects.Get(i, ChaosEffect::active))
			continue;

		// Only meta effects can lower meta cooldowns
		if (view_as<bool>(g_hEffects.Get(i, ChaosEffect::meta)) != effect.meta)
			continue;

		// Never lower cooldown below 0
		g_hEffects.Set(i, Max(0, g_hEffects.Get(i, ChaosEffect::cooldown_left) - 1), ChaosEffect::cooldown_left);
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
	fnCallback = effect.GetCallback(ChaosCb_OnStartPost);
	if (fnCallback != INVALID_FUNCTION)
	{
		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_Finish();
	}

	LogMessage("Activated effect '%s'", effect.id);

	return true;
}

static float GetEffectUpdateInterval(float flInterval, float flDefault)
{
	return flInterval != 0.0 ? flInterval : flDefault;
}

static void DisplayTimerBar()
{
	SetHudTextParams(g_stTimerBarConfig.x, g_stTimerBarConfig.y, 0.1, g_stTimerBarConfig.color[0], g_stTimerBarConfig.color[1], g_stTimerBarConfig.color[2], g_stTimerBarConfig.color[3]);

	float flInterval = sm_chaos_effect_interval.FloatValue;
	float flRatio = flInterval > 0.0 ? (g_flTimeElapsed / flInterval) : 0.0;

	char szProgressBar[64];
	BuildProgressBar(g_stTimerBarConfig, flRatio, false, szProgressBar, sizeof(szProgressBar));

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		ShowSyncHudText(client, g_hTimerBarHudSync, "%s", szProgressBar);
	}
}

static void BuildDisplayOrder()
{
	g_hDisplayOrder.Clear();

	float flCurTime = GetGameTime();

	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (g_hEffects.Get(i, ChaosEffect::active))
		{
			g_hDisplayOrder.Push(i);
			continue;
		}

		float flDuration = g_hEffects.Get(i, ChaosEffect::duration);
		if (flDuration != 0.0)
			continue;

		// One-shot effects stay on screen for some time after they run
		float flActivateTime = g_hEffects.Get(i, ChaosEffect::activate_time);
		if (flActivateTime != 0.0 && flCurTime - flActivateTime <= ONESHOT_EFFECT_DISPLAY_TIME)
			g_hDisplayOrder.Push(i);
	}

	g_hDisplayOrder.SortCustom(SortFuncADTArray_SortDisplayOrder);
}

static void DisplayActiveEffects()
{
	BuildDisplayOrder();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		char szMessage[MAX_USER_MSG_DATA - 1];
		BuildEffectHud(client, szMessage, sizeof(szMessage));

		PrintKeyHintText(client, "%s", szMessage);
	}
}

static void BuildEffectHud(int client, char[] szMessage, int iMaxLength)
{
	szMessage[0] = EOS;

	int nOffset = 0;
	int nHidden = 0;
	float flCurTime = GetGameTime();

	int nLength = g_hDisplayOrder.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(g_hDisplayOrder.Get(i), effect))
			continue;

		char szName[64];
		if (!effect.GetDisplayName(szName, sizeof(szName), client))
			continue;

		char szLine[128];

		if (effect.active)
		{
			// Expiring effects stay on screen while active
			float flTotal = effect.end_time - effect.activate_time;
			float flRatio = flTotal > 0.0 ? ((flCurTime - effect.activate_time) / flTotal) : 1.0;

			char szProgressBar[64];
			BuildProgressBar(g_stEffectBarConfig, flRatio, true, szProgressBar, sizeof(szProgressBar));

			FormatEx(szLine, sizeof(szLine), "%s %s", szProgressBar, szName);
		}
		else
		{
			// One-shot effects stay on screen for some time
			strcopy(szLine, sizeof(szLine), szName);
		}

		if (nOffset + strlen(szLine) + 1 >= iMaxLength - 12)
		{
			nHidden = nLength - i;
			break;
		}

		nOffset += FormatEx(szMessage[nOffset], iMaxLength - nOffset, "%s%s", nOffset ? "\n" : "", szLine);
	}

	if (nHidden > 0)
	{
		FormatEx(szMessage[nOffset], iMaxLength - nOffset, "%s+%d more", nOffset ? "\n" : "", nHidden);
	}
}

void ExpireAllActiveEffects(bool bForce = false)
{
	float flCurTime = GetGameTime();

	// Backwards, because ForceExpireEffect erases from the list we are walking
	for (int i = g_hActiveEffects.Length - 1; i >= 0; i--)
	{
		if (i >= g_hActiveEffects.Length)
			continue;

		ChaosEffect effect;
		if (!g_hEffects.GetArray(g_hActiveEffects.Get(i), effect))
			continue;

		if (!bForce && flCurTime < effect.end_time)
			continue;

		ForceExpireEffect(effect);
	}
}

static void ForceExpireEffect(ChaosEffect effect)
{
	int nIndex = FindEffectIndexById(effect.id);
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

		int nEntry = g_hActiveEffects.FindValue(nIndex);
		if (nEntry != -1)
			g_hActiveEffects.Erase(nEntry);

		Claims_Unregister(effect);

		Function fnCallback = effect.GetCallback(ChaosCb_OnEnd);
		if (fnCallback != INVALID_FUNCTION)
		{
			Call_StartFunction(null, fnCallback);
			Call_PushArray(effect, sizeof(effect));
			Call_Finish();
		}

		if (effect.script_file[0])
		{
			g_hEndEffect.Execute(effect.id);
		}

		if (effect.state)
		{
			effect.state.Clear();
		}

		if (effect.start_sound[0])
		{
			StopStaticSound(effect.start_sound);
		}

		if (effect.end_sound[0])
		{
			PlayStaticSound(effect.end_sound);
		}

		LogDebug("Expired effect '%s'", effect.id);
	}
}

static void ExpireConflictingEffects(ChaosEffect effect)
{
	if (!effect.claims)
		return;

	// Resolve owners up front, expiring an effect mutates the claim registry
	ArrayList hOwners = new ArrayList(ByteCountToCells(64));

	int nClaims = effect.claims.Length;
	for (int i = 0; i < nClaims; i++)
	{
		char szClaim[EFFECT_MAX_CLAIM_LENGTH];
		if (!effect.claims.GetString(i, szClaim, sizeof(szClaim)))
			continue;

		char szOwner[64];
		if (!g_hActiveClaims.GetString(szClaim, szOwner, sizeof(szOwner)))
			continue;

		if (StrEqual(szOwner, effect.id))
			continue;

		if (hOwners.FindString(szOwner) == -1)
			hOwners.PushString(szOwner);
	}

	int nOwners = hOwners.Length;
	for (int i = 0; i < nOwners; i++)
	{
		char szOwner[64];
		hOwners.GetString(i, szOwner, sizeof(szOwner));

		ChaosEffect other;
		if (GetEffectById(szOwner, other) && other.active)
		{
			ForceExpireEffect(other);
		}
	}

	delete hOwners;
}

bool GetActiveEffectByClass(const char[] szEffectClass, ChaosEffect effect)
{
	int nLength = g_hActiveEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		int nIndex = g_hActiveEffects.Get(i);

		char szClass[64];
		g_hEffects.GetString(nIndex, szClass, sizeof(szClass), ChaosEffect::effect_class);

		if (StrEqual(szEffectClass, szClass))
		{
			return g_hEffects.GetArray(nIndex, effect) != 0;
		}
	}

	return false;
}

void Chaos_SetTimers(float flTime)
{
	g_flTimeElapsed = 0.0;
	g_flMetaTimeElapsed = 0.0;

	g_flTimerBarDisplayTime = flTime;
}

void Chaos_StartTimers()
{
	Chaos_SetTimers(GetGameTime());
}

void Chaos_StopTimers()
{
	Chaos_SetTimers(-1.0);
}

void Chaos_SetPaused(bool bPaused)
{
	g_bPaused = bPaused;
}

static void SetRefusalReason(char[] szReason, int iMaxLength, const char[] format, any...)
{
	if (iMaxLength <= 0)
		return;

	VFormat(szReason, iMaxLength, format, 4);
}

static void LogDebug(const char[] format, any...)
{
	if (!sm_chaos_debug || !sm_chaos_debug.BoolValue)
		return;

	char szBuffer[512];
	VFormat(szBuffer, sizeof(szBuffer), format, 2);

	LogMessage("%s", szBuffer);
}

static void ConVarChanged_Enabled(ConVar convar, const char[] oldValue, const char[] newValue)
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

	char szEffectId[sizeof(g_szForceEffectId)];
	GetCmdArg(1, szEffectId, sizeof(szEffectId));

	ChaosEffect effect;
	if (!GetEffectById(szEffectId, effect))
	{
		CReplyToCommand(client, "%t", "#Chaos_Effect_NotFound", szEffectId);
		return Plugin_Handled;
	}

	strcopy(g_szForceEffectId, sizeof(g_szForceEffectId), szEffectId);

	CReplyToCommand(client, "%t", "#Chaos_Effect_SetNextEffect_Success", effect.name);

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

	if (FindEffectIndexById(szEffectId) == -1)
	{
		CReplyToCommand(client, "%t", "#Chaos_Effect_NotFound", szEffectId);
		return Plugin_Handled;
	}

	char szReason[192];
	if (!ActivateEffectById(szEffectId, true, szReason, sizeof(szReason)))
	{
		CReplyToCommand(client, "%t", "#Chaos_Effect_ForceEffect_Failed", szEffectId, szReason);
	}

	return Plugin_Handled;
}

static Action ConCmd_List(int client, int args)
{
	if (!g_bEnabled)
		return Plugin_Continue;

	char szFilter[64];
	if (args >= 1)
	{
		GetCmdArg(1, szFilter, sizeof(szFilter));
	}

	float flCurTime = GetGameTime();
	int nShown = 0, nActive = 0;

	// One line per effect would flood chat
	ReplySource nOldSource = SetCmdReplySource(SM_REPLY_TO_CONSOLE);

	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		ChaosEffect effect;
		if (!g_hEffects.GetArray(i, effect))
			continue;

		if (effect.active)
			nActive++;

		if (szFilter[0] && StrContains(effect.id, szFilter, false) == -1)
			continue;

		nShown++;

		if (effect.active)
		{
			ReplyToCommand(client, "[SM] %-32s ACTIVE   %.0fs left%s", effect.id, effect.end_time - flCurTime, effect.meta ? "   (meta)" : "");
		}
		else if (!effect.enabled)
		{
			ReplyToCommand(client, "[SM] %-32s DISABLED", effect.id);
		}
		else
		{
			ReplyToCommand(client, "[SM] %-32s ready in %d activation(s)%s", effect.id, effect.cooldown_left, effect.meta ? "   (meta)" : "");
		}
	}

	ReplyToCommand(client, "[SM] %d effect(s) shown, %d active, %d registered.", nShown, nActive, nLength);

	SetCmdReplySource(nOldSource);

	return Plugin_Handled;
}

static Action ConCmd_Expire(int client, int args)
{
	if (!g_bEnabled)
		return Plugin_Continue;

	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_chaos_expire <id>");
		return Plugin_Handled;
	}

	char szEffectId[64];
	GetCmdArg(1, szEffectId, sizeof(szEffectId));

	ChaosEffect effect;
	if (!GetEffectById(szEffectId, effect))
	{
		CReplyToCommand(client, "%t", "#Chaos_Effect_NotFound", szEffectId);
		return Plugin_Handled;
	}

	if (!effect.active)
	{
		CReplyToCommand(client, "%t", "#Chaos_Effect_Expire_NotActive", szEffectId);
		return Plugin_Handled;
	}

	ForceExpireEffect(effect);
	CReplyToCommand(client, "%t", "#Chaos_Effect_Expire_Success", effect.name);

	return Plugin_Handled;
}
