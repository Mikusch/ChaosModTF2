#pragma semicolon 1
#pragma newdecls required

static ArrayList g_hFakeNames;
static char g_szFakeName[64];

public bool Nothing_Initialize(ChaosEffect effect)
{
	if (!effect.data)
		return true;
	
	KeyValues data = effect.data;
	
	if (data.JumpToKey("fake_names", false))
	{
		g_hFakeNames = new ArrayList(sizeof(g_szFakeName));
		
		if (data.GotoFirstSubKey(false))
		{
			do
			{
				char[] szName = new char[g_hFakeNames.BlockSize];
				data.GetString(NULL_STRING, szName, g_hFakeNames.BlockSize);
				g_hFakeNames.PushString(szName);
			}
			while (data.GotoNextKey(false));
			data.GoBack();
		}
		data.GoBack();
	}
	
	return true;
}

public bool Nothing_OnStart(ChaosEffect effect)
{
	g_szFakeName[0] = EOS;
	
	// Allow an empty name list
	if (!g_hFakeNames || g_hFakeNames.Length == 0)
		return true;
	
	// Select a random fake name for later
	return g_hFakeNames.GetString(GetRandomInt(0, g_hFakeNames.Length - 1), g_szFakeName, sizeof(g_szFakeName)) != 0;
}

public bool Nothing_ModifyEffectName(ChaosEffect effect, char[] name, int maxlength)
{
	if (!g_szFakeName[0])
		return false;
	
	if (effect.activate_time + 8.0 < GetGameTime())
		return false;
	
	return strcopy(name, maxlength, g_szFakeName);
}
