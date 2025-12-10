#pragma semicolon 1
#pragma newdecls required

static DynamicHook g_hDHookOnWeaponSound;
static ArrayList g_hDynamicHookIds;

public bool Headshots_Initialize(ChaosEffect effect)
{
	g_hDynamicHookIds = new ArrayList();

	g_hDHookOnWeaponSound = Chaos_CreateDynamicHook("CBaseCombatWeapon::WeaponSound");
	return g_hDHookOnWeaponSound != null;
}

public bool Headshots_OnStart(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SDKHook(client, SDKHook_TraceAttack, OnPlayerTraceAttack);
		SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
		
		int iLength = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
		for (int i = 0; i < iLength; i++)
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;
			
			int iHookId = g_hDHookOnWeaponSound.HookEntity(Hook_Pre, weapon, OnWeaponSound, OnWeaponSoundHookRemoved);
			if (iHookId != INVALID_HOOK_ID)
				g_hDynamicHookIds.Push(iHookId);
		}
	}
	
	return true;
}

public void Headshots_OnEnd(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SDKUnhook(client, SDKHook_TraceAttack, OnPlayerTraceAttack);
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
	}
	
	for (int i = g_hDynamicHookIds.Length - 1; i >= 0; i--)
	{
		int hookid = g_hDynamicHookIds.Get(i);
		DynamicHook.RemoveHook(hookid);
	}
}

public void Headshots_OnClientPutInServer(ChaosEffect effect, int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnPlayerTraceAttack);
	SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

static Action OnPlayerTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	damagetype |= DMG_USE_HITLOCATIONS;
	return Plugin_Changed;
}

static void OnWeaponEquipPost(int client, int weapon)
{
	int iHookId = g_hDHookOnWeaponSound.HookEntity(Hook_Pre, weapon, OnWeaponSound, OnWeaponSoundHookRemoved);
	if (iHookId != INVALID_HOOK_ID)
		g_hDynamicHookIds.Push(iHookId);
}

static MRESReturn OnWeaponSound(int weapon, DHookParam hParams)
{
	// Miniguns and Flame Throwers do not support burst sounds
	int weaponID = TF2Util_GetWeaponID(weapon);
	return weaponID == TF_WEAPON_MINIGUN || weaponID == TF_WEAPON_FLAMETHROWER ? MRES_Supercede : MRES_Ignored;
}

static void OnWeaponSoundHookRemoved(int iHookId)
{
	int iIndex = g_hDynamicHookIds.FindValue(iHookId);
	if (iIndex != -1)
		g_hDynamicHookIds.Erase(iIndex);
}
