function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.BleedPlayerEx(0, TF_BLEEDING_DMG, true, TF_DMG_CUSTOM_BLEEDING)
	}
}