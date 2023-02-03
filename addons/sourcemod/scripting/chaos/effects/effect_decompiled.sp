#pragma semicolon 1
#pragma newdecls required

enum struct LightData
{
	char classname[64];
	float origin[3];
	float angles[3];
	int color[4];
}

static ConVar showtriggers;
static ArrayList g_hLightData;
static ArrayList g_hCreatedVisuals;
static StringMap g_hEntityToSpriteMap;
static StringMap g_hEntityToModelMap;

public void Decompiled_Initialize(ChaosEffect effect)
{
	showtriggers = FindConVar("showtriggers");
	
	g_hLightData = new ArrayList(sizeof(LightData));
	g_hCreatedVisuals = new ArrayList();
	
	g_hEntityToSpriteMap = new StringMap();
	g_hEntityToSpriteMap.SetString("ambient_generic", "editor/ambient_generic.vmt");
	g_hEntityToSpriteMap.SetString("color_correction", "editor/color_correction.vmt");
	g_hEntityToSpriteMap.SetString("env_cubemap", "editor/env_cubemap.vmt");
	g_hEntityToSpriteMap.SetString("env_global", "editor/env_global.vmt");
	g_hEntityToSpriteMap.SetString("env_global", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("env_explosion", "editor/env_explosion.vmt");
	g_hEntityToSpriteMap.SetString("env_fog_controller", "editor/fog_controller.vmt");
	g_hEntityToSpriteMap.SetString("env_shake", "editor/env_shake.vmt");
	g_hEntityToSpriteMap.SetString("env_spark", "editor/env_spark.vmt");
	g_hEntityToSpriteMap.SetString("env_soundscape", "editor/env_soundscape.vmt");
	g_hEntityToSpriteMap.SetString("env_soundscape_proxy", "editor/env_soundscape.vmt");
	g_hEntityToSpriteMap.SetString("env_tonemap_controller", "editor/env_tonemap_controller.vmt");
	g_hEntityToSpriteMap.SetString("filter_activator_class", "editor/filter_class.vmt");
	g_hEntityToSpriteMap.SetString("filter_activator_name", "editor/filter_name.vmt");
	g_hEntityToSpriteMap.SetString("filter_activator_team", "editor/filter_team.vmt");
	g_hEntityToSpriteMap.SetString("filter_activator_tfteam", "editor/filter_team.vmt");
	g_hEntityToSpriteMap.SetString("filter_enemy", "editor/filter_class.vmt");
	g_hEntityToSpriteMap.SetString("filter_multi", "editor/filter_multiple.vmt");
	g_hEntityToSpriteMap.SetString("filter_tf_class", "editor/filter_class.vmt");
	g_hEntityToSpriteMap.SetString("game_end", "editor/game_end.vmt");
	g_hEntityToSpriteMap.SetString("game_round_win", "editor/game_text.vmt");
	g_hEntityToSpriteMap.SetString("game_text", "editor/game_text.vmt");
	g_hEntityToSpriteMap.SetString("info_landmark", "editor/info_landmark.vmt");
	g_hEntityToSpriteMap.SetString("info_target", "editor/info_target.vmt");
	g_hEntityToSpriteMap.SetString("light", "editor/light.vmt");
	g_hEntityToSpriteMap.SetString("light_dynamic", "editor/light.vmt");
	g_hEntityToSpriteMap.SetString("light_environment", "editor/light_env.vmt");
	g_hEntityToSpriteMap.SetString("logic_auto", "editor/logic_auto.vmt");
	g_hEntityToSpriteMap.SetString("logic_branch", "editor/logic_branch.vmt");
	g_hEntityToSpriteMap.SetString("logic_case", "editor/logic_case.vmt");
	g_hEntityToSpriteMap.SetString("logic_compare", "editor/logic_compare.vmt");
	g_hEntityToSpriteMap.SetString("logic_eventlistener", "editor/logic_eventlistener.vmt");
	g_hEntityToSpriteMap.SetString("logic_multicompare", "editor/logic_multicompare.vmt");
	g_hEntityToSpriteMap.SetString("logic_relay", "editor/logic_relay.vmt");
	g_hEntityToSpriteMap.SetString("logic_script", "editor/logic_script.vmt");
	g_hEntityToSpriteMap.SetString("logic_timer", "editor/logic_timer.vmt");
	g_hEntityToSpriteMap.SetString("math_counter", "editor/math_counter.vmt");
	g_hEntityToSpriteMap.SetString("mapobj_cart_dispenser", "editor/bullseye.vmt");
	g_hEntityToSpriteMap.SetString("phys_ballsocket", "editor/phys_ballsocket.vmt");
	g_hEntityToSpriteMap.SetString("shadow_control", "editor/shadow_control.vmt");
	g_hEntityToSpriteMap.SetString("water_lod_control", "editor/waterlodcontrol.vmt");
	
	g_hEntityToModelMap = new StringMap();
	g_hEntityToModelMap.SetString("beam", "models/editor/cone_helper.mdl");
	g_hEntityToModelMap.SetString("bot_hint_engineer_nest", "models/bots/engineer/bot_engineer.mdl");
	g_hEntityToModelMap.SetString("bot_hint_sentrygun", "models/buildables/sentry3.mdl");
	g_hEntityToModelMap.SetString("bot_hint_sniper_spot", "models/player/sniper.mdl");
	g_hEntityToModelMap.SetString("bot_hint_teleporter_exit", "models/buildables/teleporter_blueprint_exit.mdl");
	g_hEntityToModelMap.SetString("env_steam", "models/editor/spot_cone.mdl");
	g_hEntityToModelMap.SetString("game_intro_viewpoint", "models/editor/camera.mdl");
	g_hEntityToModelMap.SetString("info_observer_point", "models/editor/camera.mdl");
	g_hEntityToModelMap.SetString("info_particle_system", "models/editor/cone_helper.mdl");
	g_hEntityToModelMap.SetString("info_player_teamspawn", "models/editor/playerstart.mdl");
	g_hEntityToModelMap.SetString("info_teleport_destination", "models/editor/playerstart.mdl");
	g_hEntityToModelMap.SetString("light_spot", "models/editor/spot.mdl");
	g_hEntityToModelMap.SetString("keyframe_rope", "models/editor/axis_helper_thick.mdl");
	g_hEntityToModelMap.SetString("move_rope", "models/editor/axis_helper_thick.mdl");
	g_hEntityToModelMap.SetString("path_track", "models/editor/ground_node.mdl");
	g_hEntityToModelMap.SetString("phys_constraint", "models/editor/axis_helper.mdl");
	g_hEntityToModelMap.SetString("point_devshot_camera", "models/editor/camera.mdl");
	g_hEntityToModelMap.SetString("scripted_sequence", "models/editor/scriptedsequence.mdl");
}

public void Decompiled_OnMapInit(ChaosEffect effect, const char[] mapName)
{
	g_hLightData.Clear();
	
	// Parse entity lump for light data
	for (int i = 0; i < EntityLump.Length(); i++)
	{
		EntityLumpEntry entry = EntityLump.Get(i);
		
		int index = -1;
		while ((index = entry.FindKey("classname", index)) != -1)
		{
			char classname[64];
			entry.Get(index, _, _, classname, sizeof(classname));
			
			if (!StrEqual(classname, "light") && !StrEqual(classname, "light_spot") && !StrEqual(classname, "light_environment"))
				continue;
			
			LightData data;
			
			strcopy(data.classname, sizeof(data.classname), classname);
			
			char value[64];
			if (entry.GetNextKey("_light", value, sizeof(value)) != -1)
			{
				StringToColor(value, data.color);
			}
			
			if (entry.GetNextKey("origin", value, sizeof(value)) != -1)
			{
				StringToVector(value, data.origin);
			}
			
			if (entry.GetNextKey("angles", value, sizeof(value)) != -1)
			{
				StringToVector(value, data.angles);
				
				if (entry.GetNextKey("pitch", value, sizeof(value)) != -1)
				{
					float angle = StringToFloat(value);
					data.angles[0] = -angle;
				}
			}
			
			g_hLightData.PushArray(data);
		}
		
		delete entry;
	}
}

public bool Decompiled_OnStart(ChaosEffect effect)
{
	showtriggers.BoolValue = true;
	ShowTriggers_Toggle();
	
	SpawnLightsFromData();
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		OnEntitySpawned(entity);
	}
	
	return true;
}

