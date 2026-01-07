local PARRY_RADIUS = 256.0 // Max distance at which a player can parry a projectile
local PARRY_FOV = 90.0
local SPEED_MULTIPLIER = 1.5 // Speed increase of the projectile after it gets parried
local MAX_PARRIED_PROJECTILES = 64 // Max projectile a player can parry at once
local SND_PARRY = "weapons/saxxy_impact_gen_01.wav" // Sound that plays on a successful parry
local SND_PARRY_RADIUS = 512.0 // Max audiable distance of the parry sound

PrecacheSound(SND_PARRY)

function ChaosEffect_Update()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		if (!player.IsAlive())
			continue

		// When melee smacks, m_iNextMeleeCrit is 0
		if (NetProps.GetPropInt(player, "m_Shared.m_iNextMeleeCrit") == 0)
		{
			// When switching away from melee, m_iNextMeleeCrit will also be 0
			local weapon = player.GetActiveWeapon()
			if (weapon != null && weapon.GetSlot() == TF_WPN_TYPE_MELEE)
			{
				local bone = player.LookupBone("bip_spine_2")
				local search_pos = bone != -1 ? player.GetBoneOrigin(bone) : player.EyePosition()
				local projectile_parried = false
				local projectile_count = 0
				local projectile = null
				while (projectile = Entities.FindByClassnameWithin(projectile, "tf_projectile_*", search_pos, PARRY_RADIUS))
				{
					if (projectile_count >= MAX_PARRIED_PROJECTILES)
						break

					if (!CanParryProjectile(player, projectile))
						continue

					ParryProjectile(player, projectile)
					projectile_parried = true
					projectile_count++
				}

				if (projectile_parried)
				{
					EmitSoundEx({
						sound_name = SND_PARRY
						entity = player
						sound_level = (40 + (20 * log10(SND_PARRY_RADIUS / 36.0))).tointeger()
					})
				}
			}

			// Continue smack detection
			NetProps.SetPropInt(player, "m_Shared.m_iNextMeleeCrit", -2)
		}
	}

	return -1
}

function CanParryProjectile(player, projectile)
{
	// Do not parry projectiles that are on the same team
	if (projectile.GetTeam() == player.GetTeam())
		return false

	// Do not parry stickies that already stick to something
	if (projectile.GetClassname() == "tf_projectile_pipe_remote" && NetProps.GetPropBool(projectile, "m_bTouched"))
		return false

	local eye_pos = player.EyePosition()
	local eye_fwr = player.EyeAngles().Forward()
	local projectile_origin = projectile.GetOrigin()
	local delta_vector = projectile_origin - eye_pos
	delta_vector.Norm()
	local dot_product = eye_fwr.Dot(delta_vector)
	local dot_threshold = cos(PARRY_FOV * PI / 360.0) // Value between -1 and 1
	if (dot_product < dot_threshold) // Projectile not in our specified FOV
		return false

	local trace =
	{
		start = eye_pos,
		end = projectile_origin,
		mask = MASK_SOLID,
		ignore = player
	}

	// Prevent parrying through walls
	if (TraceLineEx(trace) && trace.hit && !startswith(trace.enthit.GetClassname(), "tf_projectile_"))
		return false

	return true
}

function ParryProjectile(player, projectile)
{
	local eye_fwr = player.EyeAngles().Forward()
	local player_team = player.GetTeam()
	// Projectiles that use VPhysics have to be handled differently
	// (pipes, stickies, jarate, mad milk, cleaver, scout balls, gas passer)
	if (projectile.GetMoveType() == MOVETYPE_VPHYSICS)
	{
		local phys_velocity = projectile.GetPhysVelocity()
		local speed = phys_velocity.Norm() * SPEED_MULTIPLIER
		projectile.SetPhysVelocity(eye_fwr * speed)
	}
	else
	{
		local velocity = projectile.GetAbsVelocity()
		local speed = velocity.Norm() * SPEED_MULTIPLIER
		projectile.SetAbsVelocity(eye_fwr * speed)
		projectile.SetForwardVector(eye_fwr)
	}

	NetProps.SetPropEntity(projectile, "m_hOwnerEntity", player)
	NetProps.SetPropEntity(projectile, "m_hThrower", player)
	NetProps.SetPropInt(projectile, "m_iDeflected", 2)
	projectile.SetTeam(player_team)
	// 0 = red model skin
	// 1 = blu model skin
	projectile.SetSkin(player_team - 2)

	// Change trail color of projectiles that have them
	for (local trail = projectile.FirstMoveChild(); trail != null; trail = trail.NextMovePeer())
	{
		if (trail.GetClassname() != "env_spritetrail")
			continue

		local trail_material = trail.GetModelName()
		local color_to_replace = (player_team == TF_TEAM_RED) ? "blu" : "red"
		local replacement = (player_team == TF_TEAM_RED) ? "red" : "blu"
		local index = trail_material.find(color_to_replace)
		if (index == null)
			continue

		trail_material = trail_material.slice(0, index) + replacement + trail_material.slice(index + 3)
		// This is the only base trail material that uses "blue" instead of "blu"
		if (trail_material == "effects/repair_claw_trail_blu.vmt")
			trail_material = "effects/repair_claw_trail_blue.vmt"

		PrecacheModel(trail_material)
		trail.SetModel(trail_material)
	}

	// The Crusader's Crossbow projectile uses a particle effect instead of env_spritetrail
	if (projectile.GetClassname() == "tf_projectile_healing_bolt")
	{
		projectile.AcceptInput("DispatchEffect", "ParticleEffectStop", null, null)
		local particle = SpawnEntityFromTable("info_particle_system",
		{
			origin = projectile.GetOrigin(),
			effect_name = (player_team == TF_TEAM_RED) ? "healshot_trail_red" : "healshot_trail_blue",
			start_active = 1,
		})

		EntFireByHandle(particle, "SetParent", "!activator", 0.0, projectile, null)
	}
}
