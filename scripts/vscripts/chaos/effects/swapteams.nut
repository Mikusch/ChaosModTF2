function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (player.GetTeam() <= TEAM_SPECTATOR || player.GetTeam() >= TF_TEAM_COUNT)
			continue

		player.ForceChangeTeam(GetEnemyTeam(player.GetTeam()), false)
	}
}