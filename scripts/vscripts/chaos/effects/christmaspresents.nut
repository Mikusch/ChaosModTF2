// By Kamuixmod

const GRACE_PERIOD = 25.0
const BLINK_PERIOD = 5.0
const BLINK_DURATION = 0.25
const ROT_SPEED = 2
const REWARD_DURATION_MIN = 5.0
const REWARD_DURATION_MAX = 12.5
const PARTICLE_DURATION = 1.5


::originOffset <- Vector(0,0,12)
::itemIndex <- PrecacheModel("models/items/gift_festive.mdl")


// Use 'null' for default effect. Specify 'effect' as either red or blue variant, it auto-adjusts to player's team. Set 'effectpos'to target's attachment, or leave null for origin-based positioning.
local giftRewards = [
    {cond = TF_COND_OFFENSEBUFF,                 text = "Buff Banner Effect",        sound = "Weapon_BuffBanner.HornRed",               effect = null,                            effectpos = null},
    {cond = TF_COND_DEFENSEBUFF,                 text = "Battalion's Backup Effect", sound = "Weapon_BattalionsBackup.HornRed",         effect = null,                            effectpos = null},
    {cond = TF_COND_REGENONDAMAGEBUFF,           text = "Concheror Effect",          sound = "Samurai.Conch",                           effect = null,                            effectpos = null},
    {cond = TF_COND_SPEED_BOOST,                 text = "Speed Boost",               sound = "DisciplineDevice.PowerUp",                effect = "doublejump_puff",               effectpos = "head"},
    {cond = TF_COND_CRITBOOSTED_USER_BUFF,       text = "Crit Boost",                sound = "Powerup.PickUpTemp.Crit",                 effect = "mvm_levelup3",                  effectpos = "head"},
    {cond = TF_COND_INVULNERABLE_USER_BUFF,      text = "ÜberCharge",                sound = "Powerup.PickUpTemp.Uber",                 effect = "spell_overheal_red",            effectpos = "flag"},
    {cond = TF_COND_BULLET_IMMUNE,               text = "Bullet Damage Immunity",    sound = "WeaponMedigun_Vaccinator.InvulnerableOn", effect = "medic_resist_bullet",           effectpos = null},
    {cond = TF_COND_BLAST_IMMUNE,                text = "Blast Damage Immunity",     sound = "WeaponMedigun_Vaccinator.InvulnerableOn", effect = "medic_resist_blast",            effectpos = null},
    {cond = TF_COND_FIRE_IMMUNE,                 text = "Fire Damage Immunity",      sound = "WeaponMedigun_Vaccinator.InvulnerableOn", effect = "medic_resist_fire",             effectpos = null},
    {cond = TF_COND_HALLOWEEN_SPEED_BOOST,       text = "Action Speed Boost",        sound = "Powerup.PickUpAgility",                   effect = "hwn_cart_cap_neutral",          effectpos = null},
    {cond = TF_COND_HALLOWEEN_QUICK_HEAL,        text = "Quick-Fix Boost",           sound = "Mannpower.InvulnerableOn",                effect = "medic_megaheal_red",            effectpos = null},
    {cond = TF_COND_STEALTHED_USER_BUFF_FADING,  text = "Stealth Mode",              sound = "Halloween.spell_stealth",                 effect = "mvm_loot_smoke",                effectpos = "flag"},
    {cond = TF_COND_MEDIGUN_SMALL_BULLET_RESIST, text = "Bullet Resistance",         sound = "Powerup.PickUpResistance",                effect = "medic_resist_bullet",           effectpos = null},
    {cond = TF_COND_MEDIGUN_SMALL_BLAST_RESIST,  text = "Blast Resistance",          sound = "Powerup.PickUpResistance",                effect = "medic_resist_blast",            effectpos = null},
    {cond = TF_COND_MEDIGUN_SMALL_FIRE_RESIST,   text = "Fire Resistance",           sound = "Powerup.PickUpResistance",                effect = "medic_resist_fire",             effectpos = null},
    {cond = TF_COND_RADIUSHEAL_ON_DAMAGE,        text = "Radius Heal",               sound = "Halloween.spell_overheal",                effect = "powerup_supernova_explode_red", effectpos = null}
 ]

function ChaosEffect_OnStart()
{
	foreach (reward in giftRewards)
        PrecacheScriptSound(reward.sound)
}

::DisplayParticleEffect <- function(ent, effect, effect_pos)
{
    if (effect == null)
        return

    if (endswith(effect, "_"))
    {
        local teamColor = (ent.GetTeam() == TF_TEAM_RED) ? "red" : "blue"
        effect += teamColor
    }

    CreateParticleEffect(ent, effect, effect_pos)
}

::CreateParticleEffect <- function(ent, effect, effect_pos)
{
    local particle = SpawnEntityFromTable("info_particle_system",
    {
        effect_name = effect,
        start_active = true,
        origin = ent.GetOrigin(),
        angles = ent.GetAbsAngles()
    })

    EntFireByHandle(particle, "SetParent", "!activator", -1, ent, null)

    if (effect_pos != null)
        EntFireByHandle(particle, "SetParentAttachment", effect_pos, -1, ent, null)

    EntFireByHandle(particle, "Kill", null, PARTICLE_DURATION, null, null)
}

