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
//#tryinclude <smac>
#tryinclude <goomba>
#tryinclude <rtd>
#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=9
#tryinclude <rtd2>
#endif
#tryinclude <tf2attributes>
#tryinclude <updater>
#tryinclude <freak_fortress_2_kstreak>
#define REQUIRE_PLUGIN

#pragma newdecls required

/*
    This fork uses a different versioning system
    as opposed to the public FF2 versioning system
*/
#define FORK_MAJOR_REVISION "1"
#define FORK_MINOR_REVISION "18"
#define FORK_STABLE_REVISION "0"
#define FORK_SUB_REVISION "Unofficial"
#define FORK_DEV_REVISION "Dev"

#if !defined FORK_DEV_REVISION
	#define PLUGIN_VERSION FORK_SUB_REVISION..." "...FORK_MAJOR_REVISION..."."...FORK_MINOR_REVISION..."."...FORK_STABLE_REVISION
#else
	#define PLUGIN_VERSION FORK_SUB_REVISION..." "...FORK_MAJOR_REVISION..."."...FORK_MINOR_REVISION..."."...FORK_STABLE_REVISION..." "...FORK_DEV_REVISION
#endif

#define UPDATE_URL "http://batfoxkid.github.io/FreakFortressBat/update.txt"

/*
    And now, let's report its version as the latest public FF2 version
    for subplugins or plugins that uses the FF2_GetFF2Version native.
*/
#define MAJOR_REVISION "1"
#define MINOR_REVISION "10"
#define STABLE_REVISION "15"

#define MAXENTITIES 2048
#define MAXSPECIALS 150
#define MAXRANDOMS 64

#define SOUNDEXCEPT_MUSIC 0
#define SOUNDEXCEPT_VOICE 1

#define HEALTHBAR_CLASS "monster_resource"
#define HEALTHBAR_PROPERTY "m_iBossHealthPercentageByte"
#define HEALTHBAR_MAX 255
#define MONOCULUS "eyeball_boss"

#define MAX_MESSAGE_LENGTH	256
#define MAX_BUFFER_LENGTH	(MAX_MESSAGE_LENGTH * 4)

// File paths
#define ConfigPath "configs/freak_fortress_2"
#define DataPath "data/freak_fortress_2"
#define LogPath "logs/freak_fortress_2"
#define BossLogPath "logs/freak_fortress_2/bosses"
#define CharsetCFG "characters.cfg"
#define DebugLog "ff2_debug.log"
#define DoorCFG "doors.cfg"
#define MapCFG "maps.cfg"
#define WeaponCFG "weapons.cfg"

float shDmgReduction[MAXPLAYERS+1];
char dLog[256];

#if defined _steamtools_included
bool steamtools=false;
#endif

#if defined _tf2attributes_included
bool tf2attributes=false;
#endif

#if defined _goomba_included
bool goomba=false;
#endif

#if defined _freak_fortress_2_kstreak_included
bool kmerge=false;
#endif

bool smac=false;

bool isCapping=false;

int RPSWinner;
int currentBossTeam;
bool blueBoss;
int OtherTeam=2;
int BossTeam=3;
int playing;
int healthcheckused;
int RedAlivePlayers;
int BlueAlivePlayers;
int RoundCount;
int Companions=0;
int GhostBoss=0;
bool LastMan=true;
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
int detonations[MAXPLAYERS+1];
bool playBGM[MAXPLAYERS+1]=true;
int Healing[MAXPLAYERS+1];
float SapperCooldown[MAXPLAYERS+1];

float shieldHP[MAXPLAYERS+1];
char currentBGM[MAXPLAYERS+1][PLATFORM_MAX_PATH];

int FF2flags[MAXPLAYERS+1];

int Boss[MAXPLAYERS+1];
int BossHealthMax[MAXPLAYERS+1];
int BossHealth[MAXPLAYERS+1];
int BossHealthLast[MAXPLAYERS+1];
int BossLives[MAXPLAYERS+1];
int BossLivesMax[MAXPLAYERS+1];
int BossRageDamage[MAXPLAYERS+1];
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
bool emitRageSound[MAXPLAYERS+1];
bool bossHasReloadAbility[MAXPLAYERS+1];
bool bossHasRightMouseAbility[MAXPLAYERS+1];

int timeleft;
int cursongId[MAXPLAYERS+1]=1;

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
ConVar cvarUpdater;
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
ConVar cvarGhostBoss;
ConVar cvarShieldType;
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
ConVar cvarTheme;

Handle FF2Cookies;

Handle jumpHUD;
Handle rageHUD;
Handle livesHUD;
Handle timeleftHUD;
Handle abilitiesHUD;
Handle infoHUD;
//Handle lifeHUD;

bool Enabled=true;
bool Enabled2=true;
int PointDelay=6;
int PointTime=45;
float Announce=120.0;
int AliveToEnable=5;
int PointType;
int arenaRounds;
float circuitStun;
int countdownPlayers=1;
int countdownTime=120;
int countdownHealth=2000;
bool countdownOvertime=false;
bool SpecForceBoss;
int lastPlayerGlow=1;
bool bossTeleportation=true;
int shieldCrits;
int allowedDetonations;
float GoombaDamage=0.05;
float reboundPower=300.0;
bool canBossRTD;
float SniperDamage=2.5;
float SniperMiniDamage=2.1;
float BowDamage=1.25;
float BowDamageNon=0.0;
float BowDamageMini=0.0;
float SniperClimbDamage=15.0;
float SniperClimbDelay=1.56;
int QualityWep=5;
int PointsInterval=600;
float PointsInterval2=600.0;
int PointsMin=10;
int PointsDamage=0;
int PointsExtra=10;
bool DuoMin=false;
bool TellName=false;
int Annotations=0;

Handle MusicTimer[MAXPLAYERS+1];
Handle BossInfoTimer[MAXPLAYERS+1][2];
Handle DrawGameTimer;
Handle doorCheckTimer;

int botqueuepoints;
float HPTime;
char currentmap[99];
bool checkDoors=false;
bool bMedieval;
bool firstBlood;

int tf_arena_use_queue;
int mp_teams_unbalance_limit;
int tf_arena_first_blood;
int mp_forcecamera;
int tf_dropped_weapon_lifetime;
char mp_humans_must_join_team[16];

Handle cvarNextmap;
bool areSubPluginsEnabled;

int FF2CharSet;
int validCharsets[64];
char FF2CharSetString[42];
bool isCharSetSelected=false;

int healthBar=-1;
int g_Monoculus=-1;

static bool executed=false;
static bool executed2=false;
static bool ReloadFF2=false;
static bool ReloadWeapons=false;
static bool ReloadConfigs=false;
bool LoadCharset=false;
static bool HasSwitched=false;

Handle hostName;
char oldName[256];
int changeGamemode;
Handle kvWeaponMods=INVALID_HANDLE;

bool IsBossSelected[MAXPLAYERS+1];
bool dmgTriple[MAXPLAYERS+1];
bool selfKnockback[MAXPLAYERS+1];
bool randomCrits[MAXPLAYERS+1];
bool SapperBoss[MAXPLAYERS+1];
bool SapperMinion;

static const char OTVoice[][] = {
    "vo/announcer_overtime.mp3",
    "vo/announcer_overtime2.mp3",
    "vo/announcer_overtime3.mp3",
    "vo/announcer_overtime4.mp3"
};

enum WorldModelType
{
	ModelType_Normal=0,
	ModelType_PyroVision,
	ModelType_HalloweenVision,
	ModelType_RomeVision
};

enum Operators
{
	Operator_None=0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

static const char ff2versiontitles[][]=
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
	"1.18.0"
};

static const char ff2versiondates[][]=
{
	"April 6, 2012",			//1.0
	"April 14, 2012",		//1.01
	"April 14, 2012",		//1.01
	"April 17, 2012",		//1.02
	"April 19, 2012",		//1.03
	"April 21, 2012",		//1.04
	"April 29, 2012",		//1.05
	"April 29, 2012",		//1.05
	"May 1, 2012",			//1.06
	"June 22, 2012",			//1.06c
	"July 3, 2012",			//1.06d
	"August 24, 2012",			//1.06e
	"September 5, 2012",			//1.06f
	"September 5, 2012",			//1.06g
	"September 6, 2012",			//1.06h
	"October 8, 2012",			//1.07 beta 1
	"October 8, 2012",			//1.07 beta 1
	"October 8, 2012",			//1.07 beta 1
	"October 8, 2012",			//1.07 beta 1
	"October 8, 2012",			//1.07 beta 1
	"October 11, 2012",			//1.07 beta 4
	"October 18, 2012",			//1.07 beta 5
	"November 9, 2012",			//1.07 beta 6
	"December 14, 2012",			//1.07
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
	"November 19, 2015",	//1.10.7
	"November 19, 2015",	//1.10.7
	"November 19, 2015",	//1.10.7
	"November 24, 2015",	//1.10.8
	"May 7, 2016",			//1.10.9
	"May 7, 2016",			//1.10.9
	"May 7, 2016",			//1.10.9
	"May 7, 2016",			//1.10.9
	"May 7, 2016",			//1.10.9
	"August 1, 2016",		//1.10.10
	"August 1, 2016",		//1.10.11
	"August 4, 2016",		//1.10.12
	"September 1, 2016",	//1.10.13
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
	"Development"			//1.18.0
};

stock void FindVersionData(Handle panel, int versionIndex)
{
	switch(versionIndex)
	{
		case 140:  //1.18.0
		{
			DrawPanelText(panel, "1) [Core] Code is now in Transitional Syntax (Batfoxkid)");
			DrawPanelText(panel, "2) [Bosses] Merged all default subplugins (Batfoxkid)");
			DrawPanelText(panel, "3) [Bosses] Added new stun options (Batfoxkid from sarysa)");
			DrawPanelText(panel, "4) [Gameplay] Added the ability to sap bosses or minions (Batfoxkid from SHADoW)");
		}
		case 139:  //1.17.10
		{
			DrawPanelText(panel, "1) [Gameplay] Bosses] Added 'theme' setting for certain bosses blocked with ff2_theme (Batfoxkid)");
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
			DrawPanelText(panel, "5) [Gameplay] Cvar to show healing done (Vee)");
		}
		case 137:  //1.17.9
		{
			DrawPanelText(panel, "6) [Gameplay] Candy Cane Scouts gain healing credit (Vee)");
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
	CreateNative("FF2_GetForkVersion", Native_ForkVersion);
	CreateNative("FF2_GetBossUserId", Native_GetBoss);
	CreateNative("FF2_GetBossIndex", Native_GetIndex);
	CreateNative("FF2_GetBossTeam", Native_GetTeam);
	CreateNative("FF2_GetBossSpecial", Native_GetSpecial);
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
	CreateNative("FF2_GetFF2flags", Native_GetFF2flags);
	CreateNative("FF2_SetFF2flags", Native_SetFF2flags);
	CreateNative("FF2_GetQueuePoints", Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", Native_SetQueuePoints);
	CreateNative("FF2_GetClientGlow", Native_GetClientGlow);
	CreateNative("FF2_SetClientGlow", Native_SetClientGlow);
	CreateNative("FF2_GetClientShield", Native_GetClientShield);
	CreateNative("FF2_SetClientShield", Native_SetClientShield);
	CreateNative("FF2_RemoveClientShield", Native_RemoveClientShield);
	CreateNative("FF2_Debug", Native_Debug);

	PreAbility=CreateGlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);  //Boss, plugin name, ability name, slot, enabled
	OnAbility=CreateGlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);  //Boss, plugin name, ability name, status
	OnMusic=CreateGlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
	OnTriggerHurt=CreateGlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	OnSpecialSelected=CreateGlobalForward("FF2_OnSpecialSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell);  //Boss, character index, character name, preset
	OnAddQueuePoints=CreateGlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	OnLoadCharacterSet=CreateGlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_CellByRef, Param_String);
	OnLoseLife=CreateGlobalForward("FF2_OnLoseLife", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);  //Boss, lives left, max lives
	OnAlivePlayersChanged=CreateGlobalForward("FF2_OnAlivePlayersChanged", ET_Hook, Param_Cell, Param_Cell);  //Players, bosses

	RegPluginLibrary("freak_fortress_2");

	AskPluginLoad_VSH();
	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif

	#if defined _tf2attributes_included
	MarkNativeAsOptional("TF2Attrib_SetByDefIndex");
	MarkNativeAsOptional("TF2Attrib_RemoveByDefIndex");
	#endif
	return APLRes_Success;
}

// Boss Selection
char xIncoming[MAXPLAYERS+1][700];
char cIncoming[MAXPLAYERS+1][700];

// Boss Toggle
#define TOGGLE_UNDEF -1
#define TOGGLE_ON  1
#define TOGGLE_OFF 2
#define TOGGLE_TEMP 3

Handle BossCookie=INVALID_HANDLE;
Handle CompanionCookie=INVALID_HANDLE;
Handle LastPlayedCookie=INVALID_HANDLE;
Handle cvarFF2TogglePrefDelay=INVALID_HANDLE;

ClientCookie[MAXPLAYERS+1];
ClientCookie2[MAXPLAYERS+1];
ClientPoint[MAXPLAYERS+1];
ClientID[MAXPLAYERS+1];
ClientQueue[MAXPLAYERS+1][2];
bool InfiniteRageActive[MAXPLAYERS+1]=false;

// Boss Log
char bLog[PLATFORM_MAX_PATH];
char pLog[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
	LogMessage("===Freak Fortress 2 Initializing-%s===", PLUGIN_VERSION);

	// Logs
	BuildPath(Path_SM, pLog, sizeof(pLog), BossLogPath);
	if(!DirExists(pLog))
	{
		CreateDirectory(pLog, 511);
		
		if (!DirExists(pLog))
			LogError("Failed to create directory at %s", pLog);
	}

	BuildPath(Path_SM, dLog, sizeof(dLog), "%s/%s", LogPath, DebugLog);
	if(!FileExists(dLog))
		OpenFile(dLog, "a+");

	cvarVersion=CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarPointType=CreateConVar("ff2_point_type", "0", "0-Use ff2_point_alive, 1-Use ff2_point_time, 2-Use both", _, true, 0.0, true, 2.0);
	cvarPointDelay=CreateConVar("ff2_point_delay", "6", "Seconds to add to ff2_point_time per player");
	cvarPointTime=CreateConVar("ff2_point_time", "45", "Time before unlocking the control point");
	cvarAliveToEnable=CreateConVar("ff2_point_alive", "5", "The control point will only activate when there are this many people or less left alive", _, true, 0.0, true, 34.0);
	cvarAnnounce=CreateConVar("ff2_announce", "120", "Amount of seconds to wait until FF2 info is displayed again.  0 to disable", _, true, 0.0);
	cvarEnabled=CreateConVar("ff2_enabled", "1", "0-Disable FF2 (WHY?), 1-Enable FF2", FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	cvarCrits=CreateConVar("ff2_crits", "0", "Can the boss get random crits?", _, true, 0.0, true, 1.0);
	cvarArenaRounds=CreateConVar("ff2_arena_rounds", "1", "Number of rounds to make arena before switching to FF2 (helps for slow-loading players)", _, true, 0.0);
	cvarCircuitStun=CreateConVar("ff2_circuit_stun", "0", "Amount of seconds the Short Circuit stuns the boss for.  0 to disable", _, true, 0.0);
	cvarCountdownPlayers=CreateConVar("ff2_countdown_players", "1", "Amount of players until the countdown timer starts (0 to disable)", _, true, 0.0, true, 34.0);
	cvarCountdownTime=CreateConVar("ff2_countdown", "120", "Amount of seconds until the round ends in a stalemate");
	cvarCountdownHealth=CreateConVar("ff2_countdown_health", "2000", "Amount of health the Boss has remaining until the countdown stops", _, true, 0.0);
	cvarCountdownResult=CreateConVar("ff2_countdown_result", "0", "0-Kill players when the countdown ends, 1-End the round in a stalemate", _, true, 0.0, true, 1.0);
	cvarSpecForceBoss=CreateConVar("ff2_spec_force_boss", "0", "0-Spectators are excluded from the queue system, 1-Spectators are counted in the queue system", _, true, 0.0, true, 1.0);
	cvarEnableEurekaEffect=CreateConVar("ff2_enable_eureka", "0", "0-Disable the Eureka Effect, 1-Enable the Eureka Effect", _, true, 0.0, true, 1.0);
	cvarForceBossTeam=CreateConVar("ff2_force_team", "0", "0-Boss is always on Blu, 1-Boss is on a random team each round, 2-Boss is always on Red", _, true, 0.0, true, 3.0);
	cvarHealthBar=CreateConVar("ff2_health_bar", "0", "0-Disable the health bar, 1-Show the health bar", _, true, 0.0, true, 1.0);
	cvarLastPlayerGlow=CreateConVar("ff2_last_player_glow", "1", "How many players left before outlining everyone", _, true, 0.0, true, 34.0);
	cvarBossTeleporter=CreateConVar("ff2_boss_teleporter", "0", "-1 to disallow all bosses from using teleporters, 0 to use TF2 logic, 1 to allow all bosses", _, true, -1.0, true, 1.0);
	cvarBossSuicide=CreateConVar("ff2_boss_suicide", "0", "Allow the boss to suicide after the round starts?", _, true, 0.0, true, 1.0);
	cvarPreroundBossDisconnect=CreateConVar("ff2_replace_disconnected_boss", "0", "If a boss disconnects before the round starts, use the next player in line instead? 0 - No, 1 - Yes", _, true, 0.0, true, 1.0);
	cvarCaberDetonations=CreateConVar("ff2_caber_detonations", "1", "Amount of times somebody can detonate the Ullapool Caber", _, true, 1.0);
	cvarShieldCrits=CreateConVar("ff2_shield_crits", "0", "0 to disable grenade launcher crits when equipping a shield, 1 for minicrits, 2 for crits", _, true, 0.0, true, 2.0);
	cvarGoombaDamage=CreateConVar("ff2_goomba_damage", "0.05", "How much the Goomba damage should be multipled by when goomba stomping the boss (requires Goomba Stomp)", _, true, 0.01, true, 1.0);
	cvarGoombaRebound=CreateConVar("ff2_goomba_jump", "300.0", "How high players should rebound after goomba stomping the boss (requires Goomba Stomp)", _, true, 0.0);
	cvarBossRTD=CreateConVar("ff2_boss_rtd", "0", "Can the boss use rtd? 0 to disallow boss, 1 to allow boss (requires RTD)", _, true, 0.0, true, 1.0);
	cvarDeadRingerHud=CreateConVar("ff2_deadringer_hud", "1", "Dead Ringer indicator? 0 to disable, 1 to enable", _, true, 0.0, true, 1.0);
	cvarUpdater=CreateConVar("ff2_updater", "1", "0-Disable Updater support, 1-Enable automatic updating (recommended, requires Updater)", _, true, 0.0, true, 1.0);
	cvarDebug=CreateConVar("ff2_debug", "0", "0-Disable FF2 debug output, 1-Enable debugging (not recommended)", _, true, 0.0, true, 1.0);
	cvarDmg2KStreak=CreateConVar("ff2_dmg_kstreak", "250", "Minimum damage to increase killstreak count", _, true, 0.0);
	cvarAirStrike=CreateConVar("ff2_dmg_airstrike", "250", "Minimum damage to increase head count for the Air-Strike", _, true, 0.0);
	cvarSniperDamage=CreateConVar("ff2_sniper_dmg", "2.5", "Sniper Rifle normal multiplier", _, true, 0.0);
	cvarSniperMiniDamage=CreateConVar("ff2_sniper_dmg_mini", "2.1", "Sniper Rifle mini-crit multiplier", _, true, 0.0);
	cvarBowDamage=CreateConVar("ff2_bow_dmg", "1.25", "Huntsman critical multiplier", _, true, 0.0);
	cvarBowDamageNon=CreateConVar("ff2_bow_dmg_non", "0.0", "If not zero Huntsman has no crit boost, Huntsman normal non-crit multiplier", _, true, 0.0);
	cvarBowDamageMini=CreateConVar("ff2_bow_dmg_mini", "0.0", "If not zero Huntsman is mini-crit boosted, Huntsman normal mini-crit multiplier", _, true, 0.0);
	cvarSniperClimbDamage=CreateConVar("ff2_sniper_climb_dmg", "15.0", "Damage taken during climb", _, true, 0.0);
	cvarSniperClimbDelay=CreateConVar("ff2_sniper_climb_delay", "1.56", "0-Disable Climbing, Delay between climbs", _, true, 0.0);
	cvarStrangeWep=CreateConVar("ff2_strangewep", "1", "0-Disable Boss Weapon Stranges, 1-Enable Boss Weapon Stranges", _, true, 0.0, true, 1.0);
	cvarQualityWep=CreateConVar("ff2_qualitywep", "5", "Default Boss Weapon Quality", _, true, 0.0, true, 15.0);
	cvarTripleWep=CreateConVar("ff2_triplewep", "1", "0-Disable Boss Extra Triple Damage, 1-Enable Boss Extra Triple Damage", _, true, 0.0, true, 1.0);
	cvarHardcodeWep=CreateConVar("ff2_hardcodewep", "1", "0-Only Use Config, 1-Use Alongside Hardcoded, 2-Only Use Hardcoded", _, true, 0.0, true, 2.0);
	cvarSelfKnockback=CreateConVar("ff2_selfknockback", "0", "Can the boss rocket jump but take fall damage too? 0 to disallow boss, 1 to allow boss", _, true, 0.0, true, 1.0);
	cvarFF2TogglePrefDelay=CreateConVar("ff2_boss_toggle_delay", "45.0", "Delay between joining the server and asking the player for their preference, if it is not set.");
	cvarNameChange=CreateConVar("ff2_name_change", "0", "0-Disable, 1-Add the current boss to the server name", _, true, 0.0, true, 1.0);
	cvarKeepBoss=CreateConVar("ff2_boss_keep", "0", "-1-Players can't choose the same boss twice, 0-Nothing, 1-Players keep their current boss selection", _, true, -1.0, true, 1.0);
	cvarSelectBoss=CreateConVar("ff2_boss_select", "1", "0-Disable, 1-Players can select bosses", _, true, 0.0, true, 1.0);
	cvarToggleBoss=CreateConVar("ff2_boss_toggle", "1", "0-Disable, 1-Players can toggle being the boss", _, true, 0.0, true, 1.0);
	cvarDuoBoss=CreateConVar("ff2_boss_companion", "1", "0-Disable, 1-Players can toggle being a companion", _, true, 0.0, true, 1.0);
	cvarPointsInterval=CreateConVar("ff2_points_interval", "600", "Every this damage gives a point", _, true, 1.0);
	cvarPointsDamage=CreateConVar("ff2_points_damage", "0", "Damage required to earn queue points", _, true, 0.0);
	cvarPointsMin=CreateConVar("ff2_points_queue", "10", "Minimum queue points earned", _, true, 0.0);
	cvarPointsExtra=CreateConVar("ff2_points_bonus", "10", "Maximum queue points earned", _, true, 0.0);
	cvarAdvancedMusic=CreateConVar("ff2_advanced_music", "1", "0-Use classic menu, 1-Use new menu", _, true, 0.0, true, 1.0);
	cvarSongInfo=CreateConVar("ff2_song_info", "0", "-1-Never show song and artist in chat, 0-Only if boss has song and artist, 1-Always show song and artist in chat", _, true, -1.0, true, 1.0);
	cvarDuoRandom=CreateConVar("ff2_companion_random", "0", "0-Next player in queue, 1-Random player is the companion", _, true, 0.0, true, 1.0);
	cvarDuoMin=CreateConVar("ff2_companion_min", "4", "Minimum players required to enable duos", _, true, 1.0, true, 34.0);
	//cvarNewDownload=CreateConVar("ff2_new_download", "0", "0-Default disable extra checkers, 1-Default enable extra checkers", _, true, 0.0, true, 1.0);
	cvarDuoRestore=CreateConVar("ff2_companion_restore", "0", "0-Disable, 1-Companions don't lose queue points", _, true, 0.0, true, 1.0);
	cvarLowStab=CreateConVar("ff2_low_stab", "0", "0-Disable, 1-Low-player count stabs, market, and caber do more damage", _, true, 0.0, true, 1.0);
	cvarGameText=CreateConVar("ff2_text_game", "0", "For game messages: 0-Use HUD texts, 1-Use game_text_tf entities, 2-Include boss intro and timer too", _, true, 0.0, true, 2.0);
	cvarAnnotations=CreateConVar("ff2_text_msg", "0", "For backstabs and such: 0-Use hint texts, 1-Use annotations, 2-Use game_text_tf entities", _, true, 0.0, true, 2.0);
	cvarTellName=CreateConVar("ff2_text_names", "0", "For backstabs and such: 0-Don't show player/boss names, 1-Show player/boss names", _, true, 0.0, true, 1.0);
	cvarGhostBoss=CreateConVar("ff2_text_ghost", "0", "For game messages: 0-Default shows killstreak symbol, 1-Default shows a ghost", _, true, 0.0, true, 1.0);
	cvarShieldType=CreateConVar("ff2_shield_type", "1", "0-None, 1-Breaks on any hit, 2-Breaks if it'll kill, 3-Breaks if shield HP is depleted, 4-Breaks if shield or player HP is depleted", _, true, 0.0, true, 4.0);
	cvarCountdownOvertime=CreateConVar("ff2_countdown_overtime", "0", "0-Disable, 1-Delay 'ff2_countdown_result' action until control point is no longer being captured", _, true, 0.0, true, 1.0);
	cvarBossLog=CreateConVar("ff2_boss_log", "0", "0-Disable, #-Players required to enable logging", _, true, 0.0, true, 34.0);
	cvarBossDesc=CreateConVar("ff2_boss_desc", "1", "0-Disable, 1-Show boss description before selecting a boss", _, true, 0.0, true, 1.0);
	cvarRPSPoints=CreateConVar("ff2_rps_points", "0", "0-Disable, #-Queue points awarded / removed upon RPS", _, true, 0.0);
	cvarRPSLimit=CreateConVar("ff2_rps_limit", "0", "0-Disable, #-Number of times the boss loses before being slayed", _, true, 0.0);
	cvarRPSDivide=CreateConVar("ff2_rps_divide", "0", "0-Disable, 1-Divide current boss health with ff2_rps_limit", _, true, 0.0, true, 1.0);
	cvarHealingHud=CreateConVar("ff2_hud_heal", "0", "0-Disable, 1-Show player's healing in damage HUD", _, true, 0.0, true, 1.0);
	cvarSteamTools=CreateConVar("ff2_steam_tools", "1", "0-Disable, 1-Show 'Freak Fortress 2' in game description (requires SteamTools)", _, true, 0.0, true, 1.0);
	cvarSappers=CreateConVar("ff2_sapper", "0", "0-Disable, 1-Can sap the boss, 2-Can sap minions, 3-Can sap both", _, true, 0.0, true, 3.0);
	cvarSapperCooldown=CreateConVar("ff2_sapper_cooldown", "500", "0-No Cooldown, #-Damage needed to be able to use again", _, true, 0.0);
	cvarTheme=CreateConVar("ff2_theme", "0", "0-No Theme, #-Flags of Themes", _, true, 0.0, true, 15.0);

	//The following are used in various subplugins
	CreateConVar("ff2_oldjump", "1", "Use old Saxton Hale jump equations", _, true, 0.0, true, 1.0);
	CreateConVar("ff2_base_jumper_stun", "0", "Whether or not the Base Jumper should be disabled when a player gets stunned", _, true, 0.0, true, 1.0);

	HookEvent("teamplay_round_start", OnRoundStart);
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
	HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Pre);

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
	HookConVarChange(cvarLastPlayerGlow, CvarChange);
	HookConVarChange(cvarSpecForceBoss, CvarChange);
	HookConVarChange(cvarBossTeleporter, CvarChange);
	HookConVarChange(cvarShieldCrits, CvarChange);
	HookConVarChange(cvarCaberDetonations, CvarChange);
	HookConVarChange(cvarGoombaDamage, CvarChange);
	HookConVarChange(cvarGoombaRebound, CvarChange);
	HookConVarChange(cvarBossRTD, CvarChange);
	HookConVarChange(cvarUpdater, CvarChange);
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
	HookConVarChange(cvarAnnotations, CvarChange);
	HookConVarChange(cvarTellName, CvarChange);

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
	RegConsoleCmd("setboss", Command_SetMyBoss, "View FF2 Boss Preferences");

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

	BossCookie = RegClientCookie("ff2_boss_toggle", "Players FF2 Boss Toggle", CookieAccess_Public);
	CompanionCookie = RegClientCookie("ff2_companion_toggle", "Players FF2 Companion Boss Toggle", CookieAccess_Public);
	LastPlayedCookie = RegClientCookie("ff2_boss_previous", "Players FF2 Previous Boss", CookieAccess_Protected);

	RegConsoleCmd("ff2toggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("ff2_toggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("ff2companion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("ff2_companion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("haletoggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("hale_toggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("halecompanion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("hale_companion", CompanionMenu, "Toggle being a FF2 companion");
	for(int i = 0; i < MAXPLAYERS; i++)
	{
		ClientCookie[i] = TOGGLE_UNDEF;
		ClientCookie2[i] = TOGGLE_UNDEF;
	}

	RegConsoleCmd("ff2_skipsong", Command_SkipSong, "Skip the current song");
	RegConsoleCmd("ff2skipsong", Command_SkipSong, "Skip the current song");
	RegConsoleCmd("ff2_shufflesong", Command_ShuffleSong, "Play a random song");
	RegConsoleCmd("ff2shufflesong", Command_ShuffleSong, "Play a random song");
	RegConsoleCmd("ff2_tracklist", Command_Tracklist, "View list of songs");
	RegConsoleCmd("ff2tracklist", Command_Tracklist, "View list of songs");
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

	AutoExecConfig(true, "FreakFortress2");

	FF2Cookies=RegClientCookie("ff2_cookies_mk2", "", CookieAccess_Protected);

	jumpHUD=CreateHudSynchronizer();
	rageHUD=CreateHudSynchronizer();
	livesHUD=CreateHudSynchronizer();
	abilitiesHUD=CreateHudSynchronizer();
	timeleftHUD=CreateHudSynchronizer();
	infoHUD=CreateHudSynchronizer();
	//lifeHUD=CreateHudSynchronizer();

	char oldVersion[64];
	cvarVersion.GetString(oldVersion, 64);
	if(strcmp(oldVersion, PLUGIN_VERSION, false))
	{
		PrintToServer("[FF2] Warning: Your config may be outdated. Back up tf/cfg/sourcemod/FreakFortress2.cfg and delete it, and this plugin will generate a new one that you can then modify to your original values.");
	}

	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("freak_fortress_2_prefs.phrases");
	LoadTranslations("common.phrases");

	AddNormalSoundHook(HookSound);

	AddMultiTargetFilter("@hale", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!hale", BossTargetFilter, "all non-Boss players", false);
	AddMultiTargetFilter("@boss", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "all non-Boss players", false);

	#if defined _steamtools_included
	steamtools=LibraryExists("SteamTools");
	#endif

	#if defined _goomba_included
	goomba=LibraryExists("goomba");
	#endif

	#if defined _tf2attributes_included
	tf2attributes=LibraryExists("tf2attributes");
	#endif
}

public Action Command_SetRage(int client, int args)
{
	if(args!=2)
	{
		if(args!=1)
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_setrage or hale_setrage <target> <percent>");
		}
		else 
		{
			if(!IsValidClient(client))
			{
				ReplyToCommand(client, "[FF2] Command can only be used in-game!");
				return Plugin_Handled;
			}
			
			if(!IsBoss(client) || GetBossIndex(client)==-1 || !IsPlayerAlive(client) || CheckRoundState()!=1)
			{
				CReplyToCommand(client, "{olive}[FF2]{default} You must be a boss to set your RAGE!");
				return Plugin_Handled;
			}
			
			char ragePCT[80];
			GetCmdArg(1, ragePCT, sizeof(ragePCT));
			float rageMeter=StringToFloat(ragePCT);
			
			BossCharge[Boss[client]][0]=rageMeter;
			CReplyToCommand(client, "You now have %i percent RAGE (%i percent added)", RoundFloat(BossCharge[client][0]), RoundFloat(rageMeter));
			LogAction(client, client, "\"%L\" gave themselves %i RAGE", client, RoundFloat(rageMeter));
		}
		return Plugin_Handled;
	}
	
	char ragePCT[80];
	char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, ragePCT, sizeof(ragePCT));
	float rageMeter=StringToFloat(ragePCT);

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
			CReplyToCommand(client, "{olive}[FF2]{default} %s must be a boss to set RAGE!", target_name);
			return Plugin_Handled;
		}

		BossCharge[Boss[target_list[target]]][0]=rageMeter;
		LogAction(client, target_list[target], "\"%L\" set %d RAGE to \"%L\"", client, RoundFloat(rageMeter), target_list[target]);
		CReplyToCommand(client, "{olive}[FF2]{default} Set %d rage to %s", RoundFloat(rageMeter), target_name);
	}
	return Plugin_Handled;
}

public Action Command_AddRage(int client, int args)
{
	if(args!=2)
	{
		if(args!=1)
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_addrage or hale_addrage <target> <percent>");
		}
		else 
		{
			if(!IsValidClient(client))
			{
				ReplyToCommand(client, "[FF2] Command can only be used in-game!");
				return Plugin_Handled;
			}
			
			if(!IsBoss(client) || GetBossIndex(client)==-1 || !IsPlayerAlive(client) || CheckRoundState()!=1)
			{
				CReplyToCommand(client, "{olive}[FF2]{default} You must be a boss to give yourself RAGE!");
				return Plugin_Handled;
			}
			
			char ragePCT[80];
			GetCmdArg(1, ragePCT, sizeof(ragePCT));
			float rageMeter=StringToFloat(ragePCT);
			
			BossCharge[Boss[client]][0]+=rageMeter;
			CReplyToCommand(client, "You now have %i percent RAGE (%i percent added)", RoundFloat(BossCharge[client][0]), RoundFloat(rageMeter));
			LogAction(client, client, "\"%L\" gave themselves %i RAGE", client, RoundFloat(rageMeter));
		}
		return Plugin_Handled;
	}
	
	char ragePCT[80];
	char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, ragePCT, sizeof(ragePCT));
	float rageMeter=StringToFloat(ragePCT);

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
			CReplyToCommand(client, "{olive}[FF2]{default} %s must be a boss to add RAGE!", target_name);
			return Plugin_Handled;
		}

		BossCharge[Boss[target_list[target]]][0]+=rageMeter;
		LogAction(client, target_list[target], "\"%L\" added %d RAGE to \"%L\"", client, RoundFloat(rageMeter), target_list[target]);
		CReplyToCommand(client, "{olive}[FF2]{default} Added %d rage to %s", RoundFloat(rageMeter), target_name);
	}
	return Plugin_Handled;
}

