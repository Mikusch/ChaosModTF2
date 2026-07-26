#pragma semicolon 1
#pragma newdecls required

#define CONVERTER_TARGET		"chaos_physics_prop"

// CPhysConvert::InputConvertTarget only collects this many entities per input fire
#define CONVERTER_MAX_TARGETS	512

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

public bool DisassembleMap_Initialize(ChaosEffect effect)
{
	HookEvent("teamplay_round_start", EventHook_RoundStart);

	return true;
}

public bool DisassembleMap_OnStart(ChaosEffect effect)
{
	// Only activate once per round
	if (g_bActivated)
		return false;

	ArrayList hTargets = new ArrayList();

	for (int i = 0; i < sizeof(g_aClassNames); i++)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, g_aClassNames[i])) != -1)
		{
			if (GetEntityMoveType(entity) == MOVETYPE_VPHYSICS)
				continue;

			hTargets.Push(EntIndexToEntRef(entity));
		}
	}

	int converter = CreateEntityByName("phys_convert");
	if (converter == -1 || !DispatchSpawn(converter))
	{
		delete hTargets;
		return false;
	}

	int nBatch = 0;
	int nTargets = hTargets.Length;

	for (int i = 0; i < nTargets; i += CONVERTER_MAX_TARGETS)
	{
		char szTargetName[64];
		FormatEx(szTargetName, sizeof(szTargetName), "%s_%d", CONVERTER_TARGET, nBatch++);

		int nEnd = Min(i + CONVERTER_MAX_TARGETS, nTargets);
		for (int j = i; j < nEnd; j++)
		{
			int entity = EntRefToEntIndex(hTargets.Get(j));
			if (entity == -1)
				continue;

			DispatchKeyValue(entity, "targetname", szTargetName);
		}

		DispatchKeyValue(converter, "target", szTargetName);

		if (AcceptEntityInput(converter, "ConvertTarget"))
			g_bActivated = true;
	}

	delete hTargets;
	RemoveEntity(converter);

	return g_bActivated;
}

static void EventHook_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bActivated = false;
}
