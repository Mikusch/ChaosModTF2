
// config
MinProps <- 1     // int, minimum props for effect to load
JumpCooldown <- 2 // int, seconds
VPhysicsClassnames <- [
	"func_physbox"
	"passtime_ball"
	"prop_physics"
	"prop_physics_multiplayer"
	"prop_physics_override"
	"prop_sphere"
	"simple_physics_prop"
	"simple_physics_brush"
]

// code
JumpingEntities <- {}

function ChaosEffect_OnStart()
{
	foreach(classname in VPhysicsClassnames)
	{
		for(local ent; ent = Entities.FindByClassname(ent, classname);)
		{
			AddEntity(ent)
		}
	}
		
	if(JumpingEntities.len() < MinProps)
		return false
}

function ChaosEffect_OnUpdate()
{
	local timemod = Time().tointeger()
	timemod %= JumpCooldown
	foreach(classname in VPhysicsClassnames)
	{
		for(local ent; ent = Entities.FindByClassname(ent, classname);)
		{
			if(ent in JumpingEntities)
			{
				local info = JumpingEntities[ent]
				if(timemod == info.modulus)
				{
					if(!info.in_jump)
						JumpEntity(ent)
				}
				else
					info.in_jump = false // We only really care about in_jump in the same second that the entity jumps, so we can reset it in the next second
			}
			else
				AddEntity(ent)
		}
	}
}

function JumpEntity(entity)
{
	local vel = entity.GetPhysVelocity()
	vel.z = RandomFloat(250.0, 750.0)
	entity.SetPhysVelocity(vel)
	
	JumpingEntities[entity].in_jump = true
}

function AddEntity(entity)
{
	JumpingEntities[entity] <- {
		modulus = RandomInt(0, JumpCooldown - 1)
		in_jump = false
	}
}
