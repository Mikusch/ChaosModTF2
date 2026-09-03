local PARRY_RADIUS = 256.0 // Max distance at which a player can parry a projectile
local PARRY_FOV = 90.0
local SPEED_MULTIPLIER = 1.5 // Speed increase of the projectile after it gets parried
local MAX_PARRIED_PROJECTILES = 64 // Max projectile a player can parry at once
local SND_PARRY = "weapons/saxxy_impact_gen_01.wav" // Sound that plays on a successful parry
local SND_PARRY_RADIUS = 512.0 // Max audiable distance of the parry sound
local PARRY_DOT_THRESHOLD = cos(PARRY_FOV * PI / 360.0) // Half the FOV, as a dot product between -1 and 1
local SND_PARRY_LEVEL = (40 + (20 * log10(SND_PARRY_RADIUS / 36.0))).tointeger()

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
		if (NetProps.GetPropInt(player, "m_Shared.m_iNextMeleeCrit") != 0)
			continue

		// Continue smack detection
		NetProps.SetPropInt(player, "m_Shared.m_iNextMeleeCrit", -2)

		// When switching away from melee, m_iNextMeleeCrit will also be 0
		local weapon = player.GetActiveWeapon()
		if (weapon == null || weapon.GetSlot() != TF_WPN_TYPE_MELEE)
			continue

		ParrySwing(player)
	}

	return CHAOS_UPDATE_EVERY_FRAME
}

function ParrySwing(player)
{
	local bone = player.LookupBone("bip_spine_2")
	local search_pos = bone != -1 ? player.GetBoneOrigin(bone) : player.EyePosition()

	local swing =
	{
		owner = player,
		team = player.GetTeam(),
		eye_pos = player.EyePosition(),
		eye_fwd = player.EyeAngles().Forward(),
		launcher = player.GetActiveWeapon()
	}

	local parried = 0
	for (local projectile; projectile = Entities.FindByClassnameWithin(projectile, "tf_projectile_*", search_pos, PARRY_RADIUS);)
	{
		if (parried >= MAX_PARRIED_PROJECTILES)
			break

		if (!CanParryProjectile(player, projectile, swing))
			continue

		ParryProjectile(projectile, swing)
		parried++
	}

	if (parried == 0)
		return

	EmitSoundEx({
		sound_name = SND_PARRY
		entity = player
		sound_level = SND_PARRY_LEVEL
	})
}

function CanParryProjectile(player, projectile, swing)
{
	// Do not parry projectiles that are on the same team
	if (projectile.GetTeam() == swing.team)
		return false

	if (!IsProjectileInFlight(projectile))
		return false

	local projectile_origin = projectile.GetOrigin()
	local delta_vector = projectile_origin - swing.eye_pos
	delta_vector.Norm()

	if (swing.eye_fwd.Dot(delta_vector) < PARRY_DOT_THRESHOLD) // Projectile not in our specified FOV
		return false

	local trace =
	{
		start = swing.eye_pos,
		end = projectile_origin,
		mask = MASK_SOLID,
		ignore = player
	}

	// Prevent parrying through walls.
	if (TraceLineEx(trace) && trace.hit)
	{
		if (!("enthit" in trace) || !startswith(trace.enthit.GetClassname(), "tf_projectile_"))
			return false
	}

	return true
}

function ParryProjectile(projectile, swing)
{
	local speed = GetProjectileVelocity(projectile).Norm() * SPEED_MULTIPLIER
	SetProjectileVelocity(projectile, swing.eye_fwd * speed)

	NetProps.SetPropEntity(projectile, "m_hOwnerEntity", swing.owner)
	NetProps.SetPropEntity(projectile, "m_hThrower", swing.owner)
	NetProps.SetPropEntity(projectile, "m_hLauncher", swing.launcher)
	NetProps.SetPropInt(projectile, "m_iDeflected", NetProps.GetPropInt(projectile, "m_iDeflected") + 1)

	projectile.SetTeam(swing.team)
	// 0 = red model skin
	// 1 = blu model skin
	projectile.SetSkin(swing.team - 2)

	RecolorProjectileTrail(projectile, swing.team)
}

function RecolorProjectileTrail(projectile, team)
{
	for (local trail = projectile.FirstMoveChild(); trail != null; trail = trail.NextMovePeer())
	{
		if (trail.GetClassname() != "env_spritetrail")
			continue

		local trail_material = trail.GetModelName()

		// This is the only base trail material that uses "blue" instead of "blu"
		if (trail_material == "effects/repair_claw_trail_red.vmt" || trail_material == "effects/repair_claw_trail_blue.vmt")
		{
			trail_material = (team == TF_TEAM_RED) ? "effects/repair_claw_trail_red.vmt" : "effects/repair_claw_trail_blue.vmt"
		}
		else
		{
			local color_to_replace = (team == TF_TEAM_RED) ? "blu" : "red"
			local replacement = (team == TF_TEAM_RED) ? "red" : "blu"
			local index = trail_material.find(color_to_replace)
			if (index == null)
				continue

			trail_material = trail_material.slice(0, index) + replacement + trail_material.slice(index + 3)
		}

		PrecacheModel(trail_material)
		trail.SetModel(trail_material)
	}

	// The Crusader's Crossbow projectile uses a particle effect instead of env_spritetrail
	if (projectile.GetClassname() != "tf_projectile_healing_bolt")
		return

	projectile.AcceptInput("DispatchEffect", "ParticleEffectStop", null, null)

	local particle = SpawnEntityFromTable("info_particle_system",
	{
		origin = projectile.GetOrigin(),
		effect_name = (team == TF_TEAM_RED) ? "healshot_trail_red" : "healshot_trail_blue",
		start_active = 1,
	})

	EntFireByHandle(particle, "SetParent", "!activator", 0.0, projectile, null)
}
