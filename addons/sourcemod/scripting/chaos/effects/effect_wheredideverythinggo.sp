#pragma semicolon 1
#pragma newdecls required

public void WhereDidEverythingGo_OnStart()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_SetTransmit);
	}
}

public void WhereDidEverythingGo_OnEnd()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		SDKUnhook(entity, SDKHook_SetTransmit, SDKHookCB_SetTransmit);
	}
}

public void WhereDidEverythingGo_OnEntityCreated(int entity, const char[] classname)
{
	SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_SetTransmit);
}

static Action SDKHookCB_SetTransmit(int entity, int client)
{
	if (entity == client)
		return Plugin_Continue;
	
	if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity") && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
		return Plugin_Continue;
	
	// Hide every entity
	return Plugin_Handled;
}
