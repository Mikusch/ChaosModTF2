const CHAOS_NAMESPACE = "CHAOS_"
const CHAOS_LOG_PREFIX = "[TF2 Chaos VScript] "

ChaosEffectScopes <- {}

function Chaos_StartEffect(name, duration)
{
	local scopeName = CHAOS_NAMESPACE + name
	if (scopeName in ChaosEffectScopes)
	{
		printl(format(CHAOS_LOG_PREFIX + "Attempted to start effect '%s' that is already started, restarting...", name))
		Chaos_EndEffect(name)
	}

	printl(format(CHAOS_LOG_PREFIX + "Starting effect '%s'", name))

	getroottable()[scopeName] <- {}
	local scope = getroottable()[scopeName]

	IncludeScript("chaos/effects/" + name + ".nut", scope)

	if ("ChaosEffect_OnStart" in scope)
		scope.ChaosEffect_OnStart()

	if (duration > 0)
		ChaosEffectScopes[scopeName] <- scope

	return true
}

function Chaos_UpdateEffects()
{
	foreach (scopeName, scope in ChaosEffectScopes)
	{
		if ("ChaosEffect_Update" in scope)
			scope.ChaosEffect_Update()
	}

	return true
}

function Chaos_EndEffect(name)
{
	printl(format(CHAOS_LOG_PREFIX + "Stopping effect '%s'", name))

	local scopeName = CHAOS_NAMESPACE + name
	if (!(scopeName in ChaosEffectScopes))
	{
		printl(format(CHAOS_LOG_PREFIX + "Effect '%s' not found in scope list!", name))
		return false
	}

	local scope = ChaosEffectScopes[scopeName]
	if (scope == null)
	{
		printl(format(CHAOS_LOG_PREFIX + "Effect '%s' scope was deleted early!", name))
		return false
	}

	if ("ChaosEffect_OnEnd" in scope)
		scope.ChaosEffect_OnEnd()

	if ("GameEventCallbacks" in getroottable())
	{
		local gameEvents = getroottable()["GameEventCallbacks"]
		foreach (eventName, scopeList in gameEvents)
		{
			local scopeIndex = scopeList.find(scope)
			if (scopeIndex != null)
				scopeList.remove(scopeIndex)
		}
	}

	delete ChaosEffectScopes[scopeName]
	
	return true
}

function Chaos_CollectEvents()
{
    __CollectGameEventCallbacks(this)
}