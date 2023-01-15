#pragma semicolon 1
#pragma newdecls required

public Action ReverseControls_OnPlayerRunCmd(ChaosEffect effect, int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	// Reverse velocity
	vel[0] = -vel[0];
	vel[1] = -vel[1];
	
	// Reverse controls
	if (buttons & IN_MOVELEFT)
	{
		buttons &= ~IN_MOVELEFT;
		buttons |= IN_MOVERIGHT;
	}
	else if (buttons & IN_MOVERIGHT)
	{
		buttons &= ~IN_MOVERIGHT;
		buttons |= IN_MOVELEFT;
	}
	
	if (buttons & IN_FORWARD)
	{
		buttons &= ~IN_FORWARD;
		buttons |= IN_BACK;
	}
	else if (buttons & IN_BACK)
	{
		buttons &= ~IN_BACK;
		buttons |= IN_FORWARD;
	}
	
	return Plugin_Changed;
}
