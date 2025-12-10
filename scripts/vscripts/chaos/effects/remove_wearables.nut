function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		RemoveAllWearables(player)
	}
}

function RemoveAllWearables(player)
{
	for (local wearable = player.FirstMoveChild(); wearable != null; wearable = wearable.NextMovePeer())
	{
		if (!startswith(wearable.GetClassname(), "tf_wearable"))
			continue

		local item_def_index = NetProps.GetPropInt(wearable, "m_AttributeManager.m_Item.m_iItemDefinitionIndex")
		if (item_def_index == TF_DEFINDEX_CHARGIN_TARGE || item_def_index == TF_DEFINDEX_SPLENDID_SCREEN || item_def_index == TF_DEFINDEX_TIDE_TURNER || item_def_index == TF_DEFINDEX_FESTIVE_CHARGIN_TARGE)
			continue

		EntFireByHandle(wearable, "Kill", null, -1, null, null)
	}
}

function OnGameEvent_post_inventory_application(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	RemoveAllWearables(player)
}