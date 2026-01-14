#pragma semicolon 1
#pragma newdecls required

static StringMap g_hOldConVarValues;

public bool SetConVar_Initialize(ChaosEffect effect)
{
	if (!g_hOldConVarValues)
		g_hOldConVarValues = new StringMap();

	return true;
}

public bool SetConVar_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;

	if (!effect.data.JumpToKey("convars"))
		return false;

	// Check for duplicate convars in active effects
	if (effect.data.GotoFirstSubKey(false))
	{
		do
		{
			char szName[512];
			effect.data.GetSectionName(szName, sizeof(szName));

			if (FindKeyInSectionInActiveEffects(effect.effect_class, "convars", szName))
			{
				effect.data.GoBack(); // Go back to "convars"
				effect.data.GoBack(); // Go back to root
				return false;
			}
		}
		while (effect.data.GotoNextKey(false));

		effect.data.GoBack();
	}

	// Apply all convars
	bool bAnySet = false;
	if (effect.data.GotoFirstSubKey(false))
	{
		do
		{
			char szName[512], szValue[512], szOldValue[512];
			effect.data.GetSectionName(szName, sizeof(szName));
			effect.data.GetString(NULL_STRING, szValue, sizeof(szValue));

			ConVar convar = FindConVar(szName);
			if (!convar)
				continue;

			convar.GetString(szOldValue, sizeof(szOldValue));

			// Don't set if the convar value is already set to the desired value
			if (StrEqual(szOldValue, szValue))
				continue;

			g_hOldConVarValues.SetString(szName, szOldValue);
			convar.SetString(szValue, true);
			bAnySet = true;

			// If this effect has a duration, add the change hook
			if (effect.duration)
				convar.AddChangeHook(OnConVarChanged);
		}
		while (effect.data.GotoNextKey(false));

		effect.data.GoBack();
	}

	effect.data.GoBack();
	return bAnySet;
}

public void SetConVar_OnEnd(ChaosEffect effect)
{
	if (!effect.data.JumpToKey("convars"))
		return;

	if (effect.data.GotoFirstSubKey(false))
	{
		do
		{
			char szName[512], szOldValue[512];
			effect.data.GetSectionName(szName, sizeof(szName));

			if (!g_hOldConVarValues.GetString(szName, szOldValue, sizeof(szOldValue)))
				continue;

			ConVar convar = FindConVar(szName);
			if (!convar)
				continue;

			convar.RemoveChangeHook(OnConVarChanged);
			convar.SetString(szOldValue, true);
			g_hOldConVarValues.Remove(szName);
		}
		while (effect.data.GotoNextKey(false));

		effect.data.GoBack();
	}

	effect.data.GoBack();
}

static void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char szName[512];
	convar.GetName(szName, sizeof(szName));

	// Restore the old value
	convar.RemoveChangeHook(OnConVarChanged);
	convar.SetString(oldValue, true);
	convar.AddChangeHook(OnConVarChanged);

	// Update our stored value
	g_hOldConVarValues.SetString(szName, newValue);
}