public Action Command_SetInfiniteRage(int client, int args)
{
	if(args!=1)
	{
		if(args>1)
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_setinfiniterage or hale_setinfiniterage <target>");
		}
		else 
		{
			if(!IsValidClient(client))
			{
				ReplyToCommand(client, "[FF2] Command can only be used in-game!");
				return Plugin_Handled;
			}
			
			if(!IsBoss(client) || !IsPlayerAlive(client) || GetBossIndex(client)==-1 || CheckRoundState()!=1)
			{
				CReplyToCommand(client, "{olive}[FF2]{default} You must be a boss to enable/disable infinite RAGE!");
				return Plugin_Handled;
			}
			if(!InfiniteRageActive[client])
			{
				InfiniteRageActive[client]=true;
				BossCharge[Boss[client]][0]=rageMax[client];
				CReplyToCommand(client, "{olive}[FF2]{default} Infinite RAGE activated");
				LogAction(client, client, "\"%L\" activated infiite RAGE on themselves", client);
				CreateTimer(0.2, Timer_InfiniteRage, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				InfiniteRageActive[client]=false;
				CReplyToCommand(client, "{olive}[FF2]{default} Infinite RAGE deactivated");
				LogAction(client, client, "\"%L\" deactivated infiite RAGE on themselves", client);
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
			CReplyToCommand(client, "{olive}[FF2]{default} %s must be a boss to enable/disable infinite RAGE!", target_name);
			return Plugin_Handled;
		}

		if(!InfiniteRageActive[target_list[target]])
		{
			InfiniteRageActive[target_list[target]]=true;
			BossCharge[Boss[target_list[target]]][0]=rageMax[target_list[target]];
			CReplyToCommand(client, "{olive}[FF2]{default} Infinite RAGE activated for %s", target_name);
			LogAction(client, target_list[target], "\"%L\" activated infinite RAGE on \"%L\"", client, target_list[target]);
			CreateTimer(0.2, Timer_InfiniteRage, target_list[target], TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			InfiniteRageActive[target_list[target]]=false;	
			CReplyToCommand(client, "{olive}[FF2]{default} Infinite RAGE deactivated for %s", target_name);
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

public bool BossTargetFilter(const char[] pattern, Handle clients)
{
	bool non=StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && FindValueInArray(clients, client)==-1)
		{
			if(Enabled && IsBoss(client))
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
		steamtools=true;
	}
	#endif

	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
	{
		tf2attributes=true;
	}
	#endif

	#if defined _goomba_included
	if(!strcmp(name, "goomba", false))
	{
		goomba=true;
	}
	#endif

	if(!strcmp(name, "smac", false))
	{
		smac=true;
	}

	#if defined _updater_included && !defined FORK_DEV_REVISION
	if(StrEqual(name, "updater") && GetConVarBool(cvarUpdater))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif

	#if defined _freak_fortress_2_kstreak_included
	if(!strcmp(name, "ff2_kstreak_pref", false))
	{
		kmerge=view_as<bool>(FF2_KStreak_Merge());
	}
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	#if defined _steamtools_included
	if(!strcmp(name, "SteamTools", false))
	{
		steamtools=false;
	}
	#endif

	#if defined _tf2attributes_included
	if(!strcmp(name, "tf2attributes", false))
	{
		tf2attributes=false;
	}
	#endif

	#if defined _goomba_included
	if(!strcmp(name, "goomba", false))
	{
		goomba=false;
	}
	#endif

	if(!strcmp(name, "smac", false))
	{
		smac=false;
	}

	#if defined _updater_included
	if(StrEqual(name, "updater"))
	{
		Updater_RemovePlugin();
	}
	#endif

	#if defined _freak_fortress_2_kstreak_included
	if(!strcmp(name, "ff2_kstreak_pref", false))
	{
		kmerge=false;
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

	if(IsFF2Map() && GetConVarBool(cvarEnabled))
	{
		EnableFF2();
	}
	else
	{
		DisableFF2();
	}

	#if defined _updater_included && !defined FORK_DEV_REVISION
	if(LibraryExists("updater") && GetConVarBool(cvarUpdater))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	#endif
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
		CPrintToChatAll("{olive}[FF2]{default} The plugin has been unexpectedly unloaded!");
	}
}

public void EnableFF2()
{
	Enabled=true;
	Enabled2=true;

	//Cache cvars
	SetConVarString(FindConVar("ff2_version"), PLUGIN_VERSION);
	Announce=GetConVarFloat(cvarAnnounce);
	PointType=GetConVarInt(cvarPointType);
	PointDelay=GetConVarInt(cvarPointDelay);
	GoombaDamage=GetConVarFloat(cvarGoombaDamage);
	reboundPower=GetConVarFloat(cvarGoombaRebound);
	SniperDamage=GetConVarFloat(cvarSniperDamage);
	SniperMiniDamage=GetConVarFloat(cvarSniperMiniDamage);
	BowDamage=GetConVarFloat(cvarBowDamage);
	BowDamageNon=GetConVarFloat(cvarBowDamageNon);
	BowDamageMini=GetConVarFloat(cvarBowDamageMini);
	SniperClimbDamage=GetConVarFloat(cvarSniperClimbDamage);
	SniperClimbDelay=GetConVarFloat(cvarSniperClimbDelay);
	QualityWep=GetConVarInt(cvarQualityWep);
	canBossRTD=GetConVarBool(cvarBossRTD);
	AliveToEnable=GetConVarInt(cvarAliveToEnable);
	PointsInterval=GetConVarInt(cvarPointsInterval);
	PointsInterval2=GetConVarFloat(cvarPointsInterval);
	PointsDamage=GetConVarInt(cvarPointsDamage);
	PointsMin=GetConVarInt(cvarPointsMin);
	PointsExtra=GetConVarInt(cvarPointsExtra);
	arenaRounds=GetConVarInt(cvarArenaRounds);
	circuitStun=GetConVarFloat(cvarCircuitStun);
	countdownHealth=GetConVarInt(cvarCountdownHealth);
	countdownPlayers=GetConVarInt(cvarCountdownPlayers);
	countdownTime=GetConVarInt(cvarCountdownTime);
	countdownOvertime=GetConVarBool(cvarCountdownOvertime);
	lastPlayerGlow=GetConVarInt(cvarLastPlayerGlow);
	bossTeleportation=GetConVarBool(cvarBossTeleporter);
	shieldCrits=GetConVarInt(cvarShieldCrits);
	allowedDetonations=GetConVarInt(cvarCaberDetonations);
	Annotations=GetConVarInt(cvarAnnotations);
	TellName=GetConVarBool(cvarTellName);

	//Set some Valve cvars to what we want them to be
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
	SetConVarString(FindConVar("mp_humans_must_join_team"), "any");

	float time=Announce;
	if(time>1.0)
	{
		CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	CacheWeapons();
	CheckToChangeMapDoors();
	MapHasMusic(true);
	FindCharacters();
	strcopy(FF2CharSetString, 2, "");

	if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
	{
		ServerCommand("smac_removecvar sv_cheats");
		ServerCommand("smac_removecvar host_timescale");
	}

	bMedieval=FindEntityByClassname(-1, "tf_logic_medieval")!=-1 || GetConVarBool(FindConVar("tf_medieval"));
	FindHealthBar();

	#if defined _steamtools_included
	if(steamtools && GetConVarBool(cvarSteamTools))
	{
		char gameDesc[64];
		Format(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
		Steam_SetGameDescription(gameDesc);
	}
	#endif

	changeGamemode=0;
	
	/*for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		}
	}*/
}

public void DisableFF2()
{
	Enabled=false;
	Enabled2=false;

	DisableSubPlugins();

	SetConVarInt(FindConVar("tf_arena_use_queue"), tf_arena_use_queue);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), mp_teams_unbalance_limit);
	SetConVarInt(FindConVar("tf_arena_first_blood"), tf_arena_first_blood);
	SetConVarInt(FindConVar("mp_forcecamera"), mp_forcecamera);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), tf_dropped_weapon_lifetime);
	SetConVarString(FindConVar("mp_humans_must_join_team"), mp_humans_must_join_team);

	if(doorCheckTimer!=INVALID_HANDLE)
	{
		KillTimer(doorCheckTimer);
		doorCheckTimer=INVALID_HANDLE;
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(BossInfoTimer[client][1]!=INVALID_HANDLE)
			{
				KillTimer(BossInfoTimer[client][1]);
				BossInfoTimer[client][1]=INVALID_HANDLE;
			}
		}

		if(MusicTimer[client]!=INVALID_HANDLE)
		{
			KillTimer(MusicTimer[client]);
			MusicTimer[client]=INVALID_HANDLE;
		}

		bossHasReloadAbility[client]=false;
		bossHasRightMouseAbility[client]=false;
	}

	if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
	{
		ServerCommand("smac_addcvar sv_cheats replicated ban 0 0");
		ServerCommand("smac_addcvar host_timescale replicated ban 1.0 1.0");
	}

	#if defined _steamtools_included
	if(steamtools && GetConVarBool(cvarSteamTools))
	{
		Steam_SetGameDescription("Team Fortress");
	}
	#endif

	changeGamemode=0;
}

public void CacheWeapons()
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, WeaponCFG);
	
	if(!FileExists(config))
	{
		LogError("[FF2] Freak Fortress 2 disabled-can not find '%s'!", WeaponCFG);
		Enabled2=false;
		return;
	}
	
	kvWeaponMods = CreateKeyValues("Weapons");
	if(!FileToKeyValues(kvWeaponMods, config))
	{
		LogError("[FF2] Freak Fortress 2 disabled-'%s' is improperly formatted!", WeaponCFG);
		Enabled2=false;
		return;
	}
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
			LogError("[FF2] Freak Fortress 2 disabled-please move '%s' from '%s' to '%s'!", CharsetCFG, ConfigPath, DataPath);
		else
			LogError("[FF2] Freak Fortress 2 disabled-can not find '%s!", CharsetCFG);
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
			LogError("[FF2 Bosses] Invalid chances string, disregarding chances");
			strcopy(ChancesString, sizeof(ChancesString), "");
			amount=0;
		}

		chances[0]=StringToInt(stringChances[0]);
		chances[1]=StringToInt(stringChances[1]);
		for(chancesIndex=2; chancesIndex<amount; chancesIndex++)
		{
			if(chancesIndex % 2)
			{
				if(StringToInt(stringChances[chancesIndex])<=0)
				{
					LogError("[FF2 Bosses] Character %i cannot have a zero or negative chance, disregarding chances", chancesIndex-1);
					strcopy(ChancesString, sizeof(ChancesString), "");
					break;
				}
				chances[chancesIndex]=StringToInt(stringChances[chancesIndex])+chances[chancesIndex-2];
			}
			else
			{
				chances[chancesIndex]=StringToInt(stringChances[chancesIndex]);
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
	char extensions[][]={".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy"};
	char config[PLATFORM_MAX_PATH];

	//BuildPath(Path_SM, config, sizeof(config), "configs/freak_fortress_2/%s.cfg", character);
	BuildPath(Path_SM, config, sizeof(config), "%s/%s.cfg", ConfigPath, character);
	if(!FileExists(config))
	{
		LogError("[FF2 Bosses] Character %s does not exist!", character);
		return;
	}
	BossKV[Specials]=CreateKeyValues("character");
	FileToKeyValues(BossKV[Specials], config);

	int version=KvGetNum(BossKV[Specials], "version", 1);
	if(version!=StringToInt(MAJOR_REVISION) && version!=99) // 99 for bosses made ONLY for this fork
	{
		LogError("[FF2 Bosses] Character %s is only compatible with FF2 v%i!", character, version);
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
				LogError("[FF2 Bosses] Character %s needs plugin %s!", character, plugin_name);
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
	bBlockVoice[Specials]=view_as<bool>(KvGetNum(BossKV[Specials], "sound_block_vo", 0));
	BossSpeed[Specials]=KvGetFloat(BossKV[Specials], "maxspeed", 340.0);
	//BossRageDamage[Specials]=KvGetFloat(BossKV[Specials], "ragedamage", 1900.0);
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
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, config);
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
					else
					{
						if(StrContains(key, ".phy")==-1)
						{
							LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, key);
						}
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
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, key);
				}
				Format(key, sizeof(key), "%s.vmt", config);
				if(FileExists(key, true))
				{
					AddFileToDownloadsTable(key);
				}
				else
				{
					LogError("[FF2 Bosses] Character %s is missing file '%s'!", character, key);
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
					LogError("[FF2 Bosses] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
				}
			}
		}
		else if(StrEqual(section, "mod_precache") || !StrContains(section, "sound_") || StrEqual(section, "catch_phrase"))
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
						LogError("[FF2 Bosses] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
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
						LogError("[FF2 Bosses] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
					}
				}
			}
		}
	}
}

public void CvarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar==cvarAnnounce)
	{
		Announce=StringToFloat(newValue);
	}
	else if(convar==cvarArenaRounds)
	{
		arenaRounds=StringToInt(newValue);
	}
	else if(convar==cvarCircuitStun)
	{
		circuitStun=StringToFloat(newValue);
	}
	else if(convar==cvarLastPlayerGlow)
	{
		lastPlayerGlow=StringToInt(newValue);
	}
	else if(convar==cvarSpecForceBoss)
	{
		SpecForceBoss=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarBossTeleporter)
	{
		bossTeleportation=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarShieldCrits)
	{
		shieldCrits=StringToInt(newValue);
	}
	else if(convar==cvarCaberDetonations)
	{
		allowedDetonations=StringToInt(newValue);
	}
	else if(convar==cvarGoombaDamage)
	{
		GoombaDamage=StringToFloat(newValue);
	}
	else if(convar==cvarGoombaRebound)
	{
		reboundPower=StringToFloat(newValue);
	}
	else if(convar==cvarSniperDamage)
	{
		SniperDamage=StringToFloat(newValue);
	}
	else if(convar==cvarSniperMiniDamage)
	{
		SniperMiniDamage=StringToFloat(newValue);
	}
	else if(convar==cvarBowDamage)
	{
		BowDamage=StringToFloat(newValue);
	}
	else if(convar==cvarBowDamageNon)
	{
		BowDamageNon=StringToFloat(newValue);
	}
	else if(convar==cvarBowDamageMini)
	{
		BowDamageMini=StringToFloat(newValue);
	}
	else if(convar==cvarSniperClimbDamage)
	{
		SniperClimbDamage=StringToFloat(newValue);
	}
	else if(convar==cvarSniperClimbDelay)
	{
		SniperClimbDelay=StringToFloat(newValue);
	}
	else if(convar==cvarQualityWep)
	{
		QualityWep=StringToInt(newValue);
	}
	else if(convar==cvarBossRTD)
	{
		canBossRTD=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarPointsInterval)
	{
		PointsInterval=StringToInt(newValue);
		PointsInterval2=StringToFloat(newValue);
	}
	else if(convar==cvarPointsDamage)
	{
		PointsDamage=StringToInt(newValue);
	}
	else if(convar==cvarPointsMin)
	{
		PointsMin=StringToInt(newValue);
	}
	else if(convar==cvarPointsExtra)
	{
		PointsExtra=StringToInt(newValue);
	}
	else if(convar==cvarAnnotations)
	{
		Annotations=StringToInt(newValue);
	}
	else if(convar==cvarTellName)
	{
		TellName=view_as<bool>(StringToInt(newValue));
	}
	else if(convar==cvarUpdater)
	{
		#if defined _updater_included && !defined FORK_DEV_REVISION
		GetConVarInt(cvarUpdater) ? Updater_AddPlugin(UPDATE_URL) : Updater_RemovePlugin();
		#endif
	}
	else if(convar==cvarEnabled)
	{
		StringToInt(newValue) ? (changeGamemode=Enabled ? 0 : 1) : (changeGamemode=!Enabled ? 0 : 2);
	}
}
/* TODO: Re-enable in 2.0.0
#if defined _smac_included
public Action:SMAC_OnCheatDetected(int client, const char module[], DetectionType type, Handle info)
{
	Debug("SMAC: Cheat detected!");
	if(type==Detection_CvarViolation)
	{
		Debug("SMAC: Cheat was a cvar violation!");
		char cvar[PLATFORM_MAX_PATH];
		KvGetString(info, "cvar", cvar, sizeof(cvar));
		Debug("Cvar was %s", cvar);
		if((StrEqual(cvar, "sv_cheats") || StrEqual(cvar, "host_timescale")) && !(FF2flags[Boss[client]] & FF2FLAG_CHANGECVAR))
		{
			Debug("SMAC: Ignoring violation");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
#endif
*/
public Action Timer_Announce(Handle timer)
{
	static int announcecount=-1;
	announcecount++;
	if(Announce>1.0 && Enabled2)
	{
		switch(announcecount)
		{
			case 1:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "ServerAd");
			}
			case 2:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_last_update", PLUGIN_VERSION, ff2versiondates[maxVersion]);
			}
			case 3:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "ClassicAd");
			}
			case 4:
			{
				if(GetConVarBool(cvarToggleBoss))	// Toggle Command?
				{
					CPrintToChatAll("{olive}[FF2]{default} %t", "FF2 Toggle Command");
				}
				else					// Guess not, play the 4th thing and next is 5
				{
					announcecount=5;
					CPrintToChatAll("{olive}[FF2]{default} %t", "DevAd", PLUGIN_VERSION);
				}
			}
			case 5:
			{
				CPrintToChatAll("{olive}[FF2]{default} %t", "DevAd", PLUGIN_VERSION);
			}
			case 6:
			{
				if(GetConVarBool(cvarDuoBoss))		// Companion Toggle?
				{
					CPrintToChatAll("{olive}[FF2]{default} %t", "FF2 Companion Command");
				}
				else					// Guess not either, play the last thing and next is 0
				{
					announcecount=0;
					CPrintToChatAll("{olive}[FF2]{default} %t", "type_ff2_to_open_menu");
				}
			}
			default:
			{
				announcecount=0;
				CPrintToChatAll("{olive}[FF2]{default} %t", "type_ff2_to_open_menu");
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
			LogError("[FF2] Please move '%s' from '%s' to '%s'! Disabling Plugin!", MapCFG, ConfigPath, DataPath);
		}
		else
		{
			LogError("[FF2] Unable to find %s, disabling plugin.", config);
		}
		return false;
	}

	Handle file=OpenFile(config, "r");
	if(file==INVALID_HANDLE)
	{
		LogError("[FF2] Error reading maps from %s, disabling plugin.", config);
		return false;
	}

	int tries;
	while(ReadFileLine(file, config, sizeof(config)) && tries<100)
	{
		tries++;
		if(tries==100)
		{
			LogError("[FF2] Breaking infinite loop when trying to check the map.");
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
				Debug("Detected Map Music");
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
			LogError("[FF2] Please move '%s' from '%s' to '%s'!", DoorCFG, ConfigPath, DataPath);
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

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
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
		if(steamtools && GetConVarBool(cvarSteamTools))
		{
			Steam_SetGameDescription("Team Fortress");
		}
		#endif
		Enabled2=false;
	}

	Enabled=Enabled2;
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	if(FileExists("bNextMapToFF2"))
	{
		DeleteFile("bNextMapToFF2");
	}

	currentBossTeam=GetRandomInt(1,2);
	switch(GetConVarInt(cvarForceBossTeam))
	{
		case 1:
		{
			blueBoss=view_as<bool>(GetRandomInt(0, 1));
		}
		case 2:
		{
			blueBoss=false;
		}
		default:
		{
			blueBoss=true;
		}
	}

	if(blueBoss)
	{
		SetTeamScore(view_as<int>(TFTeam_Red), GetTeamScore(OtherTeam));
		SetTeamScore(view_as<int>(TFTeam_Blue), GetTeamScore(BossTeam));
		OtherTeam=view_as<int>(TFTeam_Red);
		BossTeam=view_as<int>(TFTeam_Blue);
	}
	else
	{
		SetTeamScore(view_as<int>(TFTeam_Red), GetTeamScore(BossTeam));
		SetTeamScore(view_as<int>(TFTeam_Blue), GetTeamScore(OtherTeam));
		OtherTeam=view_as<int>(TFTeam_Blue);
		BossTeam=view_as<int>(TFTeam_Red);
	}

	playing=0;
	for(int client=1; client<=MaxClients; client++)
	{
		Damage[client]=0;
		Healing[client]=0;
		uberTarget[client]=-1;
		emitRageSound[client]=true;
		AirstrikeDamage[client]=0.0;
		KillstreakDamage[client]=0.0;
		if(IsValidClient(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
		{
			playing++;
		}
	}

	if(GetClientCount()<=1 || playing<=1)  //Not enough players D:
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "needmoreplayers");
		SetConVarString(hostName, oldName);
		Enabled=false;
		DisableSubPlugins();
		SetControlPoint(true);
		return Plugin_Continue;
	}
	else if(RoundCount<arenaRounds)  //We're still in arena mode
	{
		CPrintToChatAll("{olive}[FF2]{default} %t", "arena_round", arenaRounds-RoundCount);
		Enabled=false;
		DisableSubPlugins();
		SetArenaCapEnableTime(60.0);
		CreateTimer(71.0, Timer_EnableCap, _, TIMER_FLAG_NO_MAPCHANGE);
		bool toRed;
		TFTeam team;
		for(int client; client<=MaxClients; client++)
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
				toRed=!toRed;
			}
		}
		return Plugin_Continue;
	}

	for(int client; client<=MaxClients; client++)
	{
		Boss[client]=0;
		if(IsValidClient(client) && IsPlayerAlive(client) && !(FF2flags[client] & FF2FLAG_HASONGIVED))
		{
			TF2_RespawnPlayer(client);
		}
	}

	Enabled=true;
	EnableSubPlugins();
	CheckArena();

	bool[] omit = new bool[MaxClients+1];
	Boss[0]=GetClientWithMostQueuePoints(omit);
	omit[Boss[0]]=true;

	bool teamHasPlayers[TFTeam];
	for(int client=1; client<=MaxClients; client++)  //Find out if each team has at least one player on it
	{
		if(IsValidClient(client))
		{
			TFTeam team=view_as<TFTeam>(GetClientTeam(client));
			if(team>TFTeam_Spectator)
			{
				teamHasPlayers[team]=true;
			}

			if(teamHasPlayers[TFTeam_Blue] && teamHasPlayers[TFTeam_Red])
			{
				break;
			}
		}
	}

	if(!teamHasPlayers[TFTeam_Blue] || !teamHasPlayers[TFTeam_Red])  //If there's an empty team make sure it gets populated
	{
		if(IsValidClient(Boss[0]) && GetClientTeam(Boss[0])!=BossTeam)
		{
			AssignTeam(Boss[0], BossTeam);
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !IsBoss(client) && GetClientTeam(client)!=OtherTeam)
			{
				CreateTimer(0.1, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		return Plugin_Continue;  //NOTE: This is needed because OnRoundStart gets fired a second time once both teams have players
	}

	PickCharacter(0, 0);
	if((Special[0]<0) || !BossKV[Special[0]])
	{
		LogError("[FF2 Bosses] Couldn't find a boss!");
		return Plugin_Continue;
	}

	Companions=0;
	FindCompanion(0, playing, omit);  //Find companions for the boss!

	for(int boss; boss<=MaxClients; boss++)
	{
		BossInfoTimer[boss][0]=INVALID_HANDLE;
		BossInfoTimer[boss][1]=INVALID_HANDLE;
		if(Boss[boss])
		{
			CreateTimer(0.3, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
			BossInfoTimer[boss][0]=CreateTimer(30.2, BossInfoTimer_Begin, boss, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	CreateTimer(0.4, StartIntroMusicTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(3.5, StartResponseTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.1, StartBossTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.6, MessageTimer, _, TIMER_FLAG_NO_MAPCHANGE);

	for(int entity=MaxClients+1; entity<MAXENTITIES; entity++)
	{
		if(!IsValidEntity(entity))
		{
			continue;
		}

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
		for(int client=1;client<=MaxClients;client++)
		{
			if(!IsValidClient(client))
			{
				continue;
			}
		
			ClientQueue[client][0] = client;
			ClientQueue[client][1] = GetClientQueuePoints(client);
		}
		
		SortCustom2D(ClientQueue, sizeof(ClientQueue), SortQueueDesc);
		
		for(int client=1;client<=MaxClients;client++)
		{
			if(!IsValidClient(client))
			{
				continue;
			}

			ClientID[client] = ClientQueue[client][0];
			ClientPoint[client] = ClientQueue[client][1];
			
			if(ClientCookie[client] == TOGGLE_ON)
			{
				int index = -1;
				for(int i = 1; i < MAXPLAYERS+1; i++)
				{
					if(ClientID[i] == client)
					{
						index = i;
						break;
					}
				}
				if(index > 0)
				{
					CPrintToChat(client, "{olive}[FF2]{default} %t", "FF2 Toggle Queue Notification", index, ClientPoint[index]);
				}
				else
				{
					CPrintToChat(client, "{olive}[FF2]{default} %t", "FF2 Toggle Enabled Notification");
   				}
			}
			else if(ClientCookie[client] == TOGGLE_OFF || ClientCookie[client] == TOGGLE_TEMP)
			{
				//SetClientQueuePoints(client, -15);
				char nick[64];
				GetClientName(client, nick, sizeof(nick));
				if(ClientCookie[client] == TOGGLE_OFF)
				{
					CPrintToChat(client, "{olive}[FF2]{default} %t", "FF2 Toggle Disabled Notification");
				}
				else
				{
					CPrintToChat(client, "{olive}[FF2]{default} %t", "FF2 Toggle Disabled Notification For Map");
				}
			}
			else if(ClientCookie[client] == TOGGLE_UNDEF || !ClientCookie[client])
			{
				char nick[64];
				GetClientName(client, nick, sizeof(nick));
				Handle clientPack = CreateDataPack();
				WritePackCell(clientPack, client);
				CreateTimer(GetConVarFloat(cvarFF2TogglePrefDelay), BossMenuTimer, clientPack);
			}
		}
	}

	if(GetConVarBool(cvarNameChange))
	{
		char newName[256], bossName[64];
		SetConVarString(hostName, oldName);
		KvGetString(BossKV[Special[0]], "name", bossName, sizeof(bossName));
		Format(newName, sizeof(newName), "%s | %s", oldName, bossName);
		SetConVarString(hostName, newName);
	}

	healthcheckused=0;
	firstBlood=true;
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
	Companions=0;
	SapperMinion=false;
	LastMan=true;
	if(HasSwitched)
		HasSwitched=false;

	if(playing>=GetConVarInt(cvarDuoMin) && !DuoMin)  // Check if theres enough players for companions
	{
		DuoMin=true;
	}
	else if(playing<GetConVarInt(cvarDuoMin) && DuoMin)
	{
		DuoMin=false;
	}

	if(!Enabled)
	{
		return Plugin_Continue;
	}

	if(GetConVarInt(cvarBossLog)>0 && GetConVarInt(cvarBossLog)<=playing)
	{
		int nonbots=0;
		for(int clients; clients<=MaxClients; clients++)
		{
			if(IsValidClient(clients))
			{
				if(!IsBoss(clients) && !IsFakeClient(clients))
					nonbots++;
			}
		}

		if(GetConVarInt(cvarBossLog)<=nonbots)
		{
			// Variables
			char bossName[64], FormatedTime[64], MapName[64], Result[64], PlayerName[64], Authid[64];

			// Set variables
			int CurrentTime = GetTime();
			FormatTime(FormatedTime, 100, "%X", CurrentTime);
			GetCurrentMap(MapName, sizeof(MapName));
			Format(Result, sizeof(Result), GetEventInt(event, "team")==BossTeam ? "won" : "loss");
			for(int client; client<=MaxClients; client++)
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
	}

	if(ReloadFF2)
	{
		ServerCommand("sm plugins reload freak_fortress_2");
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
		FindCharacters();
		ReloadConfigs=false;
	}

	executed=false;
	executed2=false;
	bool bossWin=false;
	char sound[PLATFORM_MAX_PATH];
	if((GetEventInt(event, "team")==BossTeam))
	{
		bossWin=true;
		if(RandomSound("sound_win", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
		}
		if(RandomSound("sound_outtromusic_win", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, _, _, _, _, _, _, _, false);
		}
		else if(RandomSound("sound_outtromusic", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, _, _, _, _, _, _, _, false);
		}
	}
	else if((GetEventInt(event, "team")==OtherTeam))
	{
		if(RandomSound("sound_outtromusic_lose", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, _, _, _, _, _, _, _, false);
		}
		else if(RandomSound("sound_outtromusic", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, _, _, _, _, _, _, _, false);
		}
	}
	else
	{
		if(RandomSound("sound_outtromusic_stalemate", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, _, _, _, _, _, _, _, false);
		}
		else if(RandomSound("sound_outtromusic_lose", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, _, _, _, _, _, _, _, false);
		}
		else if(RandomSound("sound_outtromusic", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, _, _, _, _, _, _, _, false);
		}
	}

	StopMusic();
	DrawGameTimer=INVALID_HANDLE;

	bool isBossAlive;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]))
		{
			SetClientGlow(Boss[boss], 0.0, 0.0);
			SDKUnhook(boss, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal
			if(IsPlayerAlive(Boss[boss]))
			{
				isBossAlive=true;
			}

			for(int slot=1; slot<8; slot++)
			{
				BossCharge[boss][slot]=0.0;
			}
			bossHasReloadAbility[boss]=false;
			bossHasRightMouseAbility[boss]=false;
		}
		else if(IsValidClient(boss))  //Boss here is actually a client index
		{
			SetClientGlow(boss, 0.0, 0.0);
			hadshield[boss]=false;
			shield[boss]=0;
			detonations[boss]=0;
			AirstrikeDamage[boss]=0.0;
			KillstreakDamage[boss]=0.0;
			SapperCooldown[boss]=0.0;
		}

		for(int timer; timer<=1; timer++)
		{
			if(BossInfoTimer[boss][timer]!=INVALID_HANDLE)
			{
				KillTimer(BossInfoTimer[boss][timer]);
				BossInfoTimer[boss][timer]=INVALID_HANDLE;
			}
		}
	}

	int boss;
	if(isBossAlive)
	{
		char text[128], bossName[64], lives[8];
		for(int target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				boss=Boss[target];
				KvRewind(BossKV[Special[boss]]);
				KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "=Failed name=");
				BossLives[boss]>1 ? Format(lives, sizeof(lives), "x%i", BossLives[boss]) : strcopy(lives, 2, "");
				Format(text, sizeof(text), "%s\n%t", text, "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
				CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
			}
		}

		SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
		for(int client; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				FF2_ShowHudText(client, -1, "%s", text);
			}
		}

		if(!bossWin && RandomSound("sound_fail", sound, sizeof(sound), boss))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
		}
	}

	int top[3];
	Damage[0]=0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || Damage[client]<=0 || IsBoss(client))
		{
			continue;
		}

		if(Damage[client]>=Damage[top[0]])
		{
			top[2]=top[1];
			top[1]=top[0];
			top[0]=client;
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
			top[i]=0;
		}
	}

	SetHudTextParams(-1.0, 0.3, 10.0, 255, 255, 255, 255);
	PrintCenterTextAll("");

	char text[128];
	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			//TODO:  Clear HUD text here
			if(IsBoss(client))
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], (bossWin ? "boss_win" : "boss_lose"));
			}
			else
			{
				FF2_ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "damage_fx", Damage[client], "scores", RoundFloat(Damage[client]/PointsInterval2));
			}
		}
	}

	CreateTimer(3.0, Timer_CalcQueuePoints, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Continue;
}

