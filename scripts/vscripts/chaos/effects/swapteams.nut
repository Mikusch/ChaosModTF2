function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (player.GetTeam() <= Constants.ETFTeam.TEAM_SPECTATOR)
			continue

		player.ForceChangeTeam(player.GetTeam() == Constants.ETFTeam.TF_TEAM_RED ? Constants.ETFTeam.TF_TEAM_BLUE : Constants.ETFTeam.TF_TEAM_RED, false)
	}
}