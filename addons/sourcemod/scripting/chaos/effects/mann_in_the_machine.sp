#pragma semicolon 1
#pragma newdecls required

static char g_szBotModels[][] =
{
	"", //TF_CLASS_UNDEFINED
	
	"models/bots/scout/bot_scout.mdl",
	"models/bots/sniper/bot_sniper.mdl",
	"models/bots/soldier/bot_soldier.mdl",
	"models/bots/demo/bot_demo.mdl",
	"models/bots/medic/bot_medic.mdl",
	"models/bots/heavy/bot_heavy.mdl",
	"models/bots/pyro/bot_pyro.mdl",
	"models/bots/spy/bot_spy.mdl",
	"models/bots/engineer/bot_engineer.mdl"
};

static char g_szBotBossModels[][] =
{
	"", //TF_CLASS_UNDEFINED
	
	"models/bots/scout_boss/bot_scout_boss.mdl",
	"models/bots/sniper/bot_sniper.mdl",
	"models/bots/soldier_boss/bot_soldier_boss.mdl",
	"models/bots/demo_boss/bot_demo_boss.mdl",
	"models/bots/medic/bot_medic.mdl",
	"models/bots/heavy_boss/bot_heavy_boss.mdl",
	"models/bots/pyro_boss/bot_pyro_boss.mdl",
	"models/bots/spy/bot_spy.mdl",
	"models/bots/engineer/bot_engineer.mdl"
};

static char g_szBotClassNames[][] =
{
	"", //TF_CLASS_UNDEFINED
	
	"scout",
	"sniper",
	"soldier",
	"demoman",
	"medic",
	"heavy",
	"pyro",
	"spy",
	"engineer"
};

public void MannInTheMachine_OnMapStart(ChaosEffect effect)
{
	PrecacheScriptSound("MVM.BotStep");
	PrecacheScriptSound("MVM.FallDamageBots");
	PrecacheScriptSound("MVM.GiantHeavyExplodes");
	PrecacheScriptSound("MVM.GiantCommonExplodes");
}

public bool MannInTheMachine_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidRobotPlayer(client))
			continue;
		
		SetRobotModel(client);
	}
	
	AddNormalSoundHook(OnNormalSoundPlayed);
	HookEvent("player_death", OnPlayerDeath);
	
	return true;
}

public void MannInTheMachine_OnPlayerSpawn(ChaosEffect effect, int client)
{
	if (!IsValidRobotPlayer(client))
		return;
	
	SetRobotModel(client);
}

public void MannInTheMachine_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidRobotPlayer(client))
			continue;
		
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
	}
	
	RemoveNormalSoundHook(OnNormalSoundPlayed);
	UnhookEvent("player_death", OnPlayerDeath);
}

static Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (!IsValidRobotPlayer(entity))
		return Plugin_Continue;
	
	TFClassType nClass = TF2_GetPlayerClass(entity);
	
	if (!strncmp(sample, "vo/", 3))
	{
		char szClassMvM[32];
		if (GetEntProp(entity, Prop_Send, "m_bIsMiniBoss") && nClass != TFClass_Sniper && nClass != TFClass_Engineer && nClass != TFClass_Medic && nClass != TFClass_Spy)
		{
			ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/mght/", false);
			Format(szClassMvM, sizeof(szClassMvM), "%s_mvm_m", g_szBotClassNames[view_as<int>(nClass)]);
		}
		else
		{
			ReplaceString(sample, sizeof(sample), "vo/", "vo/mvm/norm/", false);
			Format(szClassMvM, sizeof(szClassMvM), "%s_mvm", g_szBotClassNames[view_as<int>(nClass)]);
		}
		
		ReplaceString(sample, sizeof(sample), g_szBotClassNames[view_as<int>(nClass)], szClassMvM);
		
		char szSoundPath[PLATFORM_MAX_PATH];
		Format(szSoundPath, sizeof(szSoundPath), "sound/%s", sample);
		
		if (FileExists(szSoundPath, true))
		{
			PrecacheSound(sample);
			return Plugin_Changed;
		}
	}
	else if (!strncmp(sample, "player/footsteps/", 17) && !GetEntProp(entity, Prop_Send, "m_bIsMiniBoss") && !TF2_IsPlayerInCondition(entity, TFCond_Disguised))
	{
		if (nClass != TFClass_Medic)
		{
			EmitGameSoundToAll("MVM.BotStep", entity, flags);
		}
		
		return Plugin_Stop;
	}
	else if (!strncmp(sample, "player/pl_fallpain.wav", 22))
	{
		EmitGameSoundToAll("MVM.FallDamageBots", entity, flags);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

static bool IsValidRobotPlayer(int client)
{
	return (0 < client <= MaxClients) && IsClientInGame(client) && TF2_GetPlayerClass(client) > TFClass_Unknown && (!GameRules_GetProp("m_bPlayingMannVsMachine") || !(GetEntityFlags(client) & FL_FAKECLIENT));
}

static void SetRobotModel(int client)
{
	TFClassType nClass = TF2_GetPlayerClass(client);
	SetVariantString(GetEntProp(client, Prop_Send, "m_bIsMiniBoss") ? g_szBotBossModels[nClass] : g_szBotModels[nClass]);
	AcceptEntityInput(client, "SetCustomModelWithClassAnimations");
}

static void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	if (!IsValidRobotPlayer(victim))
		return;
	
	if (GetEntProp(victim, Prop_Send, "m_bIsMiniBoss"))
	{
		TFClassType nClass = TF2_GetPlayerClass(victim);
		switch (nClass)
		{
			case TFClass_Heavy:
			{
				EmitGameSoundToAll("MVM.GiantHeavyExplodes");
			}
			default:
			{
				EmitGameSoundToAll("MVM.GiantCommonExplodes");
			}
		}
	}
}
