function ChaosEffect_OnStart()
{
	if (!("duration" in Chaos_Data))
		return false

	local duration = Chaos_Data.duration
	local damage = ("damage" in Chaos_Data) ? Chaos_Data.damage : TF_BLEEDING_DMG

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.BleedPlayerEx(duration, damage, true, TF_DMG_CUSTOM_BLEEDING)
	}
}