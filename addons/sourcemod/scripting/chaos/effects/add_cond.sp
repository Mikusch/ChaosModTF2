#pragma semicolon 1
#pragma newdecls required

public void AddCond_GetClaims(ChaosEffect effect, ArrayList claims)
{
	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("conditions", false))
		return;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			char szClaim[EFFECT_MAX_CLAIM_LENGTH];
			FormatEx(szClaim, sizeof(szClaim), "cond:%d", kv.GetNum(NULL_STRING));

			claims.PushString(szClaim);
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();
}

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
	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("conditions"))
		return false;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			TFCond nCondition = view_as<TFCond>(kv.GetNum(NULL_STRING));

			for (int client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client))
					continue;

				TF2_AddCondition(client, nCondition);
			}
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();
	return true;
}

public void AddCond_OnEnd(ChaosEffect effect)
{
	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("conditions"))
		return;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			TFCond nCondition = view_as<TFCond>(kv.GetNum(NULL_STRING));

			for (int client = 1; client <= MaxClients; client++)
			{
				if (!IsClientInGame(client))
					continue;

				TF2_RemoveCondition(client, nCondition);
			}
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();
}

public void AddCond_OnPlayerSpawn(ChaosEffect effect, int client)
{
	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("conditions"))
		return;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			TF2_AddCondition(client, view_as<TFCond>(kv.GetNum(NULL_STRING)));
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();
}

public void AddCond_OnConditionRemoved(ChaosEffect effect, int client, TFCond condition)
{
	KeyValues kv = effect.OpenData();
	if (!kv || !kv.JumpToKey("conditions"))
		return;

	if (kv.GotoFirstSubKey(false))
	{
		do
		{
			if (view_as<TFCond>(kv.GetNum(NULL_STRING)) == condition)
			{
				TF2_AddCondition(client, condition);
				break;
			}
		}
		while (kv.GotoNextKey(false));
	}

	kv.Rewind();
}
