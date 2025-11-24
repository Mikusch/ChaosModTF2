const SKULL_MODEL = "models/props_mvm/mvm_human_skull_collide.mdl"
const SKULL_SOUND = "ambient/halloween/underground_wind_lp_02.wav"
const SKULL_KILL_SOUND = "Halloween.skeleton_laugh_giant"
const SKULL_SPEED = 70.0

PrecacheModel(SKULL_MODEL)
PrecacheSound(SKULL_SOUND)
PrecacheScriptSound(SKULL_KILL_SOUND)

function ChaosEffect_OnStart()
{
	local world_mins = NetProps.GetPropVector(worldspawn, "m_WorldMins")
	local world_maxs = NetProps.GetPropVector(worldspawn, "m_WorldMaxs")

	local spawn_origin = Vector(
		RandomFloat(world_mins.x, world_maxs.x),
		RandomFloat(world_mins.y, world_maxs.y),
		RandomFloat(world_mins.z, world_maxs.z)
	)

	local skull = SpawnEntityFromTable("base_boss",
	{
		origin = spawn_origin
		model = SKULL_MODEL
		health = FLT_MAX
	})

	if (skull == null)
		return false

	skull.SetSolid(SOLID_NONE)
	EntFireByHandle(skull, "Disable", null, -1, null, null)

	EmitSoundEx(
	{
		sound_name = SKULL_SOUND
		sound_level = 70
		entity = skull
		filter_type = RECIPIENT_FILTER_GLOBAL
	})

	skull.ValidateScriptScope()
	skull.GetScriptScope().SkullThink <- function()
	{
		local skull_origin = self.GetOrigin()
		local world_mins = NetProps.GetPropVector(worldspawn, "m_WorldMins")
		local world_maxs = NetProps.GetPropVector(worldspawn, "m_WorldMaxs")
		local closest_dist = FLT_MAX
		local closest_player = null

		for (local i = 1; i <= MaxClients(); i++)
		{
			local player = PlayerInstanceFromIndex(i)
			if (player == null || !player.IsAlive())
				continue

			local trace =
			{
				start = skull_origin
				end = player.EyePosition()
				hullmin = self.GetBoundingMins()
				hullmax = self.GetBoundingMaxs()
				mask = MASK_SOLID
				ignore = self
			}
			TraceHull(trace)

			if (trace.hit && trace.enthit == player)
			{
				local player_class = NetProps.GetPropInt(player, "m_PlayerClass.m_iClass")
				NetProps.SetPropInt(player, "m_PlayerClass.m_iClass", TF_CLASS_UNDEFINED)
				player.TakeDamage(10000.0, DMG_PREVENT_PHYSICS_FORCE, self)
				NetProps.SetPropInt(player, "m_PlayerClass.m_iClass", player_class)

				if (!player.IsAlive())
				{
					EmitSoundEx(
					{
						sound_name = SKULL_KILL_SOUND
						entity = player
						filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
					})

					local ragdoll = NetProps.GetPropEntity(player, "m_hRagdoll")
					if (ragdoll != null)
						ragdoll.Destroy()
				}
				continue
			}

			local dist = (player.EyePosition() - skull_origin).Length()
			if (dist < closest_dist)
			{
				closest_dist = dist
				closest_player = player
			}
		}

		if (closest_player != null)
		{
			local skull_angles = self.GetAbsAngles()
			local dir = closest_player.EyePosition() - skull_origin
			dir.Norm()

			local target_angles = VectorAngles(dir)
			local new_pitch = ApproachAngle(target_angles.x, skull_angles.x, 5.0)
			local new_yaw = ApproachAngle(target_angles.y, skull_angles.y, 5.0)
			local new_angles = QAngle(new_pitch, new_yaw, 0.0)

			local new_dir = new_angles.Forward()
			local outside_world = skull_origin.x < world_mins.x || skull_origin.x > world_maxs.x ||
			skull_origin.y < world_mins.y || skull_origin.y > world_maxs.y ||
			skull_origin.z < world_mins.z || skull_origin.z > world_maxs.z

			local speed = outside_world ? SKULL_SPEED * 10.0 : SKULL_SPEED
			local new_origin = skull_origin + new_dir * speed * FrameTime()

			self.SetAbsOrigin(new_origin)
			self.SetAbsAngles(new_angles)
		}

		return -1
	}

	AddThinkToEnt(skull, "SkullThink")

	return true
}
