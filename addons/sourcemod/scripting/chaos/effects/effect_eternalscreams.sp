#pragma semicolon 1
#pragma newdecls required

public Action EternalScreams_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	SetVariantString("HalloweenLongFall");
	AcceptEntityInput(client, "SpeakResponseConcept");
	
	return Plugin_Continue;
}
