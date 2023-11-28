const TF_GIFT_MODEL = "models/props_halloween/gargoyle_ghost.mdl"
PrecacheModel(TF_GIFT_MODEL)
PrecacheScriptSound("Halloween.PumpkinPickup")

function ChaosEffect_OnStart()
{
	if (NavMesh.GetNavAreaCount() == 0)
		return false

	local areas = {}
	NavMesh.GetAllAreas(areas)

	areas = areas.values()
	areas = areas.filter(function(index, area)
	{
		return area.IsValidForWanderingPopulation() && area.IsReachableByTeam(TF_TEAM_RED) && area.IsReachableByTeam(TF_TEAM_BLUE)
	})

	local prop = SpawnEntityFromTable("prop_dynamic", { model = TF_GIFT_MODEL })
	local hullmin = prop.GetBoundingMins()
	local hullmax = prop.GetBoundingMaxs()
	prop.Destroy()

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		local spawned = false
		while (!spawned)
		{
			local area = areas[RandomInt(0, areas.len() - 1)]
			local where = area.FindRandomSpot()

			if (IsSpaceToSpawnHere(where, hullmin, hullmax))
			{
				local gargoyle = Entities.CreateByClassname("tf_halloween_gift_pickup")
				NetProps.SetPropEntity(gargoyle, "m_hTargetPlayer", player)
				gargoyle.KeyValueFromVector("origin", where)
				gargoyle.DispatchSpawn()

				spawned = true
			}
		}
	}
}