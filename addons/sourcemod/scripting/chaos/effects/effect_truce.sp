#pragma semicolon 1
#pragma newdecls required

public void Truce_OnMapStart()
{
	PrecacheSound("vo/announcer_dec_missionbegins60s01.mp3");
	PrecacheSound("vo/announcer_dec_missionbegins60s03.mp3");
}

public void Truce_OnStart()
{
	GameRules_SetProp("m_bTruceActive", true);
	SendHudNotification(HUD_NOTIFY_TRUCE_START);
	
	EmitSoundToAll("vo/announcer_dec_missionbegins60s01.mp3", _, SNDCHAN_VOICE_BASE, SNDLEVEL_NONE);
	EmitSoundToAll("vo/announcer_dec_missionbegins60s03.mp3", _, SNDCHAN_VOICE_BASE, SNDLEVEL_NONE);
}

public void Truce_OnEnd()
{
	GameRules_SetProp("m_bTruceActive", false);
	SendHudNotification(HUD_NOTIFY_TRUCE_END);
}
