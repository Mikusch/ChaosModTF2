#pragma semicolon 1
#pragma newdecls required

static Handle g_SDKCallGiveNamedItem;
static Handle g_hSDKCallPostInventoryApplication;
static Handle g_hSDKCallGetSubType;

public bool IdentityTheft_Initialize(ChaosEffect effect)
{
	GameData gameconf = new GameData("chaos/identitytheft");
	if (!gameconf)
		return false;

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "CTFPlayer::GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_SDKCallGiveNamedItem = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "CTFPlayer::PostInventoryApplication");
	g_hSDKCallPostInventoryApplication = EndPrepSDKCall();

	delete gameconf;

	VScriptFunction hScriptGetSubType = VScript_GetClassFunction("CBaseCombatWeapon", "GetSubType");
	if (hScriptGetSubType)
		g_hSDKCallGetSubType = hScriptGetSubType.CreateSDKCall();

	return g_SDKCallGiveNamedItem && g_hSDKCallPostInventoryApplication && g_hSDKCallGetSubType;
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
	
	if (victim != attacker && 0 < attacker <= MaxClients && !(death_flags & TF_DEATHFLAG_DEADRINGER))
	{
		TF2_SetPlayerClass(attacker, TF2_GetPlayerClass(victim), _, false);
		
		// Remove attacker's weapons
		for (int i = 0; i < GetEntPropArraySize(attacker, Prop_Data, "m_hMyWeapons"); i++)
		{
			int weapon = GetEntPropEnt(attacker, Prop_Data, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;
			
			RemovePlayerItem(attacker, weapon);
			RemoveEntity(weapon);
		}
		
		// Remove attacker's wearables
		for (int wbl = TF2Util_GetPlayerWearableCount(attacker) - 1; wbl >= 0; wbl--)
		{
			int wearable = TF2Util_GetPlayerWearable(attacker, wbl);
			if (wearable == -1)
				continue;
			
			TF2_RemoveWearable(attacker, wearable);
		}
		
		// Copy victim's weapons
		for (int i = 0; i < GetEntPropArraySize(victim, Prop_Data, "m_hMyWeapons"); i++)
		{
			int weapon = GetEntPropEnt(victim, Prop_Data, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;
			
			Address pItem = GetEntityAddress(weapon) + view_as<Address>(FindItemOffset(weapon));
			if (!pItem)
				continue;
			
			char szClassname[64];
			if (!GetEntityClassname(weapon, szClassname, sizeof(szClassname)))
				continue;
			
			int newItem = SDKCall(g_SDKCallGiveNamedItem, attacker, szClassname, SDKCall(g_hSDKCallGetSubType, weapon), pItem, true);
			if (newItem == -1)
				continue;
			
			SetEntProp(newItem, Prop_Send, "m_bValidatedAttachedEntity", true);
			EquipPlayerWeapon(attacker, newItem);
			
			// Switch to our victim's active weapon
			if (GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon") == weapon)
			{
				TF2Util_SetPlayerActiveWeapon(attacker, newItem);
			}
		}
		
		// Copy victim's wearables
		for (int wbl = TF2Util_GetPlayerWearableCount(victim) - 1; wbl >= 0; wbl--)
		{
			int wearable = TF2Util_GetPlayerWearable(victim, wbl);
			if (wearable == -1)
				continue;
			
			Address pItem = GetEntityAddress(wearable) + view_as<Address>(FindItemOffset(wearable));
			if (!pItem)
				continue;
			
			char szClassname[64];
			if (!GetEntityClassname(wearable, szClassname, sizeof(szClassname)))
				continue;
			
			int newItem = SDKCall(g_SDKCallGiveNamedItem, attacker, szClassname, 0, pItem, true);
			if (newItem == -1)
				continue;
			
			SetEntProp(newItem, Prop_Send, "m_bValidatedAttachedEntity", true);
			TF2Util_EquipPlayerWearable(attacker, newItem);
		}
		
		SDKCall(g_hSDKCallPostInventoryApplication, attacker);
	}
}
