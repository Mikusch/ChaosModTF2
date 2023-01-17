#pragma semicolon 1
#pragma newdecls required

public bool RemoveRandomEntity_OnStart(ChaosEffect effect)
{
	ArrayList entities = new ArrayList();
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (entity <= MaxClients)
			continue;
		
		entities.Push(entity);
	}
	
	if (!entities.Length)
	{
		delete entities;
		return false;
	}
	
	entity = entities.Get(GetRandomInt(0, entities.Length - 1));
	delete entities;
	
	RemoveEntity(entity);
	
	char szClassname[64];
	if (GetEntityClassname(entity, szClassname, sizeof(szClassname)))
	{
		CPrintToChatAll("%s %t", PLUGIN_TAG, "#Chaos_Effect_RemoveRandomEntity_Success", entity, szClassname);
	}
	
	return true;
}
