// by pokemonpasta

// config
local MIN_PROPS = 1		// int, minimum vphysics ents present for effect to load

// code
local ThinkFuncs = {}

function ChaosEffect_OnStart()
{
	for (local ent = Entities.First(); ent = Entities.Next(ent);)
	{
		if (ent.GetMoveType() != MOVETYPE_VPHYSICS)
			continue

		StartSpinning(ent)
	}

	if (ThinkFuncs.len() < MIN_PROPS)
		return false
}

function ChaosEffect_Update()
{
	for (local ent = Entities.First(); ent = Entities.Next(ent);)
	{
		// Start spinning any VPhysics entities we aren't tracking already
		// this will usually be new entities that weren't there when we started
		if (ent in ThinkFuncs || ent.GetMoveType() != MOVETYPE_VPHYSICS)
			continue

		StartSpinning(ent)
	}
}

function ChaosEffect_OnEnd()
{
	for (local ent = Entities.First(); ent = Entities.Next(ent);)
	{
		if (!(ent in ThinkFuncs))
			continue

		local think_func = ThinkFuncs[ent]
		AddThinkToEnt(ent, think_func ? think_func : null) // if there was no original think function, we set to null to clear it
	}
}

function SpinThink()
{
	local vel = self.GetPhysAngularVelocity()
	vel.z = 1500.0
	self.SetPhysAngularVelocity(vel)
}

function StartSpinning(ent)
{
	ent.ValidateScriptScope()
	ThinkFuncs[ent] <- ent.GetScriptThinkFunc()

	ent.GetScriptScope().SpinThink <- SpinThink
	
	AddThinkToEnt(ent, "SpinThink")
}
