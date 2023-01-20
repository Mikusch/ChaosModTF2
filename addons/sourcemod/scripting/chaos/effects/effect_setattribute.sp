#pragma semicolon 1
#pragma newdecls required

public bool SetAttribute_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Don't set the same attribute twice
	if (IsEffectWithKeyAlreadyActive(effect, "name"))
		return false;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		ApplyAttributesFromEffectData(effect.data, client);
	}
	
	return true;
}

public void SetAttribute_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		ApplyAttributesFromEffectData(effect.data, client, true);
	}
}

public void SetAttribute_OnPostInventoryApplication(ChaosEffect effect, int client)
{
	ApplyAttributesFromEffectData(effect.data, client);
}

static void ApplyAttributesFromEffectData(KeyValues kv, int client, bool bRemove = false)
{
	bool bApplyToWeapons = kv.GetNum("weapons") != 0;
	
	if (kv.JumpToKey("attributes", false))
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				char szAttrib[64];
				kv.GetString("name", szAttrib, sizeof(szAttrib));
				float flValue = kv.GetFloat("value");
				
				if (bApplyToWeapons)
				{
					for (int i = 0; i < MAX_WEAPONS; i++)
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
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
}
