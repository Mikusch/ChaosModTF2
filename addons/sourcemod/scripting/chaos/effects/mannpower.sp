#pragma semicolon 1
#pragma newdecls required

static TFCond g_aPowerupConds[] =
{
	TFCond_RuneStrength,
	TFCond_RuneHaste,
	TFCond_RuneRegen,
	TFCond_RuneRegen,
	TFCond_RuneVampire,
	TFCond_RuneRegen,
	TFCond_RunePrecision,
	TFCond_RuneAgility,
	TFCond_RuneKnockout,
	TFCond_KingRune,
	TFCond_PlagueRune,
	TFCond_SupernovaRune,
};

static ConVar tf_grapplinghook_enable;

public bool Mannpower_Initialize(ChaosEffect effect, GameData gameconf)
{
	tf_grapplinghook_enable = FindConVar("tf_grapplinghook_enable");
	
	return true;
}

public bool Mannpower_OnStart(ChaosEffect effect)
{
	// Don't do this effect in powerup mode
	if (GameRules_GetProp("m_bPowerupMode"))
		return false;
	
	tf_grapplinghook_enable.BoolValue = true;
	GameRules_SetProp("m_bPowerupMode", true);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2_AddCondition(client, g_aPowerupConds[GetRandomInt(0, sizeof(g_aPowerupConds) - 1)]);
	}
	
	return true;
}

public void Mannpower_OnEnd(ChaosEffect effect)
{
	GameRules_SetProp("m_bPowerupMode", false);
	tf_grapplinghook_enable.BoolValue = false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		for (int i = 0; i < sizeof(g_aPowerupConds); i++)
		{
			TF2_RemoveCondition(client, g_aPowerupConds[i]);
		}
	}
	
	int rune = -1;
	while ((rune = FindEntityByClassname(rune, "item_powerup_rune*")) != -1)
	{
		RemoveEntity(rune);
	}
}
