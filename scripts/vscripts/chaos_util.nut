::ROOT <- getroottable();
if (!("ConstantNamingConvention" in ROOT))
{
	foreach (a, b in Constants)
		foreach (k, v in b)
			if (v == null)
				ROOT[k] <- 0
			else
				ROOT[k] <- v
}

// m_lifeState values
const LIFE_ALIVE = 0
const LIFE_DYING = 1
const LIFE_DEAD = 2
const LIFE_RESPAWNABLE = 3
const LIFE_DISCARDBODY = 4

// settings for m_takedamage
const DAMAGE_NO = 0
const DAMAGE_EVENTS_ONLY = 1
const DAMAGE_YES = 2
const DAMAGE_AIM = 3

const TF_DEATHFLAG_DEADRINGER = 32
const FLT_MAX = 0x7F7FFFFF

::worldspawn <- Entities.FindByClassname(null, "worldspawn")
::gamerules <- Entities.FindByClassname(null, "tf_gamerules")

CTFPlayer.IsAlive <- function()
{
	return NetProps.GetPropInt(this, "m_lifeState") == LIFE_ALIVE
}

CTFBot.IsAlive <- function()
{
	return NetProps.GetPropInt(this, "m_lifeState") == LIFE_ALIVE
}

::GetEnemyTeam <- function(team)
{
	if (team == Constants.ETFTeam.TF_TEAM_RED)
		return Constants.ETFTeam.TF_TEAM_BLUE

	if (team == Constants.ETFTeam.TF_TEAM_BLUE)
		return Constants.ETFTeam.TF_TEAM_RED

	// no enemy team
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