function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		NetProps.SetPropFloat(player, "m_Local.m_flStepSize", 0)
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		NetProps.SetPropFloat(player, "m_Local.m_flStepSize", Convars.GetInt("sv_stepsize"))
	}
}

function Chaos_OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	 NetProps.SetPropFloat(player, "m_Local.m_flStepSize", 0)
}

Chaos_CollectEventCallbacks(this)