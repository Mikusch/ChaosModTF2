#pragma semicolon 1
#pragma newdecls required

static ConVar sv_cheats;

public bool GrantOrRemoveAllUpgrades_Initialize(ChaosEffect effect)
{
	sv_cheats = FindConVar("sv_cheats");
	
	return true;
}

public bool GrantOrRemoveAllUpgrades_OnStart(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv)
		return false;

	if (FindEntityByClassname(-1, "func_upgradestation") == -1)
		return false;

	if (!GameModeUsesUpgrades())
		return false;

	bool bRemove = kv.GetNum("remove") != 0;
	
	// Granting upgrades for free is gated behind cheats, removing them is not
	bool bToggleCheats = !bRemove && !sv_cheats.BoolValue;
	int iOldFlags;
	
	if (bToggleCheats)
	{
		iOldFlags = sv_cheats.Flags;
		sv_cheats.Flags = iOldFlags & ~FCVAR_NOTIFY;
		sv_cheats.SetBool(true);
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (IsFakeClient(client))
			continue;
		
		SetVariantString(bRemove ? "!self.GrantOrRemoveAllUpgrades(true, false)" : "!self.GrantOrRemoveAllUpgrades(false, false)");
		AcceptEntityInput(client, "RunScriptCode");
	}
	
	if (bToggleCheats)
	{
		sv_cheats.SetBool(false);
		sv_cheats.Flags = iOldFlags;
	}
	
	return true;
}

// Mirrors CTFGameRules::GameModeUsesUpgrades
static bool GameModeUsesUpgrades()
{
	int nForceUpgrades = GameRules_GetProp("m_nForceUpgrades");
	
	if (nForceUpgrades == 1)
		return false;
	
	if (nForceUpgrades == 2)
		return true;
	
	return GameRules_GetProp("m_bPlayingMannVsMachine") != 0;
}
