#pragma semicolon 1
#pragma newdecls required

static Handle g_hSDKCallBotMirrorPlayerClassAndItems;

public bool IdentityTheft_Initialize(ChaosEffect effect)
{
	GameData gameconf = new GameData("chaos/identitytheft");
	if (!gameconf)
		return false;

	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "BotMirrorPlayerClassAndItems");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKCallBotMirrorPlayerClassAndItems = EndPrepSDKCall();

	delete gameconf;

	return g_hSDKCallBotMirrorPlayerClassAndItems;
}

public bool IdentityTheft_OnStart(ChaosEffect effect)
{
	HookEvent("player_death", OnPlayerDeath);
	
	return true;
}

public void IdentityTheft_OnEnd(ChaosEffect effect)
{
	UnhookEvent("player_death", OnPlayerDeath);
}

static void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int death_flags = GetClientOfUserId(event.GetInt("death_flags"));

	if (victim != attacker && (0 < attacker <= MaxClients) && !(death_flags & TF_DEATHFLAG_DEADRINGER))
	{
		TF2_SetPlayerClass(attacker, TF2_GetPlayerClass(victim), _, false);

		RemoveAllItems(attacker);

		// This works because CTFBot extends CTFPlayer
		SDKCall(g_hSDKCallBotMirrorPlayerClassAndItems, attacker, victim);
	}
}
