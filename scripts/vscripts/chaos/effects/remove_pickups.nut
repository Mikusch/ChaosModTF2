function ChaosEffect_OnStart()
{
	local removed = false

	foreach (classname in ["item_healthkit_*", "item_ammopack_*"])
	{
		for (local pickup; pickup = Entities.FindByClassname(pickup, classname);)
		{
			EntFireByHandle(pickup, "Kill", null, -1, null, null)
			removed = true
		}
	}

	return removed
}