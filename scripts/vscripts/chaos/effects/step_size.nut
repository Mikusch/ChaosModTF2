function ChaosEffect_OnStart()
{
	SetStepSizeOnAll(Chaos_GetData("stepsize", 18.0))
}

function ChaosEffect_OnEnd()
{
	SetStepSizeOnAll(Convars.GetFloat("sv_stepsize"))
}

function SetStepSizeOnAll(stepsize)
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		NetProps.SetPropFloat(player, "m_flStepSize", stepsize)
	}
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	NetProps.SetPropFloat(player, "m_flStepSize", Chaos_GetData("stepsize", 18.0))
}