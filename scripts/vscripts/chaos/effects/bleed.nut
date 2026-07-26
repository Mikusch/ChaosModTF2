function ChaosEffect_OnStart()
{
	local duration = Chaos_GetData("duration", 10.0)
	local damage = Chaos_GetData("damage", TF_BLEEDING_DMG)
	local endless = Chaos_GetData("endless", false)

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.BleedPlayerEx(duration, damage, endless, TF_DMG_CUSTOM_BLEEDING)
	}
}