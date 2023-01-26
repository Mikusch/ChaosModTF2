const LIFE_ALIVE = 0

function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		if (NetProps.GetPropInt(player, "m_lifeState") == LIFE_ALIVE)
			continue
		
		player.ForceRespawn()
	}
}