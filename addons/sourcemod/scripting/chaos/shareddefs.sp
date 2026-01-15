#pragma semicolon 1
#pragma newdecls required

#define ONESHOT_EFFECT_DISPLAY_TIME	75.0

#define MAX_USER_MSG_DATA	255

// Fade in/out
#define FFADE_IN			0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT			0x0002		// Fade out (not in)
#define FFADE_MODULATE		0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT		0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE			0x0010		// Purges all other fades, replacing them with this one

#define SCREENFADE_FRACBITS		9		// which leaves 16-this for the integer part

enum Dir_t
{
	DIR_FWD,
	DIR_BACK,
	DIR_LEFT,
	DIR_RIGHT,

	DIR_UP,
	DIR_DOWN,

	NUM_DIRS
}

enum ShakeCommand_t
{
	SHAKE_START = 0,		// Starts the screen shake for all players within the radius.
	SHAKE_STOP,				// Stops the screen shake for all players within the radius.
	SHAKE_AMPLITUDE,		// Modifies the amplitude of an active screen shake for all players within the radius.
	SHAKE_FREQUENCY,		// Modifies the frequency of an active screen shake for all players within the radius.
	SHAKE_START_RUMBLEONLY,	// Starts a shake effect that only rumbles the controller, no screen effect.
	SHAKE_START_NORUMBLE,	// Starts a shake that does NOT rumble the controller.
};

enum HudNotification_t
{
	HUD_NOTIFY_YOUR_FLAG_TAKEN,
	HUD_NOTIFY_YOUR_FLAG_DROPPED,
	HUD_NOTIFY_YOUR_FLAG_RETURNED,
	HUD_NOTIFY_YOUR_FLAG_CAPTURED,

	HUD_NOTIFY_ENEMY_FLAG_TAKEN,
	HUD_NOTIFY_ENEMY_FLAG_DROPPED,
	HUD_NOTIFY_ENEMY_FLAG_RETURNED,
	HUD_NOTIFY_ENEMY_FLAG_CAPTURED,

	HUD_NOTIFY_TOUCHING_ENEMY_CTF_CAP,

	HUD_NOTIFY_NO_INVULN_WITH_FLAG,
	HUD_NOTIFY_NO_TELE_WITH_FLAG,

	HUD_NOTIFY_SPECIAL,

	HUD_NOTIFY_GOLDEN_WRENCH,

	HUD_NOTIFY_RD_ROBOT_UNDER_ATTACK,

	HUD_NOTIFY_HOW_TO_CONTROL_GHOST,
	HUD_NOTIFY_HOW_TO_CONTROL_KART,

	HUD_NOTIFY_PASSTIME_HOWTO,
	HUD_NOTIFY_PASSTIME_NO_TELE,
	HUD_NOTIFY_PASSTIME_NO_CARRY,
	HUD_NOTIFY_PASSTIME_NO_INVULN,
	HUD_NOTIFY_PASSTIME_NO_DISGUISE, 
	HUD_NOTIFY_PASSTIME_NO_CLOAK, 
	HUD_NOTIFY_PASSTIME_NO_OOB, // out of bounds
	HUD_NOTIFY_PASSTIME_NO_HOLSTER,
	HUD_NOTIFY_PASSTIME_NO_TAUNT,

	HUD_NOTIFY_COMPETITIVE_GC_DOWN,

	HUD_NOTIFY_TRUCE_START,
	HUD_NOTIFY_TRUCE_END,

	HUD_NOTIFY_HOW_TO_CONTROL_GHOST_NO_RESPAWN,

	NUM_STOCK_NOTIFICATIONS
};

enum
{
	LOADOUT_POSITION_INVALID = -1,

	// Weapons & Equipment
	LOADOUT_POSITION_PRIMARY = 0,
	LOADOUT_POSITION_SECONDARY,
	LOADOUT_POSITION_MELEE,
	LOADOUT_POSITION_UTILITY,
	LOADOUT_POSITION_BUILDING,
	LOADOUT_POSITION_PDA,
	LOADOUT_POSITION_PDA2,

	// Wearables. If you add new wearable slots, make sure you add them to IsWearableSlot() below this.
	LOADOUT_POSITION_HEAD,
	LOADOUT_POSITION_MISC,

	// other
	LOADOUT_POSITION_ACTION,

	// More wearables, yay!
	LOADOUT_POSITION_MISC2,

	// taunts
	LOADOUT_POSITION_TAUNT,
	LOADOUT_POSITION_TAUNT2,
	LOADOUT_POSITION_TAUNT3,
	LOADOUT_POSITION_TAUNT4,
	LOADOUT_POSITION_TAUNT5,
	LOADOUT_POSITION_TAUNT6,
	LOADOUT_POSITION_TAUNT7,
	LOADOUT_POSITION_TAUNT8,

	CLASS_LOADOUT_POSITION_COUNT,
};
