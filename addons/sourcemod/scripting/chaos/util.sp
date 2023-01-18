#pragma semicolon 1
#pragma newdecls required

any Max(any a, any b)
{
	return (a >= b) ? a : b;
}

int Compare(any val1, any val2)
{
	if (val1 > val2)
	{
		return 1;
	}
	else if (val1 < val2)
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
	
	return (effect1.activate_time == effect2.activate_time) ? Compare(effect2.id, effect1.id) : Compare(effect1.activate_time, effect2.activate_time);
}

bool GetValueForKeyInKeyValues(KeyValues kv, const char[] szKeyToFind, char[] szValue, int iMaxLength)
{
	do
	{
		if (kv.GotoFirstSubKey(false))
		{
			// Current key is a section. Browse it recursively.
			return GetValueForKeyInKeyValues(kv, szKeyToFind, szValue, iMaxLength);
		}
		else
		{
			// Current key is a regular key, or an empty section.
			if (kv.GetDataType(NULL_STRING) != KvData_None)
			{
				char szKey[64];
				if (kv.GetSectionName(szKey, sizeof(szKey)) && StrEqual(szKey, szKeyToFind))
				{
					kv.GetString(NULL_STRING, szValue, iMaxLength);
					
					if (szValue[0])
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
	ArrayList players = new ArrayList();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (bIsAlive && !IsPlayerAlive(client))
			continue;
		
		players.Push(client);
	}
	
	if (!players.Length)
	{
		delete players;
		return false;
	}
	
	int client = players.Get(GetRandomInt(0, players.Length - 1));
	delete players;
	
	return client;
}
