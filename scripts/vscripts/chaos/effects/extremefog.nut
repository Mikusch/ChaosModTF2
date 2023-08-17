SF_FOG_MASTER <- 0x0001

local customFogController = null

function ChaosEffect_OnStart()
{
	customFogController = SpawnEntityFromTable("env_fog_controller",
	{
		fogenable		= 1
		fogstart		= 5
		fogend			= 200
		fogmaxdensity	= 1
		foglerptime		= 1.5
		fogcolor		= Vector(200, 200, 200)
		fogblend		= 0
		farz			= 8400
	})

	SetFogForAllPlayers(customFogController)
}

function ChaosEffect_Update()
{
	SetFogForAllPlayers(customFogController)
}

function ChaosEffect_OnEnd()
{
	if (customFogController != null && customFogController.IsValid())
		customFogController.Destroy()
	
	local controller = FindFogController(true)
	if (controller != null)
		SetFogForAllPlayers(controller)
	else
		SetFogForAllPlayers(FindFogController())
}

function FindFogController(master = false)
{
	local controller = null
	while (controller = Entities.FindByClassname(controller, "env_fog_controller"))
	{
		if (controller == customFogController)
			continue

		if (!master && NetProps.GetPropInt(controller, "m_spawnflags") & SF_FOG_MASTER)
			continue
		
		return controller
	}

	return null
}

function SetFogForAllPlayers(controller)
{
	if (controller == null || !controller.IsValid())
		return

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (controller == NetProps.GetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl"))
			continue

		NetProps.SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", controller)
	}
}

Chaos_CollectEventCallbacks(this)