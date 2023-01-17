#pragma semicolon 1
#pragma newdecls required

public bool FakeClientCommand_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	char szCommand[512];
	effect.data.GetString("command", szCommand, sizeof(szCommand));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		FakeClientCommand(client, szCommand);
	}
	
	return true;
}
