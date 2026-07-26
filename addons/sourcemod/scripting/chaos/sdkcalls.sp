#pragma semicolon 1
#pragma newdecls required

static Handle g_hSDKCallSetPausedForced;
static Handle g_hSDKCallEquipWearable;
static Handle g_hSDKCallGiveNamedItem;
static Handle g_hSDKCallPostInventoryApplication;
static Handle g_hSDKCallGetWeaponID;

void SDKCalls_Initialize()
{
	GameData gameconf;
	if (!LoadGameData(gameconf))
		return;

	// void IVEngineServer::SetPausedForced(bool, float) [virtual]
	StartPrepSDKCall(SDKCall_Engine);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "IVEngineServer::SetPausedForced");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_ByValue);
	g_hSDKCallSetPausedForced = EndPrepSDKCall();
	if (!g_hSDKCallSetPausedForced)
		LogError("Failed to create SDKCall for IVEngineServer::SetPausedForced");

	// void CBasePlayer::EquipWearable(CEconWearable *) [virtual]
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKCallEquipWearable = EndPrepSDKCall();
	if (!g_hSDKCallEquipWearable)
		LogError("Failed to create SDKCall for CBasePlayer::EquipWearable");

	// CBaseEntity *CTFPlayer::GiveNamedItem(const char *, int, CEconItemView *, bool) [virtual]
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "CTFPlayer::GiveNamedItem");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
#if SOURCEMOD_V_MAJOR > 1 || SOURCEMOD_V_MINOR >= 13
	PrepSDKCall_AddParameter(SDKType_Address, SDKPass_Plain);
#else
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
#endif
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_ByValue);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKCallGiveNamedItem = EndPrepSDKCall();
	if (!g_hSDKCallGiveNamedItem)
		LogError("Failed to create SDKCall for CTFPlayer::GiveNamedItem");

	// void CTFPlayer::PostInventoryApplication()
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Signature, "CTFPlayer::PostInventoryApplication");
	g_hSDKCallPostInventoryApplication = EndPrepSDKCall();
	if (!g_hSDKCallPostInventoryApplication)
		LogError("Failed to create SDKCall for CTFPlayer::PostInventoryApplication");

	// int CTFWeaponBase::GetWeaponID() [virtual]
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "CTFWeaponBase::GetWeaponID");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKCallGetWeaponID = EndPrepSDKCall();
	if (!g_hSDKCallGetWeaponID)
		LogError("Failed to create SDKCall for CTFWeaponBase::GetWeaponID");

	delete gameconf;
}

bool SDKCalls_CanSetPausedForced()
{
	return g_hSDKCallSetPausedForced != null;
}

bool SDKCalls_CanEquipWearable()
{
	return g_hSDKCallEquipWearable != null;
}

bool SDKCalls_CanGiveNamedItem()
{
	return g_hSDKCallGiveNamedItem != null;
}

bool SDKCalls_CanPostInventoryApplication()
{
	return g_hSDKCallPostInventoryApplication != null;
}

bool SDKCalls_CanGetWeaponID()
{
	return g_hSDKCallGetWeaponID != null;
}

void SetPausedForced(bool bPaused, float flDuration = -1.0)
{
	SDKCall(g_hSDKCallSetPausedForced, bPaused, flDuration);
}

void EquipPlayerWearable(int client, int wearable)
{
	SDKCall(g_hSDKCallEquipWearable, client, wearable);
}

int GiveNamedItem(int client, const char[] szClassname, int iSubType, Address pItem, bool bForce)
{
	return SDKCall(g_hSDKCallGiveNamedItem, client, szClassname, iSubType, pItem, bForce);
}

void PostInventoryApplication(int client)
{
	SDKCall(g_hSDKCallPostInventoryApplication, client);
}

int GetWeaponID(int weapon)
{
	return SDKCall(g_hSDKCallGetWeaponID, weapon);
}
