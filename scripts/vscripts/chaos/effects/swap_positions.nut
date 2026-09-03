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

	ShuffleArray(players)

	foreach (i, player in players)
	{
		local other = players[(i + 1) % players.len()]

		local scope = player.GetScriptScope()
		scope.teleport_origin <- other.GetOrigin()
		scope.teleport_angles <- other.GetAbsAngles()
		scope.teleport_velocity <- other.GetAbsVelocity()
		scope.TeleportPlayer <- TeleportPlayer

		// Delay it, so that other players can get our old position
		EntFireByHandle(player, "CallScriptFunction", "TeleportPlayer", -1, player, null)
	}
}

function TeleportPlayer()
{
	local scope = self.GetScriptScope()
	self.SetAbsOrigin(scope.teleport_origin)
	self.SetAbsAngles(scope.teleport_angles)
	self.SetAbsVelocity(scope.teleport_velocity)
	DispatchParticleEffect(self.GetTeam() == TF_TEAM_RED ? "teleportedin_red" : "teleportedin_blue", self.GetOrigin(), self.GetAbsAngles() + Vector())
}