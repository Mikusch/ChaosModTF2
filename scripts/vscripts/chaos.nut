IncludeScript("chaos/const")
IncludeScript("chaos/util")

const CHAOS_SCOPE_PREFIX = "CHAOS_"
const CHAOS_LOG_PREFIX = "[TF2 Chaos VScript] "

function Chaos_StartEffect(name, duration)
{
	local scope_name = CHAOS_SCOPE_PREFIX + name
	if (scope_name in ROOT)
	{
		printf(CHAOS_LOG_PREFIX + "Attempted to start effect '%s' that is already started, restarting...\n", name)
		Chaos_EndEffect(name)
	}

	ROOT[scope_name] <- {}
	local scope = ROOT[scope_name]

	IncludeScript("chaos/effects/" + name.tolower(), scope)
	__CollectGameEventCallbacks(scope)

	scope.Chaos_EffectName <- CHAOS_SCOPE_PREFIX + name

	local success = true
	if ("ChaosEffect_OnStart" in scope)
		success = scope.ChaosEffect_OnStart()
	
	if (success == null)
		success = true

	if (success)
	{
		printf(CHAOS_LOG_PREFIX + "Starting effect '%s'\n", name)

		if (duration > 0)
			ROOT[scope_name] <- scope
	}
	else
	{
		printf(CHAOS_LOG_PREFIX + "Failed to start effect '%s'\n", name)
	}

	return success
}

function Chaos_UpdateEffect(name)
{
	local scope_name = CHAOS_SCOPE_PREFIX + name
	if (!(scope_name in ROOT))
		return

	local scope = ROOT[scope_name]
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
	if (!(scope_name in ROOT))
	{
		printf(CHAOS_LOG_PREFIX + "Effect '%s' not found in scope list!\n", name)
		return false
	}

	local scope = ROOT[scope_name]
	if (scope == null)
	{
		printf(CHAOS_LOG_PREFIX + "Effect '%s' scope was deleted early!\n", name)
		return false
	}

	if ("ChaosEffect_OnEnd" in scope)
		scope.ChaosEffect_OnEnd()

	delete ROOT[scope_name]

	return true
}