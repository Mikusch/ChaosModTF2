function ChaosEffect_OnStart()
{
	local players = []

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.ValidateScriptScope()
		players.push(player)
	}

	if (players.len() < 2)
		return false

	local others = players.slice(0)
	ShuffleArray(others)

	foreach (i, player in players)
	{
		for (local j = others.len() - 1; j >= 0; j--)
		{
			local other = others[j]
			if (player == other)
				continue

			local scope = player.GetScriptScope()
			scope.teleport_origin <- other.GetOrigin()
			scope.teleport_angles <- other.GetAbsAngles()
			scope.teleport_velocity <- other.GetAbsVelocity()

			// Delay it, so that other players can get our old position
			EntFireByHandle(player, "RunScriptCode", Chaos_EffectName + ".TeleportPlayer()", -1, player, null)

			others.remove(j)
			break
		}
	}
}

function TeleportPlayer()
{
	local scope = activator.GetScriptScope()
	activator.SetAbsOrigin(scope.teleport_origin)
	activator.SetAbsAngles(scope.teleport_angles)
	activator.SetAbsVelocity(scope.teleport_velocity)
	DispatchParticleEffect(activator.GetTeam() == TF_TEAM_RED ? "teleportedin_red" : "teleportedin_blue", activator.GetOrigin(), activator.GetAbsAngles() + Vector())
}