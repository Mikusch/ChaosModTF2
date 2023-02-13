function ChaosEffect_Update()
{
    local velocity = self.GetAbsVelocity();
    local direction = velocity;
    local speed = direction.Norm();
    
    local trace = 
    {
        start = self.GetOrigin(),

        end = self.GetOrigin() + (direction * 12.0),
        mask = (Constants.FContents.CONTENTS_SOLID|Constants.FContents.CONTENTS_WINDOW|Constants.FContents.CONTENTS_GRATE|Constants.FContents.CONTENTS_MOVEABLE),
        ignore = self
    };
    
    DebugDrawLine(trace.start, trace.end, 0, 255, 0, false, 0.01);
    
    TraceLineEx(trace);
    
    if (trace.hit)
    {
        printl(format("Hit surface %s", trace.surface_name, trace.plane_normal.x, trace.plane_normal.y, trace.plane_normal.z));
        local new_direction = direction - (trace.plane_normal * direction.Dot(trace.plane_normal) * 2.0);
        self.SetAbsVelocity(new_direction * speed);
        self.SetForwardVector(new_direction);
    }
    
    return 0.0;
}

local rocket = null;
while (rocket = Entities.FindByClassname(rocket, "tf_projectile_rocket"))
{
    AddThinkToEnt(rocket, "ChaosEffect_Update");
}
