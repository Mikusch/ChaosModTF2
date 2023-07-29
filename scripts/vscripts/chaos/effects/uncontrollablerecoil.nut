@@ -0,0 +1,58 @@
TF_WPN_TYPE_PRIMARY <- 0
FT_STATE_IDLE <- 0

function ChaosEffect_OnStart()
{
    for (local i = 1; i <= MaxClients(); i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player == null)
            continue
        
        player.ValidateScriptScope()
        player.GetScriptScope().prevLastFireTime <- 0
    }
}

function ChaosEffect_Update()
{
    for (local i = 1; i <= MaxClients(); i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player == null)
            continue
        
        local weapon = player.GetActiveWeapon()
        local lastFireTime = NetProps.GetPropFloat(weapon, "LocalActiveTFWeaponData.m_flLastFireTime")

        if (lastFireTime > player.GetScriptScope().prevLastFireTime)
        {
            local angles = player.EyeAngles()
            angles.x += -5
            angles.y += RandomInt(-4, 4)
            player.SnapEyeAngles(angles)

            player.GetScriptScope().prevLastFireTime <- lastFireTime
        }

        if (player.GetPlayerClass() == Constants.ETFClass.TF_CLASS_PYRO && weapon != null && weapon.GetSlot() == TF_WPN_TYPE_PRIMARY && NetProps.GetPropInt(weapon, "m_iWeaponState") != FT_STATE_IDLE)
        {
            local angles = player.EyeAngles()
            angles.x += -1
            angles.y += RandomInt(-4, 4)
            player.SnapEyeAngles(angles)
        }
    }
}

function Chaos_OnGameEvent_player_spawn(params)
{
    local player = GetPlayerFromUserID(params.userid)
    if (player == null)
        return
    
    player.ValidateScriptScope()
    player.GetScriptScope().prevLastFireTime <- 0
}

Chaos_CollectEventCallbacks(this)