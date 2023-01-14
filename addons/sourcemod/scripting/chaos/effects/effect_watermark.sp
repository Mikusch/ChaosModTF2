#pragma semicolon 1
#pragma newdecls required

static Handle g_hHudSync;
static float g_flNextDisplayTime;

static ConVar hostname;

public void Watermark_Inititalize()
{
	g_hHudSync = CreateHudSynchronizer();
	hostname = FindConVar("hostname");
}

public void Watermark_OnStart()
{
	g_flNextDisplayTime = GetGameTime();
}

public void Watermark_OnGameFrame()
{
	if (g_flNextDisplayTime <= GetGameTime())
	{
		g_flNextDisplayTime = GetGameTime() + 5.0;
		
		SetHudTextParams(GetRandomFloat(), GetRandomFloat(), 5.0, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
		
		char szHostname[512];
		hostname.GetString(szHostname, sizeof(szHostname));
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			ShowSyncHudText(client, g_hHudSync, szHostname);
		}
	}
}
