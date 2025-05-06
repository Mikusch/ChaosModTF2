function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetForcedTauntCam(1)
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetForcedTauntCam(0)
	}
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	EntFireByHandle(player, "RunScriptCode", "self.SetForcedTauntCam(1)", -1, null, null)
}