const ChaosNamespace = "CHAOS_"
const ChaosLog = "[Chaos VScript] ";

ChaosEffectScopes <- {};

function Chaos_API_StartEffect(name)
{
	local scopeName = ChaosNamespace + name;
	if (scopeName in ChaosEffectScopes)
	{
		printl(format(ChaosLog + "Attempted to start effect '%s' that is already started, restarting...", name));
		Chaos_API_StopEffect(name);
	}

	printl(format(ChaosLog + "Starting effect '%s'", name));

	getroottable()[scopeName] <- {};
	local scope = getroottable()[scopeName];
	
	IncludeScript("chaos/effects/" + name + ".nut", scope);

	if ("Chaos_Start" in scope)
		scope.Chaos_Start();

	ChaosEffectScopes[scopeName] <- scope;

	return true;
}

function Chaos_API_UpdateEffects()
{
	foreach (scopeName, scope in ChaosEffectScopes)
	{
		if ("Chaos_Update" in scope)
			scope.Chaos_Update();
	}

	return true;
}

function Chaos_API_StopEffect(name)
{
	printl(format(ChaosLog + "Stopping effect '%s'", name));
		
	local scopeName = ChaosNamespace + name;
	if (!(scopeName in ChaosEffectScopes))
	{
		printl(format(ChaosLog + "Effect '%s' not found in scope list!", name));
		return false;
	}
		
	local scope = ChaosEffectScopes[scopeName];
	if (scope == null)
	{
		printl(format(ChaosLog + "Effect '%s' scope was deleted early!", name));
		return false;
	}

	if ("Chaos_Stop" in scope)
		scope.Chaos_Stop();

	if ("GameEventCallbacks" in getroottable())
	{
		local gameEvents = getroottable()["GameEventCallbacks"];
		foreach (eventName, scopeList in gameEvents)
		{
			local scopeIndex = scopeList.find(scope);
			if (scopeIndex != null)
				scopeList.remove(scopeIndex);
		}
	}
	
	delete ChaosEffectScopes[scopeName];
		
	return true;
}