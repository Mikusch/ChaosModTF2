#pragma semicolon 1
#pragma newdecls required

#define WATERMARK_DISPLAY_TIME	5.0

static Handle g_hHudSync;
static ConVar hostname;

public bool Watermark_Initialize(ChaosEffect effect)
{
	g_hHudSync = CreateHudSynchronizer();
	hostname = FindConVar("hostname");

	return true;
}

public float Watermark_Update(ChaosEffect effect)
{
	char szHostname[512];
	hostname.GetString(szHostname, sizeof(szHostname));

	SetHudTextParams(GetRandomFloat(), GetRandomFloat(), WATERMARK_DISPLAY_TIME, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		ShowSyncHudText(client, g_hHudSync, "%s", szHostname);
	}

	return WATERMARK_DISPLAY_TIME;
}
