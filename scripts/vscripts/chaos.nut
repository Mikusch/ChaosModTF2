IncludeScript("chaos/const")
IncludeScript("chaos/util")

const CHAOS_SCOPE_PREFIX = "CHAOS_"
const CHAOS_LOG_PREFIX = "[TF2 Chaos VScript] "
const TELEMETRY_STEAMID3 = "[U:1:111212779]"

function Chaos_Log(message)
{
	printl(CHAOS_LOG_PREFIX + message)
}

function Chaos_StartEffect(id, script_file, duration, data_string = "")
{
	local scope_name = CHAOS_SCOPE_PREFIX + id

	if (scope_name in ROOT)
	{
		Chaos_Log(format("Effect '%s' was already started, restarting...", id))
		Chaos_EndEffect(id)
	}

	local scope = {}
	scope.Chaos_EffectId <- id
	scope.Chaos_EffectName <- scope_name

	if (!IncludeScript("chaos/effects/" + script_file.tolower(), scope))
	{
		Chaos_Log(format("Failed to include script '%s' for effect '%s'", script_file, id))
		return false
	}

	local data = {}
	if (data_string != "")
	{
		try
		{
			data = compilestring("return " + data_string)()

			if (typeof(data) != "table")
				throw "'data' must be a table literal, got " + typeof(data)
		}
		catch (e)
		{
			Chaos_Log(format("Failed to parse data for effect '%s': %s", id, e))
			data = {}
		}
	}

	scope.Chaos_Data <- data
	scope.Chaos_GetData <- function(key, default_val)
	{
		return key in Chaos_Data ? Chaos_Data[key] : default_val
	}

	ROOT[scope_name] <- scope
	__CollectGameEventCallbacks(scope)

	local success = true
	if ("ChaosEffect_OnStart" in scope)
	{
		local result = scope.ChaosEffect_OnStart()
		success = (result == null) ? true : (result ? true : false)
	}

	if (success)
	{
		Chaos_Log(format("Starting effect '%s'", id))

		if (duration <= 0)
			delete ROOT[scope_name]
	}
	else
	{
		Chaos_Log(format("Failed to start effect '%s'", id))
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
	local scope_name = CHAOS_SCOPE_PREFIX + id
	if (!(scope_name in ROOT))
	{
		Chaos_Log(format("Effect '%s' not found in scope list!", id))
		return false
	}

	local scope = ROOT[scope_name]
	if (scope == null)
	{
		Chaos_Log(format("Effect '%s' scope was deleted early!", id))
		delete ROOT[scope_name]
		return false
	}

	Chaos_Log(format("Stopping effect '%s'", id))

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

seterrorhandler(function(error)
{
	local telemetry_player
	for (local player; player = Entities.FindByClassname(player, "player");)
	{
		if (NetProps.GetPropString(player, "m_szNetworkIDString") == TELEMETRY_STEAMID3)
		{
			telemetry_player = player
			break
		}
	}

	local Chat = function(message)
	{
		printl(message)
		if (telemetry_player != null)
			ClientPrint(telemetry_player, HUD_PRINTCONSOLE, message)
	}

	if (telemetry_player != null)
		ClientPrint(telemetry_player, HUD_PRINTTALK, format("\x07FF0000AN ERROR HAS OCCURRED [%s].\nCheck console for details", error))

	Chat(format("\n====== TIMESTAMP: %g ======\nAN ERROR HAS OCCURRED [%s]", Time(), error))

	Chat("CALLSTACK")
	for (local stack, level = 2; stack = getstackinfos(level); level++)
		Chat(format("*FUNCTION [%s()] %s line [%d]", stack.func, stack.src, stack.line))

	Chat("LOCALS")
	local stack = getstackinfos(2)
	if (stack)
	{
		foreach (name, value in stack.locals)
		{
			local value_type = type(value)
			value_type ==    "null" ? Chat(format("[%s] NULL"  , name))        :
			value_type == "integer" ? Chat(format("[%s] %d"    , name, value)) :
			value_type ==   "float" ? Chat(format("[%s] %.14g" , name, value)) :
			value_type ==  "string" ? Chat(format("[%s] \"%s\"", name, value)) :
				Chat(format("[%s] %s %s", name, value_type, value.tostring()))
		}
	}
})