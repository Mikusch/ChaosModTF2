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
	
	char szClassname[64];
	if (GetEntityClassname(entity, szClassname, sizeof(szClassname)))
	{
		char szName[64];
		if (!GetEntPropString(entity, Prop_Data, "m_iName", szName, sizeof(szName)) || !szName[0])
		{
			strcopy(szName, sizeof(szName), szClassname);
		}
		
		CPrintToChatAll("%t%t", "#Chaos_Tag", "#Chaos_Effect_RemoveRandomEntity_Removing", szClassname, szName);
	}
	
	RequestFrame(RequestFrame_RemoveEntity, EntIndexToEntRef(entity));
	
	return true;
}

static void RequestFrame_RemoveEntity(int ref)
{
	if (IsValidEntity(ref))
	{
		RemoveEntity(ref);
	}
}
