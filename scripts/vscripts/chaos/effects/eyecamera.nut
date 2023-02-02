IncludeScript("chaos_util.nut")

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

		if (!player.IsAlive())
			continue

		player.SetForceLocalDraw(false)

		player.ValidateScriptScope()

		local viewcontrol = player.GetScriptScope().viewcontrol
		if (viewcontrol == null || !viewcontrol.IsValid())
			continue

		RemoveViewControl(player, viewcontrol)
	}
}

function CreateViewControl(player)
{
	local viewcontrol = SpawnEntityFromTable("point_viewcontrol", {})
	EntFireByHandle(viewcontrol, "SetParent", "!activator", 0, player, viewcontrol)
	EntFireByHandle(viewcontrol, "SetParentAttachment", player.LookupAttachment("eyes") == 0 ? "head" : "eyes", 0, null, null)
	EntFireByHandle(viewcontrol, "Enable", "!activator", 0, player, viewcontrol)
	EntFireByHandle(player, "RunScriptCode", Chaos_EffectName + ".PostViewControlEnable()", 0, player, player)

	return viewcontrol
}

function PostViewControlEnable()
{
	local weapon = activator.GetActiveWeapon()
	if (weapon != null)
		weapon.SetDrawEnabled(true)

	NetProps.SetPropInt(activator, "m_takedamage", 2)
}

function RemoveViewControl(player, viewcontrol)
{
    EntFireByHandle(player, "RunScriptCode", "activator.ValidateScriptScope();activator.GetScriptScope().__lifestate<-NetProps.GetPropInt(activator, `m_lifeState`);", 0, player, player)
    EntFireByHandle(viewcontrol, "Disable", null, 0, player, player)
    EntFireByHandle(player, "RunScriptCode", "NetProps.SetPropInt(activator, `m_lifeState`, activator.GetScriptScope().__lifestate)", 0, player, player)
    EntFireByHandle(viewcontrol, "Kill", null, 0, null, null)
}

function Chaos_OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	player.ValidateScriptScope()

	local viewcontrol = player.GetScriptScope().viewcontrol
	if (viewcontrol != null && viewcontrol.IsValid())
	{
		RemoveViewControl(player, viewcontrol)
	}

	player.GetScriptScope().viewcontrol <- CreateViewControl(player)
}

function Chaos_OnGameEvent_player_death(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	player.ValidateScriptScope()

	local viewcontrol = player.GetScriptScope().viewcontrol
	if (viewcontrol == null || !viewcontrol.IsValid())
		return

	RemoveViewControl(player, viewcontrol)
}

function Chaos_OnGameEvent_player_initial_spawn(params)
{
	local player = PlayerInstanceFromIndex(params.index)
	if (player == null)
		return

	player.SetForceLocalDraw(true)
}

Chaos_CollectEventCallbacks(this)