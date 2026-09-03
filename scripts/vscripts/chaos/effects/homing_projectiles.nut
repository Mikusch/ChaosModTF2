// Contributed by Kamuixmod

local SPEED_MULTIPLIER = 0.4
local THINK_INTERVAL = 0.05

local TrackedProjectiles = {}
local Targets = []

function ChaosEffect_Update()
{
	CollectTargets()

	for (local projectile; projectile = Entities.FindByClassname(projectile, "tf_projectile_*");)
	{
		if (projectile in TrackedProjectiles)
			continue

		if (!IsProjectileInFlight(projectile))
			continue

		local base_speed = NetProps.GetPropVector(projectile, "m_vInitialVelocity").Length()
		if (base_speed <= 0.0)
			base_speed = GetProjectileVelocity(projectile).Length()

		if (base_speed <= 0.0)
			continue

		TrackedProjectiles[projectile] <- true

		projectile.ValidateScriptScope()
		local projectile_scope = projectile.GetScriptScope()
		projectile_scope.HomingBaseSpeed <- base_speed * SPEED_MULTIPLIER
		projectile_scope.HomingProjectileThink <- ProjectileThink.bindenv(projectile_scope)
		AddThinkToEnt(projectile, "HomingProjectileThink")
	}

	local expired = []
	foreach (projectile, _ in TrackedProjectiles)
	{
		if (projectile == null || !projectile.IsValid())
			expired.push(projectile)
	}

	foreach (projectile in expired)
		delete TrackedProjectiles[projectile]

	return CHAOS_UPDATE_EVERY_FRAME
}

function ChaosEffect_OnEnd()
{
	foreach (projectile, _ in TrackedProjectiles)
	{
		if (projectile != null && projectile.IsValid())
			AddThinkToEnt(projectile, null)
	}
}

function CollectTargets()
{
	Targets.clear()

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		if (player.IsStealthed())
			continue

		if (player.InCond(TF_COND_HALLOWEEN_GHOST_MODE))
			continue

		Targets.push(player)
	}

	// Bosses, buildings and any other combat character
	for (local entity; entity = Entities.Next(entity);)
	{
		if (entity.IsPlayer())
			continue

		if (!(entity instanceof CBaseCombatCharacter))
			continue

		if (!entity.IsAlive() || !entity.IsSolid())
			continue

		if (NetProps.GetPropInt(entity, "m_takedamage") == DAMAGE_NO)
			continue

		Targets.push(entity)
	}
}

function ProjectileThink()
{
	if (!self.IsValid())
		return

	// A sticky can still latch after we started tracking it
	if (!IsProjectileInFlight(self))
		return THINK_INTERVAL

	local origin = self.GetOrigin()
	local team = self.GetTeam()

	local closest_dir
	local closest_target
	local closest_dist = FLT_MAX

	foreach (target in Targets)
	{
		if (!target.IsValid())
			continue

		if (target.GetTeam() == team)
			continue

		if (target.IsPlayer() && target.InCond(TF_COND_DISGUISED) && target.GetDisguiseTeam() == team)
			continue

		local target_center = target.GetCenter()
		local dir = target_center - origin
		local dist = dir.Norm()
		if (dist >= closest_dist)
			continue

		if (TraceLine(origin, target_center, self) < 1.0)
			continue

		closest_dir = dir
		closest_dist = dist
		closest_target = target
	}

	if (closest_target)
	{
		local deflected = NetProps.GetPropInt(self, "m_iDeflected")
		if (deflected < 0)
			deflected = 0

		local speed_new = HomingBaseSpeed + deflected * HomingBaseSpeed * 1.1

		SetProjectileVelocity(self, closest_dir * speed_new)
	}

	return THINK_INTERVAL
}
