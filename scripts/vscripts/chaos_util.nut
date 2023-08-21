// m_lifeState values
const LIFE_ALIVE = 0
const LIFE_DYING = 1
const LIFE_DEAD = 2
const LIFE_RESPAWNABLE = 3
const LIFE_DISCARDBODY = 4

const TF_DEATHFLAG_DEADRINGER = 32

::CTFPlayer.IsAlive <- function()
{
	return NetProps.GetPropInt(this, "m_lifeState") == LIFE_ALIVE
}

::CTFBot.IsAlive <- function()
{
	return NetProps.GetPropInt(this, "m_lifeState") == LIFE_ALIVE
}

function GetEnemyTeam(team)
{
	if (team == Constants.ETFTeam.TF_TEAM_RED)
		return Constants.ETFTeam.TF_TEAM_BLUE

	if (team == Constants.ETFTeam.TF_TEAM_BLUE)
		return Constants.ETFTeam.TF_TEAM_RED

	// no enemy team
	return team
}