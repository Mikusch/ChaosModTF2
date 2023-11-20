function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		player.SetMoveType(Constants.EMoveType.MOVETYPE_NOCLIP, Constants.EMoveCollide.MOVECOLLIDE_DEFAULT)
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		player.SetMoveType(Constants.EMoveType.MOVETYPE_WALK, Constants.EMoveCollide.MOVECOLLIDE_DEFAULT)
	}
}

function Chaos_OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	EntFireByHandle(player, "RunScriptCode", "self.SetMoveType(Constants.EMoveType.MOVETYPE_NOCLIP, Constants.EMoveCollide.MOVECOLLIDE_DEFAULT)", -1, null, null)
}

Chaos_CollectEventCallbacks(this)