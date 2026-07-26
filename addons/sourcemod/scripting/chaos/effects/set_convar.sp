#pragma semicolon 1
#pragma newdecls required

public void SetConVar_GetClaims(ChaosEffect effect, ArrayList claims)
{
	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("convars"))
		return;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char szName[128];
			if (!kv.GetSectionName(szName, sizeof(szName)))
				continue;

			char szClaim[EFFECT_MAX_CLAIM_LENGTH];
			FormatEx(szClaim, sizeof(szClaim), "convar:%s", szName);

			claims.PushString(szClaim);
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();
}

public bool SetConVar_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("convars"))
		return false;

	bool bAnySet = false;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char szName[128], szValue[512], szOldValue[512];
			if (!kv.GetSectionName(szName, sizeof(szName)))
				continue;

			kv.GetString(NULL_STRING, szValue, sizeof(szValue));

			ConVar convar = FindConVar(szName);
			if (!convar)
				continue;

			convar.GetString(szOldValue, sizeof(szOldValue));

			// Don't set if the convar value is already set to the desired value
			if (StrEqual(szOldValue, szValue))
				continue;

			effect.state.SetString(szName, szOldValue);

			convar.SetString(szValue, true);

			if (effect.duration)
				convar.AddChangeHook(OnConVarChanged);

			bAnySet = true;
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();
	return bAnySet;
}

public void SetConVar_OnEnd(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("convars"))
		return;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char szName[128], szOldValue[512];
			if (!kv.GetSectionName(szName, sizeof(szName)))
				continue;

			// Only restore what we actually changed
			if (!effect.state.GetString(szName, szOldValue, sizeof(szOldValue)))
				continue;

			ConVar convar = FindConVar(szName);
			if (!convar)
				continue;

			convar.RemoveChangeHook(OnConVarChanged);
			convar.SetString(szOldValue, true);
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();
}

static void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char szName[128];
	convar.GetName(szName, sizeof(szName));

	char szClaim[EFFECT_MAX_CLAIM_LENGTH];
	FormatEx(szClaim, sizeof(szClaim), "convar:%s", szName);

	char szOwnerId[64];
	if (!g_hActiveClaims.GetString(szClaim, szOwnerId, sizeof(szOwnerId)))
		return;

	ChaosEffect owner;
	if (!GetEffectById(szOwnerId, owner) || !owner.state)
		return;

	convar.RemoveChangeHook(OnConVarChanged);
	convar.SetString(oldValue, true);
	convar.AddChangeHook(OnConVarChanged);

	owner.state.SetString(szName, newValue);
}
