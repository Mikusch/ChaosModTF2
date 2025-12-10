#pragma semicolon 1
#pragma newdecls required

public bool GrantOrRemoveAllUpgrades_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	if (!GameRules_GetProp("m_nForceUpgrades") && !GameRules_GetProp("m_bPlayingMannVsMachine"))
		return false;
	
	bool bRemove = effect.data.GetNum("remove") != 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (IsFakeClient(client))
			continue;
		
		SetVariantString(bRemove ? "!self.GrantOrRemoveAllUpgrades(true, false)" : "!self.GrantOrRemoveAllUpgrades(false, false)");
		AcceptEntityInput(client, "RunScriptCode");
	}
	
	return true;
}
