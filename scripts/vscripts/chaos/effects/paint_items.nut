function ChaosEffect_OnStart()
{
	for (local i = 1; i <= MaxClients(); i++)
	{
		local player = PlayerInstanceFromIndex(i)
		if (player == null)
			continue

		ApplyRandomPaintToItems(player)
	}
}

function ApplyRandomPaintToItems(player)
{
	for (local child = player.FirstMoveChild(); child != null; child = child.NextMovePeer())
	{
		if ("AddAttribute" in child)
		{
			child.AddAttribute("set item tint RGB", GetRandomColor(), -1)
			child.AddAttribute("set item tint RGB 2", GetRandomColor(), -1)
		}
	}
}

function GetRandomColor()
{
	return RandomInt(0, 0x1000000)
}

function OnGameEvent_post_inventory_application(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return

	ApplyRandomPaintToItems(player)
}