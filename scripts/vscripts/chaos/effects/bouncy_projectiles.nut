// Contributed by Dencube

function ChaosEffect_Update()
{
	local projectile
	while (projectile = Entities.FindByClassname(projectile, "tf_projectile_*"))
	{
		local direction = GetProjectileVelocity(projectile)
		local speed = direction.Norm()

		local trace =
		{
			start = projectile.GetOrigin(),
			end = projectile.GetOrigin() + (direction * 12.0),
			mask = MASK_SOLID_BRUSHONLY,
			ignore = projectile
		}

		if (TraceLineEx(trace) && trace.hit)
		{
			local new_direction = direction - (trace.plane_normal * direction.Dot(trace.plane_normal) * 2.0)
			SetProjectileVelocity(projectile, new_direction * speed)
		}
	}

	return CHAOS_UPDATE_EVERY_FRAME
}