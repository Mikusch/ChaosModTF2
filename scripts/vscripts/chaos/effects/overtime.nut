function ChaosEffect_Update()
{
	if (RandomInt(0, 1) > 0)
	{
		SendGlobalGameEvent("overtime_nag", {})
	}

	return 1.0
}
