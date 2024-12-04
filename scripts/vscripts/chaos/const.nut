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

// m_takedamage
const DAMAGE_NO = 0
const DAMAGE_EVENTS_ONLY = 1
const DAMAGE_YES = 2
const DAMAGE_AIM = 3

const TF_DEATHFLAG_DEADRINGER = 32
const TF_BLEEDING_DMG = 4

// Sound channels
const CHAN_STATIC = 6

// Trace masks
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