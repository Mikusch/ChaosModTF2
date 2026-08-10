local TRACK_DISTANCE = 64.0 // Distance the player has to leave before the camera starts following them
local TURN_LERP_FACTOR = 0.15

function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		SetupPlayer(player)
	}
}

function ChaosEffect_Update()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		local scope = player.GetScriptScope()
		if (scope == null || !("viewcontrol" in scope))
			continue

		local viewcontrol = scope.viewcontrol
		if (viewcontrol == null || !viewcontrol.IsValid())
			continue

		// Hold the angles the player left behind until they are far enough away to aim at
		local dir = player.EyePosition() - viewcontrol.GetOrigin()
		if (dir.Norm() < TRACK_DISTANCE)
			continue

		local goal = VectorAngles(dir)
		viewcontrol.KeyValueFromVector("angles", LerpAngles(viewcontrol.GetAbsAngles(), goal, TURN_LERP_FACTOR))
	}

	return CHAOS_UPDATE_EVERY_FRAME
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetForceLocalDraw(false)
		ViewControl_Remove(player)
	}
}

function SetupPlayer(player)
{
	player.ValidateScriptScope()
	player.SetForceLocalDraw(true)

	local viewcontrol = SpawnEntityFromTable("point_viewcontrol", { origin = player.EyePosition(), angles = player.EyeAngles() })
	EntFireByHandle(viewcontrol, "Enable", "!activator", -1, player, viewcontrol)
	EntFireByHandle(player, "RunScriptCode", "ViewControl_PostEnable(self)", -1, player, null)

	player.GetScriptScope().viewcontrol <- viewcontrol
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	ViewControl_Remove(player)
	EntFireByHandle(player, "RunScriptCode", Chaos_EffectName + ".SetupPlayer(self)", -1, player, null)
}

function OnGameEvent_player_death(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	if (params.death_flags & TF_DEATHFLAG_DEADRINGER)
		return

	ViewControl_Remove(player)
}
