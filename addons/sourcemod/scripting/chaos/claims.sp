#pragma semicolon 1
#pragma newdecls required

void Claims_Resolve(ChaosEffect effect)
{
	Function fnCallback = effect.GetCallback(ChaosCb_GetClaims);
	if (fnCallback == INVALID_FUNCTION)
		return;

	ArrayList hDerived = new ArrayList(ByteCountToCells(EFFECT_MAX_CLAIM_LENGTH));

	Call_StartFunction(null, fnCallback);
	Call_PushArray(effect, sizeof(effect));
	Call_PushCell(hDerived);

	if (Call_Finish() != SP_ERROR_NONE)
	{
		LogError("Effect '%s': the 'GetClaims' callback aborted, its conflicts will not be detected", effect.id);
		delete hDerived;
		return;
	}

	if (!hDerived.Length)
	{
		delete hDerived;
		return;
	}

	if (!effect.claims)
	{
		effect.claims = hDerived;
		return;
	}

	int nLength = hDerived.Length;
	for (int i = 0; i < nLength; i++)
	{
		char szClaim[EFFECT_MAX_CLAIM_LENGTH];
		if (hDerived.GetString(i, szClaim, sizeof(szClaim)) && effect.claims.FindString(szClaim) == -1)
			effect.claims.PushString(szClaim);
	}

	delete hDerived;
}

bool Claims_FindConflict(ChaosEffect effect, char[] szReason, int iMaxLength)
{
	if (!effect.claims)
		return false;

	int nLength = effect.claims.Length;
	for (int i = 0; i < nLength; i++)
	{
		char szClaim[EFFECT_MAX_CLAIM_LENGTH];
		if (!effect.claims.GetString(i, szClaim, sizeof(szClaim)))
			continue;

		char szOwner[64];
		if (g_hActiveClaims.GetString(szClaim, szOwner, sizeof(szOwner)) && !StrEqual(szOwner, effect.id))
		{
			FormatEx(szReason, iMaxLength, "'%s' is already held by active effect '%s'", szClaim, szOwner);
			return true;
		}
	}

	return false;
}

void Claims_Register(ChaosEffect effect)
{
	if (!effect.claims)
		return;

	int nLength = effect.claims.Length;
	for (int i = 0; i < nLength; i++)
	{
		char szClaim[EFFECT_MAX_CLAIM_LENGTH];
		if (effect.claims.GetString(i, szClaim, sizeof(szClaim)))
			g_hActiveClaims.SetString(szClaim, effect.id);
	}
}

void Claims_Unregister(ChaosEffect effect)
{
	if (!effect.claims)
		return;

	int nLength = effect.claims.Length;
	for (int i = 0; i < nLength; i++)
	{
		char szClaim[EFFECT_MAX_CLAIM_LENGTH];
		if (!effect.claims.GetString(i, szClaim, sizeof(szClaim)))
			continue;

		char szOwner[64];
		if (g_hActiveClaims.GetString(szClaim, szOwner, sizeof(szOwner)) && StrEqual(szOwner, effect.id))
			g_hActiveClaims.Remove(szClaim);
	}
}
