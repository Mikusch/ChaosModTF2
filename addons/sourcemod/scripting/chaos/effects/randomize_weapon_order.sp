#pragma semicolon 1
#pragma newdecls required

static Handle g_hSDKCallCanBeSelected;
static Handle g_hSDKCallGetSubType;

public bool RandomizeWeaponOrder_Initialize(ChaosEffect effect)
{
	VScriptFunction hScriptGetSubType = VScript_GetClassFunction("CBaseCombatWeapon", "GetSubType");
	if (hScriptGetSubType)
		g_hSDKCallGetSubType = hScriptGetSubType.CreateSDKCall();

	if (!g_hSDKCallGetSubType)
	{
		LogError("Failed to create SDKCall for CBaseCombatWeapon::GetSubType");
		return false;
	}

	VScriptFunction hScriptCanBeSelected = VScript_GetClassFunction("CBaseCombatWeapon", "CanBeSelected");
	if (hScriptCanBeSelected)
		g_hSDKCallCanBeSelected = hScriptCanBeSelected.CreateSDKCall();

	if (!g_hSDKCallCanBeSelected)
	{
		LogError("Failed to create SDKCall for CBaseCombatWeapon::CanBeSelected");
		return false;
	}

	return true;
}

public Action RandomizeWeaponOrder_OnPlayerRunCmd(ChaosEffect effect, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if (weapon == 0)
		return Plugin_Continue;
	
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon == activeWeapon)
		return Plugin_Continue;
	
	ArrayList hWeapons = new ArrayList();
	
	int nMaxWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	for (int i = 0; i < nMaxWeapons; i++)
	{
		int myWeapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (myWeapon == -1)
			continue;
		
		if (myWeapon == activeWeapon)
			continue;
		
		if (!SDKCall(g_hSDKCallCanBeSelected, myWeapon))
			continue;
		
		hWeapons.Push(myWeapon);
	}
	
	if (hWeapons.Length != 0)
	{
		int newWeapon = hWeapons.Get(GetRandomInt(0, hWeapons.Length - 1));
		weapon = newWeapon;
		subtype = SDKCall(g_hSDKCallGetSubType, newWeapon);
		
		delete hWeapons;
		return Plugin_Changed;
	}
	
	delete hWeapons;
	return Plugin_Continue;
}
