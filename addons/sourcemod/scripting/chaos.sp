#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2attributes>
#include <tf2_stocks>
#include <tf2items>
#include <tf2utils>

ArrayList g_effects;
float g_flNextEffectActivateTime;
float g_flNextEffectDisplayTime;

ConVar sm_chaos_effect_cooldown;
ConVar sm_chaos_effect_interval;
ConVar sm_chaos_force_effect;

#include "chaos/data.sp"
#include "chaos/events.sp"
#include "chaos/sdkcalls.sp"
#include "chaos/shareddefs.sp"
#include "chaos/util.sp"

#include "chaos/effects/effect_setconvar.sp"
#include "chaos/effects/effect_setattribute.sp"
#include "chaos/effects/effect_addcond.sp"

#include "chaos/effects/effect_reversecontrols.sp"
#include "chaos/effects/effect_slowmotion.sp"
#include "chaos/effects/effect_killrandomplayer.sp"
#include "chaos/effects/effect_invertgravity.sp"
#include "chaos/effects/effect_truce.sp"
#include "chaos/effects/effect_wheredideverythinggo.sp"
#include "chaos/effects/effect_eternalscreams.sp"
#include "chaos/effects/effect_seteveryoneto1hp.sp"
#include "chaos/effects/effect_watermark.sp"
#include "chaos/effects/effect_thriller.sp"
#include "chaos/effects/effect_showscoreboard.sp"
#include "chaos/effects/effect_fov.sp"
#include "chaos/effects/effect_silence.sp"
#include "chaos/effects/effect_removewearables.sp"

public void OnPluginStart()
{
	LoadTranslations("chaos.phrases");
	
	AddNormalSoundHook(NormalSHook_OnSoundPlayed);
	
	g_effects = new ArrayList(sizeof(ChaosEffect));
	
	sm_chaos_effect_cooldown = CreateConVar("sm_chaos_effect_cooldown", "8", "Default cooldown between effects.");
	sm_chaos_effect_interval = CreateConVar("sm_chaos_effect_interval", "30.0", "Interval between each effect activation.");
	sm_chaos_force_effect = CreateConVar("sm_chaos_force_effect", "-1", "ID of the effect to force.");
	
	Events_Initialize();
	ParseConfig();
	
	GameData gamedata = new GameData("chaos");
	if (gamedata)
	{
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
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect) && effect.active)
		{
			Function callback = effect.GetCallbackFunction("OnEnd");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}
		}
	}
}

public void OnMapStart()
{
	g_flNextEffectActivateTime = 0.0;
	g_flNextEffectDisplayTime = 0.0;
	
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect))
		{
			Function callback = effect.GetCallbackFunction("OnMapStart");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(effect, sizeof(effect));
				Call_Finish();
			}
		}
	}
}

public void OnGameFrame()
{
	if (GameRules_GetRoundState() <= RoundState_Preround || GameRules_GetProp("m_bInWaitingForPlayers"))
		return;
	
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect) && effect.active)
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
	
	// Show all active effects in HUD
	if (g_flNextEffectDisplayTime <= GetGameTime())
	{
		g_flNextEffectDisplayTime = GetGameTime() + 0.1;
		
		DisplayActiveEffects();
	}
	
	// Activate a new effect
	if (g_flNextEffectActivateTime <= GetGameTime())
	{
		g_flNextEffectActivateTime = GetGameTime() + sm_chaos_effect_interval.FloatValue;
		
		int iForceId = sm_chaos_force_effect.IntValue;
		if (iForceId == INVALID_EFFECT_ID)
		{
			SelectRandomEffect();
		}
		else
		{
			
			int index = g_effects.FindValue(iForceId, ChaosEffect::id);
			if (index == -1)
			{
				LogError("Failed to force unknown effect '%d'", iForceId);
				return;
			}
			
			ChaosEffect effect;
			if (g_effects.GetArray(index, effect))
			{
				StartEffect(effect);
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect) && effect.active)
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
	
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect) && effect.active)
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

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect) && effect.active)
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

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int itemDefIndex, Handle &item)
{
	Action action = Plugin_Continue;
	
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect) && effect.active)
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