::PickGiftReward <- function()
{
    local reward_index = RandomInt(0, giftRewards.len() - 1)
    local selectedReward = giftRewards[reward_index]
    local reward_duration = RandomFloat(REWARD_DURATION_MIN, REWARD_DURATION_MAX)

    self.AddCondEx(selectedReward.cond, reward_duration, null)

    // Apply the Vaccinator Über effect for Player Hud
    switch (selectedReward.cond) {
        case TF_COND_BULLET_IMMUNE:
            self.AddCondEx(TF_COND_MEDIGUN_UBER_BULLET_RESIST, 5.0, null)
            break
        case TF_COND_BLAST_IMMUNE:
            self.AddCondEx(TF_COND_MEDIGUN_UBER_BLAST_RESIST, 5.0, null)
            break
        case TF_COND_FIRE_IMMUNE:
            self.AddCondEx(TF_COND_MEDIGUN_UBER_FIRE_RESIST, 5.0, null)
            break
    }

    ClientPrint(self, HUD_PRINTCENTER, selectedReward.text)
    EmitSoundOnClient(selectedReward.sound, self)

    DisplayParticleEffect(self, selectedReward.effect, selectedReward.effectpos)
}

::PreLandingThink <- function()
{
    if (!self.IsValid()) //goddamn null pointers
        return

    // Clean up in case it gets stuck in GEO
    if (Time() - pre_landing_timer > 10.0)
        EntFireByHandle(self, "Kill", null, -1, null, null)


    local startpos = self.GetOrigin()

    local trace_down =
    {
        start = startpos,
        end = startpos + Vector(0, 0, -30.0),
        mask = MASK_SOLID_BRUSHONLY,
        ignore = self
    }

    if (TraceLineEx(trace_down))
    {
        if (trace_down.hit)
        {
            EntFireByHandle(self, "RunScriptCode", "self.SetMoveType(0, MOVECOLLIDE_FLY_BOUNCE)", -1, null, null)
            AddThinkToEnt(self, "MainThink")
        }
    }
    return -1
}

::MainThink <- function()
{
    Rotate()

    if (Time() - blink_timer >= GRACE_PERIOD)
        AddThinkToEnt(self, "BlinkThink")

    return -1
}

::BlinkThink <- function()
{
    Rotate()

    local cur_time = Time()

    if (cur_time - blink_timer >= BLINK_DURATION)
    {
        Blink()
        blink_timer = cur_time + BLINK_DURATION
    }

    if (blink_time_left <= 0)
    {
        local angles = self.GetAbsAngles()
        DispatchParticleEffect("mvm_cash_explosion", self.GetOrigin(), Vector(angles.x, angles.y, angles.z))
        EntFireByHandle(self, "Kill", null, -1, null, null)
    }
    return -1
}

::Blink <- function()
{
    EntFireByHandle(self, "RunScriptCode", "self.KeyValueFromInt(`renderamt`, 25)", -1, null, null)
    EntFireByHandle(self, "RunScriptCode", "self.KeyValueFromInt(`renderamt`, 255)", BLINK_DURATION, null, null)

    blink_time_left -= RandomFloat(0.0, BLINK_DURATION)
}

::Rotate <- function()
{
    if (self.IsValid()) // catch em null pointers
    {
        local angles = self.GetAbsAngles()
        angles.y += ROT_SPEED
        if (angles.y >= 360) {
            angles.y -= 360
        }
        self.SetAbsAngles(angles)
    }
}


::DropGift <- function()
{
    local cur_time = Time()

    local velocity = Vector(RandomFloat(-0.5, 0.5), RandomFloat(-0.5, 0.5), RandomFloat(-0.5, 0.5))
    velocity.z = 2.0
    velocity.Norm()
    velocity *= 500.0

    local pickup = SpawnEntityFromTable("tf_halloween_pickup", { origin = self.GetCenter(), rendermode = 1 , spawnflags = (1 << 30) }) // No Respawn
    pickup.SetMoveType(MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE)
    pickup.SetAbsVelocity(velocity)
    pickup.SetSolid(SOLID_BBOX)
    pickup.SetSize(Vector(-12, -12, -12), Vector(12, 12, 12)) // to fix fucked up bounding box of model
    pickup.KeyValueFromString("pickup_sound", null)
    pickup.KeyValueFromString("pickup_particle", null)

    EntityOutputs.AddOutput(pickup, "OnPlayerTouch", "!activator", "CallScriptfunction", "PickGiftReward", -1, -1)

    for (local i = 0; i < 4; i++)
        NetProps.SetPropIntArray(pickup, "m_nModelIndexOverrides", itemIndex, i)

    // Activate when at rest
    pickup.RemoveSolidFlags(FSOLID_TRIGGER)
    EntFireByHandle(pickup, "RunScriptCode", "self.AddSolidFlags(FSOLID_TRIGGER)", 0.1, null, null)

    pickup.ValidateScriptScope()
    local pickup_scope = pickup.GetScriptScope()
    pickup_scope.blink_time_left    <- BLINK_PERIOD
    pickup_scope.blink_timer        <- cur_time
    pickup_scope.pre_landing_timer  <- cur_time
    AddThinkToEnt(pickup, "PreLandingThink")
}

function Chaos_OnGameEvent_player_death(params)
{
    local victim = GetPlayerFromUserID(params.userid)
    if (victim == null)
        return

    if (params.death_flags & TF_DEATHFLAG_DEADRINGER)
		return

    local attacker = GetPlayerFromUserID(params.attacker)
    if (victim == attacker)
        return

    EntFireByHandle(victim, "CallScriptFunction", "DropGift", -1, victim, null)
}

Chaos_CollectEventCallbacks(this)
