// Contributed by Kamuixmod

local SPEED_MULTIPLIER = 0.4
local THINK_INTERVAL = 0.05

local TrackedProjectiles = {}

function ChaosEffect_Update()
{
	for (local projectile; projectile = Entities.FindByClassname(projectile, "tf_projectile_*");)
	{
		if (projectile in TrackedProjectiles)
			continue

		TrackedProjectiles[projectile] <- true

		projectile.ValidateScriptScope()
		local projectile_scope = projectile.GetScriptScope()
		projectile_scope.HomingProjectileThink <- ProjectileThink.bindenv(projectile_scope)
		AddThinkToEnt(projectile, "HomingProjectileThink")
	}

	foreach (projectile, _ in TrackedProjectiles)
	{
		if (projectile == null || !projectile.IsValid())
			delete TrackedProjectiles[projectile]
	}

	return -1
}

function ChaosEffect_OnEnd()
{
	foreach (projectile, _ in TrackedProjectiles)
	{
		if (projectile != null && projectile.IsValid())
			AddThinkToEnt(projectile, null)
	}
}

function ProjectileThink()
{
	if (!self.IsValid())
		return

	local origin = self.GetOrigin()
	local team = self.GetTeam()

	local closest_dir
	local closest_target
	local closest_dist = FLT_MAX

	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (player.GetTeam() == team)
			continue

		if (!player.IsAlive())
			continue

		if (player.IsStealthed())
			continue

		if (player.InCond(TF_COND_DISGUISED) && player.GetDisguiseTeam() == team)
			continue
		
		if (player.InCond(TF_COND_HALLOWEEN_GHOST_MODE))
			continue

		local player_center = player.GetCenter()
		local dir = player_center - origin
		local dist = dir.Norm()
		if (dist >= closest_dist)
			continue

		if (TraceLine(origin, player_center, self) < 1.0)
			continue

		closest_dir = dir
		closest_dist = dist
		closest_target = player
	}

	if (closest_target)
	{
		local initial_velocity = NetProps.GetPropVector(self, "m_vInitialVelocity")
		local speed_base = initial_velocity.Length() * SPEED_MULTIPLIER

		local deflected = NetProps.GetPropInt(self, "m_iDeflected")
		local speed_new = speed_base + deflected * speed_base * 1.1

		local new_velocity = closest_dir * speed_new

		if (self.GetMoveType() == MOVETYPE_VPHYSICS)
		{
			self.SetPhysVelocity(new_velocity)
		}
		else
		{
			local new_angles = VectorAngles(closest_dir)

			self.Teleport(false, new_velocity, true, new_angles, true, new_velocity)
		}
	}

	return THINK_INTERVAL
}
