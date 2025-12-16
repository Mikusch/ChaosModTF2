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
	EntFireByHandle(viewcontrol, "SetParent", "!activator", -1, player, viewcontrol)
	EntFireByHandle(viewcontrol, "SetParentAttachment", player.LookupAttachment("eyes") != 0 ? "eyes" : "head", -1, null, null)
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
