IncludeScript("chaos_util")

function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		if (!player.IsAlive())
			continue

		player.SetAbsOrigin(Vector(0, 0, 0))
	}
}