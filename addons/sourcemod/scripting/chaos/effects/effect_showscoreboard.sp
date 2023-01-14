#pragma semicolon 1
#pragma newdecls required

public void ShowScoreboard_OnStart()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		ShowVGUIPanel(client, "scores");
		TF2_AddCondition(client, TFCond_FreezeInput, 3.0);
	}
}
