#pragma semicolon 1
#pragma newdecls required

int GetNumEdicts()
{
	int nNumEdicts = 0;
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (!IsEntNetworkable(entity))
			continue;
		
		nNumEdicts++;
	}
	
	return nNumEdicts;
}

any Max(any a, any b)
{
	return (a >= b) ? a : b;
}

any Min(any a, any b)
{
	return (a <= b) ? a : b;
}

int SortFuncADTArray_SortDisplayOrder(int index1, int index2, Handle array, Handle hndl)
{
	ArrayList order = view_as<ArrayList>(array);

	int a = order.Get(index1);
	int b = order.Get(index2);

	// Sort by activation time descending
	float flActivate1 = g_hEffects.Get(a, ChaosEffect::activate_time);
	float flActivate2 = g_hEffects.Get(b, ChaosEffect::activate_time);
	if (flActivate1 != flActivate2)
		return FloatCompare(flActivate2, flActivate1);

	// Sort meta effects first
	bool bMeta1 = g_hEffects.Get(a, ChaosEffect::meta);
	bool bMeta2 = g_hEffects.Get(b, ChaosEffect::meta);
	if (bMeta1 != bMeta2)
		return bMeta1 ? -1 : 1;

	float flDuration1 = g_hEffects.Get(a, ChaosEffect::duration);
	float flDuration2 = g_hEffects.Get(b, ChaosEffect::duration);
	if (flDuration1 <= 0.0)
		flDuration1 = ONESHOT_EFFECT_DISPLAY_TIME;
	if (flDuration2 <= 0.0)
		flDuration2 = ONESHOT_EFFECT_DISPLAY_TIME;

	// Sort by duration ascending
	if (flDuration1 != flDuration2)
		return FloatCompare(flDuration1, flDuration2);

	// Sort alphabetically by ID
	char szId1[64], szId2[64];
	g_hEffects.GetString(a, szId1, sizeof(szId1), ChaosEffect::id);
	g_hEffects.GetString(b, szId2, sizeof(szId2), ChaosEffect::id);

	return strcmp(szId1, szId2);
}

// bInvert drains the bar as the ratio rises, for the remaining-time bar
void BuildProgressBar(ProgressBarConfig config, float flRatio, bool bInvert, char[] szBuffer, int iMaxLength)
{
	szBuffer[0] = EOS;

	if (flRatio < 0.0)
		flRatio = 0.0;
	if (flRatio > 1.0)
		flRatio = 1.0;

	int nBlocks = config.num_blocks;
	int nScaled = RoundToNearest(flRatio * float(nBlocks));

	int nFilled = bInvert ? (nBlocks - nScaled) : nScaled;
	int nEmpty = nBlocks - nFilled;

	for (int i = 0; i < nFilled; i++)
	{
		StrCat(szBuffer, iMaxLength, config.filled);
	}
	for (int i = 0; i < nEmpty; i++)
	{
		StrCat(szBuffer, iMaxLength, config.empty);
	}
}

void SendHudNotification(HudNotification_t iType, bool bForceShow = false)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageAll("HudNotify"));
	bf.WriteByte(view_as<int>(iType));
	bf.WriteBool(bForceShow);	// Display in cl_hud_minmode
	EndMessage();
}

void SendCustomHudNotificationCustom(int client, const char[] szText, const char[] szIcon, TFTeam nTeam = TFTeam_Unassigned)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("HudNotifyCustom", client));
	bf.WriteString(szText);
	bf.WriteString(szIcon);
	bf.WriteByte(view_as<int>(nTeam));
	EndMessage();
}

