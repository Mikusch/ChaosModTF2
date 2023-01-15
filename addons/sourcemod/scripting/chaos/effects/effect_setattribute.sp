#pragma semicolon 1
#pragma newdecls required

public bool SetAttribute_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	char szAttrib[64];
	effect.data.GetString("name", szAttrib, sizeof(szAttrib));
	float flValue = effect.data.GetFloat("value");
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2Attrib_SetByName(client, szAttrib, flValue);
	}
	
	return true;
}

public void SetAttribute_OnEnd(ChaosEffect effect)
{
	char szAttrib[64];
	effect.data.GetString("name", szAttrib, sizeof(szAttrib));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2Attrib_RemoveByName(client, szAttrib);
	}
}

public void SetAttribute_OnPlayerSpawn(ChaosEffect effect, int client)
{
	char szAttrib[64];
	effect.data.GetString("name", szAttrib, sizeof(szAttrib));
	float flValue = effect.data.GetFloat("value");
	
	TF2Attrib_SetByName(client, szAttrib, flValue);
}
