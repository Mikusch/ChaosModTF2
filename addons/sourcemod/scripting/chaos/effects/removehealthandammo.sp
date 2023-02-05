#pragma semicolon 1
#pragma newdecls required

public bool RemoveHealthAndAmmo_OnStart(ChaosEffect effect)
{
	bool bRemovedHealth = false, bRemovedAmmo = false;
	
	int healthkit = -1;
	while ((healthkit = FindEntityByClassname(healthkit, "item_healthkit_*")) != -1)
	{
		RemoveEntity(healthkit);
		bRemovedHealth = true;
	}
	
	int ammopack = -1;
	while ((healthkit = FindEntityByClassname(ammopack, "item_ammopack_*")) != -1)
	{
		RemoveEntity(ammopack);
		bRemovedAmmo = true;
	}
	
	return bRemovedHealth || bRemovedAmmo;
}
