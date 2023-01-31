function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue
		
		if (player.GetPlayerClass() == Constants.ETFClass.TF_CLASS_UNDEFINED)
			continue
		
		local newClass = null
		do
		{
			newClass = RandomInt(Constants.ETFClass.TF_CLASS_SCOUT, Constants.ETFClass.TF_CLASS_ENGINEER)
		}
		while (player.GetPlayerClass() == newClass)
		
		player.SetPlayerClass(newClass)
		player.Regenerate(true)
	}
}