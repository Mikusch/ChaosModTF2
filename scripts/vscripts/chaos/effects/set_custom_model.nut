function ChaosEffect_OnStart()
{
	local model = Chaos_GetData("model", "")
	if (model == "")
		return false

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetCustomModelWithClassAnimations(model)
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetCustomModel("")
	}
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	player.SetCustomModelWithClassAnimations(Chaos_GetData("model", ""))
}