#pragma semicolon 1
#pragma newdecls required

public bool ShowScoreboard_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		ShowVGUIPanel(client, "scores");
	}
	
	return true;
}
