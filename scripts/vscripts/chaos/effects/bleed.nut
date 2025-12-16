function ChaosEffect_OnStart()
{
	local duration = Chaos_Data.GetOrDefault("duration", 10.0)
	local damage = Chaos_Data.GetOrDefault("damage", TF_BLEEDING_DMG)
	local endless = Chaos_Data.GetOrDefault("endless", false)

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.BleedPlayerEx(duration, damage, endless, TF_DMG_CUSTOM_BLEEDING)
	}
}