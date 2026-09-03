#pragma semicolon 1
#pragma newdecls required

#define NOTHING_MAX_FAKE_NAME_LENGTH	64

public bool Nothing_OnStart(ChaosEffect effect)
{
	effect.state.SetString("fake_name", "");

	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("fake_names", false))
		return true;

	ArrayList hFakeNames = new ArrayList(ByteCountToCells(NOTHING_MAX_FAKE_NAME_LENGTH));

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char szName[NOTHING_MAX_FAKE_NAME_LENGTH];
			kv.GetString(NULL_STRING, szName, sizeof(szName));

			if (szName[0])
				hFakeNames.PushString(szName);
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();

	// Allow an empty name list
	if (hFakeNames.Length)
	{
		char szName[NOTHING_MAX_FAKE_NAME_LENGTH];
		hFakeNames.GetString(GetRandomInt(0, hFakeNames.Length - 1), szName, sizeof(szName));

		effect.state.SetString("fake_name", szName);
	}

	delete hFakeNames;
	return true;
}

public bool Nothing_ModifyEffectName(ChaosEffect effect, char[] name, int maxlength)
{
	if (effect.activate_time + 8.0 < GetGameTime())
		return false;

	char szName[NOTHING_MAX_FAKE_NAME_LENGTH];
	if (!effect.state.GetString("fake_name", szName, sizeof(szName)) || !szName[0])
		return false;

	return strcopy(name, maxlength, szName) != 0;
}
