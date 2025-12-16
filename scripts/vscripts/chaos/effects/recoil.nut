function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		local weapon = player.GetActiveWeapon()
		if (weapon == null)
			continue
		
		player.ValidateScriptScope()
		player.GetScriptScope().prev_last_fire_time <- NetProps.GetPropFloat(weapon, "LocalActiveTFWeaponData.m_flLastFireTime")
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
		
		local last_fire_time = NetProps.GetPropFloat(weapon, "LocalActiveTFWeaponData.m_flLastFireTime")
		if (last_fire_time > player.GetScriptScope().prev_last_fire_time)
		{
			player.ViewPunch(QAngle(-6, RandomInt(-4, 4), 0))
			player.GetScriptScope().prev_last_fire_time <- last_fire_time
		}

		if (player.GetPlayerClass() == TF_CLASS_PYRO && weapon != null && weapon.GetSlot() == TF_WPN_TYPE_PRIMARY && NetProps.GetPropInt(weapon, "m_iWeaponState") != FT_STATE_IDLE)
		{
			player.ViewPunch(QAngle(-1, RandomInt(-1.5, 1.5), 0))
		}
	}

	return -1
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return
	
	if (params.team == TEAM_UNASSIGNED)
	{
		player.ValidateScriptScope()
		return
	}

	local weapon = player.GetActiveWeapon()
	if (weapon == null)
		return
	
	player.GetScriptScope().prev_last_fire_time <- NetProps.GetPropFloat(weapon, "LocalActiveTFWeaponData.m_flLastFireTime")
}