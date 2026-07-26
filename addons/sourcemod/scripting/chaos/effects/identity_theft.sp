#pragma semicolon 1
#pragma newdecls required

public bool IdentityTheft_Initialize(ChaosEffect effect)
{
	return SDKCalls_CanGetWeaponID() && SDKCalls_CanEquipWearable() && SDKCalls_CanGiveNamedItem();
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
			
			if (GetWeaponID(weapon) == TF_WEAPON_BUILDER)
				continue;

			RemovePlayerItem(attacker, weapon);
			RemoveEntity(weapon);
		}

		// Nuke wearables.
		ArrayList hAttackerWearables = GetWearables(attacker);
		for (int wbl = 0; wbl < hAttackerWearables.Length; wbl++)
		{
			TF2_RemoveWearable(attacker, hAttackerWearables.Get(wbl));
		}
		delete hAttackerWearables;

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

			int newItem = GiveNamedItem(attacker, szClassname, 0, pItem, true);
			if (newItem == -1)
				continue;
			
			SetEntProp(newItem, Prop_Send, "m_bValidatedAttachedEntity", true);
			EquipPlayerWeapon(attacker, newItem);
			
			// Switch to our victim's active weapon.
			if (weapon == GetEntPropEnt(victim, Prop_Send, "m_hActiveWeapon"))
			{
				SetPlayerActiveWeapon(attacker, newItem);
			}
		}
		
		// Copy victim's wearables.
		ArrayList hVictimWearables = GetWearables(victim);
		for (int wbl = 0; wbl < hVictimWearables.Length; wbl++)
		{
			int wearable = hVictimWearables.Get(wbl);

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
			
			int newItem = GiveNamedItem(attacker, szClassname, 0, pItem, true);
			if (newItem == -1)
				continue;
			
			SetEntProp(newItem, Prop_Send, "m_bValidatedAttachedEntity", true);
			EquipPlayerWearable(attacker, newItem);
		}
		delete hVictimWearables;
	}
}
