#pragma semicolon 1
#pragma newdecls required

public bool NoTransmit_OnStart(ChaosEffect effect)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		SDKHook(entity, SDKHook_SetTransmit, OnEntitySetTransmit);
	}
	
	return true;
}

public void NoTransmit_OnEnd(ChaosEffect effect)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		SDKUnhook(entity, SDKHook_SetTransmit, OnEntitySetTransmit);
	}
}

public void NoTransmit_OnEntityCreated(ChaosEffect effect, int entity, const char[] classname)
{
	SDKHook(entity, SDKHook_SetTransmit, OnEntitySetTransmit);
}

static Action OnEntitySetTransmit(int entity, int client)
{
	if (entity == client)
		return Plugin_Continue;
	
	if (IsClientObserver(client))
		return Plugin_Continue;
	
	if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity") && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		return Plugin_Continue;
	
	// Hide every entity
	return Plugin_Handled;
}
