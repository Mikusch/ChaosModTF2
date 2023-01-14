#pragma semicolon 1
#pragma newdecls required

public void MidgetMercenaries_OnStart()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2Attrib_SetByName(client, "torso scale", 0.0);
	}
}

public void MidgetMercenaries_OnEnd()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2Attrib_RemoveByName(client, "torso scale");
	}
}
