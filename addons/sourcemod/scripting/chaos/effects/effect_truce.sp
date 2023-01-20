#pragma semicolon 1
#pragma newdecls required

public bool Truce_OnStart(ChaosEffect effect)
{
	if (GameRules_GetProp("m_bTruceActive"))
		return false;
	
	GameRules_SetProp("m_bTruceActive", true);
	SendHudNotification(HUD_NOTIFY_TRUCE_START);
	
	return true;
}

public void Truce_OnEnd(ChaosEffect effect)
{
	GameRules_SetProp("m_bTruceActive", false);
	SendHudNotification(HUD_NOTIFY_TRUCE_END);
}
