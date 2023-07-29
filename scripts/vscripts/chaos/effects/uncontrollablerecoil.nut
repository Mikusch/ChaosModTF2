::MaxPlayers <- MaxClients().tointeger();

function ChaosEffect_OnStart()
{
    for (local i = 1; i <= MaxPlayers ; i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player == null)
            continue
        
        player.ValidateScriptScope()
        player.GetScriptScope().pastfire <- 0
    }
}

function ChaosEffect_Update()
{
    for (local i = 1; i <= MaxPlayers ; i++)
    {
        local player = PlayerInstanceFromIndex(i)
        if (player == null)
            continue
        
        local fire = player.GetScriptScope().pastfire
        local weapon = player.GetActiveWeapon()
        local lastFireTime = NetProps.GetPropFloat(weapon, "LocalActiveTFWeaponData.m_flLastFireTime")

        if (lastFireTime > fire)
        {
            local angles = player.EyeAngles()
            angles.x += -5
            angles.y += RandomInt(-4, 4)
            player.SnapEyeAngles(angles)

            player.GetScriptScope().pastfire <- lastFireTime
        }

        if (player.GetPlayerClass() == Constants.ETFClass.TF_CLASS_PYRO && weapon != null && weapon.GetSlot() == 0 && NetProps.GetPropInt(weapon, "m_iWeaponState") != 0)
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
    player.GetScriptScope().pastfire <- 0
}

Chaos_CollectEventCallbacks(this)