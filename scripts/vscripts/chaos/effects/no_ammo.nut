// Code by ficool2

function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (!player)
			continue
		
		for (local i = 0; i < TF_AMMO_COUNT; i++)
		{
			NetProps.SetPropIntArray(player, "m_iAmmo", 0, i)
		}

		for (local i = 0; i < MAX_WEAPONS; i++)
		{
			local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
			if (!weapon)
				continue
			
			if (weapon.Clip1() > 0)
				weapon.SetClip1(0)
			if (weapon.Clip2() > 0)
				weapon.SetClip2(0)
				
			NetProps.SetPropFloat(weapon, "m_flEnergy", 0.0)
		}
	}
}