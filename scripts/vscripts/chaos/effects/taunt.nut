function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		player.Taunt(Constants.FTaunts.TAUNT_BASE_WEAPON, 0)
	}
}