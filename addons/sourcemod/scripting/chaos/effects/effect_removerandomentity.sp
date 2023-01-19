#pragma semicolon 1
#pragma newdecls required

public bool RemoveRandomEntity_OnStart(ChaosEffect effect)
{
	ArrayList hEntities = new ArrayList();
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity <= MaxClients)
			continue;
		
		hEntities.Push(entity);
	}
	
	if (!hEntities.Length)
	{
		delete hEntities;
		return false;
	}
	
	entity = hEntities.Get(GetRandomInt(0, hEntities.Length - 1));
	delete hEntities;
	
	RemoveEntity(entity);
	
	char szClassname[64];
	if (GetEntityClassname(entity, szClassname, sizeof(szClassname)))
	{
		CPrintToChatAll("%s %t", PLUGIN_TAG, "#Chaos_Effect_RemoveRandomEntity_Success", entity, szClassname);
	}
	
	return true;
}
