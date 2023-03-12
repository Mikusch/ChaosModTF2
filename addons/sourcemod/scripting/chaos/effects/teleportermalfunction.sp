#pragma semicolon 1
#pragma newdecls required

static float g_flNextTeleportTime;

public void TeleporterMalfunction_OnMapStart(ChaosEffect effect)
{
	PrecacheSound("misc/halloween/spell_teleport.wav");
}

public bool TeleporterMalfunction_OnStart(ChaosEffect effect)
{
	int iCount = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		iCount++;
	}
	
	// Require at least 2 players
	if (iCount <= 1)
		return false;
	
	g_flNextTeleportTime = GetGameTime();
	return true;
}

public void TeleporterMalfunction_Update(ChaosEffect effect)
{
	if (g_flNextTeleportTime <= GetGameTime())
	{
		ArrayList hPlayers = new ArrayList();
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (!IsPlayerAlive(client))
				continue;
			
			hPlayers.Push(client);
		}
		
		// Require at least 2 players
		if (hPlayers.Length <= 1)
		{
			delete hPlayers;
			return;
		}
		
		g_flNextTeleportTime = GetGameTime() + GetRandomFloat(4.0, 6.0);
		EmitSoundToAll("misc/halloween/spell_teleport.wav", _, SNDCHAN_STATIC, SNDLEVEL_NONE);
		
		ArrayList hOthers = hPlayers.Clone();
		hOthers.Sort(Sort_Random, Sort_Integer);
		
		for (int i = 0; i < hPlayers.Length; i++)
		{
			int client = hPlayers.Get(i);
			
			for (int j = 0; j < hOthers.Length; j++)
			{
				int other = hOthers.Get(j);
				
				if (client == other)
					continue;
				
				float vecOrigin[3], angRotation[3], vecVelocity[3];
				GetEntPropVector(other, Prop_Data, "m_vecAbsOrigin", vecOrigin);
				GetEntPropVector(other, Prop_Data, "m_angAbsRotation", angRotation);
				GetEntPropVector(other, Prop_Data, "m_vecVelocity", vecVelocity);
				
				// Queue up the teleport, so that other players can get our old position
				DataPack hPack = new DataPack();
				hPack.WriteCell(client);
				hPack.WriteFloatArray(vecOrigin, sizeof(vecOrigin));
				hPack.WriteFloatArray(angRotation, sizeof(angRotation));
				hPack.WriteFloatArray(vecVelocity, sizeof(vecVelocity));
				hPack.Reset();
				
				RequestFrame(RequestFrame_TeleportPlayer, hPack);
				
				// Never repeat a position
				hOthers.Erase(j);
				j--;
				break;
			}
		}
		
		delete hPlayers;
		delete hOthers;
	}
}

static void RequestFrame_TeleportPlayer(DataPack hPack)
{
	int client = hPack.ReadCell();
	
	float vecOrigin[3], angRotation[3], vecVelocity[3];
	hPack.ReadFloatArray(vecOrigin, sizeof(vecOrigin));
	hPack.ReadFloatArray(angRotation, sizeof(angRotation));
	hPack.ReadFloatArray(vecVelocity, sizeof(vecVelocity));
	
	TeleportEntity(client, vecOrigin, angRotation, vecVelocity);
	
	delete hPack;
}
