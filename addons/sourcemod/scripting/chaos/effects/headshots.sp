#pragma semicolon 1
#pragma newdecls required

public Action Headshots_TraceAttack(ChaosEffect effect, int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	damagetype |= DMG_USE_HITLOCATIONS;
	return Plugin_Changed;
}
