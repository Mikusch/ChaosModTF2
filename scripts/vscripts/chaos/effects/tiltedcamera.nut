function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		SetEyeAngles(player, 90)
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		SetEyeAngles(player, 0)
	}
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	SetEyeAngles(player, 90)
}

function OnGameEvent_player_teleported(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	SetEyeAngles(player, 90)
}

function SetEyeAngles(player, z)
{
	local angles = player.EyeAngles()
	angles.z = z
	player.SnapEyeAngles(angles)
}