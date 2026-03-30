#pragma semicolon 1
#pragma newdecls required

static ScriptCall g_hCanBeSelected;
static ScriptCall g_hGetSubType;

public bool RandomizeWeaponOrder_Initialize(ChaosEffect effect)
{
	g_hGetSubType = new ScriptCall("GetSubType", ScriptField_Int);
	g_hCanBeSelected = new ScriptCall("CanBeSelected", ScriptField_Bool);
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
		
		g_hCanBeSelected.ExecuteInScope(VScript_GetEntityScriptScope(myWeapon));
		if (!g_hCanBeSelected.GetReturnBool())
			continue;
		
		hWeapons.Push(myWeapon);
	}
	
	if (hWeapons.Length != 0)
	{
		int newWeapon = hWeapons.Get(GetRandomInt(0, hWeapons.Length - 1));
		weapon = newWeapon;
		g_hGetSubType.ExecuteInScope(VScript_GetEntityScriptScope(newWeapon));
		subtype = g_hGetSubType.GetReturnInt();
		
		delete hWeapons;
		return Plugin_Changed;
	}
	
	delete hWeapons;
	return Plugin_Continue;
}
