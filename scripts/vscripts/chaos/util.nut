worldspawn <- Entities.FindByClassname(null, "worldspawn")
gamerules <- Entities.FindByClassname(null, "tf_gamerules")

function GetEnemyTeam(team)
{
	switch (team)
	{
		case TF_TEAM_RED: return TF_TEAM_BLUE
		case TF_TEAM_BLUE: return TF_TEAM_RED
		default: return team
	}
}

function VectorAngles(forward)
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

function ShuffleArray(arr)
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

function DebugDrawCross3D(position, size, r, g, b, no_depth_test, duration)
{
	DebugDrawLine(position + Vector(size, 0, 0), position - Vector(size, 0, 0), r, g, b, no_depth_test, duration)
	DebugDrawLine(position + Vector(0, size, 0), position - Vector(0, size, 0), r, g, b, no_depth_test, duration)
	DebugDrawLine(position + Vector(0, 0, size), position - Vector(0, 0, size), r, g, b, no_depth_test, duration)
}

function IsSpaceToSpawnHere(where, hullmin, hullmax)
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

function IsPlayerStuck(player)
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

function ForcePlayerSuicide(player)
{
	player.TakeDamageCustom(player, player, null, Vector(), Vector(), 99999.0, DMG_CLUB | DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_SUICIDE)
}

function LerpVector(a, b, t)
{
	return Vector(
		a.x + (b.x - a.x) * t,
		a.y + (b.y - a.y) * t,
		a.z + (b.z - a.z) * t
	)
}

function LerpAngle(a, b, t)
{
	local diff = b - a
	while (diff > 180) diff -= 360
	while (diff < -180) diff += 360
	return a + diff * t
}

function LerpAngles(a, b, t)
{
	return Vector(
		LerpAngle(a.x, b.x, t),
		LerpAngle(a.y, b.y, t),
		LerpAngle(a.z, b.z, t)
	)
}

function ViewControl_PostEnable(player)
{
	local weapon = player.GetActiveWeapon()
	if (weapon != null)
		weapon.SetDrawEnabled(true)

	NetProps.SetPropInt(player, "m_takedamage", DAMAGE_YES)
}

function ViewControl_Remove(player)
{
	local scope = player.GetScriptScope()
	if (scope == null || !("viewcontrol" in scope))
		return

	local viewcontrol = scope.viewcontrol
	delete scope.viewcontrol

	if (viewcontrol == null || !viewcontrol.IsValid())
		return

	EntFireByHandle(player, "RunScriptCode", "self.GetScriptScope().lifeState <- NetProps.GetPropInt(self, `m_lifeState`)", -1, null, null)
	EntFireByHandle(player, "RunScriptCode", "NetProps.SetPropInt(self, `m_lifeState`, 0)", -1, null, null)
	EntFireByHandle(viewcontrol, "Disable", null, -1, player, player)
	EntFireByHandle(player, "RunScriptCode", "NetProps.SetPropInt(self, `m_lifeState`, self.GetScriptScope().lifeState)", -1, null, null)
	EntFireByHandle(viewcontrol, "Kill", null, -1, null, null)
}
