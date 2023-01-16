#pragma semicolon 1
#pragma newdecls required

public bool ThirdPerson_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
	
	return true;
}

public void ThirdPerson_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}

public void ThirdPerson_OnPlayerSpawn(ChaosEffect effect, int client)
{
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");
}
