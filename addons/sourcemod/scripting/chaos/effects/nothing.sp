#pragma semicolon 1
#pragma newdecls required

static ArrayList g_hFakeNames;
static char g_szFakeName[64];

public void Nothing_Initialize(ChaosEffect effect)
{
	g_hFakeNames = new ArrayList(sizeof(g_szFakeName));
	
	PopulateNameList(effect.data);
}

public bool Nothing_OnStart(ChaosEffect effect)
{
	if (!g_hFakeNames.Length)
		return false;
	
	// Select a random fake name for later
	return g_hFakeNames.GetString(GetRandomInt(0, g_hFakeNames.Length - 1), g_szFakeName, sizeof(g_szFakeName)) != 0;
}

public bool Nothing_ModifyEffectName(ChaosEffect effect, char[] szName, int iMaxLength)
{
	if (!g_szFakeName[0])
		return false;
	
	if (effect.activate_time + 5.0 >= GetGameTime())
	{
		// Prank 'em!
		return strcopy(szName, iMaxLength, g_szFakeName) != 0;
	}
	
	return false;
}

static void PopulateNameList(KeyValues kv)
{
	if (kv.JumpToKey("fake_names", false))
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				char[] szName = new char[g_hFakeNames.BlockSize];
				kv.GetString(NULL_STRING, szName, g_hFakeNames.BlockSize);
				g_hFakeNames.PushString(szName);
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
}
