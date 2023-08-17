function ChaosEffect_OnStart()
{
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