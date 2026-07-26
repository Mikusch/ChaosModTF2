#pragma semicolon 1
#pragma newdecls required

public void AddAttribute_GetClaims(ChaosEffect effect, ArrayList claims)
{
	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("attributes", false))
		return;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char szAttrib[64];
			if (!kv.GetSectionName(szAttrib, sizeof(szAttrib)))
				continue;

			char szClaim[EFFECT_MAX_CLAIM_LENGTH];
			FormatEx(szClaim, sizeof(szClaim), "attribute:%s", szAttrib);

			claims.PushString(szClaim);
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();
}

public bool AddAttribute_OnStart(ChaosEffect effect)
{
	if (!effect.OpenData())
		return false;

	ApplyAttributesToAll(effect);

	return true;
}

public void AddAttribute_OnEnd(ChaosEffect effect)
{
	ApplyAttributesToAll(effect, true);
}

public void AddAttribute_OnPlayerSpawnPost(ChaosEffect effect, int client)
{
	ApplyAttributesToPlayer(effect, client);
}

public void AddAttribute_OnPostInventoryApplication(ChaosEffect effect, int client)
{
	ApplyAttributesToPlayer(effect, client);
}

static void ApplyAttributesToAll(ChaosEffect effect, bool bRemove = false)
{
	ArrayList hWearables = AppliesToItems(effect) ? GetWearables() : null;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		ApplyAttributes(effect, client, hWearables, bRemove);
	}

	delete hWearables;
}

static void ApplyAttributesToPlayer(ChaosEffect effect, int client, bool bRemove = false)
{
	ArrayList hWearables = AppliesToItems(effect) ? GetWearables(client) : null;

	ApplyAttributes(effect, client, hWearables, bRemove);

	delete hWearables;
}

static bool AppliesToItems(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();

	return kv && kv.GetNum("apply_to_items") != 0;
}

static void ApplyAttributes(ChaosEffect effect, int client, ArrayList hWearables, bool bRemove)
{
	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("attributes", false))
		return;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char szAttrib[64];
			if (kv.GetSectionName(szAttrib, sizeof(szAttrib)))
				ApplyAttribute(client, hWearables, szAttrib, kv.GetFloat(NULL_STRING), bRemove);
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();

	// Cheapest way to force a speed recalculation without gamedata
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, GetGameFrameTime());
}

static void ApplyAttribute(int client, ArrayList hWearables, const char[] szAttrib, float flValue, bool bRemove)
{
	if (!hWearables)
	{
		if (bRemove)
			TF2Attrib_RemoveCustomPlayerAttribute(client, szAttrib);
		else
			TF2Attrib_AddCustomPlayerAttribute(client, szAttrib, flValue);

		return;
	}

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

	int nLength = hWearables.Length;
	for (int i = 0; i < nLength; i++)
	{
		int wearable = hWearables.Get(i);

		if (GetEntPropEnt(wearable, Prop_Send, "m_hOwnerEntity") != client)
			continue;

		if (bRemove)
			TF2Attrib_RemoveByName(wearable, szAttrib);
		else
			TF2Attrib_SetByName(wearable, szAttrib, flValue);
	}
}
