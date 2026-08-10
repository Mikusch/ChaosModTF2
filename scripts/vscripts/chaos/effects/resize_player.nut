function ChaosEffect_OnStart()
{
	local scale = Chaos_GetData("scale", 1.0)
	if (scale == 1.0)
		return false

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		Resize(player, scale)
	}
}

function ChaosEffect_Update()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		KillPlayerIfStuck(player)
	}
}

function ChaosEffect_OnEnd()
{
	local change_duration = Chaos_GetData("change_duration", 0.0)

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetModelScale(1.0, change_duration)
		player.RemoveCustomAttribute("voice pitch scale")

		EntFireByHandle(player, "RunScriptCode", "KillPlayerIfStuck(self)", change_duration, null, null)
	}
}

function Resize(player, scale)
{
	player.SetModelScale(scale, Chaos_GetData("change_duration", 0.0))
	player.AddCustomAttribute("voice pitch scale", 1.0 / scale, -1)
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	Resize(player, Chaos_GetData("scale", 1.0))
}