public Action OnPlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	if(playing>=GetConVarInt(cvarDuoMin) && !DuoMin)  // Check if theres enough players for companions
	{
		DuoMin=true;
	}
	else if(playing<GetConVarInt(cvarDuoMin) && DuoMin)
	{
		DuoMin=false;
	}
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	xIncoming[client] = "";
	return Plugin_Continue;
}

public Action BossMenuTimer(Handle timer, any clientpack)
{
	int clientId;
	ResetPack(clientpack);
	clientId = ReadPackCell(clientpack);
	CloseHandle(clientpack);
	if(ClientCookie[clientId] == TOGGLE_UNDEF)
	{
		BossMenu(clientId, 0);
	}
}

// Companion Menu
public Action CompanionMenu(int client, int args)
{
	if(IsValidClient(client) && GetConVarBool(cvarDuoBoss))
	{
		CPrintToChat(client, "{olive}[FF2]{default} %t", "FF2 Companion Toggle Menu Title", ClientCookie2[client]);

		char sEnabled[2];
		GetClientCookie(client, CompanionCookie, sEnabled, sizeof(sEnabled));
		ClientCookie2[client] = StringToInt(sEnabled);	

		Handle menu = CreateMenu(MenuHandlerCompanion);
		SetMenuTitle(menu, "%T", "FF2 Companion Toggle Menu Title", client, ClientCookie2[client]);

		char menuoption[128];
		Format(menuoption, sizeof(menuoption), "%T", "Enable Companion Selection", client);
		AddMenuItem(menu, "FF2 Companion Toggle Menu", menuoption);
		Format(menuoption, sizeof(menuoption), "%T", "Disable Companion Selection", client);
		AddMenuItem(menu, "FF2 Companion Toggle Menu", menuoption);
		Format(menuoption, sizeof(menuoption), "%T", "Disable Companion Selection For Map", client);
		AddMenuItem(menu, "FF2 Companion Toggle Menu", menuoption);

		SetMenuExitButton(menu, true);

		DisplayMenu(menu, client, 20);
	}
	return Plugin_Handled;
}

public int MenuHandlerCompanion(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char sEnabled[2];
		int choice = param2 + 1;

		ClientCookie2[param1] = choice;
		IntToString(choice, sEnabled, sizeof(sEnabled));

		SetClientCookie(param1, CompanionCookie, sEnabled);

		if(1 == choice)
		{
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "FF2 Companion Enabled");
		}
		else if(2 == choice)
		{
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "FF2 Companion Disabled");
		}
		else if(3 == choice)
		{
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "FF2 Companion Disabled For Map");
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// Boss menu
public Action BossMenu(int client, int args)
{
	if(IsValidClient(client) && GetConVarBool(cvarToggleBoss))
	{
		CPrintToChat(client, "{olive}[FF2]{default} %t", "FF2 Toggle Menu Title", ClientCookie[client]);
		char sEnabled[2];
		GetClientCookie(client, BossCookie, sEnabled, sizeof(sEnabled));
		ClientCookie[client] = StringToInt(sEnabled);

		Handle menu = CreateMenu(MenuHandlerBoss);
		SetMenuTitle(menu, "%T", "FF2 Toggle Menu Title", client, ClientCookie[client]);

		char menuoption[128];
		Format(menuoption, sizeof(menuoption), "%T", "Enable Queue Points", client);
		AddMenuItem(menu, "Boss Toggle", menuoption);
		Format(menuoption, sizeof(menuoption), "%T", "Disable Queue Points", client);
		AddMenuItem(menu, "Boss Toggle", menuoption);
		Format(menuoption, sizeof(menuoption), "%T", "Disable Queue Points For This Map", client);
		AddMenuItem(menu, "Boss Toggle", menuoption);

		SetMenuExitButton(menu, true);

		DisplayMenu(menu, client, 20);
	}
	return Plugin_Handled;
}

public int MenuHandlerBoss(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		char sEnabled[2];
		int choice = param2 + 1;

		ClientCookie[param1] = choice;
		IntToString(choice, sEnabled, sizeof(sEnabled));

		SetClientCookie(param1, BossCookie, sEnabled);
		
		if(1 == choice)
		{
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "FF2 Toggle Enabled Notification");
		}
		else if(2 == choice)
		{
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "FF2 Toggle Disabled Notification");
		}
		else if(3 == choice)
		{
			CPrintToChat(param1, "{olive}[FF2]{default} %t", "FF2 Toggle Disabled Notification For Map");
		}
	} 
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
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
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, _, _, _, _, _, _, _, false);
	EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, "saxton_hale/9000.wav", _, SNDCHAN_VOICE, _, _, _, _, _, _, _, false);
	return Plugin_Continue;
}

public Action Timer_CalcQueuePoints(Handle timer)
{
	int damage, damage2;
	botqueuepoints+=5;
	int[] add_points = new int[MaxClients+1];
	int[] add_points2 = new int[MaxClients+1];
	for(int client=1; client<=MaxClients; client++)
	{
		if((ClientCookie[client] == TOGGLE_OFF || ClientCookie[client] == TOGGLE_TEMP) && GetConVarBool(cvarToggleBoss)) // Do not give queue points to those who have ff2 bosses disabled
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
				if(IsFakeClient(client))
				{
					botqueuepoints=0;
				}
				else if((GetBossIndex(client)==0 && GetConVarBool(cvarDuoRestore)) || !GetConVarBool(cvarDuoRestore))
				{
					add_points[client]=-GetClientQueuePoints(client);
					add_points2[client]=add_points[client];
				}
			}
			else if(!IsFakeClient(client) && (GetClientTeam(client)>view_as<int>(TFTeam_Spectator) || SpecForceBoss))
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
					if(add_points2[client]>0)
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "add_points", add_points2[client]);
					}
					SetClientQueuePoints(client, GetClientQueuePoints(client)+add_points2[client]);
				}
			}
		}
		default:
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsValidClient(client))
				{
					if(add_points[client]>0)
					{
						CPrintToChat(client, "{olive}[FF2]{default} %t", "add_points", add_points[client]);
					}
					SetClientQueuePoints(client, GetClientQueuePoints(client)+add_points[client]);
				}
			}
		}
	}
}

public Action StartResponseTimer(Handle timer)
{
	char sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_begin", sound, sizeof(sound)))
	{
		EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
		EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
	}
	return Plugin_Continue;
}

public Action StartIntroMusicTimer(Handle timer)
{
	char sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_intromusic", sound, sizeof(sound)))
	{
		EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, _, _, _, _, _, _, _, false);
		EmitSoundToAllExcept(SOUNDEXCEPT_MUSIC, sound, _, _, _, _, _, _, _, _, _, false);
	}
	return Plugin_Continue;
}

public Action StartBossTimer(Handle timer)
{
	CreateTimer(0.1, Timer_Move, _, TIMER_FLAG_NO_MAPCHANGE);
	bool isBossAlive;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			isBossAlive=true;
			SetEntityMoveType(Boss[boss], MOVETYPE_NONE);
		}
	}

	if(!isBossAlive)
	{
		return Plugin_Continue;
	}

	playing=0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			CreateTimer(2.0, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			if(!IsBoss(client) && IsPlayerAlive(client))
			{
				playing++;
				CreateTimer(0.15, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);  //TODO:  Is this needed?
			}
		}
	}

	int playing2=playing+1;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			BossHealthMax[boss]=ParseFormula(boss, "health_formula", "(((760.8+n)*(n-1))^1.0341)+2046", RoundFloat(Pow((760.8+float(playing2))*(float(playing2)-1.0), 1.0341)+2046.0));
			BossHealth[boss]=BossHealthMax[boss]*BossLivesMax[boss];
			BossHealthLast[boss]=BossHealth[boss];
		}
	}

	CreateTimer(0.2, BossTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, Timer_StartRound, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	if(PointType==0)
	{
		SetControlPoint(false);
	}
	return Plugin_Continue;
}

public Action Timer_PrepareBGM(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(CheckRoundState()!=1 || !client || MapHasMusic() || StrEqual(currentBGM[client], "ff2_stop_music", true))
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

		index=GetRandomInt(1, index-1);
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
			LogError("[FF2 Bosses] Character %s is missing BGM file '%s'!", bossName, temp);
			Debug("{red}MALFUNCTION! NEED INPUT!");
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
			Debug("NEED INPUT!");
			return;
		}
		case Plugin_Changed:
		{
			strcopy(music, PLATFORM_MAX_PATH, temp[0]);
			time=time2;
			Debug("OOO... INPUT! %s | %f", music, time);
		}
	}

	Format(temp[0], sizeof(temp[]), "sound/%s", music);
	if(FileExists(temp[0], true))
	{
		bool unknown1 = true;
		bool unknown2 = true;
		if(CheckSoundException(client, SOUNDEXCEPT_MUSIC))
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
		if((GetConVarInt(cvarSongInfo) == 1) || (unknown1 && unknown2 && loop && (GetConVarInt(cvarSongInfo) == 0)))
		{ 
			CPrintToChat(client, "{olive}[FF2]{default} %t", "track_info", artist, name);
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
					Debug("{green}MALFUNCTION! NEED INPUT!");
				}
				StopSound(client, SNDCHAN_AUTO, currentBGM[client]);

				if(MusicTimer[client]!=INVALID_HANDLE)
				{
					Debug("TERMINATING INPUT!");
					KillTimer(MusicTimer[client]);
					MusicTimer[client]=INVALID_HANDLE;
				}
			}

			strcopy(currentBGM[client], PLATFORM_MAX_PATH, "");
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
			Debug("{green}MALFUNCTION! NEED INPUT!");
		}
		StopSound(client, SNDCHAN_AUTO, currentBGM[client]);
		StopSound(client, SNDCHAN_AUTO, currentBGM[client]);

		if(MusicTimer[client]!=INVALID_HANDLE)
		{
			Debug("END INPUT FOR %N!", client);
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

stock void EmitSoundToAllExcept(int exceptiontype=SOUNDEXCEPT_MUSIC, const char[] sample, int entity=SOUND_FROM_PLAYER, int channel=SNDCHAN_AUTO, int level=SNDLEVEL_NORMAL, int flags=SND_NOFLAGS, float volume=SNDVOL_NORMAL, int pitch=SNDPITCH_NORMAL, int speakerentity=-1, const float origin[3]=NULL_VECTOR, const float dir[3]=NULL_VECTOR, bool updatePos=true, float soundtime=0.0)
{
	int[] clients = new int[MaxClients];
	int total;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsClientInGame(client))
		{
			if(CheckSoundException(client, exceptiontype))
			{
				clients[total++]=client;
			}
		}
	}

	if(!total)
	{
		return;
	}

	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

stock bool CheckSoundException(int client, char soundException)
{
	if(!IsValidClient(client))
	{
		return false;
	}

	if(IsFakeClient(client) || !AreClientCookiesCached(client))
	{
		return true;
	}

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	if(soundException==SOUNDEXCEPT_VOICE)
	{
		return StringToInt(cookieValues[2])==1;
	}
	return StringToInt(cookieValues[1])==1;
}

void SetClientSoundOptions(int client, char soundException, bool enable)
{
	if(!IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client))
	{
		return;
	}

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	if(soundException==SOUNDEXCEPT_VOICE)
	{
		if(enable)
		{
			cookieValues[2][0]='1';
		}
		else
		{
			cookieValues[2][0]='0';
		}
	}
	else
	{
		if(enable)
		{
			cookieValues[1][0]='1';
		}
		else
		{
			cookieValues[1][0]='0';
		}
	}
	Format(cookies, sizeof(cookies), "%s %s %s %s %s %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[3], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
	SetClientCookie(client, FF2Cookies, cookies);
}

public Action Command_YouAreNext(int client, int args)
{
	if(!Enabled || !IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(IsVoteInProgress())
	{
		CreateTimer(5.0, Timer_RetryBossNotify, client);
		return Plugin_Handled;
	}
	
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	char texts[256];
	Handle panel = CreatePanel();

	Format(texts, sizeof(texts), "%T\n%T", "to0_next", client, "to0_near", client);
	CRemoveTags(texts, sizeof(texts));

	ReplaceString(texts, sizeof(texts), "{olive}", "");
	ReplaceString(texts, sizeof(texts), "{default}", "");
	
	SetPanelTitle(panel, texts);
	
	Format(texts, sizeof(texts), "%T", "to0_to0_next", client);
	DrawPanelItem(panel, texts);
	
	SendPanelToClient(panel, client, SkipBossPanelH, 30);

	CloseHandle(panel);

	return Plugin_Handled;
}

public Action Timer_RetryBossNotify(Handle timer, any client)
{
	Command_YouAreNext(client, 0);
}

public int SkipBossPanelH(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(menu);
		case MenuAction_Select:
		{
			Command_SetMyBoss(param1, 0);
		}
	}
	return;
}

public Action Command_SetMyBoss(int client, int args)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!GetConVarBool(cvarSelectBoss))
	{
		// No reply because, disabled msg and another plugin's menu shows?
		return Plugin_Handled;
	}
	
	if (!CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}

	if(args)
	{
		char name[64], boss[64], companionName[64];
		GetCmdArgString(name, sizeof(name));
		
		for(int config; config<Specials; config++)
		{
			KvRewind(BossKV[config]);
			KvGetString(BossKV[config], "companion", companionName, sizeof(companionName));
			KvGetString(BossKV[config], "name", boss, sizeof(boss));
			if(KvGetNum(BossKV[config], "blocked", 0)) continue;
			if(KvGetNum(BossKV[config], "hidden", 0)) continue;
			if(KvGetNum(BossKV[config], "admin", 0) && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) continue;
			if(KvGetNum(BossKV[config], "owner", 0) && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true)) continue;
			if(StrContains(boss, name, false)!=-1)
			{
				if(KvGetNum(BossKV[config], "donator", 0) && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true))
				{
					CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_donator");
					return Plugin_Handled;
				}
				if(KvGetNum(BossKV[config], "nofirst", 0) && (RoundCount<arenaRounds || (RoundCount==arenaRounds && CheckRoundState()!=1)))
				{
					CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_nofirst");
					return Plugin_Handled;
				}
				if(strlen(companionName) && !DuoMin)
				{
					CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_duo_short");
					return Plugin_Handled;
				}
				if(strlen(companionName) && (ClientCookie2[client]==TOGGLE_OFF || ClientCookie2[client]==TOGGLE_TEMP) && GetConVarBool(cvarDuoBoss))
				{
					CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_duo_off");
					return Plugin_Handled;
				}
				if(BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_ROOT, true))
				{
					CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_donator");
					return Plugin_Handled;
				}
				if(AreClientCookiesCached(client) && GetConVarInt(cvarKeepBoss)<0)
				{
					char cookie[64];
					GetClientCookie(client, LastPlayedCookie, cookie, sizeof(cookie));
					if(StrEqual(boss, cookie, false))
					{
						CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_recent");
						return Plugin_Handled;
					}
				}
				IsBossSelected[client]=true;
				strcopy(xIncoming[client], sizeof(xIncoming[]), boss);
				CReplyToCommand(client, "%t", "to0_boss_selected", boss);
				return Plugin_Handled;
			}

			KvGetString(BossKV[config], "filename", boss, sizeof(boss));
			if(StrContains(boss, name, false)!=-1)
			{
				if(KvGetNum(BossKV[config], "donator", 0) && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true))
				{
					CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_donator");
					return Plugin_Handled;
				}
				if(KvGetNum(BossKV[config], "nofirst", 0) && (RoundCount<arenaRounds || (RoundCount==arenaRounds && CheckRoundState()!=1)))
				{
					CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_nofirst");
					return Plugin_Handled;
				}
				if(strlen(companionName) && !DuoMin)
				{
					CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_duo_short");
					return Plugin_Handled;
				}
				if(strlen(companionName) && (ClientCookie2[client]==TOGGLE_OFF || ClientCookie2[client]==TOGGLE_TEMP) && GetConVarBool(cvarDuoBoss))
				{
					CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_duo_off");
					return Plugin_Handled;
				}
				if(BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_ROOT, true))
				{
					CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_donator");
					return Plugin_Handled;
				}
				KvGetString(BossKV[config], "name", boss, sizeof(boss));
				if(AreClientCookiesCached(client) && GetConVarInt(cvarKeepBoss)<0)
				{
					char cookie[64];
					GetClientCookie(client, LastPlayedCookie, cookie, sizeof(cookie));
					if(StrEqual(boss, cookie, false))
					{
						CReplyToCommand(client, "{olive}[FF2]{default} %t", "deny_recent");
						return Plugin_Handled;
					}
				}
				IsBossSelected[client]=true;
				strcopy(xIncoming[client], sizeof(xIncoming[]), boss);
				CReplyToCommand(client, "%t", "to0_boss_selected", boss);
				return Plugin_Handled;
			}
		}
		CReplyToCommand(client, "{olive}[FF2]{default} Boss could not be found!");
		return Plugin_Handled;
	}

	char boss[64];
	Handle dMenu = CreateMenu(Command_SetMyBossH);

	SetMenuTitle(dMenu, "%T", "ff2_boss_selection", client, xIncoming[client]);
	
	Format(boss, sizeof(boss), "%T", "to0_random", client);
	AddMenuItem(dMenu, boss, boss);
	
	if(GetConVarBool(cvarToggleBoss))
	{
		if(ClientCookie[client] == TOGGLE_ON || ClientCookie[client] == TOGGLE_UNDEF)
			Format(boss, sizeof(boss), "%T", "to0_disablepts", client);

		else
			Format(boss, sizeof(boss), "%T", "to0_enablepts", client);

		AddMenuItem(dMenu, boss, boss);
	}
	if(GetConVarBool(cvarDuoBoss))
	{
		if(ClientCookie2[client] == TOGGLE_ON || ClientCookie2[client] == TOGGLE_UNDEF)
			Format(boss, sizeof(boss), "%T", "to0_disableduo", client);

		else
			Format(boss, sizeof(boss), "%T", "to0_enableduo", client);

		AddMenuItem(dMenu, boss, boss);
	}
	#if defined _freak_fortress_2_kstreak_included
	if(kmerge && CheckCommandAccess(client, "ff2_kstreak_a", 0, true))
	{
		if(FF2_KStreak_GetCookies(client, 0)==1)
			Format(boss, sizeof(boss), "%T", "to0_disablekstreak", client);
		else if(FF2_KStreak_GetCookies(client, 0)<1)
			Format(boss, sizeof(boss), "%T", "to0_enablekstreak", client);
		else
			Format(boss, sizeof(boss), "%T", "to0_togglekstreak", client);

		AddMenuItem(dMenu, boss, boss);
	}
	#endif
	
	for(int config; config<Specials; config++)
	{
		char companionName[64];
		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "companion", companionName, sizeof(companionName));
		if(KvGetNum(BossKV[config], "blocked", 0)) continue;
		if(KvGetNum(BossKV[config], "hidden", 0)) continue;
		if(KvGetNum(BossKV[config], "admin", 0) && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) continue;
		if(KvGetNum(BossKV[config], "owner", 0) && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true)) continue;
		
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if((KvGetNum(BossKV[config], "donator", 0) && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
		   (KvGetNum(BossKV[config], "nofirst", 0) && (RoundCount<arenaRounds || (RoundCount==arenaRounds && CheckRoundState()!=1))) ||
		   (strlen(companionName) && (!DuoMin || ((ClientCookie2[client]==TOGGLE_OFF || ClientCookie2[client]==TOGGLE_TEMP) && GetConVarBool(cvarDuoBoss)))))
		{
			AddMenuItem(dMenu, boss, boss, ITEMDRAW_DISABLED);
		}
		else if(BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_ROOT, true))
		{
			AddMenuItem(dMenu, boss, boss, ITEMDRAW_DISABLED);
		}
		else
		{
			if(AreClientCookiesCached(client) && GetConVarInt(cvarKeepBoss)<0)
			{
				char cookie[64];
				GetClientCookie(client, LastPlayedCookie, cookie, sizeof(cookie));
				if(StrEqual(boss, cookie, false))
					AddMenuItem(dMenu, boss, boss, ITEMDRAW_DISABLED);
				else
					AddMenuItem(dMenu, boss, boss);
			}
			else
				AddMenuItem(dMenu, boss, boss);
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
			switch(param2)
			{
				case 0: 
				{
					IsBossSelected[param1]=true;
					xIncoming[param1] = "";
					CReplyToCommand(param1, "%t", "to0_comfirmrandom");
					return;
				}
				case 1:
				{
					if(GetConVarBool(cvarToggleBoss))
						BossMenu(param1, 0);

					else if(GetConVarBool(cvarDuoBoss))
						CompanionMenu(param1, 0);

					#if defined _freak_fortress_2_kstreak_included
					else if(kmerge && CheckCommandAccess(param1, "ff2_kstreak_a", 0, true))
						FF2_KStreak_Menu(param1, 0);
					#endif

					else
					{
						if(!GetConVarBool(cvarBossDesc) || !GetClientClassInfoCookie(param1))
						{
							IsBossSelected[param1]=true;
							GetMenuItem(menu, param2, xIncoming[param1], sizeof(xIncoming[]));
							CReplyToCommand(param1, "%t", "to0_boss_selected", xIncoming[param1]);
						}
						else
						{
							GetMenuItem(menu, param2, cIncoming[param1], sizeof(cIncoming[]));
							ConfirmBoss(param1);
						}
					}
				}
				case 2:
				{
					if(GetConVarBool(cvarDuoBoss) && GetConVarBool(cvarToggleBoss))
						CompanionMenu(param1, 0);

					#if defined _freak_fortress_2_kstreak_included
					else if(GetConVarBool(cvarToggleBoss) && !GetConVarBool(cvarDuoBoss) && kmerge && CheckCommandAccess(param1, "ff2_kstreak_a", 0, true))
						FF2_KStreak_Menu(param1, 0);

					else if(!GetConVarBool(cvarToggleBoss) && GetConVarBool(cvarDuoBoss) && kmerge && CheckCommandAccess(param1, "ff2_kstreak_a", 0, true))
						FF2_KStreak_Menu(param1, 0);
					#endif

					else
					{
						if(!GetConVarBool(cvarBossDesc) || !GetClientClassInfoCookie(param1))
						{
							IsBossSelected[param1]=true;
							GetMenuItem(menu, param2, xIncoming[param1], sizeof(xIncoming[]));
							CReplyToCommand(param1, "%t", "to0_boss_selected", xIncoming[param1]);
						}
						else
						{
							GetMenuItem(menu, param2, cIncoming[param1], sizeof(cIncoming[]));
							ConfirmBoss(param1);
						}
					}
				}
				case 3:
				{
					#if defined _freak_fortress_2_kstreak_included
					if(GetConVarBool(cvarToggleBoss) && GetConVarBool(cvarDuoBoss) && kmerge && CheckCommandAccess(param1, "ff2_kstreak_a", 0, true))
						FF2_KStreak_Menu(param1, 0);

					else
					{
						if(!GetConVarBool(cvarBossDesc) || !GetClientClassInfoCookie(param1))
						{
							IsBossSelected[param1]=true;
							GetMenuItem(menu, param2, xIncoming[param1], sizeof(xIncoming[]));
							CReplyToCommand(param1, "%t", "to0_boss_selected", xIncoming[param1]);
						}
						else
						{
							GetMenuItem(menu, param2, cIncoming[param1], sizeof(cIncoming[]));
							ConfirmBoss(param1);
						}
					}
					#else
					if(!GetConVarBool(cvarBossDesc) || !GetClientClassInfoCookie(param1))
					{
						IsBossSelected[param1]=true;
						GetMenuItem(menu, param2, xIncoming[param1], sizeof(xIncoming[]));
						CReplyToCommand(param1, "%t", "to0_boss_selected", xIncoming[param1]);
					}
					else
					{
						GetMenuItem(menu, param2, cIncoming[param1], sizeof(cIncoming[]));
						ConfirmBoss(param1);
					}
					#endif
				}
				default:
				{
					if(!GetConVarBool(cvarBossDesc) || !GetClientClassInfoCookie(param1))
					{
						IsBossSelected[param1]=true;
						GetMenuItem(menu, param2, xIncoming[param1], sizeof(xIncoming[]));
						CReplyToCommand(param1, "%t", "to0_boss_selected", xIncoming[param1]);
					}
					else
					{
						GetMenuItem(menu, param2, cIncoming[param1], sizeof(cIncoming[]));
						ConfirmBoss(param1);
					}
				}
			}
		}
	}
	return;
}

