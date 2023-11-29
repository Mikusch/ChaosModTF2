function ChaosEffect_Update()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.AddCond(TF_COND_HALLOWEEN_THRILLER)

		if (!player.IsTaunting() && player.IsAllowedToTaunt())
		{
			player.Taunt(TAUNT_BASE_WEAPON, 0)
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

		player.RemoveCond(TF_COND_HALLOWEEN_THRILLER)

		player.StopTaunt(false)
	}
}