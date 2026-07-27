// Contributed by Dencube

local TRACE_PADDING = 12.0

function ChaosEffect_Update()
{
	local frame_time = FrameTime()

	local projectile
	while (projectile = Entities.FindByClassname(projectile, "tf_projectile_*"))
	{
		local direction = GetProjectileVelocity(projectile)
		local speed = direction.Norm()

		if (speed <= 0.0)
			continue

		local classname = projectile.GetClassname()

		// Stickies that already latched onto something are not in flight
		if (classname == "tf_projectile_pipe_remote" && NetProps.GetPropBool(projectile, "m_bTouched"))
			continue

		if (classname == "tf_projectile_grapplinghook")
			continue

		local origin = projectile.GetOrigin()

		local trace =
		{
			start = origin,
			end = origin + (direction * (speed * frame_time + TRACE_PADDING)),
			mask = MASK_SOLID_BRUSHONLY,
			ignore = projectile
		}

		if (!TraceLineEx(trace) || !trace.hit)
			continue

		local dot = direction.Dot(trace.plane_normal)
		if (dot >= 0.0 || ("startsolid" in trace))
			continue

		SetProjectileVelocity(projectile, (direction - (trace.plane_normal * dot * 2.0)) * speed)
	}

	return CHAOS_UPDATE_EVERY_FRAME
}
