const CHAOS_NAMESPACE = "CHAOS_"
const CHAOS_LOG_PREFIX = "[TF2 Chaos VScript] "

::Chaos_GameEventCallbacks <- {}

::__RunGameEventCallbacks <- function(event, params)
{
    __RunEventCallbacks(event, params, "Chaos_OnGameEvent_", "Chaos_GameEventCallbacks", false)

    if ("GameEventCallbacks" in getroottable())
        __RunEventCallbacks(event, params, "OnGameEvent_", "GameEventCallbacks", true)
}

::Chaos_CollectEventCallbacks <- function(scope)
{
    __CollectEventCallbacks(scope, "Chaos_OnGameEvent_", "Chaos_GameEventCallbacks", ::RegisterScriptGameEventListener)
}

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

	IncludeScript("chaos/effects/" + name.tolower() + ".nut", scope)

	scope.Chaos_EffectName <- CHAOS_NAMESPACE + name

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

	if ("Chaos_GameEventCallbacks" in getroottable())
	{
		local gameEvents = getroottable()["Chaos_GameEventCallbacks"]
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
