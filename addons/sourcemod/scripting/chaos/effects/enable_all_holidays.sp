#pragma semicolon 1
#pragma newdecls required

static DynamicDetour g_hDetourIsHolidayActive;

public bool EnableAllHolidays_Initialize(ChaosEffect effect)
{
	g_hDetourIsHolidayActive = Chaos_CreateDetour("TF_IsHolidayActive");
	return g_hDetourIsHolidayActive != null;
}

public void EnableAllHolidays_OnMapStart(ChaosEffect effect)
{
	PrecacheScriptSound("Christmas.GiftDrop");
	PrecacheScriptSound("Christmas.GiftPickup");
}

public bool EnableAllHolidays_OnStart(ChaosEffect effect)
{
	if (!g_hDetourIsHolidayActive.Enable(Hook_Pre, OnIsHolidayActive))
		return false;
	
	Event hEvent = CreateEvent("recalculate_holidays");
	if (hEvent)
		hEvent.Fire();
	
	return true;
}

public void EnableAllHolidays_OnEnd(ChaosEffect effect)
{
	g_hDetourIsHolidayActive.Disable(Hook_Pre, OnIsHolidayActive);
}

static MRESReturn OnIsHolidayActive(DHookReturn hReturn, DHookParam hParam)
{
	hReturn.Value = true;
	return MRES_Supercede;
}
