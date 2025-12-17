#pragma semicolon 1
#pragma newdecls required

public bool FlipViewModels_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		int nMaxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
		for (int i = 0; i < nMaxWeapons; i++)
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;
			
			SetEntProp(weapon, Prop_Send, "m_bFlipViewModel", true);
		}
		
		SDKHook(client, SDKHook_WeaponEquipPost, SDKHookCB_Client_WeaponEquipPost);
	}
	
	return true;
}

public void FlipViewModels_OnClientPutInServer(ChaosEffect effect, int client)
{
	SDKHook(client, SDKHook_WeaponEquipPost, SDKHookCB_Client_WeaponEquipPost);
}

public void FlipViewModels_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		int nMaxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
		for (int i = 0; i < nMaxWeapons; i++)
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;
			
			SetEntProp(weapon, Prop_Send, "m_bFlipViewModel", false);
		}
		
		SDKUnhook(client, SDKHook_WeaponEquipPost, SDKHookCB_Client_WeaponEquipPost);
	}
}

static void SDKHookCB_Client_WeaponEquipPost(int client, int weapon)
{
	SetEntProp(weapon, Prop_Send, "m_bFlipViewModel", true);
}
