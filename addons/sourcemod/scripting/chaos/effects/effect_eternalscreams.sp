#pragma semicolon 1
#pragma newdecls required

public void EternalScreams_OnGameFrame(ChaosEffect effect)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		SetVariantString("HalloweenLongFall");
		AcceptEntityInput(client, "SpeakResponseConcept");
	}
}
