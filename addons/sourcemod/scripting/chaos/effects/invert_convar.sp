#pragma semicolon 1
#pragma newdecls required

public bool InvertConVar_OnStart(ChaosEffect effect)
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
	
	convar.FloatValue = -convar.FloatValue;
	convar.AddChangeHook(OnConVarChanged);
	
	return true;
}

public void InvertConVar_OnEnd(ChaosEffect effect)
{
	char szName[512];
	effect.data.GetString("convar", szName, sizeof(szName));

	ConVar convar = FindConVar(szName);
	if (!convar)
		return;

	convar.RemoveChangeHook(OnConVarChanged);
	convar.FloatValue = -convar.FloatValue;
}

static void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.RemoveChangeHook(OnConVarChanged);
	convar.FloatValue = -convar.FloatValue;
	convar.AddChangeHook(OnConVarChanged);
}
