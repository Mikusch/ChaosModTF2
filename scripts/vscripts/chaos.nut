IncludeScript("chaos_util")

const CHAOS_SCOPE_PREFIX = "CHAOS_"
const CHAOS_LOG_PREFIX = "[TF2 Chaos VScript] "

::Chaos_GameEventCallbacks <- {}
::Chaos_ScriptHookCallbacks <- {}

::__RunGameEventCallbacks <- function(event, params)
{
	__RunEventCallbacks(event, params, "Chaos_OnGameEvent_", "Chaos_GameEventCallbacks", false)

	if ("GameEventCallbacks" in getroottable())
		__RunEventCallbacks(event, params, "OnGameEvent_", "GameEventCallbacks", true)
}

::__RunScriptHookCallbacks <- function(event, params)
{
	__RunEventCallbacks(event, params, "Chaos_OnScriptHook_", "Chaos_ScriptHookCallbacks", false)

	if ("ScriptHookCallbacks" in getroottable())
		__RunEventCallbacks(event, params, "OnScriptHook_", "ScriptHookCallbacks", true)
}

::Chaos_CollectEventCallbacks <- function(scope)
{
	__CollectEventCallbacks(scope, "Chaos_OnGameEvent_", "Chaos_GameEventCallbacks", ::RegisterScriptGameEventListener)
	__CollectEventCallbacks(scope, "Chaos_OnScriptHook_", "Chaos_ScriptHookCallbacks", ::RegisterScriptHookListener)
}

ChaosEffectScopes <- {}

function Chaos_StartEffect(name, duration)
{
	local scope_name = CHAOS_SCOPE_PREFIX + name
	if (scope_name in ChaosEffectScopes)
	{
		printf(CHAOS_LOG_PREFIX + "Attempted to start effect '%s' that is already started, restarting...\n", name)
		Chaos_EndEffect(name)
	}

	printf(CHAOS_LOG_PREFIX + "Starting effect '%s'\n", name)

	getroottable()[scope_name] <- {}
	local scope = getroottable()[scope_name]

	IncludeScript("chaos/effects/" + name.tolower(), scope)

	scope.Chaos_EffectName <- CHAOS_SCOPE_PREFIX + name

	local success = true
	if ("ChaosEffect_OnStart" in scope)
		success = scope.ChaosEffect_OnStart()
	
	if (success == null)
		success = true

	if (success && duration > 0)
		ChaosEffectScopes[scope_name] <- scope

	return success
}

function Chaos_UpdateEffect(name)
{
	local scope_name = CHAOS_SCOPE_PREFIX + name
	if (!(scope_name in ChaosEffectScopes))
		return

	local scope = ChaosEffectScopes[scope_name]
	if (scope == null)
		return

	if (!("ChaosEffect_Update" in scope))
		return

	return scope.ChaosEffect_Update()
}

function Chaos_EndEffect(name)
{
	printf(CHAOS_LOG_PREFIX + "Stopping effect '%s'\n", name)

	local scope_name = CHAOS_SCOPE_PREFIX + name
	if (!(scope_name in ChaosEffectScopes))
	{
		printf(CHAOS_LOG_PREFIX + "Effect '%s' not found in scope list!\n", name)
		return false
	}

	local scope = ChaosEffectScopes[scope_name]
	if (scope == null)
	{
		printf(CHAOS_LOG_PREFIX + "Effect '%s' scope was deleted early!\n", name)
		return false
	}

	if ("ChaosEffect_OnEnd" in scope)
		scope.ChaosEffect_OnEnd()

	foreach (event, scopes in Chaos_GameEventCallbacks)
	{
		local index = scopes.find(scope)
		if (index != null)
			scopes.remove(index)
	}

	foreach (hook, scopes in Chaos_ScriptHookCallbacks)
	{
		local index = scopes.find(scope)
		if (index != null)
			scopes.remove(index)
	}

	delete ChaosEffectScopes[scope_name]

	return true
}