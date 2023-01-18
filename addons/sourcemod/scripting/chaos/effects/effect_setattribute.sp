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
		
		ApplyAttributesFromEffectData(effect, client);
	}
	
	return true;
}

public void SetAttribute_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		ApplyAttributesFromEffectData(effect, client, true);
	}
}

public void SetAttribute_OnPlayerSpawn(ChaosEffect effect, int client)
{
	ApplyAttributesFromEffectData(effect, client);
}

static void ApplyAttributesFromEffectData(ChaosEffect effect, int client, bool bRemove = false)
{
	KeyValues kv = effect.data;
	
	if (kv.JumpToKey("attributes", false))
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				char szAttrib[64];
				kv.GetString("name", szAttrib, sizeof(szAttrib));
				
				if (!bRemove)
				{
					float flValue = kv.GetFloat("value");
					TF2Attrib_SetByName(client, szAttrib, flValue);
				}
				else
				{
					TF2Attrib_RemoveByName(client, szAttrib);
				}
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
}
