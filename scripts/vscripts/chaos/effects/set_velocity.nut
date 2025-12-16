function ChaosEffect_OnStart()
{
	if (!("velocity" in Chaos_Data))
		return false

	local velocity = Chaos_Data.velocity
	local abs = Chaos_Data.GetOrDefault("abs", false)

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		player.SetAbsVelocity(abs ? player.GetAbsVelocity() + velocity : velocity)
	}
}