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
	
	char szName[512];
	effect.data.GetString("convar", szName, sizeof(szName));
	
	ConVar convar = FindConVar(szName);
	if (!convar)
		return false;
	
	// Don't set the same convar twice
	if (FindKeyValuePairInActiveEffects(effect.effect_class, "convar", szName))
		return false;
	
	char szValue[512], szOldValue[512];
	effect.data.GetString("value", szValue, sizeof(szValue));
	convar.GetString(szOldValue, sizeof(szOldValue));
	
	// Don't start effect if the convar value is already set to the desired value
	if (StrEqual(szOldValue, szValue))
		return false;
	
	g_hOldConVarValues.SetString(szName, szOldValue);
	convar.SetString(szValue, true);

	// If this effect has no duration, we don't need the stuff below
	if (!effect.duration)
		return true;

	convar.AddChangeHook(OnConVarChanged);

	return true;
}

public void SetConVar_OnEnd(ChaosEffect effect)
{
	char szName[512], szValue[512];
	effect.data.GetString("convar", szName, sizeof(szName));
	g_hOldConVarValues.GetString(szName, szValue, sizeof(szValue));

	ConVar convar = FindConVar(szName);

	convar.RemoveChangeHook(OnConVarChanged);
	convar.SetString(szValue, true);
	g_hOldConVarValues.Remove(szName);
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
