function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.AddCustomAttribute("SET BONUS: calling card on kill", RandomFloat(1, 4), -1)
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.RemoveCustomAttribute("SET BONUS: calling card on kill")
	}
}

function Chaos_OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	EntFireByHandle(player, "RunScriptCode", Chaos_EffectName + ".PostPlayerSpawn()", 0, player, player)
}

function PostPlayerSpawn()
{
	if (activator == null)
		return

    activator.AddCustomAttribute("SET BONUS: calling card on kill", RandomFloat(1, 4), -1)
}

Chaos_CollectEventCallbacks(this)