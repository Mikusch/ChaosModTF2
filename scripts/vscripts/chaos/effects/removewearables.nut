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

		EntFireByHandle(wearable, "Kill", null, -1, null, null)
	}
}

function Chaos_OnGameEvent_post_inventory_application(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	RemoveAllWearables(player)
}

Chaos_CollectEventCallbacks(this)