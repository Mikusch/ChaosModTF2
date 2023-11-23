#pragma semicolon 1
#pragma newdecls required

static Handle g_hSDKCallCanDeploy;
static Handle g_hSDKCallCanBeSelected;
static Handle g_hSDKCallGetSubType;

public bool RandomizeWeaponOrder_Initialize(ChaosEffect effect, GameData gameconf)
{
	if (!gameconf)
		return false;
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gameconf, SDKConf_Virtual, "CBaseCombatWeapon::CanDeploy");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	g_hSDKCallCanDeploy = EndPrepSDKCall();
	
	VScriptFunction hScriptGetSubType = VScript_GetClassFunction("CBaseCombatWeapon", "GetSubType");
	if (hScriptGetSubType)
		g_hSDKCallGetSubType = hScriptGetSubType.CreateSDKCall();
	
	VScriptFunction hScriptCanBeSelected = VScript_GetClassFunction("CBaseCombatWeapon", "CanBeSelected");
	if (hScriptCanBeSelected)
		g_hSDKCallCanBeSelected = hScriptCanBeSelected.CreateSDKCall();
	
	return g_hSDKCallCanDeploy && g_hSDKCallGetSubType && g_hSDKCallCanBeSelected;
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
	
	int iLength = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	for (int i = 0; i < iLength; i++)
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