public void Decompiled_OnEntityCreated(ChaosEffect effect, int entity, const char[] classname)
{
	SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
}

public void Decompiled_OnEnd(ChaosEffect effect)
{
	showtriggers.BoolValue = false;
	ShowTriggers_Toggle();
	
	for (int i = 0; i < g_hCreatedVisuals.Length; i++)
	{
		int visual = g_hCreatedVisuals.Get(i);
		
		if (!IsValidEntity(visual))
			continue;
		
		RemoveEntity(visual);
	}
	
	g_hCreatedVisuals.Clear();
}

static void OnEntitySpawned(int entity)
{
	if (ShouldSpawnVisual())
	{
		char szClassname[64];
		if (GetEntityClassname(entity, szClassname, sizeof(szClassname)))
		{
			CreateVisualFromEntity(entity, szClassname);
		}
	}
}

static void SpawnLightsFromData()
{
	if (g_hLightData.Length == 0)
	{
		LogMessage("No light data found! Restart the map to allow OnMapInit to parse light entities.");
		return;
	}
	
	for (int i = 0; i < g_hLightData.Length; i++)
	{
		if (!ShouldSpawnVisual())
			break;
		
		LightData data;
		if (g_hLightData.GetArray(i, data))
		{
			int visual = -1;
			
			char szModel[64];
			if (g_hEntityToSpriteMap.GetString(data.classname, szModel, sizeof(szModel)))
			{
				visual = CreateSprite(szModel, data.origin, data.angles);
			}
			else if (g_hEntityToModelMap.GetString(data.classname, szModel, sizeof(szModel)))
			{
				visual = CreateModel(szModel, data.origin, data.angles);
			}
			
			if (IsValidEntity(visual))
			{
				SetEntProp(visual, Prop_Send, "m_clrRender", Color32ToInt(data.color[0], data.color[1], data.color[2], 255));
			}
		}
	}
}