void PrintKeyHintText(int client, const char[] format, any...)
{
	char buffer[MAX_USER_MSG_DATA - 1];
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
		return -1;
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

static int FixedUnsigned16(float value, int scale)
{
	int output;
	
	output = RoundToFloor(value * float(scale));
	if (output < 0)
		output = 0;
	if (output > 0xFFFF)
		output = 0xFFFF;
	
	return output;
}

void UTIL_ScreenFade(int player, const int color[4], float fadeTime, float fadeHold, int flags)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Fade", player, USERMSG_RELIABLE));
	if (bf != null)
	{
		bf.WriteShort(FixedUnsigned16(fadeTime, 1 << SCREENFADE_FRACBITS));
		bf.WriteShort(FixedUnsigned16(fadeHold, 1 << SCREENFADE_FRACBITS));
		bf.WriteShort(flags);
		bf.WriteByte(color[0]);
		bf.WriteByte(color[1]);
		bf.WriteByte(color[2]);
		bf.WriteByte(color[3]);
		EndMessage();
	}
}

void UTIL_ScreenShake(int player, ShakeCommand_t eCommand, float flAmplitude, float flFrequency, float flDuration)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageOne("Shake", player));
	bf.WriteByte(view_as<int>(eCommand));
	bf.WriteFloat(flAmplitude);
	bf.WriteFloat(flFrequency);
	bf.WriteFloat(flDuration);
	EndMessage();
}

void WorldSpaceCenter(int entity, float vecCenter[3])
{
	float vecOrigin[3], vecMins[3], vecMaxs[3], vecOffset[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	GetEntPropVector(entity, Prop_Data, "m_vecMins", vecMins);
	GetEntPropVector(entity, Prop_Data, "m_vecMaxs", vecMaxs);
	
	AddVectors(vecMins, vecMaxs, vecOffset);
	ScaleVector(vecOffset, 0.5);
	AddVectors(vecOrigin, vecOffset, vecCenter);
}

int FindItemOffset(int entity)
{
	char szNetClass[32];
	if (!GetEntityNetClass(entity, szNetClass, sizeof(szNetClass)))
		return -1;

	return FindSendPropInfo(szNetClass, "m_Item");
}

bool IsEntityWeapon(int entity)
{
	return HasEntProp(entity, Prop_Data, "CTFWeaponBaseFallThink");
}

bool IsEntityWearable(int entity)
{
	return HasEntProp(entity, Prop_Send, "m_bDisguiseWearable");
}

ArrayList GetWearables(int client = -1)
{
	ArrayList hWearables = new ArrayList();

	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (!IsEntityWearable(entity))
			continue;

		if (client == -1 || GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			hWearables.Push(entity);
	}

	return hWearables;
}

int GetPlayerLoadoutEntity(int client, int iLoadoutSlot, bool bIncludeWearableWeapons = true)
{
	TFClassType nClass = TF2_GetPlayerClass(client);

	if (IsWearableSlot(iLoadoutSlot) || bIncludeWearableWeapons)
	{
		ArrayList hWearables = GetWearables(client);
		for (int i = 0; i < hWearables.Length; i++)
		{
			int wearable = hWearables.Get(i);

			int iItemDefIndex = GetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex");
			if (TF2Econ_GetItemLoadoutSlot(iItemDefIndex, nClass) == iLoadoutSlot)
			{
				delete hWearables;
				return wearable;
			}
		}
		delete hWearables;
	}

	int nMaxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	for (int i = 0; i < nMaxWeapons; i++)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (weapon == -1)
			continue;

		int iItemDefIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if (TF2Econ_GetItemLoadoutSlot(iItemDefIndex, nClass) == iLoadoutSlot)
			return weapon;
	}

	return -1;
}

void SetPlayerActiveWeapon(int client, int weapon)
{
	char code[64];
	FormatEx(code, sizeof(code), "self.Weapon_Switch(EntIndexToHScript(%d))", EntRefToEntIndex(weapon));

	SetVariantString(code);
	AcceptEntityInput(client, "RunScriptCode");
}

bool LoadGameData(GameData &gameconf)
{
	gameconf = new GameData("chaos");
	if (!gameconf)
	{
		LogError("Failed to load gamedata file");
		return false;
	}
	return true;
}
