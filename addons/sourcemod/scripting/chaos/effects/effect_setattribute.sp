#pragma semicolon 1
#pragma newdecls required

public bool SetAttribute_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	// Don't set the same attribute twice
	if (IsEffectWithKeyAlreadyActive(effect, "name"))
		return false;
	
	bool bWeapons = effect.data.GetNum("weapons") != 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (bWeapons)
		{
			for (int i = 0; i < MAX_WEAPONS; i++)
			{
				int myWeapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
				if (myWeapon != -1)
				{
					ApplyAttributesFromEffectData(effect, myWeapon);
				}
			}
		}
		else
		{
			ApplyAttributesFromEffectData(effect, client);
		}
	}
	
	return true;
}

public void SetAttribute_OnEnd(ChaosEffect effect)
{
	bool bWeapons = effect.data.GetNum("weapons") != 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (bWeapons)
		{
			for (int i = 0; i < MAX_WEAPONS; i++)
			{
				int myWeapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
				if (myWeapon != -1)
				{
					ApplyAttributesFromEffectData(effect, myWeapon, true);
				}
			}
		}
		else
		{
			ApplyAttributesFromEffectData(effect, client, true);
		}
	}
}

public void SetAttribute_OnPlayerSpawn(ChaosEffect effect, int client)
{
	bool bWeapons = effect.data.GetNum("weapons") != 0;
	
	if (!bWeapons)
	{
		ApplyAttributesFromEffectData(effect, client);
	}
}

public void SetAttribute_OnPostInventoryApplication(ChaosEffect effect, int client)
{
	bool bWeapons = effect.data.GetNum("weapons") != 0;
	
	if (bWeapons)
	{
		for (int i = 0; i < MAX_WEAPONS; i++)
		{
			int myWeapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
			if (myWeapon != -1)
			{
				ApplyAttributesFromEffectData(effect, myWeapon);
			}
		}
	}
}

static void ApplyAttributesFromEffectData(ChaosEffect effect, int entity, bool bRemove = false)
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
					TF2Attrib_SetByName(entity, szAttrib, flValue);
				}
				else
				{
					TF2Attrib_RemoveByName(entity, szAttrib);
				}
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
}
