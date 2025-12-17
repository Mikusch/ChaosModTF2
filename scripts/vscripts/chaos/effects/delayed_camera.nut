function GetPlayerEyeTransform(player)
{
	foreach (name in ["eyes", "head"])
	{
		local attachment = player.LookupAttachment(name)
		if (attachment == 0)
			continue

		return { origin = player.GetAttachmentOrigin(attachment), angles = player.GetAttachmentAngles(attachment) }
	}

	return { origin = player.EyePosition(), angles = player.EyeAngles() }
}

function ChaosEffect_OnStart()
{
	if (!("delay" in Chaos_Data))
		return false

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
	local history_size = (Chaos_Data.delay / FrameTime()).tointeger() + 1

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		local scope = player.GetScriptScope()
		if (!("position_history" in scope))
			continue

		local viewcontrol = scope.viewcontrol
		if (viewcontrol == null || !viewcontrol.IsValid())
			continue

		local eye_transform = GetPlayerEyeTransform(player)
		scope.position_history.push({
			origin = eye_transform.origin,
			angles = eye_transform.angles
		})

		while (scope.position_history.len() > history_size)
			scope.position_history.remove(0)

		local delayed = scope.position_history[0]

		local lerp_factor = Chaos_Data.GetOrDefault("lerp_factor", 0.15)
		scope.origin <- LerpVector(scope.origin, delayed.origin, lerp_factor)
		scope.angles <- LerpAngles(scope.angles, delayed.angles, lerp_factor)

		viewcontrol.KeyValueFromVector("origin", scope.origin)
		viewcontrol.KeyValueFromVector("angles", Vector() + scope.angles)
	}

	return -1
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetForceLocalDraw(false)
		RemoveViewControl(player)
	}
}

function SetupPlayer(player)
{
	player.ValidateScriptScope()
	player.SetForceLocalDraw(true)

	local scope = player.GetScriptScope()
	scope.position_history <- []

	local eye_transform = GetPlayerEyeTransform(player)
	local history_size = (Chaos_Data.delay / FrameTime()).tointeger() + 1
	for (local i = 0; i < history_size; i++)
	{
		scope.position_history.push({
			origin = eye_transform.origin,
			angles = eye_transform.angles
		})
	}

	scope.origin <- eye_transform.origin
	scope.angles <- eye_transform.angles

	local viewcontrol = SpawnEntityFromTable("point_viewcontrol", {
		origin = eye_transform.origin,
		angles = eye_transform.angles
	})
	scope.viewcontrol <- viewcontrol

	EntFireByHandle(viewcontrol, "Enable", "!activator", -1, player, viewcontrol)
	EntFireByHandle(player, "RunScriptCode", "ViewControl_PostEnable(self)", -1, player, null)
}

function RemoveViewControl(player)
{
	local scope = player.GetScriptScope()
	if (scope == null)
		return

	if ("position_history" in scope)
		delete scope.position_history
	if ("origin" in scope)
		delete scope.origin
	if ("angles" in scope)
		delete scope.angles

	ViewControl_Remove(player)
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	RemoveViewControl(player)
	EntFireByHandle(player, "RunScriptCode", Chaos_EffectName + ".SetupPlayer(self)", -1, player, null)
}

function OnGameEvent_player_death(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	if (params.death_flags & TF_DEATHFLAG_DEADRINGER)
		return

	RemoveViewControl(player)
}