static void CreateVisualFromEntity(int entity, const char[] szClassname)
{
	float vecOrigin[3], angRotation[3];
	CBaseEntity(entity).GetAbsOrigin(vecOrigin);
	CBaseEntity(entity).GetAbsAngles(angRotation);
	
	if (StrEqual(szClassname, "beam"))
	{
		// no angle info, need to recover it from end position
		float vecEndPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecEndPos", vecEndPos);
		SubtractVectors(vecEndPos, vecOrigin, vecEndPos);
		GetVectorAngles(vecEndPos, angRotation);
	}
	
	char szModel[PLATFORM_MAX_PATH];
	
	if (g_hEntityToSpriteMap.GetString(szClassname, szModel, sizeof(szModel)))
	{
		CreateSprite(szModel, vecOrigin, angRotation, entity);
	}
	else if (g_hEntityToModelMap.GetString(szClassname, szModel, sizeof(szModel)))
	{
		CreateModel(szModel, vecOrigin, angRotation, entity);
	}
}

static int CreateSprite(const char[] szModel, const float vecOrigin[3], const float angRotation[3] = NULL_VECTOR, int entity = -1)
{
	int sprite = CreateEntityByName("env_sprite");
	if (IsValidEntity(sprite))
	{
		DispatchKeyValueVector(sprite, "origin", vecOrigin);
		DispatchKeyValueVector(sprite, "angles", angRotation);
		DispatchKeyValue(sprite, "model", szModel);
		DispatchKeyValue(sprite, "rendermode", "1");
		
		if (DispatchSpawn(sprite) && IsValidEntity(entity))
		{
			char szParent[64];
			if (GetEntPropString(entity, Prop_Data, "m_iParent", szParent, sizeof(szParent)))
			{
				SetVariantString(szParent);
				AcceptEntityInput(sprite, "SetParent");
			}
		}
		
		g_hCreatedVisuals.Push(EntIndexToEntRef(sprite));
		return sprite;
	}
	
	return -1;
}

static int CreateModel(const char[] szModel, const float vecOrigin[3], const float angRotation[3] = NULL_VECTOR, int entity = -1)
{
	int prop = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(prop))
	{
		DispatchKeyValueVector(prop, "origin", vecOrigin);
		DispatchKeyValueVector(prop, "angles", angRotation);
		DispatchKeyValue(prop, "model", szModel);
		DispatchKeyValue(prop, "disableshadows", "1");
		
		if (DispatchSpawn(prop) && IsValidEntity(entity))
		{
			char szParent[64];
			if (GetEntPropString(entity, Prop_Data, "m_iParent", szParent, sizeof(szParent)))
			{
				SetVariantString(szParent);
				AcceptEntityInput(prop, "SetParent");
			}
		}
		
		g_hCreatedVisuals.Push(EntIndexToEntRef(prop));
		return prop;
	}
	
	return -1;
}

static int GetCurrentEntities()
{
	int nCurrentEntities = 0;
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		nCurrentEntities++;
	}
	
	return nCurrentEntities;
}

static bool ShouldSpawnVisual()
{
	// Don't spawn more entities if we're already near the limit
	return float(GetCurrentEntities()) / float(GetMaxEntities()) < 0.9;
}

static void ShowTriggers_Toggle()
{
	// Remove FCVAR_CHEAT to allow us to call it without cheats
	SetCommandFlags("showtriggers_toggle", GetCommandFlags("showtriggers_toggle") & ~FCVAR_CHEAT);
	ServerCommand("showtriggers_toggle");
	SetCommandFlags("showtriggers_toggle", GetCommandFlags("showtriggers_toggle") | FCVAR_CHEAT);
}
