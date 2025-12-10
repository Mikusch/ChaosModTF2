local TF_GIFT_MODEL = "models/props_halloween/gargoyle_ghost.mdl"
PrecacheModel(TF_GIFT_MODEL)
PrecacheScriptSound("Halloween.PumpkinPickup")

local MAX_ATTEMPTS = 10

function ChaosEffect_OnStart()
{
	if (NavMesh.GetNavAreaCount() == 0)
		return false

	local areas = {}
	NavMesh.GetAllAreas(areas)

	areas = areas.values()
	areas = areas.filter(function(index, area) { return area.IsValidForWanderingPopulation() })

	if (areas.len() == 0)
		return false

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		local gargoyle = SpawnEntityFromTable("tf_halloween_gift_pickup", {})
		local hullmin = gargoyle.GetBoundingMins()
		local hullmax = gargoyle.GetBoundingMaxs()

		local attempts = 0
		while (attempts < MAX_ATTEMPTS)
		{
			local area = areas[RandomInt(0, areas.len() - 1)]
			local where = area.FindRandomSpot()

			if (IsSpaceToSpawnHere(where, hullmin, hullmax))
			{
				NetProps.SetPropEntity(gargoyle, "m_hTargetPlayer", player)
				gargoyle.SetAbsOrigin(where)
				break
			}

			attempts++
		}

		if (attempts >= MAX_ATTEMPTS)
		{
			gargoyle.Destroy()
		}
	}
}