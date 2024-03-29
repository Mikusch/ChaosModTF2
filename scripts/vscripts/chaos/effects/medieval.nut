function ChaosEffect_OnStart()
{
	if (IsInMedievalMode())
		return false

	local gamerules = Entities.FindByClassname(null, "tf_gamerules")
	if (gamerules == null)
		return false

	NetProps.SetPropBool(gamerules, "m_bPlayingMedieval", true)

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		if (!player.IsAlive())
			continue

		local health = player.GetHealth()
		player.Regenerate(false)
		player.SetHealth(health)
	}
	
	return true
}

function ChaosEffect_OnEnd()
{
	local gamerules = Entities.FindByClassname(null, "tf_gamerules")
	if (gamerules == null)
		return

	NetProps.SetPropBool(gamerules, "m_bPlayingMedieval", false)

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		if (!player.IsAlive())
			continue

		local health = player.GetHealth()
		player.Regenerate(false)
		player.SetHealth(health)
	}
}