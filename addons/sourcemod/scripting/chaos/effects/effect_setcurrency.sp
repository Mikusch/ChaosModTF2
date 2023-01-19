#pragma semicolon 1
#pragma newdecls required

public bool PoorBoy_OnStart(ChaosEffect effect)
{
	if (!GameRules_GetProp("m_nForceUpgrades") && !GameRules_GetProp("m_bPlayingMannVsMachine"))
		return false;
	
	if (!effect.data)
		return false;
	
	int amount = effect.data.GetNum("amount");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntProp(client, Prop_Send, "m_nCurrency", amount);
	}
	
	return true;
}
