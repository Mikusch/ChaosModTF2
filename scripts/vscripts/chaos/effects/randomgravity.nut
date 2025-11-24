
function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		// SetGravity(0.0) doesn't do anything, so we use a really small min value instead for effectively no gravity.
		player.SetGravity(RandomFloat(0.000001, 2.0))
	}
}

function ChaosEffect_OnEnd()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		player.SetGravity(1.0)
	}
}