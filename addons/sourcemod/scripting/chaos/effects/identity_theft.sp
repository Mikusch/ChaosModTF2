#pragma semicolon 1
#pragma newdecls required

static Handle g_hSDKCallGiveNamedItem;

public bool IdentityTheft_Initialize(ChaosEffect effect)
{
	GameData gameconf;
	if (!Chaos_LoadGameData(gameconf))
		return false;

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "CTFPlayer::GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKCallGiveNamedItem = EndPrepSDKCall();
	delete gameconf;

	if (!g_hSDKCallGiveNamedItem)
	{
		LogError("Failed to create SDKCall for CTFPlayer::GiveNamedItem");
		return false;
	}

	return true;
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
	int death_flags = event.GetInt("death_flags");

	if (victim != attacker && (0 < attacker <= MaxClients) && !(death_flags & TF_DEATHFLAG_DEADRINGER))
	{
		TF2_SetPlayerClass(attacker, TF2_GetPlayerClass(victim), _, false);
		TF2_RegeneratePlayer(attacker);

		// Copy victim's model.
		char szCustomModel[PLATFORM_MAX_PATH];
		GetEntPropString(victim, Prop_Send, "m_iszCustomModel", szCustomModel, sizeof(szCustomModel));

		SetVariantString(szCustomModel);
		AcceptEntityInput(attacker, "SetCustomModel");

		SetEntProp(attacker, Prop_Send, "m_bUseClassAnimations", GetEntProp(victim, Prop_Send, "m_bUseClassAnimations"));
		SetEntProp(attacker, Prop_Send, "m_bCustomModelRotates", GetEntProp(victim, Prop_Send, "m_bCustomModelRotates"));
		SetEntProp(attacker, Prop_Send, "m_bCustomModelRotationSet", GetEntProp(victim, Prop_Send, "m_bCustomModelRotationSet"));
		SetEntProp(attacker, Prop_Send, "m_bCustomModelVisibleToSelf", GetEntProp(victim, Prop_Send, "m_bCustomModelVisibleToSelf"));

		float vecCustomModelOffset[3], angCustomModelRotation[3];
		GetEntPropVector(victim, Prop_Send, "m_vecCustomModelOffset", vecCustomModelOffset);
		SetEntPropVector(attacker, Prop_Send, "m_vecCustomModelOffset", vecCustomModelOffset);
		GetEntPropVector(victim, Prop_Send, "m_angCustomModelRotation", angCustomModelRotation);
		SetEntPropVector(attacker, Prop_Send, "m_angCustomModelRotation", angCustomModelRotation);

		// Nuke items.
		int nMaxWeapons = GetEntPropArraySize(attacker, Prop_Data, "m_hMyWeapons");
		for (int i = 0; i < nMaxWeapons; i++)
		{
			int weapon = GetEntPropEnt(attacker, Prop_Data, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;
			
			if (TF2Util_GetWeaponID(weapon) == TF_WEAPON_BUILDER)
				continue;

			RemovePlayerItem(attacker, weapon);
			RemoveEntity(weapon);
		}

		// Nuke wearables.
		for (int wbl = TF2Util_GetPlayerWearableCount(attacker) - 1; wbl >= 0; wbl--)
		{
			int wearable = TF2Util_GetPlayerWearable(attacker, wbl);
			if (wearable == -1)
				continue;

			TF2_RemoveWearable(attacker, wearable);
		}

		// Copy victim's weapons.
		for (int i = 0; i < GetEntPropArraySize(victim, Prop_Data, "m_hMyWeapons"); i++)
		{
			int weapon = GetEntPropEnt(victim, Prop_Data, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;

			int iItemOffset = FindItemOffset(weapon);
			if (iItemOffset == -1)
				continue;
			
			Address pItem = GetEntityAddress(weapon) + view_as<Address>(iItemOffset);
			if (!pItem)
				continue;
			
			char szClassname[64];
			if (!GetEntityClassname(weapon, szClassname, sizeof(szClassname)))
				continue;
			
			TF2Econ_TranslateWeaponEntForClass(szClassname, sizeof(szClassname), TF2_GetPlayerClass(attacker));

			int newItem = SDKCall(g_hSDKCallGiveNamedItem, attacker, szClassname, 0, pItem, true);
			if (newItem == -1)
				continue;
			
			SetEntProp(newItem, Prop_Send, "m_bValidatedAttachedEntity", true);
			EquipPlayerWeapon(attacker, newItem);
			
			// Switch to our victim's active weapon.
			if (weapon == GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon"))
			{
				TF2Util_SetPlayerActiveWeapon(attacker, newItem);
			}
		}
		
		// Copy victim's wearables.
		for (int wbl = TF2Util_GetPlayerWearableCount(victim) - 1; wbl >= 0; wbl--)
		{
			int wearable = TF2Util_GetPlayerWearable(victim, wbl);
			if (wearable == -1)
				continue;
			
			int iItemOffset = FindItemOffset(wearable);
			if (iItemOffset == -1)
				continue;
			
			Address pItem = GetEntityAddress(wearable) + view_as<Address>(iItemOffset);
			if (!pItem)
				continue;
			
			char szClassname[64];
			if (!GetEntityClassname(wearable, szClassname, sizeof(szClassname)))
				continue;

			TF2Econ_TranslateWeaponEntForClass(szClassname, sizeof(szClassname), TF2_GetPlayerClass(attacker));
			
			int newItem = SDKCall(g_hSDKCallGiveNamedItem, attacker, szClassname, 0, pItem, true);
			if (newItem == -1)
				continue;
			
			SetEntProp(newItem, Prop_Send, "m_bValidatedAttachedEntity", true);
			TF2Util_EquipPlayerWearable(attacker, newItem);
		}
	}
}
