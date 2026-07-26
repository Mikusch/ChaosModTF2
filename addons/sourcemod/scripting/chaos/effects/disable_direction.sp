#pragma semicolon 1
#pragma newdecls required

public void DisableDirection_GetClaims(ChaosEffect effect, ArrayList claims)
{
	claims.PushString("player:movement");
}

public bool DisableDirection_OnStart(ChaosEffect effect)
{
	effect.state.SetValue("direction", GetRandomInt(view_as<int>(DIR_FWD), view_as<int>(DIR_RIGHT)));

	return true;
}

public Action DisableDirection_OnPlayerRunCmd(ChaosEffect effect, int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!IsPlayerAlive(client))
		return Plugin_Continue;

	int nValue;
	if (!effect.state.GetValue("direction", nValue))
		return Plugin_Continue;

	Dir_t nDirection = view_as<Dir_t>(nValue);

	if ((nDirection == DIR_FWD && vel[0] > 0.0) || (nDirection == DIR_BACK && vel[0] < 0.0))
		vel[0] = 0.0;
	else if ((nDirection == DIR_RIGHT && vel[1] > 0.0) || (nDirection == DIR_LEFT && vel[1] < 0.0))
		vel[1] = 0.0;
	else if ((nDirection == DIR_UP && vel[2] > 0.0) || (nDirection == DIR_DOWN && vel[2] < 0.0))
		vel[2] = 0.0;
	else
		return Plugin_Continue;

	return Plugin_Changed;
}
