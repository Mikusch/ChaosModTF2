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

		EntFireByHandle(player, "AddContext", "IsMvMDefender:1", -1, null, null)
		EntFireByHandle(player, "SpeakResponseConcept", "TLK_MVM_MONEY_PICKUP", -1, null, null)
		EntFireByHandle(player, "ClearContext", null, -1, null, null)
	}
}