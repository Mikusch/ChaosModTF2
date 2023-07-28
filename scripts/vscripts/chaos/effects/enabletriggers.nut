function ChaosEffect_OnStart()
{
	local trigger = null
	while (trigger = Entities.FindByClassname(trigger, "trigger_*"))
	{
		EntFireByHandle(trigger, "Enable", null, 0, null, null)
	}
}