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

#define PLUGIN_VERSION	"1.5.0"

ConVar sm_chaos_enabled;
ConVar sm_chaos_effect_cooldown;
ConVar sm_chaos_effect_interval;
ConVar sm_chaos_meta_effect_interval;
ConVar sm_chaos_meta_effect_chance;
ConVar sm_chaos_effect_update_interval;

bool g_bEnabled;
bool g_bNoChaos;
ArrayList g_hEffects;
Handle g_hTimerBarHudSync;
float g_flTimeElapsed;
float g_flMetaTimeElapsed;
float g_flLastEffectDisplayTime;
float g_flTimerBarDisplayTime;
char g_szForceEffectId[64];

ProgressBar g_aEffectBarConfig;
ProgressBar g_aTimerBarConfig;

#include "chaos/data.sp"
#include "chaos/events.sp"
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
#include "chaos/effects/drunk.sp"
#include "chaos/effects/earthquake.sp"
#include "chaos/effects/enableallholidays.sp"
#include "chaos/effects/fakecrash.sp"
#include "chaos/effects/falldamage.sp"
#include "chaos/effects/flipviewmodels.sp"
#include "chaos/effects/floorislava.sp"
#include "chaos/effects/forceforward.sp"
#include "chaos/effects/giveitem.sp"
#include "chaos/effects/grantorremoveallupgrades.sp"
#include "chaos/effects/headshots.sp"
#include "chaos/effects/identitytheft.sp"
#include "chaos/effects/invertconvar.sp"
#include "chaos/effects/jumpjump.sp"
#include "chaos/effects/killrandomplayer.sp"
#include "chaos/effects/loudness.sp"
#include "chaos/effects/manninthemachine.sp"
#include "chaos/effects/modifypitch.sp"
#include "chaos/effects/nothing.sp"
#include "chaos/effects/randomizeweaponorder.sp"
#include "chaos/effects/removehealthandammo.sp"
#include "chaos/effects/removerandomentity.sp"
#include "chaos/effects/screenfade.sp"
#include "chaos/effects/screenoverlay.sp"
#include "chaos/effects/setattribute.sp"
#include "chaos/effects/setconvar.sp"
#include "chaos/effects/setcustommodel.sp"
#include "chaos/effects/setfov.sp"
#include "chaos/effects/sethealth.sp"
#include "chaos/effects/showscoreboard.sp"
#include "chaos/effects/silence.sp"
#include "chaos/effects/slap.sp"
#include "chaos/effects/spawnball.sp"
#include "chaos/effects/stepsize.sp"
#include "chaos/effects/truce.sp"
#include "chaos/effects/watermark.sp"
#include "chaos/effects/wheredideverythinggo.sp"

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
	sm_chaos_effect_cooldown = CreateConVar("sm_chaos_effect_cooldown", "50", "Default cooldown between effects.");
	sm_chaos_effect_interval = CreateConVar("sm_chaos_effect_interval", "45", "Interval between each effect activation, in seconds.");
	sm_chaos_meta_effect_interval = CreateConVar("sm_chaos_meta_effect_interval", "40", "Interval between each attempted meta effect activation, in seconds.");
	sm_chaos_meta_effect_chance = CreateConVar("sm_chaos_meta_effect_chance", ".025", "Chance for a meta effect to be activated every interval, in percent.");
	sm_chaos_effect_update_interval = CreateConVar("sm_chaos_effect_update_interval", ".1", "Interval at which effect update functions should be called, in seconds.");
	
	RegAdminCmd("sm_chaos_setnexteffect", ConCmd_SetNextEffect, ADMFLAG_CHEATS, "Sets the next effect.");
	RegAdminCmd("sm_chaos_forceeffect", ConCmd_ForceEffect, ADMFLAG_CHEATS, "Immediately forces an effect to start.");
	
	g_hEffects = new ArrayList(sizeof(ChaosEffect));
	g_hTimerBarHudSync = CreateHudSynchronizer();
	
	Events_Initialize();
	
	GameData hGameConf = new GameData("chaos");
	if (!hGameConf)
		LogError("Failed to find chaos gamedata");
	
	Data_Initialize(hGameConf);
	
	delete hGameConf;
}

public void OnPluginEnd()
{
	ExpireAllActiveEffects(true);
}

