function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		player.SetMoveType(MOVETYPE_NOCLIP, MOVECOLLIDE_DEFAULT)
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

		player.SetMoveType(MOVETYPE_WALK, MOVECOLLIDE_DEFAULT)

		if (IsPlayerStuck(player))
		{
			ForcePlayerSuicide(player)
		}
	}
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	EntFireByHandle(player, "RunScriptCode", "self.SetMoveType(MOVETYPE_NOCLIP, MOVECOLLIDE_DEFAULT)", -1, null, null)
}