// Contributed by Dencube

function ChaosEffect_Update()
{
	local projectile
	while (projectile = Entities.FindByClassname(projectile, "tf_projectile_*"))
	{
		local velocity = projectile.GetAbsVelocity()
		local direction = velocity
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
			projectile.SetAbsVelocity(new_direction * speed)
			projectile.SetForwardVector(new_direction)
		}
	}

	return -1
}