public void OnMapStart()
{
	g_flLastEffectDisplayTime = GetGameTime();
	
	// Initialize VScript system
	ServerCommand("script_execute %s", "chaos");
	
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
					hExecute.SetParamString(1, FIELD_CSTRING, effect.script_file);
					if (hExecute.Execute() != SCRIPT_ERROR)
					{
						float flUpdateInterval;
						if (hExecute.ReturnType == FIELD_VOID)
							flUpdateInterval = flDefaultUpdateInterval;
						else
							flUpdateInterval = float(hExecute.ReturnValue);
						
						delete hExecute;
						
						g_hEffects.Set(i, flCurTime + flUpdateInterval, ChaosEffect::next_script_update_time);
					}
				}
			}
		}
	}
	
	RoundState nRoundState = GameRules_GetRoundState();
	if (g_bNoChaos || nRoundState < RoundState_RoundRunning || nRoundState > RoundState_Stalemate || GameRules_GetProp("m_bInWaitingForPlayers"))
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
	if (g_flTimerBarDisplayTime && g_flTimerBarDisplayTime + 0.1 <= flCurTime)
	{
		g_flTimerBarDisplayTime = flCurTime;
		
		DisplayTimerBar();
	}
	
	// Activate a new effect
	if (g_flTimeElapsed >= sm_chaos_effect_interval.FloatValue)
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
	if (g_flMetaTimeElapsed >= sm_chaos_meta_effect_interval.FloatValue)
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
	
	SetChaosTimers(0.0);
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int itemDefIndex, Handle &item)
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
	Events_Toggle(bEnable);
	
	if (bEnable)
	{
		SetChaosTimers(GetGameTime());
	}
	else
	{
		SetChaosTimers(0.0);
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
		LogError("The effect '%T' (%s) is already active!", effect.name, LANG_SERVER, effect.id);
		return false;
	}
	
	if (!effect.IsCompatibleWithActiveEffects())
	{
		LogMessage("Skipped effect '%T' (%s) because it is incompatible with other active effects", effect.name, LANG_SERVER, effect.id);
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
			LogMessage("Skipped effect '%T' (%s) because its 'OnStart' callback returned false", effect.name, LANG_SERVER, effect.id);
			return false;
		}
	}
	
	if (effect.script_file[0])
	{
		VScriptExecute hExecute = new VScriptExecute(HSCRIPT_RootTable.GetValue("Chaos_StartEffect"));
		hExecute.SetParamString(1, FIELD_CSTRING, effect.script_file);
		hExecute.SetParam(2, FIELD_FLOAT, effect.duration);
		hExecute.Execute();
		bool bReturn = hExecute.ReturnValue;
		delete hExecute;
		
		if (!bReturn)
		{
			LogMessage("Skipped script file '%s' because its 'OnStart' callback returned false", effect.script_file);
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
	
	char szName[64];
	if (effect.GetName(szName, sizeof(szName)) && szName[0])
	{
		CPrintToChatAll("%s %t", PLUGIN_TAG, "#Chaos_Effect_Activated", szName);
	}
	
	// For effects that need to access modified properties
	fnCallback = effect.GetCallbackFunction("OnStartPost");
	if (fnCallback != INVALID_FUNCTION)
	{
		Call_StartFunction(null, fnCallback);
		Call_PushArray(effect, sizeof(effect));
		Call_Finish();
	}
	
	LogMessage("Activated effect '%T'", effect.name, LANG_SERVER);
	
	return true;
}

void DisplayTimerBar()
{
	SetHudTextParams(g_aTimerBarConfig.x, g_aTimerBarConfig.y, 0.1, g_aTimerBarConfig.color[0], g_aTimerBarConfig.color[1], g_aTimerBarConfig.color[2], g_aTimerBarConfig.color[3]);
	
	float flRatio = g_flTimeElapsed / sm_chaos_effect_interval.FloatValue;
	
	int iNumBlocks = g_aTimerBarConfig.num_blocks;
	int iFilledBlocks = RoundToNearest(flRatio * iNumBlocks);
	int iEmptyBlocks = iNumBlocks - iFilledBlocks;
	
	char szProgressBar[64];
	for (int i = 0; i < iFilledBlocks; i++)
	{
		StrCat(szProgressBar, sizeof(szProgressBar), g_aTimerBarConfig.filled);
	}
	for (int i = 0; i < iEmptyBlocks; i++)
	{
		StrCat(szProgressBar, sizeof(szProgressBar), g_aTimerBarConfig.empty);
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
				if (!effect.GetName(szName, sizeof(szName)) || !szName[0])
					continue;
				
				char szLine[128];
				
				// Expiring effects stay on screen while active
				if (effect.active)
				{
					float flEndTime = effect.activate_time + effect.current_duration;
					float flRatio = (GetGameTime() - effect.activate_time) / (flEndTime - effect.activate_time);
					
					int iNumBlocks = g_aEffectBarConfig.num_blocks;
					int iEmptyBlocks = RoundToNearest(flRatio * iNumBlocks);
					int iFilledBlocks = iNumBlocks - iEmptyBlocks;
					
					char szProgressBar[64];
					for (int j = 0; j < iFilledBlocks; j++)
					{
						StrCat(szProgressBar, sizeof(szProgressBar), g_aEffectBarConfig.filled);
					}
					for (int j = 0; j < iEmptyBlocks; j++)
					{
						StrCat(szProgressBar, sizeof(szProgressBar), g_aEffectBarConfig.empty);
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
			hExecute.SetParamString(1, FIELD_CSTRING, effect.script_file);
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
	int nLength = g_hEffects.Length;
	for (int i = 0; i < nLength; i++)
	{
		if (!g_hEffects.Get(i, ChaosEffect::active))
			continue;
		
		ChaosEffect effect;
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

void SetChaosTimers(float flTime)
{
	g_flTimeElapsed = 0.0;
	g_flMetaTimeElapsed = 0.0;
	g_flTimerBarDisplayTime = flTime;
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
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_chaos_setnexteffect <id>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, g_szForceEffectId, sizeof(g_szForceEffectId));
	
	int nIndex = g_hEffects.FindString(g_szForceEffectId);
	if (nIndex == -1)
	{
		ReplyToCommand(client, "%t", "#Chaos_Effect_SetNextEffect_Invalid", g_szForceEffectId);
	}
	else
	{
		ChaosEffect effect;
		if (g_hEffects.GetArray(nIndex, effect))
		{
			ReplyToCommand(client, "%t", "#Chaos_Effect_SetNextEffect_Done", effect.name);
		}
	}
	
	return Plugin_Handled;
}

static Action ConCmd_ForceEffect(int client, int args)
{
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
		ReplyToCommand(client, "%t", "#Chaos_Effect_SetNextEffect_Invalid", szEffectId);
	}
	else
	{
		ActivateEffectById(szEffectId, true);
	}
	
	return Plugin_Handled;
}
