#pragma semicolon 1
#pragma newdecls required

any Max(any a, any b)
{
	return (a >= b) ? a : b;
}

int Compare(any a, any b)
{
	if (a > b)
	{
		return 1;
	}
	else if (a < b)
	{
		return -1;
	}
	
	return 0;
}

int SortFuncADTArray_SortChaosEffectsByCooldown(int index1, int index2, Handle array, Handle hndl)
{
	ArrayList list = view_as<ArrayList>(array);
	
	ChaosEffect effect1, effect2;
	list.GetArray(index1, effect1);
	list.GetArray(index2, effect2);
	
	// If both are the same, pick a random one
	return (effect1.cooldown_left == effect2.cooldown_left) ? GetRandomInt(-1, 1) : Compare(effect1.cooldown_left, effect2.cooldown_left);
}

int SortFuncADTArray_SortChaosEffectsByActivationTime(int index1, int index2, Handle array, Handle hndl)
{
	ArrayList list = view_as<ArrayList>(array);
	
	ChaosEffect effect1, effect2;
	list.GetArray(index1, effect1);
	list.GetArray(index2, effect2);
	
	return (effect1.activate_time == effect2.activate_time) ? strcmp(effect2.id, effect1.id) : Compare(effect1.activate_time, effect2.activate_time);
}

bool FindKeyInKeyValues(KeyValues kv, const char[] szKeyToFind)
{
	do
	{
		if (kv.GotoFirstSubKey(false))
		{
			// Current key is a section. Browse it recursively.
			return FindKeyInKeyValues(kv, szKeyToFind);
		}
		else
		{
			// Current key is a regular key, or an empty section.
			if (kv.GetDataType(NULL_STRING) != KvData_None)
			{
				char szKey[64];
				if (kv.GetSectionName(szKey, sizeof(szKey)) && StrEqual(szKey, szKeyToFind))
				{
					return true;
				}
			}
		}
	}
	while (kv.GotoNextKey(false));
	
	return false;
}

bool FindKeyValuePairInKeyValues(KeyValues kv, const char[] szKeyToFind, const char[] szValueToFind)
{
	do
	{
		if (kv.GotoFirstSubKey(false))
		{
			// Current key is a section. Browse it recursively.
			return FindKeyValuePairInKeyValues(kv, szKeyToFind, szValueToFind);
		}
		else
		{
			// Current key is a regular key, or an empty section.
			if (kv.GetDataType(NULL_STRING) != KvData_None)
			{
				char szKey[64];
				if (kv.GetSectionName(szKey, sizeof(szKey)) && StrEqual(szKey, szKeyToFind))
				{
					char szValue[64];
					kv.GetString(NULL_STRING, szValue, sizeof(szValue));
					
					if (StrEqual(szValue, szValueToFind))
					{
						return true;
					}
				}
			}
		}
	}
	while (kv.GotoNextKey(false));
	
	return false;
}

void SendHudNotification(HudNotification_t iType, bool bForceShow = false)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageAll("HudNotify"));
	bf.WriteByte(view_as<int>(iType));
	bf.WriteBool(bForceShow);	// Display in cl_hud_minmode
	EndMessage();
}

void PrintKeyHintText(int client, const char[] format, any...)
{
	char buffer[256];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("KeyHintText", client));
	bf.WriteByte(1);
	bf.WriteString(buffer);
	EndMessage();
}

int GetRandomPlayer(bool bIsAlive = true)
{
	ArrayList hPlayers = new ArrayList();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (bIsAlive && !IsPlayerAlive(client))
			continue;
		
		hPlayers.Push(client);
	}
	
	if (!hPlayers.Length)
	{
		delete hPlayers;
		return false;
	}
	
	int client = hPlayers.Get(GetRandomInt(0, hPlayers.Length - 1));
	delete hPlayers;
	
	return client;
}

