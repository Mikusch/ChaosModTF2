#pragma semicolon 1
#pragma newdecls required

static Handle g_hHudSync;
static ConVar hostname;
static float g_flNextDisplayTime;

public bool Watermark_Initialize(ChaosEffect effect)
{
	g_hHudSync = CreateHudSynchronizer();
	hostname = FindConVar("hostname");
	
	return true;
}

public bool Watermark_OnStart(ChaosEffect effect)
{
	g_flNextDisplayTime = GetGameTime();
	
	return true;
}

public void Watermark_Update(ChaosEffect effect)
{
	if (g_flNextDisplayTime <= GetGameTime())
	{
		g_flNextDisplayTime = GetGameTime() + 5.0;
		
		char szHostname[512];
		hostname.GetString(szHostname, sizeof(szHostname));
		
		SetHudTextParams(GetRandomFloat(), GetRandomFloat(), 5.0, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			ShowSyncHudText(client, g_hHudSync, szHostname);
		}
	}
}
