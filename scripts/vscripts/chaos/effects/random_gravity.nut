// by pokemonpasta

// SetGravity(0.0) means "use sv_gravity", so we use a really small min value instead for effectively no gravity.
local GRAVITY_MIN = 0.000001
local GRAVITY_MAX = 3.0

function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetGravity(RandomFloat(GRAVITY_MIN, GRAVITY_MAX))
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetGravity(0.0)
	}
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	player.SetGravity(RandomFloat(GRAVITY_MIN, GRAVITY_MAX))
}
