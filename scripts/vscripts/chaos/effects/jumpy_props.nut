// by pokemonpasta

// config
local MIN_PROPS = 1		// int, minimum vphysics ents present for effect to load
local JUMP_COOLDOWN = 1.5	// float, seconds

// code
local ThinkFuncs = {}

function ChaosEffect_OnStart()
{
	for (local ent = Entities.First(); ent = Entities.Next(ent);)
	{
		if (ent.GetMoveType() != MOVETYPE_VPHYSICS)
			continue

		StartBouncing(ent)
	}

	if (ThinkFuncs.len() < MIN_PROPS)
		return false
}

function ChaosEffect_Update()
{
	for (local ent = Entities.First(); ent = Entities.Next(ent);)
	{
		// Start bouncing any VPhysics entities we aren't tracking already
		// this will usually be new entities that weren't there when we started
		if (ent in ThinkFuncs || ent.GetMoveType() != MOVETYPE_VPHYSICS)
			continue

		StartBouncing(ent)
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

	ent.GetScriptScope().JumpCooldown <- JUMP_COOLDOWN
	ent.GetScriptScope().JumpThink <- JumpThink

	// Run this on itself so we can add some delay
	EntFireByHandle(ent, "RunScriptCode", "AddThinkToEnt(self, `JumpThink`)", RandomFloat(0.0, JUMP_COOLDOWN), null, null)
}
