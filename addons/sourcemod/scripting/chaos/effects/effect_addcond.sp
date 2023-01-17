#pragma semicolon 1
#pragma newdecls required

public void AddCond_OnMapStart(ChaosEffect effect)
{
	// Halloween Ghost
	PrecacheModel("models/props_halloween/ghost_no_hat.mdl");
	PrecacheModel("models/props_halloween/ghost_no_hat_red.mdl");
	PrecacheScriptSound("Halloween.GhostBoo");
	
	// Bumper Cars
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar.mdl");
	PrecacheModel("models/props_halloween/bumpercar_cage.mdl");
	PrecacheScriptSound("BumperCar.Spawn");
	PrecacheScriptSound("BumperCar.SpawnFromLava");
	PrecacheScriptSound("BumperCar.GoLoop");
	PrecacheScriptSound("BumperCar.Screech");
	PrecacheScriptSound("BumperCar.HitGhost");
	PrecacheScriptSound("BumperCar.Bump");
	PrecacheScriptSound("BumperCar.BumpHard");
	PrecacheScriptSound("BumperCar.BumpIntoAir");
	PrecacheScriptSound("BumperCar.SpeedBoostStart");
	PrecacheScriptSound("BumperCar.SpeedBoostStop");
	PrecacheScriptSound("BumperCar.Jump");
	PrecacheScriptSound("BumperCar.JumpLand");
}

public bool AddCond_OnStart(ChaosEffect effect)
{
	if (!effect.data)
		return false;
	
	TFCond nCondition = view_as<TFCond>(effect.data.GetNum("condition"));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2_AddCondition(client, nCondition);
	}
	
	return true;
}

public void AddCond_OnEnd(ChaosEffect effect)
{
	TFCond nCondition = view_as<TFCond>(effect.data.GetNum("condition"));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		TF2_RemoveCondition(client, nCondition);
	}
}

public void AddCond_OnPlayerSpawn(ChaosEffect effect, int client)
{
	TF2_AddCondition(client, view_as<TFCond>(effect.data.GetNum("condition")));
}

public void AddCond_OnConditionRemoved(ChaosEffect effect, int client, TFCond condition)
{
	if (view_as<TFCond>(effect.data.GetNum("condition")) == condition)
	{
		TF2_AddCondition(client, condition);
	}
}
