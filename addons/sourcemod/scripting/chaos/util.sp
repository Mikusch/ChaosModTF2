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

void GetRandomColorRGB(int &r, int &g, int &b, int &a)
{
	r = GetRandomInt(0, 255);
	g = GetRandomInt(0, 255);
	b = GetRandomInt(0, 255);
	a = GetRandomInt(0, 255);
}

int GetRandomColorInt()
{
	int r, g, b, a;
	GetRandomColorRGB(r, g, b, a);
	return Color32ToInt(r, g, b, a);
}

int Color32ToInt(int r, int g, int b, int a)
{
	return (r << 24) | (g << 16) | (b << 8) | (a);
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