void SelectRandomEffect()
{
	// Sort effects based on their cooldown
	g_effects.SortCustom(SortFuncADTArray_SortChaosEffectsByCooldown);
	
	// Go through all effects until we find a valid one 
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect))
		{
			// Skip already activate effects or effects still on cooldown
			if (effect.active || effect.cooldown_left > 0)
				continue;
			
			if (StartEffect(effect))
				break;
		}
	}
}

bool StartEffect(ChaosEffect effect)
{
	int index = g_effects.FindValue(effect.id, ChaosEffect::id);
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
		
		// If OnStart returned false, do not start the effect
		bool bReturn;
		if (Call_Finish(bReturn) != SP_ERROR_NONE || !bReturn)
		{
			LogMessage("Failed to start effect '%T'", effect.name, LANG_SERVER);
			return false;
		}
	}
	
	PrintCenterTextAll("%t", "#Chaos_Effect_Activated", effect.name);
	
	// One-shot effects are never set to active state
	if (effect.duration)
	{
		effect.active = true;
		effect.timer = CreateTimer(effect.duration, Timer_ExpireEffect, effect.id);
	}
	
	effect.cooldown_left = effect.cooldown;
	effect.activate_time = GetGameTime();
	
	g_effects.SetArray(index, effect);
	
	// Lower cooldown of all other effects
	for (int j = 0; j < g_effects.Length; j++)
	{
		if (g_effects.Get(j, ChaosEffect::id) == effect.id)
			continue;
		
		// Never lower cooldown below 0
		int cooldown = Max(0, g_effects.Get(j, ChaosEffect::cooldown_left) - 1);
		g_effects.Set(j, cooldown, ChaosEffect::cooldown_left);
	}
	
	return true;
}

Action Timer_ExpireEffect(Handle timer, int id)
{
	int index = g_effects.FindValue(id, ChaosEffect::id);
	if (index == -1)
	{
		LogError("Failed to expire unknown effect with id '%d'", id);
		return Plugin_Continue;
	}
	
	ChaosEffect effect;
	if (g_effects.GetArray(index, effect))
	{
		// Time was extended, this is valid
		if (effect.timer != timer)
			return Plugin_Continue;
		
		if (!effect.active)
		{
			LogError("Failed to expire already inactive effect '%T'", effect.name, LANG_SERVER);
			return Plugin_Continue;
		}
		
		Function callback = effect.GetCallbackFunction("OnEnd");
		if (callback != INVALID_FUNCTION)
		{
			Call_StartFunction(null, callback);
			Call_PushArray(effect, sizeof(effect));
			Call_Finish();
		}
		
		effect.active = false;
		effect.timer = null;
		g_effects.SetArray(index, effect);
	}
	
	return Plugin_Continue;
}

void DisplayActiveEffects()
{
	// Sort effects based on their cooldown
	g_effects.SortCustom(SortFuncADTArray_SortChaosEffectsByActivationTime);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		char szMessage[MAX_USER_MSG_DATA - 1];
		
		// Go through all effects until we find a valid one 
		for (int i = 0; i < g_effects.Length; i++)
		{
			ChaosEffect effect;
			if (g_effects.GetArray(i, effect))
			{
				char szLine[64];
				
				// Expiring effects stay on screen while active
				if (effect.active)
				{
					float flEndTime = effect.activate_time + effect.duration;
					float flRatio = (GetGameTime() - effect.activate_time) / (flEndTime - effect.activate_time);
					
					char meter[64];
					for (int j = 0; j <= 100; j += 10)
					{
						if (flRatio * 100 >= j)
						{
							Format(meter, sizeof(meter), "%s▒", meter);
						}
						else
						{
							Format(meter, sizeof(meter), "█%s", meter);
						}
					}
					
					Format(szLine, sizeof(szLine), "%T %s", effect.name, client, meter);
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

static Action NormalSHook_OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	Action action = Plugin_Continue;
	
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect) && effect.active)
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
