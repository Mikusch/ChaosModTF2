function ChaosEffect_OnStart()
{
	local gamerules = Entities.FindByClassname(null, "tf_gamerules")
	if (gamerules == null)
		return false
	
	if (!GameModeUsesCurrency())
		return false
	
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		player.AddCurrency(30000)
	}
	
	return true
}