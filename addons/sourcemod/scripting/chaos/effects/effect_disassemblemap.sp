#pragma semicolon 1
#pragma newdecls required

#define CONVERTER_TARGET	"chaos_physics_prop"

static char g_aBrushClassNames[][] =
{
	"func_brush",
	"func_button",
	"func_illusionary",
	"func_lod",
	"func_breakable",
};

static char g_aPropClassNames[][] =
{
	"prop_*",
	"item_*",
	"obj_*",
	"tf_dropped_weapon",
};

public bool DisassembleMap_OnStart(ChaosEffect effect)
{
	int converter = CreateEntityByName("phys_convert");
	if (IsValidEntity(converter) && DispatchSpawn(converter))
	{
		DispatchKeyValue(converter, "target", CONVERTER_TARGET);
	}
	
	// Turn brush entities into physics props
	for (int i = 0; i < sizeof(g_aBrushClassNames); i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, g_aBrushClassNames[i])) != -1)
		{
			if (CBaseEntity(entity).GetMoveType() == MOVETYPE_VPHYSICS)
				continue;
			
			DispatchKeyValue(entity, "targetname", CONVERTER_TARGET);
		}
	}
	
	AcceptEntityInput(converter, "ConvertTarget");
	
	// Turn props into soccer balls
	for (int i = 0; i < sizeof(g_aPropClassNames); i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, g_aPropClassNames[i])) != -1)
		{
			char szModel[PLATFORM_MAX_PATH];
			GetEntPropString(entity, Prop_Data, "m_ModelName", szModel, sizeof(szModel));
			
			float vecOrigin[3], angRotation[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
			GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", angRotation);
			
			int ball = CreateEntityByName("prop_soccer_ball");
			if (IsValidEntity(ball))
			{
				DispatchKeyValue(ball, "model", szModel);
				DispatchKeyValueVector(ball, "origin", vecOrigin);
				DispatchKeyValueVector(ball, "angles", angRotation);
				
				if (DispatchSpawn(ball))
				{
					RemoveEntity(entity);
				}
			}
		}
	}
	
	return true;
}
