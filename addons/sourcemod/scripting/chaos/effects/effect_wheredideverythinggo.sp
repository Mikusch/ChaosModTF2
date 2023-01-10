#pragma semicolon 1
#pragma newdecls required

public void WhereDidEverythingGo_OnStart()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		SetEntProp(entity, Prop_Data, "m_fEffects", GetEntProp(entity, Prop_Data, "m_fEffects") | EF_NODRAW);
	}
}

public void WhereDidEverythingGo_OnEnd()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		SetEntProp(entity, Prop_Data, "m_fEffects", GetEntProp(entity, Prop_Data, "m_fEffects") & ~EF_NODRAW);
	}
}