public Action ConfirmBoss(int client)
{
	if(!GetConVarBool(cvarBossDesc))
	{
		return Plugin_Handled;
	}

	char text[512], language[20], boss[64];
	GetLanguageInfo(GetClientLanguage(client), language, 8, text, 8);
	Format(language, sizeof(language), "description_%s", language);
		
	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrContains(boss, cIncoming[client], false)!=-1)
		{
			KvRewind(BossKV[config]);
			KvGetString(BossKV[config], language, text, sizeof(text));
			if(!text[0])
			{
				KvGetString(BossKV[config], "description_en", text, sizeof(text));  //Default to English if their language isn't available
				if(!text[0])
				{
					Format(text, sizeof(text), "%T", "to0_nodesc", client);
				}
			}
			ReplaceString(text, sizeof(text), "\\n", "\n");
		}
	}

	Handle dMenu = CreateMenu(ConfirmBossH);
	SetMenuTitle(dMenu, text);

	Format(text, sizeof(text), "%T", "to0_confirm", client, cIncoming[client]);
	AddMenuItem(dMenu, text, text);

	Format(text, sizeof(text), "%T", "to0_cancel", client);
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
			switch(param2)
			{
				case 0: 
				{
					IsBossSelected[param1]=true;
					xIncoming[param1]=cIncoming[param1];
					CReplyToCommand(param1, "%t", "to0_boss_selected", xIncoming[param1]);
				}
				default:
				{
					Command_SetMyBoss(param1, 0);
				}
			}
		}
	}
	return;
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

public Action FF2_OnSpecialSelected(int boss, int &SpecialNum, char[] SpecialName, bool preset)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(preset)
	{
		if(!boss && !StrEqual(xIncoming[client], ""))
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "boss_selection_overridden");
		}
		return Plugin_Continue;
	}
	
	if(!boss && !StrEqual(xIncoming[client], ""))
	{
		strcopy(SpecialName, sizeof(xIncoming[]), xIncoming[client]);
		if(GetConVarInt(cvarKeepBoss)<1 || !GetConVarBool(cvarSelectBoss) || IsFakeClient(client))
		{
			xIncoming[client] = "";
		}
		return Plugin_Changed;
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
	{
		return -1;
	}
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
		bf=StartMessageAll("HudNotifyCustom");
	}
	else
	{
		bf = StartMessageOne("HudNotifyCustom", client);
	}

	if(bf==null)
	{
		return false;
	}

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
		{
			SetEntityMoveType(client, MOVETYPE_WALK);
		}
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
	while(clients<3)  //TODO: Make this configurable?
	{
		int client=GetClientWithMostQueuePoints(added);
		if(!IsValidClient(client))  //No more players left on the server
		{
			break;
		}

		if(!IsBoss(client))
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "to0_near");  //"You will become the Boss soon. Type {olive}/ff2next{default} to make sure."
			clients++;
		}
		added[client]=true;
	}
}

public Action MessageTimer(Handle timer)
{
	if(CheckRoundState())
	{
		return Plugin_Continue;
	}

	if(checkDoors)
	{
		int entity=-1;
		while((entity=FindEntityByClassname2(entity, "func_door"))!=-1)
		{
			AcceptEntityInput(entity, "Open");
			AcceptEntityInput(entity, "Unlock");
		}

		if(doorCheckTimer==INVALID_HANDLE)
		{
			doorCheckTimer=CreateTimer(5.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	char text[512], textChat[512], lives[8], name[64];
	for(int client; client<=MaxClients; client++)
	{
		if(IsBoss(client))
		{
			int boss=Boss[client];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", name, sizeof(name), "=Failed name=");
			if(BossLives[boss]>1)
			{
				Format(lives, sizeof(lives), "x%i", BossLives[boss]);
			}
			else
			{
				lives[0]='\0';
			}

			Format(text, sizeof(text), "%s\n%t", text, "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
			Format(textChat, sizeof(textChat), "{olive}[FF2]{default} %t!", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
			ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
			CPrintToChatAll("%s", textChat);
		}
	}

	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(!Companions && GetConVarInt(cvarGameText)==2 && !GhostBoss)
			{
				ShowGameText(client, "leaderboard_streak", _, text);
			}
			else if(!Companions && GetConVarInt(cvarGameText)==2)
			{
				ShowGameText(client, "ico_ghost", _, text);
			}
			else
			{
				FF2_ShowSyncHudText(client, infoHUD, text);
			}
		}
	}
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
	int client=Boss[boss];
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
			int strangerank=KvGetNum(BossKV[Special[boss]], "rank", 21);
			int weaponlevel=KvGetNum(BossKV[Special[boss]], "level", -1);
			int index=KvGetNum(BossKV[Special[boss]], "index");
			bool overridewep=view_as<bool>(KvGetNum(BossKV[Special[boss]], "override", 0));
			int strangekills=-1;
			int strangewep=1;
			switch(strangerank)
			{
				case 0:
					strangekills=GetRandomInt(0, 9);
				case 1:
					strangekills=GetRandomInt(10, 24);
				case 2:
					strangekills=GetRandomInt(25, 44);
				case 3:
					strangekills=GetRandomInt(45, 69);
				case 4:
					strangekills=GetRandomInt(70, 99);
				case 5:
					strangekills=GetRandomInt(100, 134);
				case 6:
					strangekills=GetRandomInt(135, 174);
				case 7:
					strangekills=GetRandomInt(175, 224);
				case 8:
					strangekills=GetRandomInt(225, 274);
				case 9:
					strangekills=GetRandomInt(275, 349);
				case 10:
					strangekills=GetRandomInt(350, 499);
				case 11:
				{
					if(index==656)	// Holiday Punch is different
						strangekills=GetRandomInt(500, 748);
					else
						strangekills=GetRandomInt(500, 749);
				}
				case 12:
				{
					if(index==656)
						strangekills=749;
					else
						strangekills=GetRandomInt(750, 998);
				}
				case 13:
				{
					if(index==656)
						strangekills=GetRandomInt(750, 999);
					else
						strangekills=999;
				}
				case 14:
					strangekills=GetRandomInt(1000, 1499);
				case 15:
					strangekills=GetRandomInt(1500, 2499);
				case 16:
					strangekills=GetRandomInt(2500, 4999);
				case 17:
					strangekills=GetRandomInt(5000, 7499);
				case 18:
				{
					if(index==656)
						strangekills=GetRandomInt(7500, 7922);
					else
						strangekills=GetRandomInt(7500, 7615);
				}
				case 19:
				{
					if(index==656)
						strangekills=GetRandomInt(7923, 8499);
					else
						strangekills=GetRandomInt(7616, 8499);
				}
				case 20:
					strangekills=GetRandomInt(8500, 9999);
				default:
				{
					strangekills=GetRandomInt(0, 9999);
					if(!GetConVarBool(cvarStrangeWep) || weaponlevel!=-1 || overridewep)
						strangewep=0;
				}
			}
			if(weaponlevel<0)
				weaponlevel=101;

			if(strangewep)
			{
				if(attributes[0]!='\0')
				{
					if(overridewep)
						Format(attributes, sizeof(attributes), "214 ; %d ; %s", strangekills, attributes);
					else
						Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; 214 ; %d ; 275 ; 1 ; %s", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, strangekills, attributes);
				}
				else
				{
					if(overridewep)
						Format(attributes, sizeof(attributes), "214 ; %d", strangekills);
					else
						Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; 214 ; %d ; 275 ; 1", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, strangekills);
				}
			}
			else
			{
				if(attributes[0]!='\0')
				{
					if(overridewep)
						Format(attributes, sizeof(attributes), "%s", attributes);
					else
						Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; 275 ; 1 ; %s", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, attributes);
				}
				else
				{
					if(overridewep)
						Format(attributes, sizeof(attributes), "28 ; 1");	// Does nothing
					else
						Format(attributes, sizeof(attributes), "68 ; %i ; 2 ; 3.1 ; 275 ; 1", TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2);
				}
			}

			int weapon=SpawnWeapon(client, classname, index, weaponlevel, KvGetNum(BossKV[Special[boss]], "quality", QualityWep), attributes);
			SetWeaponAmmo(client, weapon, KvGetNum(BossKV[Special[boss]], "ammo", 0));
			SetWeaponClip(client, weapon, KvGetNum(BossKV[Special[boss]], "clip", 0));
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
				char wModel[4][PLATFORM_MAX_PATH];
				KvGetString(BossKV[Special[boss]], "worldmodel", wModel[0], sizeof(wModel[]));
				KvGetString(BossKV[Special[boss]], "pyrovision", wModel[1], sizeof(wModel[]));
				KvGetString(BossKV[Special[boss]], "halloweenvision", wModel[2], sizeof(wModel[]));
				KvGetString(BossKV[Special[boss]], "romevision", wModel[3], sizeof(wModel[]));
				for(int type=0;type<=3;type++)
				{
					if(wModel[type][0])
					{
						ConfigureWorldModelOverride(weapon, index, wModel[type], view_as<WorldModelType>(type));
					}
				}
			}

			int rgba[4];
			rgba[0]=KvGetNum(BossKV[Special[boss]], "alpha", 255);
			rgba[1]=KvGetNum(BossKV[Special[boss]], "red", 255);
			rgba[2]=KvGetNum(BossKV[Special[boss]], "green", 255);
			rgba[3]=KvGetNum(BossKV[Special[boss]], "blue", 255);

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
	TFClassType class=view_as<TFClassType>(KvGetNum(BossKV[Special[boss]], "class", 1));
	if(TF2_GetPlayerClass(client)!=class)
	{
		TF2_SetPlayerClass(client, class, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	}
}

stock bool ConfigureWorldModelOverride(int entity, int index, const char[] model, WorldModelType type, bool wearable=false)
{
	if(!FileExists(model, true))
		return false;
        
	int modelIndex=PrecacheModel(model);
	if(!type)
	{
		SetEntProp(entity, Prop_Send, "m_nModelIndex", modelIndex);
	}
	else
	{
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, view_as<int>(type));
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", (!wearable ? GetEntProp(entity, Prop_Send, "m_iWorldModelIndex") : GetEntProp(entity, Prop_Send, "m_nModelIndex")), _, 0);    
	}
	return true;
}

stock int SetWeaponClip(int client, int slot, int clip)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if(IsValidEntity(weapon))
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", clip);
	}
}

stock int SetWeaponAmmo(int client, int slot, int ammo)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if(IsValidEntity(weapon))
	{
		int iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 1)*4;
		int iAmmoTable = FindSendPropInfo("CTFPlayer", "m_iAmmo");
		SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
	}
}

public Action Timer_MakeBoss(Handle timer, any boss)
{
	int client=Boss[boss];
	if(!IsValidClient(client) || CheckRoundState()==-1)
	{
		return Plugin_Continue;
	}

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
	if(GetClientTeam(client)!=BossTeam)
	{
		AssignTeam(client, BossTeam);
	}

	if(KvGetNum(BossKV[Special[boss]], "ragedamage", 1900)==1)	// If 1, toggle infinite rage
	{
		InfiniteRageActive[client]=true;
		CreateTimer(0.2, Timer_InfiniteRage, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		BossRageDamage[boss]=1;
	}
	else if(KvGetNum(BossKV[Special[boss]], "ragedamage", 1900)==-1)	// If -1, never rage
	{
		BossRageDamage[boss]=99999;
	}
	else	// Use formula or straight value
	{
		BossRageDamage[boss]=ParseFormula(boss, "ragedamage", "1900", 1900);
	}

	BossLivesMax[boss]=KvGetNum(BossKV[Special[boss]], "lives", 1);
	if(BossLivesMax[boss]<=0)
	{
		char bossName[64];
		KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName));
		PrintToServer("[FF2 Bosses] Warning: Boss %s has an invalid amount of lives, setting to 1", bossName);
		BossLivesMax[boss]=1;
	}
	BossHealthMax[boss]=ParseFormula(boss, "health_formula", "(((760.8+n)*(n-1))^1.0341)+2046", RoundFloat(Pow((760.8+float(playing))*(float(playing)-1.0), 1.0341)+2046.0));
	BossLives[boss]=BossLivesMax[boss];
	BossHealth[boss]=BossHealthMax[boss]*BossLivesMax[boss];
	BossHealthLast[boss]=BossHealth[boss];

	// True or false settings
	if(KvGetNum(BossKV[Special[boss]], "triple", -1)>=0)
		dmgTriple[client]=view_as<bool>(KvGetNum(BossKV[Special[boss]], "triple", -1));
	else
		dmgTriple[client]=GetConVarBool(cvarTripleWep);

	if(KvGetNum(BossKV[Special[boss]], "knockback", -1)>=0)
		selfKnockback[client]=view_as<bool>(KvGetNum(BossKV[Special[boss]], "knockback", -1));
	else
		selfKnockback[client]=GetConVarBool(cvarSelfKnockback);

	if(KvGetNum(BossKV[Special[boss]], "crits", -1)>=0)
		randomCrits[client]=view_as<bool>(KvGetNum(BossKV[Special[boss]], "crits", -1));
	else
		randomCrits[client]=GetConVarBool(cvarCrits);

	if(KvGetNum(BossKV[Special[boss]], "ghost", -1)>=0)
		GhostBoss=view_as<bool>(KvGetNum(BossKV[Special[boss]], "ghost", -1));
	else
		GhostBoss=GetConVarBool(cvarGhostBoss);

	// Rage settings
	rageMax[client]=KvGetFloat(BossKV[Special[boss]], "ragemax", 100.0);
	rageMin[client]=KvGetFloat(BossKV[Special[boss]], "ragemin", 100.0);
	rageMode[client]=KvGetNum(BossKV[Special[boss]], "ragemode", 0);

	// Timer/point settings
	if(KvGetNum(BossKV[Special[boss]], "pointtype", -1)>=0 && KvGetNum(BossKV[Special[boss]], "pointtype", -1)<=2)
		PointType=KvGetNum(BossKV[Special[boss]], "pointtype", -1);
	else
		PointType=GetConVarInt(cvarPointType);

	if(KvGetNum(BossKV[Special[boss]], "pointdelay", -9999)!=-9999)	// Can be below 0 so...
		PointDelay=KvGetNum(BossKV[Special[boss]], "pointdelay", -9999);
	else
		PointDelay=GetConVarInt(cvarPointDelay);

	if(KvGetNum(BossKV[Special[boss]], "pointtime", -9999)!=-9999)	// Same here, in-case of some weird boss logic
		PointTime=KvGetNum(BossKV[Special[boss]], "pointtime", -9999);
	else
		PointTime=GetConVarInt(cvarPointTime);

	if(KvGetNum(BossKV[Special[boss]], "pointalive", -1)>=0)	// Can't be below 0, it's players
		AliveToEnable=KvGetNum(BossKV[Special[boss]], "pointalive", -1);
	else
		AliveToEnable=GetConVarInt(cvarAliveToEnable);

	if(KvGetNum(BossKV[Special[boss]], "countdownhealth", -1)>=0)	// Also can't be below 0, it's health
		countdownHealth=KvGetNum(BossKV[Special[boss]], "countdownhealth", -1);
	else
		countdownHealth=GetConVarInt(cvarCountdownHealth);

	if(KvGetNum(BossKV[Special[boss]], "countdownalive", -1)>=0)	// Yet again, can't be below 0
		countdownPlayers=KvGetNum(BossKV[Special[boss]], "countdownalive", -1);
	else
		countdownPlayers=GetConVarInt(cvarCountdownPlayers);

	if(KvGetNum(BossKV[Special[boss]], "countdowntime", -1)>=0)	// .w.
		countdownTime=KvGetNum(BossKV[Special[boss]], "countdowntime", -1);
	else
		countdownTime=GetConVarInt(cvarCountdownTime);

	if(KvGetNum(BossKV[Special[boss]], "countdownovertime", -1)>=0)	// OVERTIME!
		countdownOvertime=view_as<bool>(KvGetNum(BossKV[Special[boss]], "countdownovertime", -1));
	else
		countdownOvertime=GetConVarBool(cvarCountdownOvertime);

	if((KvGetNum(BossKV[Special[boss]], "sapper", -1)<0 && (GetConVarInt(cvarSappers)==1 || GetConVarInt(cvarSappers)>2)) || KvGetNum(BossKV[Special[boss]], "sapper", -1)==1 || KvGetNum(BossKV[Special[boss]], "sapper", -1)>2)
		SapperBoss[client]=true;
	else
		SapperBoss[client]=false;

	if((KvGetNum(BossKV[Special[boss]], "sapper", -1)<0 && GetConVarInt(cvarSappers)>1) || KvGetNum(BossKV[Special[boss]], "sapper", -1)>1)
		SapperMinion=true;

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	KvRewind(BossKV[Special[boss]]);
	TF2_RemovePlayerDisguise(client);
	TF2_SetPlayerClass(client, view_as<TFClassType>(KvGetNum(BossKV[Special[boss]], "class", 1)), _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal

	switch(KvGetNum(BossKV[Special[boss]], "pickups", 0))  //Check if the boss is allowed to pickup health/ammo
	{
		case 1:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS;
		}
		case 2:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
		case 3:
		{
			FF2flags[client]|=FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
		}
	}

	if(!HasSwitched)
	{
		switch(KvGetNum(BossKV[Special[boss]], "bossteam", 0))
		{
			case 1: // Always Random
			{			
				SwitchTeams((currentBossTeam==1) ? (view_as<int>(TFTeam_Blue)) : (view_as<int>(TFTeam_Red)) , (currentBossTeam==1) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)), true);
			}
			case 2: // RED Boss
			{
				SwitchTeams(view_as<int>(TFTeam_Red), view_as<int>(TFTeam_Blue), true);
			}
			case 3: // BLU Boss
			{
				SwitchTeams(view_as<int>(TFTeam_Blue), view_as<int>(TFTeam_Red), true);
			}
			default: // Determined by "ff2_force_team" ConVar
			{
				SwitchTeams((blueBoss) ? (view_as<int>(TFTeam_Blue)) : (view_as<int>(TFTeam_Red)), (blueBoss) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)), true);
			}
		}
		HasSwitched=true;
	}

	CreateTimer(0.2, MakeModelTimer, boss, TIMER_FLAG_NO_MAPCHANGE);
	if(!IsVoteInProgress() && GetClientClassInfoCookie(client))
	{
		HelpPanelBoss(boss);
	}

	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_wear*"))!=-1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			switch(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"))
			{
				case 493, 233, 234, 241, 280, 281, 282, 283, 284, 286, 288, 362, 364, 365, 536, 542, 577, 599, 673, 729, 791, 839, 5607:  //Action slot items
				{
					//NOOP
				}
				default:
				{
					TF2_RemoveWearable(client, entity);
				}
			}
		}
	}

	entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_powerup_bottle"))!=-1)
	{
		if(IsBoss(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")))
		{
			TF2_RemoveWearable(client, entity);
		}
	}

	EquipBoss(boss);
	KSpreeCount[boss]=0;
	BossCharge[boss][0]=0.0;
	RPSHealth[boss]=-1;
	RPSLosses[boss]=0;
	RPSHealth[boss]=0;
	RPSLoser[boss]=-1.0;
	if((GetBossIndex(client)==0 && GetConVarBool(cvarDuoRestore)) || !GetConVarBool(cvarDuoRestore))
	{
		SetClientQueuePoints(client, 0);
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

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &item)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

	if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>1)
	{
		if(GetConVarInt(cvarHardcodeWep)<2)
			LogError("[FF2] Critical Error! Unable to configure weapons from '%s!", WeaponCFG);
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
				int isOverride=KvGetNum(kvWeaponMods, "mode");
				KvGetString(kvWeaponMods, "classname", weapon, sizeof(weapon));
				KvGetString(kvWeaponMods, "index", wepIndexStr, sizeof(wepIndexStr));
				KvGetString(kvWeaponMods, "attributes", attributes, sizeof(attributes));
				if(isOverride)
				{
					if(StrContains(wepIndexStr, "-2")!=-1 && StrContains(classname, weapon, false)!=-1 || StrContains(wepIndexStr, "-1")!=-1 && StrEqual(classname, weapon, false))
					{
						if(isOverride!=3)
						{
							Handle itemOverride=PrepareItemHandle(item, _, _, attributes, isOverride==1 ? false : true);
							if(itemOverride!=null)
							{
								item=itemOverride;
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
						for (int wepIdx = 0; wepIdx<=weaponIdxcount ; wepIdx++)
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
										case 2,1:
										{
											Handle itemOverride=PrepareItemHandle(item, _, _, attributes, isOverride==1 ? false : true);
											if(itemOverride!=null)
											{
												item=itemOverride;
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
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 40, 1146:  //Backburner, Festive Backburner
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "170 ; 1.5");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 41:  //Natascha
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "32 ; 0 ; 75 ; 1.34");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 43:  //Killing Gloves of Boxing
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "16 ; 50 ; 69 ; 0.15 ; 77 ; 0 ; 109 ; 0.5 ; 177 ; 2 ; 205 ; 0.7 ; 206 ; 0.7 ; 239 ; 0.25 ; 442 ; 1.35 ; 443 ; 1.1 ; 800 ; 0");
				// 16: +50 HP on hit
				// 69: -85% health from healers
				// 77: -100% max primary ammo
				// 109: -50% health from packs
				// 177: -100% weapon switch speed
				// 205: -30% damage from ranged while active
				// 206: -30% damage from melee while active
				// 239: -75% uber for healer
				// 442: +35% speed
				// 443: +10% jump
				// 800: -100% max overheal
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 44:  //Sandman
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "773 ; 1.15");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 56, 1005, 1092:  //Huntsman, Festive Huntsman, Fortified Compound
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "76 ; 2");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 127:  //Direct Hit
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "179 ; 1.0");
					//179: Crit instead of mini-critting
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 128:  //Equalizer
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "740 ; 0 ; 239 ; 0.5");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 129:  //Buff Banner
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "319 ; 1.5");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 131, 1144:  //Chargin' Targe
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "396 ; 0.95", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 140, 1086, 30668:  //Wrangler
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "54 ; 0.75 ; 128 ; 1 ; 206 ; 1.5");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 153, 466:  //Homewrecker
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "394 ; 3 ; 215 ; 10 ; 522 ; 1 ; 216 ; 10");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 154:  //Pain Train
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "20 ; 1 ; 149 ; 6 ; 204 ; 1 ; 408 ; 1", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 155:  //Southern Hospitality
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "20 ; 1 ; 149 ; 6 ; 1 ; 0.5 ; 408 ; 1", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 171, 325, 452, 648, 812, 833:  //Tribalman's Shiv, Boston Basher, Three-Rune Blade, Wrap Assassin, Guillotine(s)
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "20 ; 1 ; 408 ; 1");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 173:  //Vita-Saw
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "125 ; -10 ; 17 ; 0.15 ; 737 ; 1.25", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 220:  //Shortstop
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "868 ; 1");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 224:  //L'etranger
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "166 ; 5");
					//166: +5% cloak on hit
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 231:  //Darwin's Danger Shield
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 85 ; 800 ; 0.19 ; 69 ; 0.6 ; 109 ; 0.6", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 232:  //Bushwacka
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "58 ; 1.35");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 237:  //Rocket Jumper
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.3 ; 15 ; 0 ; 135 ; 0.5 ; 206 ; 2 ; 400 ; 1", true);
				if(itemOverride!=INVALID_HANDLE)
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
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 265:  //Sticky Jumper
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.3 ; 15 ; 0 ; 89 ; -6 ; 135 ; 0.5 ; 206 ; 2 ; 400 ; 1", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 305, 1079:  //Crusader's Crossbow, Festive Crusader's Crossbow
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "17 ; 0.2");
					//17: +20% uber on hit
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 312:  //Brass Beast
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "206 ; 1.35");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 317:  //Candy Cane
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "740 ; 0.5 ; 239 ; 0.75", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 327:  //Claidheamh Mor
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "412 ; 1.2");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 329:  //Jag
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "92 ; 1.3 ; 6 ; 0.85 ; 95 ; 0.6 ; 1 ; 0.5 ; 137 ; 1.34", true);
				if(itemOverride!=INVALID_HANDLE)
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
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 348:  //Sharpened Volcano Fragment
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "16 ; 35 ; 69 ; 0.34 ; 77 ; 0 ; 109 ; 0.5 ; 773 ; 1.5 ; 205 ; 0.8 ; 206 ; 0.6 ; 239 ; 0.25 ; 442 ; 1.15 ; 443 ; 1.15 ; 800 ; 0.34");
				// 16: +35 HP on hit
				// 69: -66% health from healers
				// 77: -100% max primary ammo
				// 109: -50% health from packs
				// 773: -50% deploy speed
				// 205: -20% damage from ranged while active
				// 206: -40% damage from melee while active
				// 239: -75% uber for healer
				// 442: +15% speed
				// 443: +15% jump
				// 800: -66% max overheal
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 349:  //Sun-on-a-Stick
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.75 ; 795 ; 2", true);
				if(itemOverride!=INVALID_HANDLE)
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
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 355:  //Fan O'War
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.25 ; 6 ; 0.5 ; 49 ; 1 ; 137 ; 4 ; 107 ; 1.1 ; 201 ; 1.1 ; 77 ; 0.38", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 404:  //Persian Persuader
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "772 ; 1.15 ; 249 ; 0.6 ; 781 ; 1 ; 778 ; 0.5 ; 782 ; 1", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 405, 608:  //Ali Baba's Wee Booties, Bootlegger
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "26 ; 25 ; 246 ; 3 ; 107 ; 1.10", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 406:  //Splendid Screen
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "248 ; 2.6", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 414:  //Liberty Launcher
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.65 ; 206 ; 1.5");
				if(itemOverride!=INVALID_HANDLE)
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
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 416:  //Market Gardener
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "5 ; 2");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 426:  //Eviction Notice
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.2 ; 6 ; 0.25 ; 107 ; 1.2 ; 737 ; 2.25", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 441:  //Cow Mangler
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "71 ; 2.5");
				if(itemOverride!=INVALID_HANDLE)
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
					if(itemOverride!=INVALID_HANDLE)
					{
						item=itemOverride;
						return Plugin_Changed;
					}
				}
				#else
				Handle itemOverride=PrepareItemHandle(item, _, _, "58 ; 1.5");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
				#endif
			}
			case 442, 588:  //Bison, Pomson
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "182 ; 2");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 528:  //Short Circuit
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "20 ; 1 ; 182 ; 2 ; 408 ; 1");
				if(itemOverride!=INVALID_HANDLE)
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
					if(itemOverride!=INVALID_HANDLE)
					{
						item=itemOverride;
						return Plugin_Changed;
					}
				}
			}
			case 593:  //Third Degree
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "853 ; 0.8 ; 854 ; 0.8");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 595:  //Manmelter
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "6 ; 0.35");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 656:  //Holiday Punch
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "178 ; 0.001", true);
					//178: Switch 99.9% faster
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 730:  //Beggar's Bazooka
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "76 ; 1.5");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 740:  //Scorch Shot
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "79 ; 0.75");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 772:  //Baby Face's Blaster
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "532 ; 1.2");
					//532: Hype decays
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 775:  //Escape Plan
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "740 ; 0 ; 206 ; 1.5 ; 239 ; 0.5");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 811, 832:  //Huo-Long Heater
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "71 ; 2.75");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 813, 834:  //Neon Annihilator
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "182 ; 2");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1099:  //Tide Turner
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "639 ; 50", true);
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1103:  //Back Scatter
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "179 ; 1");
					//179: Crit instead of mini-critting
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1104:  //Air Strike
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "1 ; 0.82 ; 206 ; 1.25");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1179:  //Thermal Thruster
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "872 ; 1");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1180:  //Gas Passer
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "875 ; 1 ; 2059 ; 3000");
				if(itemOverride!=INVALID_HANDLE)
				{
					item=itemOverride;
					return Plugin_Changed;
				}
			}
			case 1181:  //Hot Hand
			{
				Handle itemOverride=PrepareItemHandle(item, _, _, "877 ; 2");
				if(itemOverride!=INVALID_HANDLE)
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
			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
		else if(TF2_GetPlayerClass(client)==TFClass_Medic && !StrContains(classname, "tf_weapon_medigun"))  //Medi Gun
		{
			Handle itemOverride;
			if(iItemDefinitionIndex==35)  //Kritzkrieg
			{
				itemOverride=PrepareItemHandle(item, _, _, "10 ; 1.25 ; 11 ; 1.5 ; 18 ; 1 ; 199 ; 0.75 ; 547 ; 0.75");
				//10: +125% faster charge rate
				//11: +50% overheal bonus
				//18: Kritzkrieg uber
				//199: Deploys 25% faster
				//547: Holsters 25% faster
			}
			else if(iItemDefinitionIndex==411)  //Quick-Fix
			{
				itemOverride=PrepareItemHandle(item, _, _, "8 ; 1.12 ; 10 ; 2 ; 105 ; 1 ; 144 ; 2 ; 199 ; 0.75 ; 231 ; 2 ; 493 ; 1 ; 547 ; 0.75");
				//8: +12% heal rate
				//10: +100% faster charge rate
				//105: Default Medi-Gun overheal
				//144: Quick-fix speed/jump effects
				//199: Deploys 25% faster
				//231: Quick-fix no-knockback uber
				//493: Healing mastery level 1
				//547: Holsters 25% faster
			}
			else if(iItemDefinitionIndex==998)  //Vaccinator
			{
				itemOverride=PrepareItemHandle(item, _, _, "10 ; 2.5 ; 11 ; 1.5 ; 199 ; 0.75 ; 314 ; -3 ; 479 ; 0.34 ; 499 ; 1 ; 547 ; 0.75 ; 739 ; 0.34", true);
				//10: +150% faster charge rate
				//11: +50% overheal bonus
				//199: Deploys 25% faster
				//314: -3 sec uber duration
				//479: -66% overheal build rate
				//499: Projectile sheild level 1
				//547: Holsters 25% faster
				//739: -66% uber rate when overhealing
			}
			else
			{
				itemOverride=PrepareItemHandle(item, _, _, "10 ; 1.75 ; 11 ; 1.5 ; 144 ; 2.0 ; 199 ; 0.75 ; 547 ; 0.75");
				//10: +75% faster charge rate
				//11: +50% overheal bonus
				//144: Quick-fix speed/jump effects
				//199: Deploys 25% faster
				//547: Holsters 25% faster
			}	

			if(itemOverride!=INVALID_HANDLE)
			{
				item=itemOverride;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_NoHonorBound(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int melee=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		int index=((IsValidEntity(melee) && melee>MaxClients) ? GetEntProp(melee, Prop_Send, "m_iItemDefinitionIndex") : -1);
		int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		char classname[64];
		if(IsValidEntity(weapon))
		{
			GetEntityClassname(weapon, classname, sizeof(classname));
		}
		if(index==357 && weapon==melee && !strcmp(classname, "tf_weapon_katana", false))
		{
			SetEntProp(melee, Prop_Send, "m_bIsBloody", 1);
			if(GetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
			{
				SetEntProp(client, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
			}
		}
	}
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
			int attrib=StringToInt(weaponAttribsArray[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", weaponAttribsArray[i], weaponAttribsArray[i+1]);
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
	int client=GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==2 || IsBoss(client) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		return Plugin_Continue;
	}

	if(!IsVoteInProgress() && GetClientClassInfoCookie(client) && !(FF2flags[client] & FF2FLAG_CLASSHELPED))
	{
		HelpPanelClass(client);
	}

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);  //This really shouldn't be needed but I've been noticing players who still have glow

	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client)); //Temporary: Reset health to avoid an overheal bug
	if(GetClientTeam(client)==BossTeam)
	{
		AssignTeam(client, OtherTeam);
	}

	CreateTimer(0.1, Timer_CheckItems, userid, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_CheckItems(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(!IsValidClient(client) || !IsPlayerAlive(client) || CheckRoundState()==2 || IsBoss(client) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		return Plugin_Continue;
	}

	SetEntityRenderColor(client, 255, 255, 255, 255);
	hadshield[client]=false;
	shield[client]=0;
	int index=-1;
	int[] civilianCheck = new int[MaxClients+1];

	int weapon=GetPlayerWeaponSlot(client, 4);
	if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==60  && (kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0))  //Cloak and Dagger
	{
		TF2_RemoveWeaponSlot(client, 4);
		SpawnWeapon(client, "tf_weapon_invis", 60, 1, 0, "35 ; 1.65 ; 728 ; 1 ; 729 ; 0.65");
	}

	if(bMedieval)
	{
		return Plugin_Continue;
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==402 && GetConVarInt(cvarHardcodeWep)>0)
	{
		TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
		SpawnWeapon(client, "tf_weapon_sniperrifle", 402, 1, 6, "91 ; 0.5 ; 75 ; 3.75 ; 178 ; 0.8");
	}
	else
	{
		civilianCheck[client]++;
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(weapon))
	{
		if(TF2_GetPlayerClass(client)==TFClass_Medic)
		{
			if(GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee)==142)  //Gunslinger (Randomizer, etc. compatability)
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

	int playerBack=FindPlayerBack(client, 57);  //Razorback
	shield[client]=IsValidEntity(playerBack) ? playerBack : 0;
	hadshield[client]=IsValidEntity(playerBack) ? true : false;
	if(IsValidEntity(FindPlayerBack(client, 642)))  //Cozy Camper
	{
		SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "149 ; 1.5 ; 15 ; 0.0 ; 1 ; 0.75");
	}

	#if defined _tf2attributes_included
	if(tf2attributes && GetConVarInt(cvarHardcodeWep)>0)
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

	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)  //Demoshields
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			shield[client]=entity;
			hadshield[client]=true;
		}
	}

	if(IsValidEntity(shield[client]))
	{
		if(GetConVarInt(cvarShieldType)==4)
		{
			shieldHP[client]=500.0;
			shDmgReduction[client]=0.75;
		}
		else if(GetConVarInt(cvarShieldType)==3)
		{
			shieldHP[client]=1000.0;
			shDmgReduction[client]=0.5;
		}
	}

	weapon=GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(weapon))
	{
		index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		switch(index)
		{
			case 357:  //Half-Zatoichi
			{
				CreateTimer(1.0, Timer_NoHonorBound, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	if(civilianCheck[client]==3)
	{
		civilianCheck[client]=0;
		TF2_RespawnPlayer(client);
	}
	civilianCheck[client]=0;
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
			{
				TF2_RemoveWearable(client, entity);
			}
		}
	}
}

stock int RemovePlayerBack(int client, int[] indices, int length)
{
	if(length<=0)
	{
		return;
	}

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
					{
						TF2_RemoveWearable(client, entity);
					}
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
		{
			return entity;
		}
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
			if(RandomSound("sound_kill_buildable", sound, sizeof(sound)))
			{
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnUberDeployed(Handle event, const char[] name, bool dontBroadcast)
{
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(Enabled && IsValidClient(client) && IsPlayerAlive(client))
	{
		int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(IsValidEntity(medigun))
		{
			char classname[64];
			GetEntityClassname(medigun, classname, sizeof(classname));
			if(StrEqual(classname, "tf_weapon_medigun"))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5, client);
				int target=GetHealingTarget(client);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
					uberTarget[client]=target;
				}
				else
				{
					uberTarget[client]=-1;
				}
				CreateTimer(0.4, Timer_Uber, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Uber(Handle timer, any medigunid)
{
	int medigun=EntRefToEntIndex(medigunid);
	if(medigun && IsValidEntity(medigun) && CheckRoundState()==1)
	{
		int client=GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		float charge=GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if(IsValidClient(client, false) && IsPlayerAlive(client) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==medigun)
		{
			int target=GetHealingTarget(client);
			if(charge>0.05)
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5);
					uberTarget[client]=target;
				}
				else
				{
					uberTarget[client]=-1;
				}
			}
			else
			{
				return Plugin_Stop;
			}
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
	if(!IsValidClient(client) || !Enabled || CheckRoundState()!=1)
	{
		return Plugin_Continue;
	}

	Command_GetHP(client);
	return Plugin_Handled;
}

public Action Command_GetHP(int client)  //TODO: This can rarely show a very large negative number if you time it right
{
	if(IsBoss(client) || GetGameTime()>=HPTime)
	{
		char text[512], lives[8], name[64];
		for(int target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				int boss=Boss[target];
				KvRewind(BossKV[Special[boss]]);
				KvGetString(BossKV[Special[boss]], "name", name, sizeof(name), "=Failed name=");
				if(BossLives[boss]>1)
				{
					Format(lives, sizeof(lives), "x%i", BossLives[boss]);
				}
				else
				{
					lives[0]='\0';
				}
				Format(text, sizeof(text), "%s\n%t", text, "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
				CPrintToChatAll("{olive}[FF2]{default} %t", "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
				BossHealthLast[boss]=BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			}
		}

		for(int target; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
			{
				if(!Companions && GetConVarBool(cvarGameText) && !GhostBoss)
				{
					ShowGameText(target, "leaderboard_streak", _, text);
				}
				else if(!Companions && GetConVarBool(cvarGameText))
				{
					ShowGameText(target, "ico_ghost", _, text);
				}
				else
				{
					PrintCenterText(target, text);
				}
			}
		}

		if(GetGameTime()>=HPTime)
		{
			healthcheckused++;
			HPTime=GetGameTime()+(healthcheckused<3 ? 20.0 : 80.0);
		}
		return Plugin_Continue;
	}

	if(RedAlivePlayers>1)
	{
		char waitTime[128];
		for(int target; target<=MaxClients; target++)
		{
			if(IsBoss(target))
			{
				Format(waitTime, sizeof(waitTime), "%s %i,", waitTime, BossHealthLast[Boss[target]]);
			}
		}
		CPrintToChat(client, "{olive}[FF2]{default} %t", "wait_hp", RoundFloat(HPTime-GetGameTime()), waitTime);
	}
	return Plugin_Continue;
}

public Action Command_SetNextBoss(int client, int args)
{
	char name[64], boss[64];

	if(args<1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_special <boss>");
		return Plugin_Handled;
	}
	GetCmdArgString(name, sizeof(name));

	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrContains(boss, name, false)!=-1)
		{
			Incoming[0]=config;
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvGetString(BossKV[config], "filename", boss, sizeof(boss));
		if(StrContains(boss, name, false)!=-1)
		{
			Incoming[0]=config;
			KvGetString(BossKV[config], "name", boss, sizeof(boss));
			CReplyToCommand(client, "{olive}[FF2]{default} Set the next boss to %s", boss);
			return Plugin_Handled;
		}
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Boss could not be found!");
	return Plugin_Handled;
}

public Action Command_Points(int client, int args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	if(args!=2)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_addpoints <target> <points>");
		return Plugin_Handled;
	}

	char stringPoints[8], pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, stringPoints, sizeof(stringPoints));
	int points=StringToInt(stringPoints);

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
				SetClientQueuePoints(targets[target], GetClientQueuePoints(targets[target])+points);
				LogAction(client, targets[target], "\"%L\" added %d queue points to \"%L\"", client, points, targets[target]);
			}
		}
	}
	else
	{
		SetClientQueuePoints(targets[0], GetClientQueuePoints(targets[0])+points);
		LogAction(client, targets[0], "\"%L\" added %d queue points to \"%L\"", client, points, targets[0]);
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Added %d queue points to %s", points, targetName);
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
			CReplyToCommand(client, "{olive}[FF2]{default} Started boss music for %s.", targetName);
		}
		else
		{
			StartMusic();
			CReplyToCommand(client, "{olive}[FF2]{default} Started boss music for all clients.");
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
			CReplyToCommand(client, "{olive}[FF2]{default} Stopped boss music for %s.", targetName);
		}
		else
		{
			StopMusic(_, true);
			CReplyToCommand(client, "{olive}[FF2]{default} Stopped boss music for all clients.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_Charset(int client, int args)
{
	if(!args)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_charset <charset>");
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
			CReplyToCommand(client, "{olive}[FF2]{default} Charset for nextmap is %s", config);
			isCharSetSelected=true;
			FF2CharSet=i;
			break;
		}

		if(!KvGotoNextKey(Kv))
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Charset not found");
			break;
		}
	}
	CloseHandle(Kv);
	return Plugin_Handled;
}

