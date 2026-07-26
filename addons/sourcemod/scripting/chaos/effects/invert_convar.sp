#pragma semicolon 1
#pragma newdecls required

public void InvertConVar_GetClaims(ChaosEffect effect, ArrayList claims)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	char szName[128];
	kv.GetString("convar", szName, sizeof(szName));

	if (!szName[0])
		return;

	char szClaim[EFFECT_MAX_CLAIM_LENGTH];
	FormatEx(szClaim, sizeof(szClaim), "convar:%s", szName);

	claims.PushString(szClaim);
}

public bool InvertConVar_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	char szName[128];
	kv.GetString("convar", szName, sizeof(szName));

	ConVar convar = FindConVar(szName);
	if (!convar)
		return false;

	convar.FloatValue = -convar.FloatValue;
	convar.AddChangeHook(OnConVarChanged);

	return true;
}

public void InvertConVar_OnEnd(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return;

	char szName[128];
	kv.GetString("convar", szName, sizeof(szName));

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
