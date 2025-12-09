// by pokemonpasta

// config
MinProps 		<- 1	// int, minimum vphysics props present for effect to load
JumpCooldown 	<- 2.0 	// float, seconds

// code
ThinkFuncs <- {}

function ChaosEffect_OnStart()
{
	for(local ent = Entities.First();ent = Entities.Next(ent);)
	{
		if(ent.GetMoveType() != MOVETYPE_VPHYSICS)
			continue
		
		ent.ValidateScriptScope()
		ThinkFuncs[ent] <- ent.GetScriptThinkFunc()
		
		ent.GetScriptScope().JumpCooldown <- JumpCooldown
		ent.GetScriptScope().JumpThink    <- JumpThink
		EntFireByHandle(ent, "RunScriptCode", "AddThinkToEnt(self, `JumpThink`)", RandomFloat(0.0, 5.0), null, null)
	}
		
	if(ThinkFuncs.len() < MinProps)
		return false
}

function ChaosEffect_OnEnd()
{
	for(local ent = Entities.First();ent = Entities.Next(ent);)
	{
		if(!(ent in ThinkFuncs))
			continue
		
		if(ent.GetMoveType() != MOVETYPE_VPHYSICS)
			continue
		
		AddThinkToEnt(ent, ThinkFuncs[ent])
	}
}

function JumpThink()
{
	local vel = self.GetPhysVelocity()
	vel.z = RandomFloat(250.0, 750.0)
	self.SetPhysVelocity(vel)
	
	return JumpCooldown
}
