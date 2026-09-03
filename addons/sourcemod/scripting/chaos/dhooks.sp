#pragma semicolon 1
#pragma newdecls required

DynamicDetour DHooks_CreateDetour(const char[] name)
{
	GameData gameconf;
	if (!LoadGameData(gameconf))
		return null;

	DynamicDetour detour = DynamicDetour.FromConf(gameconf, name);
	delete gameconf;

	if (!detour)
	{
		LogError("Failed to create detour for '%s'", name);
		return null;
	}

	return detour;
}

DynamicHook DHooks_CreateVirtual(const char[] name)
{
	GameData gameconf;
	if (!LoadGameData(gameconf))
		return null;

	DynamicHook hook = DynamicHook.FromConf(gameconf, name);
	delete gameconf;

	if (!hook)
	{
		LogError("Failed to create virtual hook for '%s'", name);
		return null;
	}

	return hook;
}
