const TF_WPN_TYPE_PRIMARY = 0
const FT_STATE_IDLE = 0

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
		player.GetScriptScope().prevLastFireTime <- NetProps.GetPropFloat(weapon, "LocalActiveTFWeaponData.m_flLastFireTime")
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
		
		local lastFireTime = NetProps.GetPropFloat(weapon, "LocalActiveTFWeaponData.m_flLastFireTime")
		if (lastFireTime > player.GetScriptScope().prevLastFireTime)
		{
			player.ViewPunch(QAngle(-6, RandomInt(-4, 4), 0))
			player.GetScriptScope().prevLastFireTime <- lastFireTime
		}

		if (player.GetPlayerClass() == Constants.ETFClass.TF_CLASS_PYRO && weapon != null && weapon.GetSlot() == TF_WPN_TYPE_PRIMARY && NetProps.GetPropInt(weapon, "m_iWeaponState") != FT_STATE_IDLE)
		{
			player.ViewPunch(QAngle(-1, RandomInt(-1.5, 1.5), 0))
		}
	}

	return -1
}

function Chaos_OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return
	
	local weapon = player.GetActiveWeapon()
	if (weapon == null)
		return
		
	player.ValidateScriptScope()
	player.GetScriptScope().prevLastFireTime <- NetProps.GetPropFloat(weapon, "LocalActiveTFWeaponData.m_flLastFireTime")
}

Chaos_CollectEventCallbacks(this)