#pragma semicolon 1
#pragma newdecls required

enum Direction
{
	Direction_Forward,
	Direction_Back,
	Direction_Right,
	Direction_Left,
}

static Direction g_nDirection;

public bool DisableRandomDirection_OnStart(ChaosEffect effect)
{
	g_nDirection = view_as<Direction>(GetRandomInt(view_as<int>(Direction_Forward), view_as<int>(Direction_Right)));
	
	return true;
}

public Action DisableRandomDirection_OnPlayerRunCmd(ChaosEffect effect, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (g_nDirection == Direction_Forward && vel[0] > 0.0 || g_nDirection == Direction_Back && vel[0] < 0.0)
	{
		vel[0] = 0.0;
	}
	else if (g_nDirection == Direction_Right && vel[1] > 0.0 || g_nDirection == Direction_Left && vel[1] < 0.0)
	{
		vel[1] = 0.0;
	}
	
	return Plugin_Changed;
}
