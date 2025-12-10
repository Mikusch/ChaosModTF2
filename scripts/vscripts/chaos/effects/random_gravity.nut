// by pokemonpasta

function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		// SetGravity(0.0) doesn't do anything, so we use a really small min value instead for effectively no gravity.
		player.SetGravity(RandomFloat(0.000001, 3.0))
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		player.SetGravity(1.0)
	}
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player != null && player.GetGravity() == 1.0) // unlikely for a player OnStart to have gravity be set to 1
	{
		player.SetGravity(RandomFloat(0.000001, 3.0))
	}
}
