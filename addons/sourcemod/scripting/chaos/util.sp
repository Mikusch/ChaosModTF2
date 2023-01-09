#pragma semicolon 1
#pragma newdecls required

int Compare(any val1, any val2)
{
	if (val1 > val2)
	{
		return 1;
	}
	else if (val1 < val2)
	{
		return -1;
	}
	
	return 0;
}

int SortFuncADTArray_SortChaosEffectsByCooldown(int index1, int index2, Handle array, Handle hndl)
{
	ArrayList list = view_as<ArrayList>(array);
	
	ChaosEffect effect1, effect2;
	list.GetArray(index1, effect1);
	list.GetArray(index2, effect2);
	
	// If both are the same, pick a random one
	return (effect1.cooldown_left == effect2.cooldown_left) ? GetRandomInt(-1, 1) : Compare(effect1.cooldown_left, effect2.cooldown_left);
}

void SendHudNotification(HudNotification_t iType, bool bForceShow = false)
{
	BfWrite bf = UserMessageToBfWrite(StartMessageAll("HudNotify"));
	bf.WriteByte(view_as<int>(iType));
	bf.WriteBool(bForceShow);	// Display in cl_hud_minmode
	EndMessage();
}
