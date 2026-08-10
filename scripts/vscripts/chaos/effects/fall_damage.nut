function OnScriptHook_OnTakeDamage(params)
{
	if (!(params.damage_type & DMG_FALL))
		return

	if (!params.const_entity.IsPlayer())
		return

	params.damage = params.damage * Chaos_GetData("multiplier", 1.0)
}