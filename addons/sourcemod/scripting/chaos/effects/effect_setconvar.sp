#pragma semicolon 1
#pragma newdecls required

static StringMap g_hOldConvarValues;

public void SetConVar_Initialize(ChaosEffect effect)
{
	g_hOldConvarValues = new StringMap();
}

public bool SetConVar_OnStart(ChaosEffect effect)
{
	if (!effect.data)
	{
		LogError("Missing effect data!");
		return false;
	}
	
	char szName[512], szValue[512];
	effect.data.GetString("name", szName, sizeof(szName));
	effect.data.GetString("value", szValue, sizeof(szValue));
	
	ConVar convar = FindConVar(szName);
	if (!convar)
	{
		LogError("Failed to find ConVar '%s'", szName);
		return false;
	}
	
	char szOldValue[512];
	convar.GetString(szOldValue, sizeof(szOldValue));
	
	// Avoid starting effect if the convar value is already the same
	if (StrEqual(szOldValue, szValue))
		return false;
	
	g_hOldConvarValues.SetString(szName, szOldValue);
	convar.SetString(szValue, true);
	
	return true;
}

public void SetConVar_OnEnd(ChaosEffect effect)
{
	if (!effect.data)
		return;
	
	char szName[512];
	effect.data.GetString("name", szName, sizeof(szName));
	
	ConVar convar = FindConVar(szName);
	if (!convar)
		return;
	
	char szValue[512];
	g_hOldConvarValues.GetString(szName, szValue, sizeof(szValue));
	
	convar.SetString(szValue, true);
	g_hOldConvarValues.Remove(szName);
}
