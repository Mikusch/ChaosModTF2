#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ArrayList g_effects;
float g_flNextEffectActivateTime;
int g_iForceEffectId;

ConVar sm_chaos_effect_cooldown;
ConVar sm_chaos_effect_interval;

#include "chaos/data.sp"
#include "chaos/shareddefs.sp"
#include "chaos/util.sp"

#include "chaos/effects/effect_reversecontrols.sp"
#include "chaos/effects/effect_icephysics.sp"
#include "chaos/effects/effect_slowmotion.sp"
#include "chaos/effects/effect_killrandomplayer.sp"
#include "chaos/effects/effect_friendlyfire.sp"
#include "chaos/effects/effect_invertgravity.sp"
#include "chaos/effects/effect_truce.sp"
#include "chaos/effects/effect_wheredideverythinggo.sp"

public void OnPluginStart()
{
	LoadTranslations("chaos.phrases");
	
	g_effects = new ArrayList(sizeof(ChaosEffect));
	
	sm_chaos_effect_cooldown = CreateConVar("sm_chaos_effect_cooldown", "8", "Default cooldown between effects.");
	sm_chaos_effect_interval = CreateConVar("sm_chaos_effect_interval", "30.0", "Interval between each effect activation.");
	
	RegAdminCmd("sm_chaos_forceeffect", ConCmd_ForceEffect, ADMFLAG_CHEATS);
	
	ParseConfig();
}

public Action ConCmd_ForceEffect(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_chaos_forceeffect <id>");
		return Plugin_Handled;
	}
	
	int id = GetCmdArgInt(1);
	
	int index = g_effects.FindValue(id, ChaosEffect::id);
	if (index == -1)
	{
		ReplyToCommand(client, "Invalid effect id '%d'", id);
		return Plugin_Handled;
	}
	
	ChaosEffect effect;
	if (g_effects.GetArray(index, effect))
	{
		g_iForceEffectId = effect.id;
		ReplyToCommand(client, "The next effect will be '%t'", effect.name);
	}
	
	return Plugin_Handled;
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
				Call_Finish();
			}
		}
	}
}

public void OnMapStart()
{
	g_flNextEffectActivateTime = 0.0;
	g_iForceEffectId = -1;
	
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect))
		{
			Function callback = effect.GetCallbackFunction("OnMapStart");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_Finish();
			}
		}
	}
}

public void OnGameFrame()
{
	if (GameRules_GetProp("m_bInWaitingForPlayers"))
		return;
	
	if (g_flNextEffectActivateTime > GetGameTime())
		return;
	
	g_flNextEffectActivateTime = GetGameTime() + sm_chaos_effect_interval.FloatValue;
	
	if (g_iForceEffectId == INVALID_EFFECT_ID)
	{
		SelectRandomEffect();
	}
	else
	{
		int index = g_effects.FindValue(g_iForceEffectId, ChaosEffect::id);
		
		ChaosEffect effect;
		if (g_effects.GetArray(index, effect))
		{
			StartEffect(effect);
		}
		
		g_iForceEffectId = INVALID_EFFECT_ID;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	Action action = Plugin_Continue;
	
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect))
		{
			if (!effect.active)
				continue;
			
			Function callback = effect.GetCallbackFunction("OnPlayerRunCmd");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
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
			
			// Run CanActivate callback and skip effects returning false
			Function callback = effect.GetCallbackFunction("CanActivate");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				
				bool ret;
				if (Call_Finish(ret) == SP_ERROR_NONE && !ret)
				{
					continue;
				}
			}
			
			StartEffect(effect);
			break;
		}
	}
}

void StartEffect(ChaosEffect effect)
{
	int index = g_effects.FindValue(effect.id, ChaosEffect::id);
	if (index == -1)
	{
		LogError("Failed to start unknown effect with id '%d'", effect.id);
		return;
	}
	
	PrintCenterTextAll("%t", "#Chaos_Effect_Activated", effect.name);
	
	// Run OnStart callback (if the effect wasn't already active)
	if (!effect.active)
	{
		Function callback = effect.GetCallbackFunction("OnStart");
		if (callback != INVALID_FUNCTION)
		{
			Call_StartFunction(null, callback);
			Call_Finish();
		}
	}
	
	// Set new effect as active and put on cooldown
	effect.active = true;
	effect.cooldown_left = effect.cooldown;
	effect.activate_time = GetGameTime();
	effect.timer = CreateTimer(effect.duration, Timer_ExpireEffect, effect.id);
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
		if (effect.timer != timer)
		{
			LogMessage("Failed to expire effect '%T' because another expiry timer was created", effect.name, LANG_SERVER);
			return Plugin_Continue;
		}
		
		if (!effect.active)
		{
			LogError("Failed to expire already inactive effect '%T'", effect.name, LANG_SERVER);
			return Plugin_Continue;
		}
		
		Function callback = effect.GetCallbackFunction("OnEnd");
		if (callback != INVALID_FUNCTION)
		{
			Call_StartFunction(null, callback);
			Call_Finish();
		}
		
		g_effects.Set(index, false, ChaosEffect::active);
	}
	
	return Plugin_Continue;
}
