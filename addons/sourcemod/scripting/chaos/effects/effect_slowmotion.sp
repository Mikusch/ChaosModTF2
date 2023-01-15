#pragma semicolon 1
#pragma newdecls required

static ConVar host_timescale;
static ConVar sv_cheats;
static ConVar sm_chaos_effect_slowmotion_timescale;

static float flOldTimescale;

public bool SlowMotion_Initialize(ChaosEffect effect)
{
	host_timescale = FindConVar("host_timescale");
	sv_cheats = FindConVar("sv_cheats");
	
	sm_chaos_effect_slowmotion_timescale = CreateConVar("sm_chaos_effect_slowmotion_timescale", "0.5", "How much to slow the game down.");
	
	return true;
}

public void SlowMotion_OnMapStart(ChaosEffect effect)
{
	PrecacheSound("#replay/enterperformancemode.wav");
	PrecacheSound("#replay/exitperformancemode.wav");
}

public bool SlowMotion_OnStart(ChaosEffect effect)
{
	EmitSoundToAll("#replay/enterperformancemode.wav", _, SNDCHAN_STATIC, SNDLEVEL_NONE);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (IsFakeClient(client))
		{
			SetFakeClientConVar(client, "sv_cheats", "1");
		}
		else
		{
			sv_cheats.ReplicateToClient(client, "1");
		}
		
	}
	
	flOldTimescale = host_timescale.FloatValue;
	host_timescale.FloatValue *= sm_chaos_effect_slowmotion_timescale.FloatValue;
	
	return true;
}

public void SlowMotion_OnEnd(ChaosEffect effect)
{
	EmitSoundToAll("#replay/exitperformancemode.wav", _, SNDCHAN_STATIC, SNDLEVEL_NONE);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if (IsFakeClient(client))
			{
				SetFakeClientConVar(client, "sv_cheats", "0");
			}
			else
			{
				sv_cheats.ReplicateToClient(client, "0");
			}
		}
	}
	
	host_timescale.FloatValue = flOldTimescale;
}