void PlayStaticSound(const char[] sound)
{
	if (PrecacheScriptSound(sound))
	{
		EmitGameSoundToAll(sound);
	}
	else if (PrecacheSound(sound))
	{
		EmitSoundToAll(sound, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
	}
}

void StopStaticSound(const char[] sound)
{
	if (PrecacheScriptSound(sound))
	{
		EmitGameSoundToAll(sound, _, SND_STOP | SND_STOPLOOPING);
	}
	else if (PrecacheSound(sound))
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			StopSound(client, SNDCHAN_STATIC, sound);
		}
	}
}

void StringToVector(const char[] str, float vec[3])
{
	char buffer[3][16];
	ExplodeString(str, " ", buffer, sizeof(buffer), sizeof(buffer[]));
	
	for (int i = 0; i < sizeof(vec); i++)
	{
		vec[i] = StringToFloat(buffer[i]);
	}
}

void StringToColor(const char[] str, int color[4])
{
	char buffer[4][16];
	ExplodeString(str, " ", buffer, sizeof(buffer), sizeof(buffer[]));
	
	for (int i = 0; i < sizeof(color); i++)
	{
		color[i] = StringToInt(buffer[i]);
	}
}

int Color32ToInt(int r, int g, int b, int a)
{
	return (r << 24) | (g << 16) | (b << 8) | (a);
}

bool IsMiscSlot(int iSlot)
{
	return iSlot == LOADOUT_POSITION_MISC
		|| iSlot == LOADOUT_POSITION_MISC2
		|| iSlot == LOADOUT_POSITION_HEAD;
}

bool IsTauntSlot(int iSlot)
{
	return iSlot == LOADOUT_POSITION_TAUNT
		|| iSlot == LOADOUT_POSITION_TAUNT2
		|| iSlot == LOADOUT_POSITION_TAUNT3
		|| iSlot == LOADOUT_POSITION_TAUNT4
		|| iSlot == LOADOUT_POSITION_TAUNT5
		|| iSlot == LOADOUT_POSITION_TAUNT6
		|| iSlot == LOADOUT_POSITION_TAUNT7
		|| iSlot == LOADOUT_POSITION_TAUNT8;
}

bool IsWearableSlot(int iSlot)
{
	return iSlot == LOADOUT_POSITION_HEAD
		|| iSlot == LOADOUT_POSITION_MISC
		|| iSlot == LOADOUT_POSITION_ACTION
		|| IsMiscSlot(iSlot)
		|| IsTauntSlot(iSlot);
}

int GetItemDefinitionIndexByName(const char[] szItemName)
{
	if (!szItemName[0])
	{
		return TF_ITEMDEF_DEFAULT;
	}
	
	static StringMap s_hItemDefsByName;
	
	if (!s_hItemDefsByName)
	{
		s_hItemDefsByName = new StringMap();
	}
	
	if (s_hItemDefsByName.ContainsKey(szItemName))
	{
		// get cached item def from map
		int iItemDefIndex = TF_ITEMDEF_DEFAULT;
		return s_hItemDefsByName.GetValue(szItemName, iItemDefIndex) ? iItemDefIndex : TF_ITEMDEF_DEFAULT;
	}
	else
	{
		DataPack hDataPack = new DataPack();
		hDataPack.WriteString(szItemName);
		
		// search the item list and cache the result
		ArrayList hItemList = TF2Econ_GetItemList(ItemFilterCriteria_FilterByName, hDataPack);
		int iItemDefIndex = (hItemList.Length > 0) ? hItemList.Get(0) : TF_ITEMDEF_DEFAULT;
		s_hItemDefsByName.SetValue(szItemName, iItemDefIndex);
		
		delete hDataPack;
		delete hItemList;
		
		return iItemDefIndex;
	}
}

static bool ItemFilterCriteria_FilterByName(int iItemDefIndex, DataPack hDataPack)
{
	hDataPack.Reset();
	
	char szName1[64];
	hDataPack.ReadString(szName1, sizeof(szName1));
	
	char szName2[64];
	if (TF2Econ_GetItemName(iItemDefIndex, szName2, sizeof(szName2)) && StrEqual(szName1, szName2, false))
	{
		return true;
	}
	
	return false;
}
