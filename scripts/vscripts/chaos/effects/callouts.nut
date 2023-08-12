playerClassNames <-
[
	"Undefined",
	"Scout",
	"Sniper",
	"Soldier",
	"Demoman",
	"Medic",
	"Heavy",
	"Pyro",
	"Spy",
	"Engineer",
	"Civilian",
	"",
	"Random"
]

function Chaos_OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	if (params["class"] != Constants.ETFClass.TF_CLASS_SNIPER)
		return

	for (local i = 1; i <= MaxClients(); i++)
	{
		local other = PlayerInstanceFromIndex(i)
		if (other == null)
			continue

		if (other == player)
			continue
		
		if (other.GetTeam() == player.GetTeam())
			continue
		
		EntFireByHandle(other, "AddContext", "IsMvMDefender:1", 0, null, null)
		EntFireByHandle(other, "AddContext", "randomnum:100", 0, null, null)
		EntFireByHandle(other, "SpeakResponseConcept", "TLK_MVM_SNIPER_CALLOUT", 0, null, null)
		EntFireByHandle(other, "ClearContext", null, 0, null, null)
	}
}

function Chaos_OnGameEvent_player_death(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	for (local i = 1; i <= MaxClients(); i++)
	{
		local other = PlayerInstanceFromIndex(i)
		if (other == null)
			continue

		if (other == player)
			continue
		
		if (other.GetTeam() != player.GetTeam())
			continue

		EntFireByHandle(other, "AddContext", format("victimclass:%s", playerClassNames[player.GetPlayerClass()]), 0, null, null)
		EntFireByHandle(other, "AddContext", "IsMvMDefender:1", 0, null, null)
		EntFireByHandle(other, "AddContext", "randomnum:100", 0, null, null)
		EntFireByHandle(other, "SpeakResponseConcept", "TLK_MVM_DEFENDER_DIED", 0, null, null)
		EntFireByHandle(other, "ClearContext", null, 0, null, null)
	}
}

Chaos_CollectEventCallbacks(this)