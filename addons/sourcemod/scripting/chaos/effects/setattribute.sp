#pragma semicolon 1
#pragma newdecls required

public bool SetAttribute_OnStart(ChaosEffect effect)
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

public void SetAttribute_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		ApplyAttributesToPlayer(effect, client, true);
	}
}

public void SetAttribute_OnPostInventoryApplication(ChaosEffect effect, int client)
{
	ApplyAttributesToPlayer(effect, client);
}

static bool IsAlreadyActive(ChaosEffect effect)
{
	KeyValues kv = effect.data;
	
	// Make sure we traverse back to not mess up effect data
	bool bFoundKey = false;
	
	if (kv.JumpToKey("attributes", false))
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				// Check if the same attribute is already active in this effect class
				char szAttrib[64];
				if (kv.GetSectionName(szAttrib, sizeof(szAttrib)) && FindKeyInActiveEffects(effect.effect_class, szAttrib))
				{
					bFoundKey = true;
				}
			}
			while (!bFoundKey && kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
	
	return bFoundKey;
}

static void ApplyAttributesToPlayer(ChaosEffect effect, int client, bool bRemove = false)
{
	KeyValues kv = effect.data;
	
	bool bApplyToWeapons = kv.GetNum("apply_to_weapons") != 0;
	
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
					
					if (bApplyToWeapons)
					{
						for (int i = 0; i < GetEntPropArraySize(client , Prop_Send,"m_hMyWeapons"); i++)
						{
							int myWeapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
							if (myWeapon != -1)
							{
								if (!bRemove)
								{
									TF2Attrib_SetByName(myWeapon, szAttrib, flValue);
								}
								else
								{
									TF2Attrib_RemoveByName(myWeapon, szAttrib);
								}
							}
						}
					}
					else
					{
						if (!bRemove)
						{
							TF2Attrib_SetByName(client, szAttrib, flValue);
						}
						else
						{
							TF2Attrib_RemoveByName(client, szAttrib);
						}
					}
				}
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
	
	TF2Util_UpdatePlayerSpeed(client);
}
