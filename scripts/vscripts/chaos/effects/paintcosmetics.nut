function ChaosEffect_OnStart()
{
	local wearable = null
	while (wearable = Entities.FindByClassname(wearable, "tf_wearable*"))
	{
		wearable.AddAttribute("set item tint RGB", GetRandomColor(), -1)
		wearable.AddAttribute("set item tint RGB 2", GetRandomColor(), -1)
	}
}

function GetRandomColor()
{
	return RandomInt(0, 0x1000000);
}