public Action Command_LoadCharset(int client, int args)
{
	if(!args)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_loadcharset <charset>");
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
				CReplyToCommand(client, "{olive}[FF2]{default} The current character set is set to be switched to %s!", config);
				return Plugin_Handled;
			}
			
			CReplyToCommand(client, "{olive}[FF2]{default} Character set has been switched to %s", config);
			FindCharacters();
			strcopy(FF2CharSetString, 2, "");
			LoadCharset=false;
			break;
		}

		if(!KvGotoNextKey(Kv))
		{
			CReplyToCommand(client, "{olive}[FF2]{default} Charset not found");
			break;
		}
	}
	CloseHandle(Kv);
	return Plugin_Handled;
}

public Action Command_ReloadFF2(int client, int args)
{
	ReloadFF2 = true;
	if(CheckRoundState()==0 || CheckRoundState()==1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} The plugin is set to reload.");
		return Plugin_Handled;
	}
	CReplyToCommand(client, "{olive}[FF2]{default} The plugin has been reloaded.");
	ReloadFF2 = false;
	ServerCommand("sm plugins reload freak_fortress_2");
	return Plugin_Handled;
}

public Action Command_ReloadCharset(int client, int args)
{
	LoadCharset = true;
	if(CheckRoundState()==0 || CheckRoundState()==1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Current character set is set to reload!");
		return Plugin_Handled;
	}
	CReplyToCommand(client, "{olive}[FF2]{default} Current character set has been reloaded!");
	FindCharacters();
	LoadCharset=false;
	return Plugin_Handled;
}

public Action Command_ReloadFF2Weapons(int client, int args)
{
	ReloadWeapons = true;
	if(CheckRoundState()==0 || CheckRoundState()==1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} %s is set to reload!", WeaponCFG);
		return Plugin_Handled;
	}
	CReplyToCommand(client, "{olive}[FF2]{default} %s has been reloaded!", WeaponCFG);
	CacheWeapons();
	ReloadWeapons=false;
	return Plugin_Handled;
}

public Action Command_ReloadFF2Configs(int client, int args)
{
	ReloadConfigs = true;
	if(CheckRoundState()==0 || CheckRoundState()==1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} All configs are set to be reloaded!");
		return Plugin_Handled;
	}
	CacheWeapons();
	CheckToChangeMapDoors();
	FindCharacters();
	ReloadConfigs = false;
	return Plugin_Handled;
}

public Action Command_ReloadSubPlugins(int client, int args)
{
	if(Enabled)
	{
		switch(args)
		{
			case 0: // Reload ALL subplugins
			{
				DisableSubPlugins(true);
				EnableSubPlugins(true);
				CReplyToCommand(client, "{olive}[FF2]{default} Reloaded subplugins!");
			}
			case 1: // Reload a specific subplugin
			{
				char pluginName[PLATFORM_MAX_PATH];
				GetCmdArg(1, pluginName, sizeof(pluginName));
				BuildPath(Path_SM, pluginName, sizeof(pluginName), "plugins/freaks/%s.ff2", pluginName);
				if(!FileExists(pluginName))
				{
					CReplyToCommand(client, "{olive}[FF2]{default} Subplugin %s does not exist!", pluginName);
					return Plugin_Handled;
				}	
				ReplaceString(pluginName, sizeof(pluginName), "addons/sourcemod/plugins/freaks/", "freaks/", false);
				ServerCommand("sm plugins unload %s", pluginName);
				ServerCommand("sm plugins load %s", pluginName);
				ReplaceString(pluginName, sizeof(pluginName), "freaks/", " ", false);
				CReplyToCommand(client, "{olive}[FF2]{default} Reloaded subplugin %s!", pluginName);		
			}
			default:
			{
				ReplyToCommand(client, "[SM] Usage: ff2_reload_subplugins <plugin name> (omit <plugin name> to reload ALL subplugins)");	
			}
		}
	}
	return Plugin_Handled;
}

public Action Command_Point_Disable(int client, int args)
{
	if(Enabled)
	{
		SetControlPoint(false);
	}
	return Plugin_Handled;
}

public Action Command_Point_Enable(int client, int args)
{
	if(Enabled)
	{
		SetControlPoint(true);
	}
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

public void OnClientPostAdminCheck(int client)
{
	// TODO: Hook these inside of EnableFF2() or somewhere instead
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

	FF2flags[client]=0;
	Damage[client]=0;
	uberTarget[client]=-1;

	if(AreClientCookiesCached(client))
	{
		char buffer[24];
		GetClientCookie(client, FF2Cookies, buffer, sizeof(buffer));
		if(!buffer[0])
		{
			SetClientCookie(client, FF2Cookies, "0 1 1 1 3 3 3");
			//Queue points | music exception | voice exception | class info | UNUSED | UNUSED | UNUSED
		}
	}

	//We use the 0th index here because client indices can change.
	//If this is false that means music is disabled for all clients, so don't play it for new clients either.
	if(playBGM[0])
	{
		playBGM[client]=true;
		if(Enabled)
		{
			CreateTimer(0.1, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		playBGM[client]=false;
	}
}

public void OnClientCookiesCached(int client)
{
	char sEnabled[2];
	GetClientCookie(client, BossCookie, sEnabled, sizeof(sEnabled));

	int enabled = StringToInt(sEnabled);

	if(1>enabled || 2<enabled)
	{
		ClientCookie[client] = TOGGLE_UNDEF;
		Handle clientPack = CreateDataPack();
		WritePackCell(clientPack, client);
		CreateTimer(GetConVarFloat(cvarFF2TogglePrefDelay), BossMenuTimer, clientPack);
	}
	else
	{
		ClientCookie[client] = enabled;
	}

	GetClientCookie(client, CompanionCookie, sEnabled, sizeof(sEnabled));

	enabled = StringToInt(sEnabled);

	if(1>enabled || 2<enabled)
	{
		ClientCookie2[client] = TOGGLE_UNDEF;
		Handle clientPack = CreateDataPack();
		WritePackCell(clientPack, client);
	}
	else
	{
		ClientCookie2[client] = enabled;
	}
}

public void OnClientDisconnect(int client)
{
	if(Enabled)
	{
		if(IsBoss(client) && !CheckRoundState() && GetConVarBool(cvarPreroundBossDisconnect))
		{
			int boss=GetBossIndex(client);
			bool[] omit = new bool[MaxClients+1];
			omit[client]=true;
			Boss[boss]=GetClientWithMostQueuePoints(omit);

			if(Boss[boss])
			{
				CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
				CPrintToChat(Boss[boss], "{olive}[FF2]{default} %t", "Replace Disconnected Boss");
				CPrintToChatAll("{olive}[FF2]{default} %t", "Boss Disconnected", client, Boss[boss]);
			}
		}

		if(IsClientInGame(client) && IsPlayerAlive(client) && CheckRoundState()==1)
		{
			CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	FF2flags[client]=0;
	Damage[client]=0;
	uberTarget[client]=-1;

	if(MusicTimer[client]!=INVALID_HANDLE)
	{
		KillTimer(MusicTimer[client]);
		MusicTimer[client]=INVALID_HANDLE;
	}
	if(ClientCookie[client] == TOGGLE_TEMP)
	{
		SetClientCookie(client, BossCookie, "-1");
	}
	if(ClientCookie2[client] == TOGGLE_TEMP)
	{
		SetClientCookie(client, CompanionCookie, "1");
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
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");

	if(IsBoss(client))
	{
		CreateTimer(0.1, Timer_MakeBoss, GetBossIndex(client), TIMER_FLAG_NO_MAPCHANGE);
	}

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
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		TF2_RegeneratePlayer(client);
	}
}

public Action ClientTimer(Handle timer)
{
	if(!Enabled || CheckRoundState()==2 || CheckRoundState()==-1)
	{
		return Plugin_Stop;
	}

	char classname[32];
	TFCond cond;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && !IsBoss(client) && !(FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED))
		{
			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
			if(!IsPlayerAlive(client))
			{
				int observer=GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if(IsValidClient(observer) && !IsBoss(observer) && observer!=client)
				{
					if(Healing[observer]>0 && Healing[client]>0 && GetConVarBool(cvarHealingHud))
						FF2_ShowSyncHudText(client, rageHUD, "%t %t | %t %t", "Your Damage Dealt", Damage[client], "Healing", Healing[client], "Spectator Damage Dealt", observer, Damage[observer], "Healing", Healing[observer]);
					else if(Healing[client]>0 && GetConVarBool(cvarHealingHud))
						FF2_ShowSyncHudText(client, rageHUD, "%t %t | %t", "Your Damage Dealt", Damage[client], "Healing", Healing[client], "Spectator Damage Dealt", observer, Damage[observer]);
					else if(Healing[observer]>0 && GetConVarBool(cvarHealingHud))
						FF2_ShowSyncHudText(client, rageHUD, "%t | %t %t", "Your Damage Dealt", Damage[client], "Spectator Damage Dealt", observer, Damage[observer], "Healing", Healing[observer]);
					else
						FF2_ShowSyncHudText(client, rageHUD, "%t | %t", "Your Damage Dealt", Damage[client], "Spectator Damage Dealt", observer, Damage[observer]);
				}
				else
				{
					if(Healing[client]>0 && GetConVarBool(cvarHealingHud))
						FF2_ShowSyncHudText(client, rageHUD, "%t %t", "Your Damage Dealt", Damage[client], "Healing", Healing[client]);
					else
						FF2_ShowSyncHudText(client, rageHUD, "%t", "Your Damage Dealt", Damage[client]);
				}
				continue;
			}
			if(Healing[client]>0 && GetConVarBool(cvarHealingHud))
				FF2_ShowSyncHudText(client, rageHUD, "%t %t", "Your Damage Dealt", Damage[client], "Healing", Healing[client]);
			else
				FF2_ShowSyncHudText(client, rageHUD, "%t", "Your Damage Dealt", Damage[client]);

			TFClassType class=TF2_GetPlayerClass(client);
			int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(weapon<=MaxClients || !IsValidEntity(weapon) || !GetEntityClassname(weapon, classname, sizeof(classname)))
			{
				strcopy(classname, sizeof(classname), "");
			}
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
							{
								FF2flags[client]|=FF2FLAG_UBERREADY;
							}
						}
					}
				}
			}
			else if((TF2_GetPlayerClass(client)==TFClass_Sniper || TF2_GetPlayerClass(client)==TFClass_DemoMan) && (GetConVarInt(cvarShieldType)==3 || GetConVarInt(cvarShieldType)==4))
			{
				if(shield[client] && shieldHP[client]>0.0 && GetConVarInt(cvarShieldType)>2)
				{
					SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0);
					if(GetConVarInt(cvarShieldType)==4)
						FF2_ShowHudText(client, -1, "%t", "Shield HP", RoundToFloor(shieldHP[client]*0.2));
					else
						FF2_ShowHudText(client, -1, "%t", "Shield HP", RoundToFloor(shieldHP[client]*0.1));
				}
			}
			else if(SapperCooldown[client]>0.0)
			{
				SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0);
				FF2_ShowHudText(client, -1, "%t", "Sapper Cooldown", RoundToFloor((SapperCooldown[client]-GetConVarFloat(cvarSapperCooldown))*(Pow(GetConVarFloat(cvarSapperCooldown), -1.0)*-100.0)));
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
					{
						ShowSyncHudText(client, jumpHUD, "%s", s);
					}
				}
			}
			else if(class==TFClass_Soldier)
			{
				if((FF2flags[client] & FF2FLAG_ISBUFFED) && !(GetEntProp(client, Prop_Send, "m_bRageDraining")))
				{
					FF2flags[client]&=~FF2FLAG_ISBUFFED;
				}
			}

			if(RedAlivePlayers<=lastPlayerGlow)
			{
				SetClientGlow(client, 3600.0);
			}
			if(RedAlivePlayers==1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Stealthed))
			{
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.3);
				if(class==TFClass_Engineer && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))  // TODO: Is this necessary?
				{
					SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
				}
				TF2_AddCondition(client, TFCond_Buffed, 0.3);
				continue;
			}
			else if(RedAlivePlayers==2 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Stealthed))
			{
				TF2_AddCondition(client, TFCond_Buffed, 0.3);
			}

			if(bMedieval)
			{
				continue;
			}

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
				if(class==TFClass_Scout && cond==TFCond_HalloweenCritCandy && (!StrContains(classname, "tf_weapon_pistol") || !StrContains(classname, "tf_weapon_handgun_scout_secondary")))
				{
					cond=TFCond_Buffed;
				}
				if(class==TFClass_Engineer && cond==TFCond_HalloweenCritCandy && !StrContains(classname, "tf_weapon_pistol"))
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
			{
				addthecrit=false;
			}

			switch(class)
			{
				case TFClass_Medic:
				{
					int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
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
							{
								FF2flags[client]|=FF2FLAG_UBERREADY;
							}
						}
					}
				}
				case TFClass_DemoMan:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && !IsValidEntity(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)) && shieldCrits)  //Demoshields
					{
						addthecrit=true;
						if(shieldCrits==1)
						{
							cond=TFCond_CritCola;
						}
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
							TF2_AddCondition(client, TFCond_Kritzkrieged, 0.3);
						}
					}
				}
				case TFClass_Engineer:
				{
					if(weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) && StrEqual(classname, "tf_weapon_sentry_revenge", false))
					{
						int sentry=FindSentry(client);
						if(IsValidEntity(sentry) && IsBoss(GetEntPropEnt(sentry, Prop_Send, "m_hEnemy")))
						{
							SetEntProp(client, Prop_Send, "m_iRevengeCrits", 3);
							TF2_AddCondition(client, TFCond_Kritzkrieged, 0.3);
						}
						else
						{
							if(GetEntProp(client, Prop_Send, "m_iRevengeCrits"))
							{
								SetEntProp(client, Prop_Send, "m_iRevengeCrits", 0);
							}
							else if(TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) && !TF2_IsPlayerInCondition(client, TFCond_Healing))
							{
								TF2_RemoveCondition(client, TFCond_Kritzkrieged);
							}
						}
					}
				}
			}

			if(addthecrit)
			{
				TF2_AddCondition(client, cond, 0.3);
				if(healer!=-1 && cond!=TFCond_Buffed)
				{
					TF2_AddCondition(client, TFCond_Buffed, 0.3);
				}
			}
		}
	}
	return Plugin_Continue;
}

stock int FindSentry(int client)
{
	int entity=-1;
	while((entity=FindEntityByClassname2(entity, "obj_sentrygun"))!=-1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client)
		{
			return entity;
		}
	}
	return -1;
}

public Action BossTimer(Handle timer)
{
	if(!Enabled || CheckRoundState()==2)
	{
		return Plugin_Stop;
	}

	bool validBoss=false;
	for(int boss; boss<=MaxClients; boss++)
	{
		int client=Boss[boss];
		if(!IsValidClient(client) || !IsPlayerAlive(client) || !(FF2flags[client] & FF2FLAG_USEBOSSTIMER))
		{
			continue;
		}
		validBoss=true;

		if(BossSpeed[Special[boss]]>0)	// Above 0, uses the classic FF2 method
		{
			SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", BossSpeed[Special[boss]]+0.7*(100-BossHealth[boss]*100/BossLivesMax[boss]/BossHealthMax[boss]));
		}
		else if(BossSpeed[Special[boss]]==0 && GetEntityMoveType(client)!=MOVETYPE_NONE) // Is 0, freeze movement (some uses)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
		// Below 0, TF2's default speeds and whatever attributes or conditions

		if(BossHealth[boss]<=0 && IsPlayerAlive(client))  //Wat.  TODO:  Investigate
		{
			BossHealth[boss]=1;
		}

		if(BossLivesMax[boss]>1)
		{
			SetHudTextParams(-1.0, 0.77, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, livesHUD, "%t", "Boss Lives Left", BossLives[boss], BossLivesMax[boss]);
		}

		if((RoundFloat(BossCharge[boss][0])>=rageMin[client] && BossRageDamage[0]>1 && BossRageDamage[0]<99999) || BossRageDamage[0]==1)	// ragedamage above 1 and below 99999 and full rage, or ragedamage is 1
		{
			if(IsFakeClient(client) && !(FF2flags[client] & FF2FLAG_BOTRAGE))
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
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);

					for(int target=1; target<=MaxClients; target++)
					{
						if(IsClientInGame(target) && target!=client && CheckSoundException(target, SOUNDEXCEPT_VOICE))
						{
							EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
							EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
						}
					}
					FF2flags[client]&=~FF2FLAG_TALKING;
					emitRageSound[boss]=false;
				}
			}
		}
		else if(BossRageDamage[0]<99999)	// ragedamage below 999999
		{
			SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255);
			FF2_ShowSyncHudText(client, rageHUD, "%t", "rage_meter", RoundFloat(BossCharge[boss][0]));
		}
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);

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
				int slot=KvGetNum(BossKV[Special[boss]], "arg0", 0);
				int buttonmode=KvGetNum(BossKV[Special[boss]], "buttonmode", 0);
				if(slot<1)
				{
					continue;
				}

				KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability), "");
				if(!ability[0])
				{
					char ability_name[64];
					KvGetString(BossKV[Special[boss]], "name", ability_name, sizeof(ability_name));
					UseAbility(ability_name, plugin_name, boss, slot, buttonmode);
				}
				else
				{
					int count=ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
					for(int n; n<count; n++)
					{
						if(StringToInt(lives[n])==BossLives[boss])
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

		if(RedAlivePlayers<=lastPlayerGlow)
		{
			SetClientGlow(client, 3600.0);
		}
		if(RedAlivePlayers==1 && !executed2)
		{
			char message[512], name[64];
			for(int target; target<=MaxClients; target++)  //TODO: Why is this for loop needed when we're already in a boss for loop
			{
				if(IsBoss(target))
				{
					int boss2=GetBossIndex(target);
					KvRewind(BossKV[Special[boss2]]);
					KvGetString(BossKV[Special[boss2]], "name", name, sizeof(name), "=Failed name=");
					char bossLives[10];
					if(BossLives[boss2]>1)
					{
						Format(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);
					}
					else
					{
						Format(bossLives, sizeof(bossLives), "");
					}
					Format(message, sizeof(message), "%s\n%t", message, "ff2_hp", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives);
				}
			}

			for(int target; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					if(!Companions && GetConVarBool(cvarGameText) && !GhostBoss)
					{
						ShowGameText(target, "leaderboard_streak", _, message);
					}
					else if(!Companions && GetConVarBool(cvarGameText))
					{
						ShowGameText(target, "ico_ghost", _, message);
					}
					else
					{
						PrintCenterText(target, message);
					}
				}
			}
		}

		if(BossCharge[boss][0]<rageMax[client])
		{
			BossCharge[boss][0]+=OnlyScoutsLeft()*0.2;
			if(BossCharge[boss][0]>rageMax[client])
			{
				BossCharge[boss][0]=rageMax[client];
			}
		}

		HPTime-=0.2;
		if(HPTime<0)
		{
			HPTime=0.0;
		}

		for(int client2; client2<=MaxClients; client2++)
		{
			if(KSpreeTimer[client2]>0)
			{
				KSpreeTimer[client2]-=0.2;
			}
		}
	}

	if(!validBoss)
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Timer_RPS(Handle timer, int client)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(client);
	if(boss==-1 || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	RPSLosses[client]++;

	if(RPSLosses[client]<0)
		RPSLosses[client]=0;

	if(RPSHealth[client]==-1)
	{
		RPSHealth[client]=FF2_GetBossHealth(boss);
	}

	if(RPSLosses[client]>=GetConVarInt(cvarRPSLimit))
	{
		if(IsValidClient(RPSWinner) && FF2_GetBossHealth(boss)>1349)
		{
			SDKHooks_TakeDamage(client, RPSWinner, RPSWinner, float(FF2_GetBossHealth(boss)), DMG_GENERIC, -1);
		}
		else // Winner disconnects?
		{
			ForcePlayerSuicide(client);
		}
	}
	else if(FF2_GetBossHealth(boss)>1349 && GetConVarBool(cvarRPSDivide))
	{
		if(IsValidClient(RPSWinner))
		{
			SDKHooks_TakeDamage(client, RPSWinner, RPSWinner, float((RPSHealth[client]/GetConVarInt(cvarRPSLimit))-999)/1.35, DMG_GENERIC, -1);
		}
	}
	return Plugin_Continue;
}

public Action Timer_BotRage(Handle timer, any bot)
{
	if(IsValidClient(Boss[bot], false))
	{
		FakeClientCommandEx(Boss[bot], "voicemenu 0 0");
	}
}

