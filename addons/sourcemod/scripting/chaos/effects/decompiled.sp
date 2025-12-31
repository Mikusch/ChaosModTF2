#pragma semicolon 1
#pragma newdecls required

enum struct LightData
{
	char classname[64];
	float origin[3];
	float angles[3];
	int color[4];
}

enum struct VisualData
{
	int visual;
	int entity;
}

static ConVar showtriggers;
static ArrayList g_hLightData;
static ArrayList g_hCreatedVisuals;
static StringMap g_hEntityToSpriteMap;
static StringMap g_hEntityToModelMap;

public bool Decompiled_Initialize(ChaosEffect effect)
{
	showtriggers = FindConVar("showtriggers");
	
	g_hLightData = new ArrayList(sizeof(LightData));
	g_hCreatedVisuals = new ArrayList(sizeof(VisualData));
	
	g_hEntityToSpriteMap = new StringMap();
	g_hEntityToSpriteMap.SetString("ambient_generic", "editor/ambient_generic.vmt");
	g_hEntityToSpriteMap.SetString("color_correction", "editor/color_correction.vmt");
	g_hEntityToSpriteMap.SetString("env_cubemap", "editor/env_cubemap.vmt");
	g_hEntityToSpriteMap.SetString("env_global", "editor/env_global.vmt");
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
	
	// These entities have no unique visual representation, so we use obsolete
	g_hEntityToSpriteMap.SetString("env_screenoverlay", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("game_forcerespawn", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("point_template", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("point_clientcommand", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("point_hurt", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("point_servercommand", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("sky_camera", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("team_control_point_master", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("team_control_point_round", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("team_round_timer", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("team_train_watcher", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("tf_logic_arena", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("tf_logic_mann_vs_machine", "editor/obsolete.vmt");
	g_hEntityToSpriteMap.SetString("tf_gamerules", "editor/obsolete.vmt");
	
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
	
	return true;
}

public void Decompiled_OnMapStart(ChaosEffect effect)
{
	g_hLightData.Clear();
	
	// Parse entity lump for light data
	for (int i = 0; i < EntityLump.Length(); i++)
	{
		EntityLumpEntry entry = EntityLump.Get(i);
		
		int index = entry.FindKey("classname");
		if (index == -1)
			continue;
		
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
		
		delete entry;
	}
}

public bool Decompiled_OnStart(ChaosEffect effect)
{
	showtriggers.BoolValue = true;
	ShowTriggers_Toggle();
	
	Decompiled_OnRoundStart(effect);
	
	return true;
}

public void Decompiled_OnEntityCreated(ChaosEffect effect, int entity, const char[] classname)
{
	SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
}

public void Decompiled_OnEntityDestroyed(ChaosEffect effect, int entity)
{
	// If the visual is removed, remove our reference to it
	int iIndex = g_hCreatedVisuals.FindValue(EntIndexToEntRef(EntRefToEntIndex(entity)), VisualData::visual);
	if (iIndex != -1)
	{
		g_hCreatedVisuals.Erase(iIndex);
	}
	
	// If the associated entity is removed, also clear the visual
	iIndex = g_hCreatedVisuals.FindValue(EntIndexToEntRef(EntRefToEntIndex(entity)), VisualData::entity);
	if (iIndex != -1)
	{
		int visual = g_hCreatedVisuals.Get(iIndex, VisualData::visual);
		if (IsValidEntity(visual))
		{
			RemoveEntity(visual);
		}
	}
}

public void Decompiled_OnRoundStart(ChaosEffect effect)
{
	SpawnLightsFromData();
	
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "*")) != -1)
	{
		if (g_hCreatedVisuals.FindValue(EntIndexToEntRef(EntRefToEntIndex(entity)), VisualData::entity) == -1)
		{
			OnEntitySpawned(entity);
		}
	}
}

public void Decompiled_OnEnd(ChaosEffect effect)
{
	showtriggers.BoolValue = false;
	ShowTriggers_Toggle();
	
	for (int i = 0; i < g_hCreatedVisuals.Length; i++)
	{
		int visual = g_hCreatedVisuals.Get(i, VisualData::visual);
		
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
		LogMessage("No light data found! Restart the map to allow OnMapStart to parse light entities.");
		return;
	}
	
	for (int i = 0; i < g_hLightData.Length; i++)
	{
		if (!ShouldSpawnVisual())
			break;
		
		LightData lightData;
		if (g_hLightData.GetArray(i, lightData))
		{
			int visual = -1;
			
			char szModel[64];
			if (g_hEntityToSpriteMap.GetString(lightData.classname, szModel, sizeof(szModel)))
			{
				visual = CreateSprite(szModel, lightData.origin, lightData.angles);
			}
			else if (g_hEntityToModelMap.GetString(lightData.classname, szModel, sizeof(szModel)))
			{
				visual = CreateModel(szModel, lightData.origin, lightData.angles);
			}
			
			if (IsValidEntity(visual))
			{
				SetEntProp(visual, Prop_Send, "m_clrRender", Color32ToInt(lightData.color[0], lightData.color[1], lightData.color[2], 255));
				
				VisualData visualData;
				visualData.entity = -1;
				visualData.visual = EntIndexToEntRef(EntRefToEntIndex(visual));
				g_hCreatedVisuals.PushArray(visualData);
			}
		}
	}
}

static void CreateVisualFromEntity(int entity, const char[] szClassname)
{
	float vecOrigin[3], angRotation[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vecOrigin);
	GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", angRotation);
	
	if (StrEqual(szClassname, "beam"))
	{
		// No angle info, need to recover it from end position
		float vecEndPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecEndPos", vecEndPos);
		SubtractVectors(vecEndPos, vecOrigin, vecEndPos);
		GetVectorAngles(vecEndPos, angRotation);
	}
	
	char szModel[PLATFORM_MAX_PATH];
	
	int visual = -1;
	
	if (g_hEntityToSpriteMap.GetString(szClassname, szModel, sizeof(szModel)))
	{
		visual = CreateSprite(szModel, vecOrigin, angRotation);
	}
	else if (g_hEntityToModelMap.GetString(szClassname, szModel, sizeof(szModel)))
	{
		visual = CreateModel(szModel, vecOrigin, angRotation);
	}
	
	if (IsValidEntity(visual))
	{
		VisualData data;
		
		if (IsValidEntity(entity))
		{
			char szParent[64];
			if (GetEntPropString(entity, Prop_Data, "m_iParent", szParent, sizeof(szParent)))
			{
				SetVariantString(szParent);
				AcceptEntityInput(visual, "SetParent");
			}
			
			data.entity = EntIndexToEntRef(EntRefToEntIndex(entity));
		}
		else
		{
			data.entity = INVALID_ENT_REFERENCE;
		}
		
		data.visual = EntIndexToEntRef(EntRefToEntIndex(visual));
		g_hCreatedVisuals.PushArray(data);
	}
}

static int CreateSprite(const char[] szModel, const float vecOrigin[3], const float angRotation[3] = NULL_VECTOR)
{
	int sprite = CreateEntityByName("env_sprite");
	if (IsValidEntity(sprite))
	{
		DispatchKeyValueVector(sprite, "origin", vecOrigin);
		DispatchKeyValueVector(sprite, "angles", angRotation);
		DispatchKeyValue(sprite, "model", szModel);
		DispatchKeyValue(sprite, "rendermode", "1");
		DispatchSpawn(sprite);
		
		return sprite;
	}
	
	return -1;
}

static int CreateModel(const char[] szModel, const float vecOrigin[3], const float angRotation[3] = NULL_VECTOR)
{
	int prop = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(prop))
	{
		DispatchKeyValueVector(prop, "origin", vecOrigin);
		DispatchKeyValueVector(prop, "angles", angRotation);
		DispatchKeyValue(prop, "model", szModel);
		DispatchKeyValue(prop, "disableshadows", "1");
		DispatchSpawn(prop);
		
		return prop;
	}
	
	return -1;
}

static bool ShouldSpawnVisual()
{
	// Don't spawn more entities if we're already near the limit
	return float(GetNumEdicts()) / float(GetMaxEntities()) < 0.9;
}

static void ShowTriggers_Toggle()
{
	SetCommandFlags("showtriggers_toggle", GetCommandFlags("showtriggers_toggle") & ~FCVAR_CHEAT);
	ServerCommand("showtriggers_toggle");
	ServerExecute();
	SetCommandFlags("showtriggers_toggle", GetCommandFlags("showtriggers_toggle") | FCVAR_CHEAT);
}
