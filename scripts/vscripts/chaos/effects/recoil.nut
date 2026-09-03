function InitPlayer(player)
{
	player.ValidateScriptScope()

	local weapon = player.GetActiveWeapon()
	player.GetScriptScope().prev_last_fire_time <- weapon != null ? NetProps.GetPropFloat(weapon, "LocalActiveTFWeaponData.m_flLastFireTime") : 0.0
}

function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		InitPlayer(player)
	}
}

function ChaosEffect_Update()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		local weapon = player.GetActiveWeapon()
		if (weapon == null)
			continue

		local scope = player.GetScriptScope()
		if (scope == null || !("prev_last_fire_time" in scope))
			continue

		local last_fire_time = NetProps.GetPropFloat(weapon, "LocalActiveTFWeaponData.m_flLastFireTime")
		if (last_fire_time > scope.prev_last_fire_time)
		{
			player.ViewPunch(QAngle(-6, RandomInt(-4, 4), 0))
			scope.prev_last_fire_time = last_fire_time
		}

		if (player.GetPlayerClass() == TF_CLASS_PYRO && weapon.GetSlot() == TF_WPN_TYPE_PRIMARY && NetProps.GetPropInt(weapon, "m_iWeaponState") != FT_STATE_IDLE)
		{
			player.ViewPunch(QAngle(-1, RandomInt(-1.5, 1.5), 0))
		}
	}

	return CHAOS_UPDATE_EVERY_FRAME
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	InitPlayer(player)
}
