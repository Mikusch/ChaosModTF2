local validProjectiles              =
{
    tf_projectile_arrow       	    = 0
    tf_projectile_energy_ball 		= 0  // Cow mangler
    tf_projectile_healing_bolt	    = 0  // Crusader's Crossbow, Rescue Ranger
    tf_projectile_lightningorb 		= 0  // Spell Variant from Short Circuit
    tf_projectile_mechanicalarmorb	= 0  // Short Circuit
    tf_projectile_rocket 			= 0
    tf_projectile_sentryrocket	    = 0
    tf_projectile_spellfireball 	= 0
    tf_projectile_energy_ring       = 0 // Bison
    tf_projectile_flare             = 0
}

const turn_rate = 0.75

local worldspawn = Entities.FindByClassname(null, "worldspawn");

function ChaosEffect_Update()
{
    local projectile
    while ((projectile = Entities.FindByClassname(projectile, "tf_projectile_*")) != null)
    {
        if (!IsValidProjectile(projectile))
            continue

        if (projectile.GetScriptThinkFunc() == "ProjectileThink")
            continue

        AttachProjectileThinker(projectile)
    }
}

function ChaosEffect_OnEnd()
{
    local homing_projectiles
    while ((homing_projectiles = Entities.FindByClassname(projectile, "tf_projectile_*")) != null)
    {
        AddThinkToEnt(homing_projectiles, null)
    }
}

::ProjectileThink <- function()
{
    local new_target = SelectVictim(self)
    if (new_target != null && IsLookingAt(self, new_target))
        FaceToward(new_target, self, projectile_speed)

    return -1
}

::SelectVictim <- function(projectile)
{
    local target
    local min_distance = 32768.0
    for (local i = 1; i <= MaxClients(); i++)
    {
        local player = PlayerInstanceFromIndex(i)

        if (player == null)
            continue

        local distance = (projectile.GetOrigin() - player.GetOrigin()).Length()

        if (IsValidTarget(player, distance, min_distance, projectile))
        {
            target = player
            min_distance = distance
        }
    }
    return target
}

::IsLookingAt <- function(projectile, new_target)
{
    local target_origin = new_target.GetOrigin()
    local projectile_owner = projectile.GetOwner()
    local projectile_owner_pos = projectile_owner.EyePosition()

    if (!projectile_owner.IsPlayer())
         projectile_owner_pos = projectile_owner.GetCenter()

    if (TraceLine(projectile_owner_pos, target_origin, projectile_owner))
    {
        local direction = (target_origin - projectile_owner.EyePosition())
              direction.Norm()
        local product   = projectile_owner.EyeAngles().Forward().Dot(direction)

        if (product > 0.6)
            return true

    }

    return false
}

function AttachProjectileThinker(projectile)
{
    local projectile_speed = (projectile.GetAbsVelocity()).Norm()

    projectile.ValidateScriptScope()
    projectile.GetScriptScope().projectile_speed <- projectile_speed
    AddThinkToEnt(projectile, "ProjectileThink")
}

::IsValidProjectile <- function(projectile)
{
    if (projectile.GetClassname() in validProjectiles)
        return true
    return false
}

::IsValidTarget <- function(victim, distance, min_distance, projectile)
{
    if (distance > min_distance || victim.GetHealth() == 0 || victim.GetTeam() == projectile.GetTeam() || NetProps.GetPropInt(victim, "m_lifeState") > 0)
        return false
    if (victim.IsPlayer() && (victim.IsInvulnerable() || victim.InCond(Constants.ETFCond.TF_COND_HALLOWEEN_GHOST_MODE) || victim.InCond(Constants.ETFCond.TF_COND_STEALTHED)))
        return false

    return true
}

::FaceToward <- function(new_target, projectile, projectile_speed)
{
    local desired_dir = new_target.EyePosition() - projectile.GetOrigin()
          desired_dir.Norm()

    local current_dir = projectile.GetForwardVector()
    local new_dir = current_dir + (desired_dir - current_dir) * turn_rate
          new_dir.Norm()

    local move_ang = VectorAngles(new_dir)
    local projectile_velocity = move_ang.Forward() * projectile_speed

    projectile.SetAbsVelocity(projectile_velocity)
    projectile.SetLocalAngles(move_ang)
}

// Math Section for Angles
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
    if ( forward.y == 0.0 && forward.x == 0.0 )
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

// Only requiered for Detonator Flares and Bison as those persist even after hitting
function Chaos_OnScriptHook_OnTakeDamage(params)
{
    if (params.const_entity == worldspawn)
    return

    local projectile_class = params.inflictor.GetClassname()
    if (!(projectile_class == "tf_projectile_flare" || projectile_class == "tf_projectile_energy_ring"))
        return

    EntFireByHandle(params.inflictor, "Kill", null, 0.5, null, null)
}

Chaos_CollectEventCallbacks(this)
