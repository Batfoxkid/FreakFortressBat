/*
                << Freak Fortress 2 >>
                    < Unofficial >

     Original Author of VSH and FF2, Rainbolt Dash
        Programmer, modeller, mapper, painter
             Author of Demoman The Pirate
         One of two creators of Floral Defence

      And notoriously famous for creating plugins
      with terrible code and then abandoning them.

      Updated by Otokiru, Powerlord, and RavensBro
       after Rainbolt Dash got sucked into DOTA2

     Updated again by Wliu, Chris, Lawd, and Carge
              after Powerlord quit FF2

           Old Versus Saxton Hale Thread:
  http://forums.alliedmods.net/showthread.php?t=146884
             Old Freak Fortress Thread:
  http://forums.alliedmods.net/showthread.php?t=182108
           New Versus Saxton Hale Thread:
  http://forums.alliedmods.net/showthread.php?t=244209
             New Freak Fortress Thread:
  http://forums.alliedmods.net/showthread.php?t=229013

    Freak Fortress and Versus Saxton Hale Subforum:
  http://forums.alliedmods.net/forumdisplay.php?f=154




 I'm not sure how long FF2 (or TF2 in general) is going to
last, but I would hate to see this plugin go, it's one of
my all time favorite gamemodes. I just love the concept of
one vs all gameplay. Sure it may have balance issues and
other broken things, but I'll still love this gamemode
either way. So I'm giving it one hella of a booster, one
last time or to encourage others to do the same.

					-Batfoxkid

          Unofficial Freak Fortress Thread:
  http://forums.alliedmods.net/showthread.php?t=313008
*/
#pragma semicolon 1

#include <sourcemod>
#include <freak_fortress_2>
#include <adt_array>
#include <clientprefs>
#include <morecolors>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=9
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS
#endif
#undef REQUIRE_PLUGIN
#tryinclude <smac>
#tryinclude <goomba>
#tryinclude <tf2attributes>
#tryinclude <freak_fortress_2_kstreak>
#define REQUIRE_PLUGIN

#pragma newdecls required

/*
    This fork uses a different versioning system
    as opposed to the public FF2 versioning system
*/
#define FORK_MAJOR_REVISION "1"
#define FORK_MINOR_REVISION "19"
#define FORK_STABLE_REVISION "1"
#define FORK_SUB_REVISION "Unofficial"
#define FORK_DEV_REVISION "Build"

#define BUILD_NUMBER FORK_MINOR_REVISION...""...FORK_STABLE_REVISION..."002"

#if !defined FORK_DEV_REVISION
	#define PLUGIN_VERSION FORK_SUB_REVISION..." "...FORK_MAJOR_REVISION..."."...FORK_MINOR_REVISION..."."...FORK_STABLE_REVISION
#else
	#define PLUGIN_VERSION FORK_SUB_REVISION..." "...FORK_MAJOR_REVISION..."."...FORK_MINOR_REVISION..."."...FORK_STABLE_REVISION..." "...FORK_DEV_REVISION..."-"...BUILD_NUMBER
#endif

/*
    And now, let's report its version as the latest public FF2 version
    for subplugins or plugins that uses the FF2_GetFF2Version native.
*/
#define MAJOR_REVISION "1"
#define MINOR_REVISION "11"
#define STABLE_REVISION "0"
#define DEV_REVISION "Beta"

#define MAXENTITIES 2048			// Probably shouldn't touch this
#define MAXSPECIALS 144				// Maximum bosses in a pack
#define MAXRANDOMS 64				// Maximum abilites in a boss
#define MAXBOSSES RoundToFloor(MaxClients/2.0)	// Maximum number of bosses per a team

#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_COLOR "m_iBossState"
#define HEALTHBAR_MAX 255
#define MONOCULUS "eyeball_boss"

// File paths
#define ConfigPath "configs/freak_fortress_2"
#define DataPath "data/freak_fortress_2"
#define LogPath "logs/freak_fortress_2"
#define BossLogPath "logs/freak_fortress_2/bosses"
#define CharsetCFG "characters.cfg"
#define DebugLog "ff2_debug.log"
#define DoorCFG "doors.cfg"
#define ErrorLog "ff2_errors.log"
#define MapCFG "maps.cfg"
#define SpawnTeleportCFG "spawn_teleport.cfg"
#define SpawnTeleportBlacklistCFG "spawn_teleport_blacklist.cfg"
#define WeaponCFG "weapons.cfg"

#if defined _steamtools_included
bool steamtools = false;
bool EnabledDesc = false;
#endif

#if defined _tf2attributes_included
bool tf2attributes = false;
#endif

#if defined _goomba_included
bool goomba = false;
#endif

#if defined _freak_fortress_2_kstreak_included
bool kmerge = false;
#endif

#if !defined _smac_included
bool smac = false;
#endif

bool TimesTen = false;

bool isCapping = false;
int RPSWinner;
int currentBossTeam;
bool blueBoss;
int OtherTeam = 2;
int BossTeam = 3;
int playing;
int playing2;
int playingmerc;
int playingboss;
int bosses;
int healthcheckused;
int RedAlivePlayers;
int BlueAlivePlayers;
int RedAliveBosses;
int BlueAliveBosses;
int RoundCount;
bool LastMan = true;
bool CheatsUsed;
float rageMax[MAXPLAYERS+1];
float rageMin[MAXPLAYERS+1];
int rageMode[MAXPLAYERS+1];
int Special[MAXPLAYERS+1];
int Incoming[MAXPLAYERS+1];

int Damage[MAXPLAYERS+1];
int curHelp[MAXPLAYERS+1];
int uberTarget[MAXPLAYERS+1];
bool hadshield[MAXPLAYERS+1];
int shield[MAXPLAYERS+1];
float shieldHP[MAXPLAYERS+1];
float shDmgReduction[MAXPLAYERS+1];
int detonations[MAXPLAYERS+1];
bool playBGM[MAXPLAYERS+1] = true;
int Healing[MAXPLAYERS+1];
float SapperCooldown[MAXPLAYERS+1];

char currentBGM[MAXPLAYERS+1][PLATFORM_MAX_PATH];

int FF2flags[MAXPLAYERS+1];

int Boss[MAXPLAYERS+1];
int BossHealthMax[MAXPLAYERS+1];
int BossHealth[MAXPLAYERS+1];
int BossHealthLast[MAXPLAYERS+1];
int BossLives[MAXPLAYERS+1];
int BossLivesMax[MAXPLAYERS+1];
int BossRageDamage[MAXPLAYERS+1];
bool BossSwitched[MAXPLAYERS+1];
float BossCharge[MAXPLAYERS+1][8];
float Stabbed[MAXPLAYERS+1];
float Marketed[MAXPLAYERS+1];
float Cabered[MAXPLAYERS+1];
float KSpreeTimer[MAXPLAYERS+1];
int KSpreeCount[MAXPLAYERS+1];
float GlowTimer[MAXPLAYERS+1];
int shortname[MAXPLAYERS+1];
float RPSLoser[MAXPLAYERS+1];
int RPSLosses[MAXPLAYERS+1];
int RPSHealth[MAXPLAYERS+1];
float AirstrikeDamage[MAXPLAYERS+1];
float KillstreakDamage[MAXPLAYERS+1];
float HazardDamage[MAXPLAYERS+1];
bool emitRageSound[MAXPLAYERS+1];
bool bossHasReloadAbility[MAXPLAYERS+1];
bool bossHasRightMouseAbility[MAXPLAYERS+1];
bool SpawnTeleOnTriggerHurt = false;
bool HealthBarMode;
bool HealthBarModeC[MAXPLAYERS+1];
bool ShowHealthText;

int timeleft;
int cursongId[MAXPLAYERS+1] = 1;

ConVar cvarVersion;
ConVar cvarPointDelay;
ConVar cvarPointTime;
ConVar cvarAnnounce;
ConVar cvarEnabled;
ConVar cvarAliveToEnable;
ConVar cvarPointType;
ConVar cvarCrits;
ConVar cvarArenaRounds;
ConVar cvarCircuitStun;
ConVar cvarSpecForceBoss;
ConVar cvarCountdownPlayers;
ConVar cvarCountdownTime;
ConVar cvarCountdownHealth;
ConVar cvarCountdownResult;
ConVar cvarEnableEurekaEffect;
ConVar cvarForceBossTeam;
ConVar cvarHealthBar;
ConVar cvarLastPlayerGlow;
ConVar cvarBossTeleporter;
ConVar cvarBossSuicide;
ConVar cvarShieldCrits;
ConVar cvarGoombaDamage;
ConVar cvarGoombaRebound;
ConVar cvarBossRTD;
ConVar cvarDeadRingerHud;
ConVar cvarDebug;
ConVar cvarPreroundBossDisconnect;
ConVar cvarCaberDetonations;
ConVar cvarDmg2KStreak;
ConVar cvarAirStrike;
ConVar cvarSniperDamage;
ConVar cvarSniperMiniDamage;
ConVar cvarBowDamage;
ConVar cvarBowDamageNon;
ConVar cvarBowDamageMini;
ConVar cvarSniperClimbDamage;
ConVar cvarSniperClimbDelay;
ConVar cvarStrangeWep;
ConVar cvarQualityWep;
ConVar cvarTripleWep;
ConVar cvarHardcodeWep;
ConVar cvarSelfKnockback;
ConVar cvarFF2TogglePrefDelay;
ConVar cvarNameChange;
ConVar cvarKeepBoss;
ConVar cvarSelectBoss;
ConVar cvarToggleBoss;
ConVar cvarDuoBoss;
ConVar cvarPointsInterval;
ConVar cvarPointsMin;
ConVar cvarPointsDamage;
ConVar cvarPointsExtra;
ConVar cvarAdvancedMusic;
ConVar cvarSongInfo;
ConVar cvarDuoRandom;
ConVar cvarDuoMin;
ConVar cvarDuoRestore;
ConVar cvarLowStab;
ConVar cvarGameText;
ConVar cvarAnnotations;
ConVar cvarTellName;
ConVar cvarShieldType;
ConVar cvarShieldHealth;
ConVar cvarShieldResist;
ConVar cvarCountdownOvertime;
ConVar cvarBossLog;
ConVar cvarBossDesc;
ConVar cvarRPSPoints;
ConVar cvarRPSLimit;
ConVar cvarRPSDivide;
ConVar cvarHealingHud;
ConVar cvarSteamTools;
ConVar cvarSappers;
ConVar cvarSapperCooldown;
ConVar cvarSapperStart;
ConVar cvarTheme;
ConVar cvarSelfHealing;
ConVar cvarBotRage;
ConVar cvarDamageToTele;
ConVar cvarStatHud;
ConVar cvarStatPlayers;
ConVar cvarStatWin2Lose;
ConVar cvarHealthHud;
ConVar cvarLookHud;
ConVar cvarSkipBoss;
ConVar cvarBossVsBoss;
ConVar cvarBvBLose;
ConVar cvarBvBChaos;
ConVar cvarBvBMerc;
ConVar cvarBvBStat;
ConVar cvarTimesTen;

Handle FF2Cookies;
Handle StatCookies;

Handle jumpHUD;
Handle rageHUD;
Handle livesHUD;
Handle timeleftHUD;
Handle abilitiesHUD;
Handle infoHUD;
Handle statHUD;
Handle healthHUD;
Handle rivalHUD;

bool Enabled = true;
bool Enabled2 = true;
bool Enabled3 = false;
int PointDelay = 6;
int PointTime = 45;
float Announce = 120.0;
float AliveToEnable = 0.2;
int PointType;
int arenaRounds;
float circuitStun;
float countdownPlayers = 1.0;
int countdownTime = 120;
int countdownHealth = 2000;
bool countdownOvertime = false;
bool SpecForceBoss;
float lastPlayerGlow = 1.0;
bool bossTeleportation = true;
int shieldCrits;
int allowedDetonations;
float GoombaDamage = 0.05;
float reboundPower = 300.0;
bool canBossRTD;
float SniperDamage = 2.0;
float SniperMiniDamage = 2.0;
float BowDamage = 1.25;
float BowDamageNon = 0.0;
float BowDamageMini = 0.0;
float SniperClimbDamage = 15.0;
float SniperClimbDelay = 1.56;
int QualityWep = 5;
int PointsInterval = 600;
float PointsInterval2 = 600.0;
int PointsMin = 10;
int PointsDamage = 0;
int PointsExtra = 10;
bool DuoMin = false;
bool TellName = false;
int Annotations = 0;

Handle MusicTimer[MAXPLAYERS+1];
Handle BossInfoTimer[MAXPLAYERS+1][2];
Handle DrawGameTimer;
Handle doorCheckTimer;

float HPTime;
char currentmap[99];
bool checkDoors = false;
bool bMedieval;
bool firstBlood;

int tf_arena_use_queue;
int mp_teams_unbalance_limit;
int tf_arena_first_blood;
int mp_forcecamera;
int tf_dropped_weapon_lifetime;
char mp_humans_must_join_team[16];
ConVar cvarTags;

Handle cvarNextmap;
bool areSubPluginsEnabled;

int FF2CharSet;
int validCharsets[64];
char FF2CharSetString[42];
bool isCharSetSelected = false;

int healthBar = -1;
int g_Monoculus = -1;

static bool executed = false;
static bool executed2 = false;
static bool ReloadFF2 = false;
static bool ReloadWeapons = false;
static bool ConfigWeapons = false;
static bool ReloadConfigs = false;
bool LoadCharset = false;
static bool HasSwitched = false;

Handle hostName;
char oldName[256];
int changeGamemode;
Handle kvWeaponMods = INVALID_HANDLE;

bool IsBossSelected[MAXPLAYERS+1];
bool dmgTriple[MAXPLAYERS+1];
bool randomCrits[MAXPLAYERS+1];
int SelfKnockback[MAXPLAYERS+1];
bool SapperBoss[MAXPLAYERS+1];
bool SapperMinion;
char BossIcon[64];
int SelfHealing[MAXPLAYERS+1];
float LifeHealing[MAXPLAYERS+1];
float OverHealing[MAXPLAYERS+1];

static const char OTVoice[][] =
{
	"vo/announcer_overtime.mp3",
	"vo/announcer_overtime2.mp3",
	"vo/announcer_overtime3.mp3",
	"vo/announcer_overtime4.mp3"
};

enum Operators
{
	Operator_None = 0,	// None, for checking valid brackets
	Operator_Add,		// +
	Operator_Subtract,	// -
	Operator_Multiply,	// *
	Operator_Divide,	// /
	Operator_Exponent	// ^
};

enum CookieStats
{
	Cookie_BossWins = 0,	// Boss Wins
	Cookie_BossLosses,	// Boss Losses
	Cookie_BossKills,	// Boss Kills
	Cookie_BossDeaths,	// Boss Deaths
	Cookie_PlayerKills,	// Player Boss Kills
	Cookie_PlayerMvps	// Player MVPs
};

static const char ff2versiontitles[][] =
{
	"1.0",
	"1.01",
	"1.01",
	"1.02",
	"1.03",
	"1.04",
	"1.05",
	"1.05",
	"1.06",
	"1.06c",
	"1.06d",
	"1.06e",
	"1.06f",
	"1.06g",
	"1.06h",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 1",
	"1.07 beta 4",
	"1.07 beta 5",
	"1.07 beta 6",
	"1.07",
	"1.0.8",
	"1.0.8",
	"1.0.8",
	"1.0.8",
	"1.0.8",
	"1.9.0",
	"1.9.0",
	"1.9.1",
	"1.9.2",
	"1.9.2",
	"1.9.3",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.0",
	"1.10.1",
	"1.10.1",
	"1.10.1",
	"1.10.1",
	"1.10.1",
	"1.10.2",
	"1.10.3",
	"1.10.3",
	"1.10.3",
	"1.10.3",
	"1.10.3",
	"1.10.4",
	"1.10.4",
	"1.10.4",
	"1.10.4",
	"1.10.4",
	"1.10.5",
	"1.10.6",
	"1.10.6",
	"1.10.6",
	"1.10.6",
	"1.10.7",
	"1.10.7",
	"1.10.7",
	"1.10.8",
	"1.10.9",
	"1.10.9",
	"1.10.9",
	"1.10.9",
	"1.10.9",
	"1.10.10",
	"1.10.11",
	"1.10.12",
	"1.10.13",
	"1.10.14",
	"1.11.3",
	"1.11.4",
	"1.11.5",
	"1.11.6",
	"1.11.7",
	"1.11.8",
	"1.11.9",
	"1.11.10",
	"1.11.11",
	"1.11.12",
	"1.11.13",
	"1.12.0",
	"1.12.1",
	"1.12.2",
	"1.12.3",
	"1.12.4",
	"1.13.0",
	"1.13.1",
	"1.13.2",
	"1.13.3",
	"1.13.4",
	"1.13.5",
	"1.13.6",
	"1.13.7",
	"1.13.8",
	"1.14.0",
	"1.14.1",
	"1.14.2",
	"1.14.3",
	"1.14.4",
	"1.14.5",
	"1.15.0",
	"1.15.1",
	"1.15.2",
	"1.15.3",
	"1.16.0",
	"1.16.1",
	"1.16.2",
	"1.16.3",
	"1.16.4",
	"1.16.5",
	"1.16.6",
	"1.16.7",
	"1.16.8",
	"1.16.9",
	"1.16.10",
	"1.16.11",
	"1.16.12",
	"1.17.0",
	"1.17.1",
	"1.17.2",
	"1.17.3",
	"1.17.4",
	"1.17.5",
	"1.17.5",
	"1.17.6",
	"1.17.6",
	"1.17.7",
	"1.17.8",
	"1.17.9",
	"1.17.9",
	"1.17.10",
	"1.18.0",
	"1.18.0",
	"1.18.1",
	"1.18.1",
	"1.18.2",
	"1.18.3",
	"1.18.4",
	"1.18.5",
	"1.18.6",
	"1.19.0"
};

static const char ff2versiondates[][] =
{
	"April 6, 2012",		//1.0
	"April 14, 2012",		//1.01
	"April 14, 2012",		//1.01
	"April 17, 2012",		//1.02
	"April 19, 2012",		//1.03
	"April 21, 2012",		//1.04
	"April 29, 2012",		//1.05
	"April 29, 2012",		//1.05
	"May 1, 2012",			//1.06
	"June 22, 2012",		//1.06c
	"July 3, 2012",			//1.06d
	"August 24, 2012",		//1.06e
	"September 5, 2012",		//1.06f
	"September 5, 2012",		//1.06g
	"September 6, 2012",		//1.06h
	"October 8, 2012",		//1.07 beta 1
	"October 8, 2012",		//1.07 beta 1
	"October 8, 2012",		//1.07 beta 1
	"October 8, 2012",		//1.07 beta 1
	"October 8, 2012",		//1.07 beta 1
	"October 11, 2012",		//1.07 beta 4
	"October 18, 2012",		//1.07 beta 5
	"November 9, 2012",		//1.07 beta 6
	"December 14, 2012",		//1.07
	"October 30, 2013",		//1.0.8
	"October 30, 2013",		//1.0.8
	"October 30, 2013",		//1.0.8
	"October 30, 2013",		//1.0.8
	"October 30, 2013",		//1.0.8
	"March 6, 2014",		//1.9.0
	"March 6, 2014",		//1.9.0
	"March 18, 2014",		//1.9.1
	"March 22, 2014",		//1.9.2
	"March 22, 2014",		//1.9.2
	"April 5, 2014",		//1.9.3
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"July 26, 2014",		//1.10.0
	"August 28, 2014",		//1.10.1
	"August 28, 2014",		//1.10.1
	"August 28, 2014",		//1.10.1
	"August 28, 2014",		//1.10.1
	"August 28, 2014",		//1.10.1
	"August 28, 2014",		//1.10.2
	"November 6, 2014",		//1.10.3
	"November 6, 2014",		//1.10.3
	"November 6, 2014",		//1.10.3
	"November 6, 2014",		//1.10.3
	"November 6, 2014",		//1.10.3
	"March 1, 2015",		//1.10.4
	"March 1, 2015",		//1.10.4
	"March 1, 2015",		//1.10.4
	"March 1, 2015",		//1.10.4
	"March 1, 2015",		//1.10.4
	"March 13, 2015",		//1.10.5
	"August 10, 2015",		//1.10.6
	"August 10, 2015",		//1.10.6
	"August 10, 2015",		//1.10.6
	"August 10, 2015",		//1.10.6
	"November 19, 2015",		//1.10.7
	"November 19, 2015",		//1.10.7
	"November 19, 2015",		//1.10.7
	"November 24, 2015",		//1.10.8
	"May 7, 2016",			//1.10.9
	"May 7, 2016",			//1.10.9
	"May 7, 2016",			//1.10.9
	"May 7, 2016",			//1.10.9
	"May 7, 2016",			//1.10.9
	"August 1, 2016",		//1.10.10
	"August 1, 2016",		//1.10.11
	"August 4, 2016",		//1.10.12
	"September 1, 2016",		//1.10.13
	"October 21, 2016",		//1.10.14
	"October 3, 2018",		//1.11.3
	"October 3, 2018",		//1.11.4
	"October 4, 2018",		//1.11.5
	"October 5, 2018",		//1.11.6
	"October 6, 2018",		//1.11.7
	"October 7, 2018",		//1.11.8
	"October 7, 2018",		//1.11.9
	"October 8, 2018",		//1.11.10
	"October 10, 2018",		//1.11.11
	"October 13, 2018",		//1.11.12
	"October 15, 2018",		//1.11.13
	"October 17, 2018",		//1.12.0
	"October 21, 2018",		//1.12.1
	"October 27, 2018",		//1.12.2
	"October 28, 2018",		//1.12.3
	"October 29, 2018",		//1.12.4
	"November 11, 2018",		//1.13.0
	"November 14, 2018",		//1.13.1
	"November 15, 2018",		//1.13.2
	"November 15, 2018",		//1.13.3
	"November 15, 2018",		//1.13.4
	"November 16, 2018",		//1.13.5
	"November 17, 2018",		//1.13.6
	"November 17, 2018",		//1.13.7
	"November 18, 2018",		//1.13.8
	"November 24, 2018",		//1.14.0
	"November 29, 2018",		//1.14.1
	"November 30, 2018",		//1.14.2
	"November 30, 2018",		//1.14.3
	"December 2, 2018",		//1.14.4
	"December 4, 2018",		//1.14.5
	"December 5, 2018",		//1.15.0
	"December 7, 2018",		//1.15.1
	"December 8, 2018",		//1.15.2
	"December 9, 2018",		//1.15.3
	"December 11, 2018",		//1.16.0
	"December 12, 2018",		//1.16.1
	"December 13, 2018",		//1.16.2
	"December 16, 2018",		//1.16.3
	"December 18, 2018",		//1.16.4
	"December 23, 2018",		//1.16.5
	"December 24, 2018",		//1.16.6
	"December 25, 2018",		//1.16.7
	"January 3, 2019",		//1.16.8
	"January 5, 2019",		//1.16.9
	"January 7, 2019",		//1.16.10
	"January 8, 2019",		//1.16.11
	"January 9, 2019",		//1.16.12
	"January 13, 2019",		//1.17.0
	"January 15, 2019",		//1.17.1
	"January 19, 2019",		//1.17.2
	"January 22, 2019",		//1.17.3
	"January 24, 2019",		//1.17.4
	"January 29, 2019",		//1.17.5
	"January 29, 2019",		//1.17.5
	"February 5, 2019",		//1.17.6
	"February 5, 2019",		//1.17.6
	"February 10, 2019",		//1.17.7
	"February 15, 2019",		//1.17.8
	"March 8, 2019",		//1.17.9
	"March 8, 2019",		//1.17.9
	"April 3, 2019",		//1.17.10
	"May 6, 2019",			//1.18.0
	"May 6, 2019",			//1.18.0
	"May 21, 2019",			//1.18.1
	"May 21, 2019",			//1.18.1
	"May 31, 2019",			//1.18.2
	"June 1, 2019",			//1.18.3
	"June 2, 2019",			//1.18.4
	"June 12, 2019",		//1.18.5
	"June 29, 2019",		//1.18.6
	"August 23, 2019"		//1.19.0
};

stock void FindVersionData(Handle panel, int versionIndex)
{
	switch(versionIndex)
	{
		case 149:  //1.19.0
		{
			DrawPanelText(panel, "1) [Gameplay] Added boss vs boss alterative gamemode (Batfoxkid)");
			DrawPanelText(panel, "2) [Bosses] Allowed to be able to self damage via 'selfknockback' setting (Batfoxkid)");
			DrawPanelText(panel, "3) [Gameplay] Razorback and Demoman shields are more accurate towards damage changes (Marxvee)");
			DrawPanelText(panel, "4) [Gameplay] Made the shields damage reduction based on the shield's health (Batfoxkid)");
			DrawPanelText(panel, "5) [Gameplay] Fixed the Razorback animation for Spies upon backstabbing the boss (Marxvee)");
		}
		case 148:  //1.18.6
		{
			DrawPanelText(panel, "1) [Bosses] Allowed multi-lanuage boss names (Batfoxkid)");
			DrawPanelText(panel, "2) [Core] Added support for tf_arena_preround_time changes (Batfoxkid)");
			DrawPanelText(panel, "3) [Gameplay] Spy disguising as a boss will make him appear as the boss (Marxvee)");
			DrawPanelText(panel, "4) [Gameplay] Medics automatically start with 40% Ubercharge (Batfoxkid)");
		}
		case 147:  //1.18.5
		{
			DrawPanelText(panel, "1) [Gameplay] Added the ability to look at teammates to see their stats (Marxvee)");
			DrawPanelText(panel, "2) [Gameplay] Fixed healing done tracking more then max player's health (Marxvee)");
			DrawPanelText(panel, "3) [Core] Support when cookie system is unavailable (Batfoxkid)");
			DrawPanelText(panel, "4) [Gameplay] Added boss menu option to skip being a boss (JuegosPablo)");
			DrawPanelText(panel, "5) [Core] Checks if players have access to their boss selection after access changes (Batfoxkid)");
		}
		case 146:  //1.18.4
		{
			DrawPanelText(panel, "1) [Core] Fixed serious issues caused by boss rocket jumping FF2 flag (Batfoxkid)");
		}
		case 145:  //1.18.3
		{
			DrawPanelText(panel, "1) [Core] Fixed serious issue with player alive based events (Batfoxkid)");
		}
		case 144:  //1.18.2
		{
			DrawPanelText(panel, "1) [Gameplay] Fixed Health HUD values being higher for most players (Batfoxkid)");
			DrawPanelText(panel, "2) [Gameplay] Ullapool Caber detonations message doesn't show for one-shot Cabers (Batfoxkid)");
			DrawPanelText(panel, "3) [Gameplay] Fixed boss healing (again) (Batfoxkid)");
			DrawPanelText(panel, "4) [Gameplay] Player alive ConVars can now be a ratio (Batfoxkid)");
		}
		case 143:  //1.18.1
		{
			DrawPanelText(panel, "1) [Gameplay] Deadringers kills don't count towards StatTrak kills (Batfoxkid)");
			DrawPanelText(panel, "2) [Gameplay] Added/updated ConVars for the Health Bar (Batfoxkid)");
			DrawPanelText(panel, "3) [Gameplay] Boss health bar turns green during markets, cabers, stabs, goombas, or healing (Batfoxkid)");
			DrawPanelText(panel, "4) [Core] Made FF2 more multi-gamemode friendly (Batfoxkid)");
			DrawPanelText(panel, "5) [Core] Added menus for some commands (Batfoxkid)");
		}
		case 142:  //1.18.1
		{
			DrawPanelText(panel, "6) [Core] Removed Updater and ShowActivity on commands (Batfoxkid)");
			DrawPanelText(panel, "7) [Bosses] Added catch_replace to replace specific class voicelines (Batfoxkid)");
		}
		case 141:  //1.18.0
		{
			DrawPanelText(panel, "1) [Core] Code is now in Transitional Syntax (Batfoxkid)");
			DrawPanelText(panel, "2) [Bosses] Merged all default subplugins (Batfoxkid)");
			DrawPanelText(panel, "3) [Gameplay] Added the StatTrak! (Batfoxkid from SHADoW)");
			DrawPanelText(panel, "4) [Bosses] Added new stun options (Batfoxkid from sarysa/SHADoW)");
			DrawPanelText(panel, "5) [Gameplay] Added the ability to sap bosses or minions (Batfoxkid from SHADoW)");
			DrawPanelText(panel, "6) [Bosses] Replaced 'ghost' with 'icon' setting for custom icon (Batfoxkid)");
		}
		case 140:  //1.18.0
		{
			DrawPanelText(panel, "7) [Core] Added ff2_setcharge and ff2_addcharge (Batfoxkid)");
			DrawPanelText(panel, "8) [Core] Debug commands use ShowActivity settings (Batfoxkid)");
			DrawPanelText(panel, "9) [Bosses] Added 'healing' option to allow bosses to heal (Batfoxkid)");
			DrawPanelText(panel, "10) [Gameplay] Bosses are now teleported to a random spawn when touching hazards (Chdata/sarysa/SHADoW)");
			DrawPanelText(panel, "11) [Core] Error messages are moved into a custom file (SHADoW)");
		}
		case 139:  //1.17.10
		{
			DrawPanelText(panel, "1) [Bosses] Added 'theme' setting for certain bosses blocked with ff2_theme (Batfoxkid)");
			DrawPanelText(panel, "2) [Core] weapons.cfg is applied first than hardcoded, when enabled (Batfoxkid)");
			DrawPanelText(panel, "3) [Core] Added Russian preference translations (MAGNAT2645)");
			DrawPanelText(panel, "4) [Gameplay] Players with class info off won't view boss description in boss menu (Batfoxkid)");
			DrawPanelText(panel, "5) [Bosses] Fixed sound_lastman playing multiple times in a round (Batfoxkid)");
		}
		case 138:  //1.17.9
		{
			DrawPanelText(panel, "1) [Core] Cvar to show boss description before selecting the boss (Batfoxkid)");
			DrawPanelText(panel, "2) [Gameplay] Adjusted some hardcoded weapons (Batfoxkid)");
			DrawPanelText(panel, "3) [Gameplay] Fixed pickups when FF2 is disabled (Batfoxkid)");
			DrawPanelText(panel, "4) [Gameplay] Cvar for RPS queue point betting and boss limiter (Batfoxkid/SHADoW)");
			DrawPanelText(panel, "5) [Gameplay] Cvar to show healing done (Marxvee)");
		}
		case 137:  //1.17.9
		{
			DrawPanelText(panel, "6) [Gameplay] Candy Cane Scouts gain healing credit (Marxvee)");
			DrawPanelText(panel, "7) [Gameplay] Fix shields against critical hits (Batfoxkid)");
			DrawPanelText(panel, "8) [Gameplay] Made Killstreaker and Airstrike damage more accurate (Batfoxkid)");
			DrawPanelText(panel, "9) [Gameplay] Cvar for Airstrike damage to gain a head (Batfoxkid)");
		}
		case 136:  //1.17.8
		{
			DrawPanelText(panel, "1) [Core] Added Russian core translations (MAGNAT2645)");
			DrawPanelText(panel, "2) [Core] Cvar to record boss wins/losses in a log (Batfoxkid)");
			DrawPanelText(panel, "3) [Bosses] Added sound_intromusic and sound_outtromusic (Batfoxkid from SHADoW)");
		}
		case 135:  //1.17.7
		{
			DrawPanelText(panel, "1) [Bosses] Added 'bossteam' to allow specific bosses to use a specific team (SHADoW)");
			DrawPanelText(panel, "2) [Gameplay] Cvar for overtime mode activates if countdown timer expires while capping a point (SHADoW)");
			DrawPanelText(panel, "3) [Core] Added new debug logging system (Batfoxkid)");
			DrawPanelText(panel, "4) [Gameplay] Cvar for Huntsman being crit boosted and it's damage (Batfoxkid)");
		}
		case 134:  //1.17.6
		{
			DrawPanelText(panel, "1) [Gameplay] Cvar for game_text_tf entities as HUD replacements (SHADoW)");
			DrawPanelText(panel, "2) [Gameplay] Cvar for annotations or game_text_tf entities as hint replacements (Batfoxkid/SHADoW)");
			DrawPanelText(panel, "3) [Gameplay] Cvar to say the player's or boss's name in messages (Batfoxkid from SHADoW)");
			DrawPanelText(panel, "4) [Core] Fixed some issues from previous update (Batfoxkid)");
			DrawPanelText(panel, "5) [Bosses] Added 'ghost' setting for bosses for game_text_tf (Batfoxkid)");
		}
		case 133:  //1.17.6
		{
			DrawPanelText(panel, "6) [Players] Shield HP and damage reduction option (SHADoW)");
			DrawPanelText(panel, "7) [Players] Non-lethal shots don't break and none option (Batfoxkid)");
			DrawPanelText(panel, "8) [Core] Renamed \"Bat's Edit\" to \"Unofficial\" (Batfoxkid)");
			DrawPanelText(panel, "9) [Core] Improved some older and all newer changelogs (Batfoxkid from SHADoW)");
			DrawPanelText(panel, "10) [Core] Fixed ragedamage formulas and settings (Batfoxkid)");
		}
		case 132:  //1.17.5
		{
			DrawPanelText(panel, "1) [Bosses] Rages can be set infinitely, disabled, or blocked (Batfoxkid)");
			DrawPanelText(panel, "2) [Bosses] Speeds can be set to not handled by FF2 or full stand-still (Batfoxkid)");
			DrawPanelText(panel, "3) [Bosses] Added minimum, maximum, and mode rage settings (Batfoxkid)");
			DrawPanelText(panel, "4) [Core] Imported official 1.10.15 commits (naydef/Wliu)");
			DrawPanelText(panel, "5) [Bosses] Control point and round time settings can be done per-boss (Batfoxkid)");
		}
		case 131:  //1.17.5
		{
			DrawPanelText(panel, "6) [Gameplay] Allowed both ff2_point_time and ff2_point_alive for ff2_point_type (Batfoxkid)");
			DrawPanelText(panel, "7) [Bosses] Boss weapons can set custom models, clip, ammo, and color (SHADoW)");
			DrawPanelText(panel, "8) [Bosses] Boss weapons can disable base damage bonus and capture rate (Batfoxkid)");
			DrawPanelText(panel, "9) [Players] Cvar to buff backstab, market garden, and caber for low-player count (Batfoxkid)");
		}
		case 130:  //1.17.4
		{
			DrawPanelText(panel, "1) [Players] Disable boss/companion for a map duration (Batfoxkid)");
			DrawPanelText(panel, "2) [Core] More multi-translation fixes (MAGNAT2645)");
			DrawPanelText(panel, "3) [Players] Option to restore queue points after being a companion (Batfoxkid)");
			DrawPanelText(panel, "4) [Developers] Added FF2_GetForkVersion native (Batfoxkid)");
		}
		case 129:  //1.17.3
		{
			DrawPanelText(panel, "1) [Gameplay] Last player glow cvar is now how many players are left (Batfoxkid)");
			DrawPanelText(panel, "2) [Core] Multi-translation fixes (MAGNAT2645)");
			DrawPanelText(panel, "3) [Bosses] Added 'sound_ability_serverwide' for serverwide RAGE sound (SHADoW)");
			DrawPanelText(panel, "4) [Bosses] Allowed 'ragedamage' to be a formula (Batfoxkid)");
		}
		case 128:  //1.17.2
		{
			DrawPanelText(panel, "1) [Core] Companion bosses unplayable when less then defined players (Batfoxkid)");
			DrawPanelText(panel, "2) [Core] Cvar to adjust how the companion is choosen (Batfoxkid)");
		}
		case 127:  //1.17.1
		{
			DrawPanelText(panel, "1) [Core] Skip song doesn't play previous song and added shuffle song (Batfoxkid from SHADoW)");
			DrawPanelText(panel, "2) [Core] Selectable theme in track menu (Batfoxkid from SHADoW)");
		}
		case 126:  //1.17.0
		{
			DrawPanelText(panel, "1) [Core] Advanced music menu and commands (Batfoxkid from SHADoW)");
			DrawPanelText(panel, "2) [Core] Readded and improved ff2_voice (Batfoxkid)");
		}
		case 125:  //1.16.12
		{
			DrawPanelText(panel, "1) Points extra cvar defines max queue points instead (Batfoxkid)");
		}
		case 124:  //1.16.11
		{
			DrawPanelText(panel, "1) Cvars to adjust how queue points are handled (Batfoxkid from SHADoW)");
		}
		case 123:  //1.16.10
		{
			DrawPanelText(panel, "1) Cvars to disable ff2boss, ff2toggle, and/or ff2companion commands (Batfoxkid)");
		}
		case 122:  //1.16.9
		{
			DrawPanelText(panel, "1) Added nofirst setting for bosses with a first-round glitch (Batfoxkid)");
			DrawPanelText(panel, "2) Allowed to keep the boss players selected until another selection (Batfoxkid)");
			DrawPanelText(panel, "3) Removed 'No Random Critical Hits'' when attributes is undefined (Batfoxkid)");
		}
		case 121:  //1.16.8
		{
			DrawPanelText(panel, "1) Medi-Gun skins and festives are now shown (Batfoxkid)");
			DrawPanelText(panel, "2) Added crit setting for bosses (Batfoxkid)");
			DrawPanelText(panel, "3) 'Set rage' command sets rage and added 'add rage' command (Batfoxkid)");
		}
		case 120:  //1.16.7
		{
			DrawPanelText(panel, "1) Only block join team commands during a FF2 round (naydef)");
		}
		case 119:  //1.16.6
		{
			DrawPanelText(panel, "1) Added set rage command and infinite rage command (SHADoW from Chdata)");
		}
		case 118:  //1.16.5
		{
			DrawPanelText(panel, "1) Added self-knockback setting for bosses (Batfoxkid)");
		}
		case 117:  //1.16.4
		{
			DrawPanelText(panel, "1) Dead Ringer HUD (Chdata/naydef)");
		}
		case 116:  //1.16.3
		{
			DrawPanelText(panel, "1) Fixed owner marked bosses choosen by random (Batfoxkid)");
		}
		case 115:  //1.16.2
		{
			DrawPanelText(panel, "1) Server name has the current boss name (Deathreus)");
		}
		case 114:  //1.16.1
		{
			DrawPanelText(panel, "1) Details and more commands (Batfoxkid)");
			DrawPanelText(panel, "2) Fixed companion toggle (Batfoxkid)");
		}
		case 113:  //1.16.0
		{
			DrawPanelText(panel, "1) Boss selection and toggle (Batfoxkid from SHADoW)");
			DrawPanelText(panel, "2) Added owner settings for bosses (Batfoxkid)");
			DrawPanelText(panel, "3) Added triple settings for bosses (Batfoxkid/SHADoW)");
		}
		case 112:  //1.15.3
		{
			DrawPanelText(panel, "1) Bosses can take self-knockback (Bacon Plague/M76030)");
		}
		case 111:  //1.15.2
		{
			DrawPanelText(panel, "1) Fixed boss health being short by one (Batfoxkid)");
		}
		case 110:  //1.15.1
		{
			DrawPanelText(panel, "1) Weapons by config (SHADoW)");
			DrawPanelText(panel, "2) Fixed Razorback (naydef)");
			DrawPanelText(panel, "3) cvar to use hard-coded weapons (Batfoxkid)");
			DrawPanelText(panel, "4) Updated weapons stats (Batfoxkid)");
			DrawPanelText(panel, "5) Readded RTD support (for the last time) (Batfoxkid)");
			DrawPanelText(panel, "6) Boss health is reset on round start (Batfoxkid)");
		}
		case 109:  //1.15.0
		{
			DrawPanelText(panel, "1) Non-character configs use data filepath (SHADoW)");
			DrawPanelText(panel, "2) Added several admin commands for FF2 (SHADoW)");
			DrawPanelText(panel, "3) Sandman is no longer normally crit-boosted (Batfoxkid)");
		}
		case 108:  //1.14.5
		{
			DrawPanelText(panel, "1) Nerfed L'etranger (Batfoxkid)");
			DrawPanelText(panel, "2) Sniper can wall climb within FF2 (SHADoW)");
			DrawPanelText(panel, "3) Cvars for Sniper wall climbing (Batfoxkid)");
		}
		case 107:  //1.14.4
		{
			DrawPanelText(panel, "1) Boss BGM can be adjusted by TF2's music slider (SHADoW)");
			DrawPanelText(panel, "2) Bosses can set custom quaility and level (SHADoW)");
			DrawPanelText(panel, "3) Bosses can set custom strange rank/randomize rank (Batfoxkid)");
		}
		case 106:  //1.14.3
		{
			DrawPanelText(panel, "1) Fixed major issues with Huntsman and Sniper class (Batfoxkid)");
		}
		case 105:  //1.14.2
		{
			DrawPanelText(panel, "1) Adjusted Sniper Rifle/Huntsman damage with cvars (Batfoxkid)");
			DrawPanelText(panel, "2) Fixed Cozy Camper's SMG unable to be crit boosted (Batfoxkid)");
		}
		case 104:  //1.14.1
		{
			DrawPanelText(panel, "1) Killstreak system by damage done to the boss (shadow93)");
			DrawPanelText(panel, "2) Nerfed Sniper Rifle/Hunstman damage (Batfoxkid)");
			DrawPanelText(panel, "3) Buffed Sharpened Volcano Fragment (Batfoxkid)");
			DrawPanelText(panel, "4) Gave Huntsman faster charge rate (Batfoxkid)");
		}
		case 103:  //1.14.0
		{
			DrawPanelText(panel, "1) Reworked various weapons stats (Batfoxkid)");
			DrawPanelText(panel, "2) Caber no longer is crit boosted when used (Batfoxkid)");
			DrawPanelText(panel, "3) SMG deals only mini-crits (Batfoxkid)");
			DrawPanelText(panel, "4) Pistol is no longer crit-boosted by both classes (Batfoxkid)");
			DrawPanelText(panel, "5) Crit-boosted weapons that already crit (Batfoxkid)");
		}
		case 102:  //1.13.8
		{
			DrawPanelText(panel, "1) Ullapool Caber nerfed damage (Batfoxkid)");
			DrawPanelText(panel, "2) Forgot to mention Market Garden nerf like in VSH in 1.13.6 (Batfoxkid)");
		}
		case 101:  //1.13.7
		{
			DrawPanelText(panel, "1) ''admin'' in boss configs also acts the same as ''blocked'' (Batfoxkid)");
		}
		case 100:  //1.13.6
		{
			DrawPanelText(panel, "1) Pistol nerf reverted and Engineer's pistols mini-crit normally (Batfoxkid)");
			DrawPanelText(panel, "2) Buffed SMG's damage along too (Batfoxkid)");
			DrawPanelText(panel, "3) Ullapool Caber acts like a smaller Market Garden/Backstab (Batfoxkid)");
			DrawPanelText(panel, "4) Removed Ullapool Caber's multi-detonations (Batfoxkid)");
		}
		case 99:  //1.13.5
		{
			DrawPanelText(panel, "1) Reverted Razorback to match Darwin's Danger Sheild (Batfoxkid)");
			DrawPanelText(panel, "2) ''donator'' in boss configs acts the same as ''blocked'' (Batfoxkid)");
		}
		case 98:  //1.13.4
		{
			DrawPanelText(panel, "1) Increased max amount of bosses in a pack from 64 to 150 (Batfoxkid/WakaFlocka)");
			DrawPanelText(panel, "2) Increased max amount of abilties in a boss from 14 to 64? (Batfoxkid/WakaFlocka)");
		}
		case 97:  //1.13.3
		{
			DrawPanelText(panel, "1) Fixed FORK_STABLE_REVISION being STABLE_REVISION (Batfoxkid)");
		}
		case 96:  //1.13.2
		{
			DrawPanelText(panel, "1) Made public version number the same while keeping fork version");
			DrawPanelText(panel, "2) number for plugins using the FF2_GetFF2Version native. (Batfoxkid)");
		}
		case 95:  //1.13.1
		{
			DrawPanelText(panel, "1) Fixed FF2 messages not looping correctly (Batfoxkid)");
			DrawPanelText(panel, "2) Reworked Bazaar Bargain (Batfoxkid)");
		}
		case 94:  //1.13.0
		{
			DrawPanelText(panel, "1) Kritzkrieg gives only crits on Uber but faster Uber rate (Batfoxkid)");
			DrawPanelText(panel, "2) Quick-Fix gives no invulnerably but immunity to knockback with Uber (Batfoxkid)");
			DrawPanelText(panel, "3) Vaccinator gives a projectile sheild but weak Uber rate (Batfoxkid)");
			DrawPanelText(panel, "4) Nerfed Vita-Saw (Batfoxkid)");
		}
		case 93:  //1.12.4
		{
			DrawPanelText(panel, "1) Buffed Gunboats (Batfoxkid)");
			DrawPanelText(panel, "2) Reworked Chargin' Targe and Homewrecker/Mual (Batfoxkid)");
		}
		case 92:  //1.12.3
		{
			DrawPanelText(panel, "1) Buffed Rocket/Sticky Jumper (Batfoxkid)");
		}
		case 91:  //1.12.2
		{
			DrawPanelText(panel, "1) Nerfed KGB and buffed Enforcer (Batfoxkid)");
			DrawPanelText(panel, "2) YER/Wanga Prick makes backstabs silent except critical sound (Batfoxkid)");
		}
		case 90:  //1.12.1
		{
			DrawPanelText(panel, "1) DEV_REVISION adjusted to not get confused with official FF2 (Batfoxkid)");
		}
		case 89:  //1.12.0
		{
			DrawPanelText(panel, "1) Bosses damage output no longer tripled if");
			DrawPanelText(panel, "    the damage is less than 160 (Batfoxkid)");
		}
		case 88:  //1.11.13
		{
			DrawPanelText(panel, "1) Buffed Mantreads (Batfoxkid)");
		}
		case 87:  //1.11.12
		{
			DrawPanelText(panel, "1) BGM looping fixes (naydef)");
		}
		case 86:  //1.11.11
		{
			DrawPanelText(panel, "1) Fixed Detonator and Eviction Notice (Batfoxkid)");
		}
		case 85:  //1.11.10
		{
			DrawPanelText(panel, "1) Buffed Short Circuit, Righteous Bison, and Pomson 6000 (Batfoxkid)");
			DrawPanelText(panel, "2) Added sound_marketed and sound_telefraged (Batfoxkid)");
			DrawPanelText(panel, "3) Removed ff2_voice, due to it only working for very little sounds (Batfoxkid)");
		}
		case 84:  //1.11.9
		{
			DrawPanelText(panel, "1) Bosses no longer have fall damage sound effects (Batfoxkid)");
			DrawPanelText(panel, "1) Buffed Huo-Long Heater (Noobis)");
		}
		case 83:  //1.11.8
		{
			DrawPanelText(panel, "1) Nerfed KGB and Razorback (Batfoxkid)");
			DrawPanelText(panel, "2) Buffed Rocket/Sticky Jumper (Batfoxkid)");
			DrawPanelText(panel, "3) Reworked Razorback (Batfoxkid)");
			DrawPanelText(panel, "4) and Huo-Long Heater (Noobis)");
		}
		case 82:  //1.11.7
		{
			DrawPanelText(panel, "1) Nerfed KGB and Razorback (Batfoxkid)");
		}
		case 81:  //1.11.6
		{
			DrawPanelText(panel, "1) Adjusted, added, and reworked alot of weapons, too much to list (Batfoxkid)");
		}
		case 80:  //1.11.5
		{
			DrawPanelText(panel, "1) Battalion's Backup no longer gives full rage upon being hit (Batfoxkid)");
		}
		case 79:  //1.11.4
		{
			DrawPanelText(panel, "1) [Server] Always says Freak Fortress in game name (Batfoxkid)");
			DrawPanelText(panel, "       (Assuming that this server is always using FF2)");
			DrawPanelText(panel, "2) Actually blocked spectate command (Batfoxkid)");
			DrawPanelText(panel, "3) Updated killing spree, hit sounds, etc. (Batfoxkid)");
			DrawPanelText(panel, "4) No longer using TF2Items, hardcoded now (Batfoxkid)");
		}
		case 78:  //1.11.3
		{
			DrawPanelText(panel, "1) Spectate command is blocked as the boss (Batfoxkid)");
			DrawPanelText(panel, "2) Huo-Long Heater work-in-progress change (Noobis)");
		}
		case 77:  //1.10.14
		{
			DrawPanelText(panel, "1) Fixed minions occasionally spawning on the wrong team (Wliu from various)");
			DrawPanelText(panel, "2) Fixed ff2_start_music at the start of the round causing music to overlap (naydef)");
			DrawPanelText(panel, "3) Fixed new clients not hearing music in certain circumstances (naydef)");
		}
		case 76:  //1.10.13
		{
			DrawPanelText(panel, "1) Fixed insta-backstab issues (Wliu from tom0034)");
			DrawPanelText(panel, "2) Fixed team-changing exploit (Wliu from Edge_)");
			DrawPanelText(panel, "3) [Server] Fixed an error message logging the wrong values (Wliu)");
		}
		case 75:  //1.10.12
		{
			DrawPanelText(panel, "1) Actually fixed BGMs not looping (Wliu from WakaFlocka, again)");
			DrawPanelText(panel, "2) Fixed new clients not respecting the current music state (Wliu from shadow93)");
		}
		case 74:  //1.10.11
		{
			DrawPanelText(panel, "1) Fixed BGMs not looping (Wliu from WakaFlocka)");
		}
		case 73:  //1.10.10
		{
			DrawPanelText(panel, "1) Fixed multiple BGM issues in 1.10.9 (Wliu, shadow93, Nopied, WakaFlocka, and others)");
			DrawPanelText(panel, "2) Automatically start BGMs for new clients (Wliu)");
			DrawPanelText(panel, "3) Fixed the top damage dealt sometimes displaying as 0 damage (naydef)");
			DrawPanelText(panel, "4) Added back Shortstop reload penalty to reflect its buff in the Meet Your Match update (Wliu)");
			DrawPanelText(panel, "5) [Server] Fixed an invalid client error in ff2_1st_set_abilities.sp (Wliu)");
			DrawPanelText(panel, "6) [Server] Fixed a GetEntProp error (Wliu from Hemen353)");
		}
		case 72:  //1.10.9
		{
			DrawPanelText(panel, "1) Fixed a critical exploit related to sv_cheats (naydef)");
			DrawPanelText(panel, "2) Updated weapons for the Tough Break update (Wliu)");
			DrawPanelText(panel, "Partially synced with VSH (all changes listed courtesy of VSH contributors and shadow93)");
			DrawPanelText(panel, "2) VSH: Don't play end-of-round announcer sounds");
			DrawPanelText(panel, "3) VSH: Increase boss damage to 210% (up from 200%)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 71:  //1.10.9
		{
			DrawPanelText(panel, "4) VSH: Give scout bosses +3 capture rate instead of +4");
			DrawPanelText(panel, "5) VSH: Don't actually call for medic when activating rage");
			DrawPanelText(panel, "6) VSH: Override attributes for all mediguns and syringe guns");
			DrawPanelText(panel, "7) Fixed Ambassador, Diamondback, Phlogistinator, and the Manmelter not dealing the correct damage (Dalix)");
			DrawPanelText(panel, "8) Adjusted medgiun and Dead Ringer mechanics to provide a more native experience (Wliu)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 70:  //1.10.9
		{
			DrawPanelText(panel, "9) Prevent `autoteam` spam and possible crashes (naydef)");
			DrawPanelText(panel, "10) Fixed boss's health not appearing correctly before round start (Wliu)");
			DrawPanelText(panel, "11) Fixed ff2_alive...again (Wliu from Dalix)");
			DrawPanelText(panel, "12) Fixed BossInfoTimer (that thing no one knows about because it never worked) (Wliu)");
			DrawPanelText(panel, "13) Reset clone status properly (Wliu)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 69:  //1.10.9
		{
			DrawPanelText(panel, "13) Don't allow sound_kill_* and sound_hit to overlap each other (Wliu from WakaFlocka)");
			DrawPanelText(panel, "14) Prevent sound_lastman sounds from overlapping with regular kill sounds (Wliu from WakaFlocka)");
			DrawPanelText(panel, "15) Updated Russian translation (silenser)");
			DrawPanelText(panel, "16) [Server] Make sure the entity is valid before creating a healthbar (shadow93)");
			DrawPanelText(panel, "17) [Server] Fixed invalid client errors originating from ff2_1st_set_abilities.sp (Wliu)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 68:  //1.10.9
		{
			DrawPanelText(panel, "18) [Server] Added ff2_start_music command for symmetry (Wliu from WakaFlocka)");
			DrawPanelText(panel, "19) [Dev] Actually make FF2_OnMusic work (Wliu from shadow93)");
			DrawPanelText(panel, "20) [Dev] Rewrote BGM code (Wliu)");
			DrawPanelText(panel, "21) [Dev] Fixed ability sounds playing even if the ability was canceled in FF2_PreAbility (Wliu from xNanoChip)");
		}
		case 67:  //1.10.8
		{
			DrawPanelText(panel, "1) Fixed the Powerjack and Kunai killing the boss in one hit (naydef)");
		}
		case 66:  //1.10.7
		{
			DrawPanelText(panel, "1) Fixed companions always having default rage damage and lives, even if specified otherwise (Wliu from Shadow)");
			DrawPanelText(panel, "2) Fixed bosses instantly losing if a boss disconnected while there were still other bosses alive (Shadow from Spyper)");
			DrawPanelText(panel, "3) Fixed minions receiving benefits intended only for normal players (Wliu)");
			DrawPanelText(panel, "4) Removed Shortstop reload penalty (Starblaster64)");
			DrawPanelText(panel, "5) Whitelisted the Shooting Star (Wliu)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 65:  //1.10.7
		{
			DrawPanelText(panel, "6) Fixed large amounts of lives being cut off when being displayed (Wliu)");
			DrawPanelText(panel, "7) More living spectator fixes (naydef, Shadow)");
			DrawPanelText(panel, "8) Fixed health bar not updating when goomba-ing the boss (Wliu from Akuba)");
			DrawPanelText(panel, "9) [Server] Added arg12 to rage_cloneattack to determine whether or not clones die after their boss dies (Wliu");
			DrawPanelText(panel, "10) [Server] Fixed 'UTIL_SetModel not precached' crashes when using 'model_projectile_replace' (Wliu from Shadow)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 64:  //1.10.7
		{
			DrawPanelText(panel, "11) [Server] 'ff2_crits' now defaults to 0 instead of 1 (Wliu from Spyper)");
			DrawPanelText(panel, "12) [Server] Fixed divide by 0 errors (Wliu)");
			DrawPanelText(panel, "13) [Dev] Fixed FF2_OnAlivePlayersChanged not returning the number of minions (Wliu)");
			DrawPanelText(panel, "14) [Dev] Fixed PDAs and sappers not being usable when given to bosses (Shadow)");
		}
		case 63:  //1.10.6
		{
			DrawPanelText(panel, "1) Updated the default health formula to match VSH's (Wliu)");
			DrawPanelText(panel, "2) Updated for compatability with the Gunmettle update (Wliu, Shadow, Starblaster64, Chdata, sarysa, and others)");
			DrawPanelText(panel, "3) Fixed boss weapon animations sometimes not working (Chdata)");
			DrawPanelText(panel, "4) Disconnecting bosses now get replaced by the person with the second-highest queue points (Shadow)");
			DrawPanelText(panel, "5) Fixed bosses rarely becoming 'living spectators' during the first round (Shadow/Wliu)");
			DrawPanelText(panel, "See next page (press 1");
		}
		case 62:  //1.10.6
		{
			DrawPanelText(panel, "6) Fixed large amounts of damage insta-killing multi-life bosses (Wliu from Shadow)");
			DrawPanelText(panel, "7) Fixed death effects triggering when FF2 wasn't active (Shadow)");
			DrawPanelText(panel, "8) Fixed 'sound_fail' playing even when the boss won (Shadow)");
			DrawPanelText(panel, "9) Fixed charset voting again (Wliu from Shadow)");
			DrawPanelText(panel, "10) Fixed bravejump sounds not playing (Wliu from Maximilian_)");
			DrawPanelText(panel, "See next page (press 1");
		}
		case 61:  //1.10.6
		{
			DrawPanelText(panel, "11) Fixed end-of-round text occasionally showing random symbols and file paths (Wliu)");
			DrawPanelText(panel, "12) Updated Russian translations (Maximilian_)");
			DrawPanelText(panel, "13) [Server] Fixed 'UTIL_SetModel not precached' crashes-see #18 for the underlying fix (Shadow/Wliu)");
			DrawPanelText(panel, "14) [Server] Fixed Array Index Out of Bounds errors when there are more than 32 chances (Wliu from Maximilian_)");
			DrawPanelText(panel, "15) [Server] Fixed invalid client errors in easter_abilities.sp (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 60:  //1.10.6
		{
			DrawPanelText(panel, "16) [Server] Missing boss files are now logged (Shadow)");
			DrawPanelText(panel, "17) [Dev] Added FF2_StartMusic that was missing from the include file (Wliu from Shadow)");
			DrawPanelText(panel, "18) [Dev] FF2_GetBossIndex now makes sure the client index passed is valid (Wliu)");
			DrawPanelText(panel, "19) [Dev] Rewrote the health formula parser and fixed a few bugs along the way (WildCard65/Wliu)");
			DrawPanelText(panel, "20) [Dev] Prioritized exact matches in OnSpecialSelected and added a 'preset' bool (Wliu from Shadow)");
			DrawPanelText(panel, "21) [Dev] Removed deprecated FCVAR_PLUGIN cvar flags (Wliu)");
		}
		case 59:  //1.10.5
		{
			DrawPanelText(panel, "1) Fixed slow-mo being extremely buggy (Wliu from various)");
			DrawPanelText(panel, "2) Fixed the Festive SMG not getting crits (Wliu from Dalix)");
			DrawPanelText(panel, "3) Fixed teleport sounds not being played (Wliu from Dalix)");
			DrawPanelText(panel, "4) !ff2_stop_music can now target specific clients (Wliu)");
			DrawPanelText(panel, "5) [Server] Fixed multiple sounds not working after TF2 changed the default sound extension type (Wliu)");
			DrawPanelText(panel, "6) [Dev] Fixed rage damage not resetting after using FF2_SetBossRageDamage (Wliu from WildCard65)");
		}
		case 58:  //1.10.4
		{
			DrawPanelText(panel, "1) Fixed players getting overheal after winning as a boss (Wliu/FlaminSarge)");
			DrawPanelText(panel, "2) Rebalanced the Baby Face's Blaster (Shadow)");
			DrawPanelText(panel, "3) Fixed the Baby Face's Blaster being unusable when FF2 was disabled (Wliu from Curtgust)");
			DrawPanelText(panel, "4) Fixed the Darwin's Danger Shield getting replaced by the SMG (Wliu)");
			DrawPanelText(panel, "5) Added the Tide Turner and new festive weapons to the weapon whitelist (Wliu)");
			DrawPanelText(panel, "See next page (press 1");
		}
		case 57:  //1.10.4
		{
			DrawPanelText(panel, "6) Fixed Market Gardener backstabs (Wliu)");
			DrawPanelText(panel, "7) Improved class switching after you finish the round as a boss (Wliu)");
			DrawPanelText(panel, "8) Fixed the !ff2 command again (Wliu)");
			DrawPanelText(panel, "9) Fixed bosses not ducking when teleporting (CapnDev)");
			DrawPanelText(panel, "10) Prevented dead companion bosses from becoming clones (Wliu)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 56:  //1.10.4
		{
			DrawPanelText(panel, "11) [Server] Fixed 'ff2_alive' never being shown (Wliu from various)");
			DrawPanelText(panel, "12) [Server] Fixed invalid healthbar errors (Wliu from ClassicGuzzi)");
			DrawPanelText(panel, "13) [Server] Fixed OnTakeDamage errors from spell Monoculuses (Wliu from ClassicGuzzi)");
			DrawPanelText(panel, "14) [Server] Added 'ff2_arena_rounds' and deprecated 'ff2_first_round' (Wliu from Spyper)");
			DrawPanelText(panel, "15) [Server] Added 'ff2_base_jumper_stun' to disable the parachute on stun (Wliu from Shadow)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 55:  //1.10.4
		{
			DrawPanelText(panel, "16) [Server] Prevented FF2 from loading if it gets loaded in the /plugins/freaks/ directory (Wliu)");
			DrawPanelText(panel, "17) [Dev] Fixed 'sound_fail' (Wliu from M76030)");
			DrawPanelText(panel, "18) [Dev] Allowed companions to emit 'sound_nextlife' if they have it (Wliu from M76030)");
			DrawPanelText(panel, "19) [Dev] Added 'sound_last_life' (Wliu from WildCard65)");
			DrawPanelText(panel, "20) [Dev] Added FF2_OnAlivePlayersChanged and deprecated FF2_Get{Alive|Boss}Players (Wliu from Shadow)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 54:  //1.10.4
		{
			DrawPanelText(panel, "21) [Dev] Fixed AIOOB errors in FF2_GetBossUserId (Wliu)");
			DrawPanelText(panel, "22) [Dev] Improved FF2_OnSpecialSelected so that only part of a boss name is needed (Wliu)");
			DrawPanelText(panel, "23) [Dev] Added FF2_{Get|Set}BossRageDamage (Wliu from WildCard65)");
		}
		case 53:  //1.10.3
		{
			DrawPanelText(panel, "1) Fixed bosses appearing to be overhealed (War3Evo/Wliu)");
			DrawPanelText(panel, "2) Rebalanced many weapons based on misc. feedback (Wliu/various)");
			DrawPanelText(panel, "3) Fixed not being able to use strange syringe guns or mediguns (Chris from Spyper)");
			DrawPanelText(panel, "4) Fixed the Bread Bite being replaced by the GRU (Wliu from Spyper)");
			DrawPanelText(panel, "5) Fixed Mantreads not giving extra rocket jump height (Chdata");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 52:  //1.10.3
		{
			DrawPanelText(panel, "6) Prevented bosses from picking up ammo/health by default (friagram)");
			DrawPanelText(panel, "7) Fixed a bug with respawning bosses (Wliu from Spyper)");
			DrawPanelText(panel, "8) Fixed an issue with displaying boss health in chat (Wliu)");
			DrawPanelText(panel, "9) Fixed an edge case where player crits would not be applied (Wliu from Spyper)");
			DrawPanelText(panel, "10) Fixed not being able to suicide as boss after round end (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 51:  //1.10.3
		{
			DrawPanelText(panel, "11) Updated Russian translations (wasder) and added German translations (CooliMC)");
			DrawPanelText(panel, "12) Fixed Dead Ringer deaths being too obvious (Wliu from AliceTaylor12)");
			DrawPanelText(panel, "13) Fixed many bosses not voicing their catch phrases (Wliu)");
			DrawPanelText(panel, "14) Updated Gentlespy, Easter Bunny, Demopan, and CBS (Wliu, configs need to be updated)");
			DrawPanelText(panel, "15) [Server] Added new cvar 'ff2_countdown_result' (Wliu from Shadow)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 50:  //1.10.3
		{
			DrawPanelText(panel, "16) [Server] Added new cvar 'ff2_caber_detonations' (Wliu)");
			DrawPanelText(panel, "17) [Server] Fixed a bug related to 'cvar_countdown_players' and the countdown timer (Wliu from Spyper)");
			DrawPanelText(panel, "18) [Server] Fixed 'nextmap_charset' VFormat errors (Wliu from BBG_Theory)");
			DrawPanelText(panel, "19) [Server] Fixed errors when Monoculus was attacking (Wliu from ClassicGuzzi)");
			DrawPanelText(panel, "20) [Dev] Added 'sound_first_blood' (Wliu from Mr-Bro)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 49:  //1.10.3
		{
			DrawPanelText(panel, "21) [Dev] Added 'pickups' to set what the boss can pick up (Wliu)");
			DrawPanelText(panel, "22) [Dev] Added FF2FLAG_ALLOW_{HEALTH|AMMO}_PICKUPS (Powerlord)");
			DrawPanelText(panel, "23) [Dev] Added FF2_GetFF2Version (Wliu)");
			DrawPanelText(panel, "24) [Dev] Added FF2_ShowSync{Hud}Text wrappers (Wliu)");
			DrawPanelText(panel, "25) [Dev] Added FF2_SetAmmo and fixed setting clip (Wliu/friagram for fixing clip)");
			DrawPanelText(panel, "26) [Dev] Fixed weapons not being hidden when asked to (friagram)");
			DrawPanelText(panel, "27) [Dev] Fixed not being able to set constant health values for bosses (Wliu from braak0405)");
		}
		case 48:  //1.10.2
		{
			DrawPanelText(panel, "1) Fixed a critical bug that rendered most bosses as errors without sound (Wliu; thanks to slavko17 for reporting)");
			DrawPanelText(panel, "2) Reverted escape sequences change, which is what caused this bug");
		}
		case 47:  //1.10.1
		{
			DrawPanelText(panel, "1) Fixed a rare bug where rage could go over 100% (Wliu)");
			DrawPanelText(panel, "2) Updated to use Sourcemod 1.6.1 (Powerlord)");
			DrawPanelText(panel, "3) Fixed goomba stomp ignoring demoshields (Wliu)");
			DrawPanelText(panel, "4) Disabled boss from spectating (Wliu)");
			DrawPanelText(panel, "5) Fixed some possible overlapping HUD text (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 46:  //1.10.1
		{
			DrawPanelText(panel, "6) Fixed ff2_charset displaying incorrect colors (Wliu)");
			DrawPanelText(panel, "7) Boss info text now also displays in the chat area (Wliu)");
			DrawPanelText(panel, "--Partially synced with VSH 1.49 (all VSH changes listed courtesy of Chdata)--");
			DrawPanelText(panel, "8) VSH: Do not show HUD text if the scoreboard is open");
			DrawPanelText(panel, "9) VSH: Added market gardener 'backstab'");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 45:  //1.10.1
		{
			DrawPanelText(panel, "10) VSH: Removed Darwin's Danger Shield from the blacklist (Chdata) and gave it a +50 health bonus (Wliu)");
			DrawPanelText(panel, "11) VSH: Rebalanced Phlogistinator");
			DrawPanelText(panel, "12) VSH: Improved backstab code");
			DrawPanelText(panel, "13) VSH: Added ff2_shield_crits cvar to control whether or not demomen get crits when using shields");
			DrawPanelText(panel, "14) VSH: Reserve Shooter now deals crits to bosses in mid-air");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 44:  //1.10.1
		{
			DrawPanelText(panel, "15) [Server] Fixed conditions still being added when FF2 was disabled (Wliu)");
			DrawPanelText(panel, "16) [Server] Fixed a rare healthbar error (Wliu)");
			DrawPanelText(panel, "17) [Server] Added convar ff2_boss_suicide to control whether or not the boss can suicide after the round starts (Wliu)");
			DrawPanelText(panel, "18) [Server] Changed ff2_boss_teleporter's default value to 0 (Wliu)");
			DrawPanelText(panel, "19) [Server] Updated translations (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 43:  //1.10.1
		{
			DrawPanelText(panel, "20) [Dev] Added FF2_GetAlivePlayers and FF2_GetBossPlayers (Wliu/AliceTaylor)");
			DrawPanelText(panel, "21) [Dev] Fixed a bug in the main include file (Wliu)");
			DrawPanelText(panel, "22) [Dev] Enabled escape sequences in configs (Wliu)");
		}
		case 42:  //1.10.0
		{
			DrawPanelText(panel, "1) Rage is now activated by calling for medic (Wliu)");
			DrawPanelText(panel, "2) Balanced Goomba Stomp and RTD (WildCard65)");
			DrawPanelText(panel, "3) Fixed BGM not stopping if the boss suicides at the beginning of the round (Wliu)");
			DrawPanelText(panel, "4) Fixed Jarate, etc. not disappearing immediately on the boss (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 41:  //1.10.0
		{
			DrawPanelText(panel, "5) Fixed ability timers not resetting when the round was over (Wliu)");
			DrawPanelText(panel, "6) Fixed bosses losing momentum when raging in the air (Wliu)");
			DrawPanelText(panel, "7) Fixed bosses losing health if their companion left at round start (Wliu)");
			DrawPanelText(panel, "8) Fixed bosses sometimes teleporting to each other if they had a companion (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 40:  //1.10.0
		{
			DrawPanelText(panel, "9) Optimized the health calculation system (WildCard65)");
			DrawPanelText(panel, "10) Slightly tweaked default boss health formula to be more balanced (Eggman)");
			DrawPanelText(panel, "11) Fixed and optimized the leaderboard (Wliu)");
			DrawPanelText(panel, "12) Fixed medic minions receiving the medigun (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 39:  //1.10.0
		{
			DrawPanelText(panel, "13) Fixed Ninja Spy slow-mo bugs (Wliu/Powerlord)");
			DrawPanelText(panel, "14) Prevented players from changing to the incorrect team or class (Powerlord/Wliu)");
			DrawPanelText(panel, "15) Fixed bosses immediately dying after using the dead ringer (Wliu)");
			DrawPanelText(panel, "16) Fixed a rare bug where you could get notified about being the next boss multiple times (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 38:  //1.10.0
		{
			DrawPanelText(panel, "17) Fixed gravity not resetting correctly after a weighdown if using non-standard gravity (Wliu)");
			DrawPanelText(panel, "18) [Server] FF2 now properly disables itself when required (Wliu/Powerlord)");
			DrawPanelText(panel, "19) [Server] Added ammo, clip, and health arguments to rage_cloneattack (Wliu)");
			DrawPanelText(panel, "20) [Server] Changed how BossCrits works...again (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 37:  //1.10.0
		{
			DrawPanelText(panel, "21) [Server] Removed convar ff2_halloween (Wliu)");
			DrawPanelText(panel, "22) [Server] Moved convar ff2_oldjump to the main config file (Wliu)");
			DrawPanelText(panel, "23) [Server] Added convar ff2_countdown_players to control when the timer should appear (Wliu/BBG_Theory)");
			DrawPanelText(panel, "24) [Server] Added convar ff2_updater to control whether automatic updating should be turned on (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 36:  //1.10.0
		{
			DrawPanelText(panel, "25) [Server] Added convar ff2_goomba_jump to control how high players should rebound after goomba stomping the boss (WildCard65)");
			DrawPanelText(panel, "26) [Server] Fixed hale_point_enable/disable being registered twice (Wliu)");
			DrawPanelText(panel, "27) [Server] Fixed some convars not executing (Wliu)");
			DrawPanelText(panel, "28) [Server] Fixed the chances and charset systems (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 35:  //1.10.0
		{
			DrawPanelText(panel, "29) [Dev] Added more natives and one additional forward (Eggman)");
			DrawPanelText(panel, "30) [Dev] Added sound_full_rage which plays once the boss is able to rage (Wliu/Eggman)");
			DrawPanelText(panel, "31) [Dev] Fixed FF2FLAG_ISBUFFED (Wliu)");
			DrawPanelText(panel, "32) [Dev] FF2 now checks for sane values for \"lives\" and \"health_formula\" (Wliu)");
			DrawPanelText(panel, "Big thanks to GIANT_CRAB, WildCard65, and kniL for their devotion to this release!");
		}
		case 34:  //1.9.3
		{
			DrawPanelText(panel, "1) Fixed a bug in 1.9.2 where the changelog was off by one version (Wliu)");
			DrawPanelText(panel, "2) Fixed a bug in 1.9.2 where one dead player would not be cloned in rage_cloneattack (Wliu)");
			DrawPanelText(panel, "3) Fixed a bug in 1.9.2 where sentries would be permanently disabled after a rage (Wliu)");
			DrawPanelText(panel, "4) [Server] Removed ff2_halloween (Wliu)");
		}
		case 33:  //1.9.2
		{
			DrawPanelText(panel, "1) Fixed a bug in 1.9.1 that allowed the same player to be the boss over and over again (Wliu)");
			DrawPanelText(panel, "2) Fixed a bug where last player glow was being incorrectly removed on the boss (Wliu)");
			DrawPanelText(panel, "3) Fixed a bug where the boss would be assumed dead (Wliu)");
			DrawPanelText(panel, "4) Fixed having minions on the boss team interfering with certain rage calculations (Wliu)");
			DrawPanelText(panel, "See next page for more (press 1)");
		}
		case 32:  //1.9.2
		{
			DrawPanelText(panel, "5) Fixed a rare bug where the rage percentage could go above 100% (Wliu)");
			DrawPanelText(panel, "6) [Server] Fixed possible special_noanims errors (Wliu)");
			DrawPanelText(panel, "7) [Server] Added new arguments to rage_cloneattack-no updates necessary (friagram/Wliu)");
			DrawPanelText(panel, "8) [Server] Certain cvars that SMAC detects are now automatically disabled while FF2 is running (Wliu)");
			DrawPanelText(panel, "            Servers can now safely have smac_cvars enabled");
		}
		case 31:  //1.9.1
		{
			DrawPanelText(panel, "1) Fixed some minor leaderboard bugs and also improved the leaderboard text (Wliu)");
			DrawPanelText(panel, "2) Fixed a minor round end bug (Wliu)");
			DrawPanelText(panel, "3) [Server] Fixed improper unloading of subplugins (WildCard65)");
			DrawPanelText(panel, "4) [Server] Removed leftover console messages (Wliu)");
			DrawPanelText(panel, "5) [Server] Fixed sound not precached warnings (Wliu)");
		}
		case 30:  //1.9.0
		{
			DrawPanelText(panel, "1) Removed checkFirstHale (Wliu)");
			DrawPanelText(panel, "2) [Server] Fixed invalid healthbar entity bug (Wliu)");
			DrawPanelText(panel, "3) Changed default medic ubercharge percentage to 40% (Wliu)");
			DrawPanelText(panel, "4) Whitelisted festive variants of weapons (Wliu/BBG_Theory)");
			DrawPanelText(panel, "5) [Server] Added convars to control last player glow and timer health cutoff (Wliu");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 29:  //1.9.0
		{
			DrawPanelText(panel, "6) [Dev] Added new natives/stocks: Debug, FF2_SetClientGlow and FF2_GetClientGlow (Wliu)");
			DrawPanelText(panel, "7) Fixed a few minor !whatsnew bugs (BBG_Theory)");
			DrawPanelText(panel, "8) Fixed Easter Abilities (Wliu)");
			DrawPanelText(panel, "9) Minor grammar/spelling improvements (Wliu)");
			DrawPanelText(panel, "10) [Server] Minor subplugin load/unload fixes (Wliu)");
		}
		case 28:  //1.0.8
		{
			DrawPanelText(panel, "Wliu, Chris, Lawd, and Carge of 50DKP have taken over FF2 development");
			DrawPanelText(panel, "1) Prevented spy bosses from changing disguises (Powerlord)");
			DrawPanelText(panel, "2) Added Saxton Hale stab sounds (Powerlord/AeroAcrobat)");
			DrawPanelText(panel, "3) Made sure that the boss doesn't have any invalid weapons/items (Powerlord)");
			DrawPanelText(panel, "4) Tried fixing the visible weapon bug (Powerlord)");
			DrawPanelText(panel, "5) Whitelisted some more action slot items (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 27:  //1.0.8
		{
			DrawPanelText(panel, "6) Festive Huntsman has the same attributes as the Huntsman now (Powerlord)");
			DrawPanelText(panel, "7) Medigun now overheals 50% more (Powerlord)");
			DrawPanelText(panel, "8) Made medigun transparent if the medic's melee was the Gunslinger (Powerlord)");
			DrawPanelText(panel, "9) Slight tweaks to the view hp commands (Powerlord)");
			DrawPanelText(panel, "10) Whitelisted the Silver/Gold Botkiller Sniper Rifle Mk.II (Powerlord)");
			DrawPanelText(panel, "11) Slight tweaks to boss health calculation (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 26:  //1.0.8
		{
			DrawPanelText(panel, "12) Made sure that spies couldn't quick-backstab the boss (Powerlord)");
			DrawPanelText(panel, "13) Made sure the stab animations were correct (Powerlord)");
			DrawPanelText(panel, "14) Made sure that healthpacks spawned from the Candy Cane are not respawned once someone uses them (Powerlord)");
			DrawPanelText(panel, "15) Healthpacks from the Candy Cane are no longer despawned (Powerlord)");
			DrawPanelText(panel, "16) Slight tweaks to removing laughs (Powerlord)");
			DrawPanelText(panel, "17) [Dev] Added a clip argument to special_noanims.sp (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 25:  //1.0.8
		{
			DrawPanelText(panel, "18) [Dev] sound_bgm is now precached automagically (Powerlord)");
			DrawPanelText(panel, "19) Seeldier's minions can no longer cap (Wliu)");
			DrawPanelText(panel, "20) Fixed sometimes getting stuck when teleporting to a ducking player (Powerlord)");
			DrawPanelText(panel, "21) Multiple English translation improvements (Wliu/Powerlord)");
			DrawPanelText(panel, "22) Fixed Ninja Spy and other bosses that use the matrix ability getting stuck in walls/ceilings (Chris)");
			DrawPanelText(panel, "23) [Dev] Updated item attributes code per the TF2Items update (Powerlord)");
			DrawPanelText(panel, "See next page (press 1)");
		}
		case 24:  //1.0.8
		{
			DrawPanelText(panel, "24) Fixed duplicate sound downloads for Saxton Hale (Wliu)");
			DrawPanelText(panel, "25) [Server] FF2 now require morecolors, not colors (Powerlord)");
			DrawPanelText(panel, "26) [Server] Added a Halloween mode which will enable characters_halloween.cfg (Wliu)");
			DrawPanelText(panel, "27) Hopefully fixed multiple round-related issues (Wliu)");
			DrawPanelText(panel, "28) [Dev] Started to clean up/format the code (Wliu)");
			DrawPanelText(panel, "29) Changed versioning format to x.y.z and month day, year (Wliu)");
			DrawPanelText(panel, "HAPPY HALLOWEEN!");
		}
		case 23:  //1.07
		{
			DrawPanelText(panel, "1) [Players] Holiday Punch is now replaced by Fists");
			DrawPanelText(panel, "2) [Players] Bosses will have any disguises removed on round start");
			DrawPanelText(panel, "3) [Players] Bosses can no longer see all players health, as it wasn't working any more");
			DrawPanelText(panel, "4) [Server] ff2_addpoints no longer targets SourceTV or replay");
		}
		case 22:  //1.07 beta 6
		{
			DrawPanelText(panel, "1) [Dev] Fixed issue with sound hook not stopping sound when sound_block_vo was in use");
			DrawPanelText(panel, "2) [Dev] If ff2_charset was used, don't run the character set vote");
			DrawPanelText(panel, "3) [Dev] If a vote is already running, Character set vote will retry every 5 seconds or until map changes ");
		}
		case 21:  //1.07 beta 5
		{
			DrawPanelText(panel, "1) [Dev] Fixed issue with character sets not working.");
			DrawPanelText(panel, "2) [Dev] Improved IsValidClient replay check");
			DrawPanelText(panel, "3) [Dev] IsValidClient is now called when loading companion bosses");
			DrawPanelText(panel, "   This should prevent GetEntProp issues with m_iClass");
		}
		case 20:  //1.07 beta 4
		{
			DrawPanelText(panel, "1) [Players] Dead Ringers have no cloak defense buff. Normal cloaks do.");
			DrawPanelText(panel, "2) [Players] Fixed Sniper Rifle reskin behavior");
			DrawPanelText(panel, "3) [Players] Boss has small amount of stun resistance after rage");
			DrawPanelText(panel, "4) [Players] Various bugfixes and changes 1.7.0 beta 1");
		}
		case 19:  //1.07 beta
		{
			DrawPanelText(panel, "22) [Dev] Prevent boss rage from being activated if the boss is already taunting or is dead.");
			DrawPanelText(panel, "23) [Dev] Cache the result of the newer backstab detection");
			DrawPanelText(panel, "24) [Dev] Reworked Medic damage code slightly");
		}
		case 18:  //1.07 beta
		{
			DrawPanelText(panel, "16) [Server] The Boss queue now accepts negative points.");
			DrawPanelText(panel, "17) [Server] Bosses can be forced to a specific team using the new ff2_force_team cvar.");
			DrawPanelText(panel, "18) [Server] Eureka Effect can now be enabled using the new ff2_enable_eureka cvar");
			DrawPanelText(panel, "19) [Server] Bosses models and sounds are now precached the first time they are loaded.");
			DrawPanelText(panel, "20) [Dev] Fixed an issue where FF2 was trying to read cvars before config files were executed.");
			DrawPanelText(panel, "    This change should also make the game a little more multi-mod friendly.");
			DrawPanelText(panel, "21) [Dev] Fixed OnLoadCharacterSet not being fired. This should fix the deadrun plugin.");
			DrawPanelText(panel, "Continued on next page");
		}
		case 17:  //1.07 beta
		{
			DrawPanelText(panel, "10) [Players] Heatmaker gains Focus on hit (varies by charge)");
			DrawPanelText(panel, "11) [Players] Crusader's Crossbow damage has been adjusted to compensate for its speed increase.");
			DrawPanelText(panel, "12) [Players] Cozy Camper now gives you an SMG as well, but it has no crits and reduced damage.");
			DrawPanelText(panel, "13) [Players] Bosses get short defense buff after rage");
			DrawPanelText(panel, "14) [Server] Now attempts to integrate tf2items config");
			DrawPanelText(panel, "15) [Server] Changing the game description now requires Steam Tools");
			DrawPanelText(panel, "Continued on next page");
		}
		case 16:  //1.07 beta
		{
			DrawPanelText(panel, "6) [Players] Removed crits from sniper rifles, now do 2.9x damage");
			DrawPanelText(panel, "   Sydney Sleeper does 2.4x damage, 2.9x if boss's rage is >90pct");
			DrawPanelText(panel, "   Minicrit- less damage, more knockback");
			DrawPanelText(panel, "7) [Players] Baby Face's Blaster will fill boost normally, but will hit 100 and drain+minicrits.");
			DrawPanelText(panel, "8) [Players] Phlogistinator Pyros are invincible while activating the crit-boost taunt.");
			DrawPanelText(panel, "9) [Players] Can't Eureka+destroy dispenser to insta-teleport");
			DrawPanelText(panel, "Continued on next page");
		}
		case 15:  //1.07 beta
		{
			DrawPanelText(panel, "1) [Players] Reworked the crit code a bit. Should be more reliable.");
			DrawPanelText(panel, "2) [Players] Help panel should stop repeatedly popping up on round start.");
			DrawPanelText(panel, "3) [Players] Backstab disguising should be smoother/less obvious");
			DrawPanelText(panel, "4) [Players] Scaled sniper rifle glow time a bit better");
			DrawPanelText(panel, "5) [Players] Fixed Dead Ringer spy death icon");
			DrawPanelText(panel, "Continued on next page");
		}
		case 14:  //1.06h
		{
			DrawPanelText(panel, "1) [Players] Remove MvM powerup_bottle on Bosses. (RavensBro)");
		}
		case 13:  //1.06g
		{
			DrawPanelText(panel, "1) [Players] Fixed vote for charset. (RavensBro)");
		}
		case 12:  //1.06f
		{
			DrawPanelText(panel, "1) [Players] Changelog now divided into [Players] and [Dev] sections. (Otokiru)");
			DrawPanelText(panel, "2) [Players] Don't bother reading [Dev] changelogs because you'll have no idea what it's stated. (Otokiru)");
			DrawPanelText(panel, "3) [Players] Fixed civilian glitch. (Otokiru)");
			DrawPanelText(panel, "4) [Players] Fixed hale HP bar. (Valve) lol?");
			DrawPanelText(panel, "5) [Dev] Fixed \"GetEntProp\" reported: Entity XXX (XXX) is invalid on checkFirstHale(). (Otokiru)");
		}
		case 11:  //1.06e
		{

			DrawPanelText(panel, "1) [Players] Remove MvM water-bottle on hales. (Otokiru)");
			DrawPanelText(panel, "2) [Dev] Fixed \"GetEntProp\" reported: Property \"m_iClass\" not found (entity 0/worldspawn) error on checkFirstHale(). (Otokiru)");
			DrawPanelText(panel, "3) [Dev] Change how FF2 check for player weapons. Now also checks when spawned in the middle of the round. (Otokiru)");
			DrawPanelText(panel, "4) [Dev] Changed some FF2 warning messages color such as \"First-Hale Checker\" and \"Change class exploit\". (Otokiru)");
		}
		case 10:  //1.06d
		{
			DrawPanelText(panel, "1) Fix first boss having missing health or abilities. (Otokiru)");
			DrawPanelText(panel, "2) Health bar now goes away if the boss wins the round. (Powerlord)");
			DrawPanelText(panel, "3) Health bar cedes control to Monoculus if he is summoned. (Powerlord)");
			DrawPanelText(panel, "4) Health bar instantly updates if enabled or disabled via cvar mid-game. (Powerlord)");
		}
		case 9:  //1.06c
		{
			DrawPanelText(panel, "1) Remove weapons if a player tries to switch classes when they become boss to prevent an exploit. (Otokiru)");
			DrawPanelText(panel, "2) Reset hale's queue points to prevent the 'retry' exploit. (Otokiru)");
			DrawPanelText(panel, "3) Better detection of backstabs. (Powerlord)");
			DrawPanelText(panel, "4) Boss now has optional life meter on screen. (Powerlord)");
		}
		case 8:  //1.06
		{
			DrawPanelText(panel, "1) Fixed attributes key for weaponN block. Now 1 space needed for explode string.");
			DrawPanelText(panel, "2) Disabled vote for charset when there is only 1 not hidden chatset.");
			DrawPanelText(panel, "3) Fixed \"Invalid key value handle 0 (error 4)\" when when round starts.");
			DrawPanelText(panel, "4) Fixed ammo for special_noanims.ff2\\rage_new_weapon ability.");
			DrawPanelText(panel, "Coming soon: weapon balance will be moved into config file.");
		}
		case 7:  //1.05
		{
			DrawPanelText(panel, "1) Added \"hidden\" key for charsets.");
			DrawPanelText(panel, "2) Added \"sound_stabbed\" key for characters.");
			DrawPanelText(panel, "3) Mantread stomp deals 5x damage to Boss.");
			DrawPanelText(panel, "4) Minicrits will not play loud sound to all players");
			DrawPanelText(panel, "5-11) See next page...");
		}
		case 6:  //1.05
		{
			DrawPanelText(panel, "6) For mappers: Add info_target with name 'hale_no_music'");
			DrawPanelText(panel, "    to prevent Boss' music.");
			DrawPanelText(panel, "7) FF2 renames *.smx from plugins/freaks/ to *.ff2 by itself.");
			DrawPanelText(panel, "8) Third Degree hit adds uber to healers.");
			DrawPanelText(panel, "9) Fixed hard \"ghost_appearation\" in default_abilities.ff2.");
			DrawPanelText(panel, "10) FF2FLAG_HUDDISABLED flag blocks EVERYTHING of FF2's HUD.");
			DrawPanelText(panel, "11) Changed FF2_PreAbility native to fix bug about broken Boss' abilities.");
		}
		case 5:  //1.04
		{
			DrawPanelText(panel, "1) Seeldier's minions have protection (teleport) from pits for first 4 seconds after spawn.");
			DrawPanelText(panel, "2) Seeldier's minions correctly dies when owner-Seeldier dies.");
			DrawPanelText(panel, "3) Added multiplier for brave jump ability in char.configs (arg3, default is 1.0).");
			DrawPanelText(panel, "4) Added config key sound_fail. It calls when Boss fails, but still alive");
			DrawPanelText(panel, "4) Fixed potential exploits associated with feign death.");
			DrawPanelText(panel, "6) Added ff2_reload_subplugins command to reload FF2's subplugins.");
		}
		case 4:  //1.03
		{
			DrawPanelText(panel, "1) Finally fixed exploit about queue points.");
			DrawPanelText(panel, "2) Fixed non-regular bug with 'UTIL_SetModel: not precached'.");
			DrawPanelText(panel, "3) Fixed potential bug about reducing of Boss' health by healing.");
			DrawPanelText(panel, "4) Fixed Boss' stun when round begins.");
		}
		case 3:  //1.02
		{
			DrawPanelText(panel, "1) Added isNumOfSpecial parameter into FF2_GetSpecialKV and FF2_GetBossSpecial natives");
			DrawPanelText(panel, "2) Added FF2_PreAbility forward. Plz use it to prevent FF2_OnAbility only.");
			DrawPanelText(panel, "3) Added FF2_DoAbility native.");
			DrawPanelText(panel, "4) Fixed exploit about queue points...ow wait, it done in 1.01");
			DrawPanelText(panel, "5) ff2_1st_set_abilities.ff2 sets kac_enabled to 0.");
			DrawPanelText(panel, "6) FF2FLAG_HUDDISABLED flag disables Boss' HUD too.");
			DrawPanelText(panel, "7) Added FF2_GetQueuePoints and FF2_SetQueuePoints natives.");
		}
		case 2:  //1.01
		{
			DrawPanelText(panel, "1) Fixed \"classmix\" bug associated with Boss' class restoring.");
			DrawPanelText(panel, "3) Fixed other little bugs.");
			DrawPanelText(panel, "4) Fixed bug about instant kill of Seeldier's minions.");
			DrawPanelText(panel, "5) Now you can use name of Boss' file for \"companion\" Boss' keyvalue.");
			DrawPanelText(panel, "6) Fixed exploit when dead Boss can been respawned after his reconnect.");
			DrawPanelText(panel, "7-10) See next page...");
		}
		case 1:  //1.01
		{
			DrawPanelText(panel, "7) I've missed 2nd item.");
			DrawPanelText(panel, "8) Fixed \"Random\" charpack, there is no vote if only one charpack.");
			DrawPanelText(panel, "9) Fixed bug when boss' music have a chance to DON'T play.");
			DrawPanelText(panel, "10) Fixed bug associated with ff2_enabled in cfg/sourcemod/FreakFortress2.cfg and disabling of pugin.");
		}
		case 0:  //1.0
		{
			DrawPanelText(panel, "1) Boss' health devided by 3,6 in medieval mode");
			DrawPanelText(panel, "2) Restoring player's default class, after his round as Boss");
			DrawPanelText(panel, "===UPDATES OF VS SAXTON HALE MODE===");
			DrawPanelText(panel, "1) Added !ff2_resetqueuepoints command (also there is admin version)");
			DrawPanelText(panel, "2) Medic is credited 100% of damage done during ubercharge");
			DrawPanelText(panel, "3) If map changes mid-round, queue points not lost");
			DrawPanelText(panel, "4) Dead Ringer will not be able to activate for 2s after backstab");
			DrawPanelText(panel, "5) Added ff2_spec_force_boss cvar");
		}
		default:
		{
			DrawPanelText(panel, "-- Somehow you've managed to find a glitched version page!");
			DrawPanelText(panel, "-- Congratulations.  Now go and fight!");
		}
	}
}

static const int maxVersion=sizeof(ff2versiontitles)-1;

int Specials;
Handle BossKV[MAXSPECIALS];
Handle PreAbility;
Handle OnAbility;
Handle OnMusic;
Handle OnTriggerHurt;
Handle OnSpecialSelected;
Handle OnAddQueuePoints;
Handle OnLoadCharacterSet;
Handle OnLoseLife;
Handle OnAlivePlayersChanged;

bool bBlockVoice[MAXSPECIALS];
float BossSpeed[MAXSPECIALS];

char ChancesString[512];
int chances[MAXSPECIALS*2];  //This is multiplied by two because it has to hold both the boss indices and chances
int chancesIndex;

bool LateLoaded;

public Plugin myinfo=
{
	name		=	"Freak Fortress 2",
	author		=	"Many many people",
	description	=	"RUUUUNN!! COWAAAARRDSS!",
	version		=	PLUGIN_VERSION,
	url		=	"https://forums.alliedmods.net/forumdisplay.php?f=154",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freaks/"))  //Prevent plugins/freaks/freak_fortress_2.ff2 from loading if it exists -.-
	{
		strcopy(error, err_max, "There is a duplicate copy of Freak Fortress 2 inside the /plugins/freaks folder.  Please remove it");
		return APLRes_Failure;
	}

	CreateNative("FF2_IsFF2Enabled", Native_IsEnabled);
	CreateNative("FF2_GetFF2Version", Native_FF2Version);
	CreateNative("FF2_IsBossVsBoss", Native_IsVersus);
	CreateNative("FF2_GetForkVersion", Native_ForkVersion);
	CreateNative("FF2_GetBossUserId", Native_GetBoss);
	CreateNative("FF2_GetBossIndex", Native_GetIndex);
	CreateNative("FF2_GetBossTeam", Native_GetTeam);
	CreateNative("FF2_GetBossSpecial", Native_GetSpecial);
	CreateNative("FF2_GetBossName", Native_GetName);
	CreateNative("FF2_GetBossHealth", Native_GetBossHealth);
	CreateNative("FF2_SetBossHealth", Native_SetBossHealth);
	CreateNative("FF2_GetBossMaxHealth", Native_GetBossMaxHealth);
	CreateNative("FF2_SetBossMaxHealth", Native_SetBossMaxHealth);
	CreateNative("FF2_GetBossLives", Native_GetBossLives);
	CreateNative("FF2_SetBossLives", Native_SetBossLives);
	CreateNative("FF2_GetBossMaxLives", Native_GetBossMaxLives);
	CreateNative("FF2_SetBossMaxLives", Native_SetBossMaxLives);
	CreateNative("FF2_GetBossCharge", Native_GetBossCharge);
	CreateNative("FF2_SetBossCharge", Native_SetBossCharge);
	CreateNative("FF2_GetBossRageDamage", Native_GetBossRageDamage);
	CreateNative("FF2_SetBossRageDamage", Native_SetBossRageDamage);
	CreateNative("FF2_GetClientDamage", Native_GetDamage);
	CreateNative("FF2_GetRoundState", Native_GetRoundState);
	CreateNative("FF2_GetSpecialKV", Native_GetSpecialKV);
	CreateNative("FF2_StartMusic", Native_StartMusic);
	CreateNative("FF2_StopMusic", Native_StopMusic);
	CreateNative("FF2_GetRageDist", Native_GetRageDist);
	CreateNative("FF2_HasAbility", Native_HasAbility);
	CreateNative("FF2_DoAbility", Native_DoAbility);
	CreateNative("FF2_GetAbilityArgument", Native_GetAbilityArgument);
	CreateNative("FF2_GetAbilityArgumentFloat", Native_GetAbilityArgumentFloat);
	CreateNative("FF2_GetAbilityArgumentString", Native_GetAbilityArgumentString);
	CreateNative("FF2_RandomSound", Native_RandomSound);
	CreateNative("FF2_EmitVoiceToAll", Native_EmitVoiceToAll);
	CreateNative("FF2_GetFF2flags", Native_GetFF2flags);
	CreateNative("FF2_SetFF2flags", Native_SetFF2flags);
	CreateNative("FF2_GetQueuePoints", Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", Native_SetQueuePoints);
	CreateNative("FF2_GetClientGlow", Native_GetClientGlow);
	CreateNative("FF2_SetClientGlow", Native_SetClientGlow);
	CreateNative("FF2_GetClientShield", Native_GetClientShield);
	CreateNative("FF2_SetClientShield", Native_SetClientShield);
	CreateNative("FF2_RemoveClientShield", Native_RemoveClientShield);
	CreateNative("FF2_LogError", Native_LogError);
	CreateNative("FF2_Debug", Native_Debug);
	CreateNative("FF2_SetCheats", Native_SetCheats);
	CreateNative("FF2_GetCheats", Native_GetCheats);

	PreAbility = CreateGlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);  //Boss, plugin name, ability name, slot, enabled
	OnAbility = CreateGlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);  //Boss, plugin name, ability name, status
	OnMusic = CreateGlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
	OnTriggerHurt = CreateGlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	OnSpecialSelected = CreateGlobalForward("FF2_OnSpecialSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell);  //Boss, character index, character name, preset
	OnAddQueuePoints = CreateGlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	OnLoadCharacterSet = CreateGlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_CellByRef, Param_String);
	OnLoseLife = CreateGlobalForward("FF2_OnLoseLife", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);  //Boss, lives left, max lives
	OnAlivePlayersChanged = CreateGlobalForward("FF2_OnAlivePlayersChanged", ET_Hook, Param_Cell, Param_Cell);  //Players, bosses

	RegPluginLibrary("freak_fortress_2");

	AskPluginLoad_VSH();
	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif

	#if defined _tf2attributes_included
	MarkNativeAsOptional("TF2Attrib_SetByDefIndex");
	MarkNativeAsOptional("TF2Attrib_RemoveByDefIndex");
	#endif

	LateLoaded = late;
	return APLRes_Success;
}

// Boss Selection
char xIncoming[MAXPLAYERS+1][700];
char cIncoming[MAXPLAYERS+1][700];
int CanBossVs[MAXPLAYERS+1];
int CanBossTeam[MAXPLAYERS+1];

// Boss Toggle
enum SettingPrefs
{
	Setting_Undef = 0,
	Setting_On,
	Setting_Off,
	Setting_Temp
};

Handle LastPlayedCookie = INVALID_HANDLE;
Handle SelectionCookie = INVALID_HANDLE;

ClientPoint[MAXPLAYERS+1];
ClientID[MAXPLAYERS+1];
ClientQueue[MAXPLAYERS+1][2];
bool InfiniteRageActive[MAXPLAYERS+1]=false;

// Boss Log
char bLog[PLATFORM_MAX_PATH];
char eLog[PLATFORM_MAX_PATH];
char pLog[PLATFORM_MAX_PATH];

// Preferences
int QueuePoints[MAXPLAYERS+1];
bool ToggleMusic[MAXPLAYERS+1];	// TODO: Disable temp for round?
bool ToggleVoice[MAXPLAYERS+1];
bool ToggleInfo[MAXPLAYERS+1];
SettingPrefs ToggleDuo[MAXPLAYERS+1];
SettingPrefs ToggleBoss[MAXPLAYERS+1];

// Stat Tracker
int BossWins[MAXPLAYERS+1];
int BossLosses[MAXPLAYERS+1];
int BossKills[MAXPLAYERS+1];
int BossKillsF[MAXPLAYERS+1];
int BossDeaths[MAXPLAYERS+1];
int PlayerKills[MAXPLAYERS+1];
int PlayerMVPs[MAXPLAYERS+1];

public void OnPluginStart()
{
	LogMessage("===Freak Fortress 2 Initializing-%s===", BUILD_NUMBER);

	// Logs
	BuildPath(Path_SM, pLog, sizeof(pLog), BossLogPath);
	if(!DirExists(pLog))
	{
		CreateDirectory(pLog, 511);

		if(!DirExists(pLog))
			LogError("Failed to create directory at %s", pLog);
	}

	BuildPath(Path_SM, eLog, sizeof(eLog), "%s/%s", LogPath, ErrorLog);
	if(!FileExists(eLog))
		OpenFile(eLog, "a+");

	cvarVersion = CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarPointType = CreateConVar("ff2_point_type", "0", "0-Use ff2_point_alive, 1-Use ff2_point_time, 2-Use both", _, true, 0.0, true, 2.0);
	cvarPointDelay = CreateConVar("ff2_point_delay", "6", "Seconds to add to ff2_point_time per player");
	cvarPointTime = CreateConVar("ff2_point_time", "45", "Time before unlocking the control point");
	cvarAliveToEnable = CreateConVar("ff2_point_alive", "0.2", "The control point will only activate when there are this many people or less left alive, can be a ratio", _, true, 0.0, true, 34.0);
	cvarAnnounce = CreateConVar("ff2_announce", "120", "Amount of seconds to wait until FF2 info is displayed again.  0 to disable", _, true, 0.0);
	cvarEnabled = CreateConVar("ff2_enabled", "1", "0-Force Disable, 1-Standby, 2-Force Enable", FCVAR_DONTRECORD, true, 0.0, true, 2.0);
	cvarCrits = CreateConVar("ff2_crits", "0", "Can the boss get random crits?", _, true, 0.0, true, 1.0);
	cvarArenaRounds = CreateConVar("ff2_arena_rounds", "1", "Number of rounds to make arena before switching to FF2 (helps for slow-loading players)", _, true, 0.0);
	cvarCircuitStun = CreateConVar("ff2_circuit_stun", "0", "Amount of seconds the Short Circuit stuns the boss for.  0 to disable", _, true, 0.0);
	cvarCountdownPlayers = CreateConVar("ff2_countdown_players", "1", "Amount of players until the countdown timer starts, can be a ratio", _, true, 0.0, true, 34.0);
	cvarCountdownTime = CreateConVar("ff2_countdown", "120", "Amount of seconds until the round ends in a stalemate");
	cvarCountdownHealth = CreateConVar("ff2_countdown_health", "2000", "Amount of health the Boss has remaining until the countdown stops", _, true, 0.0);
	cvarCountdownResult = CreateConVar("ff2_countdown_result", "0", "0-Kill players when the countdown ends, 1-End the round in a stalemate", _, true, 0.0, true, 1.0);
	cvarSpecForceBoss = CreateConVar("ff2_spec_force_boss", "0", "0-Spectators are excluded from the queue system, 1-Spectators are counted in the queue system", _, true, 0.0, true, 1.0);
	cvarEnableEurekaEffect = CreateConVar("ff2_enable_eureka", "0", "0-Disable the Eureka Effect, 1-Enable the Eureka Effect", _, true, 0.0, true, 1.0);
	cvarForceBossTeam = CreateConVar("ff2_force_team", "0", "0-Boss is always on Blu, 1-Boss is on a random team each round, 2-Boss is always on Red", _, true, 0.0, true, 3.0);
	cvarHealthBar = CreateConVar("ff2_health_bar", "1", "0-Disable the health bar, 1-Show the health bar without lives, 2-Show the health bar with lives", _, true, 0.0, true, 2.0);
	cvarLastPlayerGlow = CreateConVar("ff2_last_player_glow", "1", "How many players left before outlining everyone, can be a ratio", _, true, 0.0, true, 34.0);
	cvarBossTeleporter = CreateConVar("ff2_boss_teleporter", "0", "-1 to disallow all bosses from using teleporters, 0 to use TF2 logic, 1 to allow all bosses", _, true, -1.0, true, 1.0);
	cvarBossSuicide = CreateConVar("ff2_boss_suicide", "0", "Allow the boss to suicide after the round starts?", _, true, 0.0, true, 1.0);
	cvarPreroundBossDisconnect = CreateConVar("ff2_replace_disconnected_boss", "0", "If a boss disconnects before the round starts, use the next player in line instead? 0 - No, 1 - Yes", _, true, 0.0, true, 1.0);
	cvarCaberDetonations = CreateConVar("ff2_caber_detonations", "1", "Amount of times somebody can detonate the Ullapool Caber", _, true, 1.0);
	cvarShieldCrits = CreateConVar("ff2_shield_crits", "0", "0 to disable grenade launcher crits when equipping a shield, 1 for minicrits, 2 for crits", _, true, 0.0, true, 2.0);
	cvarGoombaDamage = CreateConVar("ff2_goomba_damage", "0.05", "How much the Goomba damage should be multipled by when goomba stomping the boss (requires Goomba Stomp)", _, true, 0.01, true, 1.0);
	cvarGoombaRebound = CreateConVar("ff2_goomba_jump", "300.0", "How high players should rebound after goomba stomping the boss (requires Goomba Stomp)", _, true, 0.0);
	cvarBossRTD = CreateConVar("ff2_boss_rtd", "0", "Can the boss use rtd? 0 to disallow boss, 1 to allow boss (requires RTD)", _, true, 0.0, true, 1.0);
	cvarDeadRingerHud = CreateConVar("ff2_deadringer_hud", "1", "Dead Ringer indicator? 0 to disable, 1 to enable", _, true, 0.0, true, 1.0);
	cvarDebug = CreateConVar("ff2_debug", "0", "0-Disable FF2 debug output, 1-Enable debugging (not recommended)", _, true, 0.0, true, 1.0);
	cvarDmg2KStreak = CreateConVar("ff2_dmg_kstreak", "250", "Minimum damage to increase killstreak count", _, true, 0.0);
	cvarAirStrike = CreateConVar("ff2_dmg_airstrike", "250", "Minimum damage to increase head count for the Air-Strike", _, true, 0.0);
	cvarSniperDamage = CreateConVar("ff2_sniper_dmg", "2.0", "Sniper Rifle normal multiplier", _, true, 0.0);
	cvarSniperMiniDamage = CreateConVar("ff2_sniper_dmg_mini", "2.0", "Sniper Rifle mini-crit multiplier", _, true, 0.0);
	cvarBowDamage = CreateConVar("ff2_bow_dmg", "1.25", "Huntsman critical multiplier", _, true, 0.0);
	cvarBowDamageNon = CreateConVar("ff2_bow_dmg_non", "0.0", "If not zero Huntsman has no crit boost, Huntsman normal non-crit multiplier", _, true, 0.0);
	cvarBowDamageMini = CreateConVar("ff2_bow_dmg_mini", "0.0", "If not zero Huntsman is mini-crit boosted, Huntsman normal mini-crit multiplier", _, true, 0.0);
	cvarSniperClimbDamage = CreateConVar("ff2_sniper_climb_dmg", "15.0", "Damage taken during climb", _, true, 0.0);
	cvarSniperClimbDelay = CreateConVar("ff2_sniper_climb_delay", "1.56", "0-Disable Climbing, Delay between climbs", _, true, 0.0);
	cvarStrangeWep = CreateConVar("ff2_strangewep", "1", "0-Disable Boss Weapon Stranges, 1-Enable Boss Weapon Stranges", _, true, 0.0, true, 1.0);
	cvarQualityWep = CreateConVar("ff2_qualitywep", "5", "Default Boss Weapon Quality", _, true, 0.0, true, 15.0);
	cvarTripleWep = CreateConVar("ff2_triplewep", "1", "0-Disable Boss Extra Triple Damage, 1-Enable Boss Extra Triple Damage", _, true, 0.0, true, 1.0);
	cvarHardcodeWep = CreateConVar("ff2_hardcodewep", "1", "0-Only Use Config, 1-Use Alongside Hardcoded, 2-Only Use Hardcoded", _, true, 0.0, true, 2.0);
	cvarSelfKnockback = CreateConVar("ff2_selfknockback", "0", "0-Disallow boss self knockback, 1-Allow boss self knockback, 2-Allow boss taking self damage too", _, true, 0.0, true, 2.0);
	cvarFF2TogglePrefDelay = CreateConVar("ff2_boss_toggle_delay", "45.0", "Delay between joining the server and asking the player for their preference, if it is not set.");
	cvarNameChange = CreateConVar("ff2_name_change", "0", "0-Disable, 1-Add the current boss to the server name", _, true, 0.0, true, 1.0);
	cvarKeepBoss = CreateConVar("ff2_boss_keep", "1", "-1-Players can't choose the same boss twice, 0-Nothing, 1-Players keep their current boss selection", _, true, -1.0, true, 1.0);
	cvarSelectBoss = CreateConVar("ff2_boss_select", "1", "0-Disable, 1-Players can select bosses", _, true, 0.0, true, 1.0);
	cvarToggleBoss = CreateConVar("ff2_boss_toggle", "1", "0-Disable, 1-Players can toggle being the boss", _, true, 0.0, true, 1.0);
	cvarDuoBoss = CreateConVar("ff2_boss_companion", "1", "0-Disable, 1-Players can toggle being a companion", _, true, 0.0, true, 1.0);
	cvarPointsInterval = CreateConVar("ff2_points_interval", "600", "Every this damage gives a point", _, true, 1.0);
	cvarPointsDamage = CreateConVar("ff2_points_damage", "0", "Damage required to earn queue points", _, true, 0.0);
	cvarPointsMin = CreateConVar("ff2_points_queue", "10", "Minimum queue points earned", _, true, 0.0);
	cvarPointsExtra = CreateConVar("ff2_points_bonus", "10", "Maximum queue points earned", _, true, 0.0);
	cvarAdvancedMusic = CreateConVar("ff2_advanced_music", "1", "0-Use classic menu, 1-Use new menu", _, true, 0.0, true, 1.0);
	cvarSongInfo = CreateConVar("ff2_song_info", "0", "-1-Never show song and artist in chat, 0-Only if boss has song and artist, 1-Always show song and artist in chat", _, true, -1.0, true, 1.0);
	cvarDuoRandom = CreateConVar("ff2_companion_random", "0", "0-Next player in queue, 1-Random player is the companion", _, true, 0.0, true, 1.0);
	cvarDuoMin = CreateConVar("ff2_companion_min", "4", "Minimum players required to enable duos", _, true, 1.0, true, 34.0);
	cvarDuoRestore = CreateConVar("ff2_companion_restore", "0", "0-Disable, 1-Companions don't lose queue points", _, true, 0.0, true, 1.0);
	cvarLowStab = CreateConVar("ff2_low_stab", "1", "0-Disable, 1-Low-player count stabs, market, and caber do more damage", _, true, 0.0, true, 1.0);
	cvarGameText = CreateConVar("ff2_text_game", "0", "For game messages: 0-Use HUD texts, 1-Use game_text_tf entities, 2-Include boss intro and timer too", _, true, 0.0, true, 2.0);
	cvarAnnotations = CreateConVar("ff2_text_msg", "0", "For backstabs and such: 0-Use hint texts, 1-Use annotations, 2-Use game_text_tf entities", _, true, 0.0, true, 2.0);
	cvarTellName = CreateConVar("ff2_text_names", "1", "For backstabs and such: 0-Don't show player/boss names, 1-Show player/boss names", _, true, 0.0, true, 1.0);
	cvarShieldType = CreateConVar("ff2_shield_type", "1", "0-None, 1-Breaks on any hit, 2-Breaks if it'll kill, 3-Breaks if shield HP is depleted or melee hit, 4-Breaks if shield or player HP is depleted", _, true, 0.0, true, 4.0);
	cvarShieldHealth = CreateConVar("ff2_shield_health", "500", "Maximum amount of health a Shield has if ff2_shield_type is 3 or 4", _, true, 0.0);
	cvarShieldResist = CreateConVar("ff2_shield_resistance", "0.75", "Maximum amount (inverted) precentage of damage resistance a Shield has if ff2_shield_type is 3 or 4", _, true, 0.0, true, 1.0);
	cvarCountdownOvertime = CreateConVar("ff2_countdown_overtime", "0", "0-Disable, 1-Delay 'ff2_countdown_result' action until control point is no longer being captured", _, true, 0.0, true, 1.0);
	cvarBossLog = CreateConVar("ff2_boss_log", "0", "0-Disable, #-Players required to enable logging", _, true, 0.0, true, 34.0);
	cvarBossDesc = CreateConVar("ff2_boss_desc", "1", "0-Disable, 1-Show boss description before selecting a boss", _, true, 0.0, true, 1.0);
	cvarRPSPoints = CreateConVar("ff2_rps_points", "0", "0-Disable, #-Queue points awarded / removed upon RPS", _, true, 0.0);
	cvarRPSLimit = CreateConVar("ff2_rps_limit", "0", "0-Disable, #-Number of times the boss loses before being slayed", _, true, 0.0);
	cvarRPSDivide = CreateConVar("ff2_rps_divide", "0", "0-Disable, 1-Divide current boss health with ff2_rps_limit", _, true, 0.0, true, 1.0);
	cvarHealingHud = CreateConVar("ff2_hud_heal", "0", "0-Disable, 1-Show player's healing in damage HUD with they done healing, 2-Always show", _, true, 0.0, true, 2.0);
	cvarSteamTools = CreateConVar("ff2_steam_tools", "1", "0-Disable, 1-Show 'Freak Fortress 2' in game description (requires SteamTools)", _, true, 0.0, true, 1.0);
	cvarSappers = CreateConVar("ff2_sapper", "0", "0-Disable, 1-Can sap the boss, 2-Can sap minions, 3-Can sap both", _, true, 0.0, true, 3.0);
	cvarSapperCooldown = CreateConVar("ff2_sapper_cooldown", "500", "0-No Cooldown, #-Damage needed to be able to use again", _, true, 0.0);
	cvarSapperStart = CreateConVar("ff2_sapper_starting", "0", "#-Damage needed for first usage (Not used if ff2_sapper or ff2_sapper_cooldown is 0)", _, true, 0.0);
	cvarTheme = CreateConVar("ff2_theme", "0", "0-No Theme, #-Flags of Themes", _, true, 0.0, true, 15.0);
	cvarSelfHealing = CreateConVar("ff2_healing", "0", "0-Block Boss Healing, 1-Allow Self-Healing, 2-Allow Non-Self Healing, 3-Allow All Healing", _, true, 0.0, true, 3.0);
	cvarBotRage = CreateConVar("ff2_bot_rage", "1", "0-Disable, 1-Bots can use rage when ready", _, true, 0.0, true, 1.0);
	cvarDamageToTele = CreateConVar("ff2_tts_damage", "250.0", "Minimum damage boss needs to take in order to be teleported to spawn", _, true, 1.0);
	cvarStatHud = CreateConVar("ff2_hud_stats", "-1", "-1-Disable, 0-Only by ff2_stats_bosses override, 1-Show only to client, 2-Show to anybody", _, true, -1.0, true, 2.0);
	cvarStatPlayers = CreateConVar("ff2_stats_players", "6", "0-Disable, #-Players required to use StatTrak", _, true, 0.0, true, 34.0);
	cvarStatWin2Lose = CreateConVar("ff2_stats_chat", "-1", "-1-Disable, 0-Only by ff2_stats_bosses override, 1-Show only to client if changed, 2-Show to everybody if changed, 3-Show only to client, 4-Show to everybody", _, true, -1.0, true, 4.0);
	cvarHealthHud = CreateConVar("ff2_hud_health", "0", "0-Disable, 1-Show boss's lives left, 2-Show boss's total health", _, true, 0.0, true, 2.0);
	cvarLookHud = CreateConVar("ff2_hud_aiming", "0.0", "-1-No Range Limit, 0-Disable, #-Show teammate's stats by looking at them within this range", _, true, -1.0);
	cvarSkipBoss = CreateConVar("ff2_boss_skip", "0", "0-Disable, 1-Add menu option to skip being a boss", _, true, 0.0, true, 1.0);
	cvarBossVsBoss = CreateConVar("ff2_boss_vs_boss", "0", "0-Always Boss vs Players, #-Chance of Boss vs Boss, 100-Always Boss vs Boss", _, true, 0.0, true, 100.0);
	cvarBvBLose = CreateConVar("ff2_boss_vs_boss_lose", "0", "0-Lose when all of a team die, 1-Lose when all of a team's bosses die, 2-Lose when all the team's mercs die", _, true, 0.0, true, 2.0);
	cvarBvBChaos = CreateConVar("ff2_boss_vs_boss_count", "1", "How many bosses per a team are assigned?", _, true, 1.0, true, 34.0);
	cvarBvBMerc = CreateConVar("ff2_boss_vs_boss_damage", "1.0", "How much to multiply non-boss damage against non-boss while each team as a boss alive", _, true, 0.0);
	cvarBvBStat = CreateConVar("ff2_boss_vs_boss_stats", "0", "Should Boss vs Boss mode count towards StatTrak?", _, true, 0.0, true, 1.0);
	cvarTimesTen = CreateConVar("ff2_times_ten", "5.0", "Amount to multiply boss's health and ragedamage when TF2x10 is enabled", _, true, 0.0);

	//The following are used in various subplugins
	CreateConVar("ff2_oldjump", "1", "Use old Saxton Hale jump equations", _, true, 0.0, true, 1.0);
	CreateConVar("ff2_base_jumper_stun", "0", "Whether or not the Base Jumper should be disabled when a player gets stunned", _, true, 0.0, true, 1.0);
	CreateConVar("ff2_solo_shame", "0", "Always insult the boss for solo raging", _, true, 0.0, true, 1.0);

	HookEvent("teamplay_round_start", OnRoundSetup);
	HookEvent("arena_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("teamplay_broadcast_audio", OnBroadcast, EventHookMode_Pre);
	HookEvent("teamplay_point_startcapture", OnStartCapture);
	HookEvent("teamplay_capture_broken", OnBreakCapture);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_chargedeployed", OnUberDeployed);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("player_healed", OnPlayerHealed, EventHookMode_Pre);
	//HookEvent("player_ignited", OnPlayerIgnited, EventHookMode_Pre);
	HookEvent("object_destroyed", OnObjectDestroyed, EventHookMode_Pre);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Pre);
	HookEvent("deploy_buff_banner", OnDeployBackup);
	HookEvent("rps_taunt_event", OnRPS, EventHookMode_Post);

	OnPluginStart_TeleportToMultiMapSpawn();	// Setup adt_array

	HookUserMessage(GetUserMessageId("PlayerJarated"), OnJarate);	//Used to subtract rage when a boss is jarated (not through Sydney Sleeper)

	AddCommandListener(OnCallForMedic, "voicemenu");	//Used to activate rages
	AddCommandListener(OnSuicide, "explode");		//Used to stop boss from suiciding
	AddCommandListener(OnSuicide, "kill");			//Used to stop boss from suiciding
	AddCommandListener(OnSuicide, "spectate");		//Used to make sure players don't kill themselves and going to spec
	AddCommandListener(OnJoinTeam, "jointeam");		//Used to make sure players join the right team
	AddCommandListener(OnJoinTeam, "autoteam");		//Used to make sure players don't kill themselves and change team
	AddCommandListener(OnChangeClass, "joinclass");		//Used to make sure bosses don't change class

	HookConVarChange(cvarEnabled, CvarChange);
	HookConVarChange(cvarAnnounce, CvarChange);
	HookConVarChange(cvarCircuitStun, CvarChange);
	HookConVarChange(cvarHealthBar, CvarChange);
	HookConVarChange(cvarLastPlayerGlow, CvarChange);
	HookConVarChange(cvarSpecForceBoss, CvarChange);
	HookConVarChange(cvarBossTeleporter, CvarChange);
	HookConVarChange(cvarShieldCrits, CvarChange);
	HookConVarChange(cvarCaberDetonations, CvarChange);
	HookConVarChange(cvarGoombaDamage, CvarChange);
	HookConVarChange(cvarGoombaRebound, CvarChange);
	HookConVarChange(cvarBossRTD, CvarChange);
	HookConVarChange(cvarNextmap=FindConVar("sm_nextmap"), CvarChangeNextmap);
	HookConVarChange(cvarSniperDamage, CvarChange);
	HookConVarChange(cvarSniperMiniDamage, CvarChange);
	HookConVarChange(cvarBowDamage, CvarChange);
	HookConVarChange(cvarBowDamageNon, CvarChange);
	HookConVarChange(cvarBowDamageMini, CvarChange);
	HookConVarChange(cvarSniperClimbDamage, CvarChange);
	HookConVarChange(cvarSniperClimbDelay, CvarChange);
	HookConVarChange(cvarQualityWep, CvarChange);
	HookConVarChange(cvarPointsInterval, CvarChange);
	HookConVarChange(cvarPointsDamage, CvarChange);
	HookConVarChange(cvarPointsMin, CvarChange);
	HookConVarChange(cvarPointsExtra, CvarChange);
	HookConVarChange(cvarDuoMin, CvarChange);
	HookConVarChange(cvarAnnotations, CvarChange);
	HookConVarChange(cvarTellName, CvarChange);
	HookConVarChange(cvarHealthHud, CvarChange);

	RegConsoleCmd("ff2", FF2Panel, "Menu of FF2 commands");
	RegConsoleCmd("ff2_hp", Command_GetHPCmd, "View the boss's current HP");
	RegConsoleCmd("ff2hp", Command_GetHPCmd, "View the boss's current HP");
	RegConsoleCmd("ff2_next", QueuePanelCmd, "View the queue point list");
	RegConsoleCmd("ff2next", QueuePanelCmd, "View the queue point list");
	RegConsoleCmd("ff2_classinfo", Command_HelpPanelClass, "View class or boss info");
	RegConsoleCmd("ff2classinfo", Command_HelpPanelClass, "View class or boss info");
	RegConsoleCmd("ff2_infotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("ff2infotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("ff2_new", NewPanelCmd, "View FF2 changelog");
	RegConsoleCmd("ff2new", NewPanelCmd, "View FF2 changelog");
	RegConsoleCmd("ff2music", MusicTogglePanelCmd, "View the music menu");
	RegConsoleCmd("ff2_music", MusicTogglePanelCmd, "View the music menu");
	RegConsoleCmd("ff2voice", VoiceTogglePanelCmd, "Toggle hearing boss monologues");
	RegConsoleCmd("ff2_voice", VoiceTogglePanelCmd, "Toggle hearing boss monologues");
	RegConsoleCmd("ff2_resetpoints", ResetQueuePointsCmd, "Reset your queue points");
	RegConsoleCmd("ff2resetpoints", ResetQueuePointsCmd, "Reset your queue points");
	RegConsoleCmd("ff2_boss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("ff2boss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("ff2toggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("ff2_toggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("ff2companion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("ff2_companion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("ff2_skipsong", Command_SkipSong, "Skip the current song");
	RegConsoleCmd("ff2skipsong", Command_SkipSong, "Skip the current song");
	RegConsoleCmd("ff2_shufflesong", Command_ShuffleSong, "Play a random song");
	RegConsoleCmd("ff2shufflesong", Command_ShuffleSong, "Play a random song");
	RegConsoleCmd("ff2_tracklist", Command_Tracklist, "View list of songs");
	RegConsoleCmd("ff2tracklist", Command_Tracklist, "View list of songs");

	RegConsoleCmd("hale", FF2Panel, "Menu of FF2 commands");
	RegConsoleCmd("hale_hp", Command_GetHPCmd, "View the boss's current HP");
	RegConsoleCmd("halehp", Command_GetHPCmd, "View the boss's current HP");
	RegConsoleCmd("hale_next", QueuePanelCmd, "View the queue point list");
	RegConsoleCmd("halenext", QueuePanelCmd, "View the queue point list");
	RegConsoleCmd("hale_classinfo", Command_HelpPanelClass, "View class or boss info");
	RegConsoleCmd("haleclassinfo", Command_HelpPanelClass, "View class or boss info");
	RegConsoleCmd("hale_infotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("haleinfotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("hale_new", NewPanelCmd, "View FF2 changelog");
	RegConsoleCmd("halenew", NewPanelCmd, "View FF2 changelog");
	RegConsoleCmd("halemusic", MusicTogglePanelCmd, "View the music menu");
	RegConsoleCmd("hale_music", MusicTogglePanelCmd, "View the music menu");
	RegConsoleCmd("halevoice", VoiceTogglePanelCmd, "Toggle hearing boss monologues");
	RegConsoleCmd("hale_voice", VoiceTogglePanelCmd, "Toggle hearing boss monologues");
	RegConsoleCmd("hale_resetpoints", ResetQueuePointsCmd, "Reset your queue points");
	RegConsoleCmd("haleresetpoints", ResetQueuePointsCmd, "Reset your queue points");
	RegConsoleCmd("hale_boss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("haleboss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("haletoggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("hale_toggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("halecompanion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("hale_companion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("hale_skipsong", Command_SkipSong, "Skip the current song");
	RegConsoleCmd("haleskipsong", Command_SkipSong, "Skip the current song");
	RegConsoleCmd("hale_shufflesong", Command_ShuffleSong, "Play a random song");
	RegConsoleCmd("haleshufflesong", Command_ShuffleSong, "Play a random song");
	RegConsoleCmd("hale_tracklist", Command_Tracklist, "View list of songs");
	RegConsoleCmd("haletracklist", Command_Tracklist, "View list of songs");

	RegConsoleCmd("nextmap", Command_Nextmap);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	ReloadFF2 = false;
	ReloadWeapons = false;
	ReloadConfigs = false;

	RegAdminCmd("ff2_loadcharset", Command_LoadCharset, ADMFLAG_RCON, "Usage: ff2_loadcharset <charset>.  Forces FF2 to switch to a given character set without changing maps");
	RegAdminCmd("ff2_reloadcharset", Command_ReloadCharset, ADMFLAG_RCON, "Usage:  ff2_reloadcharset.  Forces FF2 to reload the current character set");
	RegAdminCmd("ff2_reload", Command_ReloadFF2, ADMFLAG_ROOT, "Reloads FF2 safely and quietly?");
	RegAdminCmd("ff2_reloadweapons", Command_ReloadFF2Weapons, ADMFLAG_RCON, "Reloads FF2 weapon configuration safely and quietly");
	RegAdminCmd("ff2_reloadconfigs", Command_ReloadFF2Configs, ADMFLAG_RCON, "Reloads ALL FF2 configs safely and quietly");

	RegAdminCmd("ff2_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  ff2_special <boss>.  Forces next round to use that boss");
	RegAdminCmd("ff2_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage:  ff2_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("ff2_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_start_music", Command_StartMusic, ADMFLAG_CHEATS, "Start the Boss's music");
	RegAdminCmd("ff2_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music");
	RegAdminCmd("ff2_resetqueuepoints", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("ff2_resetq", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("ff2_charset", Command_Charset, ADMFLAG_CHEATS, "Usage:  ff2_charset <charset>.  Forces FF2 to use a given character set");
	RegAdminCmd("ff2_reload_subplugins", Command_ReloadSubPlugins, ADMFLAG_RCON, "Reload FF2's subplugins.");
	RegAdminCmd("ff2_setrage", Command_SetRage, ADMFLAG_CHEATS, "Usage: ff2_setrage <target> <percent>. Sets the RAGE to a boss player");
	RegAdminCmd("ff2_addrage", Command_AddRage, ADMFLAG_CHEATS, "Usage: ff2_addrage <target> <percent>. Gives RAGE to a boss player");
	RegAdminCmd("ff2_setinfiniterage", Command_SetInfiniteRage, ADMFLAG_CHEATS, "Usage: ff2_infiniterage <target>. Gives infinite RAGE to a boss player");
	RegAdminCmd("ff2_setcharge", Command_SetCharge, ADMFLAG_CHEATS, "Usage: ff2_setcharge <target> <slot> <percent>. Sets a boss's charge");
	RegAdminCmd("ff2_addcharge", Command_AddCharge, ADMFLAG_CHEATS, "Usage: ff2_addcharge <target> <slot> <percent>. Adds a boss's charge");
	RegAdminCmd("ff2_makeboss", Command_MakeBoss, ADMFLAG_CHEATS, "Usage: ff2_makeboss <target> [team]. Makes a player a boss.");

	RegAdminCmd("hale_select", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage:  hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage:  hale_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("hale_start_music", Command_StartMusic, ADMFLAG_CHEATS, "Start the Boss's music");
	RegAdminCmd("hale_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music");
	RegAdminCmd("hale_resetqueuepoints", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("hale_resetq", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("hale_setrage", Command_SetRage, ADMFLAG_CHEATS, "Usage: hale_setrage <target> <percent>. Sets the RAGE to a boss player");
	RegAdminCmd("hale_addrage", Command_AddRage, ADMFLAG_CHEATS, "Usage: hale_addrage <target> <percent>. Gives RAGE to a boss player");
	RegAdminCmd("hale_setinfiniterage", Command_SetInfiniteRage, ADMFLAG_CHEATS, "Usage: hale_infiniterage <target>. Gives infinite RAGE to a boss player");
	RegAdminCmd("hale_setcharge", Command_SetCharge, ADMFLAG_CHEATS, "Usage: hale_setcharge <target> <slot> <percent>. Sets a boss's charge");
	RegAdminCmd("hale_addcharge", Command_AddCharge, ADMFLAG_CHEATS, "Usage: hale_addcharge <target> <slot> <percent>. Adds a boss's charge");
	RegAdminCmd("hale_makeboss", Command_MakeBoss, ADMFLAG_CHEATS, "Usage: hale_makeboss <target> [team]. Makes a player a boss.");

	AutoExecConfig(true, "FreakFortress2");

	FF2Cookies = RegClientCookie("ff2_cookies_mk2", "Player's Preferences", CookieAccess_Protected);
	StatCookies = RegClientCookie("ff2_cookies_stats", "Player's Statistics", CookieAccess_Protected);
	LastPlayedCookie = RegClientCookie("ff2_boss_previous", "Player's Last Boss", CookieAccess_Protected);
	SelectionCookie = RegClientCookie("ff2_boss_selection", "Player's Boss Selection", CookieAccess_Protected);

	jumpHUD = CreateHudSynchronizer();
	rageHUD = CreateHudSynchronizer();
	livesHUD = CreateHudSynchronizer();
	abilitiesHUD = CreateHudSynchronizer();
	timeleftHUD = CreateHudSynchronizer();
	infoHUD = CreateHudSynchronizer();
	statHUD = CreateHudSynchronizer();
	healthHUD = CreateHudSynchronizer();
	rivalHUD = CreateHudSynchronizer();

	char oldVersion[64];
	cvarVersion.GetString(oldVersion, 64);
	if(strcmp(oldVersion, PLUGIN_VERSION, false))
		LogToFile(eLog, "[Config] Warning: Your config may be outdated. Back up tf/cfg/sourcemod/FreakFortress2.cfg and delete it, and this plugin will generate a new one that you can then modify to your original values.");

	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("freak_fortress_2_prefs.phrases");
	LoadTranslations("freak_fortress_2_stats.phrases");
	LoadTranslations("common.phrases");

	if(LateLoaded)
		OnMapStart();

	AddNormalSoundHook(HookSound);

	AddMultiTargetFilter("@hale", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!hale", BossTargetFilter, "all non-Boss players", false);
	AddMultiTargetFilter("@boss", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "all non-Boss players", false);

	#if defined _steamtools_included
	steamtools = LibraryExists("SteamTools");
	#endif

	#if defined _goomba_included
	goomba = LibraryExists("goomba");
	#endif

	#if defined _tf2attributes_included
	tf2attributes = LibraryExists("tf2attributes");
	#endif

	TimesTen = LibraryExists("tf2x10");
}

public Action Command_SetRage(int client, int args)
{
	if(args!=2)
	{
		if(args!=1)
		{
			FReplyToCommand(client, "Usage: ff2_setrage or hale_setrage <target> <percent>");
		}
		else
		{
			if(!IsValidClient(client))
			{
				ReplyToCommand(client, "[SM] %t", "Command is in-game only");
				return Plugin_Handled;
			}

			if(!IsBoss(client) || GetBossIndex(client)==-1 || !IsPlayerAlive(client) || CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to set your RAGE!");
				return Plugin_Handled;
			}

			char ragePCT[80];
			GetCmdArg(1, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);

			BossCharge[Boss[client]][0]=rageMeter;
			FReplyToCommand(client, "You now have %i percent RAGE", RoundFloat(BossCharge[client][0]));
			LogAction(client, client, "\"%L\" gave themselves %i RAGE", client, RoundFloat(rageMeter));
			CheatsUsed = true;
		}
		return Plugin_Handled;
	}

	char ragePCT[80];
	char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml))<=0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
		{
			continue;
		}

		if(!IsBoss(target_list[target]) || GetBossIndex(target_list[target])==-1 || !IsPlayerAlive(target_list[target]) || CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to set RAGE!", target_name);
			return Plugin_Handled;
		}

		BossCharge[Boss[target_list[target]]][0]=rageMeter;
		LogAction(client, target_list[target], "\"%L\" set %d RAGE to \"%L\"", client, RoundFloat(rageMeter), target_list[target]);
		FReplyToCommand(client, "Set %d rage to %s", RoundFloat(rageMeter), target_name);
		CheatsUsed = true;
	}
	return Plugin_Handled;
}

public Action Command_AddRage(int client, int args)
{
	if(args!=2)
	{
		if(args!=1)
		{
			FReplyToCommand(client, "Usage: ff2_addrage or hale_addrage <target> <percent>");
		}
		else
		{
			if(!IsValidClient(client))
			{
				ReplyToCommand(client, "[SM] %t", "Command is in-game only");
				return Plugin_Handled;
			}

			if(!IsBoss(client) || GetBossIndex(client)==-1 || !IsPlayerAlive(client) || CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to give yourself RAGE!");
				return Plugin_Handled;
			}

			char ragePCT[80];
			GetCmdArg(1, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);

			BossCharge[Boss[client]][0]+=rageMeter;
			FReplyToCommand(client, "You now have %i percent RAGE (%i percent added)", RoundFloat(BossCharge[client][0]), RoundFloat(rageMeter));
			LogAction(client, client, "\"%L\" gave themselves %i more RAGE", client, RoundFloat(rageMeter));
			CheatsUsed = true;
		}
		return Plugin_Handled;
	}

	char ragePCT[80];
	char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml))<=0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
		{
			continue;
		}

		if(!IsBoss(target_list[target]) || GetBossIndex(target_list[target])==-1 || !IsPlayerAlive(target_list[target]) || CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to add RAGE!", target_name);
			return Plugin_Handled;
		}

		BossCharge[Boss[target_list[target]]][0]+=rageMeter;
		LogAction(client, target_list[target], "\"%L\" added %d RAGE to \"%L\"", client, RoundFloat(rageMeter), target_list[target]);
		FReplyToCommand(client, "Added %d rage to %s", RoundFloat(rageMeter), target_name);
		CheatsUsed = true;
	}
	return Plugin_Handled;
}

public Action Command_SetInfiniteRage(int client, int args)
{
	if(args!=1)
	{
		if(args>1)
		{
			FReplyToCommand(client, "Usage: ff2_setinfiniterage or hale_setinfiniterage <target>");
		}
		else
		{
			if(!IsValidClient(client))
			{
				ReplyToCommand(client, "[SM] %t", "Command is in-game only");
				return Plugin_Handled;
			}

			if(!IsBoss(client) || !IsPlayerAlive(client) || GetBossIndex(client)==-1 || CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to enable/disable infinite RAGE!");
				return Plugin_Handled;
			}
			if(!InfiniteRageActive[client])
			{
				InfiniteRageActive[client]=true;
				BossCharge[Boss[client]][0]=rageMax[client];
				FReplyToCommand(client, "Infinite RAGE activated");
				LogAction(client, client, "\"%L\" activated infinite RAGE on themselves", client);
				CreateTimer(0.2, Timer_InfiniteRage, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				CheatsUsed = true;
			}
			else
			{
				InfiniteRageActive[client]=false;
				FReplyToCommand(client, "Infinite RAGE deactivated");
				LogAction(client, client, "\"%L\" deactivated infinite RAGE on themselves", client);
				CheatsUsed = true;
			}
		}
		return Plugin_Handled;
	}

	char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml))<=0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
		{
			continue;
		}

		if(!IsBoss(target_list[target]) || GetBossIndex(target_list[target])==-1 || !IsPlayerAlive(target_list[target]) || CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to enable/disable infinite RAGE!", target_name);
			return Plugin_Handled;
		}

		if(!InfiniteRageActive[target_list[target]])
		{
			InfiniteRageActive[target_list[target]]=true;
			BossCharge[Boss[target_list[target]]][0]=rageMax[target_list[target]];
			FReplyToCommand(client, "Infinite RAGE activated for %s", target_name);
			LogAction(client, target_list[target], "\"%L\" activated infinite RAGE on \"%L\"", client, target_list[target]);
			CreateTimer(0.2, Timer_InfiniteRage, target_list[target], TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CheatsUsed = true;
		}
		else
		{
			InfiniteRageActive[target_list[target]]=false;
			FReplyToCommand(client, "Infinite RAGE deactivated for %s", target_name);
			LogAction(client, target_list[target], "\"%L\" deactivated infinite RAGE on \"%L\"", client, target_list[target]);
		}
	}
	return Plugin_Handled;
}

public Action Timer_InfiniteRage(Handle timer, any client)
{
	if(InfiniteRageActive[client] && (CheckRoundState()==2 || CheckRoundState()==-1))
		InfiniteRageActive[client]=false;

	if(!IsBoss(client) || !IsPlayerAlive(client) || GetBossIndex(client)==-1 || !InfiniteRageActive[client])
	{
		return Plugin_Stop;
	}

	if(CheckRoundState()==1)
		BossCharge[Boss[client]][0]=rageMax[client];

	return Plugin_Continue;
}

public Action Command_AddCharge(int client, int args)
{
	if(args!=3)
	{
		if(args!=2)
		{
			FReplyToCommand(client, "Usage: ff2_addcharge or hale_addcharge <target> <slot> <percent>");
		}
		else
		{
			if(!IsValidClient(client))
			{
				ReplyToCommand(client, "[SM] %t", "Command is in-game only");
				return Plugin_Handled;
			}

			if(!IsBoss(client) || !IsPlayerAlive(client) || CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to add your charge!");
				return Plugin_Handled;
			}

			char ragePCT[80], slotCharge[10];
			GetCmdArg(1, slotCharge, sizeof(slotCharge));
			GetCmdArg(2, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);
			int abilitySlot = StringToInt(slotCharge);

			if(!abilitySlot || abilitySlot<=7)
			{
				BossCharge[Boss[client]][abilitySlot]+=rageMeter;
				FReplyToCommand(client, "Slot %i's charge: %i percent (added %i percent)!", abilitySlot, RoundFloat(BossCharge[Boss[client]][abilitySlot]), RoundFloat(rageMeter));
				LogAction(client, client, "\"%L\" gave themselves %i more charge to slot %i", client, RoundFloat(rageMeter), abilitySlot);
				CheatsUsed = true;
			}
			else
			{
				FReplyToCommand(client, "Invalid slot!");
			}
		}
		return Plugin_Handled;
	}

	char ragePCT[80], slotCharge[10];
	char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, slotCharge, sizeof(slotCharge));
	GetCmdArg(3, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);
	int abilitySlot = StringToInt(slotCharge);

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml))<=0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
		{
			continue;
		}

		if(!IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to add their charge!", target_name);
			return Plugin_Handled;
		}

		if(!abilitySlot || abilitySlot<=7)
		{
			BossCharge[Boss[target_list[target]]][abilitySlot]+=rageMeter;
			FReplyToCommand(client, "%s's ability slot %i's charge: %i percent (added %i percent)!", target_name, abilitySlot, RoundFloat(BossCharge[Boss[target_list[target]]][abilitySlot]), RoundFloat(rageMeter));
			LogAction(client, target_list[target], "\"%L\" gave \"%L\" %i more charge to slot %i", client, target_list[target], RoundFloat(rageMeter), abilitySlot);
			CheatsUsed = true;
		}
		else
		{
			FReplyToCommand(client, "Invalid slot!");
		}
	}
	return Plugin_Handled;
}

public Action Command_SetCharge(int client, int args)
{
	if(args!=3)
	{
		if(args!=2)
		{
			FReplyToCommand(client, "Usage: ff2_setcharge or hale_setcharge <target> <slot> <percent>");
		}
		else
		{
			if(!IsValidClient(client))
			{
				ReplyToCommand(client, "[SM] %t", "Command is in-game only");
				return Plugin_Handled;
			}

			if(!IsBoss(client) || !IsPlayerAlive(client) || CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to set your charge!");
				return Plugin_Handled;
			}

			char ragePCT[80], slotCharge[10];
			GetCmdArg(1, slotCharge, sizeof(slotCharge));
			GetCmdArg(2, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);
			int abilitySlot = StringToInt(slotCharge);

			if(!abilitySlot || abilitySlot<=7)
			{
				BossCharge[Boss[client]][abilitySlot]=rageMeter;
				FReplyToCommand(client, "Slot %i's charge: %i percent!", abilitySlot, RoundFloat(BossCharge[Boss[client]][abilitySlot]));
				LogAction(client, client, "\"%L\" gave themselves %i charge to slot %i", client, RoundFloat(rageMeter), abilitySlot);
				CheatsUsed = true;
			}
			else
			{
				FReplyToCommand(client, "Invalid slot!");
			}
		}
		return Plugin_Handled;
	}

	char ragePCT[80], slotCharge[10];
	char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, slotCharge, sizeof(slotCharge));
	GetCmdArg(3, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);
	int abilitySlot = StringToInt(slotCharge);

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml))<=0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
		{
			continue;
		}

		if(!IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to set their charge!", target_name);
			return Plugin_Handled;
		}

		if(!abilitySlot || abilitySlot<=7)
		{
			BossCharge[Boss[target_list[target]]][abilitySlot]=rageMeter;
			FReplyToCommand(client, "%s's ability slot %i's charge: %i percent!", target_name, abilitySlot, RoundFloat(BossCharge[Boss[target_list[target]]][abilitySlot]));
			LogAction(client, target_list[target], "\"%L\" gave \"%L\" %i charge to slot %i", client, target_list[target], RoundFloat(rageMeter), abilitySlot);
			CheatsUsed = true;
		}
		else
		{
			FReplyToCommand(client, "Invalid slot!");
		}
	}
	return Plugin_Handled;
}

public Action Command_MakeBoss(int client, int args)
{
	if(args < 1)
	{
		FReplyToCommand(client, "Usage: ff2_makeboss or hale_makeboss <target> [team] [special] [index]");
		return Plugin_Handled;
	}

	char targetName[PLATFORM_MAX_PATH];
	char teamString[4];
	char specialString[4];
	char indexString[4];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, teamString, sizeof(teamString));
	int team = StringToInt(teamString);

	int special = -1;
	if(args > 2)
	{
		GetCmdArg(3, specialString, sizeof(specialString));
		special = StringToInt(specialString);
	}

	int index = -1;
	if(args > 3)
	{
		GetCmdArg(4, indexString, sizeof(indexString));
		index = StringToInt(indexString);
		if(index < 0)
		{
			FReplyToCommand(client, "Boss index can not be below 0!");
			return Plugin_Handled;
		}
		if(index > MaxClients)
		{
			FReplyToCommand(client, "Boss index can not be above %i!", MaxClients);
			return Plugin_Handled;
		}
	}

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml))<=0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	bool[] omit = new bool[MaxClients+1];
	int boss, boss2;
	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		omit[target_list[target]] = true;
		if(IsBoss(target_list[target]))
		{
			if(index >= 0)
			{
				Boss[boss] = 0;
				boss = index;
				Boss[boss] = target_list[target];
			}
			else
			{
				boss = GetBossIndex(target_list[target]);
			}

			if(team > 1)
			{
				BossSwitched[boss] = team==OtherTeam ? true : false;
			}
			else if(team > 0)
			{
				BossSwitched[boss] = GetRandomInt(0, 1) ? true : false;
			}

			if(special >= 0)
				Incoming[boss] = special;

			PickCharacter(boss, boss);
			CreateTimer(0.3, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			if(index >= 0)
			{
				Boss[index] = target_list[target];
				if(team > 1)
				{
					BossSwitched[index] = team==OtherTeam ? true : false;
				}
				else if(team > 0)
				{
					BossSwitched[index] = GetRandomInt(0, 1) ? true : false;
				}

				if(special >= 0)
					Incoming[index] = special;

				PickCharacter(index, index);
				CreateTimer(0.3, Timer_MakeBoss, index, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				while(boss2 <= MaxClients)
				{
					if(!IsValidClient(Boss[boss2]))
					{
						Boss[boss2] = target_list[target];
						if(team > 1)
						{
							BossSwitched[boss] = team==OtherTeam ? true : false;
						}
						else if(team > 0)
						{
							BossSwitched[boss] = GetRandomInt(0, 1) ? true : false;
						}

						if(special >= 0)
							Incoming[boss] = special;

						PickCharacter(boss2, boss2);
						CreateTimer(0.3, Timer_MakeBoss, boss2, TIMER_FLAG_NO_MAPCHANGE);
						boss2++;
						break;
					}
					boss2++;
				}
				if(boss2 > MaxClients)
				{
					FReplyToCommand(client, "All boss indexes have been used!");
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Handled;
}

public bool BossTargetFilter(const char[] pattern, Handle clients)
{
	bool non=StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && FindValueInArray(clients, client)==-1)
		{
			if(IsBoss(client))
			{
				if(!non)
				{
					PushArrayCell(clients, client);
				}
			}
			else if(non)
			{
				PushArrayCell(clients, client);
			}
		}
	}
	return true;
}

public void OnLibraryAdded(const char[] name)
{
	#if defined _steamtools_included
	if(!strcmp(name, "SteamTools", false))
	{
		steamtools = true;
	}
	#endif

	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
	{
		tf2attributes = true;
	}
	#endif

	#if defined _goomba_included
	if(!strcmp(name, "goomba", false))
	{
		goomba = true;
	}
	#endif

	if(!strcmp(name, "tf2x10", false))
	{
		TimesTen = true;
	}

	#if !defined _smac_included
	if(!strcmp(name, "smac", false))
	{
		smac = true;
	}
	#endif

	#if defined _freak_fortress_2_kstreak_included
	if(!strcmp(name, "ff2_kstreak_pref", false))
	{
		kmerge = view_as<bool>(FF2_KStreak_Merge());
	}
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _steamtools_included
	if(!strcmp(name, "SteamTools", false))
	{
		steamtools = false;
	}
	#endif

	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
	{
		tf2attributes = false;
	}
	#endif

	#if defined _goomba_included
	if(!strcmp(name, "goomba", false))
	{
		goomba = false;
	}
	#endif

	if(!strcmp(name, "tf2x10", false))
	{
		TimesTen = false;
	}

	#if !defined _smac_included
	if(!strcmp(name, "smac", false))
	{
		smac = false;
	}
	#endif

	#if defined _freak_fortress_2_kstreak_included
	if(!strcmp(name, "ff2_kstreak_pref", false))
	{
		kmerge = false;
	}
	#endif
}

public void OnConfigsExecuted()
{
	tf_arena_use_queue=GetConVarInt(FindConVar("tf_arena_use_queue"));
	mp_teams_unbalance_limit=GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
	tf_arena_first_blood=GetConVarInt(FindConVar("tf_arena_first_blood"));
	mp_forcecamera=GetConVarInt(FindConVar("mp_forcecamera"));
	tf_dropped_weapon_lifetime=GetConVarBool(FindConVar("tf_dropped_weapon_lifetime"));
	GetConVarString(FindConVar("mp_humans_must_join_team"), mp_humans_must_join_team, sizeof(mp_humans_must_join_team));
	GetConVarString(hostName=FindConVar("hostname"), oldName, sizeof(oldName));

	if(GetConVarInt(cvarEnabled)>1)
	{
		EnableFF2();
	}
	else if(IsFF2Map() && GetConVarInt(cvarEnabled)>0)
	{
		EnableFF2();
	}
	else
	{
		DisableFF2();
	}
}

public void OnMapStart()
{
	HPTime=0.0;
	doorCheckTimer=INVALID_HANDLE;
	RoundCount=0;
	for(int client; client<=MaxClients; client++)
	{
		KSpreeTimer[client]=0.0;
		FF2flags[client]=0;
		Incoming[client]=-1;
		MusicTimer[client]=INVALID_HANDLE;
		RPSHealth[client]=-1;
		RPSLosses[client]=0;
		RPSHealth[client]=0;
		RPSLoser[client]=-1.0;
	}

	for(int specials; specials<MAXSPECIALS; specials++)
	{
		if(BossKV[specials]!=INVALID_HANDLE)
		{
			CloseHandle(BossKV[specials]);
			BossKV[specials]=INVALID_HANDLE;
		}
	}
}

public void OnMapEnd()
{
	if(Enabled || Enabled2)
	{
		DisableFF2();
	}
}

public void OnPluginEnd()
{
	OnMapEnd();
	SetConVarString(hostName, oldName);
	if(!ReloadFF2 && CheckRoundState() == 1)
	{
		ForceTeamWin(0);
		FPrintToChatAll("The plugin has been unexpectedly unloaded!");
	}
}

public void EnableFF2()
{
	Enabled = true;
	Enabled2 = true;
	Enabled3 = false;

	//Cache cvars
	SetConVarString(FindConVar("ff2_version"), PLUGIN_VERSION);
	Announce = GetConVarFloat(cvarAnnounce);
	PointType = GetConVarInt(cvarPointType);
	PointDelay = GetConVarInt(cvarPointDelay);
	GoombaDamage = GetConVarFloat(cvarGoombaDamage);
	reboundPower = GetConVarFloat(cvarGoombaRebound);
	SniperDamage = GetConVarFloat(cvarSniperDamage);
	SniperMiniDamage = GetConVarFloat(cvarSniperMiniDamage);
	BowDamage = GetConVarFloat(cvarBowDamage);
	BowDamageNon = GetConVarFloat(cvarBowDamageNon);
	BowDamageMini = GetConVarFloat(cvarBowDamageMini);
	SniperClimbDamage = GetConVarFloat(cvarSniperClimbDamage);
	SniperClimbDelay = GetConVarFloat(cvarSniperClimbDelay);
	QualityWep = GetConVarInt(cvarQualityWep);
	canBossRTD = GetConVarBool(cvarBossRTD);
	AliveToEnable = GetConVarFloat(cvarAliveToEnable);
	PointsInterval = GetConVarInt(cvarPointsInterval);
	PointsInterval2 = GetConVarFloat(cvarPointsInterval);
	PointsDamage = GetConVarInt(cvarPointsDamage);
	PointsMin = GetConVarInt(cvarPointsMin);
	PointsExtra = GetConVarInt(cvarPointsExtra);
	arenaRounds = GetConVarInt(cvarArenaRounds);
	circuitStun = GetConVarFloat(cvarCircuitStun);
	countdownHealth = GetConVarInt(cvarCountdownHealth);
	countdownPlayers = GetConVarFloat(cvarCountdownPlayers);
	countdownTime = GetConVarInt(cvarCountdownTime);
	countdownOvertime = GetConVarBool(cvarCountdownOvertime);
	lastPlayerGlow = GetConVarFloat(cvarLastPlayerGlow);
	bossTeleportation = GetConVarBool(cvarBossTeleporter);
	shieldCrits = GetConVarInt(cvarShieldCrits);
	allowedDetonations = GetConVarInt(cvarCaberDetonations);
	Annotations = GetConVarInt(cvarAnnotations);
	TellName = GetConVarBool(cvarTellName);

	//Set some Valve cvars to what we want them to be
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
	SetConVarString(FindConVar("mp_humans_must_join_team"), "any");

	cvarTags = FindConVar("sv_tags");
        MyAddServerTag("ff2");
        MyAddServerTag("hale");
        MyAddServerTag("vsh");

	float time = Announce;
	if(time > 1.0)
		CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	CacheWeapons();
	CheckToChangeMapDoors();
	CheckToTeleportToSpawn();
	MapHasMusic(true);
	FindCharacters();
	strcopy(FF2CharSetString, 2, "");

	#if !defined _smac_included
	if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
	{
		ServerCommand("smac_removecvar sv_cheats");
		ServerCommand("smac_removecvar host_timescale");
	}
	#endif

	bMedieval = FindEntityByClassname(-1, "tf_logic_medieval")!=-1 || GetConVarBool(FindConVar("tf_medieval"));
	FindHealthBar();

	#if defined _steamtools_included
	EnabledDesc = true;
	if(steamtools && GetConVarBool(cvarSteamTools))
	{
		char gameDesc[64];
		if(TimesTen)
		{
			Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 x10 (%s)", PLUGIN_VERSION);
		}
		else
		{
			Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
		}
		Steam_SetGameDescription(gameDesc);
	}
	#endif

	changeGamemode=0;

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
			OnClientPostAdminCheck(client);
	}
}

public void DisableFF2()
{
	Enabled = false;
	Enabled2 = false;
	Enabled3 = false;

	DisableSubPlugins();

	SetConVarInt(FindConVar("tf_arena_use_queue"), tf_arena_use_queue);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), mp_teams_unbalance_limit);
	SetConVarInt(FindConVar("tf_arena_first_blood"), tf_arena_first_blood);
	SetConVarInt(FindConVar("mp_forcecamera"), mp_forcecamera);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), tf_dropped_weapon_lifetime);
	SetConVarString(FindConVar("mp_humans_must_join_team"), mp_humans_must_join_team);

        MyRemoveServerTag("ff2");
        MyRemoveServerTag("hale");
        MyRemoveServerTag("vsh");

	if(doorCheckTimer != INVALID_HANDLE)
	{
		KillTimer(doorCheckTimer);
		doorCheckTimer = INVALID_HANDLE;
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(BossInfoTimer[client][1] != INVALID_HANDLE)
			{
				KillTimer(BossInfoTimer[client][1]);
				BossInfoTimer[client][1] = INVALID_HANDLE;
			}
			SaveClientPreferences(client);
		}

		if(MusicTimer[client] != INVALID_HANDLE)
		{
			KillTimer(MusicTimer[client]);
			MusicTimer[client] = INVALID_HANDLE;
		}

		bossHasReloadAbility[client] = false;
		bossHasRightMouseAbility[client] = false;
	}

	#if !defined _smac_included
	if(smac && FindPluginByFile("smac_cvars.smx") != INVALID_HANDLE)
	{
		ServerCommand("smac_addcvar sv_cheats replicated ban 0 0");
		ServerCommand("smac_addcvar host_timescale replicated ban 1.0 1.0");
	}
	#endif

	#if defined _steamtools_included
	if(EnabledDesc && steamtools && GetConVarBool(cvarSteamTools))
	{
		Steam_SetGameDescription("Team Fortress");
	}
	EnabledDesc = false;
	#endif

	changeGamemode = 0;
}

public void CacheWeapons()
{
	if(GetConVarInt(cvarHardcodeWep)>1)
	{
		ConfigWeapons = false;
		return;
	}

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, WeaponCFG);

	if(!FileExists(config))
	{
		LogToFile(eLog, "[Weapons] Could not find '%s'!", WeaponCFG);
		ConfigWeapons = false;
		return;
	}

	kvWeaponMods = CreateKeyValues("Weapons");
	if(!FileToKeyValues(kvWeaponMods, config))
	{
		LogToFile(eLog, "[Weapons] Freak Fortress 2 disabled-'%s' is improperly formatted!", WeaponCFG);
		ConfigWeapons = false;
		return;
	}
	ConfigWeapons = true;
}

public void FindCharacters()  //TODO: Investigate KvGotoFirstSubKey; KvGotoNextKey
{
	char config[PLATFORM_MAX_PATH], key[4], charset[42];
	Specials=0;
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, CharsetCFG);

	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, CharsetCFG);
		if(FileExists(config))
		{
			LogToFile(eLog, "[!!!] Freak Fortress 2 disabled-please move '%s' from '%s' to '%s'!", CharsetCFG, ConfigPath, DataPath);
		}
		else
		{
			LogToFile(eLog, "[!!!] Freak Fortress 2 disabled-can not find '%s!", CharsetCFG);
		}
		Enabled2=false;
		return;
	}

	Handle Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	int NumOfCharSet=FF2CharSet;
	Action action=Plugin_Continue;
	Call_StartForward(OnLoadCharacterSet);
	Call_PushCellRef(NumOfCharSet);
	strcopy(charset, sizeof(charset), FF2CharSetString);
	Call_PushStringEx(charset, sizeof(charset), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	if(action==Plugin_Changed)
	{
		int i=-1;
		if(strlen(charset))
		{
			KvRewind(Kv);
			for(i=0; ; i++)
			{
				KvGetSectionName(Kv, config, sizeof(config));
				if(!strcmp(config, charset, false))
				{
					FF2CharSet=i;
					strcopy(FF2CharSetString, PLATFORM_MAX_PATH, charset);
					KvGotoFirstSubKey(Kv);
					break;
				}

				if(!KvGotoNextKey(Kv))
				{
					i=-1;
					break;
				}
			}
		}

		if(i==-1)
		{
			FF2CharSet=NumOfCharSet;
			for(i=0; i<FF2CharSet; i++)
			{
				KvGotoNextKey(Kv);
			}
			KvGotoFirstSubKey(Kv);
			KvGetSectionName(Kv, FF2CharSetString, sizeof(FF2CharSetString));
		}
	}

	KvRewind(Kv);
	for(int i; i<FF2CharSet; i++)
	{
		KvGotoNextKey(Kv);
	}

	for(int i=1; i<MAXSPECIALS; i++)
	{
		IntToString(i, key, sizeof(key));
		KvGetString(Kv, key, config, PLATFORM_MAX_PATH);
		if(!config[0])  //TODO: Make this more user-friendly (don't immediately break-they might have missed a number)
		{
			break;
		}
		LoadCharacter(config);
	}

	KvGetString(Kv, "chances", ChancesString, sizeof(ChancesString));
	CloseHandle(Kv);

	if(ChancesString[0])
	{
		char stringChances[MAXSPECIALS*2][8];

		int amount=ExplodeString(ChancesString, ";", stringChances, MAXSPECIALS*2, 8);
		if(amount % 2)
		{
			LogToFile(eLog, "[Characters] Invalid chances string, disregarding chances");
			strcopy(ChancesString, sizeof(ChancesString), "");
			amount=0;
		}

		chances[0] = StringToInt(stringChances[0]);
		chances[1] = StringToInt(stringChances[1]);
		for(chancesIndex=2; chancesIndex<amount; chancesIndex++)
		{
			if(chancesIndex % 2)
			{
				if(StringToInt(stringChances[chancesIndex])<=0)
				{
					LogToFile(eLog, "[Characters] Character %i cannot have a zero or negative chance, disregarding chances", chancesIndex-1);
					strcopy(ChancesString, sizeof(ChancesString), "");
					break;
				}
				chances[chancesIndex] = StringToInt(stringChances[chancesIndex])+chances[chancesIndex-2];
			}
			else
			{
				chances[chancesIndex] = StringToInt(stringChances[chancesIndex]);
			}
		}
	}

	if(FileExists("sound/saxton_hale/9000.wav", true))
	{
		AddFileToDownloadsTable("sound/saxton_hale/9000.wav");
		PrecacheSound("saxton_hale/9000.wav", true);
	}
	PrecacheSound("vo/announcer_am_capincite01.mp3", true);
	PrecacheSound("vo/announcer_am_capincite03.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled01.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled02.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled03.mp3", true);
	PrecacheSound("vo/announcer_am_capenabled04.mp3", true);
	PrecacheSound("weapons/barret_arm_zap.wav", true);
	PrecacheSound("vo/announcer_ends_5min.mp3", true);
	PrecacheSound("vo/announcer_ends_2min.mp3", true);
	PrecacheSound("player/doubledonk.wav", true);
	PrecacheSound("ambient/lightson.wav", true);
	PrecacheSound("ambient/lightsoff.wav", true);
	isCharSetSelected=false;
}

void EnableSubPlugins(bool force=false)
{
	if(areSubPluginsEnabled && !force)
	{
		return;
	}

	areSubPluginsEnabled=true;
	char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH], filename_old[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "plugins/freaks");
	FileType filetype;
	Handle directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".smx", false)!=-1)
		{
			Format(filename_old, sizeof(filename_old), "%s/%s", path, filename);
			ReplaceString(filename, sizeof(filename), ".smx", ".ff2", false);
			Format(filename, sizeof(filename), "%s/%s", path, filename);
			DeleteFile(filename); // Just in case filename.ff2 also exists: delete it and replace it with the new .smx version
			RenameFile(filename, filename_old);
		}
	}

	directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
		{
			ServerCommand("sm plugins load freaks/%s", filename);
		}
	}
}

void DisableSubPlugins(bool force=false)
{
	if(!areSubPluginsEnabled && !force)
	{
		return;
	}

	char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	FileType filetype;
	Handle directory=OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
		{
			InsertServerCommand("sm plugins unload freaks/%s", filename);  //ServerCommand will not work when switching maps
		}
	}
	ServerExecute();
	areSubPluginsEnabled=false;
}

public void LoadCharacter(const char[] character)
{
	char extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy"};
	char config[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, config, sizeof(config), "%s/%s.cfg", ConfigPath, character);
	if(!FileExists(config))
	{
		LogToFile(eLog, "[Characters] Character %s does not exist!", character);
		return;
	}
	BossKV[Specials] = CreateKeyValues("character");
	FileToKeyValues(BossKV[Specials], config);

	int version = KvGetNum(BossKV[Specials], "version", StringToInt(MAJOR_REVISION));
	if(version!=StringToInt(MAJOR_REVISION) && version!=99) // 99 for bosses made ONLY for this fork
	{
		LogToFile(eLog, "[Boss] Character %s is only compatible with FF2 v%i!", character, version);
		return;
	}

	version = KvGetNum(BossKV[Specials], "version_minor", StringToInt(MINOR_REVISION));
	if(version > StringToInt(MINOR_REVISION))
	{
		LogToFile(eLog, "[Boss] Character %s requires newer version of FF2 (at least %s.%i.x)!", character, MAJOR_REVISION, version);
		return;
	}

	version = KvGetNum(BossKV[Specials], "version_stable", StringToInt(STABLE_REVISION));
	if(version > StringToInt(STABLE_REVISION))
	{
		LogToFile(eLog, "[Boss] Character %s requires newer version of FF2 (at least %s.%s.%i)!", character, MAJOR_REVISION, MINOR_REVISION, version);
		return;
	}

	version = KvGetNum(BossKV[Specials], "fversion", StringToInt(FORK_MAJOR_REVISION));
	if(version != StringToInt(FORK_MAJOR_REVISION))
	{
		LogToFile(eLog, "[Boss] Character %s is only compatible with %s FF2 v%i!", character, FORK_SUB_REVISION, version);
		return;
	}

	version = KvGetNum(BossKV[Specials], "fversion_minor", StringToInt(FORK_MINOR_REVISION));
	if(version > StringToInt(FORK_MINOR_REVISION))
	{
		LogToFile(eLog, "[Boss] Character %s requires newer version of %s FF2 (at least %s.%i.x)!", character, FORK_SUB_REVISION, FORK_MAJOR_REVISION, version);
		return;
	}

	version = KvGetNum(BossKV[Specials], "fversion_stable", StringToInt(FORK_STABLE_REVISION));
	if(version > StringToInt(FORK_STABLE_REVISION))
	{
		LogToFile(eLog, "[Boss] Character %s requires newer version of %s FF2 (at least %s.%s.%i)!", character, FORK_SUB_REVISION, FORK_MAJOR_REVISION, FORK_MINOR_REVISION, version);
		return;
	}

	for(int i=1; ; i++)
	{
		Format(config, 10, "ability%i", i);
		if(KvJumpToKey(BossKV[Specials], config))
		{
			char plugin_name[64];
			KvGetString(BossKV[Specials], "plugin_name", plugin_name, 64);
			BuildPath(Path_SM, config, sizeof(config), "plugins/freaks/%s.ff2", plugin_name);
			if(!FileExists(config))
			{
				LogToFile(eLog, "[Boss] Character %s needs plugin %s!", character, plugin_name);
				return;
			}
		}
		else
		{
			break;
		}
	}
	KvRewind(BossKV[Specials]);

	char key[PLATFORM_MAX_PATH], section[64];
	KvSetString(BossKV[Specials], "filename", character);
	KvGetString(BossKV[Specials], "name", config, sizeof(config));
	bBlockVoice[Specials] = view_as<bool>(KvGetNum(BossKV[Specials], "sound_block_vo", 0));
	BossSpeed[Specials] = KvGetFloat(BossKV[Specials], "maxspeed", 340.0);
	KvGotoFirstSubKey(BossKV[Specials]);

	while(KvGotoNextKey(BossKV[Specials]))
	{
		KvGetSectionName(BossKV[Specials], section, sizeof(section));
		if(!strcmp(section, "download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
				{
					break;
				}

				if(FileExists(config, true))
				{
					AddFileToDownloadsTable(config);
				}
				else
				{
					LogToFile(eLog, "[Boss] Character %s is missing file '%s'!", character, config);
				}
			}
		}
		else if(!strcmp(section, "mod_download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
				{
					break;
				}

				for(int extension; extension<sizeof(extensions); extension++)
				{
					Format(key, PLATFORM_MAX_PATH, "%s%s", config, extensions[extension]);
					if(FileExists(key, true))
					{
						AddFileToDownloadsTable(key);
					}
					else if(StrContains(key, ".phy") == -1)
					{
						LogToFile(eLog, "[Boss] Character %s is missing file '%s'!", character, key);
					}
				}
			}
		}
		else if(!strcmp(section, "mat_download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
				{
					break;
				}
				Format(key, sizeof(key), "%s.vtf", config);
				if(FileExists(key, true))
				{
					AddFileToDownloadsTable(key);
				}
				else
				{
					LogToFile(eLog, "[Boss] Character %s is missing file '%s'!", character, key);
				}
				Format(key, sizeof(key), "%s.vmt", config);
				if(FileExists(key, true))
				{
					AddFileToDownloadsTable(key);
				}
				else
				{
					LogToFile(eLog, "[Boss] Character %s is missing file '%s'!", character, key);
				}
			}
		}
	}
	Specials++;
}

public void PrecacheCharacter(int characterIndex)
{
	char file[PLATFORM_MAX_PATH], filePath[PLATFORM_MAX_PATH], key[8], section[16], bossName[64];
	KvRewind(BossKV[characterIndex]);
	KvGetString(BossKV[characterIndex], "filename", bossName, sizeof(bossName));
	KvGotoFirstSubKey(BossKV[characterIndex]);
	while(KvGotoNextKey(BossKV[characterIndex]))
	{
		KvGetSectionName(BossKV[characterIndex], section, sizeof(section));
		if(StrEqual(section, "sound_bgm"))
		{
			for(int i=1; ; i++)
			{
				Format(key, sizeof(key), "path%d", i);
				KvGetString(BossKV[characterIndex], key, file, sizeof(file));
				if(!file[0])
				{
					break;
				}

				Format(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
				if(FileExists(filePath, true))
				{
					PrecacheSound(file);
				}
				else
				{
					LogToFile(eLog, "[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
				}
			}
		}
		else if(StrEqual(section, "mod_precache") || !StrContains(section, "sound_") || !StrContains(section, "catch_"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[characterIndex], key, file, sizeof(file));
				if(!file[0])
				{
					break;
				}

				if(StrEqual(section, "mod_precache"))
				{
					if(FileExists(file, true))
					{
						PrecacheModel(file);
					}
					else
					{
						LogToFile(eLog, "[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
					}
				}
				else
				{
					Format(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
					if(FileExists(filePath, true))
					{
						PrecacheSound(file);
					}
					else
					{
						LogToFile(eLog, "[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
					}
				}
			}
		}
	}
}

public void CvarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == cvarAnnounce)
	{
		Announce = StringToFloat(newValue);
	}
	else if(convar == cvarArenaRounds)
	{
		arenaRounds = StringToInt(newValue);
	}
	else if(convar == cvarCircuitStun)
	{
		circuitStun = StringToFloat(newValue);
	}
	else if(convar==cvarHealthBar || convar==cvarHealthHud)
	{
		UpdateHealthBar();
	}
	else if(convar == cvarLastPlayerGlow)
	{
		lastPlayerGlow = StringToFloat(newValue);
	}
	else if(convar == cvarSpecForceBoss)
	{
		SpecForceBoss = view_as<bool>(StringToInt(newValue));
	}
	else if(convar == cvarBossTeleporter)
	{
		bossTeleportation = view_as<bool>(StringToInt(newValue));
	}
	else if(convar == cvarShieldCrits)
	{
		shieldCrits = StringToInt(newValue);
	}
	else if(convar == cvarCaberDetonations)
	{
		allowedDetonations = StringToInt(newValue);
	}
	else if(convar == cvarGoombaDamage)
	{
		GoombaDamage = StringToFloat(newValue);
	}
	else if(convar == cvarGoombaRebound)
	{
		reboundPower = StringToFloat(newValue);
	}
	else if(convar == cvarSniperDamage)
	{
		SniperDamage = StringToFloat(newValue);
	}
	else if(convar == cvarSniperMiniDamage)
	{
		SniperMiniDamage = StringToFloat(newValue);
	}
	else if(convar == cvarBowDamage)
	{
		BowDamage = StringToFloat(newValue);
	}
	else if(convar == cvarBowDamageNon)
	{
		BowDamageNon = StringToFloat(newValue);
	}
	else if(convar == cvarBowDamageMini)
	{
		BowDamageMini = StringToFloat(newValue);
	}
	else if(convar == cvarSniperClimbDamage)
	{
		SniperClimbDamage = StringToFloat(newValue);
	}
	else if(convar == cvarSniperClimbDelay)
	{
		SniperClimbDelay = StringToFloat(newValue);
	}
	else if(convar == cvarQualityWep)
	{
		QualityWep = StringToInt(newValue);
	}
	else if(convar == cvarBossRTD)
	{
		canBossRTD = view_as<bool>(StringToInt(newValue));
	}
	else if(convar == cvarPointsInterval)
	{
		PointsInterval = StringToInt(newValue);
		PointsInterval2 = StringToFloat(newValue);
	}
	else if(convar == cvarPointsDamage)
	{
		PointsDamage = StringToInt(newValue);
	}
	else if(convar == cvarPointsMin)
	{
		PointsMin = StringToInt(newValue);
	}
	else if(convar == cvarPointsExtra)
	{
		PointsExtra = StringToInt(newValue);
	}
	else if(convar == cvarDuoMin)
	{
		if(playing>=GetConVarInt(cvarDuoMin) && !DuoMin)
		{
			DuoMin = true;
		}
		else if(DuoMin)
		{
			DuoMin = false;
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client) && strlen(xIncoming[client]))
				{
					if(!CheckValidBoss(client, xIncoming[client], true))
					{
						FPrintToChat(client, "%t", "boss_selection_reset");
						xIncoming[client][0] = '\0';
						CanBossVs[client] = 0;
						CanBossTeam[client] = 0;
					}
				}
			}
		}
	}
	else if(convar == cvarAnnotations)
	{
		Annotations = StringToInt(newValue);
	}
	else if(convar == cvarTellName)
	{
		TellName=view_as<bool>(StringToInt(newValue));
	}
	else if(convar == cvarEnabled)
	{
		switch(StringToInt(newValue))
		{
			case 0:
			{
				changeGamemode = Enabled ? 2 : 0;
			}
			case 1:
			{
				if(IsFF2Map() && !Enabled)
					changeGamemode = 1;
			}
			case 2:
			{
				changeGamemode = Enabled ? 0 : 1;
			}
		}
	}
}

#if defined _smac_included
public Action SMAC_OnCheatDetected(int client, const char[] module, DetectionType type, Handle info)
{
	FF2Dbg("SMAC: Cheat detected!");
	if(type == Detection_CvarViolation)
	{
		FF2Dbg("SMAC: Cheat was a cvar violation!");
		if((FF2flags[Boss[client]] & FF2FLAG_CHANGECVAR))
		{
			FF2Dbg("SMAC: Ignoring violation");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
#endif

public Action Timer_Announce(Handle timer)
{
	static int announcecount = -1;
	announcecount++;
	if(Announce>1.0 && Enabled2)
	{
		switch(announcecount)
		{
			case 1:
			{
				FPrintToChatAll("%t", "ServerAd");
			}
			case 2:
			{
				FPrintToChatAll("%t", "ff2_last_update", PLUGIN_VERSION, ff2versiondates[maxVersion]);
			}
			case 3:
			{
				FPrintToChatAll("%t", "ClassicAd");
			}
			case 4:
			{
				if(GetConVarBool(cvarToggleBoss))	// Toggle Command?
				{
					FPrintToChatAll("%t", "FF2 Toggle Command");
				}
				else					// Guess not, play the 4th thing and next is 5
				{
					announcecount = 5;
					FPrintToChatAll("%t", "DevAd", PLUGIN_VERSION);
				}
			}
			case 5:
			{
				FPrintToChatAll("%t", "DevAd", PLUGIN_VERSION);
			}
			case 6:
			{
				if(GetConVarBool(cvarDuoBoss))		// Companion Toggle?
				{
					FPrintToChatAll("%t", "FF2 Companion Command");
				}
				else					// Guess not either, play the last thing and next is 0
				{
					announcecount = 0;
					FPrintToChatAll("%t", "type_ff2_to_open_menu");
				}
			}
			default:
			{
				announcecount = 0;
				FPrintToChatAll("%t", "type_ff2_to_open_menu");
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsFF2Map()
{
	char config[PLATFORM_MAX_PATH];
	GetCurrentMap(currentmap, sizeof(currentmap));
	if(FileExists("bNextMapToFF2"))
	{
		return true;
	}
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, MapCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapCFG);
		if(FileExists(config))
		{
			LogToFile(eLog, "[!!!] Please move '%s' from '%s' to '%s'! Disabling Plugin!", MapCFG, ConfigPath, DataPath);
		}
		else
		{
			LogToFile(eLog, "[!!!] Unable to find %s, disabling plugin.", config);
		}
		return false;
	}

	Handle file=OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogToFile(eLog, "[!!!] Error reading maps from %s, disabling plugin.", config);
		return false;
	}

	int tries;
	while(ReadFileLine(file, config, sizeof(config)))
	{
		tries++;
		if(tries >= 100)
		{
			LogToFile(eLog, "[!!!] Breaking infinite loop when trying to check the map.");
			return false;
		}

		Format(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
		{
			continue;
		}

		if(!StrContains(currentmap, config, false) || !StrContains(config, "all", false))
		{
			CloseHandle(file);
			return true;
		}
	}
	CloseHandle(file);
	return false;
}

stock bool MapHasMusic(bool forceRecalc=false)  //SAAAAAARGE
{
	static bool hasMusic;
	static bool found;
	if(forceRecalc)
	{
		found=false;
		hasMusic=false;
	}

	if(!found)
	{
		int entity=-1;
		char name[64];
		while((entity=FindEntityByClassname2(entity, "info_target"))!=-1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(!strcmp(name, "hale_no_music", false))
			{
				FF2Dbg("Detected Map Music");
				hasMusic=true;
			}
		}
		found=true;
	}
	return hasMusic;
}

stock bool CheckToChangeMapDoors()
{
	if(!Enabled || !Enabled2)
	{
		return;
	}

	char config[PLATFORM_MAX_PATH];
	checkDoors=false;
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, DoorCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, DoorCFG);
		if(FileExists(config))
		{
			LogToFile(eLog, "[Doors] Please move '%s' from '%s' to '%s'!", DoorCFG, ConfigPath, DataPath);
		}
		if(!strncmp(currentmap, "vsh_lolcano_pb1", 15, false))
		{
			checkDoors=true;
		}
		return;
	}

	Handle file=OpenFile(config, "r");
	if(file==INVALID_HANDLE)
	{
		if(!strncmp(currentmap, "vsh_lolcano_pb1", 15, false))
		{
			checkDoors=true;
		}
		return;
	}

	while(!IsEndOfFile(file) && ReadFileLine(file, config, sizeof(config)))
	{
		Format(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
		{
			continue;
		}

		if(StrContains(currentmap, config, false)!=0 || !StrContains(config, "all", false))
		{
			delete file;
			checkDoors=true;
			return;
		}
	}
	delete file;
}

void CheckToTeleportToSpawn()
{
	char config[PLATFORM_MAX_PATH];
	GetCurrentMap(currentmap, sizeof(currentmap));
	SpawnTeleOnTriggerHurt = false;
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, SpawnTeleportCFG);

	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, SpawnTeleportCFG);
		if(FileExists(config))
		{
			LogToFile(eLog, "[TTS] Please move '%s' from '%s' to '%s'!", SpawnTeleportCFG, ConfigPath, DataPath);
		}
		else
		{
			LogToFile(eLog, "[TTS] Unable to find '%s', will not activate teleport to spawn.", config);
		}
		return;
	}

	Handle fileh=OpenFile(config, "r");
	if(fileh==null)
		return;

	while(!IsEndOfFile(fileh) && ReadFileLine(fileh, config, sizeof(config)))
	{
		Format(config, strlen(config) - 1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(StrContains(currentmap, config, false)>=0 || !StrContains(config, "all", false))
		{
			LogMessage("[FF2] Enabling teleport to spawn for %s", currentmap);
			SpawnTeleOnTriggerHurt = true;
			delete fileh;
			return;
		}
	}

	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, SpawnTeleportBlacklistCFG);
	if(!FileExists(config))
	{
		LogToFile(eLog, "[TTS] Unable to find '%s', will not use map blacklist.", config);
		return;
	}

	fileh=OpenFile(config, "r");
	if(fileh==null)
		return;

	while(!IsEndOfFile(fileh) && ReadFileLine(fileh, config, sizeof(config)))
	{
		Format(config, strlen(config) - 1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(StrContains(currentmap, config, false)>=0|| !StrContains(config, "all", false))
		{
			LogMessage("[FF2] %s is blacklisted and won't be teleported to spawn!", currentmap);
			SpawnTeleOnTriggerHurt = false;
			delete fileh;
			return;
		}
	}
	delete fileh;
}

public Action OnRoundSetup(Handle event, const char[] name, bool dontBroadcast)
{
	teamplay_round_start_TeleportToMultiMapSpawn(); // Cache spawns
	isCapping=false;
	if(changeGamemode==1)
	{
		EnableFF2();
	}
	else if(changeGamemode==2)
	{
		DisableFF2();
	}

	if(!GetConVarBool(cvarEnabled))
	{
		#if defined _steamtools_included
		if(EnabledDesc && steamtools && GetConVarBool(cvarSteamTools))
			Steam_SetGameDescription("Team Fortress");

		EnabledDesc = false;
		#endif
		Enabled2 = false;
		Enabled3 = false;
	}

	Enabled = Enabled2;
	if(!Enabled)
		return Plugin_Continue;

	if(FileExists("bNextMapToFF2"))
		DeleteFile("bNextMapToFF2");

	currentBossTeam = GetRandomInt(1, 2);
	switch(GetConVarInt(cvarForceBossTeam))
	{
		case 1:
			blueBoss=view_as<bool>(GetRandomInt(0, 1));

		case 2:
			blueBoss=false;

		default:
			blueBoss=true;
	}

	if(blueBoss)
	{
		SetTeamScore(view_as<int>(TFTeam_Red), GetTeamScore(OtherTeam));
		SetTeamScore(view_as<int>(TFTeam_Blue), GetTeamScore(BossTeam));
		OtherTeam = view_as<int>(TFTeam_Red);
		BossTeam = view_as<int>(TFTeam_Blue);
	}
	else
	{
		SetTeamScore(view_as<int>(TFTeam_Red), GetTeamScore(BossTeam));
		SetTeamScore(view_as<int>(TFTeam_Blue), GetTeamScore(OtherTeam));
		OtherTeam = view_as<int>(TFTeam_Blue);
		BossTeam = view_as<int>(TFTeam_Red);
	}

	playing = 0;
	playing2 = 0;
	playingboss = 0;
	playingmerc = 0;
	bosses = 0;
	for(int client; client<=MaxClients; client++)
	{
		Damage[client] = 0;
		Healing[client] = 0;
		uberTarget[client] = -1;
		emitRageSound[client] = true;
		AirstrikeDamage[client] = 0.0;
		KillstreakDamage[client] = 0.0;
		if(IsValidClient(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
		{
			playing++;
			if(!IsFakeClient(client))
				playing2++;

			if(IsBoss(client))
				playing2++;

			if(GetClientTeam(client)==BossTeam)
			{
				playingboss++;
			}
			else
			{
				playingmerc++;
			}
		}
	}

	if(GetClientCount()<=1 || playing<=1)  //Not enough players D:
	{
		FPrintToChatAll("%t", "needmoreplayers");
		SetConVarString(hostName, oldName);
		Enabled = false;
		DisableSubPlugins();
		SetControlPoint(true);
		return Plugin_Continue;
	}
	else if(RoundCount<arenaRounds)  //We're still in arena mode
	{
		FPrintToChatAll("%t", "arena_round", arenaRounds-RoundCount);
		Enabled = false;
		DisableSubPlugins();
		SetArenaCapEnableTime(60.0);
		CreateTimer(71.0, Timer_EnableCap, _, TIMER_FLAG_NO_MAPCHANGE);
		bool toRed;
		TFTeam team;
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && (team=view_as<TFTeam>(GetClientTeam(client)))>TFTeam_Spectator)
			{
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				if(toRed && team!=TFTeam_Red)
				{
					ChangeClientTeam(client, view_as<int>(TFTeam_Red));
				}
				else if(!toRed && team!=TFTeam_Blue)
				{
					ChangeClientTeam(client, view_as<int>(TFTeam_Blue));
				}
				SetEntProp(client, Prop_Send, "m_lifeState", 0);
				TF2_RespawnPlayer(client);
				toRed = !toRed;
			}
		}
		return Plugin_Continue;
	}

	for(int client; client<=MaxClients; client++)
	{
		Boss[client] = 0;
		BossSwitched[client] = false;
		if(IsValidClient(client) && IsPlayerAlive(client) && !(FF2flags[client] & FF2FLAG_HASONGIVED))
			TF2_RespawnPlayer(client);
	}

	Enabled = true;
	EnableSubPlugins();
	CheckArena();
	StopMusic();

	bool[] omit = new bool[MaxClients+1];
	Boss[0] = GetClientWithMostQueuePoints(omit, OtherTeam);
	omit[Boss[0]] = true;
	if(Enabled3)
	{
		Boss[MAXBOSSES] = GetClientWithoutBlacklist(omit, BossTeam);
		omit[Boss[MAXBOSSES]] = true;
		BossSwitched[MAXBOSSES] = true;

		if(GetConVarInt(cvarBvBChaos) > 1)
		{
			int bossCount = 0;
			while(bossCount < (GetConVarInt(cvarBvBChaos)-1))
			{
				bossCount++;
				Boss[bossCount] = GetClientWithMostQueuePoints(omit, OtherTeam);
				omit[Boss[bossCount]] = true;
				Boss[MAXBOSSES+bossCount] = GetClientWithoutBlacklist(omit, BossTeam);
				omit[Boss[MAXBOSSES+bossCount]] = true;
				BossSwitched[MAXBOSSES+bossCount] = true;
			}
		}
		CheatsUsed = true;
	}

	bool teamHasPlayers[TFTeam];
	for(int client=1; client<=MaxClients; client++)  //Find out if each team has at least one player on it
	{
		if(IsValidClient(client))
		{
			TFTeam team = view_as<TFTeam>(GetClientTeam(client));
			if(team > TFTeam_Spectator)
			{
				teamHasPlayers[team] = true;
			}

			if(teamHasPlayers[TFTeam_Blue] && teamHasPlayers[TFTeam_Red])
			{
				break;
			}
		}
	}

	if(!teamHasPlayers[TFTeam_Blue] || !teamHasPlayers[TFTeam_Red])  //If there's an empty team make sure it gets populated
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(IsValidClient(Boss[boss]))
				AssignTeam(Boss[boss], BossSwitched[boss] ? OtherTeam : BossTeam);
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !IsBoss(client) && (GetClientTeam(client)!=OtherTeam && !Enabled3))
				CreateTimer(0.1, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		return Plugin_Continue;  //NOTE: This is needed because OnRoundSetup gets fired a second time once both teams have players
	}

	PickCharacter(0, 0);
	if((Special[0]<0) || !BossKV[Special[0]])
	{
		LogToFile(eLog, "[!!!] Couldn't find a boss for index 0!");
		return Plugin_Continue;
	}

	if(Enabled3)
	{
		PickCharacter(MAXBOSSES, MAXBOSSES);
		if((Special[MAXBOSSES]<0) || !BossKV[Special[MAXBOSSES]])
		{
			LogToFile(eLog, "[!!!] Couldn't find a boss for index %i!", MAXBOSSES);
			return Plugin_Continue;
		}

		if(GetConVarInt(cvarBvBChaos) > 1)
		{
			int bossCount = 0;
			while(bossCount<(GetConVarInt(cvarBvBChaos)-1) && bossCount<(playing-1))
			{
				bossCount++;
				PickCharacter(bossCount, bossCount);
				if((Special[bossCount]<0) || !BossKV[Special[bossCount]])
				{
					LogToFile(eLog, "[!!!] Couldn't find a boss for index %i!", bossCount);
					return Plugin_Continue;
				}

				PickCharacter(MAXBOSSES+bossCount, MAXBOSSES+bossCount);
				if((Special[MAXBOSSES+bossCount]<0) || !BossKV[Special[MAXBOSSES+bossCount]])
				{
					LogToFile(eLog, "[!!!] Couldn't find a boss for index %i!", MAXBOSSES+bossCount);
					return Plugin_Continue;
				}
			}
		}
	}

	FindCompanion(0, playing, omit);  //Find companions for the boss!
	if(Enabled3)
	{
		FindCompanion(MAXBOSSES, playing, omit);
		if(GetConVarInt(cvarBvBChaos) > 1)
		{
			int bossCount = 0;
			while(bossCount<(GetConVarInt(cvarBvBChaos)-1) && bossCount<(playing-1))
			{
				bossCount++;
				FindCompanion(bossCount, playing, omit);
				FindCompanion(MAXBOSSES+bossCount, playing, omit);
			}
		}
	}

	for(int boss; boss<=MaxClients; boss++)
	{
		BossInfoTimer[boss][0] = INVALID_HANDLE;
		BossInfoTimer[boss][1] = INVALID_HANDLE;
		if(Boss[boss])
		{
			CreateTimer(0.3, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
			BossInfoTimer[boss][0] = CreateTimer(30.2, BossInfoTimer_Begin, boss, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	CreateTimer(0.4, StartIntroMusicTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer((GetConVarFloat(FindConVar("tf_arena_preround_time"))/2.857), StartResponseTimer, _, TIMER_FLAG_NO_MAPCHANGE);

	for(int entity=MaxClients+1; entity<MAXENTITIES; entity++)
	{
		if(!IsValidEntity(entity))
			continue;

		char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!strcmp(classname, "func_regenerate"))
		{
			AcceptEntityInput(entity, "Kill");
		}
		else if(!strcmp(classname, "func_respawnroomvisualizer"))
		{
			AcceptEntityInput(entity, "Disable");
		}
	}

	if(GetConVarBool(cvarToggleBoss))
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client))
				continue;

			ClientQueue[client][0] = client;
			ClientQueue[client][1] = QueuePoints[client];
		}

		SortCustom2D(ClientQueue, sizeof(ClientQueue), SortQueueDesc);

		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client) || IsBoss(client))
				continue;

			if(ToggleBoss[client] != Setting_On)
			{
				char nick[64];
				GetClientName(client, nick, sizeof(nick));
				if(ToggleBoss[client] == Setting_Off)
				{
					FPrintToChat(client, "%t", "FF2 Toggle Disabled Notification");
				}
				else if(ToggleBoss[client] == Setting_Temp)
				{
					FPrintToChat(client, "%t", "FF2 Toggle Disabled Notification For Map");
				}
				else
				{
					Handle clientPack = CreateDataPack();
					WritePackCell(clientPack, client);
					CreateTimer(GetConVarFloat(cvarFF2TogglePrefDelay), BossMenuTimer, clientPack);
				}
				continue;
			}

			ClientID[client] = ClientQueue[client][0];
			ClientPoint[client] = ClientQueue[client][1];

			if(ToggleBoss[client] == Setting_On)
			{
				int index = -1;
				for(int i=1; i<MAXPLAYERS+1; i++)
				{
					if(ClientID[i] == client)
					{
						index = i;
						break;
					}
				}
				if(index > 0)
				{
					FPrintToChat(client, "%t", "FF2 Toggle Queue Notification", index, QueuePoints[client]);
				}
				else
				{
					FPrintToChat(client, "%t", "FF2 Toggle Enabled Notification");
   				}
				continue;
			}
		}
	}

	healthcheckused = 0;
	firstBlood = true;
	CheatsUsed = false;
	ShowHealthText = false;
	return Plugin_Continue;
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;

	CreateTimer(0.5, MessageTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Timer_Move, _, TIMER_FLAG_NO_MAPCHANGE);
	bool isBossAlive;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			isBossAlive = true;
			SetEntityMoveType(Boss[boss], MOVETYPE_NONE);
		}
	}

	if(!isBossAlive)
		return Plugin_Continue;

	playing = 0;
	playing2 = 0;
	playingboss = 0;
	playingmerc = 0;
	bosses = 0;
	int medigun;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			CreateTimer(2.0, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			if(!IsBoss(client) && IsPlayerAlive(client))
			{
				playing++;
				CreateTimer(0.15, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);  //TODO:  Is this needed?
				if(!IsFakeClient(client))
					playing2++;

				if(TF2_GetPlayerClass(client) == TFClass_Medic)
				{
					medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(IsValidEntity(medigun))
						SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 0.4);
				}

				if(GetClientTeam(client) == BossTeam)
				{
					playingboss++;
				}
				else
				{
					playingmerc++;
				}
			}
			else if(IsBoss(client))
			{
				bosses++;
			}
		}
	}

	float players = 1.0;
	if(Enabled3)
	{
		players += playingmerc + bosses - playingboss*0.45;
		float players2 = playingboss + 1 + bosses - playingmerc*0.45;
		for(int boss; boss<=MaxClients; boss++)
		{
			if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
			{
				if(BossSwitched[boss])
				{
					BossHealthMax[boss] = ParseFormula(boss, "health_formula", "(((760.8+n)*(n-1))^1.0341)+2046", RoundFloat(Pow((760.8+players2)*(players2-1.0), 1.0341)+2046.0));
				}
				else
				{
					BossHealthMax[boss] = ParseFormula(boss, "health_formula", "(((760.8+n)*(n-1))^1.0341)+2046", RoundFloat(Pow((760.8+players)*(players-1.0), 1.0341)+2046.0));
				}
				if(BossHealthMax[boss]*BossLivesMax[boss] < 350)
					BossHealthMax[boss] = RoundToFloor(350.0/BossLivesMax[boss]);

				BossHealth[boss] = BossHealthMax[boss]*BossLivesMax[boss];
				BossHealthLast[boss] = BossHealth[boss];
			}
		}
	}
	else
	{
		players += playing;
		for(int boss; boss<=MaxClients; boss++)
		{
			if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
			{
				BossHealthMax[boss] = ParseFormula(boss, "health_formula", "(((760.8+n)*(n-1))^1.0341)+2046", RoundFloat(Pow((760.8+players)*(players-1.0), 1.0341)+2046.0));
				BossHealth[boss] = BossHealthMax[boss]*BossLivesMax[boss];
				BossHealthLast[boss] = BossHealth[boss];
			}
		}
	}

	CreateTimer(0.2, BossTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, Timer_StartRound, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, GlobalTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	if(!PointType)
		SetControlPoint(false);

	if(GetConVarBool(cvarNameChange))
	{
		char newName[256], bossName[64];
		SetConVarString(hostName, oldName);
		GetBossSpecial(Special[0], bossName, sizeof(bossName));
		Format(newName, sizeof(newName), "%s | %s", oldName, bossName);
		SetConVarString(hostName, newName);
	}
	return Plugin_Continue;
}

public Action Timer_EnableCap(Handle timer)
{
	if((Enabled || Enabled2) && CheckRoundState()==-1)
	{
		SetControlPoint(true);
		if(checkDoors)
		{
			int ent=-1;
			while((ent=FindEntityByClassname2(ent, "func_door"))!=-1)
			{
				AcceptEntityInput(ent, "Open");
				AcceptEntityInput(ent, "Unlock");
			}

			if(doorCheckTimer==INVALID_HANDLE)
			{
				doorCheckTimer=CreateTimer(5.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action BossInfoTimer_Begin(Handle timer, any boss)
{
	BossInfoTimer[boss][0]=INVALID_HANDLE;
	BossInfoTimer[boss][1]=CreateTimer(0.2, BossInfoTimer_ShowInfo, boss, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action BossInfoTimer_ShowInfo(Handle timer, any boss)
{
	if(!IsValidClient(Boss[boss]))
	{
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if(bossHasReloadAbility[boss])
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		if(bossHasRightMouseAbility[boss])
		{
			FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t\n%t", "ff2_buttons_reload", "ff2_buttons_rmb");
		}
		else
		{
			FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t", "ff2_buttons_reload");
		}
	}
	else if(bossHasRightMouseAbility[boss])
	{
		SetHudTextParams(0.75, 0.7, 0.15, 255, 255, 255, 255);
		FF2_ShowSyncHudText(Boss[boss], abilitiesHUD, "%t", "ff2_buttons_rmb");
	}
	else
	{
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_CheckDoors(Handle timer)
{
	if(!checkDoors)
	{
		doorCheckTimer=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if((!Enabled && CheckRoundState()!=-1) || (Enabled && CheckRoundState()!=1))
	{
		return Plugin_Continue;
	}

	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "func_door"))!=-1)
	{
		AcceptEntityInput(entity, "Open");
		AcceptEntityInput(entity, "Unlock");
	}
	return Plugin_Continue;
}

public void CheckArena()
{
	float PointTotal=float(PointTime+PointDelay*(playing-1));
	if(PointType==0 || PointTotal<0)
	{
		SetArenaCapEnableTime(0.0);
		SetControlPoint(false);
	}
	else
	{
		SetArenaCapEnableTime(PointTotal);
	}
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	RoundCount++;
	SapperMinion = false;
	LastMan = true;
	if(HasSwitched)
		HasSwitched = false;

	if(playing>=GetConVarInt(cvarDuoMin) && !DuoMin)  // Check if theres enough players for companions
	{
		DuoMin = true;
	}
	else if(DuoMin)
	{
		DuoMin = false;
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && strlen(xIncoming[client]))
			{
				if(!CheckValidBoss(client, xIncoming[client], true))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = '\0';
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
				}
			}
		}
	}

	if(!Enabled)
	{
		Enabled3 = false;
		return Plugin_Continue;
	}

	if(GetConVarInt(cvarBossLog)>0 && GetConVarInt(cvarBossLog)<=playing2 && !CheatsUsed)
	{
		// Variables
		char bossName[64], FormatedTime[64], MapName[64], Result[64], PlayerName[64], Authid[64];

		// Set variables
		int CurrentTime = GetTime();
		FormatTime(FormatedTime, 100, "%X", CurrentTime);
		GetCurrentMap(MapName, sizeof(MapName));
		Format(Result, sizeof(Result), GetEventInt(event, "team")==BossTeam ? "won" : "loss");
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsBoss(client))
			{
				int boss=Boss[client];
				if(!IsFakeClient(client))
				{
					GetClientName(Boss[boss], PlayerName, sizeof(PlayerName));
					GetClientAuthId(Boss[boss], AuthId_Steam2, Authid, sizeof(Authid), false);
				}
				else
				{
					Format(PlayerName, sizeof(PlayerName), "Bot");
					Format(Authid, sizeof(Authid), "Bot");
				}
				KvRewind(BossKV[Special[boss]]);
				KvGetString(BossKV[Special[boss]], "filename", bossName, sizeof(bossName));
				BuildPath(Path_SM, bLog, sizeof(bLog), "%s/%s.txt", BossLogPath, bossName);
			}
		}

		// Write
		Handle bossLog = OpenFile(bLog, "a+");

		WriteFileLine(bossLog, "%s on %s - %s <%s> has %s", FormatedTime, MapName, PlayerName, Authid, Result);
		WriteFileLine(bossLog, "");
		CloseHandle(bossLog);
	}

	executed = false;
	executed2 = false;
	int bossWin = 0;
	float bonusRoundTime = GetConVarFloat(FindConVar("mp_bonusroundtime"))-0.5;
	char sound[PLATFORM_MAX_PATH];
	if(GetEventInt(event, "team") == BossTeam)
	{
		bossWin = 1;
		if(RandomSound("sound_win", sound, sizeof(sound)))
			EmitSoundToAllExcept(sound);

		if(RandomSound("sound_outtromusic_win", sound, sizeof(sound)))
		{
			EmitMusicToAllExcept(sound);
		}
		else if(RandomSound("sound_outtromusic", sound, sizeof(sound)))
		{
			EmitMusicToAllExcept(sound);
		}
	}
	else if(GetEventInt(event, "team") == OtherTeam)
	{
		if(Enabled3)
		{
			if(RandomSound("sound_win", sound, sizeof(sound), MAXBOSSES))
				EmitSoundToAllExcept(sound);
		}

		if(RandomSound("sound_outtromusic_lose", sound, sizeof(sound)))
		{
			EmitMusicToAllExcept(sound);
		}
		else if(RandomSound("sound_outtromusic", sound, sizeof(sound)))
		{
			EmitMusicToAllExcept(sound);
		}
	}
	else
	{
		bossWin = -1;
		if(RandomSound("sound_stalemate", sound, sizeof(sound), MAXBOSSES))
			EmitSoundToAllExcept(sound);

		if(RandomSound("sound_outtromusic_stalemate", sound, sizeof(sound)))
		{
			EmitMusicToAllExcept(sound);
		}
		else if(RandomSound("sound_outtromusic_lose", sound, sizeof(sound)))
		{
			EmitMusicToAllExcept(sound);
		}
		else if(RandomSound("sound_outtromusic", sound, sizeof(sound)))
		{
			EmitMusicToAllExcept(sound);
		}
	}

	if(Enabled3 && bossWin>-1)
	{
		int winningTeam = GetEventInt(event, "team");
		int target;
		char text[MAXPLAYERS+1][128], bossName[64], lives[8];
		for(int boss; boss<=MaxClients; boss++)
		{
			target = Boss[boss];
			if(IsValidClient(target))
			{
				if(GetClientTeam(target) == winningTeam)
				{
					strcopy(bossName, sizeof(bossName), "=Failed name=");
					BossLives[boss]>1 ? Format(lives, sizeof(lives), "x%i", BossLives[boss]) : strcopy(lives, 2, "");
					for(int client=1; client<=MaxClients; client++)
					{
						if(IsValidClient(client))
						{
							GetBossSpecial(Special[boss], bossName, sizeof(bossName), client);
							Format(text[client], sizeof(text[]), "%s\n%t", text[client], "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
							FPrintToChat(client, "%t", "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
						}
					}
				}
			}
		}

		if(winningTeam == view_as<int>(TFTeam_Red))
		{
			SetHudTextParams(-1.0, 0.2, bonusRoundTime, 255, 50, 50, 255);
		}
		else
		{
			SetHudTextParams(-1.0, 0.2, bonusRoundTime, 50, 50, 255, 255);
		}
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
				FF2_ShowHudText(client, -1, "%s", text[client]);
		}
	}

	StopMusic();
	DrawGameTimer = INVALID_HANDLE;

	bool isBossAlive;
	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(Boss[client]))
		{
			SetClientGlow(Boss[client], 0.0, 0.0);
			SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal
			if(IsPlayerAlive(Boss[client]))
				isBossAlive = true;

			for(int slot=1; slot<8; slot++)
			{
				BossCharge[client][slot] = 0.0;
			}
			bossHasReloadAbility[client] = false;
			bossHasRightMouseAbility[client] = false;
			SaveClientStats(client);
		}
		else if(IsValidClient(client))
		{
			SetClientGlow(client, 0.0, 0.0);
			hadshield[client] = false;
			shield[client] = 0;
			detonations[client] = 0;
			AirstrikeDamage[client] = 0.0;
			KillstreakDamage[client] = 0.0;
			HazardDamage[client] = 0.0;
			SapperCooldown[client] = GetConVarFloat(cvarSapperStart);
			SaveClientStats(client);
		}

		for(int timer; timer<=1; timer++)
		{
			if(BossInfoTimer[client][timer]!=INVALID_HANDLE)
			{
				KillTimer(BossInfoTimer[client][timer]);
				BossInfoTimer[client][timer]=INVALID_HANDLE;
			}
		}
	}

	bool botBoss;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsBoss(boss) && IsFakeClient(boss))
		{
			botBoss = true;
			break;
		}
	}

	bool gainedPoint[MAXPLAYERS+1];
	int statPlayers = GetConVarInt(cvarStatPlayers);
	if(!botBoss && statPlayers<=playing2 && statPlayers>0)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(IsBoss(boss))
			{
				if(bossWin > 0)
				{
					AddClientStats(boss, Cookie_BossWins, 1);
					gainedPoint[boss] = true;
				}
				else if(bossWin == 0)
				{
					AddClientStats(boss, Cookie_BossLosses, 1);
					gainedPoint[boss] = true;
				}
			}
		}
	}

	int StatWin2Lose = GetConVarInt(cvarStatWin2Lose);
	if(StatWin2Lose==2 || StatWin2Lose>3)
	{
		for(int boss=1; boss<=MaxClients; boss++)
		{
			if(IsBoss(boss) && !IsFakeClient(boss))
			{
				if(gainedPoint[boss] || StatWin2Lose>2)
				{
					FPrintToChat(boss, "%t", "Win To Lose Self", BossWins[boss], BossLosses[boss]);
					CSkipNextClient(boss);
					FPrintToChatAll("%t", "Win To Lose", boss, BossWins[boss], BossLosses[boss]);
				}
				else
				{
					for(int client=1; client<=MaxClients; client++)
					{
						if(IsValidClient(client) && CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true))
							FPrintToChat(client, "%t", "Win To Lose", boss, BossWins[boss], BossLosses[boss]);
					}
				}
			}
		}
	}
	else if(StatWin2Lose > -1)
	{
		for(int boss=1; boss<=MaxClients; boss++)
		{
			if(IsBoss(boss) && !IsFakeClient(boss))
			{
				if(StatWin2Lose>0 && (gainedPoint[boss] || StatWin2Lose>2))
				{
					FPrintToChat(boss, "%t", "Win To Lose Self", BossWins[boss], BossLosses[boss]);
				}
				for(int client=1; client<=MaxClients; client++)
				{
					if(CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && IsValidClient(client) && (client!=boss || !(StatWin2Lose>0 && (gainedPoint[boss] || StatWin2Lose>3))))
						FPrintToChat(client, "%t", "Win To Lose", boss, BossWins[boss], BossLosses[boss]);
				}
			}
		}
	}

	if(!Enabled3 && isBossAlive)
	{
		int target;
		char text[MAXPLAYERS+1][128], bossName[64], lives[8];
		for(int boss; boss<=MaxClients; boss++)
		{
			target = Boss[boss];
			if(IsValidClient(target))
			{
				strcopy(bossName, sizeof(bossName), "=Failed name=");
				BossLives[boss]>1 ? Format(lives, sizeof(lives), "x%i", BossLives[boss]) : strcopy(lives, 2, "");
				for(int client=1; client<=MaxClients; client++)
				{
					if(IsValidClient(client))
					{
						GetBossSpecial(Special[boss], bossName, sizeof(bossName), client);
						Format(text[client], sizeof(text[]), "%s\n%t", text[client], "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
						FPrintToChat(client, "%t", "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
					}
				}
			}
		}

		SetHudTextParams(-1.0, 0.2, bonusRoundTime, 255, 255, 255, 255);
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
				FF2_ShowHudText(client, -1, "%s", text[client]);
		}

		if(!bossWin && RandomSound("sound_fail", sound, sizeof(sound)))
			EmitSoundToAllExcept(sound);
	}

	int top[3];
	Damage[0] = 0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || Damage[client]<=0 || IsBoss(client))
			continue;

		if(Damage[client]>=Damage[top[0]])
		{
			top[2] = top[1];
			top[1] = top[0];
			top[0] = client;
		}
		else if(Damage[client]>=Damage[top[1]])
		{
			top[2]=top[1];
			top[1]=client;
		}
		else if(Damage[client]>=Damage[top[2]])
		{
			top[2]=client;
		}
	}

	if(Damage[top[0]]>9000)
	{
		CreateTimer(1.0, Timer_NineThousand, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	if(!botBoss && statPlayers>0)
	{
		if(statPlayers <= playing2)
		{
			AddClientStats(top[0], Cookie_PlayerMvps, 1);
		}
		if(statPlayers*2 <= playing2)
		{
			AddClientStats(top[1], Cookie_PlayerMvps, 1);
		}
		if(statPlayers*3 <= playing2)
		{
			AddClientStats(top[2], Cookie_PlayerMvps, 1);
		}
	}

	char leaders[3][32];
	for(int i; i<=2; i++)
	{
		if(IsValidClient(top[i]))
		{
			GetClientName(top[i], leaders[i], 32);
		}
		else
		{
			Format(leaders[i], 32, "---");
			top[i] = 0;
		}
	}

	SetHudTextParams(-1.0, 0.3, bonusRoundTime, 255, 255, 255, 255);
	PrintCenterTextAll("");

	char text[128];
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			//TODO:  Clear HUD text here
			if(IsBoss(client) && GetClientTeam(client)==GetEventInt(event, "team"))
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "boss_win");
			}
			else if(IsBoss(client))
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "boss_lose");
			}
			else
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "damage_fx", Damage[client], "scores", RoundFloat(Damage[client]/PointsInterval2));
			}
		}
	}

	if(!Enabled3)
	{
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
		CreateTimer(bonusRoundTime, Timer_CheckBossVsBoss, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	if(GetConVarInt(cvarBossVsBoss) > 0)
	{
		if(GetRandomInt(0, 99) < GetConVarInt(cvarBossVsBoss))
		{
			CreateTimer(bonusRoundTime-0.5, Timer_SetEnabled3, true, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			CreateTimer(bonusRoundTime-0.5, Timer_SetEnabled3, false, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		Enabled3 = false;
	}

	if(ReloadFF2)
	{
		ServerCommand("sm plugins reload freak_fortress_2");
		return Plugin_Continue;
	}

	if(LoadCharset)
	{
		LoadCharset=false;
		FindCharacters();
		strcopy(FF2CharSetString, 2, "");
	}

	if(ReloadWeapons)
	{
		CacheWeapons();
		ReloadWeapons=false;
	}

	if(ReloadConfigs)
	{
		CacheWeapons();
		CheckToChangeMapDoors();
		CheckToTeleportToSpawn();
		FindCharacters();
		ReloadConfigs = false;
	}

	CreateTimer(3.0, Timer_CalcQueuePoints, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Continue;
}

public Action Timer_SetEnabled3(Handle timer, bool toggle)
{
	Enabled3 = toggle;
	return Plugin_Continue;
}

public Action Timer_CheckBossVsBoss(Handle timer)
{
	if(!Enabled3)
		return Plugin_Continue;

	int team = OtherTeam;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(!IsPlayerAlive(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
			{
				ChangeClientTeam(client, team);
				team = team==BossTeam ? OtherTeam : BossTeam;
			}
		}
	}

	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), mp_teams_unbalance_limit);
	return Plugin_Continue;
}

public Action BossMenuTimer(Handle timer, any clientpack)
{
	int client;
	ResetPack(clientpack);
	client = ReadPackCell(clientpack);
	CloseHandle(clientpack);
	if(ToggleBoss[client]!=Setting_On && ToggleBoss[client]!=Setting_Off)
	{
		BossMenu(client, 0);
	}
}

public Action CompanionMenu(int client, int args)
{
	if(IsValidClient(client) && GetConVarBool(cvarDuoBoss))
	{
		Handle menu = CreateMenu(MenuHandlerCompanion);
		SetGlobalTransTarget(client);
		SetMenuTitle(menu, "%t", "FF2 Companion Toggle Menu Title");

		char menuoption[128];
		Format(menuoption, sizeof(menuoption), "%t", "Enable Companion Selection");
		AddMenuItem(menu, "FF2 Companion Toggle Menu", menuoption);
		Format(menuoption, sizeof(menuoption), "%t", "Disable Companion Selection");
		AddMenuItem(menu, "FF2 Companion Toggle Menu", menuoption);
		Format(menuoption, sizeof(menuoption), "%t", "Disable Companion Selection For Map");
		if(Enabled2)
		{
			AddMenuItem(menu, "FF2 Companion Toggle Menu", menuoption);
		}
		else
		{
			AddMenuItem(menu, "FF2 Companion Toggle Menu", menuoption, ITEMDRAW_DISABLED);
		}

		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
	return Plugin_Handled;
}

public int MenuHandlerCompanion(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		int choice = param2 + 1;
		ToggleDuo[param1] = view_as<SettingPrefs>(choice);

		switch(choice)
		{
			case 1:
				FPrintToChat(param1, "%t", "FF2 Companion Enabled");
			case 2:
				FPrintToChat(param1, "%t", "FF2 Companion Disabled");
			case 3:
				FPrintToChat(param1, "%t", "FF2 Companion Disabled For Map");
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action BossMenu(int client, int args)
{
	if(IsValidClient(client) && GetConVarBool(cvarToggleBoss))
	{
		Handle menu = CreateMenu(MenuHandlerBoss);
		SetGlobalTransTarget(client);
		SetMenuTitle(menu, "%t", "FF2 Toggle Menu Title");

		char menuoption[128];
		Format(menuoption, sizeof(menuoption), "%t", "Enable Queue Points");
		AddMenuItem(menu, "Boss Toggle", menuoption);
		Format(menuoption, sizeof(menuoption), "%t", "Disable Queue Points");
		AddMenuItem(menu, "Boss Toggle", menuoption);
		Format(menuoption, sizeof(menuoption), "%t", "Disable Queue Points For This Map");
		if(Enabled2)
		{
			AddMenuItem(menu, "Boss Toggle", menuoption);
		}
		else
		{
			AddMenuItem(menu, "Boss Toggle", menuoption, ITEMDRAW_DISABLED);
		}

		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	}
	return Plugin_Handled;
}

public int MenuHandlerBoss(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		int choice = param2 + 1;
		ToggleBoss[param1] = view_as<SettingPrefs>(choice);

		switch(choice)
		{
			case 1:
				FPrintToChat(param1, "%t", "FF2 Toggle Enabled Notification");
			case 2:
				FPrintToChat(param1, "%t", "FF2 Toggle Disabled Notification");
			case 3:
				FPrintToChat(param1, "%t", "FF2 Toggle Disabled Notification For Map");
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action SkipBossPanel(int client)
{
	if(!Enabled2)
		return Plugin_Continue;

	Handle panel = CreatePanel();
	char text[128];
	SetGlobalTransTarget(client);
	Format(text, sizeof(text), "%t", "to0_resetpts");

	SetPanelTitle(panel, text);
	Format(text, sizeof(text), "%t", "Yes");
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "No");
	DrawPanelItem(panel, text);
	SendPanelToClient(panel, client, SkipBossPanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public int SkipBossPanelH(Handle menu, MenuAction action, int client, int position)
{
	if(action==MenuAction_Select && position==1)
	{
		if(shortname[client] == client)
		{
			FPrintToChat(client, "%t", "to0_resetpts");
		}
		if(QueuePoints[client] >= 10)
			QueuePoints[client] -= 10;
	}
}

public int SortQueueDesc(const x[], const y[], const array[][], Handle data)
{
	if(x[1] > y[1])
		return -1;
	else if(x[1] < y[1])
		return 1;
	return 0;
}

public Action OnBroadcast(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	char sound[PLATFORM_MAX_PATH];
	GetEventString(event, "sound", sound, sizeof(sound));
	if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false) || !StrContains(sound, "Announcer.AM_RoundStartRandom", false))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Timer_NineThousand(Handle timer)
{
	EmitSoundToAll("saxton_hale/9000.wav", _, _, _, _, _, _, _, _, _, false);
	EmitSoundToAllExcept("saxton_hale/9000.wav", _, SNDCHAN_VOICE, _, _, _, _, _, _, _, false);
	return Plugin_Continue;
}

public Action Timer_CalcQueuePoints(Handle timer)
{
	int damage, damage2;
	int[] add_points = new int[MaxClients+1];
	int[] add_points2 = new int[MaxClients+1];
	for(int client=1; client<=MaxClients; client++)
	{
		if(view_as<int>(ToggleBoss[client])>1 && GetConVarBool(cvarToggleBoss)) // Do not give queue points to those who have ff2 bosses disabled
			continue;

		if(IsValidClient(client))
		{
			damage=Damage[client];
			damage2=Damage[client];
			Handle event=CreateEvent("player_escort_score", true);
			SetEventInt(event, "player", client);

			int points;
			while(damage-PointsInterval>0)
			{
				damage-=PointsInterval;
				points++;
			}
			SetEventInt(event, "points", points);
			FireEvent(event);

			if(IsBoss(client))
			{
				if(((GetBossIndex(client)==0 && GetBossIndex(client)==MAXBOSSES) && GetConVarBool(cvarDuoRestore)) || !GetConVarBool(cvarDuoRestore))
				{
					add_points[client]=-QueuePoints[client];
					add_points2[client]=add_points[client];
				}
			}
			else if(GetClientTeam(client)>view_as<int>(TFTeam_Spectator) || SpecForceBoss)
			{
				if(damage2>=PointsDamage)
				{
					if(PointsExtra>PointsMin)
					{
						if(points>(PointsExtra-PointsMin))
						{
							add_points[client]=PointsExtra;
							add_points2[client]=PointsExtra;
						}
						else
						{
							add_points[client]=PointsMin+points;
							add_points2[client]=PointsMin+points;
						}
					}
					else
					{
						add_points[client]=PointsMin;
						add_points2[client]=PointsMin;
					}
				}
			}
		}
	}

	Action action;
	Call_StartForward(OnAddQueuePoints);
	Call_PushArrayEx(add_points2, MaxClients+1, SM_PARAM_COPYBACK);
	Call_Finish(action);
	switch(action)
	{
		case Plugin_Stop, Plugin_Handled:
		{
			return;
		}
		case Plugin_Changed:
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(IsFakeClient(client))
					{
						QueuePoints[client] += RoundFloat(add_points2[client]*0.5);
					}

					if(add_points2[client]>0)
					{
						FPrintToChat(client, "%t", "add_points", add_points2[client]);
					}
					QueuePoints[client] += add_points2[client];
				}
			}
		}
		default:
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(IsFakeClient(client))
					{
						QueuePoints[client] += RoundFloat(add_points[client]*0.5);
					}

					if(add_points[client]>0)
					{
						FPrintToChat(client, "%t", "add_points", add_points[client]);
					}
					QueuePoints[client] += add_points[client];
				}
			}
		}
	}
}

public Action StartResponseTimer(Handle timer)
{
	char sound[PLATFORM_MAX_PATH];
	if(Enabled3)
	{
		char sound2[PLATFORM_MAX_PATH];
		bool isIntro = RandomSound("sound_begin", sound, sizeof(sound));
		bool isIntro2 = RandomSound("sound_begin", sound2, sizeof(sound2), MAXBOSSES);
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && ToggleVoice[client])
			{
				if(GetClientTeam(client)==BossTeam && isIntro2)
				{
					EmitSoundToClient(client, sound2);
				}
				else if(isIntro)
				{
					EmitSoundToClient(client, sound);
				}
			}
		}
		return Plugin_Continue;
	}

	if(RandomSound("sound_begin", sound, sizeof(sound)))
		EmitSoundToAllExcept(sound);

	return Plugin_Continue;
}

public Action StartIntroMusicTimer(Handle timer)
{
	char sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_intromusic", sound, sizeof(sound)))
	{
		EmitMusicToAllExcept(sound);
	}
	return Plugin_Continue;
}

public Action Timer_PrepareBGM(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(!Enabled || CheckRoundState()!=1 || !client || MapHasMusic() || StrEqual(currentBGM[client], "ff2_stop_music", true))
	{
		MusicTimer[client]=INVALID_HANDLE;
		return;
	}

	KvRewind(BossKV[Special[0]]);
	if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH];
		int index;
		do
		{
			index++;
			Format(music, 10, "time%i", index);
		}
		while(KvGetFloat(BossKV[Special[0]], music)>1);

		char lives[256];
		for(int i; i<19; i++)
		{
			index=GetRandomInt(1, index-1);
			Format(lives, sizeof(lives), "life%i", index);
			KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
			if(StringToInt(lives))
			{
				if(StringToInt(lives)!=BossLives[Special[0]])
				{
					continue;
				}
			}
			break;
		}
		Format(music, 10, "time%i", index);
		float time=KvGetFloat(BossKV[Special[0]], music);
		Format(music, 10, "path%i", index);
		KvGetString(BossKV[Special[0]], music, music, sizeof(music));

		cursongId[client]=index;

		// manual song ID
		char id3[4][256];
		Format(id3[0], sizeof(id3[]), "name%i", index);
		KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
		Format(id3[1], sizeof(id3[]), "artist%i", index);
		KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));

		char temp[PLATFORM_MAX_PATH];
		Format(temp, sizeof(temp), "sound/%s", music);
		if(FileExists(temp, true))
		{
			PlayBGM(client, music, time, _, id3[2], id3[3]);
		}
		else
		{
			char bossName[64];
			KvRewind(BossKV[Special[0]]);
			KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
			LogToFile(eLog, "[Boss] Character %s is missing BGM file '%s'!", bossName, temp);
			FF2Dbg("{red}MALFUNCTION! NEED INPUT!");
			if(MusicTimer[client]!=INVALID_HANDLE)
			{
				KillTimer(MusicTimer[client]);
			}
		}
	}
}

void PlayBGM(int client, char[] music, float time, bool loop=true, char[] name="", char[] artist="")
{
	Action action;
	Call_StartForward(OnMusic);
	char temp[3][PLATFORM_MAX_PATH];
	float time2=time;
	strcopy(temp[0], sizeof(temp[]), music);
	strcopy(temp[1], sizeof(temp[]), name);
	strcopy(temp[2], sizeof(temp[]), artist);
	Call_PushStringEx(temp[0], sizeof(temp[]), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushFloatRef(time2);
	Call_Finish(action);
	switch(action)
	{
		case Plugin_Stop, Plugin_Handled:
		{
			FF2Dbg("NEED INPUT!");
			return;
		}
		case Plugin_Changed:
		{
			strcopy(music, PLATFORM_MAX_PATH, temp[0]);
			time=time2;
			FF2Dbg("OOO... INPUT! %s | %f", music, time);
		}
	}

	Format(temp[0], sizeof(temp[]), "sound/%s", music);
	if(FileExists(temp[0], true))
	{
		bool unknown1 = true;
		bool unknown2 = true;
		if(ToggleMusic[client])
		{
			strcopy(currentBGM[client], PLATFORM_MAX_PATH, music);

			// EmitSoundToClient can sometimes not loop correctly
			// 'playgamesound' can rarely not stop correctly
			// 'play' can be stopped or interrupted by other things
			// # before filepath effects music slider but can't stop correctly most of the time

			ClientCommand(client, "playgamesound \"%s\"", music);
			if(time>1)
			{
				MusicTimer[client]=CreateTimer(time, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		if(!name[0])
		{
			Format(name[0], 256, "%T", "unknown_song", client);
			unknown1 = false;
		}
		if(!artist[0])
		{
			Format(artist[0], 256, "%T", "unknown_artist", client);
			unknown2 = false;
		}
		if(GetConVarInt(cvarSongInfo)==1 || (unknown1 && unknown2 && loop && GetConVarInt(cvarSongInfo)==0))
		{
			FPrintToChat(client, "%t", "track_info", artist, name);
		}
	}
	else
	{
		char bossName[64];
		KvRewind(BossKV[Special[0]]);
		KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
		PrintToServer("[FF2 Bosses] Character %s is missing BGM file '%s'!", bossName, music);
	}
}

void StartMusic(int client=0)
{
	if(!Enabled)
		return;

	if(client<=0)  //Start music for all clients
	{
		StopMusic();
		for(int target; target<=MaxClients; target++)
		{
			playBGM[target]=true;  //This includes the 0th index
		}
		CreateTimer(0.1, Timer_PrepareBGM, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		StopMusic(client);
		playBGM[client]=true;
		CreateTimer(0.1, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

void StopMusic(int client=0, bool permanent=false)
{
	if(client<=0)  //Stop music for all clients
	{
		if(permanent)
		{
			playBGM[0]=false;
		}

		for(client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				if(!currentBGM[client])
				{
					FF2Dbg("{green}MALFUNCTION! NEED INPUT!");
				}
				StopSound(client, SNDCHAN_AUTO, currentBGM[client]);

				if(MusicTimer[client]!=INVALID_HANDLE)
				{
					FF2Dbg("TERMINATING INPUT!");
					KillTimer(MusicTimer[client]);
					MusicTimer[client]=INVALID_HANDLE;
				}
			}

			//strcopy(currentBGM[client], PLATFORM_MAX_PATH, "");
			if(permanent)
			{
				playBGM[client]=false;
			}
		}
	}
	else
	{
		if(!currentBGM[client])
		{
			FF2Dbg("{green}MALFUNCTION! NEED INPUT!");
		}
		StopSound(client, SNDCHAN_AUTO, currentBGM[client]);
		StopSound(client, SNDCHAN_AUTO, currentBGM[client]);

		if(MusicTimer[client]!=INVALID_HANDLE)
		{
			FF2Dbg("END INPUT FOR %N!", client);
			KillTimer(MusicTimer[client]);
			MusicTimer[client]=INVALID_HANDLE;
		}

		strcopy(currentBGM[client], PLATFORM_MAX_PATH, "");
		if(permanent)
		{
			playBGM[client]=false;
		}
	}
}

stock void EmitSoundToAllExcept(const char[] sample, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=false, float soundtime=0.0)
{
	int[] clients = new int[MaxClients];
	int total;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(ToggleVoice[client])
				clients[total++]=client;
		}
	}

	if(!total)
		return;

	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

stock void EmitMusicToAllExcept(const char[] sample, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=false, float soundtime=0.0)
{
	int[] clients = new int[MaxClients];
	int total;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(ToggleMusic[client])
				clients[total++] = client;
		}
	}

	if(!total)
		return;

	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

void SetupClientPreferences(int client)
{
	if(!IsValidClient(client))
		return;

	if(IsFakeClient(client))
	{
		QueuePoints[client] = 0;
		ToggleMusic[client] = false;
		ToggleVoice[client] = false;
		ToggleInfo[client] = false;
		ToggleDuo[client] = Setting_On;
		ToggleBoss[client] = Setting_On;
	}

	if(!AreClientCookiesCached(client))
	{
		QueuePoints[client] = 0;
		ToggleMusic[client] = true;
		ToggleVoice[client] = true;
		ToggleInfo[client] = true;
		ToggleDuo[client] = Setting_Undef;
		ToggleBoss[client] = Setting_Undef;
	}

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);

	QueuePoints[client] = StringToInt(cookieValues[0][0]);
	ToggleMusic[client] = view_as<bool>(StringToInt(cookieValues[1][0]));
	ToggleVoice[client] = view_as<bool>(StringToInt(cookieValues[2][0]));
	ToggleInfo[client] = view_as<bool>(StringToInt(cookieValues[3][0]));
	ToggleDuo[client] = view_as<SettingPrefs>(StringToInt(cookieValues[4][0]));
	ToggleBoss[client] = view_as<SettingPrefs>(StringToInt(cookieValues[5][0]));

	if(ToggleDuo[client] == Setting_Temp)
		ToggleDuo[client] = Setting_Undef;

	if(ToggleBoss[client] == Setting_Temp)
		ToggleBoss[client] = Setting_On;
}

void SaveClientPreferences(int client)
{
	if(!IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client))
		return;

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);

	Format(cookies, sizeof(cookies), "%i %i %i %i %i %i %s %s", QueuePoints[client], ToggleMusic[client] ? 1 : 0, ToggleVoice[client] ? 1 : 0, ToggleInfo[client] ? 1 : 0, view_as<int>(ToggleDuo[client]), view_as<int>(ToggleBoss[client]), cookieValues[6], cookieValues[7]);
	SetClientCookie(client, FF2Cookies, cookies);
}

void SetupClientStats(int client)
{
	if(!IsValidClient(client))
		return;

	if(IsFakeClient(client) || !AreClientCookiesCached(client))
	{
		BossWins[client] = 0;
		BossLosses[client] = 0;
		BossKills[client] = 0;
		BossKillsF[client] = 0;
		BossDeaths[client] = 0;
		PlayerKills[client] = 0;
		PlayerMVPs[client] =  0;
	}

	char cookies[48];
	char cookieValues[8][6];
	GetClientCookie(client, StatCookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 6);

	BossWins[client] = StringToInt(cookieValues[0][0]);
	BossLosses[client] = StringToInt(cookieValues[1][0]);
	BossKills[client] = StringToInt(cookieValues[2][0]);
	BossKillsF[client] = StringToInt(cookieValues[2][0]);
	BossDeaths[client] = StringToInt(cookieValues[3][0]);
	PlayerKills[client] = StringToInt(cookieValues[4][0]);
	PlayerMVPs[client] =  StringToInt(cookieValues[5][0]);
}

void SaveClientStats(int client)
{
	if(!IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client) || GetConVarInt(cvarStatPlayers)<1 || (!GetConVarBool(cvarBvBStat) && Enabled3))
		return;

	if(GetConVarInt(cvarStatWin2Lose)>2)
	{
		if(CheatsUsed)
		{
			PrintToConsole(client, "%t", "Cheats Used");
			return;
		}

		if(GetConVarInt(cvarStatPlayers) > playing2)
		{
			PrintToConsole(client, "%t", "Low Players");
			return;
		}
	}
	else if(GetConVarInt(cvarStatWin2Lose)>0 || GetConVarInt(cvarStatHud)>0)
	{
		if(CheatsUsed)
		{
			FPrintToChat(client, "%t", "Cheats Used");
			return;
		}

		if(GetConVarInt(cvarStatPlayers) > playing2)
		{
			FPrintToChat(client, "%t", "Low Players");
			return;
		}
	}
	else
	{
		if(CheatsUsed || GetConVarInt(cvarStatPlayers)>playing2)
			return;
	}

	char cookies[48];
	char cookieValues[8][6];
	GetClientCookie(client, StatCookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 6);

	Format(cookies, sizeof(cookies), "%i %i %i %i %i %i %s %s", BossWins[client], BossLosses[client], BossKills[client], BossDeaths[client], PlayerKills[client], PlayerMVPs[client], cookieValues[6], cookieValues[7]);
	SetClientCookie(client, StatCookies, cookies);
}

void AddClientStats(int client, CookieStats cookie, int num)
{
	if(!IsValidClient(client) || CheatsUsed || GetConVarInt(cvarStatPlayers)>playing2 || GetConVarInt(cvarStatPlayers)<1 || (!GetConVarBool(cvarBvBStat) && Enabled3))
		return;

	switch(cookie)
	{
		case Cookie_BossWins:
		{
			BossWins[client] += num;
		}
		case Cookie_BossLosses:
		{
			BossLosses[client] += num;
		}
		case Cookie_BossKills:
		{
			BossKills[client] += num;
		}
		case Cookie_BossDeaths:
		{
			BossDeaths[client] += num;
		}
		case Cookie_PlayerKills:
		{
			PlayerKills[client] += num;
		}
		case Cookie_PlayerMvps:
		{
			PlayerMVPs[client] += num;
		}
	}
}

public Action Command_SetMyBoss(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!GetConVarBool(cvarSelectBoss))
		return Plugin_Handled;

	if(!CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}

	if(args)
	{
		if(!Enabled2)
		{
			FReplyToCommand(client, "%t", "FF2 Disabled");
			return Plugin_Handled;
		}

		char name[64], boss[64], bossName[64], fileName[64], companionName[64];
		GetCmdArgString(name, sizeof(name));

		for(int config; config<Specials; config++)
		{
			KvRewind(BossKV[config]);
			if(KvGetNum(BossKV[config], "blocked", 0))
			{
				if(config == Specials-1)
				{
					FReplyToCommand(client, "%t", "deny_unknown");
					return Plugin_Handled;
				}
				continue;
			}

			GetBossSpecial(config, bossName, sizeof(bossName), client);
			KvGetString(BossKV[config], "name", boss, sizeof(boss));
			if(StrContains(bossName, name, false))
			{
				if(StrContains(boss, name, false))
				{
					KvGetString(BossKV[config], "filename", fileName, sizeof(fileName));
					if(StrContains(fileName, name, false))
					{
						if(config == Specials-1)
						{
							FReplyToCommand(client, "%t", "deny_unknown");
							return Plugin_Handled;
						}
						continue;
					}
				}
			}

			if((KvGetNum(BossKV[config], "donator", 0) && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
			   (KvGetNum(BossKV[config], "admin", 0) && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
			   (BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true)))
			{
				if(KvGetNum(BossKV[config], "hidden", 0))
				{
					FReplyToCommand(client, "%t", "deny_unknown");
					return Plugin_Handled;
				}
				else
				{
					FReplyToCommand(client, "%t", "deny_donator");
					return Plugin_Handled;
				}
			}
			else if(KvGetNum(BossKV[config], "owner", 0) && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true))
			{
				if(KvGetNum(BossKV[config], "hidden", 1))
				{
					FReplyToCommand(client, "%t", "deny_unknown");
					return Plugin_Handled;
				}
				else
				{
					FReplyToCommand(client, "%t", "deny_donator");
					return Plugin_Handled;
				}
			}
			else if(KvGetNum(BossKV[config], "hidden", 0) &&
			      !(KvGetNum(BossKV[config], "donator", 0) ||
			        BossTheme(config) ||
				KvGetNum(BossKV[config], "admin", 0) ||
				KvGetNum(BossKV[config], "owner", 0)))
			{
				FReplyToCommand(client, "%t", "deny_unknown");
				return Plugin_Handled;
			}

			if(KvGetNum(BossKV[config], "nofirst", 0) && (RoundCount<arenaRounds || (RoundCount==arenaRounds && CheckRoundState()!=1)))
			{
				FReplyToCommand(client, "%t", "deny_nofirst");
				return Plugin_Handled;
			}

			KvGetString(BossKV[config], "companion", companionName, sizeof(companionName));
			if(strlen(companionName) && !DuoMin)
			{
				FReplyToCommand(client, "%t", "deny_duo_short");
				return Plugin_Handled;
			}

			if(strlen(companionName) && GetConVarBool(cvarDuoBoss) && view_as<int>(ToggleDuo[client])>1)
			{
				FReplyToCommand(client, "%t", "deny_duo_off");
				return Plugin_Handled;
			}

			if(AreClientCookiesCached(client) && GetConVarInt(cvarKeepBoss)<0)
			{
				char cookie1[64], cookie2[64];
				KvGetString(BossKV[config], "name", cookie1, sizeof(cookie1));
				GetClientCookie(client, LastPlayedCookie, cookie2, sizeof(cookie2));
				if(StrEqual(cookie1, cookie2, false))
				{
					FReplyToCommand(client, "%t", "deny_recent");
					return Plugin_Handled;
				}
			}
			IsBossSelected[client] = true;
			strcopy(xIncoming[client], sizeof(xIncoming[]), boss);
			CanBossVs[client] = KvGetNum(BossKV[config], "noversus", 0);
			CanBossTeam[client] = KvGetNum(BossKV[config], "bossteam", 0);
			SaveKeepBossCookie(client);
			FReplyToCommand(client, "%t", "to0_boss_selected", bossName);
			return Plugin_Handled;
		}
	}

	char boss[64], bossName[64];
	Handle dMenu = CreateMenu(Command_SetMyBossH);
	SetGlobalTransTarget(client);
	if(ToggleBoss[client] == Setting_On)
		Format(bossName, sizeof(bossName), "%t", "to0_random");

	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		if(KvGetNum(BossKV[config], "blocked", 0))
			continue;

		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrEqual(boss, xIncoming[client], false))
		{
			GetBossSpecial(config, bossName, sizeof(bossName), client);
			break;
		}
	}
	SetMenuTitle(dMenu, "%t", "ff2_boss_selection", bossName);

	Format(boss, sizeof(boss), "%t", "to0_random");
	if(!Enabled2 || Specials<1)
	{
		AddMenuItem(dMenu, boss, boss, ITEMDRAW_DISABLED);
	}
	else
	{
		AddMenuItem(dMenu, boss, boss);
	}

	if(GetConVarBool(cvarToggleBoss))
	{
		if(view_as<int>(ToggleBoss[client]) < 2)
		{
			Format(boss, sizeof(boss), "%t", "to0_disablepts");
		}
		else
		{
			Format(boss, sizeof(boss), "%t", "to0_enablepts");
		}
		AddMenuItem(dMenu, boss, boss);
	}

	if(GetConVarBool(cvarDuoBoss))
	{
		if(view_as<int>(ToggleDuo[client]) < 2)
		{
			Format(boss, sizeof(boss), "%t", "to0_disableduo");
		}
		else
		{
			Format(boss, sizeof(boss), "%t", "to0_enableduo");
		}
		AddMenuItem(dMenu, boss, boss);
	}

	#if defined _freak_fortress_2_kstreak_included
	if(kmerge && CheckCommandAccess(client, "ff2_kstreak_a", 0, true))
	{
		if(FF2_KStreak_GetCookies(client, 0) == 1)
		{
			Format(boss, sizeof(boss), "%t", "to0_disablekstreak");
		}
		else if(FF2_KStreak_GetCookies(client, 0) < 1)
		{
			Format(boss, sizeof(boss), "%t", "to0_enablekstreak");
		}
		else
		{
			Format(boss, sizeof(boss), "%t", "to0_togglekstreak");
		}
		AddMenuItem(dMenu, boss, boss);
	}
	#endif

	if(GetConVarBool(cvarSkipBoss))
	{
		Format(boss, sizeof(boss), "%t", "to0_resetpts");
		if(QueuePoints[client]<10 || !Enabled2)
		{
			AddMenuItem(dMenu, boss, boss, ITEMDRAW_DISABLED);
		}
		else
		{
			AddMenuItem(dMenu, boss, boss);
		}
	}

	char companionName[64];
	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		if(KvGetNum(BossKV[config], "blocked", 0))
			continue;

		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		GetBossSpecial(config, bossName, sizeof(bossName), client);
		KvGetString(BossKV[config], "companion", companionName, sizeof(companionName));
		if((KvGetNum(BossKV[config], "donator", 0) && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
		   (KvGetNum(BossKV[config], "admin", 0) && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
		   (BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true)))
		{
			if(!KvGetNum(BossKV[config], "hidden", 0))
				AddMenuItem(dMenu, boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(BossKV[config], "owner", 0) && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true))
		{
			if(!KvGetNum(BossKV[config], "hidden", 1))
				AddMenuItem(dMenu, boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(BossKV[config], "hidden", 0) &&
		      !(KvGetNum(BossKV[config], "donator", 0) ||
		        BossTheme(config) ||
			KvGetNum(BossKV[config], "admin", 0) ||
			KvGetNum(BossKV[config], "owner", 0)))
		{
			// Don't show
		}
		else if(KvGetNum(BossKV[config], "nofirst", 0) && (RoundCount<arenaRounds || (RoundCount==arenaRounds && CheckRoundState()!=1)))
		{
			AddMenuItem(dMenu, boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(strlen(companionName) && ((GetConVarBool(cvarDuoBoss) && view_as<int>(ToggleDuo[client])>1) || !DuoMin))
		{
			AddMenuItem(dMenu, boss, bossName, ITEMDRAW_DISABLED);
		}
		else
		{
			if(AreClientCookiesCached(client) && GetConVarInt(cvarKeepBoss)<0 && !CheckCommandAccess(client, "ff2_replay_bosses", ADMFLAG_CHEATS, true))
			{
				char cookie1[64], cookie2[64];
				KvGetString(BossKV[config], "name", cookie1, sizeof(cookie1));
				GetClientCookie(client, LastPlayedCookie, cookie2, sizeof(cookie2));
				if(StrEqual(cookie1, cookie2, false))
				{
					AddMenuItem(dMenu, boss, bossName, ITEMDRAW_DISABLED);
					continue;
				}
			}
			AddMenuItem(dMenu, boss, bossName);
		}
	}
	SetMenuExitButton(dMenu, true);
	DisplayMenu(dMenu, client, 20);
	return Plugin_Handled;
}

public int Command_SetMyBossH(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			if(!param2)
			{
				IsBossSelected[param1]=true;
				xIncoming[param1][0] = '\0';
				CanBossVs[param1] = 0;
				CanBossTeam[param1] = 0;
				SaveKeepBossCookie(param1);
				FReplyToCommand(param1, "%t", "to0_comfirmrandom");
				return;
			}

			int option1, option2, option4;
			#if defined _freak_fortress_2_kstreak_included
			int option3;
			#endif
			for(int choices=1; choices<5; choices++)
			{
				if(!option1 && GetConVarBool(cvarToggleBoss))
				{
					option1 = choices;
					continue;
				}
				if(!option2 && GetConVarBool(cvarDuoBoss))
				{
					option2 = choices;
					continue;
				}
				#if defined _freak_fortress_2_kstreak_included
				if(!option3 && kmerge && CheckCommandAccess(param1, "ff2_kstreak_a", 0, true))
				{
					option3 = choices;
					continue;
				}
				#endif
				if(!option4 && GetConVarBool(cvarSkipBoss))
				{
					option4 = choices;
					continue;
				}
			}

			if(param2 == option1)
			{
				BossMenu(param1, 0);
				return;
			}

			if(param2 == option2)
			{
				CompanionMenu(param1, 0);
				return;
			}

			#if defined _freak_fortress_2_kstreak_included
			if(param2 == option3)
			{
				FF2_KStreak_Menu(param1, 0);
				return;
			}
			#endif

			if(param2 == option4)
			{
				SkipBossPanel(param1);
				return;
			}

			if(!GetConVarBool(cvarBossDesc) || !ToggleInfo[param1])
			{
				char name[64], bossName[64];
				GetMenuItem(menu, param2, name, sizeof(name), _, bossName, sizeof(bossName));
				if(CheckValidBoss(param1, name))
				{
					IsBossSelected[param1] = true;
					strcopy(xIncoming[param1], sizeof(xIncoming[]), name);
					SaveKeepBossCookie(param1);
					FReplyToCommand(param1, "%t", "to0_boss_selected", bossName);
				}
				else
				{
					Command_SetMyBoss(param1, 0);
				}
			}
			else
			{
				GetMenuItem(menu, param2, cIncoming[param1], sizeof(cIncoming[]));
				ConfirmBoss(param1);
			}
		}
	}
}

public Action ConfirmBoss(int client)
{
	if(!GetConVarBool(cvarBossDesc))
		return Plugin_Handled;

	char text[512], language[20], boss[64];
	GetLanguageInfo(GetClientLanguage(client), language, 8, text, 8);
	Format(language, sizeof(language), "description_%s", language);
	SetGlobalTransTarget(client);

	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrEqual(boss, cIncoming[client], false))
		{
			KvRewind(BossKV[config]);
			KvGetString(BossKV[config], language, text, sizeof(text));
			if(!text[0])
			{
				KvGetString(BossKV[config], "description_en", text, sizeof(text));  //Default to English if their language isn't available
				if(!text[0])
					Format(text, sizeof(text), "%t", "to0_nodesc");
			}
			ReplaceString(text, sizeof(text), "\\n", "\n");
			GetBossSpecial(config, boss, sizeof(boss), client);
			break;
		}
	}

	Handle dMenu = CreateMenu(ConfirmBossH);
	SetMenuTitle(dMenu, text);

	Format(text, sizeof(text), "%t", "to0_confirm", boss);
	AddMenuItem(dMenu, boss, text);

	Format(text, sizeof(text), "%t", "to0_cancel");
	AddMenuItem(dMenu, text, text);

	SetMenuExitButton(dMenu, false);
	DisplayMenu(dMenu, client, 20);
	return Plugin_Handled;
}

public int ConfirmBossH(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			if(!param2 && CheckValidBoss(param1, cIncoming[param1]))
			{
				char bossName[64];
				GetMenuItem(menu, param2, bossName, sizeof(bossName));
				IsBossSelected[param1] = true;
				strcopy(xIncoming[param1], sizeof(xIncoming[]), cIncoming[param1]);
				SaveKeepBossCookie(param1);
				FReplyToCommand(param1, "%t", "to0_boss_selected", bossName);
			}
			else
			{
				Command_SetMyBoss(param1, 0);
			}
		}
	}
}

bool BossTheme(int config)
{
	KvRewind(BossKV[config]);
	int theme=KvGetNum(BossKV[config], "theme", 0);
	if(theme>0)
	{
		switch(GetConVarInt(cvarTheme))
		{
			case 0:
			{
				return true;
			}
			case 1:
			{
				if(theme==1)
					return false;
			}
			case 2:
			{
				if(theme==2)
					return false;
			}
			case 3:
			{
				if(theme==1 || theme==2)
					return false;
			}
			case 4:
			{
				if(theme==3)
					return false;
			}
			case 5:
			{
				if(theme==1 || theme==3)
					return false;
			}
			case 6:
			{
				if(theme==2 || theme==3)
					return false;
			}
			case 7:
			{
				if(theme==1 || theme==2 || theme==3)
					return false;
			}
			case 8:
			{
				if(theme==4)
					return false;
			}
			case 9:
			{
				if(theme==1 || theme==4)
					return false;
			}
			case 10:
			{
				if(theme==2 || theme==4)
					return false;
			}
			case 11:
			{
				if(theme==1 || theme==2 || theme==4)
					return false;
			}
			case 12:
			{
				if(theme==3 || theme==4)
					return false;
			}
			case 13:
			{
				if(theme==1 || theme==3 || theme==4)
					return false;
			}
			case 14:
			{
				if(theme==2 || theme==3 || theme==4)
					return false;
			}
			default:
			{
				return false;
			}
		}
		return true;
	}
	return false;
}

void SaveKeepBossCookie(int client)
{
	if(!AreClientCookiesCached(client) || !GetConVarBool(cvarSelectBoss))
		return;

	SetClientCookie(client, SelectionCookie, xIncoming[client]);
}

bool CheckValidBoss(int client=0, char[] SpecialName, bool CompanionCheck=false)
{
	char boss[64], companionName[64];
	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		if(KvGetNum(BossKV[config], "blocked", 0))
			continue;

		KvGetString(BossKV[config], "companion", companionName, sizeof(companionName));
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrEqual(boss, SpecialName, false))
		{
			if(strlen(companionName) && CompanionCheck)
				return false;

			if(client)
			{
				if((KvGetNum(BossKV[config], "donator", 0) && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
				   (KvGetNum(BossKV[config], "admin", 0) && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
				   (KvGetNum(BossKV[config], "owner", 0) && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true)))
					return false;

				if(BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true))
					return false;
			}

			if(KvGetNum(BossKV[config], "nofirst", 0) && (RoundCount<arenaRounds || (RoundCount==arenaRounds && CheckRoundState()!=1)))
				return false;

			if(client)
			{
				CanBossVs[client] = KvGetNum(BossKV[config], "noversus", 0);
				CanBossTeam[client] = KvGetNum(BossKV[config], "bossteam", 0);
			}

			return true;
		}
	}
	return false;
}

public Action FF2_OnSpecialSelected(int boss, int &SpecialNum, char[] SpecialName, bool preset)
{
	int client = Boss[boss];
	if((!boss || boss==MAXBOSSES) && strlen(xIncoming[client]) && GetConVarBool(cvarSelectBoss))
	{
		if(preset)
		{
			FPrintToChat(client, "%t", "boss_selection_overridden");
		}
		else
		{
			strcopy(SpecialName, sizeof(xIncoming[]), xIncoming[client]);
			if(GetConVarInt(cvarKeepBoss)<1 || !GetConVarBool(cvarSelectBoss) || IsFakeClient(client))
			{
				xIncoming[client][0] = '\0';
				CanBossVs[client] = 0;
				CanBossTeam[client] = 0;
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock int CreateAttachedAnnotation(int client, int entity, bool effect=true, float time, const char[] buffer, any ...)
{
	char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 6);
	ReplaceString(message, sizeof(message), "\n", "");  //Get rid of newlines

	Handle event = CreateEvent("show_annotation");
	if(event == INVALID_HANDLE)
		return -1;

	SetEventInt(event, "follow_entindex", entity);
	SetEventFloat(event, "lifetime", time);
	SetEventInt(event, "visibilityBitfield", (1<<client));
	SetEventBool(event,"show_effect", effect);
	SetEventString(event, "text", message);
	SetEventInt(event, "id", entity); //What to enter inside? Need a way to identify annotations by entindex!
	FireEvent(event);
	return entity;
}

stock bool ShowGameText(int client, const char[] icon="leaderboard_streak", int color=0, const char[] buffer, any ...)
{
	Handle bf;
	if(!client)
	{
		bf = StartMessageAll("HudNotifyCustom");
	}
	else
	{
		bf = StartMessageOne("HudNotifyCustom", client);
	}

	if(bf == null)
		return false;

	char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 5);
	ReplaceString(message, sizeof(message), "\n", "");

	BfWriteString(bf, message);
	BfWriteString(bf, icon);
	BfWriteByte(bf, color);
	EndMessage();
	return true;
}

public Action Timer_Move(Handle timer)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client))
			SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

public Action Timer_StartRound(Handle timer)
{
	CreateTimer(10.0, Timer_NextBossPanel, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Handled;
}

public Action Timer_NextBossPanel(Handle timer)
{
	int clients;
	bool[] added = new bool[MaxClients+1];
	while(clients < 3)  //TODO: Make this configurable?
	{
		int client = GetClientWithMostQueuePoints(added);
		if(!IsValidClient(client))  //No more players left on the server
			break;

		if(!IsBoss(client) && !strlen(xIncoming[client]))
		{
			FPrintToChat(client, "%t", "to0_near");  //"You will become the Boss soon. Type {olive}/ff2next{default} to make sure."
			clients++;
		}
		added[client]=true;
	}
}

public Action MessageTimer(Handle timer)
{
	if(checkDoors)
	{
		int entity = -1;
		while((entity=FindEntityByClassname2(entity, "func_door")) != -1)
		{
			AcceptEntityInput(entity, "Open");
			AcceptEntityInput(entity, "Unlock");
		}

		if(doorCheckTimer == INVALID_HANDLE)
			doorCheckTimer = CreateTimer(5.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	char text[MAXPLAYERS+1][512], textChat[512], lives[8], name[64];
	if(Enabled3)
	{
		char text2[MAXPLAYERS+1][512];
		for(int boss; boss<=MaxClients; boss++)
		{
			if(IsValidClient(Boss[boss]))
			{
				strcopy(name, sizeof(name), "=Failed name=");
				if(BossLives[boss] > 1)
				{
					Format(lives, sizeof(lives), "x%i", BossLives[boss]);
				}
				else
				{
					lives[0] = '\0';
				}

				for(int client=1; client<=MaxClients; client++)
				{
					if(IsValidClient(client))
					{
						GetBossSpecial(Special[boss], name, sizeof(name));
						if(BossSwitched[boss])
						{
							Format(text2[client], sizeof(text2[]), "%s\n%t", text2[client], "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
						}
						else
						{
							Format(text[client], sizeof(text[]), "%s\n%t", text[client], "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
						}
						Format(textChat, sizeof(textChat), "%t", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
						ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
						FPrintToChat(client, "%s", textChat);
					}
				}
			}
		}

		SetHudTextParams(0.25, 0.3, 10.0, 100, 100, 255, 255);
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
				FF2_ShowSyncHudText(client, infoHUD, text[client]);
		}

		SetHudTextParams(0.6, 0.3, 10.0, 255, 100, 100, 255);
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
				FF2_ShowSyncHudText(client, abilitiesHUD, text2[client]);
		}
		CreateTimer(10.0, Timer_ShowHealthText, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}

	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]))
		{
			strcopy(name, sizeof(name), "=Failed name=");
			if(BossLives[boss] > 1)
			{
				Format(lives, sizeof(lives), "x%i", BossLives[boss]);
			}
			else
			{
				lives[0] = '\0';
			}

			for(int client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					GetBossSpecial(Special[boss], name, sizeof(name));
					Format(text[client], sizeof(text[]), "%s\n%t", text[client], "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
					Format(textChat, sizeof(textChat), "%t", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
					ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
					FPrintToChat(client, "%s", textChat);
				}
			}
		}
	}

	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(bosses<2 && GetConVarInt(cvarGameText)>1)
			{
				if(strlen(BossIcon))
				{
					ShowGameText(client, BossIcon, _, text[client]);
				}
				else
				{
					ShowGameText(client, "leaderboard_streak", _, text[client]);
				}
				CreateTimer(1.5, Timer_ShowHealthText, _, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				FF2_ShowSyncHudText(client, infoHUD, text[client]);
				CreateTimer(10.0, Timer_ShowHealthText, _, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_ShowHealthText(Handle timer)
{
	ShowHealthText = true;
	return Plugin_Continue;
}

public Action MakeModelTimer(Handle timer, any client)
{
	if(IsValidClient(Boss[client]) && IsPlayerAlive(Boss[client]) && CheckRoundState()!=2)
	{
		char model[PLATFORM_MAX_PATH];
		KvRewind(BossKV[Special[client]]);
		KvGetString(BossKV[Special[client]], "model", model, PLATFORM_MAX_PATH);
		SetVariantString(model);
		AcceptEntityInput(Boss[client], "SetCustomModel");
		SetEntProp(Boss[client], Prop_Send, "m_bUseClassAnimations", 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

void EquipBoss(int boss)
{
	int client = Boss[boss];
	DoOverlay(client, "");
	TF2_RemoveAllWeapons(client);
	char key[10], classname[64], attributes[256];
	for(int i=1; ; i++)
	{
		KvRewind(BossKV[Special[boss]]);
		Format(key, sizeof(key), "weapon%i", i);
		if(KvJumpToKey(BossKV[Special[boss]], key))
		{
			KvGetString(BossKV[Special[boss]], "name", classname, sizeof(classname));
			KvGetString(BossKV[Special[boss]], "attributes", attributes, sizeof(attributes));
			int strangerank = KvGetNum(BossKV[Special[boss]], "rank", 21);
			int weaponlevel = KvGetNum(BossKV[Special[boss]], "level", -1);
			int index = KvGetNum(BossKV[Special[boss]], "index");
			bool overridewep = view_as<bool>(KvGetNum(BossKV[Special[boss]], "override", 0));
			int strangekills = -1;
			int strangewep = 1;
			switch(strangerank)
			{
				case 0:
				{
					strangekills = GetRandomInt(0, 9);
				}
				case 1:
				{
					strangekills = GetRandomInt(10, 24);
				}
				case 2:
				{
					strangekills = GetRandomInt(25, 44);
				}
				case 3:
				{
					strangekills = GetRandomInt(45, 69);
				}
				case 4:
				{
					strangekills = GetRandomInt(70, 99);
				}
				case 5:
				{
					strangekills = GetRandomInt(100, 134);
				}
				case 6:
				{
					strangekills = GetRandomInt(135, 174);
				}
				case 7:
				{
					strangekills = GetRandomInt(175, 224);
				}
				case 8:
				{
					strangekills = GetRandomInt(225, 274);
				}
				case 9:
				{
					strangekills = GetRandomInt(275, 349);
				}
				case 10:
				{
					strangekills = GetRandomInt(350, 499);
				}
				case 11:
				{
					if(index == 656)	// Holiday Punch is different
					{
						strangekills = GetRandomInt(500, 748);
					}
					else
					{
						strangekills = GetRandomInt(500, 749);
					}
				}
				case 12:
				{
					if(index == 656)
					{
						strangekills = 749;
					}
					else
					{
						strangekills = GetRandomInt(750, 998);
					}
				}
				case 13:
				{
					if(index == 656)
					{
						strangekills = GetRandomInt(750, 999);
					}
					else
					{
						strangekills = 999;
					}
				}
				case 14:
				{
					strangekills = GetRandomInt(1000, 1499);
				}
				case 15:
				{
					strangekills = GetRandomInt(1500, 2499);
				}
				case 16:
				{
					strangekills = GetRandomInt(2500, 4999);
				}
				case 17:
				{
					strangekills = GetRandomInt(5000, 7499);
				}
				case 18:
				{
					if(index == 656)
					{
						strangekills = GetRandomInt(7500, 7922);
					}
					else
					{
						strangekills = GetRandomInt(7500, 7615);
					}
				}
				case 19:
				{
					if(index == 656)
					{
						strangekills = GetRandomInt(7923, 8499);
					}
					else
					{
						strangekills = GetRandomInt(7616, 8499);
					}
				}
				case 20:
				{
					strangekills = GetRandomInt(8500, 9999);
				}
				default:
				{
					strangekills = GetRandomInt(0, 9999);
					if(!GetConVarBool(cvarStrangeWep) || weaponlevel!=-1 || overridewep)
						strangewep=0;
				}
			}

			if(weaponlevel < 0)
				weaponlevel = 101;

			if(strangewep)
			{
				if(strlen(attributes))
				{
					if(overridewep)
					{
						Format(attributes, sizeof(attributes), "214 ; %d ; %s", strangekills, attributes);
					}
					else
					{
						Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; 214 ; %d ; 275 ; 1 ; %s", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, strangekills, attributes);
					}
				}
				else
				{
					if(overridewep)
					{
						Format(attributes, sizeof(attributes), "214 ; %d", strangekills);
					}
					else
					{
						Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; 214 ; %d ; 275 ; 1", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, strangekills);
					}
				}
			}
			else
			{
				if(strlen(attributes))
				{
					if(overridewep)
					{
						Format(attributes, sizeof(attributes), "%s", attributes);
					}
					else
					{
						Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; 275 ; 1 ; %s", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, attributes);
					}
				}
				else
				{
					if(overridewep)
					{
						Format(attributes, sizeof(attributes), "");
					}
					else
					{
						Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; 275 ; 1", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2);
					}
				}
			}

			int weapon = SpawnWeapon(client, classname, index, weaponlevel, KvGetNum(BossKV[Special[boss]], "quality", QualityWep), attributes);
			FF2_SetAmmo(client, weapon, KvGetNum(BossKV[Special[boss]], "ammo", -1), KvGetNum(BossKV[Special[boss]], "clip", -1));
			if(StrEqual(classname, "tf_weapon_builder", false) && index!=735)  //PDA, normal sapper
			{
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
			}
			else if(StrEqual(classname, "tf_weapon_sapper", false) || index==735)  //Sappers
			{
				SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
				SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
			}

			if(!KvGetNum(BossKV[Special[boss]], "show", 0))
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
				if(index==221 || index==572 || index==939 || index==999 || index==1013) // Workaround for jiggleboned weapons
				{
					SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
					SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
				}
			}
			else
			{
				char wModel[PLATFORM_MAX_PATH];
				KvGetString(BossKV[Special[boss]], "worldmodel", wModel, sizeof(wModel));
				if(strlen(wModel))
				{
					for(int type=0; type<=3; type++)
					{
						ConfigureWorldModelOverride(weapon, index, wModel, type);
					}
				}
			}

			int rgba[4];
			rgba[0] = KvGetNum(BossKV[Special[boss]], "alpha", 255);
			rgba[1] = KvGetNum(BossKV[Special[boss]], "red", 255);
			rgba[2] = KvGetNum(BossKV[Special[boss]], "green", 255);
			rgba[3] = KvGetNum(BossKV[Special[boss]], "blue", 255);

			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, rgba[1], rgba[2], rgba[3], rgba[0]);

			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
		else
		{
			break;
		}
	}

	KvGoBack(BossKV[Special[boss]]);
	TFClassType class = view_as<TFClassType>(KvGetNum(BossKV[Special[boss]], "class", 1));
	if(TF2_GetPlayerClass(client) != class)
	{
		TF2_SetPlayerClass(client, class, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	}
}

stock bool ConfigureWorldModelOverride(int entity, int index, const char[] model, int type, bool wearable=false)
{
	if(!FileExists(model, true))
		return false;

	int modelIndex = PrecacheModel(model);
	if(!type)
	{
		SetEntProp(entity, Prop_Send, "m_nModelIndex", modelIndex);
	}
	else
	{
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, type);
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", (!wearable ? GetEntProp(entity, Prop_Send, "m_iWorldModelIndex") : GetEntProp(entity, Prop_Send, "m_nModelIndex")), _, 0);
	}
	return true;
}

public Action Timer_MakeBoss(Handle timer, any boss)
{
	int client = Boss[boss];
	if(!IsValidClient(client) || CheckRoundState()==-1)
		return Plugin_Continue;

	if(!IsPlayerAlive(client))
	{
		if(!CheckRoundState())
		{
			TF2_RespawnPlayer(client);
		}
		else
		{
			return Plugin_Continue;
		}
	}

	KvRewind(BossKV[Special[boss]]);
	int ForcedTeam = BossSwitched[boss] ? OtherTeam : BossTeam;
	if(GetClientTeam(client) != ForcedTeam)
		AssignTeam(client, ForcedTeam);

	BossRageDamage[boss] = ParseFormula(boss, "ragedamage", "1900", 1900);
	if(KvGetNum(BossKV[Special[boss]], "ragedamage", 1900) < 0)	// -1 or below, disable RAGE
	{
		BossRageDamage[boss] = 99999;
	}

	BossLivesMax[boss] = KvGetNum(BossKV[Special[boss]], "lives", 1);
	if(BossLivesMax[boss] <= 0)
	{
		char bossName[64];
		KvGetString(BossKV[Special[boss]], "filename", bossName, sizeof(bossName));
		PrintToServer("[FF2 Bosses] Warning: Boss %s has an invalid amount of lives, setting to 1", bossName);
		BossLivesMax[boss] = 1;
	}
	BossHealthMax[boss] = ParseFormula(boss, "health_formula", "(((760.8+n)*(n-1))^1.0341)+2046", RoundFloat(Pow((760.8+float(playing))*(float(playing)-1.0), 1.0341)+2046.0));
	BossLives[boss] = BossLivesMax[boss];
	BossHealth[boss] = BossHealthMax[boss]*BossLivesMax[boss];
	BossHealthLast[boss] = BossHealth[boss];

	if(KvGetNum(BossKV[Special[boss]], "triple", -1) >= 0)
	{
		dmgTriple[client] = view_as<bool>(KvGetNum(BossKV[Special[boss]], "triple", -1));
	}
	else
	{
		dmgTriple[client] = GetConVarBool(cvarTripleWep);
	}

	if(KvGetNum(BossKV[Special[boss]], "knockback", -1)>=0)
	{
		SelfKnockback[client]=KvGetNum(BossKV[Special[boss]], "knockback", -1);
	}
	else if(KvGetNum(BossKV[Special[boss]], "rocketjump", -1)>=0)
	{
		SelfKnockback[client]=KvGetNum(BossKV[Special[boss]], "rocketjump", -1);
	}
	else
	{
		SelfKnockback[client]=GetConVarInt(cvarSelfKnockback);
	}

	if(KvGetNum(BossKV[Special[boss]], "crits", -1) >= 0)
	{
		randomCrits[client] = view_as<bool>(KvGetNum(BossKV[Special[boss]], "crits", -1));
	}
	else
	{
		randomCrits[client] = GetConVarBool(cvarCrits);
	}

	if(KvGetNum(BossKV[Special[boss]], "healing", -1) >= 0)
	{
		SelfHealing[client] = KvGetNum(BossKV[Special[boss]], "healing", -1);
	}
	else
	{
		SelfHealing[client] = GetConVarInt(cvarSelfHealing);
	}

	LifeHealing[client] = KvGetFloat(BossKV[Special[boss]], "healing_lives", 0.0);
	OverHealing[client] = KvGetFloat(BossKV[Special[boss]], "healing_over", 0.0);
	rageMode[client] = KvGetNum(BossKV[Special[boss]], "ragemode", 0);
	KvGetString(BossKV[Special[boss]], "icon", BossIcon, sizeof(BossIcon));
	rageMax[client] = KvGetFloat(BossKV[Special[boss]], "ragemax", 100.0);
	rageMin[client] = KvGetFloat(BossKV[Special[boss]], "ragemin", 100.0);
	rageMode[client] = KvGetNum(BossKV[Special[boss]], "ragemode", 0);

	// Timer/point settings
	if(KvGetNum(BossKV[Special[boss]], "pointtype", -1)>=0 && KvGetNum(BossKV[Special[boss]], "pointtype", -1)<=2)
	{
		PointType = KvGetNum(BossKV[Special[boss]], "pointtype", -1);
	}
	else
	{
		PointType = GetConVarInt(cvarPointType);
	}

	if(KvGetNum(BossKV[Special[boss]], "pointdelay", -9999) != -9999)	// Can be below 0 so...
	{
		PointDelay = KvGetNum(BossKV[Special[boss]], "pointdelay", -9999);
	}
	else
	{
		PointDelay = GetConVarInt(cvarPointDelay);
	}

	if(KvGetNum(BossKV[Special[boss]], "pointtime", -9999) != -9999)	// Same here, in-case of some weird boss logic
	{
		PointTime = KvGetNum(BossKV[Special[boss]], "pointtime", -9999);
	}
	else
	{
		PointTime = GetConVarInt(cvarPointTime);
	}

	if(KvGetFloat(BossKV[Special[boss]], "pointalive", -1.0) >= 0)	// Can't be below 0, it's players/ratio
	{
		AliveToEnable = KvGetFloat(BossKV[Special[boss]], "pointalive", -1.0);
	}
	else
	{
		AliveToEnable = GetConVarFloat(cvarAliveToEnable);
	}

	if(KvGetNum(BossKV[Special[boss]], "countdownhealth", -1) >= 0)	// Also can't be below 0, it's health
	{
		countdownHealth = KvGetNum(BossKV[Special[boss]], "countdownhealth", -1);
	}
	else
	{
		countdownHealth = GetConVarInt(cvarCountdownHealth);
	}

	if(KvGetFloat(BossKV[Special[boss]], "countdownalive", -1.0) >= 0)	// Yet again, can't be below 0
	{
		countdownPlayers = KvGetFloat(BossKV[Special[boss]], "countdownalive", -1.0);
	}
	else
	{
		countdownPlayers = GetConVarFloat(cvarCountdownPlayers);
	}

	if(KvGetNum(BossKV[Special[boss]], "countdowntime", -1) >= 0)	// .w.
	{
		countdownTime = KvGetNum(BossKV[Special[boss]], "countdowntime", -1);
	}
	else
	{
		countdownTime = GetConVarInt(cvarCountdownTime);
	}

	if(KvGetNum(BossKV[Special[boss]], "countdownovertime", -1) >= 0)	// OVERTIME!
	{
		countdownOvertime = view_as<bool>(KvGetNum(BossKV[Special[boss]], "countdownovertime", -1));
	}
	else
	{
		countdownOvertime = GetConVarBool(cvarCountdownOvertime);
	}

	if((KvGetNum(BossKV[Special[boss]], "sapper", -1)<0 && (GetConVarInt(cvarSappers)==1 || GetConVarInt(cvarSappers)>2)) || KvGetNum(BossKV[Special[boss]], "sapper", -1)==1 || KvGetNum(BossKV[Special[boss]], "sapper", -1)>2)
	{
		SapperBoss[client] = true;
	}
	else
	{
		SapperBoss[client] = false;
	}

	if((KvGetNum(BossKV[Special[boss]], "sapper", -1)<0 && GetConVarInt(cvarSappers)>1) || KvGetNum(BossKV[Special[boss]], "sapper", -1)>1)
		SapperMinion = true;

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	KvRewind(BossKV[Special[boss]]);
	TF2_RemovePlayerDisguise(client);
	TF2_SetPlayerClass(client, view_as<TFClassType>(KvGetNum(BossKV[Special[boss]], "class", 1)), _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal

	switch(KvGetNum(BossKV[Special[boss]], "pickups", 0))  //Check if the boss is allowed to pickup health/ammo
	{
		case 1:
			FF2flags[client] |= FF2FLAG_ALLOW_HEALTH_PICKUPS;

		case 2:
			FF2flags[client] |= FF2FLAG_ALLOW_AMMO_PICKUPS;

		case 3:
			FF2flags[client] |= FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
	}

	if(!HasSwitched && !Enabled3)
	{
		switch(KvGetNum(BossKV[Special[boss]], "bossteam", 0))
		{
			case 1: // Always Random
				SwitchTeams((currentBossTeam==1) ? (view_as<int>(TFTeam_Blue)) : (view_as<int>(TFTeam_Red)) , (currentBossTeam==1) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)), true);

			case 2: // RED Boss
				SwitchTeams(view_as<int>(TFTeam_Red), view_as<int>(TFTeam_Blue), true);

			case 3: // BLU Boss
				SwitchTeams(view_as<int>(TFTeam_Blue), view_as<int>(TFTeam_Red), true);

			default: // Determined by "ff2_force_team" ConVar
				SwitchTeams((blueBoss) ? (view_as<int>(TFTeam_Blue)) : (view_as<int>(TFTeam_Red)), (blueBoss) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)), true);
		}
		HasSwitched=true;
	}

	CreateTimer(0.2, MakeModelTimer, boss, TIMER_FLAG_NO_MAPCHANGE);
	if(!IsVoteInProgress() && ToggleInfo[client])
		HelpPanelBoss(boss);

	if(!IsPlayerAlive(client))
		return Plugin_Continue;

	bool cosmetics = view_as<bool>(KvGetNum(BossKV[Special[boss]], "cosmetics", 0));
	int entity = -1;
	while((entity=FindEntityByClassname2(entity, "tf_wear*")) != -1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items
				{
					//NOOP
				}
				case 131, 133, 405, 406, 444, 608, 1099, 1144:	// Wearable weapons
				{
					TF2_RemoveWearable(client, entity);
				}
				default:
				{
					if(!cosmetics)
						TF2_RemoveWearable(client, entity);
				}
			}
		}
	}

	entity = -1;
	while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle")) != -1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
			TF2_RemoveWearable(client, entity);
	}

	EquipBoss(boss);
	KSpreeCount[boss] = 0;
	BossCharge[boss][0] = 0.0;
	RPSHealth[client] = -1;
	RPSLosses[client] = 0;
	RPSHealth[client] = 0;
	RPSLoser[client] = -1.0;
	HazardDamage[client] = 0.0;
	BossKillsF[client] = BossKills[client];
	HealthBarModeC[client] = false;
	if((GetBossIndex(client)==0 && GetConVarBool(cvarDuoRestore)) || !GetConVarBool(cvarDuoRestore))
	{
		QueuePoints[client] = 0;
	}
	if(AreClientCookiesCached(client))
	{
		char cookie[64];
		KvGetString(BossKV[Special[boss]], "name", cookie, sizeof(cookie));
		SetClientCookie(client, LastPlayedCookie, cookie);
	}
	return Plugin_Continue;
}

/*
    Returns the the TeamNum of an entity.
    Works for both clients and things like healthpacks.
    Returns -1 if the entity doesn't have the m_iTeamNum prop.
    GetEntityTeamNum() doesn't always return properly when tf_arena_use_queue is set to 0
*/

stock TFTeam GetEntityTeamNum(int iEnt)
{
	return view_as<TFTeam>(GetEntProp(iEnt, Prop_Send, "m_iTeamNum"));
}

stock void SetEntityTeamNum(int iEnt, int iTeam)
{
	SetEntProp(iEnt, Prop_Send, "m_iTeamNum", iTeam);
}

/*
    TeleportToMultiMapSpawn()
    [X][2]
       [0] = RED spawnpoint entref
       [1] = BLU spawnpoint entref
*/
static ArrayList s_hSpawnArray = null;

stock void OnPluginStart_TeleportToMultiMapSpawn()
{
	s_hSpawnArray = new ArrayList(2);
}

stock void teamplay_round_start_TeleportToMultiMapSpawn()
{
	s_hSpawnArray.Clear();
	int iInt=0, iEnt=MaxClients+1;
	int iSkip[MAXPLAYERS+1]={0,...};
	while((iEnt = FindEntityByClassname2(iEnt, "info_player_teamspawn")) != -1)
	{
		TFTeam iTeam = GetEntityTeamNum(iEnt);
		int iClient = GetClosestPlayerTo(iEnt, iTeam);
		if(iClient)
		{
			bool bSkip = false;
			for(int i = 0; i<=MaxClients; i++)
			{
				if(iSkip[i] == iClient)
				{
					bSkip = true;
					break;
				}
			}
			if(bSkip)
				continue;

			iSkip[iInt++] = iClient;
			int iIndex = s_hSpawnArray.Push(EntIndexToEntRef(iEnt));
			s_hSpawnArray.Set(iIndex, iTeam, 1);	// Opposite team becomes an invalid ent
		}
	}
}

/*
    Teleports a client to spawn, but only if it's a spawn that someone spawned in at the start of the round.
    Useful for multi-stage maps like vsh_megaman
*/

stock int TeleportToMultiMapSpawn(int iClient, TFTeam iTeam=TFTeam_Unassigned)
{
	int iSpawn, iIndex;
	TFTeam iTeleTeam;
	if(iTeam <= TFTeam_Spectator)
	{
		iSpawn = EntRefToEntIndex(GetRandBlockCellEx(s_hSpawnArray));
	}
	else
	{
		do
			iTeleTeam = view_as<TFTeam>(GetRandBlockCell(s_hSpawnArray, iIndex, 1));
		while (iTeleTeam != iTeam);
		iSpawn = EntRefToEntIndex(GetArrayCell(s_hSpawnArray, iIndex, 0));
	}
	TeleMeToYou(iClient, iSpawn);
	return iSpawn;
}

/*
    Returns 0 if no client was found.
*/

stock int GetClosestPlayerTo(int iEnt, TFTeam iTeam=TFTeam_Unassigned)
{
	int iBest;
	float flDist, flTemp, vLoc[3], vPos[3];
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vLoc);
	for(int iClient=1; iClient<=MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
		{
			if(iTeam>TFTeam_Unassigned && GetEntityTeamNum(iClient)!=iTeam)
				continue;

			GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", vPos);
			flTemp = GetVectorDistance(vLoc, vPos);
			if(!iBest || flTemp<flDist)
			{
				flDist = flTemp;
				iBest = iClient;
			}
		}
	}
	return iBest;
}

/*
    Teleports one entity to another.
    Doesn't necessarily have to be players.
    Returns true if a player teleported to a ducking player
*/

stock bool TeleMeToYou(int iMe, int iYou, bool bAngles=false)
{
	float vPos[3], vAng[3];
	vAng = NULL_VECTOR;
	GetEntPropVector(iYou, Prop_Send, "m_vecOrigin", vPos);
	if(bAngles)
		GetEntPropVector(iYou, Prop_Send, "m_angRotation", vAng);

	bool bDucked = false;
	if(IsValidClient(iMe) && IsValidClient(iYou) && GetEntProp(iYou, Prop_Send, "m_bDucked"))
	{
		float vCollisionVec[3];
		vCollisionVec[0] = 24.0;
		vCollisionVec[1] = 24.0;
		vCollisionVec[2] = 62.0;
		SetEntPropVector(iMe, Prop_Send, "m_vecMaxs", vCollisionVec);
		SetEntProp(iMe, Prop_Send, "m_bDucked", 1);
		SetEntityFlags(iMe, GetEntityFlags(iMe)|FL_DUCKING);
		bDucked = true;
	}
	TeleportEntity(iMe, vPos, vAng, NULL_VECTOR);
	return bDucked;
}

stock int GetRandBlockCell(ArrayList hArray, int &iSaveIndex, int iBlock=0, bool bAsChar=false, int iDefault=0)
{
	int iSize = hArray.Length;
	if(iSize > 0)
	{
		iSaveIndex = GetRandomInt(0, iSize - 1);
		return hArray.Get(iSaveIndex, iBlock, bAsChar);
	}
	iSaveIndex = -1;
	return iDefault;
}

// Get a random value while ignoring the save index.
stock int GetRandBlockCellEx(ArrayList hArray, int iBlock=0, bool bAsChar=false, int iDefault=0)
{
	int iIndex;
	return GetRandBlockCell(hArray, iIndex, iBlock, bAsChar, iDefault);
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &item)
{
	if(!Enabled)
		return Plugin_Continue;

	if(!ConfigWeapons)
	{
		// Nothin
	}
	else if(kvWeaponMods == null)
	{
		LogToFile(eLog, "[Weapons] Critical Error! Unable to configure weapons from '%s!", WeaponCFG);
	}
	else
	{
		char weapon[64], wepIndexStr[768], attributes[768];
		for(int i=1; ; i++)
		{
			KvRewind(kvWeaponMods);
			Format(weapon, 10, "weapon%i", i);
			if(KvJumpToKey(kvWeaponMods, weapon))
			{
				int isOverride = KvGetNum(kvWeaponMods, "mode");
				KvGetString(kvWeaponMods, "classname", weapon, sizeof(weapon));
				KvGetString(kvWeaponMods, "index", wepIndexStr, sizeof(wepIndexStr));
				KvGetString(kvWeaponMods, "attributes", attributes, sizeof(attributes));
				if(isOverride)
				{
					if(StrContains(wepIndexStr, "-2")!=-1 && StrContains(classname, weapon, false)!=-1 || StrContains(wepIndexStr, "-1")!=-1 && StrEqual(classname, weapon, false))
					{
						if(isOverride != 3)
						{
							Handle itemOverride = PrepareItemHandle(item, _, _, attributes, isOverride==1 ? false : true);
							if(itemOverride != null)
							{
								item = itemOverride;
								return Plugin_Changed;
							}
						}
						else
						{
							return Plugin_Stop;
						}
					}
					if(StrContains(wepIndexStr, "-1")==-1 && StrContains(wepIndexStr, "-2")==-1)
					{
						int wepIndex;
						char wepIndexes[768][32];
						int weaponIdxcount = ExplodeString(wepIndexStr, " ; ", wepIndexes, sizeof(wepIndexes), 32);
						for(int wepIdx = 0; wepIdx<=weaponIdxcount ; wepIdx++)
						{
							if(strlen(wepIndexes[wepIdx])>0)
							{
								wepIndex = StringToInt(wepIndexes[wepIdx]);
								if(wepIndex == iItemDefinitionIndex)
								{
									switch(isOverride)
									{
										case 3:
										{
											return Plugin_Stop;
										}
										case 2, 1:
										{
											Handle itemOverride = PrepareItemHandle(item, _, _, attributes, isOverride==1 ? false : true);
											if(itemOverride != null)
											{
												item = itemOverride;
												return Plugin_Changed;
											}
										}
									}
								}
							}
						}
					}
				}
			}
			else
			{
				break;
			}
		}
		KvGoBack(kvWeaponMods);
	}

	if(GetConVarInt(cvarHardcodeWep)>0)
	{
		switch(iItemDefinitionIndex)
		{
			case 39, 1081:  //Flaregun
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.67");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 40, 1146:  //Backburner, Festive Backburner
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "170 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 41:  //Natascha
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "32 ; 0 ; 75 ; 1.34");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 43:  //Killing Gloves of Boxing
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "16 ; 50 ; 69 ; 0.2 ; 77 ; 0 ; 109 ; 0.5 ; 177 ; 2 ; 205 ; 0.7 ; 206 ; 0.7 ; 239 ; 0.6 ; 442 ; 1.35 ; 443 ; 1.1 ; 800 ; 0");
				// 16: +50 HP on hit
				// 69: -80% health from healers
				// 77: -100% max primary ammo
				// 109: -50% health from packs
				// 177: -100% weapon switch speed
				// 205: -30% damage from ranged while active
				// 206: -30% damage from melee while active
				// 239: -40% uber for healer
				// 442: +35% speed
				// 443: +10% jump
				// 800: -100% max overheal
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 44:  //Sandman
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "773 ; 1.15");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 56, 1005, 1092:  //Huntsman, Festive Huntsman, Fortified Compound
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "76 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 127:  //Direct Hit
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "179 ; 1.0");
					//179: Crit instead of mini-critting
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 128:  //Equalizer
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "740 ; 0 ; 239 ; 0.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 129:  //Buff Banner
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "319 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 131, 1144:  //Chargin' Targe
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "396 ; 0.95", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 140, 1086, 30668:  //Wrangler
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "54 ; 0.75 ; 128 ; 1 ; 206 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 153, 466:  //Homewrecker
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "394 ; 3 ; 215 ; 10 ; 522 ; 1 ; 216 ; 10");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 154:  //Pain Train
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "20 ; 1 ; 149 ; 6 ; 204 ; 1 ; 408 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 155:  //Southern Hospitality
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.6 ; 20 ; 1 ; 61 ; 1 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 171:  //Tribalman's Shiv
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "20 ; 1 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 173:  //Vita-Saw
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "125 ; -10 ; 17 ; 0.15 ; 737 ; 1.25", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 220:  //Shortstop
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "868 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 224:  //L'etranger
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "166 ; 5");
					//166: +5% cloak on hit
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 231:  //Darwin's Danger Shield
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 85 ; 800 ; 0.19 ; 69 ; 0.6 ; 109 ; 0.6", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 232:  //Bushwacka
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "58 ; 1.35");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 237:  //Rocket Jumper
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.3 ; 15 ; 0 ; 135 ; 0.5 ; 206 ; 2 ; 400 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 239, 1084, 1100:  //GRU, Festive GRU, Bread Bite
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 191 ; -7 ; 772 ; 1.5", true);
					//1: -50% damage
					//107: +50% move speed
					//128: Only when weapon is active
					//191: -7 health/second
					//772: Holsters 50% slower
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 265:  //Sticky Jumper
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.3 ; 15 ; 0 ; 89 ; -6 ; 135 ; 0.5 ; 206 ; 2 ; 280 ; 14 ; 400 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 305, 1079:  //Crusader's Crossbow, Festive Crusader's Crossbow
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "17 ; 0.2");
					//17: +20% uber on hit
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 312:  //Brass Beast
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "206 ; 1.35");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 317:  //Candy Cane
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "740 ; 0.5 ; 239 ; 0.75", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 325, 452, 812, 833:  //Boston Basher, Three-Rune Blade, Flying Guillotine(s)
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "20 ; 1 ; 138 ; 0.67 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 327:  //Claidheamh Mor
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "412 ; 1.2");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 329:  //Jag
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "92 ; 1.3 ; 6 ; 0.85 ; 95 ; 0.6 ; 1 ; 0.5 ; 137 ; 1.34", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 331:  //Fists of Steel
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "205 ; 0.65 ; 206 ; 0.65 ; 772 ; 2.0 ; 800 ; 0.6 ; 854 ; 0.6", true);
					//205: -35% damage from ranged while active
					//206: -35% damage from melee while active
					//772: Holsters 100% slower
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 348:  //Sharpened Volcano Fragment
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "16 ; 30 ; 69 ; 0.34 ; 77 ; 0 ; 109 ; 0.5 ; 773 ; 1.5 ; 205 ; 0.8 ; 206 ; 0.6 ; 239 ; 0.67 ; 442 ; 1.15 ; 443 ; 1.15 ; 800 ; 0.34");
				// 16: +30 HP on hit
				// 69: -66% health from healers
				// 77: -100% max primary ammo
				// 109: -50% health from packs
				// 773: -50% deploy speed
				// 205: -20% damage from ranged while active
				// 206: -40% damage from melee while active
				// 239: -33% uber for healer
				// 442: +15% speed
				// 443: +15% jump
				// 800: -66% max overheal
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 349:  //Sun-on-a-Stick
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.75 ; 795 ; 2", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 351:  //Detonator
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "25 ; 0.5 ; 58 ; 3.2 ; 79 ; 0.75 ; 144 ; 1.0 ; 207 ; 1.33", true);
					//25: -50% ammo
					//58: 220% self damage force
					//144: NOPE
					//207: +33% damage to self
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 355:  //Fan O'War
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.25 ; 6 ; 0.5 ; 49 ; 1 ; 137 ; 4 ; 107 ; 1.1 ; 201 ; 1.1 ; 77 ; 0.38", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 404:  //Persian Persuader
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "772 ; 1.15 ; 249 ; 0.6 ; 781 ; 1 ; 778 ; 0.5 ; 782 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 405, 608:  //Ali Baba's Wee Booties, Bootlegger
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 25 ; 246 ; 3 ; 107 ; 1.10", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 406:  //Splendid Screen
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "248 ; 2.6", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 414:  //Liberty Launcher
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.65 ; 206 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 415:  //Reserve Shooter
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "2 ; 1.1 ; 3 ; 0.5 ; 114 ; 1 ; 179 ; 1 ; 547 ; 0.6", true);
					//2: +10% damage bonus
					//3: -50% clip size
					//114: Mini-crits targets launched airborne by explosions, grapple hooks or enemy attacks
					//179: Minicrits become crits
					//547: Deploys 40% faster
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 416:  //Market Gardener
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "5 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 426:  //Eviction Notice
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.2 ; 6 ; 0.25 ; 107 ; 1.2 ; 737 ; 2.25", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 441:  //Cow Mangler
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "71 ; 2.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 444:  //Mantreads
			{
				#if defined _tf2attributes_included
				if(tf2attributes)
				{
					TF2Attrib_SetByDefIndex(client, 58, 1.5);
				}
				else
				{
					Handle itemOverride=PrepareItemHandle(item, _, _, "58 ; 1.5");
					if(itemOverride != INVALID_HANDLE)
					{
						item=itemOverride;
						return Plugin_Changed;
					}
				}
				#else
				Handle itemOverride=PrepareItemHandle(item, _, _, "58 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
				#endif
			}
			case 442, 588:  //Bison, Pomson
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "182 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 528:  //Short Circuit
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "20 ; 1 ; 182 ; 2 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 589:  //Eureka Effect
			{
				if(!GetConVarBool(cvarEnableEurekaEffect))  //Disabled
				{
					Handle itemOverride=PrepareItemHandle(item, _, _, "93 ; 0.25 ; 276 ; 1 ; 790 ; 0.5 ; 732 ; 0.9", true);
					if(itemOverride != INVALID_HANDLE)
					{
						item=itemOverride;
						return Plugin_Changed;
					}
				}
			}
			case 593:  //Third Degree
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "853 ; 0.8 ; 854 ; 0.8");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 595:  //Manmelter
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.35");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 648:  //Wrap Assassin
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.53 ; 20 ; 1 ; 138 ; 0.67 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 656:  //Holiday Punch
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "178 ; 0.001", true);
					//178: Switch 99.9% faster
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 730:  //Beggar's Bazooka
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "76 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 740:  //Scorch Shot
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "79 ; 0.75");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 772:  //Baby Face's Blaster
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "532 ; 1.2");
					//532: Hype decays
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 775:  //Escape Plan
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "740 ; 0 ; 206 ; 1.5 ; 239 ; 0.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 811, 832:  //Huo-Long Heater
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "71 ; 2.75");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 813, 834:  //Neon Annihilator
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "182 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1099:  //Tide Turner
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "639 ; 50", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1103:  //Back Scatter
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "179 ; 1");
					//179: Crit instead of mini-critting
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1104:  //Air Strike
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.82 ; 206 ; 1.25");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1179:  //Thermal Thruster
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "872 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1180:  //Gas Passer
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "875 ; 1 ; 2059 ; 3000");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1181:  //Hot Hand
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "877 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
		}
		if(TF2_GetPlayerClass(client)==TFClass_Medic && !StrContains(classname, "tf_weapon_syringegun_medic"))  //Syringe guns
		{
			Handle itemOverride=PrepareItemHandle(item, _, _, "17 ; 0.05");
				//17: 5% uber on hit
			if(itemOverride != INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		else if(TF2_GetPlayerClass(client)==TFClass_Medic && !StrContains(classname, "tf_weapon_medigun"))  //Medi Gun
		{
			Handle itemOverride;
			switch(iItemDefinitionIndex == 35)  //Kritzkrieg
			{
				case 35:
					itemOverride=PrepareItemHandle(item, _, _, "10 ; 2.25 ; 11 ; 1.5 ; 18 ; 1 ; 199 ; 0.75 ; 314 ; 3 ; 547 ; 0.75");
					//10: +125% faster charge rate
					//11: +50% overheal bonus
					//18: Kritzkrieg uber
					//199: Deploys 25% faster
					//547: Holsters 25% faster

				case 411:  //Quick-Fix
					itemOverride=PrepareItemHandle(item, _, _, "8 ; 1.0 ; 10 ; 2 ; 105 ; 1 ; 144 ; 2 ; 199 ; 0.75 ; 231 ; 2 ; 493 ; 2 ; 547 ; 0.75");
					//8: +0% heal rate
					//10: +100% faster charge rate
					//105: Default Medi-Gun overheal
					//144: Quick-fix speed/jump effects
					//199: Deploys 25% faster
					//231: Quick-fix no-knockback uber
					//493: Healing mastery level 2
					//547: Holsters 25% faster

				case 998:  //Vaccinator
					itemOverride = PrepareItemHandle(item, _, _, "10 ; 2.5 ; 11 ; 1.5 ; 199 ; 0.75 ; 314 ; -3 ; 479 ; 0.34 ; 499 ; 1 ; 547 ; 0.75 ; 739 ; 0.34", true);
					//10: +150% faster charge rate
					//11: +50% overheal bonus
					//199: Deploys 25% faster
					//314: -3 sec uber duration
					//479: -66% overheal build rate
					//499: Projectile sheild level 1
					//547: Holsters 25% faster
					//739: -66% uber rate when overhealing

				default:
					itemOverride = PrepareItemHandle(item, _, _, "10 ; 1.75 ; 11 ; 1.5 ; 144 ; 2.0 ; 199 ; 0.75 ; 547 ; 0.75");
					//10: +75% faster charge rate
					//11: +50% overheal bonus
					//144: Quick-fix speed/jump effects
					//199: Deploys 25% faster
					//547: Holsters 25% faster
			}

			if(itemOverride != INVALID_HANDLE)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

stock Handle PrepareItemHandle(Handle item, char[] name="", int index=-1, const char[] att="", bool dontPreserve=false)
{
	static Handle weapon;
	int addattribs;

	char weaponAttribsArray[32][32];
	int attribCount=ExplodeString(att, ";", weaponAttribsArray, 32, 32);

	if(attribCount % 2)
	{
		--attribCount;
	}

	int flags=OVERRIDE_ATTRIBUTES;
	if(!dontPreserve)
	{
		flags|=PRESERVE_ATTRIBUTES;
	}

	if(weapon==INVALID_HANDLE)
	{
		weapon=TF2Items_CreateItem(flags);
	}
	else
	{
		TF2Items_SetFlags(weapon, flags);
	}

	if(item!=INVALID_HANDLE)
	{
		addattribs=TF2Items_GetNumAttributes(item);
		if(addattribs>0)
		{
			for(int i; i<2*addattribs; i+=2)
			{
				bool dontAdd=false;
				int attribIndex=TF2Items_GetAttributeId(item, i);
				for(int z; z<attribCount+i; z+=2)
				{
					if(StringToInt(weaponAttribsArray[z])==attribIndex)
					{
						dontAdd=true;
						break;
					}
				}

				if(!dontAdd)
				{
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
					FloatToString(TF2Items_GetAttributeValue(item, i), weaponAttribsArray[i+1+attribCount], 32);
				}
			}
			attribCount+=2*addattribs;
		}

		if(weapon!=item)  //FlaminSarge: Item might be equal to weapon, so closing item's handle would also close weapon's
		{
			CloseHandle(item);  //probably returns false but whatever (rswallen-apparently not)
		}
	}

	if(name[0]!='\0')
	{
		flags|=OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(weapon, name);
	}

	if(index!=-1)
	{
		flags|=OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(weapon, index);
	}

	if(attribCount>0)
	{
		TF2Items_SetNumAttributes(weapon, attribCount/2);
		int i2;
		for(int i; i<attribCount && i2<16; i+=2)
		{
			int attrib = StringToInt(weaponAttribsArray[i]);
			if(!attrib)
			{
				LogToFile(eLog, "[Weapons] Bad weapon attribute passed: %s ; %s", weaponAttribsArray[i], weaponAttribsArray[i+1]);
				CloseHandle(weapon);
				return INVALID_HANDLE;
			}

			TF2Items_SetAttribute(weapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}
	TF2Items_SetFlags(weapon, flags);
	return weapon;
}

public Action Timer_MakeNotBoss(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==2 || IsBoss(client) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
		return Plugin_Continue;

	if(!IsVoteInProgress() && ToggleInfo[client] && !(FF2flags[client] & FF2FLAG_CLASSHELPED))
		HelpPanelClass(client);

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);  //This really shouldn't be needed but I've been noticing players who still have glow

	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client)); //Temporary: Reset health to avoid an overheal bug
	if(!Enabled3 && GetClientTeam(client)==BossTeam)
		AssignTeam(client, OtherTeam);

	CreateTimer(0.1, Timer_CheckItems, userid, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_CheckItems(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==2 || IsBoss(client) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
		return Plugin_Continue;

	SetEntityRenderColor(client, 255, 255, 255, 255);
	hadshield[client] = false;
	shield[client] = 0;
	int[] civilianCheck = new int[MaxClients+1];

	int weapon = GetPlayerWeaponSlot(client, 4);
	if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==60 && (kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0))  //Cloak and Dagger
	{
		TF2_RemoveWeaponSlot(client, 4);
		SpawnWeapon(client, "tf_weapon_invis", 60, 1, 0, "35 ; 1.65 ; 728 ; 1 ; 729 ; 0.65");
	}

	if(bMedieval)
		return Plugin_Continue;

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==402 && (kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0))
	{
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
		SpawnWeapon(client, "tf_weapon_sniperrifle", 402, 1, 6, "91 ; 0.5 ; 75 ; 3.75 ; 178 ; 0.8");
	}
	else
	{
		civilianCheck[client]++;
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(weapon))
	{
		if(TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 142)  //Gunslinger (Randomizer, etc. compatability)
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, 75);
			}
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	int playerBack = FindPlayerBack(client, 57);  //Razorback
	shield[client] = IsValidEntity(playerBack) ? playerBack : 0;
	hadshield[client] = IsValidEntity(playerBack) ? true : false;
	if(IsValidEntity(FindPlayerBack(client, 642)))  //Cozy Camper
		SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "149 ; 1.5 ; 15 ; 0.0 ; 1 ; 0.75");

	#if defined _tf2attributes_included
	if(tf2attributes && (kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0))
	{
		if(IsValidEntity(FindPlayerBack(client, 444)))  //Mantreads
		{
			TF2Attrib_SetByDefIndex(client, 58, 1.5);  //+50% increased push force
		}
		else
		{
			TF2Attrib_RemoveByDefIndex(client, 58);
		}
	}
	#endif

	int entity = -1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield")) != -1)  //Demoshields
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			shield[client] = entity;
			hadshield[client] = true;
		}
	}

	if(IsValidEntity(shield[client]))
	{
		shieldHP[client] = GetConVarFloat(cvarShieldHealth);
		shDmgReduction[client] = 1.0-GetConVarFloat(cvarShieldResist);
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(!IsValidEntity(weapon))
		civilianCheck[client]++;

	if(civilianCheck[client] == 3)
	{
		civilianCheck[client] = 0;
		TF2_RespawnPlayer(client);
	}
	civilianCheck[client] = 0;
	return Plugin_Continue;
}

stock void RemovePlayerTarge(int client)
{
	int entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)
	{
		int index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			if(index==131 || index==406 || index==1099 || index==1144)  //Chargin' Targe, Splendid Screen, Tide Turner, Festive Chargin' Targe
				TF2_RemoveWearable(client, entity);
		}
	}
}

stock int RemovePlayerBack(int client, int[] indices, int length)
{
	if(length<=0)
		return;

	int entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(int i; i<length; i++)
				{
					if(index==indices[i])
						TF2_RemoveWearable(client, entity);
				}
			}
		}
	}
}

stock int FindPlayerBack(int client, int index)
{
	int entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable*"))!=-1)
	{
		char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrContains(netclass, "CTFWearable")>-1 && GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")==index && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			return entity;
	}
	return -1;
}

public Action OnObjectDestroyed(Handle event, const char[] name, bool dontBroadcast)
{
	if(Enabled)
	{
		int attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
		if(!GetRandomInt(0, 2) && IsBoss(attacker))
		{
			char sound[PLATFORM_MAX_PATH];
			if(RandomSound("sound_kill_buildable", sound, sizeof(sound), GetBossIndex(attacker)))
				EmitSoundToAllExcept(sound);
		}
	}
	return Plugin_Continue;
}

public Action OnUberDeployed(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Enabled && IsValidClient(client) && IsPlayerAlive(client))
	{
		int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(medigun))
		{
			char classname[64];
			GetEntityClassname(medigun, classname, sizeof(classname));
			if(StrEqual(classname, "tf_weapon_medigun"))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5, client);
				int target = GetHealingTarget(client);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
					uberTarget[client] = target;
				}
				else
				{
					uberTarget[client] = -1;
				}
				CreateTimer(0.4, Timer_Uber, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Uber(Handle timer, any medigunid)
{
	int medigun = EntRefToEntIndex(medigunid);
	if(medigun && IsValidEntity(medigun) && CheckRoundState()==1)
	{
		int client = GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		float charge = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if(IsValidClient(client, false) && IsPlayerAlive(client) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==medigun)
		{
			int target = GetHealingTarget(client);
			if(charge > 0.05)
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5);
					uberTarget[client] = target;
				}
				else
				{
					uberTarget[client] = -1;
				}
			}
			else
			{
				return Plugin_Stop;
			}
		}
		else if(charge <= 0.05)
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Command_GetHPCmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!Enabled2)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(CheckRoundState()!=1 || GetConVarInt(cvarHealthHud)>1)
		return Plugin_Continue;

	Command_GetHP(client);
	return Plugin_Handled;
}

public Action Command_GetHP(int client)  //TODO: This can rarely show a very large negative number if you time it right
{
	if(IsBoss(client) || GetGameTime()>=HPTime)
	{
		char text[MAXPLAYERS+1][512], lives[8], name[64];
		for(int target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				int boss = Boss[target];
				strcopy(name, sizeof(name), "=Failed name=");
				if(BossLives[boss] > 1)
				{
					Format(lives, sizeof(lives), "x%i", BossLives[boss]);
				}
				else
				{
					lives[0] = '\0';
				}

				for(int clients; clients<=MaxClients; clients++)
				{
					if(IsValidClient(clients))
					{
						GetBossSpecial(Special[boss], name, sizeof(name), clients);
						Format(text[clients], sizeof(text[]), "%s\n%t", text[clients], "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
						FPrintToChat(clients, "%t", "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
					}
				}
				BossHealthLast[boss] = BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			}
		}

		for(int target; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
			{
				if(bosses<2 && GetConVarInt(cvarGameText)>0)
				{
					if(strlen(BossIcon))
					{
						ShowGameText(target, BossIcon, _, text[client]);
					}
					else
					{
						ShowGameText(target, "leaderboard_streak", _, text[client]);
					}
				}
				else
				{
					PrintCenterText(target, text[client]);
				}
			}
		}

		if(GetGameTime() >= HPTime)
		{
			healthcheckused++;
			HPTime = GetGameTime()+(healthcheckused<3 ? 20.0 : 80.0);
		}
		return Plugin_Continue;
	}

	char waitTime[128];
	for(int target; target<=MaxClients; target++)
	{
		if(IsBoss(target))
			Format(waitTime, sizeof(waitTime), "%s %i,", waitTime, BossHealthLast[Boss[target]]);
	}
	FPrintToChat(client, "%t", "wait_hp", RoundFloat(HPTime-GetGameTime()), waitTime);
	return Plugin_Continue;
}

public Action Command_SetNextBoss(int client, int args)
{
	char boss[64];

	if(args < 1)
	{
		if(!IsValidClient(client))
		{
			ReplyToCommand(client, "[SM] Usage: ff2_special <boss>");
			return Plugin_Handled;
		}

		GetBossSpecial(Incoming[0], boss, sizeof(boss), client);

		Handle dMenu = CreateMenu(Command_SetNextBossH);
		SetMenuTitle(dMenu, "Override Next Boss\n  Current Selection: %s", boss);

		Format(boss, sizeof(boss), "No Override");
		AddMenuItem(dMenu, boss, boss);

		for(int config; config<Specials; config++)
		{
			GetBossSpecial(config, boss, sizeof(boss), client);
			AddMenuItem(dMenu, boss, boss);
		}

		SetMenuExitButton(dMenu, true);
		DisplayMenu(dMenu, client, 20);
		return Plugin_Handled;
	}

	char name[64];
	GetCmdArgString(name, sizeof(name));

	for(int config; config<Specials; config++)
	{
		GetBossSpecial(config, boss, sizeof(boss), client);
		if(StrContains(boss, name, false) != -1)
		{
			Incoming[0] = config;
			FReplyToCommand(client, "Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrContains(boss, name, false) != -1)
		{
			Incoming[0] = config;
			GetBossSpecial(config, boss, sizeof(boss), client);
			FReplyToCommand(client, "Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvGetString(BossKV[config], "filename", boss, sizeof(boss));
		if(StrContains(boss, name, false) != -1)
		{
			Incoming[0] = config;
			GetBossSpecial(config, boss, sizeof(boss), client);
			FReplyToCommand(client, "Set the next boss to %s", boss);
			return Plugin_Handled;
		}
	}
	FReplyToCommand(client, "Boss could not be found!");
	return Plugin_Handled;
}

public int Command_SetNextBossH(Handle menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			switch(choice)
			{
				case 0:
				{
					Incoming[0] = '\0';
					FReplyToCommand(client, "No override to the next boss");
				}
				default:
				{
					int choice2 = choice-1;
					Incoming[0] = choice2;
					char boss[64];
					GetBossSpecial(choice2, boss, sizeof(boss), client);
					FReplyToCommand(client, "Set the next boss to %s", boss);
				}
			}
		}
	}
}

public Action Command_Points(int client, int args)
{
	if(args!=2)
	{
		FReplyToCommand(client, "Usage: ff2_addpoints <target> <points>");
		return Plugin_Handled;
	}

	char stringPoints[8], pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, stringPoints, sizeof(stringPoints));
	int points = StringToInt(stringPoints);

	char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches>1)
	{
		for(int target; target<matches; target++)
		{
			if(!IsClientSourceTV(targets[target]) && !IsClientReplay(targets[target]))
			{
				QueuePoints[targets[target]] += points;
				LogAction(client, targets[target], "\"%L\" added %d queue points to \"%L\"", client, points, targets[target]);
			}
		}
	}
	else
	{
		QueuePoints[targets[0]] += points;
		LogAction(client, targets[0], "\"%L\" added %d queue points to \"%L\"", client, points, targets[0]);
	}
	FReplyToCommand(client, "Added %d queue points to %s", points, targetName);
	return Plugin_Handled;
}

public Action Command_StartMusic(int client, int args)
{
	if(Enabled2)
	{
		if(args)
		{
			char pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			char targetName[MAX_TARGET_LENGTH];
			int targets[MAXPLAYERS], matches;
			bool targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches>1)
			{
				for(int target; target<matches; target++)
				{
					StartMusic(targets[target]);
				}
			}
			else
			{
				StartMusic(targets[0]);
			}
			FReplyToCommand(client, "Started boss music for %s.", targetName);
		}
		else
		{
			StartMusic();
			FReplyToCommand(client, "Started boss music for all clients.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_StopMusic(int client, int args)
{
	if(Enabled2)
	{
		if(args)
		{
			char pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			char targetName[MAX_TARGET_LENGTH];
			int targets[MAXPLAYERS], matches;
			bool targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches>1)
			{
				for(int target; target<matches; target++)
				{
					StopMusic(targets[target], true);
				}
			}
			else
			{
				StopMusic(targets[0], true);
			}
			FReplyToCommand(client, "Stopped boss music for %s.", targetName);
		}
		else
		{
			StopMusic(_, true);
			FReplyToCommand(client, "Stopped boss music for all clients.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_Charset(int client, int args)
{
	if(!args)
	{
		if(!client)
		{
			ReplyToCommand(client, "[SM] Usage: ff2_charset <charset>");
			return Plugin_Handled;
		}
		if(IsVoteInProgress())
		{
			ReplyToCommand(client, "[SM] %t", "Vote in Progress");
			return Plugin_Handled;
		}

		Handle menu=CreateMenu(Handler_VoteCharset, view_as<MenuAction>(MENU_ACTIONS_ALL));
		SetMenuTitle(menu, "Charset");

		char config[PLATFORM_MAX_PATH], charset[64];
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, CharsetCFG);

		Handle Kv=CreateKeyValues("");
		FileToKeyValues(Kv, config);
		int total, charsets;
		AddMenuItem(menu, "Random", "Random");
		do
		{
			total++;
			KvGetSectionName(Kv, charset, sizeof(charset));
			AddMenuItem(menu, charset, charset);

			if(KvGetNum(Kv, "hidden", 0))
				continue;

			charsets++;
			validCharsets[charsets]=total;
		}
		while(KvGotoNextKey(Kv));
		CloseHandle(Kv);

		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
		return Plugin_Handled;
	}

	char charset[32], rawText[16][16];
	GetCmdArgString(charset, sizeof(charset));
	int amount=ExplodeString(charset, " ", rawText, 16, 16);
	for(int i; i<amount; i++)
	{
		StripQuotes(rawText[i]);
	}
	ImplodeStrings(rawText, amount, " ", charset, sizeof(charset));

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, CharsetCFG);

	Handle Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(int i; ; i++)
	{
		KvGetSectionName(Kv, config, sizeof(config));
		if(StrContains(config, charset, false)>=0)
		{
			FReplyToCommand(client, "Charset for nextmap is %s", config);
			isCharSetSelected=true;
			FF2CharSet=i;
			break;
		}

		if(!KvGotoNextKey(Kv))
		{
			FReplyToCommand(client, "Charset not found");
			break;
		}
	}
	CloseHandle(Kv);
	return Plugin_Handled;
}

public int Command_CharsetH(Handle menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			FF2CharSet=choice ? choice-1 : validCharsets[GetRandomInt(1, FF2CharSet)]-1;

			char nextmap[32];
			GetConVarString(cvarNextmap, nextmap, sizeof(nextmap));
			GetMenuItem(menu, choice, FF2CharSetString, sizeof(FF2CharSetString));
			FPrintToChat(client, "%t", "nextmap_charset", nextmap, FF2CharSetString);
			isCharSetSelected=true;
		}
	}
}

public Action Command_LoadCharset(int client, int args)
{
	if(!args)
	{
		if(!client)
		{
			ReplyToCommand(client, "[SM] Usage: ff2_loadcharset <charset>");
			return Plugin_Handled;
		}
		if(IsVoteInProgress())
		{
			ReplyToCommand(client, "[SM] %t", "Vote in Progress");
			return Plugin_Handled;
		}

		Handle menu=CreateMenu(Handler_VoteCharset, view_as<MenuAction>(MENU_ACTIONS_ALL));
		SetMenuTitle(menu, "Charset");

		char config[PLATFORM_MAX_PATH], charset[64];
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, CharsetCFG);

		Handle Kv=CreateKeyValues("");
		FileToKeyValues(Kv, config);
		int total, charsets;
		AddMenuItem(menu, "Random", "Random");
		do
		{
			total++;
			KvGetSectionName(Kv, charset, sizeof(charset));
			AddMenuItem(menu, charset, charset);

			if(KvGetNum(Kv, "hidden", 0))
				continue;

			charsets++;
			validCharsets[charsets]=total;
		}
		while(KvGotoNextKey(Kv));
		CloseHandle(Kv);

		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
		return Plugin_Handled;
	}

	char charset[32], rawText[16][16];
	GetCmdArgString(charset, sizeof(charset));
	int amount=ExplodeString(charset, " ", rawText, 16, 16);
	for(int i; i<amount; i++)
	{
		StripQuotes(rawText[i]);
	}
	ImplodeStrings(rawText, amount, " ", charset, sizeof(charset));

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, CharsetCFG);

	Handle Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(int i; ; i++)
	{
		KvGetSectionName(Kv, config, sizeof(config));
		if(StrContains(config, charset, false)>=0)
		{
			FF2CharSet=i;
			LoadCharset=true;
			if(CheckRoundState()==0 || CheckRoundState()==1)
			{
				FReplyToCommand(client, "The current character set is set to be switched to %s!", config);
				return Plugin_Handled;
			}

			FReplyToCommand(client, "Character set has been switched to %s", config);
			FindCharacters();
			strcopy(FF2CharSetString, 2, "");
			LoadCharset=false;
			break;
		}

		if(!KvGotoNextKey(Kv))
		{
			FReplyToCommand(client, "Charset not found");
			break;
		}
	}
	CloseHandle(Kv);
	return Plugin_Handled;
}

public int Command_LoadCharsetH(Handle menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			FF2CharSet = choice ? choice-1 : validCharsets[GetRandomInt(1, FF2CharSet)]-1;
			LoadCharset = true;
			if(CheckRoundState()==0 || CheckRoundState()==1)
			{
				FReplyToCommand(client, "The current character set is set to be switched to %i!", FF2CharSet);
			}
			else
			{
				FReplyToCommand(client, "Character set has been switched to %i", FF2CharSet);
				FindCharacters();
				strcopy(FF2CharSetString, 2, "");
				LoadCharset = false;
			}
		}
	}
}

public Action Command_ReloadFF2(int client, int args)
{
	if(ReloadFF2)
	{
		FReplyToCommand(client, "The plugin is no longer set to reload.");
		ReloadFF2 = false;
		return Plugin_Handled;
	}
	ReloadFF2 = true;
	if(CheckRoundState()==0 || CheckRoundState()==1)
	{
		FReplyToCommand(client, "The plugin is set to reload.");
		return Plugin_Handled;
	}
	FReplyToCommand(client, "The plugin has been reloaded.");
	ReloadFF2 = false;
	ServerCommand("sm plugins reload freak_fortress_2");
	return Plugin_Handled;
}

public Action Command_ReloadCharset(int client, int args)
{
	if(LoadCharset)
	{
		FReplyToCommand(client, "Current character set no longer set to reload!");
		LoadCharset = false;
		return Plugin_Handled;
	}
	LoadCharset = true;
	if(CheckRoundState()==0 || CheckRoundState()==1)
	{
		FReplyToCommand(client, "Current character set is set to reload!");
		return Plugin_Handled;
	}
	FReplyToCommand(client, "Current character set has been reloaded!");
	FindCharacters();
	LoadCharset=false;
	return Plugin_Handled;
}

public Action Command_ReloadFF2Weapons(int client, int args)
{
	if(ReloadWeapons)
	{
		FReplyToCommand(client, "%s is no longer set to reload!", WeaponCFG);
		ReloadWeapons = false;
		return Plugin_Handled;
	}
	ReloadWeapons = true;
	if(CheckRoundState()==0 || CheckRoundState()==1)
	{
		FReplyToCommand(client, "%s is set to reload!", WeaponCFG);
		return Plugin_Handled;
	}
	FReplyToCommand(client, "%s has been reloaded!", WeaponCFG);
	CacheWeapons();
	ReloadWeapons=false;
	return Plugin_Handled;
}

public Action Command_ReloadFF2Configs(int client, int args)
{
	if(ReloadConfigs)
	{
		FReplyToCommand(client, "All configs are no longer set to be reloaded!");
		ReloadConfigs = false;
		return Plugin_Handled;
	}
	ReloadConfigs = true;
	if(CheckRoundState()==0 || CheckRoundState()==1)
	{
		FReplyToCommand(client, "All configs are set to be reloaded!");
		return Plugin_Handled;
	}
	CacheWeapons();
	CheckToChangeMapDoors();
	CheckToTeleportToSpawn();
	FindCharacters();
	ReloadConfigs = false;
	return Plugin_Handled;
}

public Action Command_ReloadSubPlugins(int client, int args)
{
	if(!Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(!args) // Reload ALL subplugins
	{
		DisableSubPlugins(true);
		EnableSubPlugins(true);
		FReplyToCommand(client, "Reloaded all subplugins!");
		return Plugin_Handled;
	}

	char pluginName[PLATFORM_MAX_PATH];
	GetCmdArg(1, pluginName, sizeof(pluginName));
	BuildPath(Path_SM, pluginName, sizeof(pluginName), "plugins/freaks/%s.ff2", pluginName);
	if(!FileExists(pluginName))
	{
		FReplyToCommand(client, "Subplugin %s does not exist!", pluginName);
		return Plugin_Handled;
	}
	ReplaceString(pluginName, sizeof(pluginName), "addons/sourcemod/plugins/freaks/", "freaks/", false);
	ServerCommand("sm plugins unload %s", pluginName);
	ServerCommand("sm plugins load %s", pluginName);
	ReplaceString(pluginName, sizeof(pluginName), "freaks/", " ", false);
	FReplyToCommand(client, "Reloaded subplugin %s!", pluginName);
	return Plugin_Handled;
}

public Action Command_Point_Disable(int client, int args)
{
	if(Enabled)
	{
		SetControlPoint(false);
		return Plugin_Handled;
	}
	FReplyToCommand(client, "%t", "FF2 Disabled");
	return Plugin_Handled;
}

public Action Command_Point_Enable(int client, int args)
{
	if(Enabled)
	{
		SetControlPoint(true);
		return Plugin_Handled;
	}
	FReplyToCommand(client, "%t", "FF2 Disabled");
	return Plugin_Handled;
}

stock void SetControlPoint(bool enable)
{
	int controlPoint=MaxClients+1;
	while((controlPoint=FindEntityByClassname2(controlPoint, "team_control_point"))!=-1)
	{
		if(controlPoint>MaxClients && IsValidEntity(controlPoint))
		{
			AcceptEntityInput(controlPoint, (enable ? "ShowModel" : "HideModel"));
			SetVariantInt(enable ? 0 : 1);
			AcceptEntityInput(controlPoint, "SetLocked");
		}
	}
}

stock void SetArenaCapEnableTime(float time)
{
	int entity=-1;
	if((entity=FindEntityByClassname2(-1, "tf_logic_arena"))!=-1 && IsValidEntity(entity))
	{
		char timeString[32];
		FloatToString(time, timeString, sizeof(timeString));
		DispatchKeyValue(entity, "CapEnableDelay", timeString);
	}
}

#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=7
public int OnRebuildAdminCache(AdminCachePart part)
#else
public void OnRebuildAdminCache(AdminCachePart part)
#endif
{
	if(part == AdminCache_Overrides)
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && strlen(xIncoming[client]))
			{
				if(!CheckValidBoss(client, xIncoming[client], !DuoMin))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = '\0';
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
				}
			}
		}
	}
}

public void OnClientPostAdminCheck(int client)
{
	// TODO: Hook these inside of EnableFF2() or somewhere instead
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

	FF2flags[client] = 0;
	Damage[client] = 0;
	uberTarget[client] = -1;
	xIncoming[client][0] = '\0';
	CanBossVs[client] = 0;
	CanBossTeam[client] = 0;

	if(AreClientCookiesCached(client))
	{
		char buffer[24];
		GetClientCookie(client, FF2Cookies, buffer, sizeof(buffer));
		if(!buffer[0])
			SetClientCookie(client, FF2Cookies, "0 1 1 1 0 0 3");
			//Queue points | music exception | voice exception | class info | companion toggle | boss toggle | UNUSED

		SetupClientPreferences(client);

		GetClientCookie(client, StatCookies, buffer, sizeof(buffer));
		if(!buffer[0])
			SetClientCookie(client, StatCookies, "0 0 0 0 0 0 0");
			//Boss wins | boss losses | boss kills | boss deaths | player kills | player MVPs | UNUSED

		SetupClientStats(client);

		GetClientCookie(client, SelectionCookie, buffer, sizeof(buffer));
		if(buffer[0])
		{
			if(CheckValidBoss(client, buffer, !DuoMin))
				strcopy(xIncoming[client], sizeof(xIncoming[]), buffer);
		}
	}

	//We use the 0th index here because client indices can change.
	//If this is false that means music is disabled for all clients, so don't play it for new clients either.
	if(playBGM[0])
	{
		playBGM[client] = true;
		if(Enabled)
			CreateTimer(0.1, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		playBGM[client] = false;
	}
}

public void OnClientDisconnect(int client)
{
	if(IsBoss(client) && !CheckRoundState() && GetConVarBool(cvarPreroundBossDisconnect))
	{
		int boss = GetBossIndex(client);
		bool[] omit = new bool[MaxClients+1];
		omit[client] = true;
		Boss[boss] = GetClientWithoutBlacklist(omit, BossSwitched[boss] ? BossTeam : OtherTeam);
		PickCharacter(boss, boss);
		if((Special[boss]<0) || !BossKV[Special[boss]])
			LogToFile(eLog, "[!!!] Couldn't find a boss for index %i!", boss);

		if(Boss[boss])
		{
			CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
			FPrintToChat(Boss[boss], "%t", "Replace Disconnected Boss");
			FPrintToChatAll("%t", "Boss Disconnected", client, Boss[boss]);
		}
	}

	if(IsBoss(client) && (CheckRoundState()==0 || CheckRoundState()==1))
		AddClientStats(client, Cookie_BossLosses, 1);

	if(Enabled && IsClientInGame(client) && IsPlayerAlive(client) && CheckRoundState()==1)
		CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);

	FF2flags[client] = 0;
	Damage[client] = 0;
	uberTarget[client] = -1;
	xIncoming[client][0] = '\0';
	CanBossVs[client] = 0;
	SaveClientStats(client);
	SaveClientPreferences(client);

	if(playing>=GetConVarInt(cvarDuoMin) && !DuoMin)  // Check if theres enough players for companions
	{
		DuoMin = true;
	}
	else if(DuoMin)
	{
		DuoMin = false;
		for(int clients=1; clients<=MaxClients; clients++)
		{
			if(IsValidClient(clients) && strlen(xIncoming[clients]))
			{
				if(!CheckValidBoss(clients, xIncoming[clients], true))
				{
					FPrintToChat(clients, "%t", "boss_selection_reset");
					xIncoming[clients][0] = '\0';
					CanBossVs[clients] = 0;
					CanBossTeam[client] = 0;
				}
			}
		}
	}

	if(MusicTimer[client] != INVALID_HANDLE)
	{
		KillTimer(MusicTimer[client]);
		MusicTimer[client] = INVALID_HANDLE;
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(Enabled && CheckRoundState()==1)
	{
		CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action OnPostInventoryApplication(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
		return Plugin_Continue;

	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");

	if(IsBoss(client))
		CreateTimer(0.1, Timer_MakeBoss, GetBossIndex(client), TIMER_FLAG_NO_MAPCHANGE);

	if(!(FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		if(!(FF2flags[client] & FF2FLAG_HASONGIVED))
		{
			FF2flags[client]|=FF2FLAG_HASONGIVED;
			RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
			RemovePlayerTarge(client);
			TF2_RemoveAllWeapons(client);
			TF2_RegeneratePlayer(client);
			CreateTimer(0.1, Timer_RegenPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		CreateTimer(0.2, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	FF2flags[client]&=~(FF2FLAG_UBERREADY|FF2FLAG_ISBUFFED|FF2FLAG_TALKING|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_USINGABILITY|FF2FLAG_CLASSHELPED|FF2FLAG_CHANGECVAR|FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS|FF2FLAG_ROCKET_JUMPING);
	FF2flags[client]|=FF2FLAG_USEBOSSTIMER;
	return Plugin_Continue;
}

public Action Timer_RegenPlayer(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
		TF2_RegeneratePlayer(client);
}

public Action ClientTimer(Handle timer)
{
	if(!Enabled)
		return Plugin_Stop;

	#if defined _tf2attributes_included
	if(tf2attributes)
	{
		for(int client=1; client<=MaxClients; client++)
		{
			//custom model disguise code sorta taken from stop that tank, let's see how well this goes!
			//this will actually let spies disguise as the boss, and bosses should have the same disguise
			//model as the players they potentially disguise as if they have a custom model (tf2attributes required)
			if(IsValidClient(client))
			{
				int iDisguisedTarget = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
				VisionFlags_Update(client);

				if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && TF2_GetPlayerClass(iDisguisedTarget)==view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass")))
				{
					ModelOverrides_Think(client, iDisguisedTarget);
				}
				else
				{
					ModelOverrides_Clear(client);
				}
			}
		}
	}
	#endif

	if(CheckRoundState()==2 || CheckRoundState()==-1)
		return Plugin_Stop;

	char classname[32], top[64];
	TFCond cond;
	bool alive;
	int StatHud = GetConVarInt(cvarStatHud);
	int HealHud = GetConVarInt(cvarHealingHud);
	float LookHud = GetConVarFloat(cvarLookHud);
	int SapperAmount;
	bool SapperEnabled = SapperMinion;
	if(!SapperEnabled)
	{
		for(int boss=1; boss<=MaxClients; boss++)
		{
			if(IsBoss(boss))
			{
				SapperEnabled = SapperBoss[boss];
				if(SapperEnabled)
					break;
			}
		}
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && !(FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED))
		{
			alive = IsPlayerAlive(client);
			if(!IsFakeClient(client))
			{
				SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
				int observer;
				if(alive && LookHud!=0)
				{
					observer = GetClientAimTarget(client, true);
					if(!IsValidClient(observer) || observer==client)
					{
						observer = 0;
					}
					else if(TF2_IsPlayerInCondition(observer, TFCond_Disguised) || TF2_IsPlayerInCondition(observer, TFCond_Cloaked) || TF2_GetClientTeam(client)!=TF2_GetClientTeam(observer))
					{
						observer = 0;
					}
					else if(LookHud > 0)
					{
						float position[3], position2[3], distance;
						GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
						GetEntPropVector(observer, Prop_Send, "m_vecOrigin", position2);
						distance = GetVectorDistance(position, position2);
						if(distance > LookHud)
							observer = 0;
					}
				}
				else if(IsClientObserver(client))
				{
					observer = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
					if(!IsValidClient(observer) || observer==client)
						observer = 0;
				}

				if(StatHud>-1 && (CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>0))
				{
					if((CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>1) && (LookHud!=0 || !alive))
					{
						if((Healing[client]>0 && HealHud==1) || HealHud>1)
						{
							Format(top, sizeof(top), "%t", "Self Stats Healing", Damage[client], Healing[client], PlayerKills[client], PlayerMVPs[client]);
						}
						else
						{
							Format(top, sizeof(top), "%t", "Self Stats", Damage[client], PlayerKills[client], PlayerMVPs[client]);
						}
					}
					else
					{
						if((Healing[client]>0 && HealHud==1) || HealHud>1)
						{
							Format(top, sizeof(top), "%t", "Stats Healing", Damage[client], Healing[client], PlayerKills[client], PlayerMVPs[client]);
						}
						else
						{
							Format(top, sizeof(top), "%t", "Stats", Damage[client], PlayerKills[client], PlayerMVPs[client]);
						}
					}
				}
				else
				{
					if(observer && !IsBoss(observer))
					{
						if((Healing[client]>0 && HealHud==1) || HealHud>1)
						{
							Format(top, sizeof(top), "%t %t | ", "Your Damage Dealt", Damage[client], "Healing", Healing[client]);
						}
						else
						{
							Format(top, sizeof(top), "%t | ", "Your Damage Dealt", Damage[client]);
						}
					}
					else
					{
						if((Healing[client]>0 && HealHud==1) || HealHud>1)
						{
							Format(top, sizeof(top), "%t %t", "Your Damage Dealt", Damage[client], "Healing", Healing[client]);
						}
						else
						{
							Format(top, sizeof(top), "%t", "Your Damage Dealt", Damage[client]);
						}
					}
				}

				if(observer)
				{
					if(StatHud>-1 && (CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>1))
					{
						if(IsBoss(observer))
						{
							FF2_ShowSyncHudText(client, statHUD, "%s%t", top, "Player Stats Boss", observer, BossWins[observer], BossLosses[observer], BossKills[observer], BossDeaths[observer]);
						}
						else if((Healing[observer]>0 && HealHud==1) || HealHud>1)
						{
							FF2_ShowSyncHudText(client, statHUD, "%s%t", top, "Player Stats Healing", observer, Damage[observer], Healing[observer], PlayerKills[observer], PlayerMVPs[observer]);
						}
						else
						{
							FF2_ShowSyncHudText(client, statHUD, "%s%t", top, "Player Stats", observer, Damage[observer], PlayerKills[observer], PlayerMVPs[observer]);
						}
					}
					else if(!IsBoss(observer))
					{
						if((Healing[observer]>0 && HealHud==1) || HealHud>1)
						{
							FF2_ShowSyncHudText(client, statHUD, "%s%t", top, "Spectator Damage Dealt", observer, Damage[observer], "Healing", Healing[observer]);
						}
						else
						{
							FF2_ShowSyncHudText(client, statHUD, "%s%t", top, "Spectator Damage Dealt", observer, Damage[observer]);
						}
					}
					else
					{
						FF2_ShowSyncHudText(client, statHUD, "%s", top);
					}
				}
				else
				{
					FF2_ShowSyncHudText(client, statHUD, "%s", top);
				}
			}

			if(!alive)
				continue;

			TFClassType class=TF2_GetPlayerClass(client);
			int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(weapon<=MaxClients || !IsValidEntity(weapon) || !GetEntityClassname(weapon, classname, sizeof(classname)))
				strcopy(classname, sizeof(classname), "");

			bool validwep=!StrContains(classname, "tf_weapon", false);

			int index=(validwep ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if(class==TFClass_Medic)
			{
				int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
				if(IsValidEntity(medigun))
				{
					int charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
					char mediclassname[64];
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						if(GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
						{
							SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
							FF2_ShowSyncHudText(client, jumpHUD, "%t", "uber-charge", charge);

							if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
							{
								FakeClientCommandEx(client, "voicemenu 1 7");
								FF2flags[client]|=FF2FLAG_UBERREADY;
							}
						}
					}
					else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
					{
						if(GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
						{
							if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
								FF2flags[client]|=FF2FLAG_UBERREADY;
						}
					}
				}
			}
			else if((TF2_GetPlayerClass(client)==TFClass_Sniper || TF2_GetPlayerClass(client)==TFClass_DemoMan) && (GetConVarInt(cvarShieldType)==3 || GetConVarInt(cvarShieldType)==4))
			{
				if(shield[client] && shieldHP[client]>0.0 && GetConVarInt(cvarShieldType)>2)
				{
					SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0);
					FF2_ShowHudText(client, -1, "%t", "Shield HP", RoundToFloor(shieldHP[client]/GetConVarFloat(cvarShieldHealth)*100.0));
				}
			}
			else if(SapperEnabled && SapperCooldown[client]>0.0 && TF2_GetPlayerClass(client)==TFClass_Spy)
			{
				SapperAmount = RoundToFloor((SapperCooldown[client]-GetConVarFloat(cvarSapperCooldown))*(Pow(GetConVarFloat(cvarSapperCooldown), -1.0)*-100.0));
				if(SapperAmount < 0)
					SapperAmount = 0;

				SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0);
				FF2_ShowHudText(client, -1, "%t", "Sapper Cooldown", SapperAmount);
			}
			// Chdata's Deadringer Notifier
			else if(GetConVarBool(cvarDeadRingerHud) && TF2_GetPlayerClass(client)==TFClass_Spy)
			{
				if(GetClientCloakIndex(client)==59)
				{
					int drstatus=TF2_IsPlayerInCondition(client, TFCond_Cloaked) ? 2 : GetEntProp(client, Prop_Send, "m_bFeignDeathReady") ? 1 : 0;

					char s[64];

					switch (drstatus)
					{
						case 1:
						{
							SetHudTextParams(-1.0, 0.83, 0.35, 90, 255, 90, 255, 0, 0.0, 0.0, 0.0);
							Format(s, sizeof(s), "%t", "Dead Ringer Ready");
						}
						case 2:
						{
							SetHudTextParams(-1.0, 0.83, 0.35, 255, 64, 64, 255, 0, 0.0, 0.0, 0.0);
							Format(s, sizeof(s), "%t", "Dead Ringer Active");
						}
						default:
						{
							SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
							Format(s, sizeof(s), "%t", "Dead Ringer Inactive");
						}
					}

					if(!(GetClientButtons(client) & IN_SCORE))
						ShowSyncHudText(client, jumpHUD, "%s", s);
				}
			}
			else if(class==TFClass_Soldier)
			{
				if((FF2flags[client] & FF2FLAG_ISBUFFED) && !(GetEntProp(client, Prop_Send, "m_bRageDraining")))
					FF2flags[client]&=~FF2FLAG_ISBUFFED;
			}

			int aliveTeammates = Enabled3 ? BlueAlivePlayers+RedAlivePlayers-1 : RedAlivePlayers;

			if(lastPlayerGlow > 0)
			{
				if(lastPlayerGlow < 1)
				{
					if(float(aliveTeammates)/playing <= lastPlayerGlow)
						SetClientGlow(client, 0.5, 3.0);
				}
				else if(aliveTeammates <= lastPlayerGlow)
				{
					SetClientGlow(client, 0.5, 3.0);
				}
			}

			aliveTeammates = Enabled3 ? GetClientTeam(client)==OtherTeam ? RedAlivePlayers : BlueAlivePlayers : RedAlivePlayers;

			if(aliveTeammates==1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Stealthed))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.3);
				if(class==TFClass_Engineer && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))  // TODO: Is this necessary?
					SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);

				TF2_AddCondition(client, TFCond_Buffed, 0.3);
				continue;
			}
			else if(aliveTeammates==2 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Stealthed))
			{
				TF2_AddCondition(client, TFCond_Buffed, 0.3);
			}

			if(Enabled3 || bMedieval)
				continue;

			cond=TFCond_HalloweenCritCandy;
			if(TF2_IsPlayerInCondition(client, TFCond_CritCola) && (class==TFClass_Scout || class==TFClass_Sniper))
			{
				TF2_AddCondition(client, cond, 0.3);
				continue;
			}

			int healer=-1;
			for(int healtarget=1; healtarget<=MaxClients; healtarget++)
			{
				if(IsValidClient(healtarget) && IsPlayerAlive(healtarget) && GetHealingTarget(healtarget, true)==client)
				{
					healer=healtarget;
					break;
				}
			}

			bool addthecrit=false;
			if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee) && StrContains(classname, "tf_weapon_knife", false)==-1)  //Every melee except knives
			{
				addthecrit=true;
				if(index==416)  //Market Gardener
				{
					addthecrit=FF2flags[client] & FF2FLAG_ROCKET_JUMPING ? true : false;
				}
				else if(index==44 || index==656)  //Sandman, Holiday Punch
				{
					addthecrit=false;
				}
				else if(index==307)	//Ullapool Caber
				{
					addthecrit=GetEntProp(weapon, Prop_Send, "m_iDetonated") ? false : true;
				}
			}
			else if((!StrContains(classname, "tf_weapon_smg") && index!=751) ||  //Cleaner's Carbine
			         !StrContains(classname, "tf_weapon_compound_bow") ||
			         !StrContains(classname, "tf_weapon_crossbow") ||
			         !StrContains(classname, "tf_weapon_cleaver") ||
			         !StrContains(classname, "tf_weapon_mechanical_arm") ||
			         !StrContains(classname, "tf_weapon_drg_pomson") ||
			         !StrContains(classname, "tf_weapon_raygun") ||
			         !StrContains(classname, "tf_weapon_pistol") ||
			         !StrContains(classname, "tf_weapon_handgun_scout_secondary"))
			{
				addthecrit=true;
				if(class==TFClass_Sniper && cond==TFCond_HalloweenCritCandy && !StrContains(classname, "tf_weapon_smg"))
				{
					cond=TFCond_Buffed;
				}
				else if(class==TFClass_Scout && cond==TFCond_HalloweenCritCandy && (!StrContains(classname, "tf_weapon_pistol") || !StrContains(classname, "tf_weapon_handgun_scout_secondary")))
				{
					cond=TFCond_Buffed;
				}
				else if(class==TFClass_Engineer && cond==TFCond_HalloweenCritCandy && !StrContains(classname, "tf_weapon_pistol"))
				{
					addthecrit=false;
				}
				if(class==TFClass_Sniper && cond==TFCond_HalloweenCritCandy && !StrContains(classname, "tf_weapon_compound_bow") && BowDamageNon>0.0)
				{
					addthecrit=false;
				}
				else if(class==TFClass_Sniper && cond==TFCond_HalloweenCritCandy && !StrContains(classname, "tf_weapon_compound_bow") && BowDamageMini>0.0)
				{
					cond=TFCond_Buffed;
				}
			}

			if(index==16 && IsValidEntity(FindPlayerBack(client, 642)) && SniperClimbDelay!=0)  //SMG, Cozy Camper
				addthecrit=false;

			switch(class)
			{
				case TFClass_Medic:
				{
					int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(IsValidEntity(medigun))
					{
						int charge=RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
						char mediclassname[64];
						if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
						{
							if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
							{
								SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
								FF2_ShowSyncHudText(client, jumpHUD, "%t", "uber-charge", charge);

								if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
								{
									FakeClientCommandEx(client, "voicemenu 1 7");
									FF2flags[client]|=FF2FLAG_UBERREADY;
								}
							}
						}
						else if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
						{
							if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
							{
								if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
									FF2flags[client]|=FF2FLAG_UBERREADY;
							}
						}
					}
				}
				case TFClass_DemoMan:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && !IsValidEntity(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)) && shieldCrits)  //Demoshields
					{
						addthecrit = true;
						if(shieldCrits == 1)
							cond = TFCond_CritCola;
					}
				}
				case TFClass_Spy:
				{
					if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						if(!TF2_IsPlayerCritBuffed(client) && !TF2_IsPlayerInCondition(client, TFCond_Buffed) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Stealthed))
						{
							TF2_AddCondition(client, TFCond_CritCola, 0.3);
						}
						else if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && index==460)
						{
							TF2_AddCondition(client, TFCond_CritOnDamage, 0.3);
						}
					}
				}
				case TFClass_Engineer:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))
					{
						int sentry = FindSentry(client);
						if(IsValidEntity(sentry) && IsBoss(GetEntPropEnt(sentry, Prop_Send, "m_hEnemy")))
						{
							SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
						}
						else if(GetEntProp(client, Prop_Send, "m_iRevengeCrits"))
						{
							SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
						}
					}
				}
			}

			if(addthecrit)
			{
				TF2_AddCondition(client, cond, 0.3);
				if(healer!=-1 && cond!=TFCond_Buffed && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Stealthed))
					TF2_AddCondition(client, TFCond_Buffed, 0.3);
			}
		}
	}
	return Plugin_Continue;
}

#if defined _tf2attributes_included
int g_teamOverrides[4] = {0, 0, 3, 0}; // This is the m_nModelIndexOverrides index for each team.

void ModelOverrides_Clear(int client)
{
	for(int i=0; i<4; i++)
	{
		SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", 0, _, i);
	}
}

void VisionFlags_Update(int client)
{
	if(!tf2attributes)
		return;

	// RED will see index 4 (rome vision)
	// BLU will see index 0 (normal, everyone sees this, but RED won't see their index unless index 0 is non-zero)
	TF2Attrib_RemoveByDefIndex(client, 406);

	if(TF2_GetClientTeam(client) == TFTeam_Red)
		TF2Attrib_SetByDefIndex(client, 406, 4.0);
}

void ModelOverrides_Think(int client, int iDisguisedTarget)
{
	int iTeam = GetClientTeam(client);
	int iEnemyTeam = (iTeam == 2) ? 3 : 2;

	char strPlayerModel[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", strPlayerModel, sizeof(strPlayerModel));
	char strEnemyModel[128];
	GetEntPropString(iDisguisedTarget, Prop_Data, "m_ModelName", strEnemyModel, sizeof(strEnemyModel));

	int iPlayerModel = PrecacheModel(strPlayerModel, true);
	int iEnemyModel = PrecacheModel(strEnemyModel, true);

	// Make the spy look normal to their team
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", iPlayerModel, _, g_teamOverrides[iTeam]);

	// Make the spy look different to the other team, should the disguise class be matching the disguise target's class
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", iEnemyModel, _, g_teamOverrides[iEnemyTeam]);
}
#endif

stock int FindSentry(int client)
{
	int entity = -1;
	while((entity=FindEntityByClassname2(entity, "obj_sentrygun")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
			return entity;
	}
	return -1;
}

public Action BossTimer(Handle timer)
{
	if(!Enabled || CheckRoundState()==2)
		return Plugin_Stop;

	bool validBoss;
	int StatHud = GetConVarInt(cvarStatHud);
	int HealHud = GetConVarInt(cvarHealingHud);
	for(int boss; boss<=MaxClients; boss++)
	{
		int client = Boss[boss];
		if(!IsValidClient(client) || !(FF2flags[client] & FF2FLAG_USEBOSSTIMER))
			continue;

		if(!IsPlayerAlive(client))
		{
			if(IsFakeClient(client))
				continue;

			int observer;
			observer = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if(!IsValidClient(observer) || observer==client)
				observer = 0;

			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255);
			if(StatHud<0 || (!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<1))
			{
				if(observer && !IsBoss(observer))
				{
					if((Healing[observer]>0 && HealHud==1) || HealHud>1)
					{
						FF2_ShowSyncHudText(client, statHUD, "%t %t", "Spectator Damage Dealt", observer, Damage[observer], "Healing", Healing[observer]);
					}
					else
					{
						FF2_ShowSyncHudText(client, statHUD, "%t", "Spectator Damage Dealt", observer, Damage[observer]);
					}
				}
			}
			else if(observer && IsBoss(observer))
			{
				if(!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<2)
				{
					FF2_ShowSyncHudText(client, statHUD, "%t", "Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client]);
				}
				else
				{
					FF2_ShowSyncHudText(client, statHUD, "%t%t", "Self Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client], "Player Stats Boss", observer, BossWins[observer], BossLosses[observer], BossKillsF[observer], BossDeaths[observer]);
				}
			}
			else if(observer)
			{
				if((Healing[observer]>0 && HealHud==1) || HealHud>1)
				{
					if(!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<2)
					{
						FF2_ShowSyncHudText(client, statHUD, "%t\n%t %t", "Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client], "Spectator Damage Dealt", observer, Damage[observer], "Healing", Healing[observer]);
					}
					else
					{
						FF2_ShowSyncHudText(client, statHUD, "%t%t", "Self Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client], "Player Stats Healing", observer, Damage[observer], Healing[observer], PlayerKills[observer], PlayerMVPs[observer]);
					}
				}
				else
				{
					if(!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<2)
					{
						FF2_ShowSyncHudText(client, statHUD, "%t\n%t", "Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client], "Spectator Damage Dealt", observer, Damage[observer]);
					}
					else
					{
						FF2_ShowSyncHudText(client, statHUD, "%t%t", "Self Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client], "Player Stats", observer, Damage[observer], PlayerKills[observer], PlayerMVPs[observer]);
					}
				}
			}
			else if(StatHud>-1 && (CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>0))
			{
				FF2_ShowSyncHudText(client, statHUD, "%t", "Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client]);
			}
			continue;
		}

		if(StatHud>-1 && (CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>0))
		{
			SetHudTextParams(-1.0, 0.99, 0.35, 90, 255, 90, 255);
			FF2_ShowSyncHudText(client, statHUD, "%t", "Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client]);
		}

		validBoss = true;

		if(BossSpeed[Special[boss]] > 0)	// Above 0, uses the classic FF2 method
		{
			SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", BossSpeed[Special[boss]]+0.7*(100-BossHealth[boss]*100/BossLivesMax[boss]/BossHealthMax[boss]));
		}
		else if(BossSpeed[Special[boss]]==0 && GetEntityMoveType(client)!=MOVETYPE_NONE) // Is 0, freeze movement (some uses)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
		// Below 0, TF2's default speeds and whatever attributes or conditions

		if(BossHealth[boss] <= 0 && IsPlayerAlive(client))  // In case the boss hits a hazard and goes into neagtive numbers
			BossHealth[boss] = 1;

		if(BossLivesMax[boss] > 1)
		{
			SetHudTextParams(-1.0, 0.77, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, livesHUD, "%t", "Boss Lives Left", BossLives[boss], BossLivesMax[boss]);
		}

		if(BossRageDamage[boss] < 2)	// When RAGE is infinite
		{
			BossCharge[boss][0] = 100.0;
		}

		if(BossRageDamage[boss] > 99998)	// When RAGE is disabled
		{
			BossCharge[boss][0] = 0.0;	// We don't want things like Sydney Sleeper acting up
		}
		else if(RoundFloat(BossCharge[boss][0]) == 100.0)
		{
			if(IsFakeClient(client) && !(FF2flags[client] & FF2FLAG_BOTRAGE) && GetConVarBool(cvarBotRage))
			{
				CreateTimer(1.0, Timer_BotRage, boss, TIMER_FLAG_NO_MAPCHANGE);
				FF2flags[client]|=FF2FLAG_BOTRAGE;
			}
			else
			{
				SetHudTextParams(-1.0, 0.83, 0.15, 255, 64, 64, 255);
				FF2_ShowSyncHudText(client, rageHUD, "%t", "do_rage");

				char sound[PLATFORM_MAX_PATH];
				if(RandomSound("sound_full_rage", sound, sizeof(sound), boss) && emitRageSound[boss])
				{
					float position[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

					FF2flags[client]|=FF2FLAG_TALKING;
					EmitSoundToAllExcept(sound);

					for(int target=1; target<=MaxClients; target++)
					{
						if(IsClientInGame(target) && target!=client && ToggleVoice[target])
						{
							EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
						}
					}
					FF2flags[client]&=~FF2FLAG_TALKING;
					emitRageSound[boss]=false;
				}
			}
		}
		else	// RAGE is not infinite, disabled, full
		{
			SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, rageHUD, "%t", "rage_meter", RoundFloat(BossCharge[boss][0]));
		}

		SetClientGlow(client, -0.2);

		char lives[MAXRANDOMS][3];
		for(int i=1; ; i++)
		{
			char ability[10];
			Format(ability, sizeof(ability), "ability%i", i);
			KvRewind(BossKV[Special[boss]]);
			if(KvJumpToKey(BossKV[Special[boss]], ability))
			{
				char plugin_name[64];
				KvGetString(BossKV[Special[boss]], "plugin_name", plugin_name, sizeof(plugin_name));
				int slot = KvGetNum(BossKV[Special[boss]], "arg0", 0);
				int buttonmode = KvGetNum(BossKV[Special[boss]], "buttonmode", 0);
				if(slot < 1)
					continue;

				KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability), "");
				if(!ability[0])
				{
					char ability_name[64];
					KvGetString(BossKV[Special[boss]], "name", ability_name, sizeof(ability_name));
					UseAbility(ability_name, plugin_name, boss, slot, buttonmode);
				}
				else
				{
					int count = ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
					for(int n; n<count; n++)
					{
						if(StringToInt(lives[n]) == BossLives[boss])
						{
							char ability_name[64];
							KvGetString(BossKV[Special[boss]], "name", ability_name, sizeof(ability_name));
							UseAbility(ability_name, plugin_name, boss, slot, buttonmode);
							break;
						}
					}
				}
			}
			else
			{
				break;
			}
		}

		int aliveTeammates = Enabled3 ? BlueAlivePlayers+RedAlivePlayers-1 : RedAlivePlayers;

		if(lastPlayerGlow > 0)
		{
			if(lastPlayerGlow < 1)
			{
				if(aliveTeammates/playing <= lastPlayerGlow)
					SetClientGlow(client, 0.3, 3.0);
			}
			else if(aliveTeammates <= lastPlayerGlow)
			{
				SetClientGlow(client, 0.3, 3.0);
			}
		}

		if(aliveTeammates<2 && GetConVarInt(cvarHealthHud)<2 && (bosses>1 || Enabled3 || !GetConVarInt(cvarGameText) || !executed2))
		{
			char message[MAXPLAYERS+1][512], name[64];
			for(int target; target<=MaxClients; target++)
			{
				if(IsBoss(target))
				{
					int boss2 = GetBossIndex(target);
					strcopy(name, sizeof(name), "=Failed name=");
					char bossLives[10];
					if(BossLives[boss2] > 1)
					{
						Format(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);
					}
					else
					{
						Format(bossLives, sizeof(bossLives), "");
					}
					for(int clients; clients<=MaxClients; clients++)
					{
						if(IsValidClient(clients))
						{
							GetBossSpecial(Special[boss2], name, sizeof(name), client);
							Format(message[clients], sizeof(message[]), "%s\n%t", message[client], "ff2_hp", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives);
						}
					}
				}
			}

			for(int target; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					if(bosses<2 && GetConVarInt(cvarGameText)>0)
					{
						if(strlen(BossIcon))
						{
							ShowGameText(target, BossIcon, _, message[target]);
						}
						else
						{
							ShowGameText(target, "leaderboard_streak", _, message[target]);
						}
					}
					else
					{
						PrintCenterText(target, message[target]);
					}
				}
			}
		}

		if(BossCharge[boss][0] < rageMax[client])
		{
			BossCharge[boss][0] += OnlyScoutsLeft(GetClientTeam(client))*0.2;
			if(BossCharge[boss][0] > rageMax[client])
				BossCharge[boss][0] = rageMax[client];
		}

		HPTime -= 0.2;
		if(HPTime < 0)
			HPTime = 0.0;

		for(int client2; client2<=MaxClients; client2++)
		{
			if(KSpreeTimer[client2] > 0)
				KSpreeTimer[client2] -= 0.2;
		}
	}

	if(!validBoss)
		return Plugin_Stop;

	return Plugin_Continue;
}

public Action GlobalTimer(Handle timer)
{
	int HealthHud = GetConVarInt(cvarHealthHud);

	if(!Enabled || CheckRoundState()==2 || CheckRoundState()==-1 || HealthHud<1)
		return Plugin_Stop;

	if(!ShowHealthText)
		return Plugin_Continue;

	char healthString[64];
	int current, lives, boss;
	if(Enabled3)
	{
		if(HealthHud > 1)
		{
			for(int clients=1; clients<=MaxClients; clients++)
			{
				if(IsBoss(clients))
				{
					if(TF2_GetClientTeam(clients) != TFTeam_Blue)
						continue;

					boss = GetBossIndex(clients);
					current += BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
					lives += BossLives[boss];
				}
			}

			if(lives > bosses)
			{
				Format(healthString, sizeof(healthString), "%ix%i", current, lives);
			}
			else
			{
				Format(healthString, sizeof(healthString), "%i", current);
			}
		}
		else
		{
			for(int clients=1; clients<=MaxClients; clients++)
			{
				if(IsBoss(clients))
				{
					if(TF2_GetClientTeam(clients) != TFTeam_Blue)
						continue;

					boss = GetBossIndex(clients);
					current += BossLives[boss];
				}
			}

			if(current > bosses)
			{
				Format(healthString, sizeof(healthString), "x%i", current);
			}
		}

		current = 0;
		lives = 0;
		char healthString2[64];
		if(HealthHud > 1)
		{
			for(int clients=1; clients<=MaxClients; clients++)
			{
				if(IsBoss(clients))
				{
					if(TF2_GetClientTeam(clients) != TFTeam_Red)
						continue;

					boss = GetBossIndex(clients);
					current += BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
					lives += BossLives[boss];
				}
			}

			if(lives > bosses)
			{
				Format(healthString2, sizeof(healthString2), "%ix%i", current, lives);
			}
			else
			{
				Format(healthString2, sizeof(healthString2), "%i", current);
			}
		}
		else
		{
			for(int clients=1; clients<=MaxClients; clients++)
			{
				if(IsBoss(clients))
				{
					if(TF2_GetClientTeam(clients) != TFTeam_Red)
						continue;

					boss = GetBossIndex(clients);
					current += BossLives[boss];
				}
			}

			if(current > bosses)
			{
				Format(healthString2, sizeof(healthString2), "x%i", current);
			}
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				if(GetClientButtons(client) & IN_SCORE)
					continue;

				if(!IsClientObserver(client))
				{
					if(HealthBarMode)
					{
						SetHudTextParams(0.43, 0.12, 0.35, 100, 255, 100, 255, 0, 0.35, 0.0, 0.1);
					}
					else
					{
						SetHudTextParams(0.43, 0.12, 0.35, 100, 100, 255, 255, 0, 0.35, 0.0, 0.1);
					}
				}
				else
				{
					if(HealthBarMode)
					{
						SetHudTextParams(0.43, 0.22, 0.35, 100, 255, 100, 255, 0, 0.35, 0.0, 0.1);
					}
					else
					{
						SetHudTextParams(0.43, 0.22, 0.35, 100, 100, 255, 255, 0, 0.35, 0.0, 0.1);
					}
				}

				SetGlobalTransTarget(client);
				ShowSyncHudText(client, healthHUD, healthString);

				if(!IsClientObserver(client))
				{
					if(HealthBarMode)
					{
						SetHudTextParams(0.53, 0.12, 0.35, 100, 255, 100, 255, 0, 0.35, 0.0, 0.1);
					}
					else
					{
						SetHudTextParams(0.53, 0.12, 0.35, 255, 100, 100, 255, 0, 0.35, 0.0, 0.1);
					}
				}
				else
				{
					if(HealthBarMode)
					{
						SetHudTextParams(0.53, 0.22, 0.35, 100, 255, 100, 255, 0, 0.35, 0.0, 0.1);
					}
					else
					{
						SetHudTextParams(0.53, 0.22, 0.35, 255, 100, 100, 255, 0, 0.35, 0.0, 0.1);
					}
				}

				ShowSyncHudText(client, rivalHUD, healthString2);
			}
		}
	}
	else
	{
		int max;
		if(HealthHud > 1)
		{
			for(int clients=1; clients<=MaxClients; clients++)
			{
				if(IsBoss(clients))
				{
					boss = GetBossIndex(clients);
					current += BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
					max += BossHealthMax[boss];
					lives += BossLives[boss];
				}
			}

			if(lives > bosses)
			{
				Format(healthString, sizeof(healthString), "%i / %ix%i", current, max, lives);
			}
			else
			{
				Format(healthString, sizeof(healthString), "%i / %i", current, max);
			}
		}
		else
		{
			for(int clients=1; clients<=MaxClients; clients++)
			{
				if(IsBoss(clients))
				{
					boss = GetBossIndex(clients);
					current += BossLives[boss];
					max += BossLivesMax[boss];
				}
			}

			if(current > bosses)
			{
				Format(healthString, sizeof(healthString), "%t", "Boss Lives Left", current, max);
			}
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				if(GetClientButtons(client) & IN_SCORE)
					continue;

				if(!IsClientObserver(client))
				{
					if(HealthBarMode)
					{
						SetHudTextParams(-1.0, 0.12, 0.35, 100, 255, 100, 255, 0, 0.35, 0.0, 0.1);
					}
					else
					{
						SetHudTextParams(-1.0, 0.12, 0.35, 200, 255, 200, 255, 0, 0.35, 0.0, 0.1);
					}
				}
				else
				{
					if(HealthBarMode)
					{
						SetHudTextParams(-1.0, 0.22, 0.35, 100, 255, 100, 255, 0, 0.35, 0.0, 0.1);
					}
					else
					{
						SetHudTextParams(-1.0, 0.22, 0.35, 200, 255, 200, 255, 0, 0.35, 0.0, 0.1);
					}
				}

				SetGlobalTransTarget(client);
				ShowSyncHudText(client, healthHUD, healthString);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_RPS(Handle timer, int client)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	int boss=GetBossIndex(client);
	if(boss==-1 || !IsPlayerAlive(client))
		return Plugin_Continue;

	RPSLosses[client]++;

	if(RPSLosses[client] < 0)
		RPSLosses[client] = 0;

	if(RPSHealth[client] == -1)
		RPSHealth[client]=BossHealth[boss];

	if(RPSLosses[client] >= GetConVarInt(cvarRPSLimit))
	{
		if(IsValidClient(RPSWinner) && FF2_GetBossHealth(boss)>1349)
		{
			SDKHooks_TakeDamage(client, RPSWinner, RPSWinner, float(BossHealth[boss]), DMG_GENERIC, -1);
		}
		else // Winner disconnects?
		{
			ForcePlayerSuicide(client);
		}
	}
	else if(FF2_GetBossHealth(boss) > (1349*GetConVarInt(cvarRPSLimit)) && GetConVarBool(cvarRPSDivide))
	{
		if(IsValidClient(RPSWinner))
			SDKHooks_TakeDamage(client, RPSWinner, RPSWinner, float((RPSHealth[client]/GetConVarInt(cvarRPSLimit))-999)/1.35, DMG_GENERIC, -1);
	}
	return Plugin_Continue;
}

public Action Timer_BotRage(Handle timer, any bot)
{
	if(IsValidClient(Boss[bot], false) && GetConVarBool(cvarBotRage))
		FakeClientCommandEx(Boss[bot], "voicemenu 0 0");
}

stock int OnlyScoutsLeft(int team)
{
	int scouts;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client) && !IsBoss(client) && GetClientTeam(client)!=team)
		{
			if(TF2_GetPlayerClass(client) != TFClass_Scout)
			{
				return 0;
			}
			else
			{
				scouts++;
			}
		}
	}
	return scouts;
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon=GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(Enabled)
	{
		if(IsBoss(client) && (condition==TFCond_Jarated || condition==TFCond_MarkedForDeath || (condition==TFCond_Dazed && TF2_IsPlayerInCondition(client, view_as<TFCond>(42)))))
		{
			TF2_RemoveCondition(client, condition);
		}
		else if(IsBoss(client) && SelfHealing[client]>0 && (condition==TFCond_Healing || condition==TFCond_RadiusHealOnDamage || condition==TFCond_HalloweenQuickHeal)) //|| condition==TFCond_KingAura))
		{
			HealthBarModeC[client] = true;
		}
		else if(!IsBoss(client) && condition==TFCond_BlastJumping)
		{
			FF2flags[client]|=FF2FLAG_ROCKET_JUMPING;
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(Enabled)
	{
		if(TF2_GetPlayerClass(client)==TFClass_Scout && condition==TFCond_CritHype)
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
		}
		else if(IsBoss(client) && (condition==TFCond_Healing || condition== TFCond_RadiusHealOnDamage || condition==TFCond_HalloweenQuickHeal)) //|| condition==TFCond_KingAura))
		{
			HealthBarModeC[client] = false;
		}
		else if(!IsBoss(client) && condition==TFCond_BlastJumping)
		{
			FF2flags[client]&=~FF2FLAG_ROCKET_JUMPING;
		}
	}
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
	if(!IsPlayerAlive(client) || CheckRoundState()!=1 || !IsBoss(client) || args!=2)
		return Plugin_Continue;

	int boss = GetBossIndex(client);
	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]) || BossRageDamage[0]>99998 || rageMode[client]==2)
		return Plugin_Continue;

	char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
		return Plugin_Continue;

	if(RoundFloat(BossCharge[boss][0])>=rageMin[client])
	{
		char ability[10], lives[MAXRANDOMS][3];
		for(int i=1; i<MAXRANDOMS; i++)
		{
			Format(ability, sizeof(ability), "ability%i", i);
			KvRewind(BossKV[Special[boss]]);
			if(KvJumpToKey(BossKV[Special[boss]], ability))
			{
				if(KvGetNum(BossKV[Special[boss]], "arg0", 0))
					continue;

				KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability));
				if(!ability[0])
				{
					char abilityName[64], pluginName[64];
					KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
					KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
					if(!UseAbility(abilityName, pluginName, boss, 0))
						return Plugin_Continue;
				}
				else
				{
					int count=ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
					for(int j; j<count; j++)
					{
						if(StringToInt(lives[j])==BossLives[boss])
						{
							char abilityName[64], pluginName[64];
							KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
							KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
							if(!UseAbility(abilityName, pluginName, boss, 0))
								return Plugin_Continue;

							break;
						}
					}
				}
			}
		}

		float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

		char sound[PLATFORM_MAX_PATH];
		if(RandomSound("sound_ability_serverwide", sound, sizeof(sound), boss))
			EmitSoundToAllExcept(sound);

		if(RandomSoundAbility("sound_ability", sound, sizeof(sound), boss))
		{
			FF2flags[Boss[boss]]|=FF2FLAG_TALKING;
			EmitSoundToAllExcept(sound);

			for(int target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && target!=Boss[boss] && ToggleVoice[target])
				{
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
				}
			}
			FF2flags[Boss[boss]]&=~FF2FLAG_TALKING;
		}
		emitRageSound[boss]=true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnSuicide(int client, const char[] command, int args)
{
	bool canBossSuicide = GetConVarBool(cvarBossSuicide);
	if(IsBoss(client) && (canBossSuicide ? !CheckRoundState() : true) && CheckRoundState()!=2)
	{
		FPrintToChat(client, "%t", canBossSuicide ? "Boss Suicide Pre-round" : "Boss Suicide Denied");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnChangeClass(int client, const char[] command, int args)
{
	if(!IsBoss(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	//Don't allow the boss to switch classes but instead set their *desired* class (for the next round)
	char class[16];
	GetCmdArg(1, class, sizeof(class));
	if(TF2_GetClass(class) != TFClass_Unknown)  //Ignore cases where the client chooses an invalid class through the console
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetClass(class));

	return Plugin_Handled;
}

public Action OnJoinTeam(int client, const char[] command, int args)
{
	// Only block the commands when FF2 is actively running
	if(!Enabled || RoundCount<arenaRounds || CheckRoundState()==-1)
		return Plugin_Continue;

	int boss = GetBossIndex(client);
	// autoteam doesn't come with arguments
	if(StrEqual(command, "autoteam", false))
	{
		if(Enabled3)
		{
			if(IsPlayerAlive(client))
				return Plugin_Handled;

			return Plugin_Continue;
		}

		int team=view_as<int>(TFTeam_Unassigned), oldTeam=GetClientTeam(client);
		if(IsBoss(client) && !BossSwitched[boss])
		{
			team = BossTeam;
		}
		else
		{
			team = OtherTeam;
		}

		if(team != oldTeam)
			ChangeClientTeam(client, team);

		return Plugin_Handled;
	}

	if(!args || (Enabled3 && !IsBoss(client)))
		return Plugin_Continue;

	int team=view_as<int>(TFTeam_Unassigned), oldTeam=GetClientTeam(client);
	char teamString[10];
	GetCmdArg(1, teamString, sizeof(teamString));

	if(StrEqual(teamString, "red", false))
	{
		team=view_as<int>(TFTeam_Red);
	}
	else if(StrEqual(teamString, "blue", false))
	{
		team=view_as<int>(TFTeam_Blue);
	}
	else if(StrEqual(teamString, "auto", false))
	{
		team=OtherTeam;
	}
	else if(StrEqual(teamString, "spectate", false) && !IsBoss(client) && GetConVarBool(FindConVar("mp_allowspectators")))
	{
		team=view_as<int>(TFTeam_Spectator);
	}

	if(team==BossTeam && (!IsBoss(client) || BossSwitched[boss]))
	{
		team=OtherTeam;
	}
	else if(team==OtherTeam && (IsBoss(client) && !BossSwitched[boss]))
	{
		team=BossTeam;
	}

	if(team>view_as<int>(TFTeam_Unassigned) && team!=oldTeam)
		ChangeClientTeam(client, team);

	if(CheckRoundState()!=1 && !IsBoss(client) || !IsPlayerAlive(client))  //No point in showing the VGUI if they can't change teams
	{
		switch(team)
		{
			case TFTeam_Red:
				ShowVGUIPanel(client, "class_red");

			case TFTeam_Blue:
				ShowVGUIPanel(client, "class_blue");
		}
	}
	return Plugin_Handled;
}

public Action OnRPS(Handle event, const char[] eventName, bool dontBroadcast)
{
	int winner = GetEventInt(event, "winner");
	int loser = GetEventInt(event, "loser");

	if(!IsValidClient(winner) || !IsValidClient(loser))	// Check for valid clients
		return;

	if(!IsBoss(winner) && IsBoss(loser) && GetBossIndex(loser)>=0 && GetConVarInt(cvarRPSLimit)>0)	// Boss Loses on RPS?
	{
		RPSWinner=winner;
		TF2_AddCondition(RPSWinner, TFCond_NoHealingDamageBuff, 3.4);	// I'm not bothered checking for mini-crit boost or not during damage
		CreateTimer(3.1, Timer_RPS, loser, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(ToggleBoss[winner]!=Setting_Off && ToggleBoss[loser]!=Setting_Off && !IsBoss(winner) && !IsBoss(loser) && QueuePoints[winner]>=GetConVarInt(cvarRPSPoints) && QueuePoints[loser]>=GetConVarInt(cvarRPSPoints) && GetConVarInt(cvarRPSPoints)>0)	// Teammate or Minion loses?
	{
		FPrintToChat(winner, "%t", "rps_won", GetConVarInt(cvarRPSPoints), loser);
		QueuePoints[winner] += GetConVarInt(cvarRPSPoints);

		FPrintToChat(loser, "%t", "rps_lost", GetConVarInt(cvarRPSPoints), winner);
		QueuePoints[loser] -= GetConVarInt(cvarRPSPoints);
	}
}

public Action OnStartCapture(Handle event, const char[] eventName, bool dontBroadcast)
{
	isCapping=true;
	return Plugin_Continue;
}

public Action OnBreakCapture(Handle event, const char[] eventName, bool dontBroadcast)
{
	if(!GetEventFloat(event, "time_remaining"))
		isCapping=false;

	return Plugin_Continue;
}

public void EndBossRound()
{
	if(!GetConVarBool(cvarCountdownResult))
	{
		for(int client=1; client<=MaxClients; client++)  //Thx MasterOfTheXP
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
				ForcePlayerSuicide(client);
		}
	}
	else
	{
		ForceTeamWin(0);  //Stalemate
	}
}

public Action OverTimeAlert(Handle timer)
{
	static int OTCount=0;
	if(CheckRoundState()!=1)
	{
		OTCount=0;
		return Plugin_Stop;
	}

	if(!isCapping)
	{
		EndBossRound();
		OTCount=0;
		return Plugin_Stop;
	}

	if(OTCount>0)
	{
		char OTAlerting[PLATFORM_MAX_PATH];
		strcopy(OTAlerting, sizeof(OTAlerting), OTVoice[GetRandomInt(0, sizeof(OTVoice)-1)]);
		EmitSoundToAll(OTAlerting);
		if(GetConVarInt(FindConVar("tf_overtime_nag")))
			OTCount=GetRandomInt(-3, 0);

		return Plugin_Continue;
	}

	OTCount++;
	return Plugin_Continue;
}

public Action OnPlayerDeath(Handle event, const char[] eventName, bool dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=1)
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	char sound[PLATFORM_MAX_PATH];
	CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	DoOverlay(client, "");

	if(!IsBoss(client))
	{
		if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
			CreateTimer(1.0, Timer_Damage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);

		if(IsBoss(attacker))
		{
			int boss = GetBossIndex(attacker);
			bool firstBloodSound = true;
			if(firstBlood)	//TF_DEATHFLAG_FIRSTBLOOD is broken
			{
				if(RandomSound("sound_first_blood", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(sound);
					firstBloodSound=false;
				}
				firstBlood=false;
			}

			int aliveTeammates = GetClientTeam(attacker)==BossTeam ? BlueAlivePlayers : RedAlivePlayers;
			if(aliveTeammates>2 && KSpreeCount[boss]<2 && firstBloodSound)  //Don't conflict with end-of-round sounds, killing spree, or first blood
			{
				int ClassKill = GetRandomInt(0, 1);
				char classnames[][] = {"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
				char class[32];
				Format(class, sizeof(class), "sound_kill_%s", classnames[TF2_GetPlayerClass(client)]);
				if(RandomSound(class, sound, sizeof(sound), boss) && ClassKill)
				{
					EmitSoundToAllExcept(sound);
				}
				else if(RandomSound("sound_hit", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(sound);
				}
			}

			if(GetGameTime() <= KSpreeTimer[boss])
			{
				KSpreeCount[boss]++;
			}
			else
			{
				KSpreeCount[boss] = 1;
			}

			if(aliveTeammates>2 && KSpreeCount[boss]==3)
			{
				if(RandomSound("sound_kspree", sound, sizeof(sound), boss))
					EmitSoundToAllExcept(sound);

				KSpreeCount[boss] = 0;
			}
			else
			{
				KSpreeTimer[boss]=GetGameTime()+5.0;
			}

			if(IsValidClient(attacker))
			{
				if(!IsFakeClient(client) || IsFakeClient(attacker))
				{
					BossKillsF[attacker]++;
					if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
						AddClientStats(attacker, Cookie_BossKills, 1);
				}
			}
		}
	}
	else if(client && attacker)
	{
		int boss = GetBossIndex(client);
		if(boss==-1 || (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
			return Plugin_Continue;

		if(RandomSound("sound_death", sound, sizeof(sound), boss))
			EmitSoundToAllExcept(sound);

		if(!IsFakeClient(client) || IsFakeClient(attacker))
			AddClientStats(attacker, Cookie_PlayerKills, 1);

		if(IsFakeClient(client) || !IsFakeClient(attacker))
			AddClientStats(client, Cookie_BossDeaths, 1);

		BossHealth[boss] = 0;
		UpdateHealthBar();
		Stabbed[boss] = 0.0;
		Marketed[boss] = 0.0;
		Cabered[boss] = 0.0;
	}

	if(TF2_GetPlayerClass(client)==TFClass_Engineer && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		char name[PLATFORM_MAX_PATH];
		FakeClientCommand(client, "destroy 2");
		for(int entity=MaxClients+1; entity<MAXENTITIES; entity++)
		{
			if(IsValidEntity(entity))
			{
				GetEntityClassname(entity, name, sizeof(name));
				if(!StrContains(name, "obj_sentrygun") && (GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client))
				{
					SetVariantInt(GetEntPropEnt(entity, Prop_Send, "m_iMaxHealth")+1);
					AcceptEntityInput(entity, "RemoveHealth");

					Handle eventRemoveObject=CreateEvent("object_removed", true);
					SetEventInt(eventRemoveObject, "userid", GetClientUserId(client));
					SetEventInt(eventRemoveObject, "index", entity);
					FireEvent(eventRemoveObject);
					AcceptEntityInput(entity, "kill");
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Damage(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient(client, false))
		FPrintToChat(client, "{olive}%t. %t{default}", "damage", Damage[client], "scores", RoundToFloor(Damage[client]/PointsInterval2));

	return Plugin_Continue;
}

public Action OnObjectDeflected(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || GetEventInt(event, "weaponid"))  //0 means that the client was airblasted, which is what we want
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "ownerid"));
	int boss = GetBossIndex(client);
	if(boss!=-1 && BossCharge[boss][0]<rageMax[client])
	{
		BossCharge[boss][0]+=rageMax[client]*7.0/rageMin[client];  //TODO: Allow this to be customizable
		if(BossCharge[boss][0]>rageMax[client])
			BossCharge[boss][0]=rageMax[client];
	}
	return Plugin_Continue;
}

public Action OnJarate(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int client = BfReadByte(bf);
	int victim = BfReadByte(bf);
	int boss = GetBossIndex(victim);
	if(boss != -1)
	{
		int jarate = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(jarate != -1)
		{
			int index=GetEntProp(jarate, Prop_Send, "m_iItemDefinitionIndex");
			if((index==58 || index==1083 || index==1105) && GetEntProp(jarate, Prop_Send, "m_iEntityLevel")!=-122)  //-122 is the Jar of Ants which isn't really Jarate
			{
				BossCharge[boss][0] -= rageMax[victim]*8.0/rageMin[victim];  //TODO: Allow this to be customizable
				if(BossCharge[boss][0] < 0.0)
				{
					BossCharge[boss][0] = 0.0;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action OnDeployBackup(Handle event, const char[] name, bool dontBroadcast)
{
	if(Enabled && GetEventInt(event, "buff_type")==2)
		FF2flags[GetClientOfUserId(GetEventInt(event, "buff_owner"))]|=FF2FLAG_ISBUFFED;

	return Plugin_Continue;
}

public Action Timer_CheckAlivePlayers(Handle timer)
{
	if(CheckRoundState() == 2)
		return Plugin_Continue;

	RedAlivePlayers = 0;
	BlueAlivePlayers = 0;
	RedAliveBosses = 0;
	BlueAliveBosses = 0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(GetClientTeam(client) == OtherTeam)
			{
				RedAlivePlayers++;
				if(IsBoss(client))
					RedAliveBosses++;
			}
			else if(GetClientTeam(client) == BossTeam)
			{
				BlueAlivePlayers++;
				if(IsBoss(client))
					BlueAliveBosses++;
			}
		}
	}

	Call_StartForward(OnAlivePlayersChanged);  //Let subplugins know that the number of alive players just changed
	Call_PushCell(RedAlivePlayers);
	Call_PushCell(BlueAlivePlayers);
	Call_Finish();

	if(!RedAlivePlayers && !BlueAlivePlayers)
	{
		ForceTeamWin(0);
		return Plugin_Continue;
	}
	if(!RedAlivePlayers)
	{
		ForceTeamWin(BossTeam);
		return Plugin_Continue;
	}
	if(!BlueAlivePlayers)
	{
		ForceTeamWin(OtherTeam);
		return Plugin_Continue;
	}

	if(Enabled3 && GetConVarInt(cvarBvBLose))
	{
		switch(GetConVarInt(cvarBvBLose))
		{
			case 1:
			{
				if(!RedAliveBosses && !BlueAliveBosses)
				{
					ForceTeamWin(0);
					return Plugin_Continue;
				}
				if(!RedAliveBosses)
				{
					ForceTeamWin(BossTeam);
					return Plugin_Continue;
				}
				if(!BlueAliveBosses)
				{
					ForceTeamWin(OtherTeam);
					return Plugin_Continue;
				}
			}
			case 2:
			{
				if(!(RedAlivePlayers - RedAliveBosses) && !(BlueAlivePlayers - BlueAliveBosses))
				{
					ForceTeamWin(BossTeam);
					return Plugin_Continue;
				}
				if(!(RedAlivePlayers - RedAliveBosses))
				{
					ForceTeamWin(BossTeam);
					return Plugin_Continue;
				}
				if(!(BlueAlivePlayers - BlueAliveBosses))
				{
					ForceTeamWin(OtherTeam);
					return Plugin_Continue;
				}
			}
		}
	}

	if(RedAlivePlayers==1 && BlueAlivePlayers && Boss[0] && !DrawGameTimer && LastMan && !Enabled3)
	{
		char sound[PLATFORM_MAX_PATH];
		if(RandomSound("sound_lastman", sound, sizeof(sound)))
			EmitSoundToAllExcept(sound);

		LastMan=false;
	}

	float alivePlayers = Enabled3 ? float(RedAlivePlayers + BlueAlivePlayers - 2) : float(RedAlivePlayers);
	if(countdownPlayers>0 && BossHealth[0]>=countdownHealth && (BossHealth[MAXBOSSES]>=countdownHealth || !Enabled3) && countdownTime>1 && !executed2)
	{
		if(countdownPlayers < 1)
		{
			if(alivePlayers/playing <= countdownPlayers)
			{
				if(FindEntityByClassname2(-1, "team_control_point") != -1)
				{
					timeleft = countdownTime;
					DrawGameTimer = CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				executed2 = true;
			}
		}
		else
		{
			if(alivePlayers <= countdownPlayers)
			{
				if(FindEntityByClassname2(-1, "team_control_point") != -1)
				{
					timeleft = countdownTime;
					DrawGameTimer = CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				executed2 = true;
			}
		}
	}

	if(PointType!=1 && AliveToEnable>0 && !executed)
	{
		if(AliveToEnable < 1)
		{
			if(alivePlayers/playing > AliveToEnable)
				return Plugin_Continue;
		}
		else
		{
			if(alivePlayers > AliveToEnable)
				return Plugin_Continue;
		}

		if(alivePlayers < playing)
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsClientInGame(client) && IsPlayerAlive(client))
				{
					if(GetConVarInt(cvarGameText)>0)
					{
						ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "point_enable", RoundFloat(alivePlayers));
					}
					else
					{
						PrintHintText(client, "%t", "point_enable", RoundFloat(alivePlayers));
					}
				}
			}

			char sound[64];
			if(GetRandomInt(0, 2))
			{
				Format(sound, sizeof(sound), "vo/announcer_am_capenabled0%i.mp3", GetRandomInt(1, 4));
			}
			else
			{
				Format(sound, sizeof(sound), "vo/announcer_am_capincite0%i.mp3", GetRandomInt(0, 1) ? 1 : 3);
			}
			EmitSoundToAll(sound);
		}
		SetArenaCapEnableTime(0.0);
		SetControlPoint(true);
		executed = true;
	}
	return Plugin_Continue;
}

public Action Timer_DrawGame(Handle timer)
{
	if((BossHealth[0]<countdownHealth && (BossHealth[MAXBOSSES]<countdownHealth || !Enabled3)) || CheckRoundState()!=1)
	{
		executed2 = false;
		return Plugin_Stop;
	}

	float alivePlayers = Enabled3 ? float(RedAlivePlayers + BlueAlivePlayers - 2) : float(RedAlivePlayers);
	if(countdownPlayers < 1)
	{
		if(alivePlayers/playing > countdownPlayers)
		{
			executed2 = false;
			return Plugin_Stop;
		}
	}
	else if(alivePlayers > countdownPlayers)
	{
		executed2 = false;
		return Plugin_Stop;
	}

	int time = timeleft;
	timeleft--;
	char timeDisplay[6];
	if(time/60 > 9)
	{
		IntToString(time/60, timeDisplay, sizeof(timeDisplay));
	}
	else
	{
		Format(timeDisplay, sizeof(timeDisplay), "0%i", time/60);
	}

	if(time%60 > 9)
	{
		Format(timeDisplay, sizeof(timeDisplay), "%s:%i", timeDisplay, time%60);
	}
	else
	{
		Format(timeDisplay, sizeof(timeDisplay), "%s:0%i", timeDisplay, time%60);
	}

	SetHudTextParams(-1.0, 0.17, 1.1, 255, 255, 255, 255);

	char message[MAXPLAYERS+1][512], name[64];
	if(bosses<2 && GetConVarInt(cvarGameText)>0 && alivePlayers==1 && GetConVarInt(cvarHealthHud)<2)
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsBoss(client))
			{
				int boss2 = GetBossIndex(client);
				strcopy(name, sizeof(name), "=Failed name=");
				char bossLives[10];
				if(BossLives[boss2] > 1)
				{
					Format(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);
				}
				else
				{
					Format(bossLives, sizeof(bossLives), "");
				}

				for(int clients; clients<=MaxClients; clients++)
				{
					if(IsValidClient(client))
					{
						GetBossSpecial(Special[boss2], name, sizeof(name), client);
						Format(message[clients], sizeof(message[]), "%s\n%t", message[clients], "ff2_hp", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives);
					}
				}
			}
		}
	}
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(bosses<2 && GetConVarInt(cvarGameText)>0 && alivePlayers==1 && GetConVarInt(cvarHealthHud)<2)
			{
				if(timeleft<=countdownTime && timeleft>=countdownTime/2)
				{
					ShowGameText(client, "ico_notify_sixty_seconds", _, "%s | %s", message[client], timeDisplay);
				}
				else if(timeleft<countdownTime/2 && timeleft>=countdownTime/6)
				{
					ShowGameText(client, "ico_notify_thirty_seconds", _, "%s | %s", message[client], timeDisplay);
				}
				else if(timeleft<countdownTime/6 && timeleft>0)
				{
					ShowGameText(client, "ico_notify_ten_seconds", _, "%s | %s", message[client], timeDisplay);
				}
				else if(isCapping)
				{
					ShowGameText(client, "ico_notify_flag_moving_alt", _, "%s | %t", message[client], "Overtime");
				}
				else if(strlen(BossIcon))
				{
					ShowGameText(client, BossIcon, _, "%s | %s", message[client], timeDisplay);
				}
				else
				{
					ShowGameText(client, "leaderboard_streak", _, "%s | %s", message[client], timeDisplay);
				}
			}
			else if(bosses<2 && GetConVarInt(cvarGameText)>1)
			{
				if(timeleft<=countdownTime && timeleft>=countdownTime/2)
				{
					ShowGameText(client, "ico_notify_sixty_seconds", _, "%t", "Time Left", timeDisplay);
				}
				else if(timeleft<countdownTime/2 && timeleft>=countdownTime/6)
				{
					ShowGameText(client, "ico_notify_thirty_seconds", _, "%t", "Time Left", timeDisplay);
				}
				else if(timeleft<countdownTime/6 && timeleft>=0)
				{
					ShowGameText(client, "ico_notify_ten_seconds", _, "%t", "Time Left", timeDisplay);
				}
				else if(isCapping)
				{
					ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Overtime");
				}
				else if(strlen(BossIcon))
				{
					ShowGameText(client, BossIcon, _, timeDisplay);
				}
				else
				{
					ShowGameText(client, "leaderboard_streak", _, timeDisplay);
				}
			}
			else if(isCapping && timeleft<=0)
			{
				FF2_ShowSyncHudText(client, timeleftHUD, "%t", "Overtime");
			}
			else
			{
				FF2_ShowSyncHudText(client, timeleftHUD, timeDisplay);
			}
		}
	}

	switch(time)
	{
		case 300:
		{
			EmitSoundToAll("vo/announcer_ends_5min.mp3");
		}
		case 120:
		{
			EmitSoundToAll("vo/announcer_ends_2min.mp3");
		}
		case 60:
		{
			EmitSoundToAll("vo/announcer_ends_60sec.mp3");
		}
		case 30:
		{
			EmitSoundToAll("vo/announcer_ends_30sec.mp3");
		}
		case 10:
		{
			EmitSoundToAll("vo/announcer_ends_10sec.mp3");
		}
		case 1, 2, 3, 4, 5:
		{
			char sound[PLATFORM_MAX_PATH];
			Format(sound, PLATFORM_MAX_PATH, "vo/announcer_ends_%isec.mp3", time);
			EmitSoundToAll(sound);
		}
		case 0:
		{
			if(countdownOvertime && isCapping)
			{
				CreateTimer(1.0, OverTimeAlert, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				EndBossRound();
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=1)
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int damage = GetEventInt(event, "damageamount");

	if(IsValidClient(attacker) && GetClientTeam(attacker)!=GetClientTeam(client) && shield[client] && damage)
	{
		int preHealth = GetClientHealth(client)+damage;
		int health = GetClientHealth(client);
		switch(GetConVarInt(cvarShieldType))
		{
			case 1:
			{
				SetEntityHealth(client, preHealth);
				RemoveShield(client, attacker);
				return Plugin_Handled;
			}
			case 2:
			{
				if(preHealth <= damage)
				{
					SetEntityHealth(client, preHealth);
					RemoveShield(client, attacker);
					return Plugin_Handled;
				}
			}
			case 3:
			{
				if(GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee)!=GetEventInt(event, "weaponid") && shieldHP[client]>=0.0 && damage<preHealth)
				{
					int damageresist = RoundFloat(float(damage)*shDmgReduction[client]);

					shieldHP[client] -= damage;		// take a small portion of shield health away

					SetEntityHealth(client, health+damageresist);

					shDmgReduction[client] = shieldHP[client]/GetConVarFloat(cvarShieldHealth)*(1.0-GetConVarFloat(cvarShieldResist));

					if(shieldHP[client] > 0.0)
					{
						char ric[PLATFORM_MAX_PATH];
						Format(ric, sizeof(ric), "weapons/fx/rics/ric%i.wav", GetRandomInt(1,5));
						EmitSoundToClient(client, ric, _, _, _, _, 0.7, _, _, _, _, false);
						EmitSoundToClient(attacker, ric, _, _, _, _, 0.7, _, _, _, _, false);
						SetEventInt(event, "damageamount", damage-damageresist);
						return Plugin_Changed;
					}
				}

				SetEntityHealth(client, preHealth);
				RemoveShield(client, attacker);
				return Plugin_Handled;
			}
			case 4:
			{
				int damageresist = RoundFloat(float(damage)*shDmgReduction[client]);

				shieldHP[client] -= damage;		// take a small portion of shield health away

				SetEntityHealth(client, health+damageresist);

				shDmgReduction[client] = shieldHP[client]/GetConVarFloat(cvarShieldHealth)*(1.0-GetConVarFloat(cvarShieldResist));

				if(shieldHP[client]<=0.0 || (health+damageresist)<=damage)
				{
					SetEntityHealth(client, preHealth);
					RemoveShield(client, attacker);
					return Plugin_Handled;
				}

				char ric[PLATFORM_MAX_PATH];
				Format(ric, sizeof(ric), "weapons/fx/rics/ric%i.wav", GetRandomInt(1,5));
				EmitSoundToClient(client, ric, _, _, _, _, 0.7, _, _, _, _, false);
				EmitSoundToClient(attacker, ric, _, _, _, _, 0.7, _, _, _, _, false);
				SetEventInt(event, "damageamount", damage-damageresist);
				return Plugin_Changed;
			}
		}
	}

	int boss = GetBossIndex(client);
	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]) || (client==attacker && SelfKnockback[client]<2))
		return Plugin_Continue;

	int custom = GetEventInt(event, "custom");
	if(custom == TF_CUSTOM_TELEFRAG)
	{
		damage = IsPlayerAlive(attacker) ? 9001 : 1;
	}
	else if(custom == TF_CUSTOM_BOOTS_STOMP)
	{
		damage *= 5;
	}

	if(GetEventBool(event, "minicrit") && GetEventBool(event, "allseecrit"))
		SetEventBool(event, "allseecrit", false);

	if(custom==TF_CUSTOM_TELEFRAG || custom==TF_CUSTOM_BOOTS_STOMP)
		SetEventInt(event, "damageamount", damage);

	for(int lives=1; lives<BossLives[boss]; lives++)
	{
		if(BossHealth[boss]-damage <= BossHealthMax[boss]*lives)
		{
			SetEntityHealth(client, (BossHealth[boss]-damage)-BossHealthMax[boss]*(lives-1)); //Set the health early to avoid the boss dying from fire, etc.

			Action action = Plugin_Continue;  //Used for the forward
			int bossLives=BossLives[boss];
			Call_StartForward(OnLoseLife);
			Call_PushCell(boss);
			Call_PushCellRef(bossLives);
			Call_PushCell(BossLivesMax[boss]);
			Call_Finish(action);
			if(action==Plugin_Stop || action==Plugin_Handled)
			{
				return action;
			}
			else if(action == Plugin_Changed)
			{
				if(bossLives > BossLivesMax[boss])
				{
					BossLivesMax[boss] = bossLives;
				}
				BossLives[boss] = bossLives;
			}

			char ability[PLATFORM_MAX_PATH];
			for(int n=1; n<MAXRANDOMS; n++)
			{
				Format(ability, 10, "ability%i", n);
				KvRewind(BossKV[Special[boss]]);
				if(KvJumpToKey(BossKV[Special[boss]], ability))
				{
					if(KvGetNum(BossKV[Special[boss]], "arg0", 0) != -1)
						continue;

					KvGetString(BossKV[Special[boss]], "life", ability, 10);
					if(!ability[0])
					{
						char abilityName[64], pluginName[64];
						KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
						UseAbility(abilityName, pluginName, boss, -1);
					}
					else
					{
						char stringLives[MAXRANDOMS][3];
						int count=ExplodeString(ability, " ", stringLives, MAXRANDOMS, 3);
						for(int j; j<count; j++)
						{
							if(StringToInt(stringLives[j]) == BossLives[boss])
							{
								char abilityName[64], pluginName[64];
								KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
								KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
								UseAbility(abilityName, pluginName, boss, -1);
								break;
							}
						}
					}
				}

				Format(ability, 10, "sound_bgm");
				KvRewind(BossKV[Special[boss]]);
				if(KvJumpToKey(BossKV[Special[boss]], ability))
				{
					Format(ability, 10, "life%i", n);
					KvGetString(BossKV[Special[boss]], ability, ability, 10);
					if(ability[0])
						StartMusic(client);
				}
			}
			BossLives[boss] = lives;

			char bossName[64];
			strcopy(bossName, sizeof(bossName), "=Failed name=");

			strcopy(ability, sizeof(ability), BossLives[boss]==1 ? "ff2_life_left" : "ff2_lives_left");
			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					if(GetConVarInt(cvarGameText) > 0)
					{
						GetBossSpecial(Special[boss], bossName, sizeof(bossName), target);
						ShowGameText(target, "ico_notify_flag_moving_alt", Enabled3 ? GetClientTeam(client) : 0, "%t", ability, bossName, BossLives[boss]);
					}
					else
					{
						GetBossSpecial(Special[boss], bossName, sizeof(bossName), target);
						PrintCenterText(target, "%t", ability, bossName, BossLives[boss]);
					}
				}
			}

			if(BossLives[boss]==1 && RandomSound("sound_last_life", ability, sizeof(ability), boss))
			{
				EmitSoundToAllExcept(ability, _, _, _, _, _, _, _, _, _, false);
			}
			else if(RandomSound("sound_nextlife", ability, sizeof(ability), boss))
			{
				EmitSoundToAllExcept(ability, _, _, _, _, _, _, _, _, _, false);
			}

			UpdateHealthBar();
			break;
		}
	}

	BossHealth[boss] -= damage;
	BossCharge[boss][0] += damage*100.0/BossRageDamage[boss];
	Damage[attacker] += damage;

	int healers[MAXPLAYERS];
	int healerCount;
	for(int target; target<=MaxClients; target++)
	{
		if(IsValidClient(target) && IsPlayerAlive(target) && (GetHealingTarget(target, true)==attacker))
		{
			healers[healerCount]=target;
			healerCount++;
		}
	}

	for(int target; target<healerCount; target++)
	{
		if(IsValidClient(healers[target]) && IsPlayerAlive(healers[target]))
		{
			if(damage<10 || uberTarget[healers[target]]==attacker)
			{
				Damage[healers[target]]+=damage;
			}
			else
			{
				Damage[healers[target]]+=damage/(healerCount+1);
			}
		}
	}

	if(IsValidClient(attacker) && IsValidClient(client) && client!=attacker && damage>0 && !IsBoss(attacker))
	{
		int i;
		if(GetConVarFloat(cvarAirStrike) > 0)  //Air Strike-moved from OTD
		{
			int weapon = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
			if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==1104)
			{
				AirstrikeDamage[attacker] += damage;
				while(AirstrikeDamage[attacker]>=GetConVarFloat(cvarAirStrike) && i<5)
				{
					i++;
					SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
					AirstrikeDamage[attacker] -= GetConVarFloat(cvarAirStrike);
				}
			}
		}
		i = 0;
		if(GetConVarFloat(cvarDmg2KStreak) > 0)
		{
			KillstreakDamage[attacker] += damage;
			while(KillstreakDamage[attacker]>=GetConVarFloat(cvarDmg2KStreak) && i<21)
			{
				i++;
				SetEntProp(attacker, Prop_Send, "m_nStreaks", GetEntProp(attacker, Prop_Send, "m_nStreaks")+1);
				KillstreakDamage[attacker] -= GetConVarFloat(cvarDmg2KStreak);
			}
		}
		if(SapperCooldown[attacker] > 0.0)
			SapperCooldown[attacker] -= damage;
	}

	if(BossCharge[boss][0] > rageMax[client])
		BossCharge[boss][0] = rageMax[client];

	return Plugin_Continue;
}

// True if the condition was removed.
stock bool RemoveCond(int client, TFCond cond)
{
	if(TF2_IsPlayerInCondition(client, cond))
	{
		TF2_RemoveCondition(client, cond);
		return true;
	}
	return false;
}

public Action OnPlayerHealed(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=1)
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(event, "patient"));
	int healer = GetClientOfUserId(GetEventInt(event, "healer"));
	int heals = GetEventInt(event, "amount");

	if(IsBoss(client))
	{
		int boss = GetBossIndex(client);
		int health = BossHealth[boss];
		int totalhealth = BossHealthMax[boss]*BossLives[boss];

		if(client==healer && (SelfHealing[client]==1 || SelfHealing[client]>2))
		{
			health += heals;
			if(health > totalhealth)
				health = totalhealth;
		}
		else if(client!=healer && SelfHealing[client]>1)
		{
			health += heals;
			if(health > totalhealth)
				health = totalhealth;
		}
		BossHealth[boss] = health;
		return Plugin_Continue;
	}

	if(client == healer)
		return Plugin_Continue;

	int extrahealth = GetClientHealth(client)-GetEntProp(client, Prop_Data, "m_iMaxHealth");
	if(extrahealth > 0)
		heals -= extrahealth;

	if(heals > 0)
		Healing[healer] += heals;

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!Enabled || CheckRoundState()!=1)
		return Plugin_Continue;

	int index = -1;
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(entity) && IsValidEdict(entity) && GetClientTeam(client)==OtherTeam && SapperCooldown[client]<=0)
	{
		index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

		if((buttons & IN_ATTACK) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !GetEntProp(client, Prop_Send, "m_bFeignDeathReady") && (index==735 || index==736 || index==810 || index==831 || index==933 || index==1080 || index==1102))
		{
			float position[3], position2[3], distance;
			int boss;
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target)==BossTeam)
				{
					boss = GetBossIndex(target);
					GetEntPropVector(target, Prop_Send, "m_vecOrigin", position2);
					distance = GetVectorDistance(position, position2);
					if(distance<120 && target!=client &&
					  !TF2_IsPlayerInCondition(target, TFCond_Dazed) &&
					  !TF2_IsPlayerInCondition(target, TFCond_Sapped) &&
					  !TF2_IsPlayerInCondition(target, TFCond_UberchargedHidden) &&
					  !TF2_IsPlayerInCondition(target, TFCond_Ubercharged) &&
					  !TF2_IsPlayerInCondition(target, TFCond_Bonked) &&
					  !TF2_IsPlayerInCondition(target, TFCond_MegaHeal))
					{
						if(boss>=0 && SapperBoss[target])
						{
							#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=7
							TF2_StunPlayer(target, 3.0, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
							TF2_AddCondition(target, TFCond_Sapped, 3.0);
							#else
							if(index==810 || index==831)
							{
								TF2_AddCondition(target, TFCond_PasstimePenaltyDebuff, 6.0);
								TF2_AddCondition(target, TFCond_Sapped, 6.0);
							}
							else
							{
								TF2_StunPlayer(target, 3.0, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
								TF2_AddCondition(target, TFCond_Sapped, 3.0);
							}
							#endif
							SapperCooldown[client] = GetConVarFloat(cvarSapperCooldown);
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
							SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+1.0);
							SetEntPropFloat(client, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+1.0);
							return Plugin_Handled;
						}
						else if(boss<0 && SapperMinion)
						{
							#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=7
							TF2_StunPlayer(target, 4.0, 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
							TF2_AddCondition(target, TFCond_Sapped, 4.0);
							#else
							if(index==810 || index==831)
							{
								TF2_AddCondition(target, TFCond_PasstimePenaltyDebuff, 8.0);
								TF2_AddCondition(target, TFCond_Sapped, 8.0);
							}
							else
							{
								TF2_StunPlayer(target, 4.0, 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
								TF2_AddCondition(target, TFCond_Sapped, 4.0);
							}
							#endif
							SapperCooldown[client] = GetConVarFloat(cvarSapperCooldown);
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
							SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+1.0);
							SetEntPropFloat(client, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+1.0);
							return Plugin_Handled;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!Enabled || !IsValidEntity(attacker))
		return Plugin_Continue;

	if((attacker<=0 || client==attacker) && IsBoss(client) && damagetype & DMG_FALL)
	{
		return Plugin_Handled;
	}
	else if((attacker<=0 || client==attacker) && IsBoss(client) && !SelfKnockback[client])
	{
		return Plugin_Handled;
	}

	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
		return Plugin_Continue;

	float position[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);

	if(IsBoss(attacker) && IsValidClient(client))
	{
		int boss = GetBossIndex(client);
		if(boss==-1 && !TF2_IsPlayerInCondition(client, TFCond_Bonked))
		{
			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);
				damage *= 0.3;
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))
			{
				damage *= 9;
				TF2_AddCondition(client, TFCond_Bonked, 0.1);
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
			{
				damage *= 0.25;
				return Plugin_Changed;
			}

			if(damage<=160.0 && dmgTriple[attacker])
			{
				damage *= 3;
				return Plugin_Changed;
			}
		}
		else if(boss != -1)
		{
			bool bIsTelefrag, bIsBackstab;
			if(damagecustom == TF_CUSTOM_BACKSTAB)
			{
				bIsBackstab = true;
			}
			else if(damagecustom == TF_CUSTOM_TELEFRAG)
			{
				bIsTelefrag = true;
			}
			else if(weapon!=4095 && IsValidEntity(weapon) && weapon==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage>1000.0)
			{
				char classname[32];
				if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_knife", false))
					bIsBackstab = true;
			}
			else if(!IsValidEntity(weapon) && (damagetype & DMG_CRUSH)==DMG_CRUSH && damage==1000.0)
			{
				bIsTelefrag = true;
			}

			if(bIsBackstab)
			{
				if(TimesTen)
				{
					damage = BossHealthMax[boss]*bosses*(LastBossIndex()+1)*BossLivesMax[boss]*(0.1-Stabbed[boss]/90)/(GetConVarFloat(cvarTimesTen)*3);
				}
				else if(GetConVarBool(cvarLowStab))
				{
					damage = (BossHealthMax[boss]*bosses*(LastBossIndex()+1)*BossLivesMax[boss]*(0.11-Stabbed[boss]/90)+(750/float(playing)))/5;
				}
				else
				{
					damage = BossHealthMax[boss]*bosses*(LastBossIndex()+1)*BossLivesMax[boss]*(0.12-Stabbed[boss]/90)/5;
				}
				damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
				damagecustom = 0;

				EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
				EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+1.5);
				SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+1.5);
				SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+1.5);

				int viewmodel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
				if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
				{
					int melee = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
					int animation = 42;
					switch(melee)
					{
						case 225, 356, 423, 461, 574, 649, 1071, 30758:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan, Prinny Machete
							animation=16;

						case 638:  //Sharp Dresser
							animation=32;
					}
					SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
				}

				if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
				{
					if(TellName)
					{
						char spcl[768];
						GetBossSpecial(Special[boss], spcl, sizeof(spcl), attacker);
						switch(Annotations)
						{
							case 1:
								CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Backstab Player", spcl);

							case 2:
								ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Backstab Player", spcl);

							default:
								PrintHintText(attacker, "%t", "Backstab Player", spcl);
						}
					}
					else
					{
						switch(Annotations)
						{
							case 1:
								CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Backstab");

							case 2:
								ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Backstab");

							default:
								PrintHintText(attacker, "%t", "Backstab");
						}
					}
				}

					/*int aList[16];
					float aValues[16];
					Address aAddress;
					bool aSlient;
					int iCount = TF2Attrib_ListDefIndices(iEntity, iAttribList);
					if(iCount > 0)
					{
						for(int i; i<iCount; i++)
						{
							aAddress = TF2Attrib_GetByDefIndex(iEntity, aList[i]);
							aValues[i] = TF2Attrib_GetValue(aAddress);
							switch(aList[i])
							{
								case 154:
								{
									if(aValues[i])
										CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
								}
								case 156:
								{
									if(aValues[i])
										aSlient = true;
								}
								case 217:
								{
									if(aValues[i]>0 && (SelfHealing[attacker]==1 || SelfHealing[attacker]>2))
										BossHealth[GetBossIndex(attacker)] += RoundToFloor(damage*3.0*aValues[i]);
								}
							}
						}
					}*/

				if(/*!aSlient*/ bIsBackstab)
				{
					EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);

					if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							char spcl[768];
							GetBossSpecial(Special[GetBossIndex(attacker)], spcl, sizeof(spcl), attacker);
							switch(Annotations)
							{
								case 1:
									CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Backstabbed Player", spcl);

								case 2:
									ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Backstabbed Player", spcl);

								default:
									PrintHintText(client, "%t", "Backstabbed Player", spcl);
							}
						}
						else
						{
							switch(Annotations)
							{
								case 1:
									CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Backstabbed");

								case 2:
									ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Backstabbed");

								default:
									PrintHintText(client, "%t", "Backstabbed");
							}
						}
					}

					if(BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1) > damage*3)
					{
						char sound[PLATFORM_MAX_PATH];
						if(RandomSound("sound_stabbed_boss", sound, sizeof(sound), boss))
						{
							EmitSoundToAllExcept(sound, _, _, _, _, _, _, Boss[boss], _, _, false);
						}
						else if(RandomSound("sound_stabbed", sound, sizeof(sound), boss))
						{
							EmitSoundToAllExcept(sound, _, _, _, _, _, _, Boss[boss], _, _, false);
						}
					}

					HealthBarMode = true;
					CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
				}

				if(Stabbed[boss] < 3)
					Stabbed[boss]++;

				return Plugin_Changed;
			}

			if(bIsTelefrag)
			{
				damagecustom = 0;
				if(!IsPlayerAlive(attacker))
				{
					damage = 1.0;
					return Plugin_Changed;
				}
				damage = BossHealth[boss]*1.001;

				for(int all=1; all<=MaxClients; all++)
				{
					if(IsValidClient(all) && IsPlayerAlive(all))
					{
						if(!(FF2flags[all] & FF2FLAG_HUDDISABLED))
						{
							switch(Annotations)
							{
								case 1:
									CreateAttachedAnnotation(all, client, true, 5.0, "%t", "Telefrag Global");

								case 2:
									ShowGameText(all, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Global");

								default:
									PrintHintText(all, "%t", "Telefrag Global");
							}
						}
					}
				}

				int teleowner = FindTeleOwner(attacker);
				if(IsValidClient(teleowner) && teleowner!=attacker)
				{
					if(GetClientTeam(teleowner) == GetClientTeam(attacker))
						Damage[teleowner] += BossHealth[boss]*3/5;

					if(!(FF2flags[teleowner] & FF2FLAG_HUDDISABLED))
					{
						switch(Annotations)
						{
							case 1:
								CreateAttachedAnnotation(teleowner, client, true, 5.0, "%t", "Telefrag Assist");

							case 2:
								ShowGameText(teleowner, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Assist");

							default:
								PrintHintText(teleowner, "%t", "Telefrag Assist");
						}
					}
				}

				if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
				{
					if(TellName)
					{
						char spcl[768];
						GetBossSpecial(Special[boss], spcl, sizeof(spcl), attacker);
						switch(Annotations)
						{
							case 1:
								CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Telefrag Player", spcl);

							case 2:
								ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Player", spcl);

							default:
								PrintHintText(attacker, "%t", "Telefrag Player", spcl);
						}
					}
					else
					{
						switch(Annotations)
						{
							case 1:
								CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Telefrag");

							case 2:
								ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Telefrag");

							default:
								PrintHintText(attacker, "%t", "Telefrag");
						}
					}
				}

				if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
				{
					if(TellName)
					{
						char spcl[768];
						GetBossSpecial(Special[GetBossIndex(attacker)], spcl, sizeof(spcl), client);
						switch(Annotations)
						{
							case 1:
								CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Telefraged Player", spcl);

							case 2:
								ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Telefraged Player", spcl);

							default:
								PrintHintText(client, "%t", "Telefraged Player", spcl);
						}
					}
					else
					{
						switch(Annotations)
						{
							case 1:
								CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Telefraged");

							case 2:
								ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Telefraged");

							default:
								PrintHintText(client, "%t", "Telefraged");
						}
					}
				}

				char sound[PLATFORM_MAX_PATH];
				if(RandomSound("sound_telefraged", sound, sizeof(sound)))
					EmitSoundToAllExcept(sound);

				HealthBarMode = true;
				CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
				return Plugin_Changed;
			}

			bool changed;
			if(damage<=160.0 && dmgTriple[attacker])
			{
				damage *= 3;
				changed = true;
			}

			if(damagetype & DMG_CRIT)
			{
				if(damage > 333)
				{
					damage = 333.0;
					changed = true;
				}
			}
			else if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed) || TF2_IsPlayerInCondition(attacker, TFCond_NoHealingDamageBuff))
			{
				if(damage > 740)
				{
					damage = 740.0;
					changed = true;
				}
			}
			else if(damage > 999)
			{
				damage = 999.0;
				changed = true;
			}

			if(changed)
				return Plugin_Changed;
		}
	}
	else
	{
		int boss = GetBossIndex(client);
		if(boss != -1)
		{
			if(attacker <= MaxClients)
			{
				bool bIsTelefrag, bIsBackstab;
				if(damagecustom == TF_CUSTOM_BACKSTAB)
				{
					bIsBackstab = true;
				}
				else if(damagecustom == TF_CUSTOM_TELEFRAG)
				{
					bIsTelefrag = true;
				}
				else if(weapon!=4095 && IsValidEntity(weapon) && weapon==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage>1000.0)
				{
					char classname[32];
					if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_knife", false))
						bIsBackstab = true;
				}
				else if(!IsValidEntity(weapon) && (damagetype & DMG_CRUSH)==DMG_CRUSH && damage==1000.0)
				{
					bIsTelefrag = true;
				}

				int index;
				char classname[64];
				if(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients)
				{
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(!StrContains(classname, "eyeball_boss"))  //Dang spell Monoculuses
					{
						index = -1;
						Format(classname, sizeof(classname), "");
					}
					else
					{
						index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					}
				}
				else
				{
					index = -1;
					Format(classname, sizeof(classname), "");
				}

				//Sniper rifles aren't handled by the switch/case because of the amount of reskins there are
				if(!StrContains(classname, "tf_weapon_sniperrifle"))
				{
					if(CheckRoundState() != 2)
					{
						float charge=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						if(index == 752)  //Hitman's Heatmaker
						{
							float focus = 10+(charge/10);
							if(TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
								focus /= 3;

							float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
							SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage+focus>100) ? 100.0 : rage+focus);
						}
						else if(index!=230 && index!=402 && index!=526 && index!=30665)  //Sydney Sleeper, Bazaar Bargain, Machina, Shooting Star
						{
							float time = (GlowTimer[boss]>10 ? 1.0 : 2.0);
							time += (GlowTimer[boss]>10 ? (GlowTimer[boss]>20 ? 1.0 : 2.0) : 4.0)*(charge/100.0);
							SetClientGlow(Boss[boss], time);
							if(GlowTimer[boss] > 25.0)
								GlowTimer[boss] = 25.0;
						}

						if(!(damagetype & DMG_CRIT))
						{
							if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
							{
								damage *= SniperMiniDamage;
							}
							else if(index!=230 || BossCharge[boss][0]>90.0)  //Sydney Sleeper
							{
								damage *= SniperDamage;
							}
							else
							{
								damage *= (SniperDamage*0.8);
							}
							return Plugin_Changed;
						}
					}
				}
				else if(!StrContains(classname, "tf_weapon_compound_bow"))
				{
					if(CheckRoundState() != 2)
					{
						if((damagetype & DMG_CRIT))
						{
							damage *= BowDamage;
							return Plugin_Changed;
						}
						else if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
						{
							if(BowDamageMini > 0)
							{
								damage *= BowDamageMini;
								return Plugin_Changed;
							}
						}
						else if(BowDamageNon>0)
						{
							damage *= BowDamageNon;
							return Plugin_Changed;
						}
					}
				}

				switch(index)
				{
					case 61, 1006:  //Ambassador, Festive Ambassador
					{
						if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0)
						{
							if(damagecustom == TF_CUSTOM_HEADSHOT)
							{
								damage = 85.0;  //Final damage 255
								return Plugin_Changed;
							}
						}
					}
					case 132, 266, 482, 1082:  //Eyelander, HHHH, Nessie's Nine Iron, Festive Eyelander
					{
						IncrementHeadCount(attacker);
					}
					case 214:  //Powerjack
					{
						if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0)
						{
							int health = GetClientHealth(attacker);
							int newhealth = health+25;
							if(newhealth <= GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
								SetEntityHealth(attacker, newhealth);
						}
					}
					case 307:  //Ullapool Caber
					{
						if(GetEntProp(weapon, Prop_Send, "m_iDetonated") == 0)	// If using ullapool caber, only trigger if bomb hasn't been detonated
                        			{
							if(TimesTen)
							{
								damage = ((Pow(float(BossHealthMax[boss]), 0.74074)-(Cabered[client]/128.0*float(BossHealthMax[boss])))/(3+(GetConVarFloat(cvarTimesTen)*allowedDetonations*3)))*bosses;
							}
							else if(GetConVarBool(cvarLowStab))
							{
								damage = ((Pow(float(BossHealthMax[boss]), 0.74074)+(2000.0/float(playing))+206.0-(Cabered[client]/128.0*float(BossHealthMax[boss])))/(3+(allowedDetonations*3)))*bosses;
							}
							else
							{
								damage = ((Pow(float(BossHealthMax[boss]), 0.74074)+512.0-(Cabered[client]/128.0*float(BossHealthMax[boss])))/(3+(allowedDetonations*3)))*bosses;
							}
							damagetype |= DMG_CRIT;

							if(Cabered[client] < 5)
								Cabered[client]++;

							if(allowedDetonations < 3)
							{
								if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
								{
									if(TellName)
									{
										char spcl[768];
										GetBossSpecial(Special[boss], spcl, sizeof(spcl), attacker);
										switch(Annotations)
										{
											case 1:
												CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Caber Player", spcl);

											case 2:
												ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Caber Player", spcl);

											default:
												PrintHintText(attacker, "%t", "Caber Player", spcl);
										}
									}
									else
									{
										switch(Annotations)
										{
											case 1:
												CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Caber");

											case 2:
												ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Caber");

											default:
												PrintHintText(attacker, "%t", "Caber");
										}
									}
								}
								if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
								{
									if(TellName)
									{
										switch(Annotations)
										{
											case 1:
												CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Cabered Player", attacker);

											case 2:
												ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Cabered Player", attacker);

											default:
												PrintHintText(client, "%t", "Cabered Player", attacker);
										}
									}
									else
									{
										switch(Annotations)
										{
											case 1:
												CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Cabered");

											case 2:
												ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Cabered");

											default:
												PrintHintText(client, "%t", "Cabered");
										}
									}
								}

								EmitSoundToClient(attacker, "ambient/lightsoff.wav", _, _, _, _, 0.6, _, _, position, _, false);
								EmitSoundToClient(client, "ambient/lightson.wav", _, _, _, _, 0.6, _, _, position, _, false);

								if(BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1) > damage*3)
								{
									char sound[PLATFORM_MAX_PATH];
									if(RandomSound("sound_cabered", sound, sizeof(sound)))
										EmitSoundToAllExcept(sound);
								}

								HealthBarMode = true;
								CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
							}
							return Plugin_Changed;
						}
					}
					case 310:  //Warrior's Spirit
					{
						if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0)
						{
							int health = GetClientHealth(attacker);
							int newhealth = health+50;
							if(newhealth <= GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
								SetEntityHealth(attacker, newhealth);
						}
					}
					case 317:  //Candycane
					{
						SpawnSmallHealthPackAt(client, GetClientTeam(attacker), attacker);
					}
					case 327:  //Claidheamh Mor
					{
						if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0)
						{
							float charge=GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter");
							if(charge+25.0 >= 100.0)
							{
								SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", 100.0);
							}
							else
							{
								SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", charge+25.0);
							}
						}
					}
					case 348:  //Sharpened Volcano Fragment
					{
						if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0)
						{
							int health = GetClientHealth(attacker);
							int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
							int newhealth = health+5;
							if(health < max+60)
							{
								if(newhealth > max+60)
									newhealth=max+60;

								SetEntityHealth(attacker, newhealth);
							}
						}
					}
					case 357:  //Half-Zatoichi
					{
						int health = GetClientHealth(attacker);
						int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						int max2 = RoundToFloor(max*2.0);
						int newhealth;
						if(GetEntProp(weapon, Prop_Send, "m_bIsBloody"))	// Less effective used more than once
						{
							newhealth = health+25;
							if(health < max2)
							{
								if(newhealth > max2)
									newhealth = max2;

								SetEntityHealth(attacker, newhealth);
							}
						}
						else	// Most effective on first hit
						{
							newhealth = health + RoundToFloor(max/2.0);
							if(health < max2)
							{
								if(newhealth > max2)
									newhealth = max2;

								SetEntityHealth(attacker, newhealth);
							}
							if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
								TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
						SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
						if(GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
							SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
					}
					case 416:  //Market Gardener (courtesy of Chdata)
					{
						if(RemoveCond(attacker, TFCond_BlastJumping))	// New way to check explosive jumping status
						//if(FF2flags[attacker] & FF2FLAG_ROCKET_JUMPING)
                        			{
							if(TimesTen)
							{
								damage = ((Pow(float(BossHealthMax[boss]), 0.74074)-(Marketed[client]/128.0*float(BossHealthMax[boss])))/(GetConVarFloat(cvarTimesTen)*3))*bosses;
							}
							else if(GetConVarBool(cvarLowStab))
							{
								damage = ((Pow(float(BossHealthMax[boss]), 0.74074)+(1750.0/float(playing))+206.0-(Marketed[client]/128.0*float(BossHealthMax[boss])))/3)*bosses;
							}
							else
							{
								damage = ((Pow(float(BossHealthMax[boss]), 0.74074)+512.0-(Marketed[client]/128.0*float(BossHealthMax[boss])))/3)*bosses;
							}
							damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;

							if(RemoveCond(attacker, TFCond_Parachute))	// If you parachuted to do this, remove your parachute.
								damage *= 0.8;	// And nerf your damage

							if(Marketed[client] < 5)
								Marketed[client]++;

							if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
							{
								if(TellName)
								{
									char spcl[768];
									GetBossSpecial(Special[boss], spcl, sizeof(spcl), attacker);
									switch(Annotations)
									{
										case 1:
											CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Market Gardener Player", spcl);

										case 2:
											ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Market Gardener Player", spcl);

										default:
											PrintHintText(attacker, "%t", "Market Gardener Player", spcl);
									}
								}
								else
								{
									switch(Annotations)
									{
										case 1:
											CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Market Gardener");

										case 2:
											ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Market Gardener");

										default:
											PrintHintText(attacker, "%t", "Market Gardener");
									}
								}
							}
							if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
							{
								if(TellName)
								{
									switch(Annotations)
									{
										case 1:
											CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Market Gardened Player", attacker);

										case 2:
											ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Market Gardened Player", attacker);

										default:
											PrintHintText(client, "%t", "Market Gardened Player", attacker);
									}
								}
								else
								{
									switch(Annotations)
									{
										case 1:
											CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Market Gardened");

										case 2:
											ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Market Gardened");

										default:
											PrintHintText(client, "%t", "Market Gardened");
									}
								}
							}

							EmitSoundToClient(attacker, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
							EmitSoundToClient(client, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);

							if(BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1) > damage*3)
							{
								char sound[PLATFORM_MAX_PATH];
								if(RandomSound("sound_marketed", sound, sizeof(sound)))
									EmitSoundToAllExcept(sound);
							}

							HealthBarMode = true;
							CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
							return Plugin_Changed;
						}
					}
					case 525, 595:  //Diamondback, Manmelter
					{
						if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0)
						{
							if(GetEntProp(attacker, Prop_Send, "m_iRevengeCrits"))  //If a revenge crit was used, give a damage bonus
							{
								damage = 85.0;  //255 final damage
								return Plugin_Changed;
							}
						}
					}
					case 528:  //Short Circuit
					{
						if(circuitStun)
						{
							TF2_StunPlayer(client, circuitStun, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
							EmitSoundToAll("weapons/barret_arm_zap.wav", client);
							EmitSoundToClient(client, "weapons/barret_arm_zap.wav");
						}
					}
					case 593:  //Third Degree
					{
						int healers[MAXPLAYERS];
						int healerCount;
						for(int healer; healer<=MaxClients; healer++)
						{
							if(IsValidClient(healer) && IsPlayerAlive(healer) && (GetHealingTarget(healer, true)==attacker))
							{
								healers[healerCount]=healer;
								healerCount++;
							}
						}

						for(int healer; healer<healerCount; healer++)
						{
							if(IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
							{
								int medigun=GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
								if(IsValidEntity(medigun))
								{
									char medigunClassname[64];
									GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
									if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
									{
										float uber=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(0.1/healerCount);
										if(uber>1.0)
											uber=1.0;

										SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
									}
								}
							}
						}
					}
					case 594:  //Phlogistinator
					{
						if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0)
						{
							if(!TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))
							{
								damage/=2.0;
								return Plugin_Changed;
							}
						}
					}
				}

				if(bIsBackstab)
				{
					if(TimesTen)
					{
						damage = BossHealthMax[boss]*bosses*(LastBossIndex()+1)*BossLivesMax[boss]*(0.1-Stabbed[boss]/90)/(GetConVarFloat(cvarTimesTen)*3);
					}
					else if(GetConVarBool(cvarLowStab))
					{
						damage = (BossHealthMax[boss]*bosses*(LastBossIndex()+1)*BossLivesMax[boss]*(0.11-Stabbed[boss]/90)+(1500/float(playing)))/3;
					}
					else
					{
						damage = BossHealthMax[boss]*bosses*(LastBossIndex()+1)*BossLivesMax[boss]*(0.12-Stabbed[boss]/90)/3;
					}
					damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
					damagecustom = 0;

					EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);

					int viewmodel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
					if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
					{
						int melee = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
						int animation = 42;
						switch(melee)
						{
							case 225, 356, 423, 461, 574, 649, 1071, 30758:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan, Prinny Machete
								animation=16;

							case 638:  //Sharp Dresser
								animation=32;
						}
						SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
					}

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							char spcl[768];
							GetBossSpecial(Special[boss], spcl, sizeof(spcl), attacker);
							switch(Annotations)
							{
								case 1:
									CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Backstab Player", spcl);

								case 2:
									ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Backstab Player", spcl);

								default:
									PrintHintText(attacker, "%t", "Backstab Player", spcl);
							}
						}
						else
						{
							switch(Annotations)
							{
								case 1:
									CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Backstab");

								case 2:
									ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Backstab");

								default:
									PrintHintText(attacker, "%t", "Backstab");
							}
						}
					}

					if(index!=225 && index!=574)  //Your Eternal Reward, Wanga Prick
					{
						EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
						EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);

						if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
						{
							if(TellName)
							{
								char spcl[768];
								GetClientName(attacker, spcl, sizeof(spcl));
								switch(Annotations)
								{
									case 1:
										CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Backstabbed Player", spcl);

									case 2:
										ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Backstabbed Player", spcl);

									default:
										PrintHintText(client, "%t", "Backstabbed Player", spcl);
								}
							}
							else
							{
								switch(Annotations)
								{
									case 1:
										CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Backstabbed");

									case 2:
										ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Backstabbed");

									default:
										PrintHintText(client, "%t", "Backstabbed");
								}
							}
						}


						if(BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1) > damage*3)
						{
							char sound[PLATFORM_MAX_PATH];
							if(RandomSound("sound_stabbed", sound, sizeof(sound), boss))
								EmitSoundToAllExcept(sound, _, _, _, _, _, _, Boss[boss]);
						}

						HealthBarMode = true;
						CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
					}
					switch(index)
					{
						case 225, 574:	//Your Eternal Reward, Wanga Prick
						{
							CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
						}
						case 356:	//Conniver's Kunai
						{
							int health = GetClientHealth(attacker)+200;
							if(health > 600)
								health = 600;

							SetEntityHealth(attacker, health);
						}
						case 461:	//Big Earner
						{
							SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);  //Full cloak
							TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);  //Speed boost
						}
					}

					if(GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary)==525)  //Diamondback
						SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+3);

					if(Stabbed[boss] < 3)
						Stabbed[boss]++;

					return Plugin_Changed;
				}

				if(bIsTelefrag)
				{
					damagecustom=0;
					if(!IsPlayerAlive(attacker))
					{
						damage=1.0;
						return Plugin_Changed;
					}
					damage = (TimesTen ? 5000.0*GetConVarFloat(cvarTimesTen) : 9001.0);

					for(int all; all<=MaxClients; all++)
					{
						if(IsValidClient(all) && IsPlayerAlive(all))
						{
							if(!(FF2flags[all] & FF2FLAG_HUDDISABLED))
							{
								switch(Annotations)
								{
									case 1:
										CreateAttachedAnnotation(all, client, true, 5.0, "%t", "Telefrag Global");

									case 2:
										ShowGameText(all, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Global");

									default:
										PrintHintText(all, "%t", "Telefrag Global");
								}
							}
						}
					}

					int teleowner = FindTeleOwner(attacker);
					if(IsValidClient(teleowner) && teleowner!=attacker)
					{
						if(GetClientTeam(teleowner) == GetClientTeam(attacker))
						{
							Damage[teleowner] += (TimesTen ? 3000.0*GetConVarFloat(cvarTimesTen) : 5401.0);

							if(!(FF2flags[teleowner] & FF2FLAG_HUDDISABLED))
							{
								switch(Annotations)
								{
									case 1:
										CreateAttachedAnnotation(teleowner, client, true, 5.0, "%t", "Telefrag Assist");

									case 2:
										ShowGameText(teleowner, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Assist");

									default:
										PrintHintText(teleowner, "%t", "Telefrag Assist");
								}
							}
						}
					}

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							char spcl[768];
							GetBossSpecial(Special[boss], spcl, sizeof(spcl), attacker);
							switch(Annotations)
							{
								case 1:
									CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Telefrag Player", spcl);

								case 2:
									ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Player", spcl);

								default:
									PrintHintText(attacker, "%t", "Telefrag Player", spcl);
							}
						}
						else
						{
							switch(Annotations)
							{
								case 1:
									CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Telefrag");

								case 2:
									ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Telefrag");

								default:
									PrintHintText(attacker, "%t", "Telefrag");
							}
						}
					}

					if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							char spcl[768];
							GetClientName(attacker, spcl, sizeof(spcl));
							switch(Annotations)
							{
								case 1:
									CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Telefraged Player", spcl);

								case 2:
									ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Telefraged Player", spcl);

								default:
									PrintHintText(client, "%t", "Telefraged Player", spcl);
							}
						}
						else
						{
							switch(Annotations)
							{
								case 1:
									CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Telefraged");

								case 2:
									ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Telefraged");

								default:
									PrintHintText(client, "%t", "Telefraged");
							}
						}
					}

					char sound[PLATFORM_MAX_PATH];
					if(RandomSound("sound_telefraged", sound, sizeof(sound)))
						EmitSoundToAllExcept(sound);

					HealthBarMode = true;
					CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
					return Plugin_Changed;
				}

				if((damagetype & DMG_CLUB) && TF2_GetPlayerClass(client)!=TFClass_Spy)
				{
					int melee = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
					if(melee!=416 && melee!=307 && melee!=44)
					{
						damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
						return Plugin_Changed;
					}
				}
			}
			else
			{
				char classname[64];
				if(GetEntityClassname(attacker, classname, sizeof(classname)) && !strcmp(classname, "trigger_hurt", false))
				{
					if(SpawnTeleOnTriggerHurt && IsBoss(client) && CheckRoundState()==1)
					{
						HazardDamage[client] += damage;
						if(HazardDamage[client] >= GetConVarFloat(cvarDamageToTele))
						{
							TeleportToMultiMapSpawn(client);
							HazardDamage[client] = 0.0;
						}
					}

					Action action = Plugin_Continue;
					Call_StartForward(OnTriggerHurt);
					Call_PushCell(boss);
					Call_PushCell(attacker);
					float damage2 = damage;
					Call_PushFloatRef(damage2);
					Call_Finish(action);
					if(action!=Plugin_Stop && action!=Plugin_Handled)
					{
						if(action == Plugin_Changed)
							damage=damage2;

						if(damage > 600.0)
							damage = 600.0;

						BossHealth[boss] -= RoundFloat(damage);
						BossCharge[boss][0] += damage*100.0/BossRageDamage[boss];
						if(BossHealth[boss] <= 0)
							damage *= 5;

						if(BossCharge[boss][0] > rageMax[client])
							BossCharge[boss][0] = rageMax[client];

						return Plugin_Changed;
					}
					else
					{
						return action;
					}
				}
			}

			if(BossCharge[boss][0] > rageMax[client])
				BossCharge[boss][0] = rageMax[client];
		}
		else
		{
			if(allowedDetonations > 1)
			{
				int index = (IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
				if(index == 307)  //Ullapool Caber
				{
					if(detonations[attacker] < allowedDetonations)
					{
						detonations[attacker]++;
						PrintHintText(attacker, "%t", "Detonations Left", allowedDetonations-detonations[attacker]);
						if(allowedDetonations-detonations[attacker])  //Don't reset their caber if they have 0 detonations left
						{
							SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
							SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
						}
					}
				}
			}

			if(IsValidClient(client, false) && TF2_GetPlayerClass(client)==TFClass_Soldier)  //TODO: LOOK AT THIS
			{
				if(damagetype & DMG_FALL)
				{
					int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(secondary<=0 || !IsValidEntity(secondary))
					{
						damage/=10.0;
						return Plugin_Changed;
					}
				}
			}

			if(Enabled3 && GetConVarFloat(cvarBvBMerc)!=1 && RedAliveBosses && BlueAliveBosses)
			{
				if(IsValidClient(client) && IsValidClient(attacker) && GetClientTeam(attacker)!=GetClientTeam(client))
				{
					damage *= GetConVarFloat(cvarBvBMerc);
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action TF2_OnPlayerTeleport(int client, int teleporter, bool &result)
{
	if(IsBoss(client))
	{
		switch(bossTeleportation)
		{
			case -1:  //No bosses are allowed to use teleporters
				result = false;

			case 1:  //All bosses are allowed to use teleporters
				result = true;
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnStomp(int attacker, int victim, float &damageMultiplier, float &damageBonus, float &JumpPower)
{
	if(!Enabled || !IsValidClient(attacker) || !IsValidClient(victim) || attacker==victim)
		return Plugin_Continue;

	if(IsBoss(victim))
	{
		damageMultiplier = GoombaDamage;
		JumpPower = reboundPower;
		if(TimesTen)
		{
			damageMultiplier /= GetConVarFloat(cvarTimesTen);
			JumpPower *= 2.0;
		}
		return Plugin_Changed;
	}
	else if(IsBoss(attacker))
	{
		if(shield[victim])
		{
			float position[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
			RemoveShield(victim, attacker);
			damageMultiplier = 0.0;
			damageBonus = 0.0;
			return Plugin_Changed;
		}
		damageMultiplier = 3.0;
		damageBonus = 201.5;
		JumpPower = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public int OnStompPost(int attacker, int victim, float damageMultiplier, float damageBonus, float jumpPower)
{
	int boss;
	char spcl[64];
	if(IsBoss(victim))
	{
		if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
		{
			if(TellName)
			{
				boss = GetBossIndex(victim);
				GetBossSpecial(Special[boss], spcl, sizeof(spcl), attacker);
				switch(Annotations)
				{
					case 1:
						CreateAttachedAnnotation(attacker, victim, true, 3.0, "%t", "Goomba Stomp Player", spcl);

					case 2:
						ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp Player", spcl);

					default:
						PrintHintText(attacker, "%t", "Goomba Stomp Player", spcl);
				}
			}
			else
			{
				switch(Annotations)
				{
					case 1:
						CreateAttachedAnnotation(attacker, victim, true, 3.0, "%t", "Goomba Stomp");

					case 2:
						ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp");

					default:
						PrintHintText(attacker, "%t", "Goomba Stomp");
				}
			}
		}
		if(!(FF2flags[victim] & FF2FLAG_HUDDISABLED))
		{
			if(TellName)
			{
				if(IsBoss(attacker))
				{
					boss = GetBossIndex(attacker);
					GetBossSpecial(Special[boss], spcl, sizeof(spcl), victim);
				}
				else
				{
					GetClientName(attacker, spcl, sizeof(spcl));
				}
				switch(Annotations)
				{
					case 1:
						CreateAttachedAnnotation(victim, attacker, true, 3.0, "%t", "Goomba Stomped Boss Player", spcl);

					case 2:
						ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped Boss Player", spcl);

					default:
						PrintHintText(victim, "%t", "Goomba Stomped Boss Player", spcl);
				}
			}
			else
			{
				switch(Annotations)
				{
					case 1:
						CreateAttachedAnnotation(victim, attacker, true, 3.0, "%t", "Goomba Stomped Boss");

					case 2:
						ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped Boss");

					default:
						PrintHintText(victim, "%t", "Goomba Stomped Boss");
				}
			}
		}
		HealthBarMode = true;
		CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
		UpdateHealthBar();
	}
	else if(IsBoss(attacker))
	{
		if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
		{
			if(TellName)
			{
				if(IsBoss(victim))
				{
					boss = GetBossIndex(victim);
					GetBossSpecial(Special[boss], spcl, sizeof(spcl), attacker);
				}
				else
				{
					GetClientName(victim, spcl, sizeof(spcl));
				}
				switch(Annotations)
				{
					case 1:
						CreateAttachedAnnotation(attacker, victim, true, 3.0, "%t", "Goomba Stomp Boss Player", spcl);

					case 2:
						ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp Boss Player", spcl);

					default:
						PrintHintText(attacker, "%t", "Goomba Stomp Boss Player", spcl);
				}
			}
			else
			{
				switch(Annotations)
				{
					case 1:
						CreateAttachedAnnotation(attacker, victim, true, 3.0, "%t", "Goomba Stomp Boss");

					case 2:
						ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp Boss");

					default:
						PrintHintText(attacker, "%t", "Goomba Stomp Boss");
				}
			}
		}
		if(!(FF2flags[victim] & FF2FLAG_HUDDISABLED))
		{
			if(TellName)
			{
				boss = GetBossIndex(attacker);
				GetBossSpecial(Special[boss], spcl, sizeof(spcl), victim);
				switch(Annotations)
				{
					case 1:
						CreateAttachedAnnotation(victim, attacker, true, 3.0, "%t", "Goomba Stomped Player", spcl);

					case 2:
						ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped Player", spcl);

					default:
						PrintHintText(victim, "%t", "Goomba Stomped Player", spcl);
				}
			}
			else
			{
				switch(Annotations)
				{
					case 1:
						CreateAttachedAnnotation(victim, attacker, true, 3.0, "%t", "Goomba Stomped");

					case 2:
						ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped");

					default:
						PrintHintText(victim, "%t", "Goomba Stomped");
				}
			}
		}
	}
}

public Action RTD_CanRollDice(int client)
{
	if(IsBoss(client) && !canBossRTD)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action RTD2_CanRollDice(int client)
{
	if(IsBoss(client) && !canBossRTD)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action OnGetMaxHealth(int client, int &maxHealth)
{
	if(IsBoss(client))
	{
		int boss = GetBossIndex(client);
		SetEntityHealth(client, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1));
		maxHealth = BossHealthMax[boss];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

void GetBossSpecial(int boss=0, char[] buffer, int bufferLength, int client=0)
{
	if(boss < 0)
		return;

	if(!BossKV[boss])
		return;

	char name[64], language[20];
	GetLanguageInfo(IsValidClient(client) ? GetClientLanguage(client) : GetServerLanguage(), language, 8, name, 8);
	Format(language, sizeof(language), "name_%s", language);

	KvRewind(BossKV[boss]);
	KvGetString(BossKV[boss], language, name, bufferLength);
	if(!name[0])
	{
		if(IsValidClient(client))	// Don't check server's lanuage twice
		{
			GetLanguageInfo(GetServerLanguage(), language, 8, name, 8);
			Format(language, sizeof(language), "name_%s", language);
			KvGetString(BossKV[boss], language, name, bufferLength);
		}
		if(!name[0])
		{
			KvGetString(BossKV[boss], "name", name, bufferLength);
			if(!name[0])
				return;
		}
	}
	strcopy(buffer, bufferLength, name);
}

stock int GetClientCloakIndex(int client)
{
	if(!IsValidClient(client, false))
		return -1;

	int weapon = GetPlayerWeaponSlot(client, 4);
	if(!IsValidEntity(weapon))
		return -1;

	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if(strncmp(classname, "tf_wea", 6, false))
		return -1;

	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

stock int SpawnSmallHealthPackAt(int client, int team=0, int attacker)
{
	if(!IsValidClient(client, false) || !IsPlayerAlive(client))
		return;

	int healthpack = CreateEntityByName("item_healthkit_small");
	float position[3];
	GetClientAbsOrigin(client, position);
	position[2] += 20.0;
	if(IsValidEntity(healthpack))
	{
		DispatchKeyValue(healthpack, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(healthpack);
		SetEntProp(healthpack, Prop_Send, "m_iTeamNum", team, 4);
		SetEntityMoveType(healthpack, MOVETYPE_VPHYSICS);
		float velocity[3];//={float(GetRandomInt(-10, 10)), float(GetRandomInt(-10, 10)), 50.0};  //Q_Q
		velocity[0] = float(GetRandomInt(-10, 10)), velocity[1]=float(GetRandomInt(-10, 10)), velocity[2]=50.0;  //I did this because setting it on the creation of the vel variable was creating a compiler error for me.
		TeleportEntity(healthpack, position, NULL_VECTOR, velocity);
		SetEntPropEnt(healthpack, Prop_Send, "m_hOwnerEntity", attacker);
	}
}

stock void IncrementHeadCount(int client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);

	int decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
	int health = GetClientHealth(client);
	SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations+1);
	SetEntityHealth(client, health+15);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}

stock int FindTeleOwner(int client)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
		return -1;

	int teleporter = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	char classname[32];
	if(IsValidEntity(teleporter) && GetEntityClassname(teleporter, classname, sizeof(classname)) && !strcmp(classname, "obj_teleporter", false))
	{
		int owner = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
		if(IsValidClient(owner, false))
			return owner;
	}
	return -1;
}

stock bool TF2_IsPlayerCritBuffed(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, view_as<TFCond>(34)) || TF2_IsPlayerInCondition(client, view_as<TFCond>(35)) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph));
}

public Action Timer_DisguiseBackstab(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(IsValidClient(client, false))
		RandomlyDisguise(client);

	return Plugin_Continue;
}

stock void AssignTeam(int client, int team)
{
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))  //Living spectator check: 0 means that no class is selected
	{
		FF2Dbg("%N does not have a desired class", client);
		if(IsBoss(client))
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", KvGetNum(BossKV[Special[Boss[client]]], "class", 1));  //So we assign one to prevent living spectators
		}
		else
		{
			FF2Dbg("%N was not a boss and did not have a desired class", client);
		}
	}

	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);

	if(GetEntProp(client, Prop_Send, "m_iObserverMode") && IsPlayerAlive(client))  //Welp
	{
		FF2Dbg("%N is a living spectator", client);
		if(IsBoss(client))
		{
			TF2_SetPlayerClass(client, view_as<TFClassType>(KvGetNum(BossKV[Special[Boss[client]]], "class", 1)));
		}
		else
		{
			FF2Dbg("Additional information: %N was not a boss", client);
			TF2_SetPlayerClass(client, TFClass_Heavy);
		}
		TF2_RespawnPlayer(client);
	}
}

stock void RandomlyDisguise(int client)	//Original code was mecha's, but the original code is broken and this uses a better method now.
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int disguiseTarget = -1;
		int team = GetClientTeam(client);

		Handle disguiseArray = CreateArray();
		for(int clientcheck; clientcheck<=MaxClients; clientcheck++)
		{
			if(IsValidClient(clientcheck) && GetClientTeam(clientcheck)==team && clientcheck!=client)
				PushArrayCell(disguiseArray, clientcheck);
		}

		if(GetArraySize(disguiseArray) <= 0)
		{
			disguiseTarget = client;
		}
		else
		{
			disguiseTarget = GetArrayCell(disguiseArray, GetRandomInt(0, GetArraySize(disguiseArray)-1));
			if(!IsValidClient(disguiseTarget))
				disguiseTarget=client;
		}

		int class = GetRandomInt(0, 4);
		TFClassType classArray[] = {TFClass_Scout, TFClass_Pyro, TFClass_Medic, TFClass_Engineer, TFClass_Sniper};
		CloseHandle(disguiseArray);

		if(TF2_GetPlayerClass(client)==TFClass_Spy)
		{
			TF2_DisguisePlayer(client, view_as<TFTeam>(team), classArray[class], disguiseTarget);
		}
		else
		{
			TF2_AddCondition(client, TFCond_Disguised, -1.0);
			SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
			SetEntProp(client, Prop_Send, "m_nDisguiseClass", classArray[class]);
			SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguiseTarget);
			SetEntProp(client, Prop_Send, "m_iDisguiseHealth", 200);
		}
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if(IsBoss(client) && CheckRoundState()==1 && !TF2_IsPlayerCritBuffed(client) && !randomCrits[client])
	{
		result = false;
		return Plugin_Changed;
	}

	if(Enabled && !IsBoss(client) && CheckRoundState()==1 && IsValidEntity(weapon) && SniperClimbDelay!=0)
	{
		if(!StrContains(weaponname, "tf_weapon_club"))
			SickleClimbWalls(client, weapon);
	}
	return Plugin_Continue;
}

public int SickleClimbWalls(int client, int weapon)	 //Credit to Mecha the Slag
{
	if(!IsValidClient(client) || (GetClientHealth(client)<=SniperClimbDamage))
		return;

	char classname[64];
	float vecClientEyePos[3];
	float vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);   // Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng);	   // Get the angle the player is looking

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if(!TR_DidHit(INVALID_HANDLE))
		return;

	int TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
	GetEdictClassname(TRIndex, classname, sizeof(classname));
	if(!StrEqual(classname, "worldspawn"))
		return;

	float fNormal[3];
	TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
	GetVectorAngles(fNormal, fNormal);

	if(fNormal[0]>=30.0 && fNormal[0]<=330.0)
		return;
	if(fNormal[0] <= -30.0)
		return;

	float pos[3];
	TR_GetEndPosition(pos);
	float distance = GetVectorDistance(vecClientEyePos, pos);

	if(distance >= 100.0)
		return;

	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

	fVelocity[2] = 600.0;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);

	SDKHooks_TakeDamage(client, client, client, SniperClimbDamage, DMG_CLUB, 0);

	if(!IsBoss(client))
		ClientCommand(client, "playgamesound \"%s\"", "player\\taunt_clip_spin.wav");

	RequestFrame(Timer_NoAttacking, EntIndexToEntRef(weapon));
}

stock int SetNextAttack(int weapon, float duration=0.0)
{
	if(weapon <= MaxClients)
		return;

	if(!IsValidEntity(weapon))
		return;

	float next = GetGameTime() + duration;
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", next);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", next);
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return (entity != data);
}

public void Timer_NoAttacking(any ref)
{
	int weapon = EntRefToEntIndex(ref);
	SetNextAttack(weapon, SniperClimbDelay);
}

stock int GetClientWithMostQueuePoints(bool[] omit, int enemyTeam=4, bool ignorePrefs=true)
{
	int winner;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && (!Enabled3 || (CanBossVs[client]<2 && CanBossTeam[client]!=enemyTeam) || !ignorePrefs) && QueuePoints[client]>=QueuePoints[winner] && !omit[client])
		{
			if(GetConVarBool(cvarToggleBoss) && view_as<int>(ToggleBoss[client])>1)	// Skip clients who have disabled being able to be a boss
				continue;

			if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				winner=client;
		}
	}

	if(!winner)	// Ignore the boss toggle pref if we can't find available clients
	{
		if(!ignorePrefs)
			return -1;

		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && (!Enabled3 || (CanBossVs[client]<2 && CanBossTeam[client]!=enemyTeam)) && !omit[client])
			{
				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
					winner=client;
			}
		}
	}

	if(!winner)	// Ignore players who have a boss who can't play Boss vs Boss
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && !omit[client])
			{
				if(GetConVarBool(cvarToggleBoss) && view_as<int>(ToggleBoss[client])>1)	// Skip clients who have disabled being able to be a boss
					continue;

				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = '\0';
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					winner = client;
				}
			}
		}
	}

	if(!winner)	// Ignore everything!
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && !omit[client])
			{
				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = '\0';
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					winner = client;
				}
			}
		}
	}
	return winner;
}

stock int GetClientWithoutBlacklist(bool[] omit, int enemyTeam=4)
{
	int winner;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && (!Enabled3 || (!CanBossVs[client] && CanBossTeam[client]!=enemyTeam)) && QueuePoints[client]>=QueuePoints[winner] && !omit[client])
		{
			if(GetConVarBool(cvarToggleBoss) && view_as<int>(ToggleBoss[client])>1)	// Skip clients who have disabled being able to be a boss
				continue;

			if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				winner=client;
		}
	}

	if(!winner)	// Ignore the boss toggle pref if we can't find available clients
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && (!Enabled3 || (!CanBossVs[client] && CanBossTeam[client]!=enemyTeam)) && !omit[client])
			{
				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
					winner=client;
			}
		}
	}

	if(!winner)	// Ignore players who have a boss who can't play Boss vs Boss
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && !omit[client])
			{
				if(GetConVarBool(cvarToggleBoss) && view_as<int>(ToggleBoss[client])>1)	// Skip clients who have disabled being able to be a boss
					continue;

				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = '\0';
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					winner = client;
				}
			}
		}
	}

	if(!winner)	// Ignore everything!
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && !omit[client])
			{
				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = '\0';
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					winner = client;
				}
			}
		}
	}
	return winner;
}

stock int GetRandomValidClient(bool[] omit)
{
	int companion;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !omit[client] && (QueuePoints[client]>=QueuePoints[companion] || (GetConVarBool(cvarDuoRandom) && GetRandomInt(0, RoundToCeil(MaxClients/5.0))==0)))
		{
			if(GetConVarBool(cvarDuoBoss) && view_as<int>(ToggleDuo[client])>1)	// Skip clients who have disabled being able to be selected as a companion
				continue;

			if(GetConVarBool(cvarToggleBoss) && view_as<int>(ToggleBoss[client])>1)	// Skip clients who have disabled being able to be a boss
				continue;

			if((SpecForceBoss && !GetConVarBool(cvarDuoRandom)) || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				companion=client;
		}
	}

	if(!companion)	// Ignore the companion toggle pref if we can't find available clients
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && !omit[client] && (QueuePoints[client]>=QueuePoints[companion] || (GetConVarBool(cvarDuoRandom) && GetRandomInt(0, RoundToCeil(MaxClients/5.0))==0)))
			{
				if(GetConVarBool(cvarToggleBoss) && view_as<int>(ToggleBoss[client])>1) // Skip clients who have disabled being able to be a boss
					continue;

				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
					companion=client;
			}
		}
	}

	if(!companion)	// Ignore the boss toggle pref if we can't find available clients
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && !omit[client] && (QueuePoints[client]>=QueuePoints[companion] || (GetConVarBool(cvarDuoRandom) && GetRandomInt(0, RoundToCeil(MaxClients/5.0))==0)))
			{
				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
					companion=client;
			}
		}
	}
	return companion;
}

stock int LastBossIndex()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(!Boss[client])
			return client-1;
	}
	return 0;
}

stock int GetBossIndex(int client)
{
	if(client>0 && client<=MaxClients)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss] == client)
				return boss;
		}
	}
	return -1;
}

stock int Operate(Handle sumArray, int &bracket, float value, Handle _operator)
{
	float sum = GetArrayCell(sumArray, bracket);
	switch(GetArrayCell(_operator, bracket))
	{
		case Operator_Add:
		{
			SetArrayCell(sumArray, bracket, sum+value);
		}
		case Operator_Subtract:
		{
			SetArrayCell(sumArray, bracket, sum-value);
		}
		case Operator_Multiply:
		{
			SetArrayCell(sumArray, bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				LogToFile(eLog, "[Boss] Detected a divide by 0!");
				bracket = 0;
				return;
			}
			SetArrayCell(sumArray, bracket, sum/value);
		}
		case Operator_Exponent:
		{
			SetArrayCell(sumArray, bracket, Pow(sum, value));
		}
		default:
		{
			SetArrayCell(sumArray, bracket, value);  //This means we're dealing with a constant
		}
	}
	SetArrayCell(_operator, bracket, Operator_None);
}

stock void OperateString(Handle sumArray, int &bracket, char[] value, int size, Handle _operator)
{
	if(!StrEqual(value, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

stock int ParseFormula(int boss, const char[] key, const char[] defaultFormula, int defaultValue)
{
	char formula[1024], bossName[64];
	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], "filename", bossName, sizeof(bossName));
	KvGetString(BossKV[Special[boss]], key, formula, sizeof(formula), defaultFormula);

	float players = 1.0;
	if(Enabled3)
	{
		if(BossSwitched[boss])
		{
			players += bosses + playingboss - playingmerc*0.45;
		}
		else
		{
			players += bosses + playingmerc - playingboss*0.45;
		}
	}
	else
	{
		players += playing;
	}

	int size = 1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i] == '(')
		{
			if(!matchingBrackets)
			{
				size++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(formula[i] == ')')
		{
			matchingBrackets++;
		}
	}

	Handle sumArray = CreateArray(_, size), _operator=CreateArray(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	SetArrayCell(sumArray, 0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	SetArrayCell(_operator, bracket, Operator_None);

	char character[2], value[16];  //We don't decl value because we directly append characters to it and there's no point in decl'ing character
	for(int i; i<=strlen(formula); i++)
	{
		character[0] = formula[i];  //Find out what the next char in the formula is
		switch(character[0])
		{
			case ' ', '\t':  //Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				bracket++;  //We've just entered a new parentheses so increment the bracket value
				SetArrayCell(sumArray, bracket, 0.0);
				SetArrayCell(_operator, bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(GetArrayCell(_operator, bracket) != Operator_None)  //Something like (5*)
				{
					LogToFile(eLog, "[Boss] %s's %s formula has an invalid operator at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogToFile(eLog, "[Boss] %s's %s formula has an unbalanced parentheses at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				Operate(sumArray, bracket, GetArrayCell(sumArray, bracket+1), _operator);
			}
			case '\0':  //End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);  //Constant?  Just add it to the current value
			}
			case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, players, _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
				{
					case '+':
					{
						SetArrayCell(_operator, bracket, Operator_Add);
					}
					case '-':
					{
						SetArrayCell(_operator, bracket, Operator_Subtract);
					}
					case '*':
					{
						SetArrayCell(_operator, bracket, Operator_Multiply);
					}
					case '/':
					{
						SetArrayCell(_operator, bracket, Operator_Divide);
					}
					case '^':
					{
						SetArrayCell(_operator, bracket, Operator_Exponent);
					}
				}
			}
		}
	}

	float result = GetArrayCell(sumArray, 0);
	CloseHandle(sumArray);
	CloseHandle(_operator);

	float addition = GetConVarFloat(cvarTimesTen);
	if(result <= 0)
	{
		LogToFile(eLog, "[Boss] %s has an invalid %s, using default!", bossName, key);
		if(TimesTen && addition!=1 && addition>0)
			return RoundFloat(defaultValue*addition);

		return defaultValue;
	}

	if(TimesTen && addition!=1 && addition>0)
	{
		result *= addition;
	}

	if(StrContains(key, "ragedamage", false))
	{
		if(bMedieval)
			return RoundFloat(result/3.6);  //TODO: Make this configurable
	}
	return RoundFloat(result);
}

stock int GetAbilityArgument(int index, const char[] plugin_name, const char[] ability_name, int arg, int defvalue=0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return 0;

	KvRewind(BossKV[Special[index]]);
	char s[10];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(s, 10, "ability%i", i);
		if(KvJumpToKey(BossKV[Special[index]], s))
		{
			char ability_name2[64];
			KvGetString(BossKV[Special[index]], "name", ability_name2, 64);
			if(strcmp(ability_name, ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			char plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name", plugin_name2, 64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name, plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s, 10, "arg%i", arg);
			return KvGetNum(BossKV[Special[index]], s, defvalue);
		}
	}
	return 0;
}

stock float GetAbilityArgumentFloat(int index, const char[] plugin_name, const char[] ability_name, int arg, float defvalue=0.0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return 0.0;

	KvRewind(BossKV[Special[index]]);
	char s[10];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(s, 10, "ability%i", i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			char ability_name2[64];
			KvGetString(BossKV[Special[index]], "name", ability_name2, 64);
			if(strcmp(ability_name, ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			char plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name", plugin_name2, 64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name, plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s, 10, "arg%i", arg);
			float see = KvGetFloat(BossKV[Special[index]], s, defvalue);
			return see;
		}
	}
	return 0.0;
}

stock int GetAbilityArgumentString(int index, const char[] plugin_name, const char[] ability_name, int arg, char[] buffer, int buflen, const char[] defvalue="")
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
	{
		strcopy(buffer, buflen, "");
		return;
	}
	KvRewind(BossKV[Special[index]]);
	char s[10];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(s, 10, "ability%i", i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			char ability_name2[64];
			KvGetString(BossKV[Special[index]], "name", ability_name2, 64);
			if(strcmp(ability_name, ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			char plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name", plugin_name2, 64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name, plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s, 10, "arg%i", arg);
			KvGetString(BossKV[Special[index]], s, buffer, buflen, defvalue);
		}
	}
}

stock bool RandomSound(const char[] sound, char[] file, int length, int boss=0)
{
	if(boss<0 || Special[boss]<0 || !BossKV[Special[boss]])
		return false;

	KvRewind(BossKV[Special[boss]]);
	if(!KvJumpToKey(BossKV[Special[boss]], sound))
	{
		KvRewind(BossKV[Special[boss]]);
		return false;  //Requested sound not implemented for this boss
	}

	char key[4];
	int sounds;
	while(++sounds)  //Just keep looping until there's no keys left
	{
		IntToString(sounds, key, sizeof(key));
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
		{
			sounds--;  //This sound wasn't valid, so don't include it
			break;  //Assume that there's no more sounds
		}
	}

	if(!sounds)
		return false;  //Found sound, but no sounds inside of it

	IntToString(GetRandomInt(1, sounds), key, sizeof(key));
	KvGetString(BossKV[Special[boss]], key, file, length);  //Populate file
	return true;
}

stock bool RandomSoundAbility(const char[] sound, char[] file, int length, int boss=0, int slot=0)
{
	if(boss<0 || Special[boss]<0 || !BossKV[Special[boss]])
		return false;

	KvRewind(BossKV[Special[boss]]);
	if(!KvJumpToKey(BossKV[Special[boss]], sound))
		return false;  //Sound doesn't exist

	char key[10];
	int sounds, matches, match[MAXRANDOMS];
	while(++sounds)
	{
		IntToString(sounds, key, 4);
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
			break;  //Assume that there's no more sounds

		Format(key, sizeof(key), "slot%i", sounds);
		if(KvGetNum(BossKV[Special[boss]], key, 0)==slot)
		{
			match[matches] = sounds;  //Found a match: let's store it in the array
			matches++;
		}
	}

	if(!matches)
		return false;  //Found sound, but no sounds inside of it

	IntToString(match[GetRandomInt(0, matches-1)], key, 4);
	KvGetString(BossKV[Special[boss]], key, file, length);  //Populate file
	return true;
}

stock bool RandomSoundVo(const char[] sound, char[] file, int length, int boss=0, const char[] oldFile)
{
	if(boss<0 || Special[boss]<0 || !BossKV[Special[boss]])
		return false;

	KvRewind(BossKV[Special[boss]]);
	if(!KvJumpToKey(BossKV[Special[boss]], sound))
		return false;  //Sound doesn't exist

	char key[10], replacement[PLATFORM_MAX_PATH];
	int sounds, matches, match[MAXRANDOMS];
	while(++sounds)
	{
		IntToString(sounds, key, 4);
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
			break;  //Assume that there's no more sounds

		Format(key, sizeof(key), "vo%i", sounds);
		KvGetString(BossKV[Special[boss]], key, replacement, sizeof(replacement));
		if(StrEqual(replacement, oldFile, false))
		{
			match[matches] = sounds;  //Found a match: let's store it in the array
			matches++;
		}
	}

	if(!matches)
		return false;  //Found sound, but no sounds inside of it

	IntToString(match[GetRandomInt(0, matches-1)], key, 4);
	KvGetString(BossKV[Special[boss]], key, file, length);  //Populate file
	return true;
}

void ForceTeamWin(int team)
{
	char temp[PLATFORM_MAX_PATH];
	GetCurrentMap(temp, sizeof(temp));
	if(!strlen(temp))
		return;

	int entity = FindEntityByClassname2(-1, "team_control_point_master");
	if(!IsValidEntity(entity))
	{
		entity = CreateEntityByName("team_control_point_master");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(entity, "SetWinner");
}

public bool PickCharacter(int boss, int companion)
{
	if(boss == companion)
	{
		Special[boss] = Incoming[boss];
		Incoming[boss] = -1;
		if(Special[boss] != -1)  //We've already picked a boss through Command_SetNextBoss
		{
			Action action;
			Call_StartForward(OnSpecialSelected);
			Call_PushCell(boss);
			int characterIndex = Special[boss];
			Call_PushCellRef(characterIndex);
			char newName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", newName, sizeof(newName));
			Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(true);  //Preset
			Call_Finish(action);
			if(action == Plugin_Changed)
			{
				if(newName[0])
				{
					char characterName[64];
					int foundExactMatch=-1, foundPartialMatch=-1;
					for(int character; BossKV[character] && character<MAXSPECIALS; character++)
					{
						KvRewind(BossKV[character]);
						KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch=character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false)!=-1)
						{
							foundPartialMatch=character;
						}

						//Do the same thing as above here, but look at the filename instead of the boss name
						KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch=character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false)!=-1)
						{
							foundPartialMatch=character;
						}
					}

					if(foundExactMatch!=-1)
					{
						Special[boss]=foundExactMatch;
					}
					else if(foundPartialMatch!=-1)
					{
						Special[boss]=foundPartialMatch;
					}
					else
					{
						return false;
					}
					PrecacheCharacter(Special[boss]);
					return true;
				}
				Special[boss]=characterIndex;
				PrecacheCharacter(Special[boss]);
				return true;
			}
			/*else
			{
				int client = Boss[boss];
				if(xIncoming[client][0])
				{
					char characterName[64];
					int foundExactMatch=-1, foundPartialMatch=-1;
					for(int character; BossKV[character] && character<MAXSPECIALS; character++)
					{
						KvRewind(BossKV[character]);
						KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
						if(StrEqual(xIncoming[client], characterName, false))
						{
							foundExactMatch=character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(xIncoming[client], characterName, false)!=-1)
						{
							foundPartialMatch=character;
						}

						//Do the same thing as above here, but look at the filename instead of the boss name
						KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
						if(StrEqual(xIncoming[client], characterName, false))
						{
							foundExactMatch=character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(xIncoming[client], characterName, false)!=-1)
						{
							foundPartialMatch=character;
						}
					}

					if(foundExactMatch!=-1)
					{
						Special[boss]=foundExactMatch;
					}
					else if(foundPartialMatch!=-1)
					{
						Special[boss]=foundPartialMatch;
					}
					else
					{
						return false;
					}
					PrecacheCharacter(Special[boss]);
					return true;
				}
				Special[boss]=characterIndex;
				PrecacheCharacter(Special[boss]);
				return true;
			}*/
			PrecacheCharacter(Special[boss]);
			return true;
		}

		for(int tries; tries<100; tries++)
		{
			if(ChancesString[0])
			{
				int characterIndex=chancesIndex;  //Don't touch chancesIndex since it doesn't get reset
				int i=GetRandomInt(0, chances[characterIndex-1]);

				while(characterIndex>=2 && i<chances[characterIndex-1])
				{
					Special[boss]=chances[characterIndex-2]-1;
					characterIndex-=2;
				}
			}
			else
			{
				Special[boss]=GetRandomInt(0, Specials-1);
			}

			char companionName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName));
			if(KvGetNum(BossKV[Special[boss]], "blocked") ||
			   KvGetNum(BossKV[Special[boss]], "donator") ||
			   KvGetNum(BossKV[Special[boss]], "admin") ||
			   KvGetNum(BossKV[Special[boss]], "owner") ||
			   KvGetNum(BossKV[Special[boss]], "theme") ||
			  (KvGetNum(BossKV[Special[boss]], "nofirst") && RoundCount<=arenaRounds) ||
			  (strlen(companionName) && !DuoMin) ||
			  (Enabled3 && (KvGetNum(BossKV[Special[boss]], "noversus")==2 ||
			  (KvGetNum(BossKV[Special[boss]], "noversus")==1 && BossSwitched[boss]) ||
			  (KvGetNum(BossKV[Special[boss]], "bossteam")==BossTeam && BossSwitched[boss]) ||
			  (KvGetNum(BossKV[Special[boss]], "bossteam")==OtherTeam && !BossSwitched[boss]))))
			{
				Special[boss]=-1;
				continue;
			}
			break;
		}
	}
	else
	{
		char bossName[64], companionName[64];
		KvRewind(BossKV[Special[boss]]);
		KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName), "=Failed companion name=");

		int character;
		while(character<Specials)  //Loop through all the bosses to find the companion we're looking for
		{
			KvRewind(BossKV[character]);
			KvGetString(BossKV[character], "name", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				Special[companion]=character;
				break;
			}

			KvGetString(BossKV[character], "filename", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				Special[companion]=character;
				break;
			}
			character++;
		}

		if(character==Specials)  //Companion not found
			return false;
	}

	//All of the following uses `companion` because it will always be the boss index we want
	Action action;
	Call_StartForward(OnSpecialSelected);
	Call_PushCell(companion);
	int characterIndex=Special[companion];
	Call_PushCellRef(characterIndex);
	char newName[64];
	KvRewind(BossKV[Special[companion]]);
	KvGetString(BossKV[Special[companion]], "name", newName, sizeof(newName));
	Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(false);  //Not preset
	Call_Finish(action);
	if(action==Plugin_Changed)
	{
		if(newName[0])
		{
			char characterName[64];
			int foundExactMatch=-1, foundPartialMatch=-1;
			for(int character; BossKV[character] && character<MAXSPECIALS; character++)
			{
				KvRewind(BossKV[character]);
				KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch=character;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch=character;
				}

				//Do the same thing as above here, but look at the filename instead of the boss name
				KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch=character;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch=character;
				}
			}

			if(foundExactMatch!=-1)
			{
				Special[companion]=foundExactMatch;
			}
			else if(foundPartialMatch!=-1)
			{
				Special[companion]=foundPartialMatch;
			}
			else
			{
				return false;
			}
			PrecacheCharacter(Special[companion]);
			return true;
		}
		Special[companion]=characterIndex;
		PrecacheCharacter(Special[companion]);
		return true;
	}
	PrecacheCharacter(Special[companion]);
	return true;
}

void FindCompanion(int boss, int players, bool[] omit)
{
	static int playersNeeded=2;
	char companionName[64];
	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName));
	if(playersNeeded<players && strlen(companionName))  //Only continue if we have enough players and if the boss has a companion
	{
		int companion=GetRandomValidClient(omit);
		Boss[companion]=companion;
		BossSwitched[companion]=BossSwitched[boss];
		omit[companion]=true;
		int client=Boss[boss];
		if(PickCharacter(boss, companion))  //TODO: This is a bit misleading
		{
			if(BossRageDamage[companion]==1)	// If 1, toggle infinite rage
			{
				InfiniteRageActive[client]=true;
				CreateTimer(0.2, Timer_InfiniteRage, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				BossRageDamage[companion]=1;
			}
			else if(BossRageDamage[companion]==-1)	// If -1, never rage
			{
				BossRageDamage[companion]=99999;
			}
			else	// Use formula or straight value
			{
				BossRageDamage[companion]=ParseFormula(companion, "ragedamage", "1900", 1900);
			}
			BossLivesMax[companion]=KvGetNum(BossKV[Special[companion]], "lives", 1);
			if(BossLivesMax[companion]<=0)
			{
				LogToFile(eLog, "[Boss] Boss %s has an invalid amount of lives, setting to 1", companionName);
				BossLivesMax[companion]=1;
			}
			playersNeeded++;
			FindCompanion(companion, players, omit);  //Make sure this companion doesn't have a companion of their own
		}
	}
	playersNeeded=2;  //Reset the amount of players needed back after we're done
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, char[] att)
{
	Handle hWeapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon==INVALID_HANDLE)
		return -1;

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count=ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
		--count;

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib = StringToInt(atts[i]);
			if(!attrib)
			{
				LogToFile(eLog, "[Boss] Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				CloseHandle(hWeapon);
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	int entity=TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

public int HintPanelH(Handle menu, MenuAction action, int client, int selection)
{
	if(IsValidClient(client) && (action==MenuAction_Select || (action==MenuAction_Cancel && selection==MenuCancel_Exit)))
		FF2flags[client]|=FF2FLAG_CLASSHELPED;

	return;
}

public int QueuePanelH(Handle menu, MenuAction action, int client, int selection)
{
	if(action==MenuAction_Select && selection==10)
		TurnToZeroPanel(client, client);

	return false;
}

public Action QueuePanelCmd(int client, int args)
{
	char text[64];
	int items;
	bool[] added = new bool[MaxClients+1];

	Handle panel = CreatePanel();
	Format(text, sizeof(text), "%T", "thequeue", client);  //"Boss Queue"
	SetPanelTitle(panel, text);
	for(int boss; boss<=MaxClients; boss++)  //Add the current bosses to the top of the list
	{
		if(IsBoss(boss))
		{
			added[boss] = true;  //Don't want the bosses to show up again in the actual queue list
			Format(text, sizeof(text), "%N-%i", boss, QueuePoints[boss]);
			DrawPanelItem(panel, text);
			items++;
		}
	}

	DrawPanelText(panel, "---");
	do
	{
		int target = GetClientWithMostQueuePoints(added, _, false);  //Get whoever has the highest queue points out of those who haven't been listed yet
		if(!IsValidClient(target))  //When there's no players left, fill up the rest of the list with blank lines
		{
			DrawPanelItem(panel, "");
			items++;
			continue;
		}

		Format(text, sizeof(text), "%N-%i", target, QueuePoints[target]);
		if(client != target)
		{
			DrawPanelItem(panel, text);
			items++;
		}
		else
		{
			DrawPanelText(panel, text);  //DrawPanelText() is white, which allows the client's points to stand out
		}
		added[target]=true;
	}
	while(items < 9);

	Format(text, sizeof(text), "%T (%T)", "your_points", client, QueuePoints[client], "to0", client);  //"Your queue point(s) is {1} (set to 0)"
	DrawPanelItem(panel, text);

	SendPanelToClient(panel, client, QueuePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action ResetQueuePointsCmd(int client, int args)
{
	if(client && !args)  //Normal players
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(!client)  //No confirmation for console
	{
		TurnToZeroPanelH(INVALID_HANDLE, MenuAction_Select, client, 1);
		return Plugin_Handled;
	}

	AdminId admin=GetUserAdmin(client);	 //Normal players
	if((admin==INVALID_ADMIN_ID) || !GetAdminFlag(admin, Admin_Cheats))
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(args!=1)  //Admins
	{
		FReplyToCommand(client, "Usage: ff2_resetqueuepoints <target>");
		return Plugin_Handled;
	}

	char pattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof(pattern));
	char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, 1, 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches>1)
	{
		for(int target; target<matches; target++)
		{
			TurnToZeroPanel(client, targets[target]);  //FIXME:  This can only handle one client currently and doesn't iterate through all clients
		}
	}
	else
	{
		TurnToZeroPanel(client, targets[0]);
	}
	return Plugin_Handled;
}

public int TurnToZeroPanelH(Handle menu, MenuAction action, int client, int position)
{
	if(action==MenuAction_Select && position==1)
	{
		if(shortname[client]==client)
		{
			FPrintToChat(client, "%t", "to0_done");  //Your queue points have been reset to {olive}0{default}
		}
		else
		{
			FPrintToChat(client, "%t", "to0_done_admin", shortname[client]);  //{olive}{1}{default}'s queue points have been reset to {olive}0{default}
			FPrintToChat(shortname[client], "%t", "to0_done_by_admin", client);  //{olive}{1}{default} reset your queue points to {olive}0{default}
			LogAction(client, shortname[client], "\"%L\" reset \"%L\"'s queue points to 0", client, shortname[client]);
		}
		QueuePoints[shortname[client]] = 0;
	}
}

public Action TurnToZeroPanel(int client, int target)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(QueuePoints[client]<0 && client==target)
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Continue;
	}

	Handle panel=CreatePanel();
	char text[128];
	if(client==target)
	{
		Format(text, sizeof(text), "%T", "to0_title", client);  //Do you really want to set your queue points to 0?
	}
	else
	{
		Format(text, sizeof(text), "%T", "to0_title_admin", client, target);  //Do you really want to set {1}'s queue points to 0?
	}

	PrintToChat(client, text);
	SetPanelTitle(panel, text);
	Format(text, sizeof(text), "%T", "Yes", client);
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%T", "No", client);
	DrawPanelItem(panel, text);
	shortname[client]=target;
	SendPanelToClient(panel, client, TurnToZeroPanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

stock bool IsBoss(int client)
{
	if(IsValidClient(client) && Enabled)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss]==client)
				return true;
		}
	}
	return false;
}

void DoOverlay(int client, const char[] overlay)
{
	int flags=GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	if(overlay[0]=='\0')
	{
		ClientCommand(client, "r_screenoverlay off");
	}
	else
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	}
	SetCommandFlags("r_screenoverlay", flags);
}

public int FF2PanelH(Handle menu, MenuAction action, int client, int selection)
{
	if(action==MenuAction_Select)
	{
		switch(selection)
		{
			case 1:
				Command_GetHPCmd(client, 0);

			case 2:
				Command_SetMyBoss(client, 0);

			case 3:
				Command_HelpPanelClass(client, 0);

			case 4:
				NewPanelCmd(client, 0);

			case 5:
				QueuePanelCmd(client, 0);

			case 6:
				MusicTogglePanelCmd(client, 0);

			case 7:
				VoiceTogglePanelCmd(client, 0);

			case 8:
				HelpPanel3Cmd(client, 0);

			default:
				return;
		}
	}
}

public Action FF2Panel(int client, int args)  //._.
{
	if(!IsValidClient(client, false))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	Handle panel=CreatePanel();
	char text[256];
	SetGlobalTransTarget(client);
	Format(text, sizeof(text), "%t", "menu_1");  //What's up?
	SetPanelTitle(panel, text);
	Format(text, sizeof(text), "%t", "menu_2");  //Investigate the boss's current health level (/ff2hp)
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "menu_3");  //Boss Preferences (/ff2boss)
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "menu_7");  //Changes to my class in FF2 (/ff2classinfo)
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "menu_4");  //What's new? (/ff2new).
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "menu_5");  //Queue points
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "menu_8");  //Toggle music (/ff2music)
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "menu_9");  //Toggle monologues (/ff2voice)
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "menu_9a");  //Toggle info about changes of classes in FF2
	DrawPanelItem(panel, text);
	Format(text, sizeof(text), "%t", "menu_6");  //Exit
	DrawPanelItem(panel, text);
	SendPanelToClient(panel, client, FF2PanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public int NewPanelH(Handle menu, MenuAction action, int param1, int param2)
{
	if(action==MenuAction_Select)
	{
		switch(param2)
		{
			case 1:
			{
				if(curHelp[param1]<=0)
				{
					NewPanel(param1, 0);
				}
				else
				{
					NewPanel(param1, --curHelp[param1]);
				}
			}
			case 2:
			{
				if(curHelp[param1]>=maxVersion)
				{
					NewPanel(param1, maxVersion);
				}
				else
				{
					NewPanel(param1, ++curHelp[param1]);
				}
			}
			default:
			{
				return;
			}
		}
	}
}

public Action NewPanelCmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	NewPanel(client, maxVersion);
	return Plugin_Handled;
}

public Action NewPanel(int client, int versionIndex)
{
	curHelp[client]=versionIndex;
	Handle panel=CreatePanel();
	char whatsNew[90];

	SetGlobalTransTarget(client);
	Format(whatsNew, 90, "=%t:=", "whatsnew", ff2versiontitles[versionIndex], ff2versiondates[versionIndex]);
	SetPanelTitle(panel, whatsNew);
	FindVersionData(panel, versionIndex);
	if(versionIndex>0)
	{
		Format(whatsNew, 90, "%t", "older");
	}
	else
	{
		Format(whatsNew, 90, "%t", "noolder");
	}

	DrawPanelItem(panel, whatsNew);
	if(versionIndex<maxVersion)
	{
		Format(whatsNew, 90, "%t", "newer");
	}
	else
	{
		Format(whatsNew, 90, "%t", "nonewer");
	}

	DrawPanelItem(panel, whatsNew);
	Format(whatsNew, 512, "%T", "menu_6", client);
	DrawPanelItem(panel, whatsNew);
	SendPanelToClient(panel, client, NewPanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Continue;
}

public Action HelpPanel3Cmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!GetConVarBool(cvarAdvancedMusic))
	{
		HelpPanel3(client);
	}
	else
	{
		ToggleClassInfo(client);
	}

	return Plugin_Handled;
}

public Action HelpPanel3(int client)
{
	Handle panel=CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 class info...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, ClassInfoTogglePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public int ClassInfoTogglePanelH(Handle menu, MenuAction action, int client, int selection)
{
	if(IsValidClient(client))
	{
		if(action==MenuAction_Select)
		{
			if(selection==2)
			{
				ToggleInfo[client] = false;
			}
			else
			{
				ToggleInfo[client] = true;
			}
			FPrintToChat(client, "%t", "ff2_classinfo", selection==2 ? "off" : "on");	// TODO: Make this more multi-language friendly
		}
	}
}

void ToggleClassInfo(int client)
{
	if(ToggleInfo[client])
	{
		ToggleInfo[client] = false;
	}
	else
	{
		ToggleInfo[client] = true;
	}
	FPrintToChat(client, "%t", "ff2_classinfo", ToggleInfo[client] ? "on" : "off");	// TODO: Make this more multi-language friendly
}

public Action Command_HelpPanelClass(int client, int args)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!Enabled2)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	HelpPanelClass(client);
	return Plugin_Handled;
}

public Action HelpPanelClass(int client)
{
	if(!Enabled)
		return Plugin_Continue;

	int boss=GetBossIndex(client);
	if(boss!=-1)
	{
		HelpPanelBoss(boss);
		return Plugin_Continue;
	}

	char text[512];
	TFClassType class=TF2_GetPlayerClass(client);
	SetGlobalTransTarget(client);
	switch(class)
	{
		case TFClass_Scout:
			Format(text, sizeof(text), "%T", "help_scout", client);

		case TFClass_Soldier:
			Format(text, sizeof(text), "%T", "help_soldier", client);

		case TFClass_Pyro:
			Format(text, sizeof(text), "%T", "help_pyro", client);

		case TFClass_DemoMan:
			Format(text, sizeof(text), "%T", "help_demo", client);

		case TFClass_Heavy:
			Format(text, sizeof(text), "%T", "help_heavy", client);

		case TFClass_Engineer:
			Format(text, sizeof(text), "%T", "help_eggineer", client);

		case TFClass_Medic:
			Format(text, sizeof(text), "%T", "help_medic", client);

		case TFClass_Sniper:
			Format(text, sizeof(text), "%T", "help_sniper", client);

		case TFClass_Spy:
			Format(text, sizeof(text), "%T", "help_spie", client);

		default:
			Format(text, sizeof(text), "");
	}

	Format(text, sizeof(text), "%T\n%s", "help_melee", client, text);
	Handle panel=CreatePanel();
	SetPanelTitle(panel, text);
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, HintPanelH, 20);
	CloseHandle(panel);
	return Plugin_Continue;
}

void HelpPanelBoss(int boss)
{
	if(!IsValidClient(Boss[boss]))
		return;

	char text[512], language[20];
	GetLanguageInfo(GetClientLanguage(Boss[boss]), language, 8, text, 8);
	Format(language, sizeof(language), "description_%s", language);

	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], language, text, sizeof(text));
	if(!text[0])
	{
		KvGetString(BossKV[Special[boss]], "description_en", text, sizeof(text));  //Default to English if their language isn't available
		if(!text[0])
			return;
	}
	ReplaceString(text, sizeof(text), "\\n", "\n");

	Handle panel=CreatePanel();
	SetPanelTitle(panel, text);
	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, Boss[boss], HintPanelH, 20);
	CloseHandle(panel);
}

public Action MusicTogglePanelCmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(args)
	{
		char cmd[64];
		GetCmdArgString(cmd, sizeof(cmd));
		if(StrContains(cmd, "off", false)!=-1 || StrContains(cmd, "disable", false)!=-1 || StrContains(cmd, "0", false)!=-1)
		{
			ToggleBGM(client, false);
		}
		else if(StrContains(cmd, "on", false)!=-1 || StrContains(cmd, "enable", false)!=-1 || StrContains(cmd, "1", false)!=-1)
		{
			if(ToggleMusic[client])
			{
				FReplyToCommand(client, "You already have boss themes enabled...");
				return Plugin_Handled;
			}
			ToggleBGM(client, true);
		}
		FPrintToChat(client, "%t", "ff2_music", ToggleMusic[client] ? "on" : "off");	// TODO: Make this more multi-language friendly
		return Plugin_Handled;
	}

	MusicTogglePanel(client);
	return Plugin_Handled;
}

public Action MusicTogglePanel(int client)
{
	if(!GetConVarBool(cvarAdvancedMusic))
	{
		Handle panel=CreatePanel();
		SetPanelTitle(panel, "Turn the Freak Fortress 2 music...");
		DrawPanelItem(panel, "On");
		DrawPanelItem(panel, "Off");
		SendPanelToClient(panel, client, MusicTogglePanelH, MENU_TIME_FOREVER);
		CloseHandle(panel);
	}
	else
	{
		char title[128];
		Handle togglemusic = CreateMenu(MusicTogglePanelH);
		SetGlobalTransTarget(client);
		Format(title, sizeof(title), "%t", "theme_menu");
		SetMenuTitle(togglemusic, title, title);
		if(ToggleMusic[client])
		{
			Format(title, sizeof(title), "%t", "themes_disable");
			AddMenuItem(togglemusic, title, title);
			Format(title, sizeof(title), "%t", "theme_skip");
			AddMenuItem(togglemusic, title, title);
			Format(title, sizeof(title), "%t", "theme_shuffle");
			AddMenuItem(togglemusic, title, title);
			if(GetConVarInt(cvarSongInfo)>=0)
			{
				Format(title, sizeof(title), "%t", "theme_select");
				AddMenuItem(togglemusic, title, title);
			}
		}
		else
		{
			Format(title, sizeof(title), "%t", "themes_enable");
			AddMenuItem(togglemusic, title, title);
		}
		SetMenuExitButton(togglemusic, true);
		DisplayMenu(togglemusic, client, MENU_TIME_FOREVER);
	}
	return Plugin_Continue;
}

public int MusicTogglePanelH(Handle menu, MenuAction action, int client, int selection)
{
	if(IsValidClient(client) && action==MenuAction_Select)
	{
		if(!GetConVarBool(cvarAdvancedMusic))
		{
			if(selection==2)  //Off
			{
				ToggleMusic[client] = false;
				StopMusic(client, true);
			}
			else  //On
			{
				//If they already have music enabled don't do anything
				if(!ToggleMusic[client])
				{
					ToggleMusic[client] = true;
					StartMusic(client);
				}
			}
			FPrintToChat(client, "%t", "ff2_music", selection==2 ? "off" : "on");	// TODO: Make this more multi-language friendly
		}
		else
		{
			switch(selection)
			{
				case 0:
				{
					ToggleBGM(client, ToggleMusic[client] ? false : true);
					FPrintToChat(client, "%t", "ff2_music", ToggleVoice[client] ? "on" : "off");	// And here too
				}
				case 1:
				{
					Command_SkipSong(client, 0);
				}
				case 2:
				{
					Command_ShuffleSong(client, 0);
				}
				case 3:
				{
					Command_Tracklist(client, 0);
				}
			}
		}
	}
}

void ToggleBGM(int client, bool enable)
{
	if(enable)
	{
		ToggleMusic[client] = true;
		StartMusic(client);
	}
	else
	{
		ToggleMusic[client] = false;
		StopMusic(client, true);
	}
}

public Action Command_SkipSong(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!GetConVarBool(cvarAdvancedMusic))
		return Plugin_Continue;

	if(!Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(StrEqual(currentBGM[client], "ff2_stop_music", true) || !ToggleMusic[client])
	{
		FReplyToCommand(client, "%t", "ff2_music_disabled");
		return Plugin_Handled;
	}

	if(CheckRoundState()!=1)
	{
		FReplyToCommand(client, "%t", "ff2_please wait");
		return Plugin_Handled;
	}

    	FReplyToCommand(client, "%t", "track_skipped");

	StopMusic(client, true);

	char id3[6][256];
	KvRewind(BossKV[Special[0]]);
	if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH];
		int index;
		do
		{
			index++;
			Format(music, 10, "time%i", index);
		}
		while(KvGetFloat(BossKV[Special[0]], music)>1);

		if(!index)
		{
			FReplyToCommand(client, "%t", "ff2_no_music");
			return Plugin_Handled;
		}

		cursongId[client]++;
		if(cursongId[client]>=index)
			cursongId[client]=1;

		char lives[256];
		Format(lives, sizeof(lives), "life%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
		if(strlen(lives))
		{
			if(StringToInt(lives)!=BossLives[Special[0]])
			{
				for(int i; i<index-1; i++)
				{
					if(StringToInt(lives)!=BossLives[Special[0]])
					{
						cursongId[client]=i;
						continue;
					}
					break;
				}
			}
		}

		Format(music, 10, "time%i", cursongId[client]);
		float time=KvGetFloat(BossKV[Special[0]], music);
		Format(music, 10, "path%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], music, music, sizeof(music));

		Format(id3[0], sizeof(id3[]), "name%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
		Format(id3[1], sizeof(id3[]), "artist%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));

		char temp[PLATFORM_MAX_PATH];
		Format(temp, sizeof(temp), "sound/%s", music);
		if(FileExists(temp, true))
		{
			PlayBGM(client, music, time, _, id3[2], id3[3]);
		}
		else
		{
			char bossName[64];
			KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
			LogToFile(eLog, "[Boss] Character %s is missing BGM file '%s'!", bossName, temp);
			if(MusicTimer[client]!=INVALID_HANDLE)
				KillTimer(MusicTimer[client]);
		}
	}
	return Plugin_Handled;
}

public Action Command_ShuffleSong(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!GetConVarBool(cvarAdvancedMusic))
		return Plugin_Continue;

	if(!Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(StrEqual(currentBGM[client], "ff2_stop_music", true) || !ToggleMusic[client])
	{
		FReplyToCommand(client, "%t", "ff2_music_disabled");
		return Plugin_Handled;
	}

	if(CheckRoundState()!=1)
	{
		FReplyToCommand(client, "%t", "ff2_please wait");
		return Plugin_Handled;
	}

	FReplyToCommand(client, "%t", "track_shuffle");
	StartMusic(client);
	return Plugin_Handled;
}

public Action Command_Tracklist(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!GetConVarBool(cvarAdvancedMusic) || GetConVarInt(cvarSongInfo)<0)
		return Plugin_Continue;

	if(!Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(StrEqual(currentBGM[client], "ff2_stop_music", true) || !ToggleMusic[client])
	{
		FReplyToCommand(client, "%t", "ff2_music_disabled");
		return Plugin_Handled;
	}

	if(CheckRoundState()!=1)
	{
		FReplyToCommand(client, "%t", "ff2_please wait");
		return Plugin_Handled;
	}

	char id3[6][256];
	Handle trackList = CreateMenu(Command_TrackListH);
	SetGlobalTransTarget(client);
	SetMenuTitle(trackList, "%t", "track_select");
	KvRewind(BossKV[Special[0]]);
	if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH];
		int index;
		do
		{
			index++;
			Format(music, 10, "time%i", index);
		}
		while(KvGetFloat(BossKV[Special[0]], music)>1);

		if(!index)
		{
			FReplyToCommand(client, "%t", "ff2_no_music");
			return Plugin_Handled;
		}

		char lives[256];
		for(int trackIdx=1; trackIdx<=index-1; trackIdx++)
		{
			Format(lives, sizeof(lives), "life%i", trackIdx);
			KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
			if(strlen(lives))
			{
				if(StringToInt(lives) != BossLives[Special[0]])
					continue;
			}
			Format(id3[0], sizeof(id3[]), "name%i", trackIdx);
			KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
			Format(id3[1], sizeof(id3[]), "artist%i", trackIdx);
			KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));
			GetSongTime(trackIdx, id3[5], sizeof(id3[]));
			if(!id3[3])
				Format(id3[3], sizeof(id3[]), "%t", "unknown_artist");

			if(!id3[2])
				Format(id3[2], sizeof(id3[]), "%t", "unknown_song");

			Format(id3[4], sizeof(id3[]), "%s - %s (%s)", id3[3], id3[2], id3[5]);
			CRemoveTags(id3[4], sizeof(id3[]));
			AddMenuItem(trackList, id3[4], id3[4]);
		}
	}

	SetMenuExitButton(trackList, true);
	DisplayMenu(trackList, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

stock float GetSongLength(char[] trackIdx)
{
	float duration;
	char bgmTime[128];
	KvGetString(BossKV[Special[0]], trackIdx, bgmTime, sizeof(bgmTime));
	if(StrContains(bgmTime, ":", false)!=-1) // new-style MM:SS:MSMS
	{
		char time2[32][32];
		int count = ExplodeString(bgmTime, ":", time2, sizeof(time2), sizeof(time2));
		if(count > 0)
		{
			for(int i = 0; i < count; i+=3)
			{
				char newTime[64];
				int mins = StringToInt(time2[i])*60;
				int secs = StringToInt(time2[i+1]);
				int milsecs = StringToInt(time2[i+2]);
				Format(newTime, sizeof(newTime), "%i.%i", mins+secs, milsecs);
				duration = StringToFloat(newTime);
			}
		}
	}
	else // old style seconds
	{
		duration=KvGetFloat(BossKV[Special[0]], trackIdx);
	}
	return duration;
}

stock void GetSongTime(int trackIdx, char[] timeStr, int length)
{
	char songIdx[32];
	Format(songIdx, sizeof(songIdx), "time%i", trackIdx);
	int time=RoundToFloor(GetSongLength(songIdx));
	if(time/60>9)
	{
		IntToString(time/60, timeStr, length);
	}
	else
	{
		Format(timeStr, length, "0%i", time/60);
	}

	if(time%60>9)
	{
		Format(timeStr, length, "%s:%i", timeStr, time%60);
	}
	else
	{
		Format(timeStr, length, "%s:0%i", timeStr, time%60);
	}
}

public int Command_TrackListH(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			StopMusic(param1, true);
			KvRewind(BossKV[Special[0]]);
			if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
			{
				char music[PLATFORM_MAX_PATH];
				int track=param2+1;
				Format(music, 10, "time%i", track);

				float time=GetSongLength(music);
				Format(music, 10, "path%i", track);
				KvGetString(BossKV[Special[0]], music, music, sizeof(music));

				char id3[4][256];
				Format(id3[0], sizeof(id3[]), "name%i", track);
				KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
				Format(id3[1], sizeof(id3[]), "artist%i", track);
				KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));

				char temp[PLATFORM_MAX_PATH], lives[256];
				Format(temp, sizeof(temp), "sound/%s", music);
				if(FileExists(temp, true))
				{
					Format(lives, sizeof(lives), "life%i", track);
					KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
					if(strlen(lives))
					{
						if(StringToInt(lives)!=BossLives[Special[0]])
						{
							if(MusicTimer[param1]!=INVALID_HANDLE)
								KillTimer(MusicTimer[param1]);

							return;
						}
					}
					PlayBGM(param1, music, time, _, id3[2], id3[3]);
				}
				else
				{
					char bossName[64];
					KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
					LogToFile(eLog, "[Boss] Character %s is missing BGM file '%s'!", bossName, temp);
					if(MusicTimer[param1]!=INVALID_HANDLE)
						KillTimer(MusicTimer[param1]);
				}
			}
		}
	}
	return;
}

public Action VoiceTogglePanelCmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!GetConVarBool(cvarAdvancedMusic))
	{
		VoiceTogglePanel(client);
	}
	else
	{
		if(ToggleVoice[client])
		{
			ToggleVoice[client] = false;
			FPrintToChat(client, "%t", "ff2_voice", "off");	// TODO: Make this more multi-language friendly
		}
		else
		{
			ToggleVoice[client] = true;
			FPrintToChat(client, "%t", "ff2_voice", "on");	// TODO: Make this more multi-language friendly
		}
	}
	return Plugin_Handled;
}

public Action VoiceTogglePanel(int client)
{
	Handle panel=CreatePanel();
	SetPanelTitle(panel, "Turn the Freak Fortress 2 voices...");
	DrawPanelItem(panel, "On");
	DrawPanelItem(panel, "Off");
	SendPanelToClient(panel, client, VoiceTogglePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Continue;
}

public int VoiceTogglePanelH(Handle menu, MenuAction action, int client, int selection)
{
	if(IsValidClient(client) && action==MenuAction_Select)
	{
		if(selection==2)
		{
			ToggleVoice[client] = false;
		}
		else
		{
			ToggleVoice[client] = true;
		}

		FPrintToChat(client, "%t", "ff2_voice", selection==2 ? "off" : "on");	// TODO: Make this more multi-language friendly
		if(selection==2)
			FPrintToChat(client, "%t", "ff2_voice2");
	}
}

//Ugly compatability layer since HookSound's arguments changed in 1.8
#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=7
public Action HookSound(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags)
#else
public Action HookSound(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
#endif
{
	if(!Enabled || !IsValidClient(client) || channel<1)
		return Plugin_Continue;

	if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		int iDisguisedTarget = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
		int iDisguisedClass = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
		int disguiseboss = GetBossIndex(iDisguisedTarget);

		if(disguiseboss==-1 || TF2_GetPlayerClass(iDisguisedTarget)!=view_as<TFClassType>(iDisguisedClass))
			return Plugin_Continue;

		if(channel==SNDCHAN_VOICE && !(FF2flags[Boss[disguiseboss]] & FF2FLAG_TALKING))
		{
			char newSound[PLATFORM_MAX_PATH];
			if(RandomSoundVo("catch_replace", newSound, PLATFORM_MAX_PATH, disguiseboss, sound))
			{
				strcopy(sound, PLATFORM_MAX_PATH, newSound);
				return Plugin_Changed;
			}

			if(RandomSound("catch_phrase", newSound, PLATFORM_MAX_PATH, disguiseboss))
			{
				strcopy(sound, PLATFORM_MAX_PATH, newSound);
				return Plugin_Changed;
			}

			if(bBlockVoice[Special[disguiseboss]])
				return Plugin_Stop;
		}
	}

	int boss = GetBossIndex(client);
	if(boss == -1)
		return Plugin_Continue;

	if(channel==SNDCHAN_VOICE && !(FF2flags[Boss[boss]] & FF2FLAG_TALKING))
	{
		char newSound[PLATFORM_MAX_PATH];
		if(RandomSoundVo("catch_replace", newSound, PLATFORM_MAX_PATH, boss, sound))
		{
			strcopy(sound, PLATFORM_MAX_PATH, newSound);
			return Plugin_Changed;
		}

		if(RandomSound("catch_phrase", newSound, PLATFORM_MAX_PATH, boss))
		{
			strcopy(sound, PLATFORM_MAX_PATH, newSound);
			return Plugin_Changed;
		}

		if(bBlockVoice[Special[boss]])
			return Plugin_Stop;
	}
	return Plugin_Continue;
}

stock int GetHealingTarget(int client, bool checkgun=false)
{
	int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");

		return -1;
	}

	if(IsValidEntity(medigun))
	{
		char classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(!strcmp(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		}
	}
	return -1;
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}

public void CvarChangeNextmap(Handle convar, const char[] oldValue, const char[] newValue)
{
	CreateTimer(0.1, Timer_DisplayCharsetVote, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_DisplayCharsetVote(Handle timer)
{
	if(isCharSetSelected)
		return Plugin_Continue;

	if(IsVoteInProgress())
	{
		CreateTimer(5.0, Timer_DisplayCharsetVote, _, TIMER_FLAG_NO_MAPCHANGE);  //Try again in 5 seconds if there's a different vote going on
		return Plugin_Continue;
	}

	Handle menu=CreateMenu(Handler_VoteCharset, view_as<MenuAction>(MENU_ACTIONS_ALL));
	SetMenuTitle(menu, "%t", "select_charset");

	char config[PLATFORM_MAX_PATH], charset[64];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, CharsetCFG);

	Handle Kv=CreateKeyValues("");
	FileToKeyValues(Kv, config);
	int total, charsets;
	AddMenuItem(menu, "Random", "Random");
	do
	{
		total++;
		if(KvGetNum(Kv, "hidden", 0))  //Hidden charsets are hidden for a reason :P
			continue;

		charsets++;
		validCharsets[charsets]=total;

		KvGetSectionName(Kv, charset, sizeof(charset));
		AddMenuItem(menu, charset, charset);
	}
	while(KvGotoNextKey(Kv));
	CloseHandle(Kv);

	if(charsets>1)  //We have enough to call a vote
	{
		FF2CharSet=charsets;  //Temporary so that if the vote result is random we know how many valid charsets are in the validCharset array
		Handle voteDuration=FindConVar("sm_mapvote_voteduration");
		VoteMenuToAll(menu, voteDuration ? GetConVarInt(voteDuration) : 20);
	}

	return Plugin_Continue;
}
public int Handler_VoteCharset(Handle menu, MenuAction action, int param1, int param2)
{
	if(action==MenuAction_VoteEnd)
	{
		FF2CharSet=param1 ? param1-1 : validCharsets[GetRandomInt(1, FF2CharSet)]-1;  //If param1 is 0 then we need to find a random charset

		char nextmap[32];
		GetConVarString(cvarNextmap, nextmap, sizeof(nextmap));
		GetMenuItem(menu, param1, FF2CharSetString, sizeof(FF2CharSetString));
		FPrintToChatAll("%t", "nextmap_charset", nextmap, FF2CharSetString);  //"The character set for {1} will be {2}."
		isCharSetSelected=true;
	}
	else if(action==MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action Command_Nextmap(int client, int args)
{
	if(FF2CharSetString[0])
	{
		char nextmap[42];
		GetConVarString(cvarNextmap, nextmap, sizeof(nextmap));
		FPrintToChat(client, "%t", "nextmap_charset", nextmap, FF2CharSetString);
	}
	return Plugin_Handled;
}

public Action Command_Say(int client, int args)
{
	char chat[128];
	if(GetCmdArgString(chat, sizeof(chat))<1 || !client)
		return Plugin_Continue;

	if(!strcmp(chat, "\"nextmap\"") && FF2CharSetString[0])
	{
		Command_Nextmap(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

bool UseAbility(const char[] ability_name, const char[] plugin_name, int boss, int slot, int buttonMode=0)
{
	int client = Boss[boss];
	bool enabled = true;
	Call_StartForward(PreAbility);
	Call_PushCell(boss);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	Call_PushCell(slot);
	Call_PushCellRef(enabled);
	Call_Finish();

	if(!enabled)
		return false;

	Action action = Plugin_Continue;
	Call_StartForward(OnAbility);
	Call_PushCell(boss);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	if(slot == -1)
	{
		Call_PushCell(3);  // Status - we're assuming here a life-loss ability will always be in use if it gets called
		Call_Finish(action);
	}
	else if(!slot)
	{
		FF2flags[Boss[boss]]&=~FF2FLAG_BOTRAGE;
		Call_PushCell(3);  // Status - we're assuming here a rage ability will always be in use if it gets called
		Call_Finish(action);

		if(BossRageDamage[boss] > 1)
		{
			if(rageMode[client] == 1)
			{
				BossCharge[boss][slot] -= rageMin[client];
			}
			else if(rageMode[client] == 0)
			{
				BossCharge[boss][slot] = 0.0;
			}
		}
	}
	else
	{
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
		int button;
		switch(buttonMode)
		{
			case 1:
			{
				button = IN_DUCK|IN_ATTACK2;
				bossHasRightMouseAbility[boss] = true;
			}
			case 2:
			{
				button = IN_RELOAD;
				bossHasReloadAbility[boss] = true;
			}
			case 3:
			{
				button = IN_ATTACK3;
			}
			default:
			{	// I really don't want players relying on ducking
				button = IN_ATTACK2;
				bossHasRightMouseAbility[boss] = true;
			}
		}

		if(GetClientButtons(Boss[boss]) & button)
		{
			for(int timer; timer<=1; timer++)
			{
				if(BossInfoTimer[boss][timer]!=INVALID_HANDLE)
				{
					KillTimer(BossInfoTimer[boss][timer]);
					BossInfoTimer[boss][timer]=INVALID_HANDLE;
				}
			}

			if(BossCharge[boss][slot] >= 0.0)
			{
				Call_PushCell(2);  //Status
				Call_Finish(action);
				float charge = 100.0*0.2/GetAbilityArgumentFloat(boss, plugin_name, ability_name, 1, 1.5);
				if(BossCharge[boss][slot]+charge < 100.0)
				{
					BossCharge[boss][slot] += charge;
				}
				else
				{
					BossCharge[boss][slot] = 100.0;
				}
			}
			else
			{
				Call_PushCell(1);  //Status
				Call_Finish(action);
				BossCharge[boss][slot] += 0.2;
			}
		}
		else if(BossCharge[boss][slot] > 0.3)
		{
			float angles[3];
			GetClientEyeAngles(Boss[boss], angles);
			if(angles[0] < -45.0)
			{
				Call_PushCell(3);
				Call_Finish(action);
				Handle data;
				CreateDataTimer(0.1, Timer_UseBossCharge, data);
				WritePackCell(data, boss);
				WritePackCell(data, slot);
				WritePackFloat(data, -1.0*GetAbilityArgumentFloat(boss, plugin_name, ability_name, 2, 5.0));
				ResetPack(data);
			}
			else
			{
				Call_PushCell(0);  //Status
				Call_Finish(action);
				BossCharge[boss][slot] = 0.0;
			}
		}
		else if(BossCharge[boss][slot] < 0.0)
		{
			Call_PushCell(1);  //Status
			Call_Finish(action);
			BossCharge[boss][slot] += 0.2;
		}
		else
		{
			Call_PushCell(0);  //Status
			Call_Finish(action);
		}
	}
	return true;
}

stock void SwitchEntityTeams(char[] entityname, int bossteam, int otherteam)
{
	int ent = -1;
	while((ent=FindEntityByClassname2(ent, entityname)) != -1)
	{
		SetEntityTeamNum(ent, view_as<int>(GetEntityTeamNum(ent))==otherteam ? bossteam : otherteam);
	}
}

public void SwitchTeams(int bossteam, int otherteam, bool respawn)
{
	SetTeamScore(bossteam, GetTeamScore(bossteam));
	SetTeamScore(otherteam, GetTeamScore(otherteam));
	OtherTeam=otherteam;
	BossTeam=bossteam;

	if(Enabled)
	{
		if(bossteam==view_as<int>(TFTeam_Red) && otherteam==view_as<int>(TFTeam_Blue))
		{
			SwitchEntityTeams("info_player_teamspawn", bossteam, otherteam);
			SwitchEntityTeams("obj_sentrygun", bossteam, otherteam);
			SwitchEntityTeams("obj_dispenser", bossteam, otherteam);
			SwitchEntityTeams("obj_teleporter", bossteam, otherteam);
			SwitchEntityTeams("filter_activator_tfteam", bossteam, otherteam);

			if(respawn)
			{
				for(int client=1; client<=MaxClients; client++)
				{
					if(!IsValidClient(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator) || TF2_GetPlayerClass(client)==TFClass_Unknown)
						continue;

					TF2_RespawnPlayer(client);
				}
			}
		}
	}
}

public Action Timer_UseBossCharge(Handle timer, Handle data)
{
	BossCharge[ReadPackCell(data)][ReadPackCell(data)]=ReadPackFloat(data);
	return Plugin_Continue;
}

stock void RemoveShield(int client, int attacker)
{
	TF2_RemoveWearable(client, shield[client]);
	EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
	EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
	if(GetConVarInt(cvarShieldType) == 3)
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
	}
	else
	{
		EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
		EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
	}

	shieldHP[client] = 0.0;
	shield[client] = 0;
}

public int Native_IsEnabled(Handle plugin, int numParams)
{
	return Enabled;
}

public int Native_FF2Version(Handle plugin, int numParams)
{
	int version[3];  //Blame the compiler for this mess -.-
	version[0] = StringToInt(MAJOR_REVISION);
	version[1] = StringToInt(MINOR_REVISION);
	version[2] = StringToInt(STABLE_REVISION);
	SetNativeArray(1, version, sizeof(version));
	#if defined DEV_REVISION
	return true;
	#else
	return false;
	#endif
}

public int Native_IsVersus(Handle plugin, int numParams)
{
	return Enabled3;
}

public int Native_ForkVersion(Handle plugin, int numParams)
{
	int fversion[3];
	fversion[0] = StringToInt(FORK_MAJOR_REVISION);
	fversion[1] = StringToInt(FORK_MINOR_REVISION);
	fversion[2] = StringToInt(FORK_STABLE_REVISION);
	SetNativeArray(1, fversion, sizeof(fversion));
	#if defined FORK_DEV_REVISION
	return true;
	#else
	return false;
	#endif
}

public int Native_GetBoss(Handle plugin, int numParams)
{
	int boss=GetNativeCell(1);
	if(boss>=0 && boss<=MaxClients && IsValidClient(Boss[boss]))
		return GetClientUserId(Boss[boss]);

	return -1;
}

public int Native_GetIndex(Handle plugin, int numParams)
{
	return GetBossIndex(GetNativeCell(1));
}

public int Native_GetTeam(Handle plugin, int numParams)
{
	return BossTeam;
}

public int Native_GetSpecial(Handle plugin, int numParams)
{
	int index=GetNativeCell(1), dstrlen=GetNativeCell(3), see=GetNativeCell(4);
	char[] s = new char[dstrlen];
	if(see)
	{
		if(index<0)
			return false;

		if(!BossKV[index])
			return false;

		KvRewind(BossKV[index]);
		KvGetString(BossKV[index], "name", s, dstrlen);
	}
	else
	{
		if(index<0)
			return false;

		if(Special[index]<0)
			return false;

		if(!BossKV[Special[index]])
			return false;

		KvRewind(BossKV[Special[index]]);
		KvGetString(BossKV[Special[index]], "name", s, dstrlen);
	}
	SetNativeString(2, s, dstrlen);
	return true;
}

public int Native_GetName(Handle plugin, int numParams)
{
	int index=GetNativeCell(1), dstrlen=GetNativeCell(3), see=GetNativeCell(4), client=GetNativeCell(5);
	char[] s = new char[dstrlen];

	char language[20];
	GetLanguageInfo(client ? GetClientLanguage(client) : GetServerLanguage(), language, 8, s, 8);
	Format(language, sizeof(language), "name_%s", language);

	if(see)
	{
		if(index < 0)
			return false;

		if(!BossKV[index])
			return false;

		KvRewind(BossKV[index]);
		KvGetString(BossKV[index], language, s, dstrlen);
		if(!s[0])
		{
			if(client)
			{
				GetLanguageInfo(GetServerLanguage(), language, 8, s, 8);
				Format(language, sizeof(language), "name_%s", language);
				KvGetString(BossKV[index], language, s, dstrlen);
			}

			if(!s[0])
				KvGetString(BossKV[index], "name", s, dstrlen);
		}
	}
	else
	{
		if(index < 0)
			return false;

		if(Special[index]<0)
			return false;

		if(!BossKV[Special[index]])
			return false;

		KvRewind(BossKV[Special[index]]);
		KvGetString(BossKV[Special[index]], language, s, dstrlen);
		if(!s[0])
		{
			if(client)
			{
				GetLanguageInfo(GetServerLanguage(), language, 8, s, 8);
				Format(language, sizeof(language), "name_%s", language);
				KvGetString(BossKV[Special[index]], language, s, dstrlen);
			}

			if(!s[0])
				KvGetString(BossKV[Special[index]], "name", s, dstrlen);
		}
	}

	if(!s[0])
		return false;

	SetNativeString(2, s, dstrlen);
	return true;
}

public int Native_GetBossHealth(Handle plugin, int numParams)
{
	return BossHealth[GetNativeCell(1)];
}

public int Native_SetBossHealth(Handle plugin, int numParams)
{
	BossHealth[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetBossMaxHealth(Handle plugin, int numParams)
{
	return BossHealthMax[GetNativeCell(1)];
}

public int Native_SetBossMaxHealth(Handle plugin, int numParams)
{
	BossHealthMax[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetBossLives(Handle plugin, int numParams)
{
	return BossLives[GetNativeCell(1)];
}

public int Native_SetBossLives(Handle plugin, int numParams)
{
	BossLives[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetBossMaxLives(Handle plugin, int numParams)
{
	return BossLivesMax[GetNativeCell(1)];
}

public int Native_SetBossMaxLives(Handle plugin, int numParams)
{
	BossLivesMax[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetBossCharge(Handle plugin, int numParams)
{
	return view_as<int>(BossCharge[GetNativeCell(1)][GetNativeCell(2)]);
}

public int Native_SetBossCharge(Handle plugin, int numParams)  //TODO: This duplicates logic found in Timer_UseBossCharge
{
	BossCharge[GetNativeCell(1)][GetNativeCell(2)]=view_as<float>(GetNativeCell(3));
}

public int Native_GetBossRageDamage(Handle plugin, int numParams)
{
	return BossRageDamage[GetNativeCell(1)];
}

public int Native_SetBossRageDamage(Handle plugin, int numParams)
{
	BossRageDamage[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetRoundState(Handle plugin, int numParams)
{
	if(CheckRoundState()<=0)
		return 0;

	return CheckRoundState();
}

public int Native_GetRageDist(Handle plugin, int numParams)
{
	int index=GetNativeCell(1);
	char plugin_name[64];
	GetNativeString(2,plugin_name,64);
	char ability_name[64];
	GetNativeString(3,ability_name,64);

	if(!BossKV[Special[index]])
		return view_as<int>(0.0);

	KvRewind(BossKV[Special[index]]);
	float see;
	if(!ability_name[0])
		return view_as<int>(KvGetFloat(BossKV[Special[index]],"ragedist",400.0));

	char s[10];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(s,10,"ability%i",i);
		if(KvJumpToKey(BossKV[Special[index]],s))
		{
			char ability_name2[64];
			KvGetString(BossKV[Special[index]], "name",ability_name2,64);
			if(strcmp(ability_name,ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			if((see=KvGetFloat(BossKV[Special[index]],"dist",-1.0))<0)
			{
				KvRewind(BossKV[Special[index]]);
				see=KvGetFloat(BossKV[Special[index]],"ragedist",400.0);
			}
			return view_as<int>(see);
		}
	}
	return view_as<int>(0.0);
}

public int Native_HasAbility(Handle plugin, int numParams)
{
	char pluginName[64], abilityName[64];

	int boss=GetNativeCell(1);
	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	if(boss==-1 || Special[boss]==-1 || !BossKV[Special[boss]])
		return false;

	KvRewind(BossKV[Special[boss]]);
	if(!BossKV[Special[boss]])
	{
		LogToFile(eLog, "[Boss] Failed KV: %i %i", boss, Special[boss]);
		return false;
	}

	char ability[12];
	for(int i=1; i<MAXRANDOMS; i++)
	{
		Format(ability, sizeof(ability), "ability%i", i);
		if(KvJumpToKey(BossKV[Special[boss]], ability))  //Does this ability number exist?
		{
			char abilityName2[64];
			KvGetString(BossKV[Special[boss]], "name", abilityName2, sizeof(abilityName2));
			if(StrEqual(abilityName, abilityName2))  //Make sure the ability names are equal
			{
				char pluginName2[64];
				KvGetString(BossKV[Special[boss]], "plugin_name", pluginName2, sizeof(pluginName2));
				if(!pluginName[0] || !pluginName2[0] || StrEqual(pluginName, pluginName2))  //Make sure the plugin names are equal
					return true;
			}
			KvGoBack(BossKV[Special[boss]]);
		}
	}
	return false;
}

public int Native_DoAbility(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	GetNativeString(2, plugin_name, 64);
	GetNativeString(3, ability_name, 64);
	UseAbility(ability_name,plugin_name, GetNativeCell(1), GetNativeCell(4), GetNativeCell(5));
}

public int Native_GetAbilityArgument(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	GetNativeString(2, plugin_name, 64);
	GetNativeString(3, ability_name, 64);
	return GetAbilityArgument(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5));
}

public int Native_GetAbilityArgumentFloat(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	GetNativeString(2, plugin_name, 64);
	GetNativeString(3, ability_name, 64);
	return view_as<int>(GetAbilityArgumentFloat(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5)));
}

public int Native_GetAbilityArgumentString(Handle plugin, int numParams)
{
	char plugin_name[64];
	GetNativeString(2, plugin_name, 64);
	char ability_name[64];
	GetNativeString(3, ability_name, 64);
	int dstrlen = GetNativeCell(6);
	char[] s = new char[dstrlen+1];
	GetAbilityArgumentString(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), s, dstrlen);
	SetNativeString(5, s, dstrlen);
}

public int Native_GetDamage(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return 0;

	return Damage[client];
}

public int Native_GetFF2flags(Handle plugin, int numParams)
{
	return FF2flags[GetNativeCell(1)];
}

public int Native_SetFF2flags(Handle plugin, int numParams)
{
	FF2flags[GetNativeCell(1)]=GetNativeCell(2);
}

public int Native_GetQueuePoints(Handle plugin, int numParams)
{
	return QueuePoints[GetNativeCell(1)];
}

public int Native_SetQueuePoints(Handle plugin, int numParams)
{
	QueuePoints[GetNativeCell(1)] = GetNativeCell(2);
}

public int Native_GetSpecialKV(Handle plugin, int numParams)
{
	int index=GetNativeCell(1);
	bool isNumOfSpecial=view_as<bool>(GetNativeCell(2));
	if(isNumOfSpecial)
	{
		if(index!=-1 && index<Specials)
		{
			if(BossKV[index]!=INVALID_HANDLE)
				KvRewind(BossKV[index]);

			return view_as<int>(BossKV[index]);
		}
	}
	else
	{
		if(index!=-1 && index<=MaxClients && Special[index]!=-1 && Special[index]<MAXSPECIALS)
		{
			if(BossKV[Special[index]]!=INVALID_HANDLE)
				KvRewind(BossKV[Special[index]]);

			return view_as<int>(BossKV[Special[index]]);
		}
	}
	return view_as<int>(INVALID_HANDLE);
}

public int Native_StartMusic(Handle plugin, int numParams)
{
	StartMusic(GetNativeCell(1));
}

public int Native_StopMusic(Handle plugin, int numParams)
{
	StopMusic(GetNativeCell(1));
}

public int Native_RandomSound(Handle plugin, int numParams)
{
	int length = GetNativeCell(3)+1;
	int boss = GetNativeCell(4);
	int slot = GetNativeCell(5);
	char[] sound = new char[length];
	int kvLength;

	GetNativeStringLength(1, kvLength);
	kvLength++;

	char[] keyvalue = new char[kvLength];
	GetNativeString(1, keyvalue, kvLength);

	bool soundExists;
	if(!StrContains(keyvalue, "sound_ability", false))
	{
		soundExists = RandomSoundAbility(keyvalue, sound, length, boss, slot);
	}
	else
	{
		soundExists = RandomSound(keyvalue, sound, length, boss);
	}
	SetNativeString(2, sound, length);
	return soundExists;
}

public int Native_EmitVoiceToAll(Handle plugin, int numParams)
{
	int kvLength;
	GetNativeStringLength(1, kvLength);
	kvLength++;
	char[] keyvalue = new char[kvLength];
	GetNativeString(1, keyvalue, kvLength);

	float origin[3], dir[3];
	GetNativeArray(9, origin, 3);
	GetNativeArray(10, dir, 3);

	EmitSoundToAllExcept(keyvalue, GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), GetNativeCell(8), origin, dir, GetNativeCell(11), GetNativeCell(12));
}

public int Native_GetClientGlow(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client))
	{
		return view_as<int>(GlowTimer[client]);
	}
	else
	{
		return -1;
	}
}

public int Native_SetClientGlow(Handle plugin, int numParams)
{
	SetClientGlow(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public int Native_GetClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client) && hadshield[client])
	{
		if(shield[client])
		{
			if(GetConVarInt(cvarShieldType) > 2)
			{
				return RoundToFloor(shieldHP[client]/GetConVarFloat(cvarShieldHealth)*100.0);
			}
			else
			{
				return 100;
			}
		}
		return 0;
	}
	return -1;
}

public int Native_SetClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client))
	{
		if(GetNativeCell(2) > 0)
			shield[client] = GetNativeCell(2);

		if(GetNativeCell(3) >= 0)
			shieldHP[client] = GetNativeCell(3)*GetConVarFloat(cvarShieldHealth)/100.0;

		if(GetNativeCell(4) > 0)
		{
			shDmgReduction[client] = (1.0-GetNativeCell(4));
		}
		else if(GetNativeCell(3) > 0)
		{
			shDmgReduction[client] = shieldHP[client]/GetConVarFloat(cvarShieldHealth)*(1.0-GetConVarFloat(cvarShieldResist));
		}
	}
}

public int Native_RemoveClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(IsValidClient(client))
	{
		TF2_RemoveWearable(client, shield[client]);
		shieldHP[client] = 0.0;
		shield[client] = 0;
	}
}

public int Native_LogError(Handle plugin, int numParams)
{
	char buffer[MAX_BUFFER_LENGTH], buffer2[MAX_BUFFER_LENGTH], message[192];
	SetNativeString(1, message, sizeof(message));
	Format(buffer, sizeof(buffer), "%s", message);
	VFormat(buffer2, sizeof(buffer2), buffer, 2);
	LogToFile(eLog, buffer2);
}

public int Native_Debug(Handle plugin, int numParams)
{
	return GetConVarBool(cvarDebug);
}

public int Native_SetCheats(Handle plugin, int numParams)
{
	CheatsUsed = GetNativeCell(1);
}

public int Native_GetCheats(Handle plugin, int numParams)
{
	return CheatsUsed;
}

public int Native_IsVSHMap(Handle plugin, int numParams)
{
	return false;
}

public Action VSH_OnIsSaxtonHaleModeEnabled(int &result)
{
	if((!result || result==1) && Enabled)
	{
		result = 2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleTeam(int &result)
{
	if(Enabled)
	{
		result = BossTeam;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleUserId(int &result)
{
	if(Enabled && IsClientConnected(Boss[0]))
	{
		result = GetClientUserId(Boss[0]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSpecialRoundIndex(int &result)
{
	if(Enabled)
	{
		result = Special[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleHealth(int &result)
{
	if(Enabled)
	{
		result = BossHealth[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleHealthMax(int &result)
{
	if(Enabled)
	{
		result = BossHealthMax[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetClientDamage(int client, int &result)
{
	if(Enabled)
	{
		result = Damage[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetRoundState(int &result)
{
	if(Enabled)
	{
		result = CheckRoundState();
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnTakeDamagePost(int client, int attacker, int inflictor, float damage, int damagetype)
{
	if(IsBoss(client))
	{
		UpdateHealthBar();
	}
}

stock void MyAddServerTag(const char[] tag)
{
	char currtags[128];
	if(cvarTags == INVALID_HANDLE)
		return;

	GetConVarString(cvarTags, currtags, sizeof(currtags));
	if(StrContains(currtags, tag) > -1)
		return;

	char newtags[128];
	Format(newtags, sizeof(newtags), "%s%s%s", currtags, (currtags[0]!=0) ? "," : "", tag);
	int flags = GetConVarFlags(cvarTags);
	SetConVarFlags(cvarTags, flags & ~FCVAR_NOTIFY);
	SetConVarString(cvarTags, newtags);
	SetConVarFlags(cvarTags, flags);
}

stock void MyRemoveServerTag(const char[] tag)
{
	char newtags[128];
	if (cvarTags == INVALID_HANDLE)
		return;

	GetConVarString(cvarTags, newtags, sizeof(newtags));
	if(StrContains(newtags, tag) == -1)
		return;

	ReplaceString(newtags, sizeof(newtags), tag, "");
	ReplaceString(newtags, sizeof(newtags), ",,", "");
	int flags = GetConVarFlags(cvarTags);
	SetConVarFlags(cvarTags, flags & ~FCVAR_NOTIFY);
	SetConVarString(cvarTags, newtags);
	SetConVarFlags(cvarTags, flags);
}

public Action Timer_HealthBarMode(Handle timer, bool set)
{
	if(set && !HealthBarMode)
	{
		HealthBarMode = true;
		UpdateHealthBar();
	}
	else if(!set && HealthBarMode)
	{
		HealthBarMode = false;
		UpdateHealthBar();
	}
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(GetConVarInt(cvarHealthBar) > 0)
	{
		if(StrEqual(classname, HEALTHBAR_CLASS))
			healthBar = entity;

		if(!IsValidEntity(g_Monoculus) && StrEqual(classname, MONOCULUS))
			g_Monoculus = entity;
	}

	if(StrContains(classname, "item_healthkit")!=-1 || StrContains(classname, "item_ammopack")!=-1 || StrEqual(classname, "tf_ammo_pack"))
		SDKHook(entity, SDKHook_Spawn, OnItemSpawned);
}

public void OnEntityDestroyed(int entity)
{
	if(entity==g_Monoculus)
	{
		g_Monoculus=FindEntityByClassname(-1, MONOCULUS);
		if(g_Monoculus==entity)
			g_Monoculus=FindEntityByClassname(entity, MONOCULUS);
	}
}

public void OnItemSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPickup);
	SDKHook(entity, SDKHook_Touch, OnPickup);
}

public Action OnPickup(int entity, int client)  //Thanks friagram!
{
	if(IsBoss(client))
	{
		char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!StrContains(classname, "item_healthkit") && !(FF2flags[client] & FF2FLAG_ALLOW_HEALTH_PICKUPS))
		{
			return Plugin_Handled;
		}
		else if((!StrContains(classname, "item_ammopack") || StrEqual(classname, "tf_ammo_pack")) && !(FF2flags[client] & FF2FLAG_ALLOW_AMMO_PICKUPS))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return 1;
		}
		default:
		{
			return 2;
		}
	}
	#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=9
	return -1;  //Compiler bug-doesn't recognize 'default' as a valid catch-all
	#endif
}

void FindHealthBar()
{
	healthBar=FindEntityByClassname(-1, HEALTHBAR_CLASS);
	if(!IsValidEntity(healthBar))
		healthBar=CreateEntityByName(HEALTHBAR_CLASS);
}

public void HealthbarEnableChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(Enabled && GetConVarInt(cvarHealthBar)>0 && IsValidEntity(healthBar))
	{
		UpdateHealthBar();
	}
	else if(!IsValidEntity(g_Monoculus) && IsValidEntity(healthBar))
	{
		SetEntProp(healthBar, Prop_Send, HEALTHBAR_PROPERTY, 0);
	}
}

void UpdateHealthBar()
{
	if(!Enabled || GetConVarInt(cvarHealthBar)<1 || IsValidEntity(g_Monoculus) || !IsValidEntity(healthBar) || CheckRoundState()!=1)
		return;

	int healthAmount, maxHealthAmount, healthPercent;
	int healing = HealthBarMode ? 1 : 0;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			if(Enabled3)
			{
				if(TF2_GetClientTeam(Boss[boss]) == TFTeam_Blue)
				{
					healthAmount += BossHealth[boss];
				}
				else
				{
					maxHealthAmount += BossHealth[boss];
				}
			}
			else
			{
				if(GetConVarInt(cvarHealthBar) > 1)
				{
					healthAmount += BossHealth[boss];
					maxHealthAmount += BossHealthMax[boss]*BossLivesMax[boss];
				}
				else
				{
					healthAmount += BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
					maxHealthAmount += BossHealthMax[boss];
				}
			}
			if(HealthBarModeC[boss])
				healing = 1;
		}
	}

	if(maxHealthAmount)
	{
		if(Enabled3)
		{
			if(maxHealthAmount > healthAmount)
			{
				healthPercent = RoundToCeil(float(healthAmount)/float(maxHealthAmount)*float(HEALTHBAR_MAX)*0.5);
			}
			else
			{
				healthPercent = RoundToCeil((1.0-(float(maxHealthAmount)/float(healthAmount)*0.5))*float(HEALTHBAR_MAX));
			}
		}
		else
		{
			healthPercent = RoundToCeil(float(healthAmount)/float(maxHealthAmount)*float(HEALTHBAR_MAX));
		}

		if(healthPercent > HEALTHBAR_MAX)
		{
			healthPercent = HEALTHBAR_MAX;
		}
		else if(healthPercent <= 0)
		{
			healthPercent = 1;
		}
	}
	SetEntProp(healthBar, Prop_Send, HEALTHBAR_COLOR, healing);
	SetEntProp(healthBar, Prop_Send, HEALTHBAR_PROPERTY, healthPercent);
}

void SetClientGlow(int client, float time1, float time2=-1.0)
{
	if(IsValidClient(client))
	{
		GlowTimer[client]+=time1;
		if(time2>=0)
			GlowTimer[client]=time2;

		if(GlowTimer[client]<=0.0)
		{
			GlowTimer[client]=0.0;
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		}
	}
}

#include <freak_fortress_2_vsh_feedback>

#file "Unofficial Freak Fortress"
