#pragma semicolon 1
#pragma newdecls required

enum struct FogControllerData
{
	int hController;
	float flFogEnd;
}

static ArrayList g_hOldFogStarts;

public void ExtremeFog_Initialize(ChaosEffect effect)
{
	g_hOldFogStarts = new ArrayList(sizeof(FogControllerData));
}

public bool ExtremeFog_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	float flFogEnd = effect.data.GetFloat("fog_end");
	
	int controller = -1;
	while ((controller = FindEntityByClassname(controller, "env_fog_controller")) != -1)
	{
		// Save old fog controller data
		FogControllerData data;
		data.hController = EntIndexToEntRef(controller);
		data.flFogEnd = GetEntPropFloat(controller, Prop_Send, "m_fog.end");
		g_hOldFogStarts.PushArray(data);
		
		SetEntPropFloat(controller, Prop_Send, "m_fog.end", flFogEnd);
	}
	
	return g_hOldFogStarts.Length != 0;
}

public void ExtremeFog_OnEnd(ChaosEffect effect)
{
	int controller = -1;
	while ((controller = FindEntityByClassname(controller, "env_fog_controller")) != -1)
	{
		int index = g_hOldFogStarts.FindValue(EntIndexToEntRef(controller), FogControllerData::hController);
		if (index == -1)
			continue;
		
		// Reset fog controller from stored data
		SetEntPropFloat(controller, Prop_Send, "m_fog.end", g_hOldFogStarts.Get(index, FogControllerData::flFogEnd));
		
		g_hOldFogStarts.Erase(index);
	}
}
