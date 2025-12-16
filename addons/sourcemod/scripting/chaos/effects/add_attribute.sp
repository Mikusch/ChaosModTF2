#pragma semicolon 1
#pragma newdecls required

public bool AddAttribute_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;

	// Don't set the same attribute twice
	if (IsAlreadyActive(effect))
		return false;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		ApplyAttributesToPlayer(effect, client);
	}

	return true;
}

public void AddAttribute_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		ApplyAttributesToPlayer(effect, client, true);
	}
}

public void AddAttribute_OnPlayerSpawnPost(ChaosEffect effect, int client)
{
	ApplyAttributesToPlayer(effect, client);
}

public void AddAttribute_OnPostInventoryApplication(ChaosEffect effect, int client)
{
	ApplyAttributesToPlayer(effect, client);
}

static bool IsAlreadyActive(ChaosEffect effect)
{
	KeyValues kv = effect.data;

	if (!kv.JumpToKey("attributes", false))
		return false;

	bool bFoundKey = false;
	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char szAttrib[64];
			if (kv.GetSectionName(szAttrib, sizeof(szAttrib)) && FindKeyInActiveEffects(effect.effect_class, szAttrib))
			{
				bFoundKey = true;
				break;
			}
		}
		while (kv.GotoNextKey(false));
		kv.GoBack();
	}
	kv.GoBack();

	return bFoundKey;
}

static void ApplyAttributesToPlayer(ChaosEffect effect, int client, bool bRemove = false)
{
	KeyValues kv = effect.data;
	bool bApplyToItems = kv.GetNum("apply_to_items") != 0;

	if (!kv.JumpToKey("attributes", false))
		return;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char szAttrib[64];
			if (kv.GetSectionName(szAttrib, sizeof(szAttrib)))
				ApplyAttribute(client, szAttrib, kv.GetFloat(NULL_STRING), bApplyToItems, bRemove);
		}
		while (kv.GotoNextKey(false));
		kv.GoBack();
	}
	kv.GoBack();

	TF2Util_UpdatePlayerSpeed(client);
}

static void ApplyAttribute(int client, const char[] szAttrib, float flValue, bool bApplyToItems, bool bRemove)
{
	if (bApplyToItems)
	{
		int nMaxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
		for (int i = 0; i < nMaxWeapons; i++)
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;

			if (bRemove)
				TF2Attrib_RemoveByName(weapon, szAttrib);
			else
				TF2Attrib_SetByName(weapon, szAttrib, flValue);
		}

		int nMaxWearables = TF2Util_GetPlayerWearableCount(client);
		for (int i = 0; i < nMaxWearables; i++)
		{
			int wearable = TF2Util_GetPlayerWearable(client, i);
			if (wearable == -1)
				continue;

			if (bRemove)
				TF2Attrib_RemoveByName(wearable, szAttrib);
			else
				TF2Attrib_SetByName(wearable, szAttrib, flValue);
		}
	}
	else
	{
		if (bRemove)
			TF2Attrib_RemoveCustomPlayerAttribute(client, szAttrib);
		else
			TF2Attrib_AddCustomPlayerAttribute(client, szAttrib, flValue);
	}
}
