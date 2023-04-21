enum BUTTONS
{
    IN_ATTACK = 1,
    IN_JUMP = 2,
    IN_DUCK = 4,
    IN_FORWARD = 8,
    IN_BACK = 16,
    IN_USE = 32,
    IN_CANCEL = 64,
    IN_LEFT = 128,
    IN_RIGHT = 256,
    IN_MOVELEFT = 512,
    IN_MOVERIGHT = 1024,
    IN_ATTACK2 = 2048,
    IN_RUN = 4096,
    IN_RELOAD = 8192,
    IN_ALT1 = 16384,
    IN_ALT2 = 32768,
    IN_SCORE = 65536,
    IN_SPEED = 131072,
    IN_WALK = 262144,
    IN_ZOOM = 524288,
    IN_WEAPON1 = 1048576,
    IN_WEAPON2 = 2097152,
    IN_BULLRUSH = 4194304,
    IN_GRENADE1 = 8388608,
    IN_GRENADE2 = 16777216,
    IN_ATTACK3 = 33554432
};
function ChaosEffect_Update()
{
for (local i = 1; i <= Constants.Server.MAX_PLAYERS; i++)
{
    local player = PlayerInstanceFromIndex(i)
    if (player == null)
        continue;
        doOnKeyPress(player)
    
}
}
AddThinkToEnt(Entities.FindByClassname(null, "worldspawn"), "ChaosEffect_Update")
function doOnKeyPress(player)
     {
                 local btn = NetProps.GetPropInt(player, "m_nButtons")
                 if (btn & BUTTONS.IN_ATTACK)
                     {
                      local angles = player.EyeAngles()
                      angles.x += -4
                      angles.y += RandomInt(-5, 5)

                      player.SnapEyeAngles(angles)
                     }   
     }

function ChaosEffect_OnEnd()
{

}