stock int OnlyScoutsLeft()
{
	int scouts;
	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)!=BossTeam)
		{
			if(TF2_GetPlayerClass(client)!=TFClass_Scout)
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
		else if(!IsBoss(client) && condition==TFCond_BlastJumping)
		{
			FF2flags[client]&=~FF2FLAG_ROCKET_JUMPING;
		}
	}
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
	if(!Enabled || !IsPlayerAlive(client) || CheckRoundState()!=1 || !IsBoss(client) || args!=2)
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(client);
	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]) || BossRageDamage[0]>=99999 || rageMode[client]==2)
	{
		return Plugin_Continue;
	}

	char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
	{
		return Plugin_Continue;
	}

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
				{
					continue;
				}

				KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability));
				if(!ability[0])
				{
					char abilityName[64], pluginName[64];
					KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
					KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
					if(!UseAbility(abilityName, pluginName, boss, 0))
					{
						return Plugin_Continue;
					}
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
							{
								return Plugin_Continue;
							}
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
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
		}
		if(RandomSoundAbility("sound_ability", sound, sizeof(sound), boss))
		{
			FF2flags[Boss[boss]]|=FF2FLAG_TALKING;
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);

			for(int target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && target!=Boss[boss] && CheckSoundException(target, SOUNDEXCEPT_VOICE))
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
	bool canBossSuicide=GetConVarBool(cvarBossSuicide);
	if(Enabled && IsBoss(client) && (canBossSuicide ? !CheckRoundState() : true) && CheckRoundState()!=2)
	{	
		CPrintToChat(client, "{olive}[FF2]{default} %t", canBossSuicide ? "Boss Suicide Pre-round" : "Boss Suicide Denied");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnChangeClass(int client, const char[] command, int args)
{
	if(Enabled && IsBoss(client) && IsPlayerAlive(client))
	{
		//Don't allow the boss to switch classes but instead set their *desired* class (for the next round)
		char class[16];
		GetCmdArg(1, class, sizeof(class));
		if(TF2_GetClass(class)!=TFClass_Unknown)  //Ignore cases where the client chooses an invalid class through the console
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetClass(class));
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnJoinTeam(int client, const char[] command, int args)
{
	// Only block the commands when FF2 is actively running
	if(!Enabled || RoundCount<arenaRounds || CheckRoundState()==-1)
	{
		return Plugin_Continue;
	}

	// autoteam doesn't come with arguments
	if(StrEqual(command, "autoteam", false))
	{
		int team=view_as<int>(TFTeam_Unassigned), oldTeam=GetClientTeam(client);
		if(IsBoss(client))
		{
			team=BossTeam;
		}
		else
		{
			team=OtherTeam;
		}

		if(team!=oldTeam)
		{
			ChangeClientTeam(client, team);
		}
		return Plugin_Handled;
	}

	if(!args)
	{
		return Plugin_Continue;
	}

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

	if(team==BossTeam && !IsBoss(client))
	{
		team=OtherTeam;
	}
	else if(team==OtherTeam && IsBoss(client))
	{
		team=BossTeam;
	}

	if(team>view_as<int>(TFTeam_Unassigned) && team!=oldTeam)
	{
		ChangeClientTeam(client, team);
	}

	if(CheckRoundState()!=1 && !IsBoss(client) || !IsPlayerAlive(client))  //No point in showing the VGUI if they can't change teams
	{
		switch(team)
		{
			case TFTeam_Red:
			{
				ShowVGUIPanel(client, "class_red");
			}
			case TFTeam_Blue:
			{
				ShowVGUIPanel(client, "class_blue");
			}
		}
	}
	return Plugin_Handled;
}

public Action OnRPS(Handle event, const char[] eventName, bool dontBroadcast)
{
	int winner = GetEventInt(event, "winner");
	int loser = GetEventInt(event, "loser");

	if(!IsValidClient(winner) || !IsValidClient(loser)) // Check for valid clients
	{
		return;
	}

	if(!IsBoss(winner) && IsBoss(loser) && GetBossIndex(loser)>=0 && GetConVarInt(cvarRPSLimit)>0)	// Boss Loses on RPS?
	{
		RPSWinner=winner;
		TF2_AddCondition(RPSWinner, TFCond_NoHealingDamageBuff, 3.4);	// I'm not bothered checking for mini-crit boost or not during damage
		CreateTimer(3.1, Timer_RPS, loser, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	if(ClientCookie[winner]!=TOGGLE_OFF && ClientCookie[loser]!=TOGGLE_OFF && !IsBoss(winner) && !IsBoss(loser) && GetClientQueuePoints(loser)>=GetConVarInt(cvarRPSPoints) && GetConVarInt(cvarRPSPoints)>0)	// Teammate or Minion loses?
	{
		CPrintToChat(winner, "{olive}[FF2]{default} %t", "rps_won", GetConVarInt(cvarRPSPoints), loser);
		SetClientQueuePoints(winner, GetClientQueuePoints(winner)+GetConVarInt(cvarRPSPoints));

		CPrintToChat(loser, "{olive}[FF2]{default} %t", "rps_lost", GetConVarInt(cvarRPSPoints), winner);
		SetClientQueuePoints(loser, GetClientQueuePoints(loser)-GetConVarInt(cvarRPSPoints));
	}
}

public Action OnStartCapture(Handle event, const char[] eventName, bool dontBroadcast)
{
	if(!isCapping)
	{
		isCapping=true;
	}
}

public Action OnBreakCapture(Handle event, const char[] eventName, bool dontBroadcast)
{
	if(!GetEventFloat(event, "time_remaining") && isCapping)
	{
		isCapping=false;
	}
}

public void EndBossRound()
{
	if(!GetConVarBool(cvarCountdownResult))
	{
		for(int client=1; client<=MaxClients; client++)  //Thx MasterOfTheXP
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				ForcePlayerSuicide(client);
			}
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
		{
			OTCount=GetRandomInt(-3, 0);
		}
		return Plugin_Continue;
	}

	OTCount++;
	return Plugin_Continue;
}

public Action OnPlayerDeath(Handle event, const char[] eventName, bool dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=1)
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(GetEventInt(event, "userid")), attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	char sound[PLATFORM_MAX_PATH];
	CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	DoOverlay(client, "");
	if(!IsBoss(client))
	{
		if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			CreateTimer(1.0, Timer_Damage, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}

		if(IsBoss(attacker))
		{
			int boss=GetBossIndex(attacker);
			bool firstBloodSound=true;
			if(firstBlood)  //TF_DEATHFLAG_FIRSTBLOOD is broken
			{
				if(RandomSound("sound_first_blood", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					firstBloodSound=false;
				}
				firstBlood=false;
			}

			if(RedAlivePlayers!=1 && KSpreeCount[boss]<2 && firstBloodSound)  //Don't conflict with end-of-round sounds, killing spree, or first blood
			{
				int ClassKill=GetRandomInt(0, 1);
				char classnames[][]={"", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
				char class[32];
				Format(class, sizeof(class), "sound_kill_%s", classnames[TF2_GetPlayerClass(client)]);
				if(RandomSound(class, sound, sizeof(sound), boss) && ClassKill)
				{
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
				}
				else if(RandomSound("sound_hit", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
				}
			}

			if(GetGameTime()<=KSpreeTimer[boss])
			{
				KSpreeCount[boss]++;
			}
			else
			{
				KSpreeCount[boss]=1;
			}

			if(RedAlivePlayers!=1 && KSpreeCount[boss]==3)
			{
				if(RandomSound("sound_kspree", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
				}
				KSpreeCount[boss]=0;
			}
			else
			{
				KSpreeTimer[boss]=GetGameTime()+5.0;
			}
		}
	}
	else
	{
		int boss=GetBossIndex(client);
		if(boss==-1 || (GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
		{
			return Plugin_Continue;
		}

		if(RandomSound("sound_death", sound, sizeof(sound), boss))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
		}

		BossHealth[boss]=0;
		UpdateHealthBar();

		Stabbed[boss]=0.0;
		Marketed[boss]=0.0;
		Cabered[boss]=0.0;
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
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client, false))
	{
		CPrintToChat(client, "{olive}[FF2] %t. %t{default}", "damage", Damage[client], "scores", RoundFloat(Damage[client]/PointsInterval2));
	}
	return Plugin_Continue;
}

public Action OnObjectDeflected(Handle event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || GetEventInt(event, "weaponid"))  //0 means that the client was airblasted, which is what we want
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(GetEventInt(event, "ownerid"));
	int boss=GetBossIndex(client);
	if(boss!=-1 && BossCharge[boss][0]<rageMax[client])
	{
		BossCharge[boss][0]+=rageMax[client]*7.0/rageMin[client];  //TODO: Allow this to be customizable
		if(BossCharge[boss][0]>rageMax[client])
		{
			BossCharge[boss][0]=rageMax[client];
		}
	}
	return Plugin_Continue;
}

public Action OnJarate(UserMsg msg_id, Handle bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int client=BfReadByte(bf);
	int victim=BfReadByte(bf);
	int boss=GetBossIndex(victim);
	if(boss!=-1)
	{
		int jarate=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if(jarate!=-1)
		{
			int index=GetEntProp(jarate, Prop_Send, "m_iItemDefinitionIndex");
			if((index==58 || index==1083 || index==1105) && GetEntProp(jarate, Prop_Send, "m_iEntityLevel")!=-122)  //-122 is the Jar of Ants which isn't really Jarate
			{
				BossCharge[boss][0]-=rageMax[victim]*8.0/rageMin[victim];  //TODO: Allow this to be customizable
				if(BossCharge[boss][0]<0.0)
				{
					BossCharge[boss][0]=0.0;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action OnDeployBackup(Handle event, const char[] name, bool dontBroadcast)
{
	if(Enabled && GetEventInt(event, "buff_type")==2)
	{
		FF2flags[GetClientOfUserId(GetEventInt(event, "buff_owner"))]|=FF2FLAG_ISBUFFED;
	}
	return Plugin_Continue;
}

public Action Timer_CheckAlivePlayers(Handle timer)
{
	if(CheckRoundState()==2)
	{
		return Plugin_Continue;
	}

	RedAlivePlayers=0;
	BlueAlivePlayers=0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(GetClientTeam(client)==OtherTeam)
			{
				RedAlivePlayers++;
			}
			else if(GetClientTeam(client)==BossTeam)
			{
				BlueAlivePlayers++;
			}
		}
	}

	Call_StartForward(OnAlivePlayersChanged);  //Let subplugins know that the number of alive players just changed
	Call_PushCell(RedAlivePlayers);
	Call_PushCell(BlueAlivePlayers);
	Call_Finish();

	if(!RedAlivePlayers)
	{
		ForceTeamWin(BossTeam);
	}
	else if(RedAlivePlayers==1 && BlueAlivePlayers && Boss[0] && !DrawGameTimer && LastMan)
	{
		char sound[PLATFORM_MAX_PATH];
		if(RandomSound("sound_lastman", sound, sizeof(sound)))
		{
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
			EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
		}
		LastMan=false;
	}
	else if(PointType!=1 && RedAlivePlayers<=AliveToEnable && !executed)
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
			{
				if(RedAlivePlayers>1 && GetConVarBool(cvarGameText))
				{
					ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "point_enable", AliveToEnable);
				}
				else
				{
					PrintHintText(client, "%t", "point_enable", AliveToEnable);
				}
			}
		}
		if(RedAlivePlayers==AliveToEnable)
		{
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
		executed=true;
	}

	if(RedAlivePlayers<=countdownPlayers && BossHealth[0]>countdownHealth && countdownTime>1 && !executed2)
	{
		if(FindEntityByClassname2(-1, "team_control_point")!=-1)
		{
			timeleft=countdownTime;
			DrawGameTimer=CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		executed2=true;
	}
	return Plugin_Continue;
}

public Action Timer_DrawGame(Handle timer)
{
	if(BossHealth[0]<countdownHealth || CheckRoundState()!=1 || RedAlivePlayers>countdownPlayers)
	{
		executed2=false;
		return Plugin_Stop;
	}

	int time=timeleft;
	timeleft--;
	char timeDisplay[6];
	if(time/60>9)
	{
		IntToString(time/60, timeDisplay, sizeof(timeDisplay));
	}
	else
	{
		Format(timeDisplay, sizeof(timeDisplay), "0%i", time/60);
	}

	if(time%60>9)
	{
		Format(timeDisplay, sizeof(timeDisplay), "%s:%i", timeDisplay, time%60);
	}
	else
	{
		Format(timeDisplay, sizeof(timeDisplay), "%s:0%i", timeDisplay, time%60);
	}

	SetHudTextParams(-1.0, 0.17, 1.1, 255, 255, 255, 255);

	char message[512], name[64];
	for(int client; client<=MaxClients; client++)
	{
		if(IsBoss(client))
		{
			int boss2=GetBossIndex(client);
			KvRewind(BossKV[Special[boss2]]);
			KvGetString(BossKV[Special[boss2]], "name", name, sizeof(name), "=Failed name=");
			char bossLives[10];
			if(BossLives[boss2]>1)
			{
				Format(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);
			}
			else
			{
				Format(bossLives, sizeof(bossLives), "");
			}
			Format(message, sizeof(message), "%s\n%t", message, "ff2_hp", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives);
		}
	}
	for(int client; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			if(!Companions && GetConVarBool(cvarGameText) && RedAlivePlayers==1)
			{
				if(timeleft<=countdownTime && timeleft>=countdownTime/2)
				{
					ShowGameText(client, "ico_notify_sixty_seconds", _, "%s | %s", message, timeDisplay);
				}
				else if(timeleft<countdownTime/2 && timeleft>=countdownTime/6)
				{
					ShowGameText(client, "ico_notify_thirty_seconds", _, "%s | %s", message, timeDisplay);
				}
				else if(timeleft<countdownTime/6 && timeleft>0)
				{
					ShowGameText(client, "ico_notify_ten_seconds", _, "%s | %s", message, timeDisplay);
				}
				else if(isCapping)
				{
					ShowGameText(client, "ico_notify_flag_moving_alt", _, "%s | %t", message, "Overtime");
				}
				else if(GhostBoss)
				{
					ShowGameText(client, "ico_ghost", _, "%s | %s", message, timeDisplay);
				}
				else
				{
					ShowGameText(client, "leaderboard_streak", _, "%s | %s", message, timeDisplay);
				}
			}
			else if(!Companions && GetConVarInt(cvarGameText)==2)
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
				else if(GhostBoss)
				{
					ShowGameText(client, "ico_ghost", _, timeDisplay);
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
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	int boss=GetBossIndex(client);
	int damage=GetEventInt(event, "damageamount");
	int custom=GetEventInt(event, "custom");
	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]) || client==attacker)
	{
		return Plugin_Continue;
	}

	if(custom==TF_CUSTOM_TELEFRAG)
	{
		damage=IsPlayerAlive(attacker) ? 9001 : 1;
	}
	else if(custom==TF_CUSTOM_BOOTS_STOMP)
	{
		damage*=5;
	}

	if(GetEventBool(event, "minicrit") && GetEventBool(event, "allseecrit"))
	{
		SetEventBool(event, "allseecrit", false);
	}

	if(custom==TF_CUSTOM_TELEFRAG || custom==TF_CUSTOM_BOOTS_STOMP)
	{
		SetEventInt(event, "damageamount", damage);
	}

	for(int lives=1; lives<BossLives[boss]; lives++)
	{
		if(BossHealth[boss]-damage<=BossHealthMax[boss]*lives)
		{
			SetEntityHealth(client, (BossHealth[boss]-damage)-BossHealthMax[boss]*(lives-1)); //Set the health early to avoid the boss dying from fire, etc.

			Action action=Plugin_Continue;  //Used for the forward
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
			else if(action==Plugin_Changed)
			{
				if(bossLives>BossLivesMax[boss])
				{
					BossLivesMax[boss]=bossLives;
				}
				BossLives[boss]=bossLives;
			}

			char ability[PLATFORM_MAX_PATH];
			for(int n=1; n<MAXRANDOMS; n++)
			{
				Format(ability, 10, "ability%i", n);
				KvRewind(BossKV[Special[boss]]);
				if(KvJumpToKey(BossKV[Special[boss]], ability))
				{
					if(KvGetNum(BossKV[Special[boss]], "arg0", 0)!=-1)
					{
						continue;
					}

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
							if(StringToInt(stringLives[j])==BossLives[boss])
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
			}
			BossLives[boss]=lives;

			char bossName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "=Failed name=");

			strcopy(ability, sizeof(ability), BossLives[boss]==1 ? "ff2_life_left" : "ff2_lives_left");
			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					if(!Companions && GetConVarBool(cvarGameText))
					{
						ShowGameText(target, "ico_notify_flag_moving_alt", _, "%t", ability, bossName, BossLives[boss]);
					}
					else
					{
						PrintCenterText(target, "%t", ability, bossName, BossLives[boss]);
					}
				}
			}

			if(BossLives[boss]==1 && RandomSound("sound_last_life", ability, sizeof(ability), boss))
			{
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, ability, _, _, _, _, _, _, _, _, _, false);
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, ability, _, _, _, _, _, _, _, _, _, false);
			}
			else if(RandomSound("sound_nextlife", ability, sizeof(ability), boss))
			{
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, ability, _, _, _, _, _, _, _, _, _, false);
				EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, ability, _, _, _, _, _, _, _, _, _, false);
			}

			UpdateHealthBar();
			break;
		}
	}

	BossHealth[boss]-=damage;
	BossCharge[boss][0]+=damage*100.0/BossRageDamage[boss];
	Damage[attacker]+=damage;

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

	if(IsValidClient(attacker) && IsValidClient(client) && client!=attacker && damage>0 && GetClientTeam(attacker)==OtherTeam)
	{
		int i;
		float position[3];
		GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
		if(GetConVarFloat(cvarAirStrike)>0)  //Air Strike-moved from OTD
		{
			int weapon=GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
			if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==1104)
			{
				AirstrikeDamage[attacker]+=damage;
				while(AirstrikeDamage[attacker]>=GetConVarFloat(cvarAirStrike) && i<26)
				{
					i++;
					SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
					AirstrikeDamage[attacker]-=GetConVarFloat(cvarAirStrike);
				}
			}
		}
		if(GetConVarFloat(cvarDmg2KStreak)>0)
		{
			KillstreakDamage[attacker]+=damage;
			while(KillstreakDamage[attacker]>=GetConVarFloat(cvarDmg2KStreak) && i<26)
			{
				i++;
				SetEntProp(attacker, Prop_Send, "m_nStreaks", GetEntProp(attacker, Prop_Send, "m_nStreaks")+1);
				KillstreakDamage[attacker]-=GetConVarFloat(cvarDmg2KStreak);
			}
		}
		if(SapperCooldown[attacker]>0.0)
		{
			SapperCooldown[attacker]-=damage;
		}
	}

	if(BossCharge[boss][0]>rageMax[client])
	{
		BossCharge[boss][0]=rageMax[client];
	}
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
	{
		return Plugin_Continue;
	}

	int client=GetClientOfUserId(GetEventInt(event, "patient"));
	int healer=GetClientOfUserId(GetEventInt(event, "healer"));
	int heals=GetEventInt(event, "amount");
	if(client==healer)
	{
		return Plugin_Continue;
	}

	Healing[healer]+=heals;
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!Enabled || CheckRoundState()!=1)
		return Plugin_Continue;

	int index=-1;
	int entity=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
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
					boss=FF2_GetBossIndex(target);
					GetEntPropVector(target, Prop_Send, "m_vecOrigin", position2);
					distance=GetVectorDistance(position, position2);
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
							SapperCooldown[client]=GetConVarFloat(cvarSapperCooldown);
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
							SapperCooldown[client]=GetConVarFloat(cvarSapperCooldown);
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
	{
		return Plugin_Continue;
	}

	static bool foundDmgCustom, dmgCustomInOTD;
	if(!foundDmgCustom)
	{
		dmgCustomInOTD=(GetFeatureStatus(FeatureType_Capability, "SDKHook_DmgCustomInOTD")==FeatureStatus_Available);
		foundDmgCustom=true;
	}

	//ABILITY TO ROCKET JUMP PT1
	if((attacker<=0 || client==attacker) && IsBoss(client) && damagetype & DMG_FALL && selfKnockback[attacker])
	{
		damage*=1.0;
		return Plugin_Changed;
	}
	else if((attacker<=0 || client==attacker) && IsBoss(client) && !selfKnockback[attacker])
	{
		return Plugin_Handled;
	}
	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
	{
		return Plugin_Continue;
	}
	/*if(!CheckRoundState() && IsBoss(client) && !selfKnockback[attacker])
	{
		damage*=0.0;
		return Plugin_Changed;
	}*/
	//END OF PART 1

	float position[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
	if(IsValidClient(attacker) && GetClientTeam(attacker)==BossTeam && shield[client] && damage>0 && GetConVarInt(cvarShieldType)==3) // Absorbs damage from bosses AND minions
	{
		if(!(damagetype & DMG_CLUB) && shieldHP[client]>0.0 && RoundToFloor(damage)<GetClientHealth(client))
		{
			damage*=shDmgReduction[client]; // damage resistance on shield
			
			shieldHP[client]-=damage;		// take a small portion of shield health away	
			
			if(shDmgReduction[client]>=1.0)
			{
				shDmgReduction[client]=1.0;
			}
			else
			{
				shDmgReduction[client]+=0.03;
			}
						
			char ric[PLATFORM_MAX_PATH];
			Format(ric, sizeof(ric), "weapons/fx/rics/ric%i.wav", GetRandomInt(1,5));
			EmitSoundToClient(client, ric, _, _, _, _, 0.7, _, _, position, _, false);
			EmitSoundToClient(attacker, ric, _, _, _, _, 0.7, _, _, position, _, false);
			return Plugin_Changed;
		}
		else
		{
			RemoveShield(client, attacker, position);
			return Plugin_Stop;					
		}
	}
	else if(IsValidClient(attacker) && GetClientTeam(attacker)==BossTeam && shield[client] && damage>0 && GetConVarInt(cvarShieldType)==4)
	{
		if(damagetype & DMG_CRIT)
			damage*=damage*3.0;
		else if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed) || TF2_IsPlayerInCondition(attacker, TFCond_NoHealingDamageBuff))
			damage*=damage*1.35;

		damage*=shDmgReduction[client];	// damage resistance on shield

		shieldHP[client]-=damage;	// take a small portion of shield health away

		if(shDmgReduction[client]>=1.0)
		{
			shDmgReduction[client]=1.0;
		}
		else
		{
			shDmgReduction[client]+=0.03;
		}

		int health=GetClientHealth(client);
		if(shieldHP[client]<=0.0 || health<=damage)
		{
			RemoveShield(client, attacker, position);
		}

		char ric[PLATFORM_MAX_PATH];
		Format(ric, sizeof(ric), "weapons/fx/rics/ric%i.wav", GetRandomInt(1,5));
		EmitSoundToClient(client, ric, _, _, _, _, 0.7, _, _, position, _, false);
		EmitSoundToClient(attacker, ric, _, _, _, _, 0.7, _, _, position, _, false);

		return Plugin_Changed;
	}
	else if(IsValidClient(attacker) && GetClientTeam(attacker)==BossTeam && shield[client] && damage>0 && GetConVarInt(cvarShieldType)==2)
	{
		if(damagetype & DMG_CRIT)
			damage=damage*3.0;
		else if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed) || TF2_IsPlayerInCondition(attacker, TFCond_NoHealingDamageBuff))
			damage=damage*1.35;

		int health=GetClientHealth(client);
		if(health<=damage)
		{
			RemoveShield(client, attacker, position);
		}
	}
	if(IsBoss(attacker))
	{
		if(IsValidClient(client) && !IsBoss(client) && !TF2_IsPlayerInCondition(client, TFCond_Bonked))
		{
			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);
				damage*=0.3;
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffMmmph))
			{
				damage*=9;
				TF2_AddCondition(client, TFCond_Bonked, 0.1);
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
			{
				damage*=0.25;
				return Plugin_Changed;
			}

			if(shield[client] && damage && GetConVarInt(cvarShieldType)==1)
			{
				RemoveShield(client, attacker, position);
				return Plugin_Handled;
			}

			if(damage<=160.0 && dmgTriple[attacker])
			{
				damage*=3;
				return Plugin_Changed;
			}
		}
	}
	else
	{
		int boss=GetBossIndex(client);
		if(boss!=-1)
		{
			//ABILITY TO ROCKETJUMP PART2
			if(damagetype & DMG_FALL && selfKnockback[client])
			{
				damage=1.0;
				return Plugin_Changed;
			}
			//END OF PART 2
			if(attacker<=MaxClients)
			{
				bool bIsTelefrag, bIsBackstab;
				if(dmgCustomInOTD)
				{
					if(damagecustom==TF_CUSTOM_BACKSTAB)
					{
						bIsBackstab=true;
					}
					else if(damagecustom==TF_CUSTOM_TELEFRAG)
					{
						bIsTelefrag=true;
					}
				}
				else if(weapon!=4095 && IsValidEntity(weapon) && weapon==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage>1000.0)
				{
					char classname[32];
					if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_knife", false))
					{
						bIsBackstab=true;
					}
				}
				else if(!IsValidEntity(weapon) && (damagetype & DMG_CRUSH)==DMG_CRUSH && damage==1000.0)
				{
					bIsTelefrag=true;
				}

				int index;
				char classname[64];
				if(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients)
				{
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(!StrContains(classname, "eyeball_boss"))  //Dang spell Monoculuses
					{
						index=-1;
						Format(classname, sizeof(classname), "");
					}
					else
					{
						index=GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					}
				}
				else
				{
					index=-1;
					Format(classname, sizeof(classname), "");
				}

				//Sniper rifles aren't handled by the switch/case because of the amount of reskins there are
				if(!StrContains(classname, "tf_weapon_sniperrifle"))
				{
					if(CheckRoundState()!=2)
					{
						float charge=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						if(index==752)  //Hitman's Heatmaker
						{
							float focus=10+(charge/10);
							if(TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
							{
								focus/=3;
							}
							float rage=GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
							SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage+focus>100) ? 100.0 : rage+focus);
						}
						else if(index!=230 && index!=402 && index!=526 && index!=30665)  //Sydney Sleeper, Bazaar Bargain, Machina, Shooting Star
						{
							float time=(GlowTimer[boss]>10 ? 1.0 : 2.0);
							time+=(GlowTimer[boss]>10 ? (GlowTimer[boss]>20 ? 1.0 : 2.0) : 4.0)*(charge/100.0);
							SetClientGlow(Boss[boss], time);
							if(GlowTimer[boss]>25.0)
							{
								GlowTimer[boss]=25.0;
							}
						}

						if(!(damagetype & DMG_CRIT))
						{
							if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
							{
								damage*=SniperMiniDamage;
							}
							else
							{
								if(index!=230 || BossCharge[boss][0]>90.0)  //Sydney Sleeper
								{
									damage*=SniperDamage;
								}
								else
								{
									damage*=(SniperDamage*0.8);
								}
							}
							return Plugin_Changed;
						}
					}
				}
				else if(!StrContains(classname, "tf_weapon_compound_bow"))
				{
					if(CheckRoundState()!=2)
					{
						if((damagetype & DMG_CRIT))
						{
							damage*=BowDamage;
							return Plugin_Changed;
						}
						else if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
						{
							if(BowDamageMini>0)
							{
								damage*=BowDamageMini;
								return Plugin_Changed;
							}
						}
						else if(BowDamageNon>0)
						{
							damage*=BowDamageNon;
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
							if(damagecustom==TF_CUSTOM_HEADSHOT)
							{
								damage=85.0;  //Final damage 255
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
							int health=GetClientHealth(attacker);
							int newhealth=health+25;
							if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
							{
								SetEntityHealth(attacker, newhealth);
							}
						}
					}
					case 307:  //Ullapool Caber
					{
						if(GetEntProp(weapon, Prop_Send, "m_iDetonated") == 0)	// If using ullapool caber, only trigger if bomb hasn't been detonated
                        			{
							if(GetConVarBool(cvarLowStab))
								damage=(Pow(float(BossHealthMax[boss]), 0.74074)+(2000.0/float(playing))+206.0-(Cabered[client]/128.0*float(BossHealthMax[boss])))/(3+(allowedDetonations*3));
							else
								damage=(Pow(float(BossHealthMax[boss]), 0.74074)+512.0-(Cabered[client]/128.0*float(BossHealthMax[boss])))/(3+(allowedDetonations*3));
							damagetype|=DMG_CRIT;

							if(Cabered[client]<5)
							{
								Cabered[client]++;
							}

							if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
							{
								if(TellName)
								{
									char spcl[768];
									KvGetString(BossKV[Special[boss]], "name", spcl, sizeof(spcl), "=Failed name=");
									if(Annotations==1)
										CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Caber Player", spcl);
									else if(Annotations==2)
										ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Caber Player", spcl);
									else
										PrintHintText(attacker, "%t", "Caber Player", spcl);
								}
								else
								{
									if(Annotations==1)
										CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Caber");
									else if(Annotations==2)
										ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Caber");
									else
										PrintHintText(attacker, "%t", "Caber");
								}
							}
							if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
							{
								if(TellName)
								{
									if(Annotations==1)
										CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Cabered Player", attacker);
									else if(Annotations==2)
										ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Cabered Player", attacker);
									else
										PrintHintText(client, "%t", "Cabered Player", attacker);
								}
								else
								{
									if(Annotations==1)
										CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Cabered");
									else if(Annotations==2)
										ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Cabered");
									else
										PrintHintText(client, "%t", "Cabered");
								}
							}

							EmitSoundToClient(attacker, "ambient/lightsoff.wav", _, _, _, _, 0.6, _, _, position, _, false);
							EmitSoundToClient(client, "ambient/lightson.wav", _, _, _, _, 0.6, _, _, position, _, false);

							char sound[PLATFORM_MAX_PATH];
							if(RandomSound("sound_cabered", sound, sizeof(sound)))
							{
								EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
								EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
							}
							return Plugin_Changed;
						}
					}
					case 310:  //Warrior's Spirit
					{
						if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0)
						{
							int health=GetClientHealth(attacker);
							int newhealth=health+50;
							if(newhealth<=GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
							{
								SetEntityHealth(attacker, newhealth);
							}
						}
					}
					case 317:  //Candycane
					{
						SpawnSmallHealthPackAt(client, GetClientTeam(attacker), attacker);
					}
					case 327:  //Claidheamh Mòr
					{
						if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0)
						{
							float charge=GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter");
							if(charge+25.0>=100.0)
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
							int health=GetClientHealth(attacker);
							int max=GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
							int newhealth=health+5;
							if(health<max+60)
							{
								if(newhealth>max+60)
								{
									newhealth=max+60;
								}
								SetEntityHealth(attacker, newhealth);
							}
						}
					}
					case 357:  //Half-Zatoichi
					{
						int health=GetClientHealth(attacker);
						int max=GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						int max2=RoundToFloor(max*2.0);
						int newhealth;
						if(GetEntProp(weapon, Prop_Send, "m_bIsBloody"))	// Less effective used more than once
						{
							newhealth=health+25;
							if(health<max2)
							{
								if(newhealth>max2)
								{
									newhealth=max2;
								}
								SetEntityHealth(attacker, newhealth);
							}
						}
						else	// Most effective on first hit
						{
							newhealth=health+RoundToFloor(max/2.0);
							if(health<max2)
							{
								if(newhealth>max2)
								{
									newhealth=max2;
								}
								SetEntityHealth(attacker, newhealth);
							}
							if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
							{
								TF2_RemoveCondition(attacker, TFCond_OnFire);
							}
						}
						SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
						if(GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy")<1)
						{
							SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
						}
					}
					case 416:  //Market Gardener (courtesy of Chdata)
					{
						if (RemoveCond(attacker, TFCond_BlastJumping))	// New way to check explosive jumping status
						//if(FF2flags[attacker] & FF2FLAG_ROCKET_JUMPING)
                        			{
							if(GetConVarBool(cvarLowStab))
								damage=(Pow(float(BossHealthMax[boss]), 0.74074)+(1750.0/float(playing))+206.0-(Marketed[client]/128.0*float(BossHealthMax[boss])))/3;
							else
								damage=(Pow(float(BossHealthMax[boss]), 0.74074)+512.0-(Marketed[client]/128.0*float(BossHealthMax[boss])))/3;
							damagetype|=DMG_CRIT;

							if(RemoveCond(attacker, TFCond_Parachute))	// If you parachuted to do this, remove your parachute.
							{
								damage*=0.8;	//  And nerf your damage
							}
							if(Marketed[client]<5)
							{
								Marketed[client]++;
							}

							if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
							{
								if(TellName)
								{
									char spcl[768];
									KvGetString(BossKV[Special[boss]], "name", spcl, sizeof(spcl), "=Failed name=");
									if(Annotations==1)
										CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Market Gardener Player", spcl);
									else if(Annotations==2)
										ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Market Gardener Player", spcl);
									else
										PrintHintText(attacker, "%t", "Market Gardener Player", spcl);
								}
								else
								{
									if(Annotations==1)
										CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Market Gardener");
									else if(Annotations==2)
										ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Market Gardener");
									else
										PrintHintText(attacker, "%t", "Market Gardener");
								}
							}
							if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
							{
								if(TellName)
								{
									if(Annotations==1)
										CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Market Gardened Player", attacker);
									else if(Annotations==2)
										ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Market Gardened Player", attacker);
									else
										PrintHintText(client, "%t", "Market Gardened Player", attacker);
								}
								else
								{
									if(Annotations==1)
										CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Market Gardened");
									else if(Annotations==2)
										ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Market Gardened");
									else
										PrintHintText(client, "%t", "Market Gardened");
								}
							}

							EmitSoundToClient(attacker, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
							EmitSoundToClient(client, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);

							char sound[PLATFORM_MAX_PATH];
							if(RandomSound("sound_marketed", sound, sizeof(sound)))
							{
								EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
								EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
							}
							return Plugin_Changed;
						}
					}
					case 525, 595:  //Diamondback, Manmelter
					{
						if(kvWeaponMods == null || GetConVarInt(cvarHardcodeWep)>0)
						{
							if(GetEntProp(attacker, Prop_Send, "m_iRevengeCrits"))  //If a revenge crit was used, give a damage bonus
							{
								damage=85.0;  //255 final damage
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
										{
											uber=1.0;
										}
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
					if(GetConVarBool(cvarLowStab))
						damage=(BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.11-Stabbed[boss]/90)+(1500/float(playing)))/3;
					else
						damage=BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.12-Stabbed[boss]/90)/3;
					damagetype|=DMG_CRIT;
					damagecustom=0;

					EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);

					int viewmodel=GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
					if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
					{
						int melee=GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
						int animation=41;
						switch(melee)
						{
							case 225, 356, 423, 461, 574, 649, 1071, 30758:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan, Prinny Machete
							{
								animation=15;
							}
							case 638:  //Sharp Dresser
							{
								animation=31;
							}
						}
						SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
					}

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							char spcl[768];
							KvGetString(BossKV[Special[boss]], "name", spcl, sizeof(spcl), "=Failed name=");
							if(Annotations==1)
								CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Backstab Player", spcl);
							else if(Annotations==2)
								ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Backstab Player", spcl);
							else
								PrintHintText(attacker, "%t", "Backstab Player", spcl);
						}
						else
						{
							if(Annotations==1)
								CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Backstab");
							else if(Annotations==2)
								ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Backstab");
							else
								PrintHintText(attacker, "%t", "Backstab");
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
								if(Annotations==1)
									CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Backstabbed Player", attacker);
								else if(Annotations==2)
									ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Backstabbed Player", attacker);
								else
									PrintHintText(client, "%t", "Backstabbed Player", attacker);
							}
							else
							{
								if(Annotations==1)
									CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Backstabbed");
								else if(Annotations==2)
									ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Backstabbed");
								else
									PrintHintText(client, "%t", "Backstabbed");
							}
						}

						char sound[PLATFORM_MAX_PATH];
						if(RandomSound("sound_stabbed", sound, sizeof(sound), boss))
						{
							EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[boss], _, _, false);
							EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, Boss[boss], _, _, false);
						}
					}
					if(index==225 || index==574)  //Your Eternal Reward, Wanga Prick
					{
						CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
					}
					else if(index==356)  //Conniver's Kunai
					{
						int health=GetClientHealth(attacker)+200;
						if(health>600)
						{
							health=600;
						}
						SetEntityHealth(attacker, health);
					}
					else if(index==461)  //Big Earner
					{
						SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);  //Full cloak
						TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);  //Speed boost
					}

					if(GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary)==525)  //Diamondback
					{
						SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+3);
					}

					if(Stabbed[boss]<3)
					{
						Stabbed[boss]++;
					}
					return Plugin_Changed;
				}
				else if(bIsTelefrag)
				{
					damagecustom=0;
					if(!IsPlayerAlive(attacker))
					{
						damage=1.0;
						return Plugin_Changed;
					}
					damage=(BossHealth[boss]>9001 ? 9001.0 : float(GetEntProp(Boss[boss], Prop_Send, "m_iHealth"))+90.0);

					for(int all; all<=MaxClients; all++)
					{
						if(IsValidClient(all) && IsPlayerAlive(all))
						{
							if(!(FF2flags[all] & FF2FLAG_HUDDISABLED))
							{
								if(Annotations==1)
									CreateAttachedAnnotation(all, client, true, 5.0, "%t", "Telefrag Global");
								else if(Annotations==2)
									ShowGameText(all, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Global");
								else
									PrintHintText(all, "%t", "Telefrag Global");
							}
						}
					}

					int teleowner=FindTeleOwner(attacker);
					if(IsValidClient(teleowner) && teleowner!=attacker)
					{
						Damage[teleowner]+=9001*3/5;
						if(!(FF2flags[teleowner] & FF2FLAG_HUDDISABLED))
						{
							if(Annotations==1)
								CreateAttachedAnnotation(teleowner, client, true, 5.0, "%t", "Telefrag Assist");
							else if(Annotations==2)
								ShowGameText(teleowner, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Assist");
							else
								PrintHintText(teleowner, "%t", "Telefrag Assist");
						}
					}

					if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							char spcl[768];
							KvGetString(BossKV[Special[boss]], "name", spcl, sizeof(spcl), "=Failed name=");
							if(Annotations==1)
								CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Telefrag Player", spcl);
							else if(Annotations==2)
								ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Player", spcl);
							else
								PrintHintText(attacker, "%t", "Telefrag Player", spcl);
						}
						else
						{
							if(Annotations==1)
								CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Telefrag");
							else if(Annotations==2)
								ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Telefrag");
							else
								PrintHintText(attacker, "%t", "Telefrag");
						}
					}

					if(!(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							if(Annotations==1)
								CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Telefraged Player", attacker);
							else if(Annotations==2)
								ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Telefraged Player", attacker);
							else
								PrintHintText(client, "%t", "Telefrged Player", attacker);
						}
						else
						{
							if(Annotations==1)
								CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Telefraged");
							else if(Annotations==2)
								ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Telefraged");
							else
								PrintHintText(client, "%t", "Telefraged");
						}
					}

					char sound[PLATFORM_MAX_PATH];
					if(RandomSound("sound_telefraged", sound, sizeof(sound)))
					{
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
						EmitSoundToAllExcept(SOUNDEXCEPT_VOICE, sound, _, _, _, _, _, _, _, _, _, false);
					}
					return Plugin_Changed;
				}
			}
			else
			{
				char classname[64];
				if(GetEntityClassname(attacker, classname, sizeof(classname)) && !strcmp(classname, "trigger_hurt", false))
				{
					Action action=Plugin_Continue;
					Call_StartForward(OnTriggerHurt);
					Call_PushCell(boss);
					Call_PushCell(attacker);
					float damage2=damage;
					Call_PushFloatRef(damage2);
					Call_Finish(action);
					if(action!=Plugin_Stop && action!=Plugin_Handled)
					{
						if(action==Plugin_Changed)
						{
							damage=damage2;
						}

						if(damage>600.0)
						{
							damage=600.0;
						}

						BossHealth[boss]-=RoundFloat(damage);
						BossCharge[boss][0]+=damage*100.0/BossRageDamage[boss];
						if(BossHealth[boss]<=0)  //Wat
						{
							damage*=5;
						}

						if(BossCharge[boss][0]>rageMax[client])
						{
							BossCharge[boss][0]=rageMax[client];
						}
						return Plugin_Changed;
					}
					else
					{
						return action;
					}
				}
			}

			if(BossCharge[boss][0]>rageMax[client])
			{
				BossCharge[boss][0]=rageMax[client];
			}
		}
		else
		{
			int index=(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
			if(index==307)  //Ullapool Caber
			{
				if(detonations[attacker]<allowedDetonations)
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

			if(IsValidClient(client, false) && TF2_GetPlayerClass(client)==TFClass_Soldier)  //TODO: LOOK AT THIS
			{
				if(damagetype & DMG_FALL)
				{
					int secondary=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(secondary<=0 || !IsValidEntity(secondary))
					{
						damage/=10.0;
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action TF2_OnPlayerTeleport(int client, int teleporter, bool &result)
{
	if(Enabled && IsBoss(client))
	{
		switch(bossTeleportation)
		{
			case -1:  //No bosses are allowed to use teleporters
			{
				result=false;
			}
			case 1:  //All bosses are allowed to use teleporters
			{
				result=true;
			}
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnStomp(int attacker, int victim, float &damageMultiplier, float &damageBonus, float &JumpPower)
{
	if(!Enabled || !IsValidClient(attacker) || !IsValidClient(victim) || attacker==victim)
	{
		return Plugin_Continue;
	}

	if(IsBoss(attacker))
	{
		int boss=GetBossIndex(attacker);
		if(shield[victim])
		{
			float position[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
			RemoveShield(victim, attacker, position);
			return Plugin_Handled;
		}
		damageMultiplier=900.0;
		JumpPower=0.0;
		if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
		{
			if(TellName)
			{
				if(Annotations==1)
					CreateAttachedAnnotation(attacker, victim, true, 5.0, "%t", "Goomba Stomp Boss Player", victim);
				else if(Annotations==2)
					ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp Boss Player", victim);
				else
					PrintHintText(attacker, "%t", "Goomba Stomp Boss Player", victim);
			}
			else
			{
				if(Annotations==1)
					CreateAttachedAnnotation(attacker, victim, true, 5.0, "%t", "Goomba Stomp Boss");
				else if(Annotations==2)
					ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp Boss");
				else
					PrintHintText(attacker, "%t", "Goomba Stomp Boss");
			}
		}
		if(!(FF2flags[victim] & FF2FLAG_HUDDISABLED))
		{
			if(TellName)
			{
				char spcl[768];
				KvGetString(BossKV[Special[boss]], "name", spcl, sizeof(spcl), "=Failed name=");
				if(Annotations==1)
					CreateAttachedAnnotation(victim, attacker, true, 5.0, "%t", "Goomba Stomped Player", spcl);
				else if(Annotations==2)
					ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped Player", spcl);
				else
					PrintHintText(victim, "%t", "Goomba Stomped Player", spcl);
			}
			else
			{
				if(Annotations==1)
					CreateAttachedAnnotation(victim, attacker, true, 5.0, "%t", "Goomba Stomped");
				else if(Annotations==2)
					ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped");
				else
					PrintHintText(victim, "%t", "Goomba Stomped");
			}
		}
		return Plugin_Changed;
	}
	else if(IsBoss(victim))
	{
		int boss=GetBossIndex(victim);
		damageMultiplier=GoombaDamage;
		JumpPower=reboundPower;
		if(!(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
		{
			if(TellName)
			{
				char spcl[768];
				KvGetString(BossKV[Special[boss]], "name", spcl, sizeof(spcl), "=Failed name=");
				if(Annotations==1)
					CreateAttachedAnnotation(attacker, victim, true, 5.0, "%t", "Goomba Stomp Player", spcl);
				else if(Annotations==2)
					ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp Player", spcl);
				else
					PrintHintText(attacker, "%t", "Goomba Stomp Player", spcl);
			}
			else
			{
				if(Annotations==1)
					CreateAttachedAnnotation(attacker, victim, true, 5.0, "%t", "Goomba Stomp");
				else if(Annotations==2)
					ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp");
				else
					PrintHintText(attacker, "%t", "Goomba Stomp");
			}
		}
		if(!(FF2flags[victim] & FF2FLAG_HUDDISABLED))
		{
			if(TellName)
			{
				if(Annotations==1)
					CreateAttachedAnnotation(victim, attacker, true, 5.0, "%t", "Goomba Stomped Boss Player", attacker);
				else if(Annotations==2)
					ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped Boss Player", attacker);
				else
					PrintHintText(victim, "%t", "Goomba Stomped Boss Player", attacker);
			}
			else
			{
				if(Annotations==1)
					CreateAttachedAnnotation(victim, attacker, true, 5.0, "%t", "Goomba Stomped Boss");
				else if(Annotations==2)
					ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped Boss");
				else
					PrintHintText(victim, "%t", "Goomba Stomped Boss");
			}
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public int OnStompPost(int attacker, int victim, float damageMultiplier, float damageBonus, float jumpPower)
{
	if(Enabled && IsBoss(victim))
	{
		UpdateHealthBar();
	}
}

public Action RTD_CanRollDice(int client)
{
	if(Enabled && IsBoss(client) && !canBossRTD)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action RTD2_CanRollDice(int client)
{
	if(Enabled && IsBoss(client) && !canBossRTD)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnGetMaxHealth(int client, int &maxHealth)
{
	if(Enabled && IsBoss(client))
	{
		int boss=GetBossIndex(client);
		SetEntityHealth(client, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1));
		maxHealth=BossHealthMax[boss];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock int GetClientCloakIndex(int client)
{
	if(!IsValidClient(client, false))
	{
		return -1;
	}

	int weapon=GetPlayerWeaponSlot(client, 4);
	if(!IsValidEntity(weapon))
	{
		return -1;
	}

	char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if(strncmp(classname, "tf_wea", 6, false))
	{
		return -1;
	}
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

stock int SpawnSmallHealthPackAt(int client, int team=0, int attacker)
{
	if(!IsValidClient(client, false) || !IsPlayerAlive(client))
	{
		return;
	}

	int healthpack=CreateEntityByName("item_healthkit_small");
	float position[3];
	GetClientAbsOrigin(client, position);
	position[2]+=20.0;
	if(IsValidEntity(healthpack))
	{
		DispatchKeyValue(healthpack, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(healthpack);
		SetEntProp(healthpack, Prop_Send, "m_iTeamNum", team, 4);
		SetEntityMoveType(healthpack, MOVETYPE_VPHYSICS);
		float velocity[3];//={float(GetRandomInt(-10, 10)), float(GetRandomInt(-10, 10)), 50.0};  //Q_Q
		velocity[0]=float(GetRandomInt(-10, 10)), velocity[1]=float(GetRandomInt(-10, 10)), velocity[2]=50.0;  //I did this because setting it on the creation of the vel variable was creating a compiler error for me.
		TeleportEntity(healthpack, position, NULL_VECTOR, velocity);
		SetEntPropEnt(healthpack, Prop_Send, "m_hOwnerEntity", attacker);
	}
}

stock void IncrementHeadCount(int client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
	{
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);
	}

	int decapitations=GetEntProp(client, Prop_Send, "m_iDecapitations");
	int health=GetClientHealth(client);
	SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations+1);
	SetEntityHealth(client, health+15);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}

stock int FindTeleOwner(int client)
{
	if(!IsValidClient(client) || !IsPlayerAlive(client))
	{
		return -1;
	}

	int teleporter=GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	char classname[32];
	if(IsValidEntity(teleporter) && GetEntityClassname(teleporter, classname, sizeof(classname)) && !strcmp(classname, "obj_teleporter", false))
	{
		int owner=GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
		if(IsValidClient(owner, false))
		{
			return owner;
		}
	}
	return -1;
}

stock bool TF2_IsPlayerCritBuffed(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, view_as<TFCond>(34)) || TF2_IsPlayerInCondition(client, view_as<TFCond>(35)) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph));
}

public Action Timer_DisguiseBackstab(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(IsValidClient(client, false))
	{
		RandomlyDisguise(client);
	}
	return Plugin_Continue;
}

stock void AssignTeam(int client, int team)
{
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))  //Living spectator check: 0 means that no class is selected
	{
		Debug("%N does not have a desired class", client);
		if(IsBoss(client))
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", KvGetNum(BossKV[Special[Boss[client]]], "class", 1));  //So we assign one to prevent living spectators
		}
		else
		{
			Debug("%N was not a boss and did not have a desired class", client);
		}
	}

	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);

	if(GetEntProp(client, Prop_Send, "m_iObserverMode") && IsPlayerAlive(client))  //Welp
	{
		Debug("%N is a living spectator", client);
		if(IsBoss(client))
		{
			TF2_SetPlayerClass(client, view_as<TFClassType>(KvGetNum(BossKV[Special[Boss[client]]], "class", 1)));
		}
		else
		{
			Debug("Additional information: %N was not a boss", client);
			TF2_SetPlayerClass(client, TFClass_Heavy);
		}
		TF2_RespawnPlayer(client);
	}
}

stock void RandomlyDisguise(int client)	//Original code was mecha's, but the original code is broken and this uses a better method now.
{
	if(IsValidClient(client) && IsPlayerAlive(client))
	{
		int disguiseTarget=-1;
		int team=GetClientTeam(client);

		Handle disguiseArray=CreateArray();
		for(int clientcheck; clientcheck<=MaxClients; clientcheck++)
		{
			if(IsValidClient(clientcheck) && GetClientTeam(clientcheck)==team && clientcheck!=client)
			{
				PushArrayCell(disguiseArray, clientcheck);
			}
		}

		if(GetArraySize(disguiseArray)<=0)
		{
			disguiseTarget=client;
		}
		else
		{
			disguiseTarget=GetArrayCell(disguiseArray, GetRandomInt(0, GetArraySize(disguiseArray)-1));
			if(!IsValidClient(disguiseTarget))
			{
				disguiseTarget=client;
			}
		}

		int class=GetRandomInt(0, 4);
		TFClassType classArray[]={TFClass_Scout, TFClass_Pyro, TFClass_Medic, TFClass_Engineer, TFClass_Sniper};
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
	if(Enabled && IsBoss(client) && CheckRoundState()==1 && !TF2_IsPlayerCritBuffed(client) && !randomCrits[client])
	{
		result=false;
		return Plugin_Changed;
	}
	else if (Enabled && !IsBoss(client) && CheckRoundState()==1 && IsValidEntity(weapon) && SniperClimbDelay!=0)
	{
		if (!StrContains(weaponname, "tf_weapon_club"))
		{
			SickleClimbWalls(client, weapon);
		}
	}
	return Plugin_Continue;
}

public int SickleClimbWalls(int client, int weapon)	 //Credit to Mecha the Slag
{
	if (!IsValidClient(client) || (GetClientHealth(client)<=SniperClimbDamage) )return;

	char classname[64];
	float vecClientEyePos[3];
	float vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);   // Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng);	   // Get the angle the player is looking

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if (!TR_DidHit(INVALID_HANDLE)) return;

	int TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
	GetEdictClassname(TRIndex, classname, sizeof(classname));
	if (!StrEqual(classname, "worldspawn")) return;

	float fNormal[3];
	TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
	GetVectorAngles(fNormal, fNormal);

	if (fNormal[0] >= 30.0 && fNormal[0] <= 330.0) return;
	if (fNormal[0] <= -30.0) return;

	float pos[3];
	TR_GetEndPosition(pos);
	float distance = GetVectorDistance(vecClientEyePos, pos);

	if (distance >= 100.0) return;

	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

	fVelocity[2] = 600.0;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);

	SDKHooks_TakeDamage(client, client, client, SniperClimbDamage, DMG_CLUB, GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));

	if (!IsBoss(client)) ClientCommand(client, "playgamesound \"%s\"", "player\\taunt_clip_spin.wav");

	RequestFrame(Timer_NoAttacking, EntIndexToEntRef(weapon));
	// CreateTimer(0.0, Timer_NoAttacking, EntIndexToEntRef(weapon), TIMER_FLAG_NO_MAPCHANGE);
}

stock int SetNextAttack(int weapon, float duration = 0.0)
{
	if (weapon <= MaxClients) return;
	if (!IsValidEntity(weapon)) return;
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

stock int GetClientWithMostQueuePoints(bool[] omit)
{
	int winner;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && GetClientQueuePoints(client)>=GetClientQueuePoints(winner) && !omit[client])
		{
			if((ClientCookie[client]==TOGGLE_OFF || ClientCookie[client]==TOGGLE_TEMP) && GetConVarBool(cvarToggleBoss)) // Skip clients who have disabled being able to be a boss
				continue;
			
			if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
			{
				winner=client;
			}
		}
	}
	
	if(!winner)
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && !omit[client])
			{
				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					winner=client;
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
		if(IsValidClient(client) && !omit[client] && (GetClientQueuePoints(client)>=GetClientQueuePoints(companion) || GetConVarBool(cvarDuoRandom)))
		{
			if((ClientCookie2[client]==TOGGLE_OFF || ClientCookie2[client]==TOGGLE_TEMP) && GetConVarBool(cvarDuoBoss)) // Skip clients who have disabled being able to be selected as a companion
				continue;

			if((ClientCookie[client]==TOGGLE_OFF || ClientCookie[client]==TOGGLE_TEMP) && GetConVarBool(cvarToggleBoss)) // Skip clients who have disabled being able to be a boss
				continue;
			
			if((SpecForceBoss && !GetConVarBool(cvarDuoRandom)) || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
			{
				companion=client;
			}
		}
	}
	
	if(!companion)
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && !omit[client]) //&& (GetClientQueuePoints(client)>=GetClientQueuePoints(companion) || GetConVarBool(cvarDuoRandom)))
			{
				if((ClientCookie[client]==TOGGLE_OFF || ClientCookie[client]==TOGGLE_TEMP) && GetConVarBool(cvarToggleBoss)) // Skip clients who have disabled being able to be a boss
					continue;

				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator)) // Ignore the companion toggle pref if we can't find available clients
				{
					companion=client;
				}
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
		{
			return client-1;
		}
	}
	return 0;
}

stock int GetBossIndex(int client)
{
	if(client>0 && client<=MaxClients)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss]==client)
			{
				return boss;
			}
		}
	}
	return -1;
}

stock int Operate(Handle sumArray, int &bracket, float value, Handle _operator)
{
	float sum=GetArrayCell(sumArray, bracket);
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
				LogError("[FF2 Bosses] Detected a divide by 0!");
				bracket=0;
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
	KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "=Failed name=");
	KvGetString(BossKV[Special[boss]], key, formula, sizeof(formula), defaultFormula);

	int playing2=playing + 1;
	int size=1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i]=='(')
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
		else if(formula[i]==')')
		{
			matchingBrackets++;
		}
	}

	Handle sumArray=CreateArray(_, size), _operator=CreateArray(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	SetArrayCell(sumArray, 0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	SetArrayCell(_operator, bracket, Operator_None);

	char character[2], value[16];  //We don't decl value because we directly append characters to it and there's no point in decl'ing character
	for(int i; i<=strlen(formula); i++)
	{
		character[0]=formula[i];  //Find out what the next char in the formula is
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
				if(GetArrayCell(_operator, bracket)!=Operator_None)  //Something like (5*)
				{
					LogError("[FF2 Bosses] %s's %s formula has an invalid operator at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogError("[FF2 Bosses] %s's %s formula has an unbalanced parentheses at character %i", bossName, key, i+1);
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
				Operate(sumArray, bracket, float(playing2), _operator);
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

	int result=RoundFloat(GetArrayCell(sumArray, 0));
	CloseHandle(sumArray);
	CloseHandle(_operator);
	if(result<=0)
	{
		LogError("[FF2] %s has an invalid %s formula, using default!", bossName, key);
		return defaultValue;
	}

	if(bMedieval && StrContains(key, "ragedamage", false))
	{
		return RoundFloat(result/3.6);  //TODO: Make this configurable
	}
	return result;
}

stock int GetAbilityArgument(int index, const char[] plugin_name, const char[] ability_name, int arg, int defvalue=0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return 0;
	KvRewind(BossKV[Special[index]]);
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
			char plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			return KvGetNum(BossKV[Special[index]], s,defvalue);
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
			char plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
			Format(s,10,"arg%i",arg);
			float see=KvGetFloat(BossKV[Special[index]], s,defvalue);
			return see;
		}
	}
	return 0.0;
}

stock int GetAbilityArgumentString(int index, const char[] plugin_name, const char[] ability_name, int arg, char[] buffer, int buflen, const char[] defvalue="")
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
	{
		strcopy(buffer,buflen,"");
		return;
	}
	KvRewind(BossKV[Special[index]]);
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
			char plugin_name2[64];
			KvGetString(BossKV[Special[index]], "plugin_name",plugin_name2,64);
			if(plugin_name[0] && plugin_name2[0] && strcmp(plugin_name,plugin_name2))
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
	{
		return false;
	}

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
	{
		return false;  //Found sound, but no sounds inside of it
	}

	IntToString(GetRandomInt(1, sounds), key, sizeof(key));
	KvGetString(BossKV[Special[boss]], key, file, length);  //Populate file
	return true;
}

stock bool RandomSoundAbility(const char[] sound, char[] file, int length, int boss=0, int slot=0)
{
	if(boss<0 || Special[boss]<0 || !BossKV[Special[boss]])
	{
		return false;
	}

	KvRewind(BossKV[Special[boss]]);
	if(!KvJumpToKey(BossKV[Special[boss]], sound))
	{
		return false;  //Sound doesn't exist
	}

	char key[10];
	int sounds, matches, match[MAXRANDOMS];
	while(++sounds)
	{
		IntToString(sounds, key, 4);
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
		{
			break;  //Assume that there's no more sounds
		}

		Format(key, sizeof(key), "slot%i", sounds);
		if(KvGetNum(BossKV[Special[boss]], key, 0)==slot)
		{
			match[matches]=sounds;  //Found a match: let's store it in the array
			matches++;
		}
	}

	if(!matches)
	{
		return false;  //Found sound, but no sounds inside of it
	}

	IntToString(match[GetRandomInt(0, matches-1)], key, 4);
	KvGetString(BossKV[Special[boss]], key, file, length);  //Populate file
	return true;
}

void ForceTeamWin(int team)
{
	int entity=FindEntityByClassname2(-1, "team_control_point_master");
	if(!IsValidEntity(entity))
	{
		entity=CreateEntityByName("team_control_point_master");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(entity, "SetWinner");
}

public bool PickCharacter(int boss, int companion)
{
	if(boss==companion)
	{
		Special[boss]=Incoming[boss];
		Incoming[boss]=-1;
		if(Special[boss]!=-1)  //We've already picked a boss through Command_SetNextBoss
		{
			Action action;
			Call_StartForward(OnSpecialSelected);
			Call_PushCell(boss);
			int characterIndex=Special[boss];
			Call_PushCellRef(characterIndex);
			char newName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", newName, sizeof(newName));
			Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(true);  //Preset
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
			  (KvGetNum(BossKV[Special[boss]], "nofirst") && (RoundCount<arenaRounds || (RoundCount==arenaRounds && CheckRoundState()!=1))) ||
			  (strlen(companionName) && !DuoMin))
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
		{
			return false;
		}
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
		Boss[companion]=companion;  //Woo boss indexes!
		omit[companion]=true;
		int client=Boss[boss];
		Companions=1;
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
				LogError("[FF2 Bosses] Warning: Boss %s has an invalid amount of lives, setting to 1", companionName);
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
	{
		return -1;
	}

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count=ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
	{
		--count;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib=StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
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
	{
		FF2flags[client]|=FF2FLAG_CLASSHELPED;
	}
	return;
}

public int QueuePanelH(Handle menu, MenuAction action, int client, int selection)
{
	if(action==MenuAction_Select && selection==10)
	{
		TurnToZeroPanel(client, client);
	}
	return false;
}


public Action QueuePanelCmd(int client, int args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	char text[64];
	int items;
	bool[] added = new bool[MaxClients+1];

	Handle panel=CreatePanel();
	Format(text, sizeof(text), "%T", "thequeue", client);  //"Boss Queue"
	SetPanelTitle(panel, text);
	for(int boss; boss<=MaxClients; boss++)  //Add the current bosses to the top of the list
	{
		if(IsBoss(boss))
		{
			added[boss]=true;  //Don't want the bosses to show up again in the actual queue list
			Format(text, sizeof(text), "%N-%i", boss, GetClientQueuePoints(boss));
			DrawPanelItem(panel, text);
			items++;
		}
	}

	DrawPanelText(panel, "---");
	do
	{
		int target=GetClientWithMostQueuePoints(added);  //Get whoever has the highest queue points out of those who haven't been listed yet
		if(!IsValidClient(target))  //When there's no players left, fill up the rest of the list with blank lines
		{
			DrawPanelItem(panel, "");
			items++;
			continue;
		}

		Format(text, sizeof(text), "%N-%i", target, GetClientQueuePoints(target));
		if(client!=target)
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
	while(items<9);

	Format(text, sizeof(text), "%T (%T)", "your_points", client, GetClientQueuePoints(client), "to0", client);  //"Your queue point(s) is {1} (set to 0)"
	DrawPanelItem(panel, text);

	SendPanelToClient(panel, client, QueuePanelH, MENU_TIME_FOREVER);
	CloseHandle(panel);
	return Plugin_Handled;
}

public Action ResetQueuePointsCmd(int client, int args)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

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
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: ff2_resetqueuepoints <target>");
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
			CPrintToChat(client,"{olive}[FF2]{default} %t", "to0_done");  //Your queue points have been reset to {olive}0{default}
		}
		else
		{
			CPrintToChat(client, "{olive}[FF2]{default} %t", "to0_done_admin", shortname[client]);  //{olive}{1}{default}'s queue points have been reset to {olive}0{default}
			CPrintToChat(shortname[client], "{olive}[FF2]{default} %t", "to0_done_by_admin", client);  //{olive}{1}{default} reset your queue points to {olive}0{default}
			LogAction(client, shortname[client], "\"%L\" reset \"%L\"'s queue points to 0", client, shortname[client]);
		}
		SetClientQueuePoints(shortname[client], 0);
	}
}

public Action TurnToZeroPanel(int client, int target)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(GetClientQueuePoints(client)<0 && client==target)
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

bool GetClientClassInfoCookie(int client)
{
	if(!IsValidClient(client) || IsFakeClient(client))
	{
		return false;
	}

	if(!AreClientCookiesCached(client))
	{
		return true;
	}

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	return StringToInt(cookieValues[3])==1;
}

int GetClientQueuePoints(int client)
{
	if(!IsValidClient(client) || !AreClientCookiesCached(client))
	{
		return 0;
	}

	if(IsFakeClient(client))
	{
		return botqueuepoints;
	}

	char cookies[24], cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	return StringToInt(cookieValues[0]);
}

void SetClientQueuePoints(int client, int points)
{
	if(IsValidClient(client) && !IsFakeClient(client) && AreClientCookiesCached(client))
	{
		char cookies[24], cookieValues[8][5];
		GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
		ExplodeString(cookies, " ", cookieValues, 8, 5);
		Format(cookies, sizeof(cookies), "%i %s %s %s %s %s %s %s", points, cookieValues[1], cookieValues[2], cookieValues[3], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
		SetClientCookie(client, FF2Cookies, cookies);
	}
}

stock bool IsBoss(int client)
{
	if(IsValidClient(client))
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss]==client)
			{
				return true;
			}
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
			{
				Command_GetHP(client);
			}
			case 2:
			{
				Command_SetMyBoss(client, 0);
			}
			case 3:
			{
				HelpPanelClass(client);
			}
			case 4:
			{
				NewPanel(client, maxVersion);
			}
			case 5:
			{
				QueuePanelCmd(client, 0);
			}
			case 6:
			{
				MusicTogglePanel(client);
			}
			case 7:
			{
				VoiceTogglePanel(client);
			}
			case 8:
			{
				HelpPanel3(client);
			}
			default:
			{
				return;
			}
		}
	}
}

