function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		player.SetAbsVelocity(Vector(RandomFloat(-1000, 1000), RandomFloat(-1000, 1000), RandomFloat(500, 1000)))
	}
}