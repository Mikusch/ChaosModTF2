function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	if (params["class"] != Constants.ETFClass.TF_CLASS_SNIPER)
		return

	for (local i = 1; i <= MaxClients(); i++)
	{
		local other = PlayerInstanceFromIndex(i)
		if (other == null)
			continue

		if (other == player)
			continue
		
		if (other.GetTeam() == player.GetTeam())
			continue
		
		EntFireByHandle(other, "AddContext", "IsMvMDefender:1", -1, null, null)
		EntFireByHandle(other, "AddContext", "randomnum:100", -1, null, null)
		EntFireByHandle(other, "SpeakResponseConcept", "TLK_MVM_SNIPER_CALLOUT", -1, null, null)
		EntFireByHandle(other, "ClearContext", null, -1, null, null)
	}
}

function OnGameEvent_player_death(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	for (local i = 1; i <= MaxClients(); i++)
	{
		local other = PlayerInstanceFromIndex(i)
		if (other == null)
			continue

		if (other == player)
			continue
		
		if (other.GetTeam() != player.GetTeam())
			continue

		EntFireByHandle(other, "AddContext", format("victimclass:%s", PlayerClassNames[player.GetPlayerClass()]), -1, null, null)
		EntFireByHandle(other, "AddContext", "IsMvMDefender:1", -1, null, null)
		EntFireByHandle(other, "AddContext", "randomnum:100", -1, null, null)
		EntFireByHandle(other, "SpeakResponseConcept", "TLK_MVM_DEFENDER_DIED", -1, null, null)
		EntFireByHandle(other, "ClearContext", null, -1, null, null)
	}
}