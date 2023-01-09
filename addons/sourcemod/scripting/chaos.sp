#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ArrayList g_effects;
float g_flNextEffectActivateTime;

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

public void OnPluginStart()
{
	LoadTranslations("chaos.phrases");
	
	g_effects = new ArrayList(sizeof(ChaosEffect));
	
	sm_chaos_effect_cooldown = CreateConVar("sm_chaos_effect_cooldown", "8", "Default cooldown between effects.");
	sm_chaos_effect_interval = CreateConVar("sm_chaos_effect_interval", "30.0", "Interval between each effect activation.");
	
	ParseConfig();
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
	
	// Sort effects based on their cooldown
	g_effects.SortCustom(SortFuncADTArray_SortChaosEffectsByCooldown);
	
	// Go through all effects until we find a valid one 
	for (int i = 0; i < g_effects.Length; i++)
	{
		ChaosEffect effect;
		if (g_effects.GetArray(i, effect))
		{
			// Check if we can activate this effect
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
			
			PrintCenterTextAll("%t", "#Chaos_Effect_Activated", effect.name);
			
			callback = effect.GetCallbackFunction("OnStart");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_Finish();
			}
			
			// Set effect as active and set cooldown
			g_effects.Set(i, true, ChaosEffect::active);
			g_effects.Set(i, effect.cooldown, ChaosEffect::cooldown_left);
			CreateTimer(effect.duration, Timer_ExpireEffect, effect.id);
			
			// Lower cooldown of all other effects
			for (int j = 0; j < g_effects.Length; j++)
			{
				if (j == i)
					continue;
				
				g_effects.Set(j, g_effects.Get(j, ChaosEffect::cooldown_left) - 1, ChaosEffect::cooldown_left);
			}
			
			break;
		}
	}
}

static Action Timer_ExpireEffect(Handle timer, int id)
{
	int index = g_effects.FindValue(id, ChaosEffect::id);
	if (index == -1)
	{
		LogError("Failed to expire effect with id '%d'", id);
		return Plugin_Continue;
	}
	
	ChaosEffect effect;
	if (g_effects.GetArray(index, effect) && effect.active)
	{
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

public Action OnPlayerRunCmd(int client, int & buttons, int & impulse, float vel[3], float angles[3], int & weapon, int & subtype, int & cmdnum, int & tickcount, int & seed, int mouse[2])
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
