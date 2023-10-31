function ChaosEffect_Update()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		player.AddHudHideFlags(Constants.FHideHUD.HIDEHUD_HEALTH | Constants.FHideHUD.HIDEHUD_MISCSTATUS | Constants.FHideHUD.HIDEHUD_CROSSHAIR)
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		player.RemoveHudHideFlags(Constants.FHideHUD.HIDEHUD_HEALTH | Constants.FHideHUD.HIDEHUD_MISCSTATUS | Constants.FHideHUD.HIDEHUD_CROSSHAIR)
	}
}