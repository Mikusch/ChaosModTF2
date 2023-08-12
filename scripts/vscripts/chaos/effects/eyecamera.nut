IncludeScript("chaos_util")

function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.SetForceLocalDraw(true)

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
	local viewcontrol = SpawnEntityFromTable("point_viewcontrol", 
	{
		origin = player.EyePosition(),
		angles = player.EyeAngles()
	})
	
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

function RemoveViewControl(player)
{
	player.ValidateScriptScope()
	if ("viewcontrol" in player.GetScriptScope())
	{
		local viewcontrol = player.GetScriptScope().viewcontrol
		if (viewcontrol != null && viewcontrol.IsValid())
		{
			EntFireByHandle(player, "RunScriptCode", "activator.ValidateScriptScope();activator.GetScriptScope().__lifestate<-NetProps.GetPropInt(activator, `m_lifeState`);NetProps.SetPropInt(activator, `m_lifeState`, 0)", 0, player, player)
			EntFireByHandle(viewcontrol, "Disable", null, 0, player, player)
			EntFireByHandle(player, "RunScriptCode", "NetProps.SetPropInt(activator, `m_lifeState`, activator.GetScriptScope().__lifestate)", 0, player, player)
			EntFireByHandle(viewcontrol, "Kill", null, 0, null, null)
		}
	}
}

function Chaos_OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	RemoveViewControl(player)

	player.ValidateScriptScope()
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

function Chaos_OnGameEvent_player_initial_spawn(params)
{
	local player = PlayerInstanceFromIndex(params.index)
	if (player == null)
		return

	player.SetForceLocalDraw(true)
}

Chaos_CollectEventCallbacks(this)