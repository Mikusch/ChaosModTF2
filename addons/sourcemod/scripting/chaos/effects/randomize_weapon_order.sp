#pragma semicolon 1
#pragma newdecls required

static VScriptHandle g_hVScriptGetSubType;
static VScriptHandle g_hVScriptCanBeSelected;

public bool RandomizeWeaponOrder_Initialize(ChaosEffect effect)
{
	StartPrepVScriptCall(VScriptScope_EntityInstance);
	PrepVScriptCall_SetFunction("GetSubType");
	PrepVScriptCall_AddParameter(VScriptParamType_Entity);
	PrepVScriptCall_SetReturnType(VScriptReturnType_Int);
	g_hVScriptGetSubType = EndPrepVScriptCall();

	StartPrepVScriptCall(VScriptScope_EntityInstance);
	PrepVScriptCall_SetFunction("CanBeSelected");
	PrepVScriptCall_AddParameter(VScriptParamType_Entity);
	PrepVScriptCall_SetReturnType(VScriptReturnType_Bool);
	g_hVScriptCanBeSelected = EndPrepVScriptCall();

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

		StartVScriptFunc(g_hVScriptCanBeSelected);
		VScriptFunc_PushEntity(myWeapon);
		if (!FireVScriptFunc_ReturnAny())
			continue;

		hWeapons.Push(myWeapon);
	}

	if (hWeapons.Length != 0)
	{
		int newWeapon = hWeapons.Get(GetRandomInt(0, hWeapons.Length - 1));
		weapon = newWeapon;

		StartVScriptFunc(g_hVScriptGetSubType);
		VScriptFunc_PushEntity(newWeapon);
		subtype = FireVScriptFunc_ReturnAny();

		delete hWeapons;
		return Plugin_Changed;
	}
	
	delete hWeapons;
	return Plugin_Continue;
}
