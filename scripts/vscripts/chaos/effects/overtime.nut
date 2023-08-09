nextOvertimeNag <- 0.0

function ChaosEffect_OnStart()
{
	nextOvertimeNag = Time()
}

function ChaosEffect_Update()
{
	if (Time() > nextOvertimeNag)
	{
		nextOvertimeNag = Time() + 1.0;

		if (RandomInt(0, 1) > 0)
		{
			SendGlobalGameEvent("overtime_nag", {})
		}
	}
}