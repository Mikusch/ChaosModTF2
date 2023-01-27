function ChaosEffect_OnStart()
{
	local trigger = null
	while (trigger = Entities.FindByClassname(trigger, "trigger_*"))
	{
		EntFireByHandle(trigger, "Toggle", null, 0, null, null)
	}
}