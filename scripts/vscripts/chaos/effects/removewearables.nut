function ChaosEffect_OnStart()
{
	local wearable = null
	while (wearable = Entities.FindByClassname(wearable, "tf_wearable*"))
	{
		wearable.Destroy()
	}
}