function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		local angles = player.EyeAngles()
		angles.y += 180

		player.SnapEyeAngles(angles)
		player.SetAbsVelocity(player.GetAbsVelocity() * -1)
	}
}