function ApplyUnlimitedCharge(player)
{
	if (!NetProps.GetPropBool(player, "m_Shared.m_bShieldEquipped"))
		return

	player.AddCustomAttribute("charge time increased", 99999.0, -1)
	NetProps.SetPropFloat(player, "m_Shared.m_flChargeMeter", 100.0)
}

function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		ApplyUnlimitedCharge(player)
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

		if (!NetProps.GetPropBool(player, "m_Shared.m_bShieldEquipped"))
			continue

		NetProps.SetPropFloat(player, "m_Shared.m_flChargeMeter", 100.0)
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.RemoveCustomAttribute("charge time increased")
	}
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	EntFireByHandle(player, "RunScriptCode", Chaos_EffectName + ".ApplyUnlimitedCharge(self)", -1, null, null)
}
