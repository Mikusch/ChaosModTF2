::worldspawn <- Entities.FindByClassname(null, "worldspawn")
::gamerules <- Entities.FindByClassname(null, "tf_gamerules")

::GetEnemyTeam <- function(team)
{
	if (team == TF_TEAM_RED)
		return TF_TEAM_BLUE

	if (team == TF_TEAM_BLUE)
		return TF_TEAM_RED

	return team
}

::NormalizeAngle <- function(target)
{
	target %= 360.0
	if (target > 180.0)
		target -= 360.0
	else if (target < -180.0)
		target += 360.0
	
	return target
}

::ApproachAngle <- function(target, value, speed)
{
	target = NormalizeAngle(target)
	value = NormalizeAngle(value)

	local delta = NormalizeAngle(target - value)
	if (delta > speed)
		return value + speed
	else if (delta < -speed)
		return value - speed
	
	return value
}

::VectorAngles <- function(forward)
{
	local yaw, pitch
	if (forward.y == 0.0 && forward.x == 0.0)
	{
		yaw = 0.0
		if (forward.z > 0.0)
			pitch = 270.0
		else
			pitch = 90.0
	}
	else
	{
		yaw = (atan2(forward.y, forward.x) * 180.0 / Constants.Math.Pi)
		if (yaw < 0.0)
			yaw += 360.0
		pitch = (atan2(-forward.z, forward.Length2D()) * 180.0 / Constants.Math.Pi)
		if (pitch < 0.0)
			pitch += 360.0
	}

	return QAngle(pitch, yaw, 0.0)
}

::ShuffleArray <- function(arr)
{
	local i = arr.len()
	while (i > 0)
	{
		local j = RandomInt(0, --i)
		local temp = arr[i]
		arr[i] = arr[j]
		arr[j] = temp
	}
}

::DebugDrawCross3D <- function(position, size, r, g, b, no_depth_test, duration)
{
	DebugDrawLine(position + Vector(size, 0, 0), position - Vector(size, 0, 0), r, g, b, no_depth_test, duration)
	DebugDrawLine(position + Vector(0, size, 0), position - Vector(0, size, 0), r, g, b, no_depth_test, duration)
	DebugDrawLine(position + Vector(0, 0, size), position - Vector(0, 0, size), r, g, b, no_depth_test, duration)
}

::IsSpaceToSpawnHere <- function(where, hullmin, hullmax)
{
	local trace =
	{
		start = where,
		end = where,
		hullmin = hullmin,
		hullmax = hullmax,
		mask = MASK_PLAYERSOLID
	}
	TraceHull(trace)

	if (Convars.GetBool("tf_debug_placement_failure") && trace.fraction < 1.0)
	{
		DebugDrawCross3D(where, 5.0, 255, 100, 0, true, 99999.9)
	}

	return trace.fraction >= 1.0
}

::IsPlayerStuck <- function(player)
{
	local trace =
	{
		start = player.GetOrigin(),
		end = player.GetOrigin(),
		hullmin = player.GetBoundingMins(),
		hullmax = player.GetBoundingMaxs(),
		mask = MASK_SOLID_BRUSHONLY,
		ignore = player
	}
		
	return TraceHull(trace) && trace.hit
}

::ForcePlayerSuicide <- function(player)
{
	player.TakeDamageCustom(player, player, null, Vector(), Vector(), 99999.0, DMG_CLUB | DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_SUICIDE)
}