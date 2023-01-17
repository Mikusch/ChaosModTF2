#pragma semicolon 1
#pragma newdecls required

public void HideHUD_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
	}
}

public Action HideHUD_OnPlayerRunCmd(ChaosEffect effect, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	SetEntProp(client, Prop_Send, "m_iHideHUD", HIDEHUD_HEALTH | HIDEHUD_MISCSTATUS | HIDEHUD_CROSSHAIR);
	
	return Plugin_Continue;
}
