IncludeScript("chaos/const")
IncludeScript("chaos/util")

const CHAOS_SCOPE_PREFIX = "CHAOS_"
const CHAOS_LOG_PREFIX = "[TF2 Chaos VScript] "

function Chaos_StartEffect(id, script_file, duration, data_string = "")
{
	local scope_name = CHAOS_SCOPE_PREFIX + id
	if (scope_name in ROOT)
	{
		printf(CHAOS_LOG_PREFIX + "Attempted to start effect '%s' that is already started, restarting...\n", id)
		Chaos_EndEffect(id)
	}

	ROOT[scope_name] <- {}
	local scope = ROOT[scope_name]

	IncludeScript("chaos/effects/" + script_file.tolower(), scope)
	__CollectGameEventCallbacks(scope)

	scope.Chaos_EffectId <- id
	scope.Chaos_EffectName <- CHAOS_SCOPE_PREFIX + id

	if (data_string != "")
	{
		try
		{
			local data_func = compilestring("return " + data_string)
			scope.Chaos_Data <- data_func()
		}
		catch (e)
		{
			printf(CHAOS_LOG_PREFIX + "Failed to parse data for effect '%s': %s\n", id, e)
			scope.Chaos_Data <- {}
		}
	}
	else
	{
		scope.Chaos_Data <- {}
	}

	scope.Chaos_Data.GetOrDefault <- function(key, default_val)
	{
		return key in this ? this[key] : default_val
	}

	local success = true
	if ("ChaosEffect_OnStart" in scope)
		success = scope.ChaosEffect_OnStart()

	if (success == null)
		success = true

	if (success)
	{
		printf(CHAOS_LOG_PREFIX + "Starting effect '%s'\n", id)

		if (duration <= 0)
			delete ROOT[scope_name]
	}
	else
	{
		printf(CHAOS_LOG_PREFIX + "Failed to start effect '%s'\n", id)
		delete ROOT[scope_name]
	}

	return success
}

function Chaos_UpdateEffect(id)
{
	local scope_name = CHAOS_SCOPE_PREFIX + id
	if (!(scope_name in ROOT))
		return

	local scope = ROOT[scope_name]
	if (scope == null)
		return

	if (!("ChaosEffect_Update" in scope))
		return

	return scope.ChaosEffect_Update()
}

function Chaos_EndEffect(id)
{
	printf(CHAOS_LOG_PREFIX + "Stopping effect '%s'\n", id)

	local scope_name = CHAOS_SCOPE_PREFIX + id
	if (!(scope_name in ROOT))
	{
		printf(CHAOS_LOG_PREFIX + "Effect '%s' not found in scope list!\n", id)
		return false
	}

	local scope = ROOT[scope_name]
	if (scope == null)
	{
		printf(CHAOS_LOG_PREFIX + "Effect '%s' scope was deleted early!\n", id)
		return false
	}

	if ("ChaosEffect_OnEnd" in scope)
		scope.ChaosEffect_OnEnd()

	delete ROOT[scope_name]

	return true
}

// Override ClearGameEventCallbacks to wipe events from the root table or from entities only.
// This way, backwards compatibility is preserved with maps using this deprecated function.
// Events that are namespaced and not tied to the entity (e.g. for script plugins) are preserved.
function ClearGameEventCallbacks()
{
	foreach (callbacks in [GameEventCallbacks, ScriptEventCallbacks, ScriptHookCallbacks])
	{
		foreach (event_name, scopes in callbacks)
		{
			for (local i = scopes.len() - 1; i >= 0; i--)
			{
				local scope = scopes[i]
				if (scope == null || scope == ROOT || "__vrefs" in scope)
					scopes.remove(i)
			}
		}
	}
}