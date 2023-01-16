#pragma semicolon 1
#pragma newdecls required

public bool NoChaos_OnStart(ChaosEffect effect)
{
	for (int i = 0; i < g_effects.Length; i++)
	{
		// End all active effects now
		ChaosEffect other;
		if (g_effects.GetArray(i, other) && other.active)
		{
			// Don't force-end ourselves
			if (effect.id == other.id)
				continue;
			
			Function callback = other.GetCallbackFunction("OnEnd");
			if (callback != INVALID_FUNCTION)
			{
				Call_StartFunction(null, callback);
				Call_PushArray(other, sizeof(other));
				Call_Finish();
			}
			
			other.active = false;
			other.timer = null;
			g_effects.SetArray(i, other);
		}
	}
	
	// Request to pause timer
	g_bNoChaos = true;
	
	return true;
}

public void NoChaos_OnEnd(ChaosEffect effect)
{
	// Resume chaos
	g_bNoChaos = false;
	g_flLastEffectActivateTime = GetGameTime();
	g_flLastMetaEffectActivateTime = GetGameTime();
}
