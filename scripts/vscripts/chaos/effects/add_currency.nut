function ChaosEffect_OnStart()
{
	if (!GameModeUsesCurrency())
		return false

	if (!("amount" in Chaos_Data))
		return false

	local amount = Chaos_Data.amount

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (amount >= 0)
		{
			player.AddCurrency(amount)

			EntFireByHandle(player, "AddContext", "IsMvMDefender:1", -1, null, null)
			EntFireByHandle(player, "SpeakResponseConcept", "TLK_MVM_MONEY_PICKUP", -1, null, null)
			EntFireByHandle(player, "ClearContext", null, -1, null, null)
		}
		else
		{
			player.RemoveCurrency(abs(amount))
		}
	}
}