public Action FF2Panel(int client, int args)  //._.
{
	if(Enabled2 && IsValidClient(client, false))
	{
		Handle panel=CreatePanel();
		char text[256];
		SetGlobalTransTarget(client);
		Format(text, sizeof(text), "%T", "menu_1", client);  //What's up?
		SetPanelTitle(panel, text);
		Format(text, sizeof(text), "%T", "menu_2", client);  //Investigate the boss's current health level (/ff2hp)
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%T", "menu_3", client);  //Boss Preferences (/ff2boss)
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%T", "menu_7", client);  //Changes to my class in FF2 (/ff2classinfo)
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%T", "menu_4", client);  //What's new? (/ff2new).
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%T", "menu_5", client);  //Queue points
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%T", "menu_8", client);  //Toggle music (/ff2music)
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%T", "menu_9", client);  //Toggle monologues (/ff2voice)
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%T", "menu_9a", client);  //Toggle info about changes of classes in FF2
		DrawPanelItem(panel, text);
		Format(text, sizeof(text), "%T", "menu_6", client);  //Exit
		DrawPanelItem(panel, text);
		SendPanelToClient(panel, client, FF2PanelH, MENU_TIME_FOREVER);
		CloseHandle(panel);
		return Plugin_Handled;
	}
	return Plugin_Continue;
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
					NewPanel(param1, 0);
				else
					NewPanel(param1, --curHelp[param1]);
			}
			case 2:
			{
				if(curHelp[param1]>=maxVersion)
					NewPanel(param1, maxVersion);
				else
					NewPanel(param1, ++curHelp[param1]);
			}
			default: return;
		}
	}
}

