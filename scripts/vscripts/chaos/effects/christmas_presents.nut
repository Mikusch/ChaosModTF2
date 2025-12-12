// By Kamuixmod

local GRACE_PERIOD = 25.0
local BLINK_PERIOD = 5.0
local BLINK_DURATION = 0.25
local ROT_SPEED = 2
local REWARD_DURATION_MIN = 7.5
local REWARD_DURATION_MAX = 20.0
local PARTICLE_DURATION = 3

::itemIndex <- PrecacheModel("models/items/gift_festive.mdl")

// Use 'null' for default effect. Specify 'effect' as either red or blue variant, it auto-adjusts to player's team. Set 'effectpos'to target's attachment, or leave null for origin-based positioning.
local giftRewards =
[
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

::ReplaceString <- function(original, search, replace)
{
	local result = ""
	local startIdx = 0
	local foundIdx = original.find(search, startIdx)

	while (foundIdx != null)
	{
		// Append part of the original string before the found substring
		result += original.slice(startIdx, foundIdx)
		// Append the replacement string
		result += replace

		// Update the start index to continue searching
		startIdx = foundIdx + search.len()
		foundIdx = original.find(search, startIdx)
	}

	// Append any remaining part of the original string
	result += original.slice(startIdx)

	return result
}

::DisplayParticleEffect <- function(ent, effect, effect_pos)
{
	if (effect == null)
		return

	// Check if the effect name contains 'red' or 'blue'
	local ent_team = ent.GetTeam()
	if (ent_team == TF_TEAM_RED && effect.find("blue") != null)
		effect = ReplaceString(effect, "blue", "red")
	else if (ent_team == TF_TEAM_BLUE && effect.find("red") != null)
		effect = ReplaceString(effect, "red", "blue")

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
	local reward = giftRewards[reward_index]
	local reward_duration = RandomFloat(REWARD_DURATION_MIN, REWARD_DURATION_MAX)

	ApplyReward(self, reward, reward_duration)
}

::ApplyReward <- function(player, reward, duration)
{
	player.AddCondEx(reward.cond, duration, null)

	// Apply the Vaccinator Über effect for Player Hud
	switch (reward.cond)
	{
		case TF_COND_BULLET_IMMUNE: player.AddCondEx(TF_COND_MEDIGUN_UBER_BULLET_RESIST, duration, null); break;
		case TF_COND_BLAST_IMMUNE:  player.AddCondEx(TF_COND_MEDIGUN_UBER_BLAST_RESIST, duration, null); break;
		case TF_COND_FIRE_IMMUNE:   player.AddCondEx(TF_COND_MEDIGUN_UBER_FIRE_RESIST, duration, null); break;
	}

	ClientPrint(player, HUD_PRINTCENTER, reward.text)
	EmitSoundOnClient(reward.sound, player)
	DisplayParticleEffect(player, reward.effect, reward.effectpos)
}

::PreLandingThink <- function()
{
	if (!self.IsValid()) //goddamn null pointers
		return

	// Clean up in case it gets stuck in GEO
	if (Time() - Pre_Landing_Timer > 10.0)
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

	if (Time() - Blink_Timer >= GRACE_PERIOD)
		AddThinkToEnt(self, "BlinkThink")

	return -1
}

::BlinkThink <- function()
{
	Rotate()

	local cur_time = Time()

	if (cur_time - Blink_Timer >= BLINK_DURATION)
	{
		Blink()
		Blink_Timer = cur_time + BLINK_DURATION
	}

	if (Blink_Time_Left <= 0)
	{
		DispatchParticleEffect("mvm_cash_explosion", self.GetOrigin(), Vector())
		EntFireByHandle(self, "Kill", null, -1, null, null)
	}
	return -1
}

::Blink <- function()
{
	EntFireByHandle(self, "RunScriptCode", "self.KeyValueFromInt(`renderamt`, 25)", -1, null, null)
	EntFireByHandle(self, "RunScriptCode", "self.KeyValueFromInt(`renderamt`, 255)", BLINK_DURATION, null, null)

	Blink_Time_Left -= RandomFloat(0.0, BLINK_DURATION)
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
	pickup_scope.Blink_Time_Left    <- BLINK_PERIOD
	pickup_scope.Blink_Timer        <- cur_time
	pickup_scope.Pre_Landing_Timer  <- cur_time
	AddThinkToEnt(pickup, "PreLandingThink")
}

function OnGameEvent_player_death(params)
{
	local victim = GetPlayerFromUserID(params.userid)
	if (victim == null || params.death_flags & TF_DEATHFLAG_DEADRINGER)
		return

	local attacker = GetPlayerFromUserID(params.attacker)
	if (victim == attacker)
		return

	EntFireByHandle(victim, "CallScriptFunction", "DropGift", -1, victim, null)
}