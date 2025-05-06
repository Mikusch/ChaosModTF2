function OnScriptHook_OnTakeDamage(params)
{
	// Only modify for CBaseCombatCharacter
	if (!NetProps.HasProp(params.const_entity, "m_flNextAttack"))
		return

	params.damage = 1
}