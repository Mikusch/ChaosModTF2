#pragma semicolon 1
#pragma newdecls required

public void Truce_OnStart()
{
	GameRules_SetProp("m_bTruceActive", true);
	SendHudNotification(HUD_NOTIFY_TRUCE_START);
}

public void Truce_OnEnd()
{
	GameRules_SetProp("m_bTruceActive", false);
	SendHudNotification(HUD_NOTIFY_TRUCE_END);
}
