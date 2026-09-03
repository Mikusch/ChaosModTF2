function ChaosEffect_OnStart()
{
	Fade(null, FFADE_OUT | FFADE_STAYOUT)
}

function ChaosEffect_OnEnd()
{
	Fade(null, FFADE_IN | FFADE_PURGE)
}

function Fade(player, flags)
{
	local color = Chaos_GetData("color", [0, 0, 0, 255])

	ScreenFade(player, color[0], color[1], color[2], color[3], 0.0, 0.0, flags)
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	Fade(player, FFADE_OUT | FFADE_STAYOUT)
}