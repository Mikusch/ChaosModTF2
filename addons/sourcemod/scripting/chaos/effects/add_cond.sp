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

	if (!effect.data.JumpToKey("conditions"))
		return false;

	// Check for duplicate conditions in active effects
	if (effect.data.GotoFirstSubKey(false))
	{
		do
		{
			char szCondition[12];
			effect.data.GetString(NULL_STRING, szCondition, sizeof(szCondition));

			if (FindKeyValuePairInActiveEffects(effect.effect_class, "conditions", szCondition))
			{
				effect.data.GoBack(); // Go back to "conditions"
				effect.data.GoBack(); // Go back to root
				return false;
			}
		}
		while (effect.data.GotoNextKey(false));

		effect.data.GoBack();
	}

	// Apply all conditions
	if (effect.data.GotoFirstSubKey(false))
	{
		do
		{
			TFCond nCondition = view_as<TFCond>(effect.data.GetNum(NULL_STRING));

			for (int client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client))
					continue;

				TF2_AddCondition(client, nCondition);
			}
		}
		while (effect.data.GotoNextKey(false));

		effect.data.GoBack();
	}

	effect.data.GoBack();
	return true;
}

public void AddCond_OnEnd(ChaosEffect effect)
{
	if (!effect.data.JumpToKey("conditions"))
		return;

	if (effect.data.GotoFirstSubKey(false))
	{
		do
		{
			TFCond nCondition = view_as<TFCond>(effect.data.GetNum(NULL_STRING));

			for (int client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client))
					continue;

				TF2_RemoveCondition(client, nCondition);
			}
		}
		while (effect.data.GotoNextKey(false));

		effect.data.GoBack();
	}

	effect.data.GoBack();
}

public void AddCond_OnPlayerSpawn(ChaosEffect effect, int client)
{
	if (!effect.data.JumpToKey("conditions"))
		return;

	if (effect.data.GotoFirstSubKey(false))
	{
		do
		{
			TF2_AddCondition(client, view_as<TFCond>(effect.data.GetNum(NULL_STRING)));
		}
		while (effect.data.GotoNextKey(false));

		effect.data.GoBack();
	}

	effect.data.GoBack();
}

public void AddCond_OnConditionRemoved(ChaosEffect effect, int client, TFCond condition)
{
	if (!effect.data.JumpToKey("conditions"))
		return;

	if (effect.data.GotoFirstSubKey(false))
	{
		do
		{
			if (view_as<TFCond>(effect.data.GetNum(NULL_STRING)) == condition)
			{
				TF2_AddCondition(client, condition);
				break;
			}
		}
		while (effect.data.GotoNextKey(false));

		effect.data.GoBack();
	}

	effect.data.GoBack();
}