public Action NewPanelCmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	NewPanel(client, maxVersion);
	return Plugin_Handled;
}

public Action NewPanel(int client, int versionIndex)
{
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

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
		return Plugin_Continue;
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
	if(!Enabled2)
	{
		return Plugin_Continue;
	}

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
			char cookies[24];
			char cookieValues[8][5];
			GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
			ExplodeString(cookies, " ", cookieValues, 8, 5);
			if(selection==2)
			{
				Format(cookies, sizeof(cookies), "%s %s %s 0 %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
			}
			else
			{
				Format(cookies, sizeof(cookies), "%s %s %s 1 %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
			}
			SetClientCookie(client, FF2Cookies, cookies);
			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_classinfo", selection==2 ? "off" : "on");	// TODO: Make this more multi-language friendly
		}
	}
}

void ToggleClassInfo(int client)
{
	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);
	if(StringToInt(cookieValues[3])==1)
	{
		Format(cookies, sizeof(cookies), "%s %s %s 0 %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
	}
	else
	{
		Format(cookies, sizeof(cookies), "%s %s %s 1 %s %s %s", cookieValues[0], cookieValues[1], cookieValues[2], cookieValues[4], cookieValues[5], cookieValues[6], cookieValues[7]);
	}
	SetClientCookie(client, FF2Cookies, cookies);
	CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_classinfo", StringToInt(cookieValues[3])==0 ? "off" : "on");	// TODO: Make this more multi-language friendly
}

public Action Command_HelpPanelClass(int client, int args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}

	HelpPanelClass(client);
	return Plugin_Handled;
}

public Action HelpPanelClass(int client)
{
	if(!Enabled)
	{
		return Plugin_Continue;
	}

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
		{
			Format(text, sizeof(text), "%T", "help_scout", client);
		}
		case TFClass_Soldier:
		{
			Format(text, sizeof(text), "%T", "help_soldier", client);
		}
		case TFClass_Pyro:
		{
			Format(text, sizeof(text), "%T", "help_pyro", client);
		}
		case TFClass_DemoMan:
		{
			Format(text, sizeof(text), "%T", "help_demo", client);
		}
		case TFClass_Heavy:
		{
			Format(text, sizeof(text), "%T", "help_heavy", client);
		}
		case TFClass_Engineer:
		{
			Format(text, sizeof(text), "%T", "help_eggineer", client);
		}
		case TFClass_Medic:
		{
			Format(text, sizeof(text), "%T", "help_medic", client);
		}
		case TFClass_Sniper:
		{
			Format(text, sizeof(text), "%T", "help_sniper", client);
		}
		case TFClass_Spy:
		{
			Format(text, sizeof(text), "%T", "help_spie", client);
		}
		default:
		{
			Format(text, sizeof(text), "");
		}
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
	{
		return;
	}

	char text[512], language[20];
	GetLanguageInfo(GetClientLanguage(Boss[boss]), language, 8, text, 8);
	Format(language, sizeof(language), "description_%s", language);

	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], language, text, sizeof(text));
	if(!text[0])
	{
		KvGetString(BossKV[Special[boss]], "description_en", text, sizeof(text));  //Default to English if their language isn't available
		if(!text[0])
		{
			return;
		}
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
		return Plugin_Continue;
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
			if(CheckSoundException(client, SOUNDEXCEPT_MUSIC))
			{
				CReplyToCommand(client, "{olive}[FF2]{default} You already have boss themes enabled...");
				return Plugin_Handled;
			}
			ToggleBGM(client, true);
		}
		CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_music", !CheckSoundException(client, SOUNDEXCEPT_MUSIC) ? "off" : "on");	// TODO: Make this more multi-language friendly
		return Plugin_Handled;
	}

	MusicTogglePanel(client);
	return Plugin_Handled;
}

public Action MusicTogglePanel(int client)
{
	if(!Enabled || !IsValidClient(client))
	{
		return Plugin_Continue;
	}

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
		Format(title,sizeof(title), "%T", "theme_menu", client);
		SetMenuTitle(togglemusic, title, title);
		if(CheckSoundException(client, SOUNDEXCEPT_MUSIC))
			Format(title, sizeof(title), "%T", "themes_disable", client);
		else
			Format(title, sizeof(title), "%T", "themes_enable", client);
		AddMenuItem(togglemusic, title, title);
		if(CheckSoundException(client, SOUNDEXCEPT_MUSIC))
		{
			Format(title, sizeof(title), "%T", "theme_skip", client);
			AddMenuItem(togglemusic, title, title);
			Format(title, sizeof(title), "%T", "theme_shuffle", client);
			AddMenuItem(togglemusic, title, title);
			if(GetConVarInt(cvarSongInfo)>=0)
			{
				Format(title, sizeof(title), "%T", "theme_select", client);
				AddMenuItem(togglemusic, title, title);
			}
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
				SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, false);
				StopMusic(client, true);
			}
			else  //On
			{
				//If they already have music enabled don't do anything
				if(!CheckSoundException(client, SOUNDEXCEPT_MUSIC))
				{
					SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, true);
					StartMusic(client);
				}
			}
			CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_music", selection==2 ? "off" : "on");	// TODO: Make this more multi-language friendly
		}
		else
		{
			switch(selection)
			{
				case 0:
				{
					ToggleBGM(client, CheckSoundException(client, SOUNDEXCEPT_MUSIC) ? false : true);               
					CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_music", !CheckSoundException(client, SOUNDEXCEPT_MUSIC) ? "off" : "on");	// And here too
				}
				case 1: Command_SkipSong(client, 0);
				case 2: Command_ShuffleSong(client, 0);
				case 3: Command_Tracklist(client, 0);
			}
		}
	}
}

void ToggleBGM(int client, bool enable)
{
	if(enable)
	{
		SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, true);
		StartMusic(client);
	}
	else
	{
		SetClientSoundOptions(client, SOUNDEXCEPT_MUSIC, false);
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

	if(!Enabled || CheckRoundState()!=1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2_please wait");
		return Plugin_Handled;
	}

	if(StrEqual(currentBGM[client], "ff2_stop_music", true)|| !CheckSoundException(client, SOUNDEXCEPT_MUSIC))
	{
		CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2_music_disabled");
		return Plugin_Handled;
	}

    	CReplyToCommand(client, "{olive}[FF2]{default} %t", "track_skipped");

	StopMusic(client, true);
	
	char id3[4][256];
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

		cursongId[client]++;
		if(cursongId[client]>=index)
		{
			cursongId[client]=1;
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
			KvRewind(BossKV[Special[0]]);
			KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
			LogError("[FF2 Bosses] Character %s is missing BGM file '%s'!", bossName, temp);
			if(MusicTimer[client]!=INVALID_HANDLE)
			{
				KillTimer(MusicTimer[client]);
			}
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

	if(!Enabled || CheckRoundState()!=1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2_please wait");
		return Plugin_Handled;
	}

	if(StrEqual(currentBGM[client], "ff2_stop_music", true)|| !CheckSoundException(client, SOUNDEXCEPT_MUSIC))
	{
		CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2_music_disabled");
		return Plugin_Handled;
	}

	if(!GetConVarBool(cvarAdvancedMusic))
	{
		return Plugin_Handled;
	}

	CReplyToCommand(client, "{olive}[FF2]{default} %t", "track_shuffle");
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

	if(!Enabled || CheckRoundState()!=1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2_please wait");
		return Plugin_Handled;
	}

	if(StrEqual(currentBGM[client], "ff2_stop_music", true) || !CheckSoundException(client, SOUNDEXCEPT_MUSIC))
	{
		CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2_music_disabled");
		return Plugin_Handled;
	}

	if(!GetConVarBool(cvarAdvancedMusic) || (GetConVarInt(cvarSongInfo)<0))
	{
		return Plugin_Handled;
	}

	char id3[6][256];
	Handle trackList = CreateMenu(Command_TrackListH);
	SetMenuTitle(trackList, "%T", "track_select", client);
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
			CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2_no_music");		
			return Plugin_Handled;		
		}

		for(int trackIdx=1;trackIdx<=index-1;trackIdx++)
		{
			Format(id3[0], sizeof(id3[]), "name%i", trackIdx);
			KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
			Format(id3[1], sizeof(id3[]), "artist%i", trackIdx);
			KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));
			GetSongTime(trackIdx, id3[5], sizeof(id3[]));
			if(!id3[3])
			{
				Format(id3[3], sizeof(id3[]), "%T", "unknown_artist", client);
			}
			if(!id3[2])
			{
				Format(id3[2], sizeof(id3[]), "%T", "unknown_song", client);
			}
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
				int mins=StringToInt(time2[i])*60;
				int secs=StringToInt(time2[i+1]);
				int milsecs=StringToInt(time2[i+2]);
				Format(newTime, sizeof(newTime), "%i.%i", mins+secs, milsecs);
				duration=StringToFloat(newTime);				   
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

				char temp[PLATFORM_MAX_PATH];
				Format(temp, sizeof(temp), "sound/%s", music);
				if(FileExists(temp, true))
				{
					PlayBGM(param1, music, time, _, id3[2], id3[3]);
				}
				else
				{
					char bossName[64];
					KvRewind(BossKV[Special[0]]);
					KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
					LogError("[FF2 Bosses] Character %s is missing BGM file '%s'!", bossName, temp);
					if(MusicTimer[param1]!=INVALID_HANDLE)
					{
						KillTimer(MusicTimer[param1]);
					}
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
		return Plugin_Continue;
	}

	if(!GetConVarBool(cvarAdvancedMusic))
	{
		VoiceTogglePanel(client);
	}
	else
	{
		ToggleVoice(client, CheckSoundException(client, SOUNDEXCEPT_VOICE) ? false : true);
		CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_voice", !CheckSoundException(client, SOUNDEXCEPT_VOICE) ? "off" : "on");	// TODO: Make this more multi-language friendly
	}
	return Plugin_Handled;
}

public Action VoiceTogglePanel(int client)
{
	if(!Enabled || !IsValidClient(client))
	{
		return Plugin_Continue;
	}

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
			SetClientSoundOptions(client, SOUNDEXCEPT_VOICE, false);
		}
		else
		{
			SetClientSoundOptions(client, SOUNDEXCEPT_VOICE, true);
		}

		CPrintToChat(client, "{olive}[FF2]{default} %t", "ff2_voice", selection==2 ? "off" : "on");	// TODO: Make this more multi-language friendly
		if(selection==2)
		{
			CPrintToChat(client, "%t", "ff2_voice2");
		}
	}
}

void ToggleVoice(int client, bool enable)
{
	if(enable)
	{
		SetClientSoundOptions(client, SOUNDEXCEPT_VOICE, true);
	}
	else
	{
		SetClientSoundOptions(client, SOUNDEXCEPT_VOICE, false);
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
	{
		return Plugin_Continue;
	}

	int boss=GetBossIndex(client);
	if(boss==-1)
	{
		return Plugin_Continue;
	}

	if(channel==SNDCHAN_VOICE && !(FF2flags[Boss[boss]] & FF2FLAG_TALKING))
	{
		char newSound[PLATFORM_MAX_PATH];
		if(RandomSound("catch_phrase", newSound, PLATFORM_MAX_PATH, boss))
		{
			strcopy(sound, PLATFORM_MAX_PATH, newSound);
			return Plugin_Changed;
		}

		if(bBlockVoice[Special[boss]])
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

stock int GetHealingTarget(int client, bool checkgun=false)
{
	int medigun=GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
		{
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		}
		return -1;
	}

	if(IsValidEntity(medigun))
	{
		char classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(!strcmp(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			{
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
			}
		}
	}
	return -1;
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<=0 || client>MaxClients)
	{
		return false;
	}

	if(!IsClientInGame(client))
	{
		return false;
	}

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
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
	{
		return Plugin_Continue;
	}

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
		{
			continue;
		}
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
	if(charsets<3)
	{
		RemoveMenuItem(menu, 0);
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
		CPrintToChatAll("{olive}[FF2]{default} %t", "nextmap_charset", nextmap, FF2CharSetString);  //"The character set for {1} will be {2}."
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
		CPrintToChat(client, "{olive}[FF2]{default} %t", "nextmap_charset", nextmap, FF2CharSetString);
	}
	return Plugin_Handled;
}

public Action Command_Say(int client, int args)
{
	char chat[128];
	if(GetCmdArgString(chat, sizeof(chat))<1 || !client)
	{
		return Plugin_Continue;
	}

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
	int client=Boss[boss];
	bool enabled=true;
	Call_StartForward(PreAbility);
	Call_PushCell(boss);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	Call_PushCell(slot);
	Call_PushCellRef(enabled);
	Call_Finish();

	if(!enabled)
	{
		return false;
	}

	Action action=Plugin_Continue;
	Call_StartForward(OnAbility);
	Call_PushCell(boss);
	Call_PushString(plugin_name);
	Call_PushString(ability_name);
	if(slot==-1)
	{
		Call_PushCell(3);  //Status - we're assuming here a life-loss ability will always be in use if it gets called
		Call_Finish(action);
	}
	else if(!slot)
	{
		FF2flags[Boss[boss]]&=~FF2FLAG_BOTRAGE;
		Call_PushCell(3);  //Status - we're assuming here a rage ability will always be in use if it gets called
		Call_Finish(action);
		if(rageMode[client]==1)
		{
			BossCharge[boss][slot]=BossCharge[boss][slot]-rageMin[client];	// This is weird...
		}
		else if(rageMode[client]==0)
		{
			BossCharge[boss][slot]=0.0;
		}
	}
	else
	{
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
		int button;
		switch(buttonMode)
		{
			case 2:
			{
				button=IN_RELOAD;
				bossHasReloadAbility[boss]=true;
			}
			default:
			{
				button=IN_DUCK|IN_ATTACK2;
				bossHasRightMouseAbility[boss]=true;
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

			if(BossCharge[boss][slot]>=0.0)
			{
				Call_PushCell(2);  //Status
				Call_Finish(action);
				float charge=100.0*0.2/GetAbilityArgumentFloat(boss, plugin_name, ability_name, 1, 1.5);
				if(BossCharge[boss][slot]+charge<100.0)
				{
					BossCharge[boss][slot]+=charge;
				}
				else
				{
					BossCharge[boss][slot]=100.0;
				}
			}
			else
			{
				Call_PushCell(1);  //Status
				Call_Finish(action);
				BossCharge[boss][slot]+=0.2;
			}
		}
		else if(BossCharge[boss][slot]>0.3)
		{
			float angles[3];
			GetClientEyeAngles(Boss[boss], angles);
			if(angles[0]<-45.0)
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
				BossCharge[boss][slot]=0.0;
			}
		}
		else if(BossCharge[boss][slot]<0.0)
		{
			Call_PushCell(1);  //Status
			Call_Finish(action);
			BossCharge[boss][slot]+=0.2;
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
	int ent=-1;
	while((ent=FindEntityByClassname2(ent, entityname))!=-1)
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
				for(int client=1;client<=MaxClients;client++)
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

stock void RemoveShield(int client, int attacker, float position[3])
{
	TF2_RemoveWearable(client, shield[client]);
	EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	if(GetConVarInt(cvarShieldType)!=3)
	{
		EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
		EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
	}
	TF2_AddCondition(client, TFCond_Bonked, 0.1); // Shows "MISS!" upon breaking shield
	if(GetConVarInt(cvarShieldType)==3)
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
	shieldHP[client]=0.0;
	shield[client]=0;
	CreateTimer(1.0, Timer_RemoveStun, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_RemoveStun(Handle timer, int client)
{
	if(RemoveCond(client, TFCond_Dazed))
	{
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public int Native_IsEnabled(Handle plugin, int numParams)
{
	return Enabled;
}

public int Native_FF2Version(Handle plugin, int numParams)
{
	int version[3];  //Blame the compiler for this mess -.-
	version[0]=StringToInt(MAJOR_REVISION);
	version[1]=StringToInt(MINOR_REVISION);
	version[2]=StringToInt(STABLE_REVISION);
	SetNativeArray(1, version, sizeof(version));
	#if !defined DEV_REVISION
		return false;
	#else
		return true;
	#endif
}

public int Native_ForkVersion(Handle plugin, int numParams)
{
	int fversion[3];
	fversion[0]=StringToInt(FORK_MAJOR_REVISION);
	fversion[1]=StringToInt(FORK_MINOR_REVISION);
	fversion[2]=StringToInt(FORK_STABLE_REVISION);
	SetNativeArray(1, fversion, sizeof(fversion));
	#if !defined FORK_SUB_REVISION
		return false;
	#else
		return true;
	#endif
}

public int Native_GetBoss(Handle plugin, int numParams)
{
	int boss=GetNativeCell(1);
	if(boss>=0 && boss<=MaxClients && IsValidClient(Boss[boss]))
	{
		return GetClientUserId(Boss[boss]);
	}
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
		if(index<0) return false;
		if(!BossKV[index]) return false;
		KvRewind(BossKV[index]);
		KvGetString(BossKV[index], "name", s, dstrlen);
		SetNativeString(2, s,dstrlen);
	}
	else
	{
		if(index<0) return false;
		if(Special[index]<0) return false;
		if(!BossKV[Special[index]]) return false;
		KvRewind(BossKV[Special[index]]);
		KvGetString(BossKV[Special[index]], "name", s, dstrlen);
		SetNativeString(2, s,dstrlen);
	}
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
	{
		return 0;
	}
	return CheckRoundState();
}

public int Native_GetRageDist(Handle plugin, int numParams)
{
	int index=GetNativeCell(1);
	char plugin_name[64];
	GetNativeString(2,plugin_name,64);
	char ability_name[64];
	GetNativeString(3,ability_name,64);

	if(!BossKV[Special[index]]) return view_as<int>(0.0);
	KvRewind(BossKV[Special[index]]);
	float see;
	if(!ability_name[0])
	{
		return view_as<int>(KvGetFloat(BossKV[Special[index]],"ragedist",400.0));
	}
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
	{
		return false;
	}

	KvRewind(BossKV[Special[boss]]);
	if(!BossKV[Special[boss]])
	{
		LogError("Failed KV: %i %i", boss, Special[boss]);
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
				{
					return true;
				}
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
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	UseAbility(ability_name,plugin_name, GetNativeCell(1), GetNativeCell(4), GetNativeCell(5));
}

public int Native_GetAbilityArgument(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	return GetAbilityArgument(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),GetNativeCell(5));
}

public int Native_GetAbilityArgumentFloat(Handle plugin, int numParams)
{
	char plugin_name[64];
	char ability_name[64];
	GetNativeString(2,plugin_name,64);
	GetNativeString(3,ability_name,64);
	return view_as<int>(GetAbilityArgumentFloat(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),GetNativeCell(5)));
}

public int Native_GetAbilityArgumentString(Handle plugin, int numParams)
{
	char plugin_name[64];
	GetNativeString(2,plugin_name,64);
	char ability_name[64];
	GetNativeString(3,ability_name,64);
	int dstrlen=GetNativeCell(6);
	char[] s = new char[dstrlen+1];
	GetAbilityArgumentString(GetNativeCell(1),plugin_name,ability_name,GetNativeCell(4),s,dstrlen);
	SetNativeString(5,s,dstrlen);
}

public int Native_GetDamage(Handle plugin, int numParams)
{
	int client=GetNativeCell(1);
	if(!IsValidClient(client))
	{
		return 0;
	}
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
	return GetClientQueuePoints(GetNativeCell(1));
}

public int Native_SetQueuePoints(Handle plugin, int numParams)
{
	SetClientQueuePoints(GetNativeCell(1), GetNativeCell(2));
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
			{
				KvRewind(BossKV[index]);
			}
			return view_as<int>(BossKV[index]);
		}
	}
	else
	{
		if(index!=-1 && index<=MaxClients && Special[index]!=-1 && Special[index]<MAXSPECIALS)
		{
			if(BossKV[Special[index]]!=INVALID_HANDLE)
			{
				KvRewind(BossKV[Special[index]]);
			}
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
	int length=GetNativeCell(3)+1;
	int boss=GetNativeCell(4);
	int slot=GetNativeCell(5);
	char[] sound = new char[length];
	int kvLength;

	GetNativeStringLength(1, kvLength);
	kvLength++;

	char[] keyvalue = new char[kvLength];
	GetNativeString(1, keyvalue, kvLength);

	bool soundExists;
	if(!strcmp(keyvalue, "sound_ability"))
	{
		soundExists=RandomSoundAbility(keyvalue, sound, length, boss, slot);
	}
	else
	{
		soundExists=RandomSound(keyvalue, sound, length, boss);
	}
	SetNativeString(2, sound, length);
	return soundExists;
}

public int Native_GetClientGlow(Handle plugin, int numParams)
{
	int client=GetNativeCell(1);
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
	int client=GetNativeCell(1);
	if(hadshield[client])
	{
		if(shield[client])
		{
			if(GetConVarInt(cvarShieldType)==4)
				return RoundToFloor(shieldHP[client]*0.2);
			else if(GetConVarInt(cvarShieldType)==3)
				return RoundToFloor(shieldHP[client]*0.1);
			else
				return 100;
		}
		return 0;
	}
	return -1;
}

public int Native_SetClientShield(Handle plugin, int numParams)
{
	int client=GetNativeCell(1);
	shield[client]=GetNativeCell(2);
	if(GetConVarInt(cvarShieldType)==4)
	{
		shieldHP[client]=GetNativeCell(3)*5.0;
		if(GetNativeCell(4)>0)
			shDmgReduction[client]=GetNativeCell(4);
		else
			shDmgReduction[client]=GetNativeCell(3)*0.0075;
	}
	else
	{
		shieldHP[client]=GetNativeCell(3)*10.0;
		if(GetNativeCell(4)>0)
			shDmgReduction[client]=GetNativeCell(4);
		else
			shDmgReduction[client]=GetNativeCell(3)*0.005;
	}
}

public int Native_RemoveClientShield(Handle plugin, int numParams)
{
	int client=GetNativeCell(1);
	TF2_RemoveWearable(client, shield[client]);
}

public int Native_Debug(Handle plugin, int numParams)
{
	return GetConVarBool(cvarDebug);
}

public int Native_IsVSHMap(Handle plugin, int numParams)
{
	return false;
}

public Action VSH_OnIsSaxtonHaleModeEnabled(int &result)
{
	if((!result || result==1) && Enabled)
	{
		result=2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleTeam(int &result)
{
	if(Enabled)
	{
		result=BossTeam;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleUserId(int &result)
{
	if(Enabled && IsClientConnected(Boss[0]))
	{
		result=GetClientUserId(Boss[0]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSpecialRoundIndex(int &result)
{
	if(Enabled)
	{
		result=Special[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleHealth(int &result)
{
	if(Enabled)
	{
		result=BossHealth[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleHealthMax(int &result)
{
	if(Enabled)
	{
		result=BossHealthMax[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetClientDamage(int client, int &result)
{
	if(Enabled)
	{
		result=Damage[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetRoundState(int &result)
{
	if(Enabled)
	{
		result=CheckRoundState();
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnTakeDamagePost(int client, int attacker, int inflictor, float damage, int damagetype)
{
	if(Enabled && IsBoss(client))
	{
		UpdateHealthBar();
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(GetConVarBool(cvarHealthBar))
	{
		if(StrEqual(classname, HEALTHBAR_CLASS))
		{
			healthBar=entity;
		}

		if(!IsValidEntity(g_Monoculus) && StrEqual(classname, MONOCULUS))
		{
			g_Monoculus=entity;
		}
	}

	if(StrContains(classname, "item_healthkit")!=-1 || StrContains(classname, "item_ammopack")!=-1 || StrEqual(classname, "tf_ammo_pack"))
	{
		SDKHook(entity, SDKHook_Spawn, OnItemSpawned);
	}
}

public void OnEntityDestroyed(int entity)
{
	if(entity==g_Monoculus)
	{
		g_Monoculus=FindEntityByClassname(-1, MONOCULUS);
		if(g_Monoculus==entity)
		{
			g_Monoculus=FindEntityByClassname(entity, MONOCULUS);
		}
	}
}

public void OnItemSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPickup);
	SDKHook(entity, SDKHook_Touch, OnPickup);
}

public Action OnPickup(int entity, int client)  //Thanks friagram!
{
	if(IsBoss(client) && Enabled)
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
	{
		healthBar=CreateEntityByName(HEALTHBAR_CLASS);
	}
}

public void HealthbarEnableChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(Enabled && GetConVarBool(cvarHealthBar) && IsValidEntity(healthBar))
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
	if(!Enabled || !GetConVarBool(cvarHealthBar) || IsValidEntity(g_Monoculus) || !IsValidEntity(healthBar) || CheckRoundState()==-1)
	{
		return;
	}

	int healthAmount, maxHealthAmount, bosses, healthPercent;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			bosses++;
			healthAmount+=BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			maxHealthAmount+=BossHealthMax[boss];
		}
	}

	if(bosses)
	{
		healthPercent=RoundToCeil(float(healthAmount)/float(maxHealthAmount)*float(HEALTHBAR_MAX));
		if(healthPercent>HEALTHBAR_MAX)
		{
			healthPercent=HEALTHBAR_MAX;
		}
		else if(healthPercent<=0)
		{
			healthPercent=1;
		}
	}
	SetEntProp(healthBar, Prop_Send, HEALTHBAR_PROPERTY, healthPercent);
}

void SetClientGlow(int client, float time1, float time2=-1.0)
{
	if(IsValidClient(client))
	{
		GlowTimer[client]+=time1;
		if(time2>=0)
		{
			GlowTimer[client]=time2;
		}

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
