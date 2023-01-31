#pragma semicolon 1
#pragma newdecls required

public bool GiveItem_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		AddItemsFromData(client, effect.data);
	}
	
	return true;
}

static void AddItemsFromData(int client, KeyValues kv)
{
	if (kv.JumpToKey("items", false))
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				char szItemName[64];
				kv.GetString("name", szItemName, sizeof(szItemName));
				
				int item = AddItem(client, szItemName);
				if (!IsValidEntity(item))
					continue;
				
				AddAttributesFromData(item, kv);
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
}

static void AddAttributesFromData(int item, KeyValues kv)
{
	if (kv.JumpToKey("attributes", false))
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				char szAttrib[64];
				if (kv.GetSectionName(szAttrib, sizeof(szAttrib)))
				{
					float flValue = kv.GetFloat(NULL_STRING);
					TF2Attrib_SetByName(item, szAttrib, flValue);
				}
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
}

static int AddItem(int client, const char[] szItemName)
{
	int iItemDefIndex = GetItemDefinitionIndexByName(szItemName);
	if (iItemDefIndex != TF_ITEMDEF_DEFAULT)
	{
		// If we already have an item in that slot, remove it
		TFClassType nClass = TF2_GetPlayerClass(client);
		int iSlot = TF2Econ_GetItemLoadoutSlot(iItemDefIndex, nClass);
		int nNewItemRegionMask = TF2Econ_GetItemEquipRegionMask(iItemDefIndex);
		
		if (IsWearableSlot(iSlot))
		{
			// Remove any wearable that has a conflicting equip_region
			for (int wbl = 0; wbl < TF2Util_GetPlayerWearableCount(client); wbl++)
			{
				int wearable = TF2Util_GetPlayerWearable(client, wbl);
				if (wearable == -1)
					continue;
				
				int iWearableDefIndex = GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex");
				if (iWearableDefIndex == 0xFFFF)
					continue;
				
				int nWearableRegionMask = TF2Econ_GetItemEquipRegionMask(iWearableDefIndex);
				if (nWearableRegionMask & nNewItemRegionMask)
				{
					TF2_RemoveWearable(client, wearable);
				}
			}
		}
		else
		{
			int entity = TF2Util_GetPlayerLoadoutEntity(client, iSlot);
			if (entity != -1)
			{
				RemovePlayerItem(client, entity);
				RemoveEntity(entity);
			}
		}
		
		Handle hItem = TF2Items_CreateItem(PRESERVE_ATTRIBUTES | FORCE_GENERATION);
		
		char szClassname[64];
		TF2Econ_GetItemClassName(iItemDefIndex, szClassname, sizeof(szClassname));
		TF2Econ_TranslateWeaponEntForClass(szClassname, sizeof(szClassname), nClass);
		
		TF2Items_SetClassname(hItem, szClassname);
		TF2Items_SetItemIndex(hItem, iItemDefIndex);
		
		int newItem = TF2Items_GiveNamedItem(client, hItem);
		if (newItem != -1)
		{
			if (TF2Util_IsEntityWearable(newItem))
			{
				TF2Util_EquipPlayerWearable(client, newItem);
			}
			else if (TF2Util_IsEntityWeapon(newItem))
			{
				EquipPlayerWeapon(client, newItem);
			}
		}
		
		SetEntProp(newItem, Prop_Send, "m_bValidatedAttachedEntity", true);
		
		SDKCall_PostInventoryApplication(client);
		
		delete hItem;
		return newItem;
	}
	else
	{
		if (szItemName[0])
		{
			LogError("GiveItem: Invalid item %s.", szItemName);
		}
	}
	
	return -1;
}
