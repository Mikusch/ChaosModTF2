::MaxPlayers <- MaxClients().tointeger();
function ChaosEffect_Update()
{
for (local i = 1; i <= MaxPlayers ; i++)
{
    local player = PlayerInstanceFromIndex(i)
    if (player == null)
        continue;
        doOnKey(player) 
}
}
function OnGameEvent_player_spawn(params)
{
    local player = GetPlayerFromUserID(params.userid)
    if (player != null)
    {
        player.ValidateScriptScope();
        player.GetScriptScope().pastfire <- 0.0;
    }
}
AddThinkToEnt(Entities.FindByClassname(null, "worldspawn"), "ChaosEffect_Update")
function doOnKey(player)
     {
                 local fire = player.GetScriptScope().pastfire;
                 local weapons = player.GetActiveWeapon();
                 local firetime = NetProps.GetPropFloat(weapons, "LocalActiveTFWeaponData.m_flLastFireTime");
                 local flames = NetProps.GetPropInt(weapons, "m_iWeaponState")
                 if (firetime > fire)
                     {
                      local angles = player.EyeAngles()
                      angles.x += -5
                      angles.y += RandomInt(-4, 4)
                      player.SnapEyeAngles(angles)
    
                      player.GetScriptScope().pastfire <- NetProps.GetPropFloat(weapons, "LocalActiveTFWeaponData.m_flLastFireTime")
                     }
                  if(player.GetPlayerClass() == 7 && flames != 0)
                  {
                     if (weapons.GetSlot() == 0)
                     {
                      local angles = player.EyeAngles()
                      angles.x += -5
                      angles.y += RandomInt(-4, 4)
                      player.SnapEyeAngles(angles)
                     }
                  }
     }
function ChaosEffect_OnEnd()
{
    AddThinkToEnt((Entities.FindByClassname(null, "worldspawn")), null)
}
