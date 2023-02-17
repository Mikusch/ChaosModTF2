function ChaosEffect_Update()
{
    local rocket = null
    while (rocket = Entities.FindByClassname(rocket, "tf_projectile_rocket"))
    {
        local velocity = rocket.GetAbsVelocity()
        local direction = velocity
        local speed = direction.Norm()

        local trace =
        {
            start = rocket.GetOrigin(),
            end = rocket.GetOrigin() + (direction * 12.0),
            mask = (Constants.FContents.CONTENTS_SOLID | Constants.FContents.CONTENTS_WINDOW | Constants.FContents.CONTENTS_GRATE | Constants.FContents.CONTENTS_MOVEABLE),
            ignore = rocket
        }

        TraceLineEx(trace)

        if (trace.hit)
        {
            local new_direction = direction - (trace.plane_normal * direction.Dot(trace.plane_normal) * 2.0)
            rocket.SetAbsVelocity(new_direction * speed)
            rocket.SetForwardVector(new_direction)
        }
    }
}