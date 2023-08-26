IncludeScript("chaos_util")

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

function ChaosEffect_Update()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.ViewPunch(QAngle(0, 0, FLT_MAX))
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

function Chaos_OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	SetEyeAngles(player, 90)
}

function Chaos_OnGameEvent_player_teleported(params)
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

Chaos_CollectEventCallbacks(this)