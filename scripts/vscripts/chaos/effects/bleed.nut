function ChaosEffect_OnStart()
{
	local duration = ("duration" in Chaos_Data) ? Chaos_Data.duration : 10.0
	local damage = ("damage" in Chaos_Data) ? Chaos_Data.damage : TF_BLEEDING_DMG
	local endless = ("endless" in Chaos_Data) ? Chaos_Data.endless : false

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.BleedPlayerEx(duration, damage, endless, TF_DMG_CUSTOM_BLEEDING)
	}
}