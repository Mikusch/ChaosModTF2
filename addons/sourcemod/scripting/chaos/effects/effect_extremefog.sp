#pragma semicolon 1
#pragma newdecls required

#define SF_FOG_MASTER		0x0001

static int g_hCustomFogController = INVALID_ENT_REFERENCE;

public bool ExtremeFog_OnStart(ChaosEffect effect)
{
	if (IsValidEntity(g_hCustomFogController))
		return false;
	
	int controller = CreateEntityByName("env_fog_controller");
	if (IsValidEntity(controller))
	{
		DispatchKeyValue(controller, "fogenable", "1");
		DispatchKeyValue(controller, "fogstart", "5");
		DispatchKeyValue(controller, "fogend", "200");
		DispatchKeyValue(controller, "fogmaxdensity", "1");
		DispatchKeyValue(controller, "foglerptime", "1.5");
		DispatchKeyValue(controller, "fogcolor", "200 200 200");
		DispatchKeyValue(controller, "fogblend", "0");
		DispatchKeyValue(controller, "farz", "8400");
		DispatchSpawn(controller);
		
		SetFogController(controller);
		
		g_hCustomFogController = EntIndexToEntRef(controller);
		return true;
	}
	
	return false;
}

public void ExtremeFog_OnClientPutInServer(ChaosEffect effect, int client)
{
	SetEntPropEnt(client, Prop_Send, "m_PlayerFog.m_hCtrl", g_hCustomFogController);
}

public void ExtremeFog_OnEnd(ChaosEffect effect)
{
	RemoveEntity(g_hCustomFogController);
	g_hCustomFogController = INVALID_ENT_REFERENCE;
	
	// Find master controller first, the try others
	int controller = FindFogController(true);
	if (IsValidEntity(controller))
	{
		SetFogController(controller);
	}
	else
	{
		controller = FindFogController();
		if (IsValidEntity(controller))
		{
			SetFogController(controller);
		}
	}
}

static int FindFogController(bool bMaster = false)
{
	int controller = -1;
	while ((controller = FindEntityByClassname(controller, "env_fog_controller")) != -1)
	{
		// Don't find our custom fog controller
		if (EntRefToEntIndex(g_hCustomFogController) == controller)
			continue;
		
		if (bMaster && !(GetEntProp(controller, Prop_Data, "m_spawnflags") & SF_FOG_MASTER))
			continue;
		
		return controller;
	}
	
	return -1;
}

static void SetFogController(int controller)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetEntPropEnt(client, Prop_Send, "m_PlayerFog.m_hCtrl", controller);
	}
}
