function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (player.GetPlayerClass() == TF_CLASS_UNDEFINED)
			continue

		local new_class = null
		do
		{
			new_class = RandomInt(TF_CLASS_SCOUT, TF_CLASS_ENGINEER)
		}
		while (player.GetPlayerClass() == new_class)

		player.SetPlayerClass(new_class)
		player.Regenerate(true)
	}
}