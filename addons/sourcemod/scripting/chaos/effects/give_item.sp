#pragma semicolon 1
#pragma newdecls required

public bool GiveItem_Initialize(ChaosEffect effect)
{
	return SDKCalls_CanEquipWearable() && SDKCalls_CanPostInventoryApplication();
}

public bool GiveItem_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		if (!IsPlayerAlive(client))
			continue;

		AddItemsFromData(client, kv);
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
				int newItem = AddItem(client, kv);
				if (newItem == -1)
					continue;
				
				AddAttributesFromData(newItem, kv);
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
}

static int AddItem(int client, KeyValues kv)
{
	char szItemName[64];
	if (!kv.GetSectionName(szItemName, sizeof(szItemName)))
		return -1;

	int iItemDefIndex = GetItemDefinitionIndexByName(szItemName);
	int iQuality = kv.GetNum("quality", 0);
	int iLevel = kv.GetNum("level", 1);
	
	if (iItemDefIndex != TF_ITEMDEF_DEFAULT)
	{
		// If we already have an item in that slot, remove it
		TFClassType iClass = TF2_GetPlayerClass(client);
		int iSlot = TF2Econ_GetItemLoadoutSlot(iItemDefIndex, iClass);
		int nNewItemRegionMask = TF2Econ_GetItemEquipRegionMask(iItemDefIndex);
		
		if (IsWearableSlot(iSlot))
		{
			// Remove any wearable that has a conflicting equip_region
			ArrayList hWearables = GetWearables(client);
			for (int wbl = 0; wbl < hWearables.Length; wbl++)
			{
				int wearable = hWearables.Get(wbl);

				if (!GetEntProp(wearable, Prop_Send, "m_bInitialized"))
					continue;

				int nWearableRegionMask = TF2Econ_GetItemEquipRegionMask(GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex"));
				if (nWearableRegionMask & nNewItemRegionMask)
				{
					TF2_RemoveWearable(client, wearable);
				}
			}
			delete hWearables;
		}
		else
		{
			int entity = GetPlayerLoadoutEntity(client, iSlot);
			if (entity != -1)
			{
				RemovePlayerItem(client, entity);
				RemoveEntity(entity);
			}
		}
		
		Handle hItem = TF2Items_CreateItem(PRESERVE_ATTRIBUTES | FORCE_GENERATION);
		
		char szClassname[64];
		TF2Econ_GetItemClassName(iItemDefIndex, szClassname, sizeof(szClassname));
		TF2Econ_TranslateWeaponEntForClass(szClassname, sizeof(szClassname), iClass);
		
		TF2Items_SetClassname(hItem, szClassname);
		TF2Items_SetItemIndex(hItem, iItemDefIndex);
		TF2Items_SetQuality(hItem, iQuality);
		TF2Items_SetLevel(hItem, iLevel);
		
		int newItem = TF2Items_GiveNamedItem(client, hItem);
		if (newItem != -1)
		{
			if (IsEntityWearable(newItem))
			{
				EquipPlayerWearable(client, newItem);
			}
			else if (IsEntityWeapon(newItem))
			{
				EquipPlayerWeapon(client, newItem);
				SetPlayerActiveWeapon(client, newItem);
			}

			SetEntProp(newItem, Prop_Send, "m_bValidatedAttachedEntity", true);
		}

		PostInventoryApplication(client);

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
