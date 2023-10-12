function ChaosEffect_Update()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.AddCond(Constants.ETFCond.TF_COND_HALLOWEEN_THRILLER)

		if (!player.InCond(Constants.ETFCond.TF_COND_TAUNTING) && player.IsAllowedToTaunt())
		{
			player.Taunt(Constants.FTaunts.TAUNT_BASE_WEAPON, 0)
		}
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.RemoveCond(Constants.ETFCond.TF_COND_HALLOWEEN_THRILLER)

		player.StopTaunt(false)
	}
}