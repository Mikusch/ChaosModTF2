IncludeScript("chaos_util")

function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (player.GetTeam() <= Constants.ETFTeam.TEAM_SPECTATOR || player.GetTeam() >= Constants.ETFTeam.TF_TEAM_COUNT)
			continue

		player.ForceChangeTeam(GetEnemyTeam(player.GetTeam()), false)
	}
}