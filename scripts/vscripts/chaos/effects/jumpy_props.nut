// by pokemonpasta

// config
local MIN_PROPS = 1		// int, minimum vphysics ents present for effect to load
local JUMP_COOLDOWN = 1.5	// float, seconds
local JUMP_SPEED_MIN = 400.0	// float, units per second
local JUMP_SPEED_MAX = 600.0	// float, units per second

// code
local ThinkFuncs = {}

function ChaosEffect_OnStart()
{
	for (local ent; ent = Entities.Next(ent);)
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
	for (local ent; ent = Entities.Next(ent);)
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
	for (local ent; ent = Entities.Next(ent);)
	{
		if (!(ent in ThinkFuncs))
			continue

		local think_func = ThinkFuncs[ent]
		AddThinkToEnt(ent, think_func != "" ? think_func : null) // if there was no original think function, we set to null to clear it
	}
}

function JumpThink()
{
	local scope = self.GetScriptScope()

	local remaining = scope.JumpNextTime - Time()
	if (remaining > 0.0)
		return remaining

	local vel = self.GetPhysVelocity()
	vel.z = RandomFloat(JUMP_SPEED_MIN, JUMP_SPEED_MAX)
	self.SetPhysVelocity(vel)

	scope.JumpNextTime = Time() + scope.JumpCooldown

	return scope.JumpCooldown
}

function StartBouncing(ent)
{
	ent.ValidateScriptScope()
	ThinkFuncs[ent] <- ent.GetScriptThinkFunc()

	local scope = ent.GetScriptScope()
	scope.JumpCooldown <- JUMP_COOLDOWN
	// Stagger the first jump in the think, a delayed EntFire could outlive the effect
	scope.JumpNextTime <- Time() + RandomFloat(0.0, JUMP_COOLDOWN)
	scope.JumpThink <- JumpThink

	AddThinkToEnt(ent, "JumpThink")
}
