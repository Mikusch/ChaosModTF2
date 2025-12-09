// by pokemonpasta

// config
MinProps 		<- 1	// int, minimum vphysics props present for effect to load
JumpCooldown 	<- 1.5 	// float, seconds

// code
ThinkFuncs <- {}

function ChaosEffect_OnStart()
{
	for(local ent = Entities.First();ent = Entities.Next(ent);)
	{
		if(ent.GetMoveType() != MOVETYPE_VPHYSICS)
			continue
		
		StartBouncing(ent)
	}
		
	if(ThinkFuncs.len() < MinProps)
		return false
}

function ChaosEffect_Update()
{
	for(local ent = Entities.First();ent = Entities.Next(ent);)
	{
		// Start bouncing any VPhysics entities we aren't tracking already
		if(ent in ThinkFuncs || ent.GetMoveType() != MOVETYPE_VPHYSICS)
			continue
		
		StartBouncing(ent)
	}
}

function ChaosEffect_OnEnd()
{
	for(local ent = Entities.First();ent = Entities.Next(ent);)
	{
		if(!(ent in ThinkFuncs))
			continue
		
		local think_func = ThinkFuncs[ent]
		AddThinkToEnt(ent, think_func ? think_func : null)
	}
}

function JumpThink()
{
	local vel = self.GetPhysVelocity()
	vel.z = RandomFloat(400.0, 600.0)
	self.SetPhysVelocity(vel)
	
	return JumpCooldown
}

function StartBouncing(ent)
{
	ent.ValidateScriptScope()
	ThinkFuncs[ent] <- ent.GetScriptThinkFunc()
	
	ent.GetScriptScope().JumpCooldown <- JumpCooldown
	ent.GetScriptScope().JumpThink    <- JumpThink
	
	// Run this on itself so we can add some delay
	EntFireByHandle(ent, "RunScriptCode", "AddThinkToEnt(self, `JumpThink`)", RandomFloat(0.0, 5.0), null, null)
}