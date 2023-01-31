function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetForceLocalDraw(true)
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetForceLocalDraw(false)
	}
}

function Chaos_OnGameEvent_player_initial_spawn(params)
{
	local player = PlayerInstanceFromIndex(params.index)
	if (player == null)
		return

	player.SetForceLocalDraw(true)
}

Chaos_CollectEventCallbacks(this)