
/*
    This fork uses a different versioning system
    as opposed to the public FF2 versioning system
*/
#define FORK_MAJOR_REVISION "1"
#define FORK_MINOR_REVISION "20"
#define FORK_STABLE_REVISION "5"
#define FORK_SUB_REVISION "Unofficial"
//#define FORK_DEV_REVISION "development"
#define FORK_DATE_REVISION "March 8, 2021"

#if defined FORK_DEV_REVISION
	#define PLUGIN_VERSION FORK_SUB_REVISION..." "...FORK_MAJOR_REVISION..."."...FORK_MINOR_REVISION..."."...FORK_STABLE_REVISION..." "...FORK_DEV_REVISION
#else
	#define PLUGIN_VERSION FORK_SUB_REVISION..." "...FORK_MAJOR_REVISION..."."...FORK_MINOR_REVISION..."."...FORK_STABLE_REVISION
#endif

/*
    And now, let's report its version as the latest public FF2 version
    for subplugins or plugins that uses the FF2_GetFF2Version native.
*/
#define MAJOR_REVISION "1"
#define MINOR_REVISION "11"
#define STABLE_REVISION "0"
#define DEV_REVISION "Beta"
#define DATE_REVISION "--Unknown--"

#define DATATABLE "ff2_stattrak"
#define CHANGELOG_URL "https://batfoxkid.github.io/FreakFortressBat"

#define MAXENTITIES 2048			// Probably shouldn't touch this
#define MAXSPECIALS 128				// Maximum bosses in a pack
#define MAXRANDOMS 64				// Maximum abilites in a boss
#define MAXTF2PLAYERS 36			// Maximum TF2 players + bots
#define MAXBOSSES RoundToFloor(MaxClients/2.0)	// Maximum number of bosses per a team
#define MAXCHARSETS 7				// Maximum number of charsets to save selection/view

#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_COLOR "m_iBossState"
#define HEALTHBAR_MAX 255
#define MONOCULUS "eyeball_boss"

#define ConfigPath "configs/freak_fortress_2"
#define DataPath "data/freak_fortress_2"
#define CharsetCFG "characters.cfg"
#define DoorCFG "doors.cfg"
#define DifficultyCFG "difficulty.cfg"
#define MapCFG "maps.cfg"
#define SpawnTeleportCFG "spawn_teleport.cfg"
#define SpawnTeleportBlacklistCFG "spawn_teleport_blacklist.cfg"
#define WeaponCFG "weapons.cfg"

#define LogPath "logs/freak_fortress_2"
#define BossLogPath "logs/freak_fortress_2/bosses"
#define DebugLog "ff2_debug.log"
#define ErrorLog "ff2_errors.log"

/*< freak_fortress_2.inc >*/
#define FF2FLAG_UBERREADY			(1<<1)		//Used when medic says "I'm charged!"
#define FF2FLAG_ISBUFFED			(1<<2)		//Used when soldier uses the Battalion's Backup
#define FF2FLAG_CLASSTIMERDISABLED 		(1<<3)		//Used to prevent clients' timer
#define FF2FLAG_HUDDISABLED			(1<<4)		//Used to prevent custom hud from clients' timer
#define FF2FLAG_BOTRAGE				(1<<5)		//Used by bots to use Boss's rage
#define FF2FLAG_TALKING				(1<<6)		//Used by Bosses with "sound_block_vo" to disable block for some lines
#define FF2FLAG_ALLOWSPAWNINBOSSTEAM		(1<<7)		//Used to allow spawn players in Boss's team
#define FF2FLAG_USEBOSSTIMER			(1<<8)		//Used to prevent Boss's timer
#define FF2FLAG_USINGABILITY			(1<<9)		//Used to prevent Boss's hints about abilities buttons
#define FF2FLAG_CLASSHELPED			(1<<10)
#define FF2FLAG_HASONGIVED			(1<<11)
#define FF2FLAG_CHANGECVAR			(1<<12)		//Used to prevent SMAC from kicking bosses who are using certain rages (NYI)
#define FF2FLAG_ALLOW_HEALTH_PICKUPS		(1<<13)		//Used to prevent bosses from picking up health
#define FF2FLAG_ALLOW_AMMO_PICKUPS		(1<<14)		//Used to prevent bosses from picking up ammo
#define FF2FLAG_ROCKET_JUMPING			(1<<15)		//Used when a soldier is rocket jumping
#define FF2FLAG_ALLOW_BOSS_WEARABLES		(1<<16)		//Used to allow boss having wearables (only for Official FF2)
#define FF2FLAGS_SPAWN				~FF2FLAG_UBERREADY & ~FF2FLAG_ISBUFFED & ~FF2FLAG_TALKING & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM & ~FF2FLAG_CHANGECVAR & ~FF2FLAG_ROCKET_JUMPING & FF2FLAG_USEBOSSTIMER & FF2FLAG_USINGABILITY