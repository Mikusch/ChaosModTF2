#pragma semicolon 1
#pragma newdecls required

#define CONVERTER_TARGET	"chaos_physics_prop"

static char g_aClassNames[][] =
{
	"func_brush",
	"func_button",
	"func_illusionary",
	"func_lod",
	"func_breakable",
	"prop_*",
	"item_*",
};

static bool g_bActivated;

public bool DisassembleMap_OnStart(ChaosEffect effect)
{
	// Only activate once per round
	if (g_bActivated)
		return false;
	
	int converter = CreateEntityByName("phys_convert");
	if (IsValidEntity(converter) && DispatchSpawn(converter))
	{
		DispatchKeyValue(converter, "target", CONVERTER_TARGET);
	}
	
	// Turn brush entities into physics props
	for (int i = 0; i < sizeof(g_aClassNames); i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, g_aClassNames[i])) != -1)
		{
			if (view_as<MoveType>(GetEntProp(entity, Prop_Data, "m_MoveType")) == MOVETYPE_VPHYSICS)
				continue;
			
			DispatchKeyValue(entity, "targetname", CONVERTER_TARGET);
		}
	}
	
	g_bActivated = AcceptEntityInput(converter, "ConvertTarget");
	RemoveEntity(converter);
	
	return g_bActivated;
}

public void DisassembleMap_OnRoundStart(ChaosEffect effect)
{
	g_bActivated = false;
}
