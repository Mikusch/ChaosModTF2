function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		player.SetForceLocalDraw(true)
		player.ValidateScriptScope()
		player.GetScriptScope().viewcontrol <- CreateViewControl(player)
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
		RemoveViewControl(player)
	}
}

function CreateViewControl(player)
{
	local viewcontrol = SpawnEntityFromTable("point_viewcontrol", { origin = player.EyePosition(), angles = player.EyeAngles() })
	EntFireByHandle(viewcontrol, "SetParent", "!activator", -1, player, viewcontrol)
	EntFireByHandle(viewcontrol, "SetParentAttachment", player.LookupAttachment("eyes") == 0 ? "head" : "eyes", -1, null, null)
	EntFireByHandle(viewcontrol, "Enable", "!activator", -1, player, viewcontrol)
	EntFireByHandle(player, "RunScriptCode", Chaos_EffectName + ".PostViewControlEnable()", -1, player, null)
	return viewcontrol
}

function PostViewControlEnable()
{
	local weapon = activator.GetActiveWeapon()
	if (weapon != null)
		weapon.SetDrawEnabled(true)

	NetProps.SetPropInt(activator, "m_takedamage", DAMAGE_YES)
}

function RemoveViewControl(player)
{
	if (!("viewcontrol" in player.GetScriptScope()))
		return

	local viewcontrol = player.GetScriptScope().viewcontrol
	if (viewcontrol == null || !viewcontrol.IsValid())
		return

	EntFireByHandle(player, "RunScriptCode", "self.GetScriptScope().lifeState <- NetProps.GetPropInt(self, `m_lifeState`)", -1, null, null)
	EntFireByHandle(player, "RunScriptCode", "NetProps.SetPropInt(self, `m_lifeState`, 0)", -1, null, null)
	EntFireByHandle(viewcontrol, "Disable", null, -1, player, player)
	EntFireByHandle(player, "RunScriptCode", "NetProps.SetPropInt(self, `m_lifeState`, self.GetScriptScope().lifeState)", -1, null, null)
	EntFireByHandle(viewcontrol, "Kill", null, -1, null, null)
}

function Chaos_OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	if (params.team == TEAM_UNASSIGNED)
	{
		player.ValidateScriptScope()
		return
	}

	player.SetForceLocalDraw(true)
	RemoveViewControl(player)
	player.GetScriptScope().viewcontrol <- CreateViewControl(player)
}

function Chaos_OnGameEvent_player_death(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	if (params.death_flags & TF_DEATHFLAG_DEADRINGER)
		return

	RemoveViewControl(player)
}

Chaos_CollectEventCallbacks(this)