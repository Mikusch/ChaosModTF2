::CONST <- getconsttable()
::ROOT <- getroottable()

if (!("ConstantNamingConvention" in ROOT))
{
	foreach(a, b in Constants)
		foreach(k, v in b)
		{
			CONST[k] <- v != null ? v : 0
			ROOT[k] <- v != null ? v : 0
		}
}

CONST.setdelegate({ _newslot = @(k, v) compilestring("const " + k + "=" + (typeof(v) == "string" ? ("\"" + v + "\"") : v))() })

const FLT_MAX = 0x7F7FFFFF

const MAX_WEAPONS = 48

const TF_DEATHFLAG_DEADRINGER = 32

const TF_BLEEDING_DMG = 4

// m_takedamage
const DAMAGE_NO = 0
const DAMAGE_EVENTS_ONLY = 1
const DAMAGE_YES = 2
const DAMAGE_AIM = 3

const TF_WPN_TYPE_PRIMARY = 0
const TF_WPN_TYPE_SECONDARY = 1
const TF_WPN_TYPE_MELEE = 2
const TF_WPN_TYPE_GRENADE = 3
const TF_WPN_TYPE_BUILDING = 4
const TF_WPN_TYPE_PDA = 5
const TF_WPN_TYPE_ITEM1 = 6
const TF_WPN_TYPE_ITEM2 = 7
const TF_WPN_TYPE_HEAD = 8
const TF_WPN_TYPE_MISC = 9
const TF_WPN_TYPE_MELEE_ALLCLASS = 10
const TF_WPN_TYPE_SECONDARY2 = 11
const TF_WPN_TYPE_PRIMARY2 = 12
const TF_WPN_TYPE_ITEM3 = 13
const TF_WPN_TYPE_ITEM4 = 14

const TF_AMMO_DUMM = 0
const TF_AMMO_PRIMARY = 1
const TF_AMMO_SECONDARY = 2
const TF_AMMO_METAL = 3
const TF_AMMO_GRENADES1 = 4
const TF_AMMO_GRENADES2 = 5
const TF_AMMO_GRENADES3 = 6
const TF_AMMO_COUNT = 7 

// Flamethrower firing state
const FT_STATE_IDLE = 0

// env_fog_controller
const SF_FOG_MASTER = 0x0001

const TF_DEFINDEX_CHARGIN_TARGE = 131
const TF_DEFINDEX_SPLENDID_SCREEN = 406
const TF_DEFINDEX_TIDE_TURNER = 1099
const TF_DEFINDEX_FESTIVE_CHARGIN_TARGE = 1144

const CHAN_REPLACE = -1
const CHAN_AUTO = 0
const CHAN_WEAPON = 1
const CHAN_VOICE = 2
const CHAN_ITEM = 3
const CHAN_BODY = 4
const CHAN_STREAM = 5
const CHAN_STATIC = 6
const CHAN_VOICE2 = 7

CONST.MASK_SOLID <- (CONTENTS_SOLID | CONTENTS_MOVEABLE | CONTENTS_WINDOW | CONTENTS_MONSTER | CONTENTS_GRATE)
CONST.MASK_PLAYERSOLID <- (CONST.MASK_SOLID | CONTENTS_PLAYERCLIP)
CONST.MASK_SOLID_BRUSHONLY <- (CONTENTS_SOLID | CONTENTS_MOVEABLE | CONTENTS_WINDOW | CONTENTS_GRATE)

::PlayerClassNames <-
[
	"Undefined",
	"Scout",
	"Sniper",
	"Soldier",
	"Demoman",
	"Medic",
	"Heavy",
	"Pyro",
	"Spy",
	"Engineer",
	"Civilian",
	"",
	"Random"
]