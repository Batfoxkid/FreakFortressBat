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
#include <clientprefs>
#include <morecolors>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#tryinclude <SteamWorks>
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#tryinclude <cw3>
#tryinclude <smac>
#tryinclude <goomba>
#tryinclude <tf2attributes>
#define REQUIRE_PLUGIN

#pragma newdecls required

/*
    This fork uses a different versioning system
    as opposed to the public FF2 versioning system
*/
#define FORK_MAJOR_REVISION "1"
#define FORK_MINOR_REVISION "20"
#define FORK_STABLE_REVISION "3"
#define FORK_SUB_REVISION "Unofficial"
//#define FORK_DEV_REVISION "development"
#define FORK_DATE_REVISION "January 26, 2021"

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
/*< >*/

bool EnabledDesc = false;
#if defined _steamtools_included
bool steamtools = false;
#endif
#if defined _SteamWorks_Included
bool steamworks = false;
#endif

#if defined _tf2attributes_included
bool tf2attributes = false;
#endif

#if defined _goomba_included
bool goomba = false;
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
int MercAlivePlayers;
int BossAlivePlayers;
int RedAliveBosses;
int BlueAliveBosses;
int RoundCount;
bool LastMan = true;
bool CheatsUsed;
float rageMax[MAXTF2PLAYERS];
float rageMin[MAXTF2PLAYERS];
int rageMode[MAXTF2PLAYERS];
int Special[MAXTF2PLAYERS];
int Incoming[MAXTF2PLAYERS];

TFClassType LastAliveClass[MAXTF2PLAYERS];
int Damage[MAXTF2PLAYERS];
int uberTarget[MAXTF2PLAYERS];
bool hadshield[MAXTF2PLAYERS];
int shield[MAXTF2PLAYERS];
float shieldHP[MAXTF2PLAYERS];
float shDmgReduction[MAXTF2PLAYERS];
int detonations[MAXTF2PLAYERS];
bool playBGM[MAXTF2PLAYERS] = true;
int Healing[MAXTF2PLAYERS];
float SapperCooldown[MAXTF2PLAYERS];

char currentBGM[MAXTF2PLAYERS][PLATFORM_MAX_PATH];

int FF2flags[MAXTF2PLAYERS];

int Boss[MAXTF2PLAYERS];
int BossHealthMax[MAXTF2PLAYERS];
int BossHealth[MAXTF2PLAYERS];
int BossHealthLast[MAXTF2PLAYERS];
int BossLives[MAXTF2PLAYERS];
int BossLivesMax[MAXTF2PLAYERS];
int BossRageDamage[MAXTF2PLAYERS];
bool BossSwitched[MAXTF2PLAYERS];
float BossCharge[MAXTF2PLAYERS][4];
float Stabbed[MAXTF2PLAYERS];
float Marketed[MAXTF2PLAYERS];
float Cabered[MAXTF2PLAYERS];
float KSpreeTimer[MAXTF2PLAYERS];
int KSpreeCount[MAXTF2PLAYERS];
float GlowTimer[MAXTF2PLAYERS];
bool IsGlowing[MAXTF2PLAYERS];
bool HasEquipped[MAXTF2PLAYERS];
int shortname[MAXTF2PLAYERS];
float RPSLoser[MAXTF2PLAYERS];
int RPSLosses[MAXTF2PLAYERS];
int RPSHealth[MAXTF2PLAYERS];
float AirstrikeDamage[MAXTF2PLAYERS];
float KillstreakDamage[MAXTF2PLAYERS];
float HazardDamage[MAXTF2PLAYERS];
bool emitRageSound[MAXTF2PLAYERS];
bool SpawnTeleOnTriggerHurt = false;
bool HealthBarMode;
bool HealthBarModeC[MAXTF2PLAYERS];
bool ShowHealthText;
bool SpecialRound;
int CritBoosted[MAXTF2PLAYERS][3];

int timeleft;
int cursongId[MAXTF2PLAYERS] = 1;

ConVar cvarVersion;
ConVar cvarCharset;
ConVar cvarPointDelay;
ConVar cvarPointTime;
ConVar cvarAnnounce;
ConVar cvarAnnounceAds;
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
ConVar cvarChangelog;
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
ConVar cvarShuffleCharset;
ConVar cvarBroadcast;
ConVar cvarMarket;
ConVar cvarCloak;
ConVar cvarRinger;
ConVar cvarKunai;
ConVar cvarKunaiMax;
ConVar cvarDisguise;
ConVar cvarDiamond;
ConVar cvarCloakStun;
ConVar cvarDatabase;
ConVar cvarChargeAngle;
ConVar cvarAttributes;
ConVar cvarStartingUber;
ConVar cvarDamageHud;
ConVar cvarTelefrag;
ConVar cvarHealth;
ConVar cvarRageDamage;
ConVar cvarDifficulty;
ConVar cvarEnableSandmanStun;
ConVar cvarShowBossBlocked;

Handle FF2Cookies;
Handle StatCookies;
Handle StatDatabase;
Handle HudCookies;

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
int EnabledD = 0;
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
int bossTeleportation = 0;
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
float ChargeAngle = 30.0;
char Attributes[128] = "2 ; 3.1 ; 275 ; 1";
float StartingUber = 40.0;
char HealthFormula[1024] = "(((760.8+n)*(n-1))^1.0341)+2046";
char RageDamage[1024] = "1900";

Handle MusicTimer[MAXTF2PLAYERS];
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

ConVar cvarNextmap;
bool areSubPluginsEnabled;

int CurrentCharSet;
char CharSetString[MAXCHARSETS][42];
char FF2CharSetString[42];
bool isCharSetSelected = false;
bool HasCharSets;
bool CharSetOldPath = false;

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

ConVar hostName;
char oldName[256];
int changeGamemode;
Handle kvWeaponMods = INVALID_HANDLE;
Handle kvDiffMods = INVALID_HANDLE;
Handle SDKEquipWearable = null;

bool dmgTriple[MAXTF2PLAYERS];
bool randomCrits[MAXTF2PLAYERS];
int SelfKnockback[MAXTF2PLAYERS];
bool SapperBoss[MAXTF2PLAYERS];
bool SapperMinion;
char BossIcon[64];
int SelfHealing[MAXTF2PLAYERS];
float LifeHealing[MAXTF2PLAYERS];
float OverHealing[MAXTF2PLAYERS];
int GoombaMode;
int CapMode;
bool TimerMode;

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

#define HUDTYPES 6
static const char HudTypes[][] =	// Names used in translation files
{
	"Hud Damage",
	"Hud Extra",
	"Hud Message",
	"Hud Countdown",
	"Hud Health",
	"Hud Ranking"
};

enum
{
	GOOMBA_NONE = 0,
	GOOMBA_ALL,
	GOOMBA_BOSSTEAM,
	GOOMBA_OTHERTEAM,
	GOOMBA_NOTBOSS,
	GOOMBA_NOMINION,
	GOOMBA_BOSS
};

enum
{
	CAP_ALL = 0,
	CAP_NONE,
	CAP_BOSS_ONLY,
	CAP_BOSS_TEAM,
	CAP_NOT_BOSS,
	CAP_MERC_TEAM,
	CAP_NO_MINIONS
};

int Specials;
KeyValues BossKV[MAXSPECIALS];
int PackSpecials[MAXCHARSETS];
Handle PackKV[MAXSPECIALS][MAXCHARSETS];
Handle PreAbility;
Handle OnAbility;
Handle OnMusic;
Handle OnMusic2;
Handle OnTriggerHurt;
Handle OnSpecialSelected;
Handle OnAddQueuePoints;
Handle OnLoadCharacterSet;
Handle OnLoseLife;
Handle OnAlivePlayersChanged;
Handle OnBackstabbed;

bool bBlockVoice[MAXSPECIALS];
bool MapBlocked[MAXSPECIALS];
float BossSpeed[MAXSPECIALS];

char ChancesString[512];
int chances[MAXSPECIALS*2];  //This is multiplied by two because it has to hold both the boss indices and chances
int chancesIndex;

bool LateLoaded;


/*< Boss precached data >*/
enum struct FF2QueryData
{
	StringMap cache;

	int client_serial;
	int char_idx;

	char key_name[48];

	char current_plugin_name[64];
	char current_ability_name[64];

	int GetClient()
	{
		return GetClientFromSerial(this.client_serial);
	}
}

methodmap FF2Save < StringMap
{
	public FF2Save()
	{
		return view_as<FF2Save>(new StringMap());
	}

	public bool GetInfos(const char[] name, FF2QueryData data)
	{
		return this.GetArray(name, data, sizeof(FF2QueryData));
	}

	public bool SetInfos(const char[] name, const FF2QueryData data)
	{
		return this.SetArray(name, data, sizeof(FF2QueryData));
	}

	public void RegisterCharacter(const char[] name, int boss)
	{
		FF2QueryData data;
		if (this.GetInfos(name, data))
			return;

		data.cache = new StringMap();
		data.client_serial = GetClientSerial(Boss[boss]);
		data.char_idx = Special[boss];
		strcopy(data.key_name, sizeof(FF2QueryData::key_name), name);

		this.SetInfos(name, data);
	}

	public void ClearAll()
	{
		StringMapSnapshot snap = this.Snapshot();
		int size = snap.Length;

		FF2QueryData data;
		char key[48];

		for (int i = 0; i < size; i++)
		{
			snap.GetKey(i, key, sizeof(key));
			this.GetInfos(key, data);
			delete data.cache;
		}

		delete snap;
		this.Clear();
	}
}
FF2Save _FF2Save;

methodmap FF2Cache < StringMap
{
	public FF2Cache()
	{
		return view_as<FF2Cache>(new StringMap());
	}

	//FF2Cache.Request() 
	//retrieve boss' cache by filename
	public static bool Request(int boss, FF2QueryData data)
	{
		if (boss < 0 || Special[boss] < 0 || !BossKV[Special[boss]])
			return false;

		static char name[48];
		static KeyValues last_kv;
		KeyValues kv = BossKV[Special[boss]];

		if (kv == last_kv)
			return _FF2Save.GetInfos(name, data);

		kv.Rewind();
		kv.GetString("filename", name, sizeof(name), NULL_STRING);

		if (IsNullString(name)) {
			return false;
		}

		last_kv = kv;
		return _FF2Save.GetInfos(name, data);
	}

	public static void Update(const FF2QueryData data)
	{
		_FF2Save.SetInfos(data.key_name, data);
	}
	
	//sizeof(plugin_name)<64> + '.'<1> + sizeof(ability_name)<64> + '\0'<1> = 130
	public static void FormatToKey(char[] str, const char[] plugin_name, const char[] ability_name)
	{
		Format(str, 132, "%s.%s", plugin_name, ability_name);
	}

	//sizeof(plugin_name)<64> + '/'<1> + sizeof(ability_name)<64> + '\0'<1> = 130
	public static void FormatToHasAbility(char[] str, const char[] plugin_name, const char[] ability_name)
	{
		Format(str, 132, "%s/%s", plugin_name, ability_name);
	}
}

methodmap FF2Data 
{
	property int boss {
		public get() { return view_as<int>(this); }
	}

	property bool Invalid {
		public get() { return this.boss == -1; }
	}

	property int client {
		public get() { 
			if (this.Invalid) {
				return -1;
			}

			FF2QueryData data;
			if ((FF2Cache.Request(this.boss, data)))
				return data.GetClient();
			else return -1;
		}
	}

	public static FF2Data Unknown(int client)
	{
		return view_as<FF2Data>(GetBossIndex(client));
	}

	public FF2Data(int boss, const char[] _plugin, const char[] _ability)
	{
		if (boss < 0) {
			return view_as<FF2Data>(-1);
		}

		FF2QueryData data;

		if (!FF2Cache.Request(boss, data)) {
			return view_as<FF2Data>(-1);
		}

		strcopy(data.current_plugin_name, sizeof(FF2QueryData::current_plugin_name), _plugin);
		strcopy(data.current_ability_name, sizeof(FF2QueryData::current_ability_name), _ability);

		FF2Cache.Update(data);

		return view_as<FF2Data>(boss);
	}
	
	public void Change(const char[] _plugin, const char[] _ability)
	{
		FF2QueryData data;

		if (!FF2Cache.Request(this.boss, data)) {
			return;
		}

		strcopy(data.current_plugin_name, sizeof(FF2QueryData::current_plugin_name), _plugin);
		strcopy(data.current_ability_name, sizeof(FF2QueryData::current_ability_name), _ability);

		FF2Cache.Update(data);
	}
	
	public int GetArgI(const char[] arg, int def, int base = 10)
	{
		if (this.Invalid) {
			return 0;
		}

		FF2QueryData data;
		if (!FF2Cache.Request(this.boss, data)) {
			return def;
		}

		char res[12];
		if (!UTIL_FindCharArg(data, arg, res, sizeof(res))) {
			return def;
		}

		return StringToInt(res, base);
	}
	public float GetArgF(const char[] arg, float def)
	{
		if (this.Invalid) {
			return def;
		}

		FF2QueryData data;
		if (!FF2Cache.Request(this.boss, data)) {
			return def;
		}

		char res[12];
		if (!UTIL_FindCharArg(data, arg, res, sizeof(res))) {
			return def;
		}

		return StringToFloat(res);
	}
	public int GetArgS(const char[] arg, char[] res, int maxlen)
	{
		if (this.Invalid) {
			return 0;
		}

		FF2QueryData data;
		if (!FF2Cache.Request(this.boss, data)) {
			return 0;
		}

		if (!UTIL_FindCharArg(data, arg, res, maxlen)) {
			return 0;
		}

		return strlen(res);
	}
	public bool GetArgB(const char[] arg, bool def)
	{
		if (this.Invalid) {
			return false;
		}

		FF2QueryData data;
		if (!FF2Cache.Request(this.boss, data)) {
			return def;
		}

		char res[1];
		if (!UTIL_FindCharArg(data, arg, res, 1)) {
			return def;
		}

		return res[0] != '0';
	}
}
/*<	>*/

public Plugin myinfo =
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
	CreateNative("FF2_GetArgNamedI", Native_GetArgNamedI);
	CreateNative("FF2_GetArgNamedF", Native_GetArgNamedF);
	CreateNative("FF2_GetArgNamedS", Native_GetArgNamedS);
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
	CreateNative("FF2_MakeBoss", Native_MakeBoss);
	CreateNative("FF2_SelectBoss", Native_ChooseBoss);
	CreateNative("FF2_ReportError", Native_ReportError);
	
	CreateNative("FF2Data.Unknown", FF2Data_Unknown);
	CreateNative("FF2Data.FF2Data", FF2Data_FF2Data);
	CreateNative("FF2Data.boss.get", FF2Data_boss);
	CreateNative("FF2Data.client.get", FF2Data_client);
	CreateNative("FF2Data.Config.get", FF2Data_GetConfig);
	CreateNative("FF2Data.Health.get", Native_GetBossHealth);
	CreateNative("FF2Data.Health.set", Native_SetBossHealth);
	CreateNative("FF2Data.MaxHealth.get", Native_GetBossMaxHealth);
	CreateNative("FF2Data.MaxHealth.set", Native_SetBossMaxHealth);
	CreateNative("FF2Data.Lives.get", Native_SetBossLives);
	CreateNative("FF2Data.Lives.set", Native_GetBossLives);
	CreateNative("FF2Data.MaxLives.get", Native_GetBossMaxLives);
	CreateNative("FF2Data.MaxLives.set", Native_SetBossMaxLives);
	CreateNative("FF2Data.RageDmg.get", Native_GetBossRageDamage);
	CreateNative("FF2Data.RageDmg.set", Native_SetBossRageDamage);
	CreateNative("FF2Data.Change", FF2Data_Change);
	CreateNative("FF2Data.GetArgI", FF2Data_GetArgI);
	CreateNative("FF2Data.GetArgF", FF2Data_GetArgF);
	CreateNative("FF2Data.GetArgB", FF2Data_GetArgB);
	CreateNative("FF2Data.GetArgS", FF2Data_GetArgS);
	CreateNative("FF2Data.HasAbility", FF2Data_HasAbility);
	CreateNative("FF2Data.BossTeam", Native_GetTeam);
	
	PreAbility = new GlobalForward("FF2_PreAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell, Param_CellByRef);  //Boss, plugin name, ability name, slot, enabled
	OnAbility = new GlobalForward("FF2_OnAbility", ET_Hook, Param_Cell, Param_String, Param_String, Param_Cell);  //Boss, plugin name, ability name, status
	OnMusic = new GlobalForward("FF2_OnMusic", ET_Hook, Param_String, Param_FloatByRef);
	OnMusic2 = new GlobalForward("FF2_OnMusic2", ET_Hook, Param_String, Param_FloatByRef, Param_String, Param_String);
	OnTriggerHurt = new GlobalForward("FF2_OnTriggerHurt", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	OnSpecialSelected = new GlobalForward("FF2_OnSpecialSelected", ET_Hook, Param_Cell, Param_CellByRef, Param_String, Param_Cell);  //Boss, character index, character name, preset
	OnAddQueuePoints = new GlobalForward("FF2_OnAddQueuePoints", ET_Hook, Param_Array);
	OnLoadCharacterSet = new GlobalForward("FF2_OnLoadCharacterSet", ET_Hook, Param_CellByRef, Param_String);
	OnLoseLife = new GlobalForward("FF2_OnLoseLife", ET_Hook, Param_Cell, Param_CellByRef, Param_Cell);  //Boss, lives left, max lives
	OnAlivePlayersChanged = new GlobalForward("FF2_OnAlivePlayersChanged", ET_Hook, Param_Cell, Param_Cell);  //Players, bosses
	OnBackstabbed = new GlobalForward("FF2_OnBackStabbed", ET_Hook, Param_Cell, Param_Cell, Param_Cell);  //Boss, client, attacker

	RegPluginLibrary("freak_fortress_2");

	AskPluginLoad_VSH();
	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif

	#if defined _SteamWorks_Included
	MarkNativeAsOptional("SteamWorks_SetGameDescription");
	#endif

	#if defined _tf2attributes_included
	MarkNativeAsOptional("TF2Attrib_SetByDefIndex");
	MarkNativeAsOptional("TF2Attrib_RemoveByDefIndex");
	#endif

	LateLoaded = late;
	return APLRes_Success;
}

// Boss Selection
char xIncoming[MAXTF2PLAYERS][700];
char cIncoming[MAXTF2PLAYERS][700];
char dIncoming[MAXTF2PLAYERS][700];
int CanBossVs[MAXTF2PLAYERS];
int CanBossTeam[MAXTF2PLAYERS];
bool IgnoreValid[MAXTF2PLAYERS];

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
Handle DiffCookie = INVALID_HANDLE;

ClientPoint[MAXTF2PLAYERS];
ClientID[MAXTF2PLAYERS];
ClientQueue[MAXTF2PLAYERS][2];
bool InfiniteRageActive[MAXTF2PLAYERS] = false;

// Boss Log
char bLog[PLATFORM_MAX_PATH];
char eLog[PLATFORM_MAX_PATH];
char pLog[PLATFORM_MAX_PATH];

// Preferences
int QueuePoints[MAXTF2PLAYERS];
bool ToggleMusic[MAXTF2PLAYERS];	// TODO: Disable temp for round?
bool ToggleVoice[MAXTF2PLAYERS];
bool ToggleInfo[MAXTF2PLAYERS];
SettingPrefs ToggleDuo[MAXTF2PLAYERS];
SettingPrefs ToggleBoss[MAXTF2PLAYERS];
SettingPrefs ToggleDiff[MAXTF2PLAYERS];

// Stat Tracker
int BossWins[MAXTF2PLAYERS];
int BossLosses[MAXTF2PLAYERS];
int BossKills[MAXTF2PLAYERS];
int BossKillsF[MAXTF2PLAYERS];
int BossDeaths[MAXTF2PLAYERS];
int PlayerKills[MAXTF2PLAYERS];
int PlayerMVPs[MAXTF2PLAYERS];

// HUD Toggle
int HudSettings[MAXTF2PLAYERS][HUDTYPES];

public void OnPluginStart()
{
	LogMessage("Freak Fortress 2 %s Loading...", PLUGIN_VERSION);

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
		
	_FF2Save = new FF2Save();
	
	cvarVersion = CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarCharset = CreateConVar("ff2_current", "0", "Freak Fortress 2 Current Boss Pack", FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarPointType = CreateConVar("ff2_point_type", "0", "0-Use ff2_point_alive, 1-Use ff2_point_time, 2-Use both", _, true, 0.0, true, 2.0);
	cvarPointDelay = CreateConVar("ff2_point_delay", "6", "Seconds to add to ff2_point_time per player");
	cvarPointTime = CreateConVar("ff2_point_time", "45", "Time before unlocking the control point");
	cvarAliveToEnable = CreateConVar("ff2_point_alive", "0.2", "The control point will only activate when there are this many people or less left alive, can be a ratio", _, true, 0.0, true, 34.0);
	cvarAnnounce = CreateConVar("ff2_announce", "120", "Amount of seconds to wait until FF2 info is displayed again.  0 to disable", _, true, 0.0);
	cvarAnnounceAds = CreateConVar("ff2_announce_ads", "1", "0-Disable mentioning authors/links, 1-Mention authors/links", _, true, 0.0, true, 1.0);
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
	cvarChangelog = CreateConVar("ff2_changelog_url", CHANGELOG_URL, "FF2 Changelog URL. Normally you are not supposed to change this...", FCVAR_SPONLY|FCVAR_DONTRECORD);
	cvarCaberDetonations = CreateConVar("ff2_caber_detonations", "1", "Amount of times somebody can detonate the Ullapool Caber (0 = Infinite)", _, true, 0.0);
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
	cvarNameChange = CreateConVar("ff2_name_change", "0", "0-Disable, 1-Add the current boss to the server name, 2-Add the current charset to the server name", _, true, 0.0, true, 2.0);
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
	cvarSteamTools = CreateConVar("ff2_steam_tools", "1", "0-Disable, 1-Show 'Freak Fortress 2' in game description (requires SteamTools or SteamWorks)", _, true, 0.0, true, 1.0);
	cvarSappers = CreateConVar("ff2_sapper", "0", "0-Disable, 1-Can sap the boss, 2-Can sap minions, 3-Can sap both", _, true, 0.0, true, 3.0);
	cvarSapperCooldown = CreateConVar("ff2_sapper_cooldown", "500", "0-No Cooldown, #-Damage needed to be able to use again", _, true, 0.0);
	cvarSapperStart = CreateConVar("ff2_sapper_starting", "0", "#-Damage needed for first usage (Not used if ff2_sapper or ff2_sapper_cooldown is 0)", _, true, 0.0);
	cvarTheme = CreateConVar("ff2_theme", "0", "0-No Theme, #-Flags of Themes", _, true, 0.0);
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
	cvarShuffleCharset = CreateConVar("ff2_bosspack_vote", "0", "0-Random option and show all packs, #-Random amount of packs to choose", _, true, 0.0, true, 64.0);
	cvarBroadcast = CreateConVar("ff2_broadcast", "0", "0-Block round end sounds, 1-Play round end sounds", _, true, 0.0, true, 1.0);
	cvarMarket = CreateConVar("ff2_market_garden", "1.0", "0-Disable market gardens, #-Damage ratio of market gardens", _, true, 0.0);
	cvarCloak = CreateConVar("ff2_cloak_damage", "1.0", "#-Extra damage multipler or maximum damage taken for cloak watches from bosses", _, true, 0.0);
	cvarRinger = CreateConVar("ff2_deadringer_damage", "1.0", "#-Extra damage multipler or maximum damage taken for dead ringers from bosses", _, true, 0.0);
	cvarKunai = CreateConVar("ff2_kunai_health", "200", "#-Overheal gained via Conniver's Kunai");
	cvarKunaiMax = CreateConVar("ff2_kunai_max", "600", "#-Maximum overheal gained via Conniver's Kunai", _, true, 1.0);
	cvarDisguise = CreateConVar("ff2_disguise", "1", "0-Disable, 1-Enable disguises showing player models (requires tf2attributes)", _, true, 0.0, true, 1.0);
	cvarDiamond = CreateConVar("ff2_diamondback", "2", "#-Amount of revenge crits gained upon backstabbing a boss", _, true, 0.0);
	cvarCloakStun = CreateConVar("ff2_cloak_stun", "2.0", "#-Amount in seconds before allowing to cloak after a backstab", _, true, 0.0);
	cvarDatabase = CreateConVar("ff2_stats_database", "0", "0-Only Client Preferences, 1-SQL over Client Preferences, 2-Only SQL | Table is ff2_stattrak", _, true, 0.0, true, 2.0);
	cvarChargeAngle = CreateConVar("ff2_charge_angle", "30", "View angle requirement to activate charge abilities", _, true, 0.0, true, 360.0);
	cvarAttributes = CreateConVar("ff2_attributes", "2 ; 3.1 ; 275 ; 1", "Default attributes assigned to bosses without 'override' setting");
	cvarStartingUber = CreateConVar("ff2_uber_start", "40.0", "Starting Ubercharge precentage on round start", _, true, 0.0, true, 100.0);
	cvarDamageHud = CreateConVar("ff2_damage_tracker", "0", "Default Damage Tracker value for players", _, true, 0.0, true, 9.0);
	cvarTelefrag = CreateConVar("ff2_telefrag_damage", "5000.0", "Damage dealt upon a Telefrag", _, true, 0.0);
	cvarHealth = CreateConVar("ff2_health_formula", "(((760.8+n)*(n-1))^1.0341)+2046", "Default boss health formula");
	cvarRageDamage = CreateConVar("ff2_rage_formula", "1900.0", "Default boss ragedamage formula");
	cvarDifficulty = CreateConVar("ff2_difficulty_random", "0.0", "0-Players can set their difficulty, #-Chance of difficulty", _, true, 0.0, true, 100.0);
	cvarEnableSandmanStun = CreateConVar("ff2_enable_sandmanstun", "0", "0-Disable the Sandman stun ability, 1-Enable the Sandman stun ability", _, true, 0.0, true, 1.0);
	cvarShowBossBlocked = CreateConVar("ff2_boss_show_in_blocked_maps", "1.0", "0-Bosses will not appear in !ff2boss if their config blocked the map. 1-Bosses will appear in !ff2boss as a disabled option.", _, true, 0.0, true, 1.0);

	//The following are used in various subplugins
	CreateConVar("ff2_oldjump", "1", "Use old Saxton Hale jump equations", _, true, 0.0, true, 1.0);
	CreateConVar("ff2_base_jumper_stun", "0", "Whether or not the Base Jumper should be disabled when a player gets stunned", _, true, 0.0, true, 1.0);
	CreateConVar("ff2_solo_shame", "0", "Always insult the boss for solo raging", _, true, 0.0, true, 1.0);

	// Round Events
	HookEvent("teamplay_round_start", OnRoundSetup, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd);

	// Control Point Events
	HookEvent("teamplay_point_startcapture", OnStartCapture, EventHookMode_PostNoCopy);
	HookEvent("teamplay_capture_broken", OnBreakCapture);

	// Player Events
	HookEvent("post_inventory_application", OnPostInventoryApplication, EventHookMode_Pre);
	HookEvent("player_healed", OnPlayerHealed, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("player_chargedeployed", OnUberDeployed);
	HookEvent("object_deflected", OnObjectDeflected, EventHookMode_Pre);
	HookEvent("deploy_buff_banner", OnDeployBackup);
	HookEvent("rps_taunt_event", OnRPS);

	// Other Events
	HookEvent("teamplay_broadcast_audio", OnBroadcast, EventHookMode_Pre);
	HookEvent("object_destroyed", OnObjectDestroyed, EventHookMode_Pre);
	HookEvent("arena_win_panel", OnWinPanel, EventHookMode_Pre);

	OnPluginStart_TeleportToMultiMapSpawn();	// Setup adt_array

	HookUserMessage(GetUserMessageId("PlayerJarated"), OnJarate);	//Used to subtract rage when a boss is jarated (not through Sydney Sleeper)

	AddCommandListener(OnCallForMedic, "voicemenu");	//Used to activate rages
	AddCommandListener(OnSuicide, "explode");		//Used to stop boss from suiciding
	AddCommandListener(OnSuicide, "kill");			//Used to stop boss from suiciding
	AddCommandListener(OnSuicide, "spectate");		//Used to make sure players don't kill themselves and going to spec
	AddCommandListener(OnJoinTeam, "jointeam");		//Used to make sure players join the right team
	AddCommandListener(OnJoinTeam, "autoteam");		//Used to make sure players don't kill themselves and change team
	AddCommandListener(OnChangeClass, "joinclass");		//Used to make sure bosses don't change class

	cvarEnabled.AddChangeHook(CvarChange);
	cvarAnnounce.AddChangeHook(CvarChange);
	cvarCircuitStun.AddChangeHook(CvarChange);
	cvarHealthBar.AddChangeHook(CvarChange);
	cvarLastPlayerGlow.AddChangeHook(CvarChange);
	cvarSpecForceBoss.AddChangeHook(CvarChange);
	cvarBossTeleporter.AddChangeHook(CvarChange);
	cvarShieldCrits.AddChangeHook(CvarChange);
	cvarCaberDetonations.AddChangeHook(CvarChange);
	cvarGoombaDamage.AddChangeHook(CvarChange);
	cvarGoombaRebound.AddChangeHook(CvarChange);
	cvarBossRTD.AddChangeHook(CvarChange);
	cvarSniperDamage.AddChangeHook(CvarChange);
	cvarSniperMiniDamage.AddChangeHook(CvarChange);
	cvarBowDamage.AddChangeHook(CvarChange);
	cvarBowDamageNon.AddChangeHook(CvarChange);
	cvarBowDamageMini.AddChangeHook(CvarChange);
	cvarSniperClimbDamage.AddChangeHook(CvarChange);
	cvarSniperClimbDelay.AddChangeHook(CvarChange);
	cvarQualityWep.AddChangeHook(CvarChange);
	cvarPointsInterval.AddChangeHook(CvarChange);
	cvarPointsDamage.AddChangeHook(CvarChange);
	cvarPointsMin.AddChangeHook(CvarChange);
	cvarPointsExtra.AddChangeHook(CvarChange);
	cvarDuoMin.AddChangeHook(CvarChange);
	cvarAnnotations.AddChangeHook(CvarChange);
	cvarTellName.AddChangeHook(CvarChange);
	cvarHealthHud.AddChangeHook(CvarChange);
	cvarDatabase.AddChangeHook(CvarChange);
	cvarChargeAngle.AddChangeHook(CvarChange);
	cvarAttributes.AddChangeHook(CvarChange);
	cvarStartingUber.AddChangeHook(CvarChange);
	cvarHealth.AddChangeHook(CvarChange);
	cvarRageDamage.AddChangeHook(CvarChange);
	(cvarNextmap=FindConVar("sm_nextmap")).AddChangeHook(CvarChangeNextmap);

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
	RegConsoleCmd("ff2_hud", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("ff2hud", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("ff2_dmg", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("ff2dmg", Command_HudMenu, "Toggle specific HUD settings");

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
	RegConsoleCmd("hale_hud", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("halehud", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("hale_dmg", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("haledmg", Command_HudMenu, "Toggle specific HUD settings");

	RegConsoleCmd("sm_setboss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("sm_boss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("nextmap", Command_Nextmap);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	ReloadFF2 = false;
	ReloadWeapons = false;
	ReloadConfigs = false;

	RegAdminCmd("ff2_loadcharset", Command_LoadCharset, ADMFLAG_RCON, "Usage: ff2_loadcharset <charset>.  Forces FF2 to switch to a given character set without changing maps");
	RegAdminCmd("ff2_reloadcharset", Command_ReloadCharset, ADMFLAG_RCON, "Forces FF2 to reload the current character set");
	RegAdminCmd("ff2_reload", Command_ReloadFF2, ADMFLAG_ROOT, "Reloads FF2 safely and quietly");
	RegAdminCmd("ff2_reloadweapons", Command_ReloadFF2Weapons, ADMFLAG_RCON, "Reloads FF2 weapon configuration safely and quietly");
	RegAdminCmd("ff2_reloadconfigs", Command_ReloadFF2Configs, ADMFLAG_RCON, "Reloads ALL FF2 configs safely and quietly");

	RegAdminCmd("ff2_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage: ff2_special <boss>.  Forces next round to use that boss");
	RegAdminCmd("ff2_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage: ff2_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("ff2_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_start_music", Command_StartMusic, ADMFLAG_CHEATS, "Start the Boss's music");
	RegAdminCmd("ff2_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently playing Boss music");
	RegAdminCmd("ff2_resetqueuepoints", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("ff2_resetq", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("ff2_charset", Command_Charset, ADMFLAG_CHEATS, "Usage: ff2_charset <charset>.  Forces FF2 to use a given character set");
	RegAdminCmd("ff2_reload_subplugins", Command_ReloadSubPlugins, ADMFLAG_RCON, "Reload FF2's subplugins.");
	RegAdminCmd("ff2_setrage", Command_SetRage, ADMFLAG_CHEATS, "Usage: ff2_setrage <target> <percent>. Sets the RAGE to a boss player");
	RegAdminCmd("ff2_addrage", Command_AddRage, ADMFLAG_CHEATS, "Usage: ff2_addrage <target> <percent>. Gives RAGE to a boss player");
	RegAdminCmd("ff2_setinfiniterage", Command_SetInfiniteRage, ADMFLAG_CHEATS, "Usage: ff2_infiniterage <target>. Gives infinite RAGE to a boss player");
	RegAdminCmd("ff2_setcharge", Command_SetCharge, ADMFLAG_CHEATS, "Usage: ff2_setcharge <target> <slot> <percent>. Sets a boss's charge");
	RegAdminCmd("ff2_addcharge", Command_AddCharge, ADMFLAG_CHEATS, "Usage: ff2_addcharge <target> <slot> <percent>. Adds a boss's charge");
	RegAdminCmd("ff2_makeboss", Command_MakeBoss, ADMFLAG_CHEATS, "Usage: ff2_makeboss <target> [team]. Makes a player a boss.");

	RegAdminCmd("hale_select", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage: hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage: hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage: hale_addpoints <target> <points>.  Adds queue points to any player");
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
	HudCookies = RegClientCookie("ff2_cookies_huds", "Player's HUD Settings", CookieAccess_Protected);
	LastPlayedCookie = RegClientCookie("ff2_boss_previous", "Player's Last Boss", CookieAccess_Protected);
	SelectionCookie = RegClientCookie("ff2_boss_selection", "Player's Boss Selection", CookieAccess_Protected);
	DiffCookie = RegClientCookie("ff2_boss_difficulty", "Player's Difficulty Selection", CookieAccess_Protected);

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
	LoadTranslations("freak_fortress_2_weaps.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

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

	#if defined _SteamWorks_Included
	steamworks = LibraryExists("SteamWorks");
	#endif

	#if defined _goomba_included
	goomba = LibraryExists("goomba");
	#endif

	#if defined _tf2attributes_included
	tf2attributes = LibraryExists("tf2attributes");
	#endif

	TimesTen = LibraryExists("tf2x10");

	Handle gameData = LoadGameConfigFile("equipwearable");
	if(gameData == INVALID_HANDLE)
	{
		LogToFile(eLog, "[Gamedata] Failed to find equipwearable.txt");
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(SDKEquipWearable == null)
		LogToFile(eLog, "[Gamedata] Failed to create call: CBasePlayer::EquipWearable");

	delete gameData;
}

public Action Command_SetRage(int client, int args)
{
	if(args != 2)
	{
		if(args != 1)
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

			if(!IsBoss(client) || !IsPlayerAlive(client) || CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to set your RAGE!");
				return Plugin_Handled;
			}

			static char ragePCT[80];
			GetCmdArg(1, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);

			BossCharge[GetBossIndex(client)][0] = rageMeter;
			FReplyToCommand(client, "You now have %i percent RAGE", RoundFloat(BossCharge[client][0]));
			LogAction(client, client, "\"%L\" gave themselves %i RAGE", client, RoundFloat(rageMeter));
			CheatsUsed = true;
		}
		return Plugin_Handled;
	}

	static char ragePCT[80];
	static char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		if(!IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to set RAGE!", target_name);
			return Plugin_Handled;
		}

		BossCharge[GetBossIndex(target_list[target])][0] = rageMeter;
		LogAction(client, target_list[target], "\"%L\" set %d RAGE to \"%L\"", client, RoundFloat(rageMeter), target_list[target]);
		FReplyToCommand(client, "Set %d rage to %s", RoundFloat(rageMeter), target_name);
		CheatsUsed = true;
	}
	return Plugin_Handled;
}

public Action Command_AddRage(int client, int args)
{
	if(args != 2)
	{
		if(args != 1)
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

			if(!IsBoss(client) || !IsPlayerAlive(client) || CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to give yourself RAGE!");
				return Plugin_Handled;
			}

			static char ragePCT[80];
			GetCmdArg(1, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);

			BossCharge[GetBossIndex(client)][0] += rageMeter;
			FReplyToCommand(client, "You now have %i percent RAGE (%i percent added)", RoundFloat(BossCharge[client][0]), RoundFloat(rageMeter));
			LogAction(client, client, "\"%L\" gave themselves %i more RAGE", client, RoundFloat(rageMeter));
			CheatsUsed = true;
		}
		return Plugin_Handled;
	}

	static char ragePCT[80];
	static char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		if(!IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to add RAGE!", target_name);
			return Plugin_Handled;
		}

		BossCharge[GetBossIndex(target_list[target])][0] += rageMeter;
		LogAction(client, target_list[target], "\"%L\" added %d RAGE to \"%L\"", client, RoundFloat(rageMeter), target_list[target]);
		FReplyToCommand(client, "Added %d rage to %s", RoundFloat(rageMeter), target_name);
		CheatsUsed = true;
	}
	return Plugin_Handled;
}

public Action Command_SetInfiniteRage(int client, int args)
{
	if(args != 1)
	{
		if(args > 1)
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

			if(!IsBoss(client) || !IsPlayerAlive(client) || CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to enable/disable infinite RAGE!");
				return Plugin_Handled;
			}

			if(!InfiniteRageActive[client])
			{
				InfiniteRageActive[client] = true;
				BossCharge[GetBossIndex(client)][0] = rageMax[client];
				FReplyToCommand(client, "Infinite RAGE activated");
				LogAction(client, client, "\"%L\" activated infinite RAGE on themselves", client);
				CreateTimer(0.2, Timer_InfiniteRage, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				CheatsUsed = true;
			}
			else
			{
				InfiniteRageActive[client] = false;
				FReplyToCommand(client, "Infinite RAGE deactivated");
				LogAction(client, client, "\"%L\" deactivated infinite RAGE on themselves", client);
				CheatsUsed = true;
			}
		}
		return Plugin_Handled;
	}

	static char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		if(!IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to enable/disable infinite RAGE!", target_name);
			return Plugin_Handled;
		}

		if(!InfiniteRageActive[target_list[target]])
		{
			InfiniteRageActive[target_list[target]] = true;
			BossCharge[GetBossIndex(target_list[target])][0] = rageMax[target_list[target]];
			FReplyToCommand(client, "Infinite RAGE activated for %s", target_name);
			LogAction(client, target_list[target], "\"%L\" activated infinite RAGE on \"%L\"", client, target_list[target]);
			CreateTimer(0.2, Timer_InfiniteRage, GetClientUserId(target_list[target]), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CheatsUsed = true;
		}
		else
		{
			InfiniteRageActive[target_list[target]] = false;
			FReplyToCommand(client, "Infinite RAGE deactivated for %s", target_name);
			LogAction(client, target_list[target], "\"%L\" deactivated infinite RAGE on \"%L\"", client, target_list[target]);
		}
	}
	return Plugin_Handled;
}

public Action Timer_InfiniteRage(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsBoss(client))
		return Plugin_Stop;

	if(CheckRoundState()!=1 || !IsPlayerAlive(client))
	{
		InfiniteRageActive[client] = false;
		return Plugin_Stop;
	}

	if(CheckRoundState() == 1)
		BossCharge[GetBossIndex(client)][0] = rageMax[client];

	return Plugin_Continue;
}

public Action Command_AddCharge(int client, int args)
{
	if(args != 3)
	{
		if(args != 2)
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

			static char ragePCT[80], slotCharge[10];
			GetCmdArg(1, slotCharge, sizeof(slotCharge));
			GetCmdArg(2, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);
			int abilitySlot = StringToInt(slotCharge);

			if(abilitySlot>=0 && abilitySlot<4)
			{
				BossCharge[GetBossIndex(client)][abilitySlot] += rageMeter;
				FReplyToCommand(client, "Slot %i's charge: %i percent (added %i percent)!", abilitySlot, RoundFloat(BossCharge[GetBossIndex(client)][abilitySlot]), RoundFloat(rageMeter));
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

	static char ragePCT[80], slotCharge[10];
	static char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, slotCharge, sizeof(slotCharge));
	GetCmdArg(3, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);
	int abilitySlot = StringToInt(slotCharge);

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		if(!IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to add their charge!", target_name);
			return Plugin_Handled;
		}

		if(abilitySlot>=0 || abilitySlot<4)
		{
			BossCharge[GetBossIndex(target_list[target])][abilitySlot] += rageMeter;
			FReplyToCommand(client, "%s's ability slot %i's charge: %i percent (added %i percent)!", target_name, abilitySlot, RoundFloat(BossCharge[GetBossIndex(target_list[target])][abilitySlot]), RoundFloat(rageMeter));
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
	if(args != 3)
	{
		if(args != 2)
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

			static char ragePCT[80], slotCharge[10];
			GetCmdArg(1, slotCharge, sizeof(slotCharge));
			GetCmdArg(2, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);
			int abilitySlot = StringToInt(slotCharge);

			if(abilitySlot>=0 || abilitySlot<4)
			{
				BossCharge[GetBossIndex(client)][abilitySlot] = rageMeter;
				FReplyToCommand(client, "Slot %i's charge: %i percent!", abilitySlot, RoundFloat(BossCharge[GetBossIndex(client)][abilitySlot]));
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

	static char ragePCT[80], slotCharge[10];
	static char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, slotCharge, sizeof(slotCharge));
	GetCmdArg(3, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);
	int abilitySlot = StringToInt(slotCharge);

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		if(!IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to set their charge!", target_name);
			return Plugin_Handled;
		}

		if(abilitySlot>=0 || abilitySlot<4)
		{
			BossCharge[GetBossIndex(target_list[target])][abilitySlot] = rageMeter;
			FReplyToCommand(client, "%s's ability slot %i's charge: %i percent!", target_name, abilitySlot, RoundFloat(BossCharge[GetBossIndex(target_list[target])][abilitySlot]));
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

	static char targetName[PLATFORM_MAX_PATH], teamString[4], specialString[4], indexString[4];
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

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
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

			HasEquipped[boss] = false;
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

				HasEquipped[boss] = false;
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
							BossSwitched[boss] = team==OtherTeam;
						}
						else if(team > 0)
						{
							BossSwitched[boss] = GetRandomInt(0, 1)==1;
						}

						if(special >= 0)
							Incoming[boss] = special;

						HasEquipped[boss] = false;
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
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || FindValueInArray(clients, client)!=-1)
			continue;

		if(IsBoss(client))
		{
			if(!non)
				PushArrayCell(clients, client);
		}
		else if(non)
		{
			PushArrayCell(clients, client);
		}
	}
	return true;
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "tf2x10", false))
	{
		TimesTen = true;
	}
	#if defined _steamtools_included
	else if(StrEqual(name, "SteamTools", false))
	{
		steamtools = true;
	}
	#endif
	#if defined _SteamWorks_Included
	else if(StrEqual(name, "SteamWorks", false))
	{
		steamworks = true;
	}
	#endif
	#if defined _tf2attributes_included
	else if(StrEqual(name, "tf2attributes", false))
	{
		tf2attributes = true;
	}
	#endif
	#if defined _goomba_included
	else if(StrEqual(name, "goomba", false))
	{
		goomba = true;
	}
	#endif
	#if !defined _smac_included
	else if(StrEqual(name, "smac", false))
	{
		smac = true;
	}
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "tf2x10", false))
	{
		TimesTen = false;
	}
	#if defined _steamtools_included
	else if(StrEqual(name, "SteamTools", false))
	{
		steamtools = false;
	}
	#endif
	#if defined _SteamWorks_Included
	else if(StrEqual(name, "SteamWorks", false))
	{
		steamworks = false;
	}
	#endif
	#if defined _tf2attributes_included
	else if(StrEqual(name, "tf2attributes", false))
	{
		tf2attributes = false;
	}
	#endif
	#if defined _goomba_included
	else if(StrEqual(name, "goomba", false))
	{
		goomba = false;
	}
	#endif
	#if !defined _smac_included
	else if(StrEqual(name, "smac", false))
	{
		smac = false;
	}
	#endif
}

public void OnConfigsExecuted()
{
	tf_arena_use_queue = GetConVarInt(FindConVar("tf_arena_use_queue"));
	mp_teams_unbalance_limit = GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
	tf_arena_first_blood = GetConVarInt(FindConVar("tf_arena_first_blood"));
	mp_forcecamera = GetConVarInt(FindConVar("mp_forcecamera"));
	tf_dropped_weapon_lifetime = GetConVarInt(FindConVar("tf_dropped_weapon_lifetime"));
	GetConVarString(FindConVar("mp_humans_must_join_team"), mp_humans_must_join_team, sizeof(mp_humans_must_join_team));
	GetConVarString(hostName=FindConVar("hostname"), oldName, sizeof(oldName));

	if(cvarEnabled.IntValue>1 || (IsFF2Map(currentmap) && cvarEnabled.IntValue>0))
	{
		EnableFF2();
	}
	else
	{
		DisableFF2();
		CacheDifficulty();
		FindCharacters();
	}
}

public void OnMapStart()
{
	HPTime = 0.0;
	doorCheckTimer = INVALID_HANDLE;
	RoundCount = 0;
	GetCurrentMap(currentmap, sizeof(currentmap));

	for(int client; client<=MaxClients; client++)
	{
		KSpreeTimer[client] = 0.0;
		FF2flags[client] = 0;
		Incoming[client] = -1;
		delete MusicTimer[client];
		RPSHealth[client] = -1;
		RPSLosses[client] = 0;
		RPSHealth[client] = 0;
		RPSLoser[client] = -1.0;
	}

	for(int specials; specials<MAXSPECIALS; specials++)
	{
		for(int i; i<MAXCHARSETS; i++)
		{
			if(PackKV[specials][i] == null)
				continue;

			delete PackKV[specials][i];
		}

		if(BossKV[specials] == null)
			continue;

		delete BossKV[specials];
	}
}

public void OnMapEnd()
{
	if(Enabled || Enabled2)
		DisableFF2();
}

public void OnPluginEnd()
{
	OnMapEnd();
	hostName.SetString(oldName);
	if(!ReloadFF2 && CheckRoundState()==1)
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
	Announce = cvarAnnounce.FloatValue;
	PointType = cvarPointType.IntValue;
	PointDelay = cvarPointDelay.IntValue;
	GoombaDamage = cvarGoombaDamage.FloatValue;
	reboundPower = cvarGoombaRebound.FloatValue;
	SniperDamage = cvarSniperDamage.FloatValue;
	SniperMiniDamage = cvarSniperMiniDamage.FloatValue;
	BowDamage = cvarBowDamage.FloatValue;
	BowDamageNon = cvarBowDamageNon.FloatValue;
	BowDamageMini = cvarBowDamageMini.FloatValue;
	SniperClimbDamage = cvarSniperClimbDamage.FloatValue;
	SniperClimbDelay = cvarSniperClimbDelay.FloatValue;
	QualityWep = cvarQualityWep.IntValue;
	canBossRTD = cvarBossRTD.BoolValue;
	AliveToEnable = cvarAliveToEnable.FloatValue;
	PointsInterval = cvarPointsInterval.IntValue;
	PointsInterval2 = cvarPointsInterval.FloatValue;
	PointsDamage = cvarPointsDamage.IntValue;
	PointsMin = cvarPointsMin.IntValue;
	PointsExtra = cvarPointsExtra.IntValue;
	arenaRounds = cvarArenaRounds.IntValue;
	circuitStun = cvarCircuitStun.FloatValue;
	countdownHealth = cvarCountdownHealth.IntValue;
	countdownPlayers = cvarCountdownPlayers.FloatValue;
	countdownTime = cvarCountdownTime.IntValue;
	countdownOvertime = cvarCountdownOvertime.BoolValue;
	lastPlayerGlow = cvarLastPlayerGlow.FloatValue;
	bossTeleportation = cvarBossTeleporter.IntValue;
	shieldCrits = cvarShieldCrits.IntValue;
	allowedDetonations = cvarCaberDetonations.IntValue;
	Annotations = cvarAnnotations.IntValue;
	TellName = cvarTellName.BoolValue;

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
	CacheDifficulty();
	CheckToChangeMapDoors();
	CheckToTeleportToSpawn();
	MapHasMusic(true);
	FindCharacters();
	FF2CharSetString[0] = 0;

	#if !defined _smac_included
	if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
	{
		ServerCommand("smac_removecvar sv_cheats");
		ServerCommand("smac_removecvar host_timescale");
	}
	#endif

	bMedieval = FindEntityByClassname(-1, "tf_logic_medieval")!=-1 || GetConVarBool(FindConVar("tf_medieval"));
	FindHealthBar();

	changeGamemode = 0;

	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client))
			OnClientPostAdminCheck(client);
	}

	EnabledDesc = true;
	if(cvarSteamTools.BoolValue)
	{
		char gameDesc[64];
		if(TimesTen)
		{
			FormatEx(gameDesc, sizeof(gameDesc), "Freak Fortress 2 x10 (%s)", PLUGIN_VERSION);
		}
		else
		{
			FormatEx(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
		}

		#if defined _SteamWorks_Included
		if(steamworks)
		{
			SteamWorks_SetGameDescription(gameDesc);
			return;
		}
		#endif

		#if defined _steamtools_included
		if(steamtools)
		{
			Steam_SetGameDescription(gameDesc);
		}
		#endif
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
	hostName.SetString(oldName);

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
			SaveClientPreferences(client);

		if(MusicTimer[client] != null)
		{
			delete MusicTimer[client];
		}
	}

	#if !defined _smac_included
	if(smac && FindPluginByFile("smac_cvars.smx") != INVALID_HANDLE)
	{
		ServerCommand("smac_addcvar sv_cheats replicated ban 0 0");
		ServerCommand("smac_addcvar host_timescale replicated ban 1.0 1.0");
	}
	#endif

	changeGamemode = 0;

	if(EnabledDesc && cvarSteamTools.BoolValue)
	{
		#if defined _SteamWorks_Included
		if(steamworks)
		{
			SteamWorks_SetGameDescription("Team Fortress");
			EnabledDesc = false;
			return;
		}
		#endif

		#if defined _steamtools_included
		if(steamtools)
			Steam_SetGameDescription("Team Fortress");
		#endif
	}
	EnabledDesc = false;
}

public void CacheWeapons()
{
	if(cvarHardcodeWep.IntValue > 1)
	{
		ConfigWeapons = false;
		return;
	}

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, WeaponCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, WeaponCFG);
		if(!FileExists(config))
		{
			LogToFile(eLog, "[Weapons] Could not find '%s'!", WeaponCFG);
			ConfigWeapons = false;
			return;
		}
	}

	kvWeaponMods = CreateKeyValues("Weapons");
	if(!FileToKeyValues(kvWeaponMods, config))
	{
		LogToFile(eLog, "[Weapons] '%s' is improperly formatted!", WeaponCFG);
		ConfigWeapons = false;
		return;
	}
	ConfigWeapons = true;
}

public void CacheDifficulty()
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, DifficultyCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, DifficultyCFG);
		if(!FileExists(config))
		{
			kvDiffMods = null;
			return;
		}
	}

	kvDiffMods = CreateKeyValues("difficulty");
	if(!FileToKeyValues(kvDiffMods, config))
	{
		LogToFile(eLog, "[Difficulty] '%s' is improperly formatted!", DifficultyCFG);
		kvDiffMods = null;
		return;
	}
}

public void FindCharacters()
{
	char filepath[PLATFORM_MAX_PATH], config[PLATFORM_MAX_PATH], key[4], charset[42];
	Specials = 0;
	int i;
	for(; i<MAXCHARSETS; i++)
	{
		PackSpecials[i] = 0;
	}
	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, "%s/%s", DataPath, CharsetCFG);

	if(!FileExists(filepath))
	{
		BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, "%s/%s", ConfigPath, CharsetCFG);
		if(!FileExists(filepath))
		{
			LogToFile(eLog, "[!!!] Unable to find '%s'", CharsetCFG);
			Enabled2 = false;
			return;
		}
		CharSetOldPath = true;
	}
	else
	{
		CharSetOldPath = false;
	}

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, filepath);
	int FF2CharSet = cvarCharset.IntValue;
	if(!Enabled2)
	{
		int amount;
		do
		{
			KvGetSectionName(Kv, CharSetString[amount], sizeof(CharSetString[]));
			KvGetString(Kv, "1", config, PLATFORM_MAX_PATH);
			if(config[0])
			{
				for(i=1; PackSpecials[amount]<MAXSPECIALS && i<=MAXSPECIALS; i++)
				{
					IntToString(i, key, sizeof(key));
					KvGetString(Kv, key, config, PLATFORM_MAX_PATH);
					if(!config[0])
						continue;

					if(StrContains(config, "*") >= 0)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						ProcessDirectory(filepath, "", config, amount);
						continue;
					}
					LoadSideCharacter(config, amount);
				}
			}
			else
			{
				KvGotoFirstSubKey(Kv);
				do
				{
					KvGetSectionName(Kv, config, PLATFORM_MAX_PATH);
					if(!config[0])
						break;

					if(StrContains(config, "*") >= 0)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						ProcessDirectory(filepath, "", config, amount);
						continue;
					}
					LoadSideCharacter(config, amount);
				} while(KvGotoNextKey(Kv) && PackSpecials[amount]<MAXSPECIALS);
				KvGoBack(Kv);
			}
			amount++;
		} while(amount<MAXCHARSETS && KvGotoNextKey(Kv));

		delete Kv;
		CurrentCharSet = -1;
		return;
	}

	int NumOfCharSet = FF2CharSet;
	Action action = Plugin_Continue;
	Call_StartForward(OnLoadCharacterSet);
	Call_PushCellRef(NumOfCharSet);
	strcopy(charset, sizeof(charset), FF2CharSetString);
	Call_PushStringEx(charset, sizeof(charset), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	if(action == Plugin_Changed)
	{
		i = -1;
		if(charset[0])
		{
			KvRewind(Kv);
			for(i=0; ; i++)
			{
				KvGetSectionName(Kv, config, sizeof(config));
				if(StrEqual(config, charset, false))
				{
					FF2CharSet = i;
					strcopy(FF2CharSetString, PLATFORM_MAX_PATH, charset);
					KvGotoFirstSubKey(Kv);
					break;
				}

				if(!KvGotoNextKey(Kv))
				{
					i = -1;
					break;
				}
			}
		}

		if(i == -1)
		{
			FF2CharSet = NumOfCharSet;
			for(i=0; i<FF2CharSet; i++)
			{
				KvGotoNextKey(Kv);
			}
			KvGotoFirstSubKey(Kv);
			KvGetSectionName(Kv, FF2CharSetString, sizeof(FF2CharSetString));
		}
	}

	KvRewind(Kv);
	for(i=0; i<FF2CharSet; i++)
	{
		if(!KvGotoNextKey(Kv))
			break;
	}

	CurrentCharSet = i;
	KvGetSectionName(Kv, CharSetString[CurrentCharSet], sizeof(CharSetString[]));

	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, ConfigPath);
	KvGetString(Kv, "1", config, PLATFORM_MAX_PATH);
	if(config[0])
	{
		for(i=1; Specials<MAXSPECIALS && i<=MAXSPECIALS; i++)
		{
			IntToString(i, key, sizeof(key));
			KvGetString(Kv, key, config, PLATFORM_MAX_PATH);
			if(!config[0])
				continue;

			if(StrContains(config, "*") >= 0)
			{
				ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
				ProcessDirectory(filepath, "", config, -1);
				continue;
			}
			LoadCharacter(config);
		}
	}
	else
	{
		KvGotoFirstSubKey(Kv);
		do
		{
			KvGetSectionName(Kv, config, PLATFORM_MAX_PATH);
			if(!config[0])
				break;

			if(StrContains(config, "*") >= 0)
			{
				ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
				ProcessDirectory(filepath, "", config, -1);
				continue;
			}
			LoadCharacter(config);
		} while(KvGotoNextKey(Kv) && Specials<MAXSPECIALS);
		KvGoBack(Kv);
	}

	KvGetString(Kv, "chances", ChancesString, sizeof(ChancesString));

	// Check if the current charset is not the first
	// one or if there's a charset after this one
	HasCharSets = CurrentCharSet>0;
	if(!HasCharSets)
		HasCharSets = KvGotoNextKey(Kv);

	delete Kv;

	int amount;
	if(HasCharSets)
	{
		if(cvarNameChange.IntValue == 2)
		{
			char newName[256];
			FormatEx(newName, 256, "%s | %s", oldName, CharSetString[CurrentCharSet]);
			hostName.SetString(newName);
		}

		// KvRewind, you son of a-
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);
		Kv = CreateKeyValues("");
		FileToKeyValues(Kv, config);
		do
		{
			if(amount == CurrentCharSet)	// Skip the current pack
			{
				amount++;
				continue;
			}

			KvGetSectionName(Kv, CharSetString[amount], sizeof(CharSetString[]));
			KvGetString(Kv, "1", config, PLATFORM_MAX_PATH);
			if(config[0])
			{
				for(i=1; PackSpecials[amount]<MAXSPECIALS && i<=MAXSPECIALS; i++)
				{
					IntToString(i, key, sizeof(key));
					KvGetString(Kv, key, config, PLATFORM_MAX_PATH);
					if(!config[0])
						continue;

					if(StrContains(config, "*") >= 0)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						ProcessDirectory(filepath, "", config, amount);
						continue;
					}
					LoadSideCharacter(config, amount);
				}
			}
			else
			{
				KvGotoFirstSubKey(Kv);
				do
				{
					KvGetSectionName(Kv, config, PLATFORM_MAX_PATH);
					if(!config[0])
						break;

					if(StrContains(config, "*") >= 0)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						ProcessDirectory(filepath, "", config, amount);
						continue;
					}
					LoadSideCharacter(config, amount);
				} while(KvGotoNextKey(Kv) && PackSpecials[amount]<MAXSPECIALS);
				KvGoBack(Kv);
			}
			amount++;
		} while(amount<MAXCHARSETS && KvGotoNextKey(Kv));

		delete Kv;
	}

	if(ChancesString[0])
	{
		char stringChances[MAXSPECIALS*2][8];
		amount = ExplodeString(ChancesString, ";", stringChances, MAXSPECIALS*2, 8);
		if(amount % 2)
		{
			LogToFile(eLog, "[Characters] Invalid chances string, disregarding chances");
			ChancesString[0] = 0;
			amount = 0;
		}

		chances[0] = StringToInt(stringChances[0]);
		chances[1] = StringToInt(stringChances[1]);
		for(chancesIndex=2; chancesIndex<amount; chancesIndex++)
		{
			if(chancesIndex % 2)
			{
				if(StringToInt(stringChances[chancesIndex]) < 1)
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
	PrecacheScriptSound("Announcer.AM_CapEnabledRandom");
	PrecacheScriptSound("Announcer.AM_CapIncite01.mp3");
	PrecacheScriptSound("Announcer.AM_CapIncite02.mp3");
	PrecacheScriptSound("Announcer.AM_CapIncite03.mp3");
	PrecacheScriptSound("Announcer.AM_CapIncite04.mp3");
	PrecacheScriptSound("Announcer.RoundEnds5minutes");
	PrecacheScriptSound("Announcer.RoundEnds2minutes");
	PrecacheSound("weapons/barret_arm_zap.wav", true);
	PrecacheSound("player/doubledonk.wav", true);
	PrecacheSound("ambient/lightson.wav", true);
	PrecacheSound("ambient/lightsoff.wav", true);
	isCharSetSelected = false;
}

void EnableSubPlugins(bool force=false)
{
	if(areSubPluginsEnabled && !force)
		return;

	areSubPluginsEnabled = true;
	char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH], filename_old[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "plugins/freaks");
	FileType filetype;
	Handle directory = OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".smx", false)!=-1)
		{
			FormatEx(filename_old, sizeof(filename_old), "%s/%s", path, filename);
			ReplaceString(filename, sizeof(filename), ".smx", ".ff2", false);
			Format(filename, sizeof(filename), "%s/%s", path, filename);
			DeleteFile(filename); // Just in case filename.ff2 also exists: delete it and replace it with the new .smx version
			RenameFile(filename, filename_old);
		}
	}

	directory = OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
			ServerCommand("sm plugins load freaks/%s", filename);
	}
}

void DisableSubPlugins(bool force=false)
{
	if(!areSubPluginsEnabled && !force)
		return;

	char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	FileType filetype;
	Handle directory = OpenDirectory(path);
	while(ReadDirEntry(directory, filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
			InsertServerCommand("sm plugins unload freaks/%s", filename);  //ServerCommand will not work when switching maps
	}
	ServerExecute();
	areSubPluginsEnabled = false;
}

public void ProcessDirectory(const char[] directory, const char[] current, const char[] config, int pack)
{
	char file[PLATFORM_MAX_PATH];
	FormatEx(file, PLATFORM_MAX_PATH, "%s\\%s", directory, current);
	if(!DirExists(file))
		return;

	DirectoryListing listing = OpenDirectory(file);
	if(listing == null)
		return;

	FileType type;
	while((((pack<0 && Specials<MAXSPECIALS) || (pack>=0 && PackSpecials[pack]<MAXSPECIALS))) && listing.GetNext(file, PLATFORM_MAX_PATH, type))
	{
		if(type == FileType_File)
		{
			if(ReplaceString(file, PLATFORM_MAX_PATH, ".cfg", "", false) != 1)
				continue;

			if(current[0])
			{
				Format(file, PLATFORM_MAX_PATH, "%s\\%s", current, file);
				ReplaceString(file, PLATFORM_MAX_PATH, "\\", "/");
			}

			if(!StrContains(file, config))
			{
				if(pack < 0)
				{
					LoadCharacter(file);
				}
				else
				{
					LoadSideCharacter(file, pack);
				}
			}
			continue;
		}

		if(type!=FileType_Directory || !StrContains(file, "."))
			continue;

		if(current[0])
		{
			Format(file, PLATFORM_MAX_PATH, "%s/%s", current, file);
			ProcessDirectory(directory, file, config, pack);
		}
		else
		{
			ProcessDirectory(directory, file, config, pack);
		}
	}
	delete listing;
}

public void LoadCharacter(const char[] character)
{
	static char extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy"};
	static char config[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, config, sizeof(config), "%s/%s.cfg", ConfigPath, character);
	if(!FileExists(config))
	{
		LogToFile(eLog, "[Characters] Character %s does not exist!", character);
		return;
	}
	BossKV[Specials] = CreateKeyValues("character");
	FileToKeyValues(BossKV[Specials], config);

	MapBlocked[Specials] = false;
	if(KvJumpToKey(BossKV[Specials], "map_only"))
	{
		char item[6];
		static char buffer[34];
		bool shouldBlock = true;
		for(int size=1; ; size++)
		{
			FormatEx(item, sizeof(item), "map%d", size);
			KvGetString(BossKV[Specials], item, buffer, sizeof(buffer));
			if(!buffer[0])
			{
				if(size==1)
				{
					shouldBlock = false;
				}
				break;
			}
            
			if(StrContains(currentmap, buffer)>=0)
			{
				shouldBlock = false;
				break;
			}
		}
		MapBlocked[Specials] = shouldBlock;
	}
	KvRewind(BossKV[Specials]);
	if(KvJumpToKey(BossKV[Specials], "map_exclude"))
	{
		char item[6];
		static char buffer[34];
		for(int size=1; ; size++)
		{
			FormatEx(item, sizeof(item), "map%d", size);
			KvGetString(BossKV[Specials], item, buffer, sizeof(buffer));
			if(!buffer[0])
				break;

			if(!StrContains(currentmap, buffer))
			{
				MapBlocked[Specials] = true;
				break;
			}
		}
	}
	KvRewind(BossKV[Specials]);

	int version = KvGetNum(BossKV[Specials], "version", StringToInt(MAJOR_REVISION));
	if(version!=StringToInt(MAJOR_REVISION) && version!=99) // 99 for bosses made ONLY for this fork
	{
		LogToFile(eLog, "[Boss] Character %s is only compatible with FF2 v%i!", character, version);
		return;
	}

	version = KvGetNum(BossKV[Specials], "version_minor", StringToInt(MINOR_REVISION));
	int version2 = KvGetNum(BossKV[Specials], "version_stable", StringToInt(STABLE_REVISION));
	if(version>StringToInt(MINOR_REVISION) || (version2>StringToInt(STABLE_REVISION) && version==StringToInt(MINOR_REVISION)))
	{
		LogToFile(eLog, "[Boss] Character %s requires newer version of FF2 (at least %s.%i.%i)!", character, MAJOR_REVISION, version, version2);
		return;
	}

	version = KvGetNum(BossKV[Specials], "fversion", StringToInt(FORK_MAJOR_REVISION));
	if(version != StringToInt(FORK_MAJOR_REVISION))
	{
		LogToFile(eLog, "[Boss] Character %s is only compatible with %s FF2 v%i!", character, FORK_SUB_REVISION, version);
		return;
	}

	version = KvGetNum(BossKV[Specials], "fversion_minor", StringToInt(FORK_MINOR_REVISION));
	version2 = KvGetNum(BossKV[Specials], "fversion_stable", StringToInt(FORK_STABLE_REVISION));
	if(version>StringToInt(FORK_MINOR_REVISION) || (version2>StringToInt(FORK_STABLE_REVISION) && version==StringToInt(FORK_MINOR_REVISION)))
	{
		LogToFile(eLog, "[Boss] Character %s requires newer version of %s FF2 (at least %s.%i.%i)!", character, FORK_SUB_REVISION, FORK_MAJOR_REVISION, version, version2);
		return;
	}

	for(int i=1; ; i++)
	{
		Format(config, sizeof(config), "ability%i", i);
		if(KvJumpToKey(BossKV[Specials], config))
		{
			static char plugin_name[64];
			KvGetString(BossKV[Specials], "plugin_name", plugin_name, 64);
			BuildPath(Path_SM, config, sizeof(config), "plugins/freaks/%s.ff2", plugin_name);
			if(!FileExists(config))
			{
				LogToFile(eLog, "[Boss] Character %s needs plugin %s!", character, plugin_name);
				return;
			}
			KvRewind(BossKV[Specials]);
		}
		else
		{
			break;
		}
	}


	char key[PLATFORM_MAX_PATH];
	static char section[64];
	KvSetString(BossKV[Specials], "filename", character);
	KvGetString(BossKV[Specials], "name", config, sizeof(config));
	bBlockVoice[Specials] = view_as<bool>(KvGetNum(BossKV[Specials], "sound_block_vo"));
	BossSpeed[Specials] = KvGetFloat(BossKV[Specials], "maxspeed", 340.0);
	KvGotoFirstSubKey(BossKV[Specials]);

	while(KvGotoNextKey(BossKV[Specials]))
	{
		KvGetSectionName(BossKV[Specials], section, sizeof(section));
		if(StrEqual(section, "download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
					break;

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
		else if(StrEqual(section, "mod_download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
					break;

				for(int extension; extension<sizeof(extensions); extension++)
				{
					FormatEx(key, PLATFORM_MAX_PATH, "%s%s", config, extensions[extension]);
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
		else if(StrEqual(section, "mat_download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
				if(!config[0])
					break;

				FormatEx(key, sizeof(key), "%s.vtf", config);
				if(FileExists(key, true))
				{
					AddFileToDownloadsTable(key);
				}
				else
				{
					LogToFile(eLog, "[Boss] Character %s is missing file '%s'!", character, key);
				}

				FormatEx(key, sizeof(key), "%s.vmt", config);
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
	char filePath[PLATFORM_MAX_PATH], key[8];
	static char file[PLATFORM_MAX_PATH], section[16], bossName[64];
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
				FormatEx(key, sizeof(key), "path%d", i);
				KvGetString(BossKV[characterIndex], key, file, sizeof(file));
				if(!file[0])
					break;

				FormatEx(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
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
					break;

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
					FormatEx(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
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

public void LoadSideCharacter(const char[] character, int pack)
{
	static char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s.cfg", ConfigPath, character);
	if(!FileExists(config))
		return;

	PackKV[PackSpecials[pack]][pack] = CreateKeyValues("character");
	FileToKeyValues(PackKV[PackSpecials[pack]][pack], config);
	KvSetString(PackKV[PackSpecials[pack]][pack], "filename", character);

	int version = KvGetNum(PackKV[PackSpecials[pack]][pack], "version", StringToInt(MAJOR_REVISION));
	if(version!=StringToInt(MAJOR_REVISION) && version!=99) // 99 for bosses made ONLY for this fork
		return;

	version = KvGetNum(PackKV[PackSpecials[pack]][pack], "version_minor", StringToInt(MINOR_REVISION));
	if(version > StringToInt(MINOR_REVISION))
		return;

	int version2 = KvGetNum(PackKV[PackSpecials[pack]][pack], "version_stable", StringToInt(STABLE_REVISION));
	if(version2>StringToInt(STABLE_REVISION) && version==StringToInt(MINOR_REVISION))
		return;

	version = KvGetNum(PackKV[PackSpecials[pack]][pack], "fversion", StringToInt(FORK_MAJOR_REVISION));
	if(version != StringToInt(FORK_MAJOR_REVISION))
		return;

	version = KvGetNum(PackKV[PackSpecials[pack]][pack], "fversion_minor", StringToInt(FORK_MINOR_REVISION));
	if(version > StringToInt(FORK_MINOR_REVISION))
		return;

	version2 = KvGetNum(PackKV[PackSpecials[pack]][pack], "fversion_stable", StringToInt(FORK_STABLE_REVISION));
	if(version2>StringToInt(FORK_STABLE_REVISION) && version==StringToInt(FORK_MINOR_REVISION))
		return;

	PackSpecials[pack]++;
}

public void CvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
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
		bossTeleportation = StringToInt(newValue);
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
		CheckDuoMin();
	}
	else if(convar == cvarAnnotations)
	{
		Annotations = StringToInt(newValue);
	}
	else if(convar == cvarTellName)
	{
		TellName = view_as<bool>(StringToInt(newValue));
	}
	else if(convar == cvarChargeAngle)
	{
		ChargeAngle = StringToFloat(newValue);
	}
	else if(convar == cvarAttributes)
	{
		strcopy(Attributes, sizeof(Attributes), newValue);
	}
	else if(convar == cvarStartingUber)
	{
		StartingUber = StringToFloat(newValue);
	}
	else if(convar == cvarHealth)
	{
		strcopy(HealthFormula, sizeof(HealthFormula), newValue);
	}
	else if(convar == cvarRageDamage)
	{
		strcopy(RageDamage, sizeof(RageDamage), newValue);
	}
	else if(convar == cvarDatabase)
	{
		if(StringToInt(newValue))
		{
			if(!EnabledD)
			{
				SetupDatabase();
			}
			else if(EnabledD == 1)
			{
				EnabledD++;
			}
		}
		else if(EnabledD == 2)
		{
			EnabledD = 1;
		}
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
				if(IsFF2Map(currentmap) && !Enabled)
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
	//PrintToConsoleAll("SMAC: Cheat detected!");
	if(type == Detection_CvarViolation)
	{
		//PrintToConsoleAll("SMAC: Cheat was a cvar violation!");
		if((FF2flags[client] & FF2FLAG_CHANGECVAR))
		{
			//PrintToConsoleAll("SMAC: Ignoring violation");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
#endif

public void CW3_OnWeaponSpawned(int weapon, int slot, int client)
{
	if(!IsBoss(client))
		return;

	TF2_RemoveWeaponSlot(client, slot);
	int boss = GetBossIndex(client);
	if(HasEquipped[boss])
		EquipBoss(boss);
}

public Action Timer_Announce(Handle timer)
{
	static int announcecount = -1;
	announcecount++;
	if(Announce>1.0 && Enabled2)
	{
		if(cvarAnnounceAds.BoolValue)
		{
			switch(announcecount)
			{
				case 1:
				{
					FPrintToChatAll("%t", "ff2_last_update", PLUGIN_VERSION, FORK_DATE_REVISION);
				}
				case 2:
				{
					FPrintToChatAll("%t", "ClassicAd");
				}
				case 3:
				{
					if(cvarToggleBoss.BoolValue)	// Toggle Command?
					{
						FPrintToChatAll("%t", "FF2 Toggle Command");
					}
					else	// Guess not, play the 4th thing and next is 5
					{
						announcecount = 5;
						FPrintToChatAll("%t", "DevAd", PLUGIN_VERSION);
					}
				}
				case 4:
				{
					FPrintToChatAll("%t", "DevAd", PLUGIN_VERSION);
				}
				case 5:
				{
					if(cvarDuoBoss.BoolValue)	// Companion Toggle?
					{
						FPrintToChatAll("%t", "FF2 Companion Command");
					}
					else	// Guess not either, play the last thing and next is 0
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
		else
		{
			switch(announcecount)
			{
				case 1:
				{
					if(cvarToggleBoss.BoolValue)	// Toggle Command?
						FPrintToChatAll("%t", "FF2 Toggle Command");
				}
				case 2:
				{
					if(cvarDuoBoss.BoolValue)	// Companion Toggle?
						FPrintToChatAll("%t", "FF2 Companion Command");
				}
				default:
				{
					announcecount = 0;
					FPrintToChatAll("%t", "type_ff2_to_open_menu");
				}
			}
		}
	}
	return Plugin_Continue;
}

stock bool IsFF2Map(const char[] mapName)
{
	if(FileExists("bNextMapToFF2"))
		return true;

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, MapCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapCFG);
		if(!FileExists(config))
		{
			LogToFile(eLog, "[Maps] Unable to find '%s'", MapCFG);
			return true;
		}
	}

	File file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogToFile(eLog, "[Maps] Error reading from '%s'", config);
		return true;
	}

	int tries;
	while(file.ReadLine(config, sizeof(config)))
	{
		tries++;
		if(tries >= 100)
		{
			LogToFile(eLog, "[Maps] An infinite loop occurred while trying to check the map");
			delete file;
			return true;
		}

		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(!StrContains(mapName, config, false) || !StrContains(config, "all", false))
		{
			delete file;
			return true;
		}
	}
	delete file;
	return false;
}

stock bool MapHasMusic(bool forceRecalc=false)  //SAAAAAARGE
{
	static bool hasMusic;
	static bool found;
	if(forceRecalc)
	{
		found = false;
		hasMusic = false;
	}

	if(!found)
	{
		int entity = -1;
		char name[64];
		while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(StrEqual(name, "hale_no_music", false))
			{
				//PrintToConsoleAll("Detected Map Music");
				hasMusic = true;
			}
		}
		found = true;
	}
	return hasMusic;
}

stock void CheckToChangeMapDoors()
{
	if(!Enabled || !Enabled2)
		return;

	char config[PLATFORM_MAX_PATH];
	checkDoors = false;
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, DoorCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, DoorCFG);
		if(!FileExists(config))
		{
			LogToFile(eLog, "[Doors] Unable to find '%s'", DoorCFG);
			return;
		}
	}

	File file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogToFile(eLog, "[Doors] Error reading from '%s'", config);
		return;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(StrContains(currentmap, config, false)!=-1 || !StrContains(config, "all", false))
		{
			delete file;
			checkDoors = true;
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
		if(!FileExists(config))
		{
			LogToFile(eLog, "[TTS] Unable to find '%s'", SpawnTeleportCFG);
			return;
		}
	}

	File file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogToFile(eLog, "[TTS] Error reading from '%s'", SpawnTeleportCFG);
		return;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(StrContains(currentmap, config, false)>=0 || !StrContains(config, "all", false))
		{
			SpawnTeleOnTriggerHurt = true;
			delete file;
			return;
		}
	}
	delete file;

	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, SpawnTeleportBlacklistCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, SpawnTeleportBlacklistCFG);
		if(!FileExists(config))
		{
			LogToFile(eLog, "[TTS] Unable to find '%s'", SpawnTeleportBlacklistCFG);
			return;
		}
	}

	file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogToFile(eLog, "[TTS] Error reading from '%s'", SpawnTeleportBlacklistCFG);
		return;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(StrContains(currentmap, config, false)>=0 || !StrContains(config, "all", false))
		{
			SpawnTeleOnTriggerHurt = false;
			break;
		}
	}
	delete file;
}

public void OnRoundSetup(Event event, const char[] name, bool dontBroadcast)
{
	teamplay_round_start_TeleportToMultiMapSpawn(); // Cache spawns
	isCapping = false;
	SpecialRound = false;
	if(changeGamemode == 1)
	{
		EnableFF2();
	}
	else if(changeGamemode == 2)
	{
		DisableFF2();
	}

	if(!cvarEnabled.BoolValue)
	{
		Enabled2 = false;
		Enabled3 = false;
		if(EnabledDesc && cvarSteamTools.BoolValue)
		{
			#if defined _SteamWorks_Included
			if(steamworks)
			{
				SteamWorks_SetGameDescription("Team Fortress");
				Enabled = false;
				EnabledDesc = false;
				return;
			}
			#endif

			#if defined _steamtools_included
			if(steamtools)
				Steam_SetGameDescription("Team Fortress");
			#endif
		}
		EnabledDesc = false;
	}

	Enabled = Enabled2;
	if(!Enabled)
		return;

	if(FileExists("bNextMapToFF2"))
		DeleteFile("bNextMapToFF2");

	currentBossTeam = GetRandomInt(1, 2);
	switch(cvarForceBossTeam.IntValue)
	{
		case 1:
			blueBoss = view_as<bool>(GetRandomInt(0, 1));

		case 2:
			blueBoss = false;

		default:
			blueBoss = true;
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
				bosses++;

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
		hostName.SetString(oldName);
		Enabled = false;
		DisableSubPlugins();
		SetControlPoint(true);
		return;
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
		return;
	}

	for(int client; client<=MaxClients; client++)
	{
		Boss[client] = 0;
		BossSwitched[client] = false;
		HasEquipped[client] = false;
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

		if(cvarBvBChaos.IntValue > 1)
		{
			int bossCount = 0;
			while(bossCount < (cvarBvBChaos.IntValue-1))
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

	bool teamHasPlayers[2];
	for(int client=1; client<=MaxClients; client++)  //Find out if each team has at least one player on it
	{
		if(IsValidClient(client))
		{
			int team = GetClientTeam(client);
			if(team > view_as<int>(TFTeam_Spectator))
				teamHasPlayers[team-2] = true;

			if(teamHasPlayers[0] && teamHasPlayers[1])
				break;
		}
	}

	if(!teamHasPlayers[0] || !teamHasPlayers[1])  //If there's an empty team make sure it gets populated
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
		return;  //NOTE: This is needed because OnRoundSetup gets fired a second time once both teams have players
	}

	PickCharacter(0, 0);
	if((Special[0]<0) || !BossKV[Special[0]])
	{
		LogToFile(eLog, "[!!!] Couldn't find a boss for index 0!");
		return;
	}

	if(Enabled3)
	{
		PickCharacter(MAXBOSSES, MAXBOSSES);
		if((Special[MAXBOSSES]<0) || !BossKV[Special[MAXBOSSES]])
		{
			LogToFile(eLog, "[!!!] Couldn't find a boss for index %i!", MAXBOSSES);
			return;
		}

		if(cvarBvBChaos.IntValue > 1)
		{
			int bossCount = 0;
			while(bossCount<(cvarBvBChaos.IntValue-1) && bossCount<(playing-1))
			{
				bossCount++;
				PickCharacter(bossCount, bossCount);
				if((Special[bossCount]<0) || !BossKV[Special[bossCount]])
				{
					LogToFile(eLog, "[!!!] Couldn't find a boss for index %i!", bossCount);
					return;
				}

				PickCharacter(MAXBOSSES+bossCount, MAXBOSSES+bossCount);
				if((Special[MAXBOSSES+bossCount]<0) || !BossKV[Special[MAXBOSSES+bossCount]])
				{
					LogToFile(eLog, "[!!!] Couldn't find a boss for index %i!", MAXBOSSES+bossCount);
					return;
				}
			}
		}
	}

	FindCompanion(0, playing, omit);  //Find companions for the boss!
	if(Enabled3)
	{
		FindCompanion(MAXBOSSES, playing, omit);
		if(cvarBvBChaos.IntValue > 1)
		{
			int bossCount = 0;
			while(bossCount<(cvarBvBChaos.IntValue-1) && bossCount<(playing-1))
			{
				bossCount++;
				FindCompanion(bossCount, playing, omit);
				FindCompanion(MAXBOSSES+bossCount, playing, omit);
			}
		}
	}

	for(int boss; boss<=MaxClients; boss++)
	{
		if(Boss[boss])
			CreateTimer(0.3, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
	}

	CreateTimer(0.4, StartIntroMusicTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer((GetConVarFloat(FindConVar("tf_arena_preround_time"))/2.857), StartResponseTimer, _, TIMER_FLAG_NO_MAPCHANGE);

	for(int entity=MaxClients+1; entity<MAXENTITIES; entity++)
	{
		if(!IsValidEntity(entity))
			continue;

		static char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(StrEqual(classname, "func_regenerate"))
		{
			AcceptEntityInput(entity, "Kill");
		}
		else if(StrEqual(classname, "func_respawnroomvisualizer"))
		{
			AcceptEntityInput(entity, "Disable");
		}
	}

	if(cvarToggleBoss.BoolValue)
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
				static char nick[64];
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
					CreateTimer(cvarFF2TogglePrefDelay.FloatValue, BossMenuTimer, GetClientUserId(client));
				}
				continue;
			}

			ClientID[client] = ClientQueue[client][0];
			ClientPoint[client] = ClientQueue[client][1];

			if(ToggleBoss[client] == Setting_On)
			{
				int index = -1;
				for(int i=1; i<MAXTF2PLAYERS; i++)
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
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return;

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
		return;

	int point = MaxClients+1;
	while((point=FindEntityByClassname2(point, "trigger_capture_area")) != -1)
	{
		SDKHook(point, SDKHook_StartTouch, OnCPTouch);
		SDKHook(point, SDKHook_Touch, OnCPTouch);
	}

	playing = 0;
	playing2 = 0;
	playingboss = 0;
	playingmerc = 0;
	bosses = 0;
	int medigun, boss;
	static char command[512];
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
						SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", StartingUber/100.0);
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
				boss = GetBossIndex(client);
				KvRewind(BossKV[Special[boss]]);
				KvGetString(BossKV[Special[boss]], "command", command, sizeof(command));
				if(command[0])
					ServerCommand(command);
			}
		}
	}

	float players = 1.0;
	if(Enabled3)
	{
		players += playingmerc + bosses - playingboss*0.75;
		float players2 = playingboss + 1 + bosses - playingmerc*0.75;
		for(boss=0; boss<=MaxClients; boss++)
		{
			if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
			{
				if(BossSwitched[boss])
				{
					BossHealthMax[boss] = ParseFormula(boss, "health_formula", HealthFormula, RoundFloat(Pow((760.8+players2)*(players2-1.0), 1.0341)+2046.0));
				}
				else
				{
					BossHealthMax[boss] = ParseFormula(boss, "health_formula", HealthFormula, RoundFloat(Pow((760.8+players)*(players-1.0), 1.0341)+2046.0));
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
		for(boss=0; boss<=MaxClients; boss++)
		{
			if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
			{
				BossHealthMax[boss] = ParseFormula(boss, "health_formula", HealthFormula, RoundFloat(Pow((760.8+players)*(players-1.0), 1.0341)+2046.0));
				BossHealth[boss] = BossHealthMax[boss]*BossLivesMax[boss];
				BossHealthLast[boss] = BossHealth[boss];
			}
		}
	}

	if(bosses==1 && kvDiffMods!=null && IsValidClient(Boss[0]) && IsPlayerAlive(Boss[0]))
	{
		if(!IsFakeClient(Boss[0]) && !cvarDifficulty.BoolValue && dIncoming[Boss[0]][0])
		{
			LoadDifficulty(0);
		}
		else if((IsFakeClient(Boss[0]) && !cvarDifficulty.BoolValue && !GetRandomInt(0, 9)) || (GetRandomFloat(0.0, 100.0)<cvarDifficulty.FloatValue && ToggleDiff[Boss[0]]!=Setting_Off  && ToggleDiff[Boss[0]]!=Setting_Temp))
		{
			int count;
			KvRewind(kvDiffMods);
			KvGotoFirstSubKey(kvDiffMods);
			while(KvGotoNextKey(kvDiffMods))
			{
				count++;
			}

			if(count)
			{
				KvRewind(kvDiffMods);
				KvGotoFirstSubKey(kvDiffMods);
				for(count=GetRandomInt(0, count-1); count>0; count--)
				{
					KvGotoNextKey(kvDiffMods);
				}

				KvGetSectionName(kvDiffMods, dIncoming[Boss[0]], sizeof(dIncoming[]));
				LoadDifficulty(0);
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

	if(cvarNameChange.IntValue == 1)
	{
		char newName[256];
		static char bossName[64];
		GetBossSpecial(Special[0], bossName, 64);
		FormatEx(newName, 256, "%s | %s", oldName, bossName);
		hostName.SetString(newName);
	}
}

void LoadDifficulty(int boss)
{
	char plugin[68];
	KvRewind(kvDiffMods);
	KvGotoFirstSubKey(kvDiffMods);
	do
	{
		static char section[64];
		KvGetSectionName(kvDiffMods, section, sizeof(section));
		if(!StrEqual(section, dIncoming[Boss[boss]]))
			continue;

		KvRewind(BossKV[Special[boss]]);
		KvGetString(BossKV[Special[boss]], "filename", plugin, sizeof(plugin));
		if(!KvGetNum(kvDiffMods, plugin, KvGetNum(kvDiffMods, "default", 1)))
			break;

		SpecialRound = true;
		KvGotoFirstSubKey(kvDiffMods);
		do
		{
			static char buffer[PLATFORM_MAX_PATH];
			KvGetSectionName(kvDiffMods, buffer, sizeof(buffer));
			FormatEx(plugin, sizeof(plugin), "%s.ff2", buffer);
			Handle iter = GetPluginIterator();
			Handle pl = INVALID_HANDLE;
			while(MorePlugins(iter))
			{
				pl = ReadPlugin(iter);
				GetPluginFilename(pl, buffer, sizeof(buffer));
				if(StrContains(buffer, plugin, false) == -1)
					continue;

				Function func = GetFunctionByName(pl, "FF2_OnDifficulty");
				if(func == INVALID_FUNCTION)
					break;

				Call_StartFunction(pl, func);
				Call_PushCell(boss);
				Call_PushString(section);
				Call_PushCell(kvDiffMods);
				Call_Finish();
				break;
			}
			delete iter;

			if(kvDiffMods == INVALID_HANDLE)
			{
				LogToFile(eLog, "[Difficulty] %s closed needed Handle for difficulty!", buffer);
				CacheDifficulty();
				return;
			}

		} while(KvGotoNextKey(kvDiffMods));
		break;
	} while(KvGotoNextKey(kvDiffMods));
}

public Action Timer_EnableCap(Handle timer)
{
	if((Enabled || Enabled2) && CheckRoundState()==-1)
	{
		SetControlPoint(true);
		if(checkDoors)
		{
			int ent = -1;
			while((ent=FindEntityByClassname2(ent, "func_door")) != -1)
			{
				AcceptEntityInput(ent, "Open");
				AcceptEntityInput(ent, "Unlock");
			}

			if(doorCheckTimer == INVALID_HANDLE)
			{
				doorCheckTimer = CreateTimer(5.0, Timer_CheckDoors, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action Timer_CheckDoors(Handle timer)
{
	if(!checkDoors)
	{
		doorCheckTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if((!Enabled && CheckRoundState()!=-1) || (Enabled && CheckRoundState()!=1))
		return Plugin_Continue;

	int entity = -1;
	while((entity=FindEntityByClassname2(entity, "func_door")) != -1)
	{
		AcceptEntityInput(entity, "Open");
		AcceptEntityInput(entity, "Unlock");
	}
	return Plugin_Continue;
}

public void CheckArena()
{
	float PointTotal = float(PointTime+PointDelay*(playing-1));
	if(!PointType || PointTotal<0)
	{
		SetArenaCapEnableTime(0.0);
		SetControlPoint(false);
	}
	else
	{
		SetArenaCapEnableTime(PointTotal);
	}
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	RoundCount++;
	SapperMinion = false;
	LastMan = true;
	if(HasSwitched)
		HasSwitched = false;

	CheckDuoMin();
	
	if (_FF2Save)
		_FF2Save.ClearAll();
	
	if(!Enabled)
	{
		Enabled3 = false;
		return;
	}

	int team = event.GetInt("team");
	if(cvarBossLog.IntValue>0 && cvarBossLog.IntValue<=playing2 && !CheatsUsed && !SpecialRound)
	{
		File bossLog = OpenFile(bLog, "a+");
		if(bossLog != INVALID_HANDLE)
		{
			static char bossName[64], FormatedTime[64], Result[64], PlayerName[64], Authid[64];
			int CurrentTime = GetTime();
			int boss;

			FormatTime(FormatedTime, sizeof(FormatedTime), "%X", CurrentTime);
			strcopy(Result, sizeof(Result), team==BossTeam ? "won" : "loss");
			for(int client=1; client<=MaxClients; client++)
			{
				boss = GetBossIndex(client);
				if(boss != -1)
				{
					if(IsFakeClient(client))
					{
						strcopy(PlayerName, sizeof(PlayerName), "Bot");
						strcopy(Authid, sizeof(Authid), "Bot");
					}
					else
					{
						GetClientName(Boss[boss], PlayerName, sizeof(PlayerName));
						GetClientAuthId(Boss[boss], AuthId_Steam2, Authid, sizeof(Authid), false);
					}
					KvRewind(BossKV[Special[boss]]);
					KvGetString(BossKV[Special[boss]], "filename", bossName, sizeof(bossName));
					BuildPath(Path_SM, bLog, sizeof(bLog), "%s/%s.txt", BossLogPath, bossName);
				}
			}

			bossLog.WriteLine("%s on %s - %s <%s> has %s", FormatedTime, currentmap, PlayerName, Authid, Result);
			bossLog.WriteLine("");
			delete bossLog;
		}
	}

	executed = false;
	executed2 = false;
	int bossWin = 0;
	float bonusRoundTime = GetConVarFloat(FindConVar("mp_bonusroundtime"))-0.5;
	static char sound[PLATFORM_MAX_PATH];
	if(team == BossTeam)
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
	else if(team == OtherTeam)
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
		if(RandomSound("sound_stalemate", sound, sizeof(sound)))
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
		int target;
		char[][] text = new char[MaxClients+1][128];
		bool multi;
		static char bossName[64];
		for(int boss; boss<=MaxClients; boss++)
		{
			target = Boss[boss];
			if(IsValidClient(target))
			{
				if(GetClientTeam(target) == team)
				{
					char lives[8];
					if(BossLives[boss] > 1)
						FormatEx(lives, sizeof(lives), "x%i", BossLives[boss]);

					for(int client=1; client<=MaxClients; client++)
					{
						if(IsValidClient(client))
						{
							GetBossSpecial(Special[boss], bossName, sizeof(bossName), client);
							Format(text[client], 128, "%s\n%t", multi ? text[client] : "", "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
							FPrintToChat(client, "%t", "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
						}
					}
					multi = true;
				}
			}
		}

		if(team == view_as<int>(TFTeam_Red))
		{
			SetHudTextParams(-1.0, 0.25, bonusRoundTime, 255, 50, 50, 255);
		}
		else
		{
			SetHudTextParams(-1.0, 0.25, bonusRoundTime, 50, 50, 255, 255);
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !HudSettings[client][2] && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(GetClientButtons(client) & IN_SCORE))
				ShowHudText(client, -1, text[client]);
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

			for(int slot=1; slot<4; slot++)
			{
				BossCharge[client][slot] = 0.0;
			}
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
			SapperCooldown[client] = cvarSapperStart.FloatValue;
			SaveClientStats(client);
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

	bool gainedPoint[MAXTF2PLAYERS];
	int statPlayers = cvarStatPlayers.IntValue;
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
				else if(!bossWin)
				{
					AddClientStats(boss, Cookie_BossLosses, 1);
					gainedPoint[boss] = true;
				}
			}
		}
	}

	int StatWin2Lose = cvarStatWin2Lose.IntValue;
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
		char[][] text = new char[MaxClients+1][128];
		bool multi;
		static char bossName[64];
		for(int boss; boss<=MaxClients; boss++)
		{
			target = Boss[boss];
			if(IsValidClient(target))
			{
				char lives[8];
				if(BossLives[boss] > 1)
					FormatEx(lives, sizeof(lives), "x%i", BossLives[boss]);

				for(int client=1; client<=MaxClients; client++)
				{
					if(IsValidClient(client))
					{
						GetBossSpecial(Special[boss], bossName, sizeof(bossName), client);
						Format(text[client], 128, "%s\n%t", multi ? text[client] : "", "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
						FPrintToChat(client, "%t", "ff2_alive", bossName, target, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
						if(SpecialRound)
							Format(text[client], 128, "%s\n(%s)", text[client], dIncoming[target]);
					}
				}
				multi = true;
			}
		}

		SetHudTextParams(-1.0, 0.25, bonusRoundTime, 255, 255, 255, 255);
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !HudSettings[client][2] && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(GetClientButtons(client) & IN_SCORE))
				ShowHudText(client, -1, text[client]);
		}

		if(!bossWin && RandomSound("sound_fail", sound, sizeof(sound)))
			EmitSoundToAllExcept(sound);
	}

	int top[3];
	Damage[0] = 0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || Damage[client]<1 || IsBoss(client))
			continue;

		if(Damage[client] >= Damage[top[0]])
		{
			top[2] = top[1];
			top[1] = top[0];
			top[0] = client;
		}
		else if(Damage[client] >= Damage[top[1]])
		{
			top[2] = top[1];
			top[1] = client;
		}
		else if(Damage[client] >= Damage[top[2]])
		{
			top[2] = client;
		}
	}

	if(!TimesTen && Damage[top[0]]>9000)
		CreateTimer(1.0, Timer_NineThousand, _, TIMER_FLAG_NO_MAPCHANGE);

	if(!botBoss && statPlayers>0)
	{
		if(statPlayers <= playing2)
			AddClientStats(top[0], Cookie_PlayerMvps, 1);

		if(statPlayers*2 <= playing2)
			AddClientStats(top[1], Cookie_PlayerMvps, 1);

		if(statPlayers*3 <= playing2)
			AddClientStats(top[2], Cookie_PlayerMvps, 1);
	}

	static char leaders[3][32];
	for(int i; i<=2; i++)
	{
		if(IsValidClient(top[i]))
		{
			GetClientName(top[i], leaders[i], 32);
		}
		else
		{
			strcopy(leaders[i], 32, "---");
			top[i] = 0;
		}
	}

	SetHudTextParams(-1.0, 0.35, bonusRoundTime, 255, 255, 255, 255);
	PrintCenterTextAll("");

	static char text[128];
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
			continue;

		SetGlobalTransTarget(client);
		if(IsBoss(client) && GetClientTeam(client)==team)
		{
			ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "boss_win");
		}
		else if(IsBoss(client))
		{
			ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "boss_lose");
		}
		else
		{
			ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "damage_fx", Damage[client], "scores", RoundFloat(Damage[client]/PointsInterval2));
		}
	}

	if(cvarBossVsBoss.IntValue > 0)
	{
		if(GetRandomInt(0, 99) < cvarBossVsBoss.IntValue)
		{
			CreateTimer(bonusRoundTime-0.1, Timer_SetEnabled3, true, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			CreateTimer(bonusRoundTime-0.1, Timer_SetEnabled3, false, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		Enabled3 = false;
	}

	if(ReloadFF2)
	{
		ServerCommand("sm plugins reload freak_fortress_2");
		return;
	}

	if(ReloadConfigs)
	{
		CacheWeapons();
		CacheDifficulty();
		CheckToChangeMapDoors();
		CheckToTeleportToSpawn();
		FindCharacters();
		FF2CharSetString[0] = 0;
		ReloadConfigs = false;
		LoadCharset = false;
		ReloadWeapons = false;
	}

	if(LoadCharset)
	{
		FindCharacters();
		FF2CharSetString[0] = 0;
		LoadCharset = false;
	}

	if(ReloadWeapons)
	{
		CacheWeapons();
		ReloadWeapons = false;
	}

	CreateTimer(3.0, Timer_CalcQueuePoints, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
}

public Action Timer_SetEnabled3(Handle timer, bool toggle)
{
	Enabled3 = toggle;
	if(Enabled3)
	{
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);

		int reds, blus;
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client))
				continue;

			if(GetClientTeam(client) == OtherTeam)
			{
				reds++;
			}
			else if(GetClientTeam(client) == BossTeam)
			{
				blus++;
			}
		}

		int team;
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client))
				continue;

			if(IsPlayerAlive(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
				continue;

			if(reds>blus || (reds==blus && GetRandomInt(0, 1))) // More reds or their equal with 50/50 chance
			{
				team = BossTeam;
				reds--;
				blus++;
			}
			else
			{
				team = OtherTeam;
				reds++;
				blus--;
			}

			ChangeClientTeam(client, team);
		}
	}
	else
	{
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), mp_teams_unbalance_limit);
	}
	return Plugin_Continue;
}

public Action OnWinPanel(Event event, const char[] name, bool dontBroadcast)
{
	return Enabled ? Plugin_Handled : Plugin_Continue;
}

public Action BossMenuTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(client);
	if(IsValidClient(client) && ToggleBoss[client]!=Setting_On && ToggleBoss[client]!=Setting_Off)
		BossMenu(client, 0);

	return Plugin_Continue;
}

public Action CompanionMenu(int client, int args)
{
	if(IsValidClient(client) && cvarDuoBoss.BoolValue)
	{
		Menu menu = new Menu(MenuHandlerCompanion);
		SetGlobalTransTarget(client);
		menu.SetTitle("%t", "FF2 Companion Toggle Menu Title");

		char menuoption[128];
		FormatEx(menuoption, sizeof(menuoption), "%t", "Enable Companion Selection");
		menu.AddItem("FF2 Companion Toggle Menu", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Companion Selection");
		menu.AddItem("FF2 Companion Toggle Menu", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Companion Selection For Map");
		if(Enabled2)
		{
			menu.AddItem("FF2 Companion Toggle Menu", menuoption);
		}
		else
		{
			menu.AddItem("FF2 Companion Toggle Menu", menuoption, ITEMDRAW_DISABLED);
		}

		menu.ExitButton = true;
		menu.Display(client, 20);
	}
	return Plugin_Handled;
}

public int MenuHandlerCompanion(Menu menu, MenuAction action, int param1, int param2)
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
		delete menu;
	}
}

public Action BossMenu(int client, int args)
{
	if(IsValidClient(client) && cvarToggleBoss.BoolValue)
	{
		Menu menu = new Menu(MenuHandlerBoss);
		SetGlobalTransTarget(client);
		menu.SetTitle("%t", "FF2 Toggle Menu Title");

		char menuoption[128];
		FormatEx(menuoption, sizeof(menuoption), "%t", "Enable Queue Points");
		menu.AddItem("Boss Toggle", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Queue Points");
		menu.AddItem("Boss Toggle", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Queue Points For This Map");
		if(Enabled2)
		{
			menu.AddItem("Boss Toggle", menuoption);
		}
		else
		{
			menu.AddItem("Boss Toggle", menuoption, ITEMDRAW_DISABLED);
		}

		menu.ExitButton = true;
		menu.Display(client, 20);
	}
	return Plugin_Handled;
}

public int MenuHandlerBoss(Menu menu, MenuAction action, int param1, int param2)
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
		delete menu;
	}
}

public Action Command_HudMenu(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	Menu menu = new Menu(Command_HudMenuH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "FF2 Hud Menu Title");

	char menuOption[64];
	for(int i; i<(HUDTYPES-1); i++)
	{
		FormatEx(menuOption, sizeof(menuOption), "%t [%t]", HudTypes[i], HudSettings[client][i] ? "Off" : "On");
		menu.AddItem(menuOption, menuOption);
	}

	int value = HudSettings[client][HUDTYPES-1] ? HudSettings[client][HUDTYPES-1] : cvarDamageHud.IntValue;
	FormatEx(menuOption, sizeof(menuOption), "%t [%i]", HudTypes[HUDTYPES-1], value<3 ? 0 : value);
	menu.AddItem(menuOption, menuOption);

	menu.ExitButton = true;
	menu.Display(client, 20);
	return Plugin_Handled;
}

public int Command_HudMenuH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(param2 == HUDTYPES-1)
			{
				if(++HudSettings[param1][param2] < 3)
					HudSettings[param1][param2] = 3;

				if(HudSettings[param1][param2] > 9)
					HudSettings[param1][param2] = 1;
			}
			else
			{
				HudSettings[param1][param2] = HudSettings[param1][param2] ? 0 : 1;
			}
			Command_HudMenu(param1, 0);
		}
	}
}

public Action SkipBossPanel(int client)
{
	if(!Enabled2)
		return Plugin_Continue;

	Menu menu = new Menu(SkipBossPanelH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "to0_resetpts");

	char text[128];
	FormatEx(text, sizeof(text), "%t", "Yes");
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "No");
	menu.AddItem(text, text);
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int SkipBossPanelH(Menu menu, MenuAction action, int client, int position)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!position)
			{
				if(shortname[client] == client)
					FPrintToChat(client, "%t", "to0_resetpts");

				if(QueuePoints[client] >= 10)
					QueuePoints[client] -= 10;
			}
		}
	}
}

public Action DiffMenu(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(cvarDifficulty.BoolValue)
	{
		Menu menu = new Menu(MenuHandlerDifficulty);
		SetGlobalTransTarget(client);
		menu.SetTitle("%t", "FF2 Special Menu Title");

		char menuoption[128];
		FormatEx(menuoption, sizeof(menuoption), "%t", "Enable Special");
		menu.AddItem("FF2 Special Toggle Menu", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Special");
		menu.AddItem("FF2 Special Toggle Menu", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Special For This Map");
		if(Enabled2 && kvDiffMods!=null)
		{
			menu.AddItem("FF2 Special Toggle Menu", menuoption);
		}
		else
		{
			menu.AddItem("FF2 Special Toggle Menu", menuoption, ITEMDRAW_DISABLED);
		}

		menu.ExitButton = true;
		menu.Display(client, 20);
		return Plugin_Handled;
	}

	if(kvDiffMods == null)
		return Plugin_Handled;

	if(!CheckCommandAccess(client, "ff2_difficulty", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}

	bool denyAll = (!cvarBossDesc.BoolValue || !ToggleInfo[client]) && (IsBoss(client) && CheckRoundState()!=2);

	char name[64];
	Menu menu = new Menu(DiffMenuH);
	SetGlobalTransTarget(client);

	menu.SetTitle("%t\n %t", "FF2 Difficulty Settings Menu Title", "ff2_boss_selection_diff", dIncoming[client][0] ? dIncoming[client] : "-");

	FormatEx(name, sizeof(name), "%t", "Off");
	menu.AddItem("", name, (!dIncoming[client][0] || denyAll || (IsBoss(client) && CheckRoundState()!=2)) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	KvRewind(kvDiffMods);
	KvGotoFirstSubKey(kvDiffMods);
	do
	{
		KvGetSectionName(kvDiffMods, name, sizeof(name));
		menu.AddItem(name, name, denyAll ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	} while(KvGotoNextKey(kvDiffMods));

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandlerDifficulty(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			int choice = param2 + 1;
			ToggleDiff[param1] = view_as<SettingPrefs>(choice);

			switch(choice)
			{
				case 1:
					FPrintToChat(param1, "%t", "FF2 Special Enabled");
				case 2:
					FPrintToChat(param1, "%t", "FF2 Special Disabled");
				case 3:
					FPrintToChat(param1, "%t", "FF2 Special Disabled For Map");
			}
			
		}
	}
}

public int DiffMenuH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!param2)
			{
				dIncoming[param1][0] = 0;
				SaveKeepBossCookie(param1);
				ToggleDiff[param1] = Setting_Off;
				Command_SetMyBoss(param1, 0);
				return;
			}

			if(!cvarBossDesc.BoolValue)
			{
				if(IsBoss(param1) && CheckRoundState()!=2)
				{
					FReplyToCommand(param1, "%t", "ff2_changedifficulty_denied");
					DiffMenu(param1, 0);
					return;
				}

				menu.GetItem(param2, dIncoming[param1], sizeof(dIncoming[]));
				SaveKeepBossCookie(param1);
				ToggleDiff[param1] = Setting_On;
				Command_SetMyBoss(param1, 0);
				return;
			}

			menu.GetItem(param2, cIncoming[param1], sizeof(cIncoming[]));
			ConfirmDiff(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Command_SetMyBoss(param1, 0);
		}
	}
}

public Action ConfirmDiff(int client)
{
	char text[512];
	static char language[20], name[64];
	GetLanguageInfo(GetClientLanguage(client), language, sizeof(language), text, sizeof(text));
	Format(language, sizeof(language), "description_%s", language);
	SetGlobalTransTarget(client);

	KvRewind(kvDiffMods);
	KvGotoFirstSubKey(kvDiffMods);
	do
	{
		KvGetSectionName(kvDiffMods, name, sizeof(name));
		if(StrEqual(name, cIncoming[client], false))
		{
			KvGetString(kvDiffMods, language, text, sizeof(text));
			if(!text[0])
			{
				KvGetString(kvDiffMods, "description_en", text, sizeof(text));  //Default to English if their language isn't available
				if(!text[0])
					FormatEx(text, sizeof(text), "%t", "to0_nodesc");
			}
			ReplaceString(text, sizeof(text), "\\n", "\n");
			break;
		}
	} while(KvGotoNextKey(kvDiffMods));

	Menu menu = new Menu(ConfirmDiffH);
	menu.SetTitle(text);

	FormatEx(text, sizeof(text), "%t", "to0_confirm", name);
	menu.AddItem(name, text, (IsBoss(client) && CheckRoundState()!=2) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	FormatEx(text, sizeof(text), "%t", "to0_cancel");
	menu.AddItem(text, text);

	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int ConfirmDiffH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(param2)
			{
				DiffMenu(param1, 0);
			}
			else if(IsBoss(param1) && CheckRoundState()!=2)
			{
				FReplyToCommand(param1, "%t", "ff2_changedifficulty_denied");
				DiffMenu(param1, 0);
			}
			else
			{
				strcopy(dIncoming[param1], sizeof(dIncoming[]), cIncoming[param1]);
				SaveKeepBossCookie(param1);
				ToggleDiff[param1] = Setting_On;
				Command_SetMyBoss(param1, 0);
			}
		}
	}
}

public int SortQueueDesc(const x[], const y[], const array[][], Handle data)
{
	if(x[1] > y[1])
	{
		return -1;
	}
	else if(x[1] < y[1])
	{
		return 1;
	}
	return 0;
}

public Action OnBroadcast(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || cvarBroadcast.BoolValue)
		return Plugin_Continue;

	static char sound[PLATFORM_MAX_PATH];
	event.GetString("sound", sound, sizeof(sound));
	if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false) || !StrContains(sound, "Announcer.AM_RoundStartRandom", false))
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action Timer_NineThousand(Handle timer)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && ToggleVoice[client])
			ClientCommand(client, "playgamesound \"saxton_hale/9000.wav\"");
	}
	return Plugin_Continue;
}

public Action Timer_CalcQueuePoints(Handle timer)
{
	int damage, damage2;
	int[] add_points = new int[MaxClients+1];
	int[] add_points2 = new int[MaxClients+1];
	for(int client=1; client<=MaxClients; client++)
	{
		if(view_as<int>(ToggleBoss[client])>1 && cvarToggleBoss.BoolValue)	// Do not give queue points to those who have ff2 bosses disabled
			continue;

		if(IsValidClient(client))
		{
			damage = Damage[client];
			damage2 = Damage[client];
			Event event = CreateEvent("player_escort_score", true);
			event.SetInt("player", client);

			int points;
			while(damage-PointsInterval > 0)
			{
				damage -= PointsInterval;
				points++;
			}
			event.SetInt("points", points);
			event.Fire();

			if(IsBoss(client))
			{
				if(((!GetBossIndex(client) || GetBossIndex(client)==MAXBOSSES) && cvarDuoRestore.BoolValue) || !cvarDuoRestore.BoolValue)
				{
					add_points[client] = -QueuePoints[client];
					add_points2[client] = add_points[client];
				}
			}
			else if(GetClientTeam(client)>view_as<int>(TFTeam_Spectator) || SpecForceBoss)
			{
				if(damage2 >= PointsDamage)
				{
					if(PointsExtra > PointsMin)
					{
						if(points > (PointsExtra-PointsMin))
						{
							add_points[client] = PointsExtra;
							add_points2[client] = PointsExtra;
						}
						else
						{
							add_points[client] = PointsMin+points;
							add_points2[client] = PointsMin+points;
						}
					}
					else
					{
						add_points[client] = PointsMin;
						add_points2[client] = PointsMin;
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
				if(!IsValidClient(client))
					continue;

				if(IsFakeClient(client))
					add_points2[client] /= 2;

				if(add_points2[client] > 0)
					FPrintToChat(client, "%t", "add_points", add_points2[client]);

				QueuePoints[client] += add_points2[client];
			}
		}
		default:
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(!IsValidClient(client))
					continue;

				if(IsFakeClient(client))
					add_points[client] /= 2;

				if(add_points[client] > 0)
					FPrintToChat(client, "%t", "add_points", add_points[client]);

				QueuePoints[client] += add_points[client];
			}
		}
	}
}

public Action StartResponseTimer(Handle timer)
{
	static char sound[PLATFORM_MAX_PATH];
	if(Enabled3)
	{
		static char sound2[PLATFORM_MAX_PATH];
		bool isIntro = RandomSound("sound_begin", sound, sizeof(sound));
		bool isIntro2 = RandomSound("sound_begin", sound2, sizeof(sound2), MAXBOSSES);
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client) || !ToggleVoice[client])
				continue;

			if(GetClientTeam(client)==BossTeam && isIntro2)
			{
				EmitSoundToClient(client, sound2);
			}
			else if(isIntro)
			{
				EmitSoundToClient(client, sound);
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
	static char sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_intromusic", sound, sizeof(sound)))
		EmitMusicToAllExcept(sound);

	return Plugin_Continue;
}

public Action Timer_PrepareBGM(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(!Enabled || CheckRoundState()!=1 || !client || MapHasMusic() || StrEqual(currentBGM[client], "ff2_stop_music", true))
	{
		delete MusicTimer[client];
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
			FormatEx(music, 10, "time%i", index);
		}
		while(KvGetFloat(BossKV[Special[0]], music)>1);

		char lives[256];
		int topIndex = index;
		for(int i; i<19; i++)
		{
			index = GetRandomInt(1, topIndex-1);
			FormatEx(lives, sizeof(lives), "life%i", index);
			KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
			if(StringToInt(lives))
			{
				if(StringToInt(lives) != BossLives[0])
					continue;
			}
			break;
		}
		FormatEx(music, 10, "time%i", index);
		float time = KvGetFloat(BossKV[Special[0]], music);
		FormatEx(music, 10, "path%i", index);
		KvGetString(BossKV[Special[0]], music, music, sizeof(music));

		cursongId[client]=index;

		// manual song ID
		char id3[4][256];
		FormatEx(id3[0], sizeof(id3[]), "name%i", index);
		KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
		FormatEx(id3[1], sizeof(id3[]), "artist%i", index);
		KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));

		char temp[PLATFORM_MAX_PATH];
		FormatEx(temp, sizeof(temp), "sound/%s", music);
		if(FileExists(temp, true))
		{
			PlayBGM(client, music, time, id3[2], id3[3]);
		}
		else
		{
			char bossName[64];
			KvRewind(BossKV[Special[0]]);
			KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
			LogToFile(eLog, "[Boss] Character %s is missing BGM file '%s'!", bossName, temp);
			//PrintToConsoleAll("{red}MALFUNCTION! NEED INPUT!");
			if(MusicTimer[client] != null) {
				delete MusicTimer[client];
			}
		}
	}
}

void PlayBGM(int client, char[] music, float time, char[] name="", char[] artist="")
{
	Action action;
	Call_StartForward(OnMusic2);
	char temp[3][PLATFORM_MAX_PATH];
	float time2 = time;
	strcopy(temp[0], sizeof(temp[]), music);
	strcopy(temp[1], sizeof(temp[]), name);
	strcopy(temp[2], sizeof(temp[]), artist);
	Call_PushStringEx(temp[0], sizeof(temp[]), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushFloatRef(time2);
	Call_PushStringEx(temp[1], sizeof(temp[]), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(temp[2], sizeof(temp[]), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(action);
	switch(action)
	{
		case Plugin_Stop, Plugin_Handled:
		{
			//PrintToConsoleAll("NEED BIGGER INPUT!");
			return;
		}
		case Plugin_Changed:
		{
			strcopy(music, PLATFORM_MAX_PATH, temp[0]);
			strcopy(name, PLATFORM_MAX_PATH, temp[1]);
			strcopy(artist, PLATFORM_MAX_PATH, temp[2]);
			time = time2;
			//PrintToConsoleAll("OOO... BIGGER INPUT! %s | %f | %s | %s", music, time, name, artist);
		}
		default:
		{
			Action action2;
			Call_StartForward(OnMusic);
			time2 = time;
			strcopy(temp[0], sizeof(temp[]), music);
			Call_PushStringEx(temp[0], sizeof(temp[]), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushFloatRef(time2);
			Call_Finish(action2);
			switch(action2)
			{
				case Plugin_Stop, Plugin_Handled:
				{
					//PrintToConsoleAll("NEED INPUT!");
					return;
				}
				case Plugin_Changed:
				{
					strcopy(music, PLATFORM_MAX_PATH, temp[0]);
					time=time2;
					//PrintToConsoleAll("OOO... INPUT! %s | %f", music, time);
				}
			}
		}
	}

	FormatEx(temp[0], sizeof(temp[]), "sound/%s", music);
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
			if(time > 1)
				MusicTimer[client] = CreateTimer(time, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}

		if(!name[0])
		{
			FormatEx(name, 256, "%T", "unknown_song", client);
			unknown1 = false;
		}

		if(!artist[0])
		{
			FormatEx(artist, 256, "%T", "unknown_artist", client);
			unknown2 = false;
		}

		if(cvarSongInfo.IntValue==1 || ((unknown1 || unknown2) && !cvarSongInfo.IntValue))
		{
			FPrintToChat(client, "%t", "track_info", artist, name);
		}
	}
	else
	{
		char bossName[64];
		KvRewind(BossKV[Special[0]]);
		KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
		LogToFile(eLog, "[Boss] Character %s is missing BGM file '%s'!", bossName, music);
	}
}

void StartMusic(int client=0)
{
	if(!Enabled)
		return;

	if(client < 1)  //Start music for all clients
	{
		StopMusic();
		for(int target; target<=MaxClients; target++)
		{
			playBGM[target] = true;  //This includes the 0th index
			if(IsValidClient(target))
			{
				CreateTimer(0.2, Timer_PrepareBGM, GetClientUserId(target), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	else
	{
		StopMusic(client);
		playBGM[client] = true;
		CreateTimer(0.1, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

void StopMusic(int client=0, bool permanent=false)
{
	if(client < 1)  //Stop music for all clients
	{
		if(permanent)
			playBGM[0] = false;

		for(client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				StopSound(client, SNDCHAN_AUTO, currentBGM[client]);
				if(MusicTimer[client] != null)
				{
					//PrintToConsoleAll("TERMINATING INPUT!");
					delete MusicTimer[client];
				}
			}

			//strcopy(currentBGM[client], PLATFORM_MAX_PATH, "");
			if(permanent)
				playBGM[client]=false;
		}
	}
	else
	{
		StopSound(client, SNDCHAN_AUTO, currentBGM[client]);
		StopSound(client, SNDCHAN_AUTO, currentBGM[client]);

		if(MusicTimer[client] != null)
		{
			//PrintToConsoleAll("END INPUT FOR %N!", client);
			delete MusicTimer[client];
		}

		strcopy(currentBGM[client], PLATFORM_MAX_PATH, "");
		if(permanent)
			playBGM[client] = false;
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
				clients[total++] = client;
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

void SetupDatabase()
{
	char query[256];
	StatDatabase = SQL_Connect(DATATABLE, true, query, sizeof(query));
	if(StatDatabase == INVALID_HANDLE)
	{
		LogToFile(eLog, "[Database] %s", query);
		EnabledD = 0;
		return;
	}

	FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (steamid INT, win INT, lose INT, kill INT, death INT, slain INT, mvp INT)", DATATABLE);
	SQL_LockDatabase(StatDatabase);
	if(!SQL_FastQuery(StatDatabase, query))
	{
		SQL_GetError(StatDatabase, query, sizeof(query));
		LogToFile(eLog, "[Database] %s", query);
		SQL_UnlockDatabase(StatDatabase);
		EnabledD = 0;
		return;
	}
	SQL_UnlockDatabase(StatDatabase);
	EnabledD = 2;
}

void SetupClientCookies(int client)
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
		ToggleDiff[client] = Setting_On;

		BossWins[client] = 0;
		BossLosses[client] = 0;
		BossKills[client] = 0;
		BossKillsF[client] = 0;
		BossDeaths[client] = 0;
		PlayerKills[client] = 0;
		PlayerMVPs[client] =  0;

		for(int i=0; i<(HUDTYPES-1); i++)
		{
			HudSettings[client][i] = 1;
		}
		HudSettings[client][HUDTYPES-1] = 0;
		return;
	}

	if(AreClientCookiesCached(client))
	{
		static char cookies[454];
		char cookieValues[MAXCHARSETS][64];
		GetClientCookie(client, FF2Cookies, cookies, 48);
		ExplodeString(cookies, " ", cookieValues, MAXCHARSETS, 6);

		QueuePoints[client] = StringToInt(cookieValues[0][0]);
		ToggleMusic[client] = view_as<bool>(StringToInt(cookieValues[1][0]));
		ToggleVoice[client] = view_as<bool>(StringToInt(cookieValues[2][0]));
		ToggleInfo[client] = view_as<bool>(StringToInt(cookieValues[3][0]));
		ToggleDuo[client] = view_as<SettingPrefs>(StringToInt(cookieValues[4][0]));
		ToggleBoss[client] = view_as<SettingPrefs>(StringToInt(cookieValues[5][0]));
		ToggleDiff[client] = view_as<SettingPrefs>(StringToInt(cookieValues[6][0]));

		if(ToggleDuo[client] == Setting_Temp)
			ToggleDuo[client] = Setting_On;

		if(ToggleBoss[client] == Setting_Temp)
			ToggleBoss[client] = Setting_Undef;

		if(ToggleDiff[client] == Setting_Temp)
			ToggleDiff[client] = Setting_On;

		if(cvarDatabase.IntValue < 2)
		{
			GetClientCookie(client, StatCookies, cookies, 48);
			ExplodeString(cookies, " ", cookieValues, MAXCHARSETS, 6);

			BossWins[client] = StringToInt(cookieValues[0][0]);
			BossLosses[client] = StringToInt(cookieValues[1][0]);
			BossKills[client] = StringToInt(cookieValues[2][0]);
			BossKillsF[client] = StringToInt(cookieValues[2][0]);
			BossDeaths[client] = StringToInt(cookieValues[3][0]);
			PlayerKills[client] = StringToInt(cookieValues[4][0]);
			PlayerMVPs[client] =  StringToInt(cookieValues[5][0]);
		}

		GetClientCookie(client, HudCookies, cookies, 48);
		ExplodeString(cookies, " ", cookieValues, MAXCHARSETS, 6);
		for(int i=0; i<HUDTYPES; i++)
		{
			HudSettings[client][i] = StringToInt(cookieValues[i]);
		}

		GetClientCookie(client, SelectionCookie, cookies, sizeof(cookies));
		ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
		strcopy(xIncoming[client], sizeof(xIncoming[]), cookieValues[CurrentCharSet]);
		CheckValidBoss(client, xIncoming[client], !DuoMin);

		GetClientCookie(client, DiffCookie, dIncoming[client], sizeof(dIncoming[]));
	}
	else
	{
		QueuePoints[client] = 0;
		ToggleMusic[client] = true;
		ToggleVoice[client] = true;
		ToggleInfo[client] = true;
		ToggleDuo[client] = Setting_Undef;
		ToggleBoss[client] = Setting_Undef;
		ToggleDiff[client] = Setting_Undef;

		BossWins[client] = 0;
		BossLosses[client] = 0;
		BossKills[client] = 0;
		BossKillsF[client] = 0;
		BossDeaths[client] = 0;
		PlayerKills[client] = 0;
		PlayerMVPs[client] =  0;

		for(int i=0; i<(HUDTYPES-1); i++)
		{
			HudSettings[client][i] = 0;
		}
		HudSettings[client][HUDTYPES-1] = 1;
	}

	if(EnabledD != 2)
		return;

	int steamid = GetSteamAccountID(client);
	if(!steamid)
		return;

	static char query[256];
	FormatEx(query, sizeof(query), "SELECT win, lose, kill, death, slain, mvp FROM %s WHERE steamid=%d;", DATATABLE, steamid);

	SQL_LockDatabase(StatDatabase);
	DBResultSet result;
	if((result = SQL_Query(StatDatabase, query)) == null)
	{
		SQL_UnlockDatabase(StatDatabase);
		return;
	}

	SQL_FetchRow(result);

	int stat[6];
	for(int i; i<6; i++)
	{
		stat[i] = SQL_FetchInt(result, i);
	}

	delete result;
	SQL_UnlockDatabase(StatDatabase);

	if(stat[0] > BossWins[client])
		BossWins[client] = stat[0];

	if(stat[1] > BossLosses[client])
		BossLosses[client] = stat[1];

	if(stat[2] > BossKills[client])
	{
		BossKills[client] = stat[2];
		BossKillsF[client] = stat[2];
	}

	if(stat[3] > BossDeaths[client])
		BossDeaths[client] = stat[3];

	if(stat[4] > PlayerKills[client])
		PlayerKills[client] = stat[4];

	if(stat[5] > PlayerKills[client])
		PlayerKills[client] = stat[5];
}

void SaveClientPreferences(int client)
{
	if(!IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client))
		return;

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2Cookies, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);

	FormatEx(cookies, sizeof(cookies), "%i %i %i %i %i %i %i 3", QueuePoints[client], ToggleMusic[client] ? 1 : 0, ToggleVoice[client] ? 1 : 0, ToggleInfo[client] ? 1 : 0, view_as<int>(ToggleDuo[client]), view_as<int>(ToggleBoss[client]), view_as<int>(ToggleDiff[client]));
	SetClientCookie(client, FF2Cookies, cookies);

	IntToString(HudSettings[client][0], cookies, sizeof(cookies));
	for(int i=1; i<HUDTYPES; i++)
	{
		Format(cookies, sizeof(cookies), "%s %i", cookies, HudSettings[client][i]);
	}
	SetClientCookie(client, HudCookies, cookies);
}

void SaveClientStats(int client)
{
	if(SpecialRound || !IsValidClient(client) || IsFakeClient(client) || cvarStatPlayers.IntValue<1 || (!cvarBvBStat.BoolValue && Enabled3))
		return;

	if(cvarStatWin2Lose.IntValue > 2)
	{
		if(CheatsUsed)
		{
			PrintToConsole(client, "%t", "Cheats Used");
			return;
		}

		if(cvarStatPlayers.IntValue > playing2)
		{
			PrintToConsole(client, "%t", "Low Players");
			return;
		}
	}
	else if(cvarStatWin2Lose.IntValue>0 || cvarStatHud.IntValue>0)
	{
		if(CheatsUsed)
		{
			FPrintToChat(client, "%t", "Cheats Used");
			return;
		}

		if(cvarStatPlayers.IntValue > playing2)
		{
			FPrintToChat(client, "%t", "Low Players");
			return;
		}
	}
	else
	{
		if(CheatsUsed || cvarStatPlayers.IntValue>playing2)
			return;
	}

	if(AreClientCookiesCached(client) && cvarDatabase.IntValue<2)
	{
		char cookies[48];
		FormatEx(cookies, sizeof(cookies), "%i %i %i %i %i %i 0 0", BossWins[client], BossLosses[client], BossKills[client], BossDeaths[client], PlayerKills[client], PlayerMVPs[client]);
		SetClientCookie(client, StatCookies, cookies);
	}

	if(EnabledD != 2)
		return;

	int steamid = GetSteamAccountID(client);
	if(!steamid)
		return;

	char query[256];
	FormatEx(query, sizeof(query), "UPDATE %s SET win=%d, lose=%d, kill=%d, death=%d, slain=%d, mvp=%d WHERE steamid=%d);", DATATABLE, BossWins[client], BossLosses[client], BossKills[client], BossDeaths[client], PlayerKills[client], PlayerMVPs[client], steamid);

	SQL_LockDatabase(StatDatabase);
	if(!SQL_FastQuery(StatDatabase, query))
	{
		SQL_GetError(StatDatabase, query, sizeof(query));
		LogToFile(eLog, "[Database] %s", query);
	}
	SQL_UnlockDatabase(StatDatabase);
}

void AddClientStats(int client, CookieStats cookie, int num)
{
	if(SpecialRound || !IsValidClient(client) || cvarStatPlayers.IntValue<1)
		return;

	if(!IsFakeClient(client) && (CheatsUsed || cvarStatPlayers.IntValue>playing2 || (!cvarBvBStat.BoolValue && Enabled3)))
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

	if(!cvarSelectBoss.BoolValue)
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

		static char name[64], boss[64], bossName[64], fileName[64], companionName[64];
		GetCmdArgString(name, sizeof(name));

		for(int config; config<Specials; config++)
		{
			KvRewind(BossKV[config]);
			if(KvGetNum(BossKV[config], "blocked"))
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

			if((KvGetNum(BossKV[config], "donator") && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
			   (KvGetNum(BossKV[config], "admin") && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
			   (BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true)))
			{
				if(KvGetNum(BossKV[config], "hidden"))
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
			else if(KvGetNum(BossKV[config], "owner") && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true))
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
			else if(KvGetNum(BossKV[config], "hidden") &&
			      !(KvGetNum(BossKV[config], "donator") ||
			        KvGetNum(BossKV[config], "theme") ||
				KvGetNum(BossKV[config], "admin") ||
				KvGetNum(BossKV[config], "owner")))
			{
				FReplyToCommand(client, "%t", "deny_unknown");
				return Plugin_Handled;
			}

			if(MapBlocked[config])
			{
				if(!cvarShowBossBlocked.BoolValue)
				{
					FReplyToCommand(client, "%t", "deny_unknown");
				}
				else 
				{
					FReplyToCommand(client, "%t", "deny_map");
				}
				return Plugin_Handled;
			}

			if(KvGetNum(BossKV[config], "nofirst") && (RoundCount<arenaRounds || (RoundCount==arenaRounds && CheckRoundState()!=1)))
			{
				FReplyToCommand(client, "%t", "deny_nofirst");
				return Plugin_Handled;
			}

			KvGetString(BossKV[config], "companion", companionName, sizeof(companionName));
			if(companionName[0] && !DuoMin)
			{
				FReplyToCommand(client, "%t", "deny_duo_short");
				return Plugin_Handled;
			}

			if(companionName[0] && cvarDuoBoss.BoolValue && view_as<int>(ToggleDuo[client])>1)
			{
				FReplyToCommand(client, "%t", "deny_duo_off");
				return Plugin_Handled;
			}

			if(AreClientCookiesCached(client) && cvarKeepBoss.IntValue<0)
			{
				static char cookie1[64], cookie2[64];
				KvGetString(BossKV[config], "name", cookie1, sizeof(cookie1));
				GetClientCookie(client, LastPlayedCookie, cookie2, sizeof(cookie2));
				if(StrEqual(cookie1, cookie2, false))
				{
					FReplyToCommand(client, "%t", "deny_recent");
					return Plugin_Handled;
				}
			}
			strcopy(xIncoming[client], sizeof(xIncoming[]), boss);
			CanBossVs[client] = KvGetNum(BossKV[config], "noversus");
			CanBossTeam[client] = KvGetNum(BossKV[config], "bossteam");
			IgnoreValid[client] = false;
			SaveKeepBossCookie(client);
			FReplyToCommand(client, "%t", "to0_boss_selected", bossName);
			return Plugin_Handled;
		}
	}

	char boss[64];
	static char bossName[64];
	Menu menu = new Menu(Command_SetMyBossH);
	SetGlobalTransTarget(client);
	if(ToggleBoss[client] == Setting_On)
	{
		for(int config; config<=Specials; config++)
		{
			if(config == Specials)
			{
				FormatEx(boss, sizeof(boss), "%t", "to0_random");
				break;
			}

			KvRewind(BossKV[config]);
			if(KvGetNum(BossKV[config], "blocked"))
				continue;

			KvGetString(BossKV[config], "name", bossName, sizeof(bossName));
			if(StrEqual(bossName, xIncoming[client], false))
			{
				if(IgnoreValid[client] || CheckValidBoss(client, xIncoming[client], !DuoMin))
					GetBossSpecial(config, boss, sizeof(boss), client);

				break;
			}
		}
	}

	if(Enabled2 && HasCharSets && CurrentCharSet<MAXCHARSETS)
	{
		if(kvDiffMods!=null && !cvarDifficulty.BoolValue && CheckCommandAccess(client, "ff2_difficulty", 0, true))
		{
			menu.SetTitle("%t%t", "ff2_boss_selection_pack", CharSetString[CurrentCharSet], boss, "ff2_boss_selection_diff", dIncoming[client][0] ? dIncoming[client] : "-");
		}
		else
		{
			menu.SetTitle("%t", "ff2_boss_selection_pack", CharSetString[CurrentCharSet], boss);
		}
	}
	else
	{
		if(kvDiffMods!=null && !cvarDifficulty.BoolValue && CheckCommandAccess(client, "ff2_difficulty", 0, true))
		{
			menu.SetTitle("%t%t", "ff2_boss_selection", boss, "ff2_boss_selection_diff", dIncoming[client][0] ? dIncoming[client] : "-");
		}
		else
		{
			menu.SetTitle("%t", "ff2_boss_selection", boss);
		}
	}

	FormatEx(boss, sizeof(boss), "%t", "to0_random");
	if(!Enabled2)
	{
		menu.AddItem(boss, boss, ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem(boss, boss);
	}

	if(cvarToggleBoss.BoolValue)
	{
		if(view_as<int>(ToggleBoss[client]) < 2)
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_disablepts");
		}
		else
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_enablepts");
		}
		menu.AddItem(boss, boss);
	}

	if(cvarDuoBoss.BoolValue)
	{
		if(view_as<int>(ToggleDuo[client]) < 2)
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_disableduo");
		}
		else
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_enableduo");
		}
		menu.AddItem(boss, boss);
	}

	if(kvDiffMods!=null && CheckCommandAccess(client, "ff2_difficulty", 0, true))
	{
		if(cvarDifficulty.BoolValue)
		{
			if(view_as<int>(ToggleDiff[client]) < 2)
			{
				FormatEx(boss, sizeof(boss), "%t", "to0_disablediff");
			}
			else
			{
				FormatEx(boss, sizeof(boss), "%t", "to0_enablediff");
			}
		}
		else
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_difficulty");
		}
		menu.AddItem(boss, boss);
	}

	if(cvarSkipBoss.BoolValue)
	{
		FormatEx(boss, sizeof(boss), "%t", "to0_resetpts");
		if(QueuePoints[client]<10 || !Enabled2)
		{
			menu.AddItem(boss, boss, ITEMDRAW_DISABLED);
		}
		else
		{
			menu.AddItem(boss, boss);
		}
	}

	if(HasCharSets)
	{
		FormatEx(boss, sizeof(boss), "%t", "to0_viewall");
		menu.AddItem(boss, boss);
	}

	if(!Enabled2)
	{
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}

	static char companionName[64];
	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		if(KvGetNum(BossKV[config], "blocked"))
			continue;

		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		GetBossSpecial(config, bossName, sizeof(bossName), client);
		KvGetString(BossKV[config], "companion", companionName, sizeof(companionName));
		if((KvGetNum(BossKV[config], "donator") && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
		   (KvGetNum(BossKV[config], "admin") && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
		   (BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true)))
		{
			if(!KvGetNum(BossKV[config], "hidden"))
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(BossKV[config], "owner") && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true))
		{
			if(!KvGetNum(BossKV[config], "hidden", 1))
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(BossKV[config], "hidden") &&
		      !(KvGetNum(BossKV[config], "donator") ||
		        KvGetNum(BossKV[config], "theme") ||
			KvGetNum(BossKV[config], "admin") ||
			KvGetNum(BossKV[config], "owner")))
		{
			// Don't show
		}
		else if(MapBlocked[config])
		{
			if(cvarShowBossBlocked.BoolValue)
			{
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
			}
		}
		else if(KvGetNum(BossKV[config], "nofirst") && (RoundCount<arenaRounds || (RoundCount==arenaRounds && CheckRoundState()!=1)))
		{
			menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(companionName[0] && ((cvarDuoBoss.BoolValue && view_as<int>(ToggleDuo[client])>1) || !DuoMin))
		{
			menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else
		{
			if(AreClientCookiesCached(client) && cvarKeepBoss.IntValue<0 && !CheckCommandAccess(client, "ff2_replay_bosses", ADMFLAG_CHEATS, true))
			{
				GetClientCookie(client, LastPlayedCookie, companionName, sizeof(companionName));
				if(StrEqual(boss, companionName, false))
				{
					menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
					continue;
				}
			}
			menu.AddItem(boss, bossName);
		}
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int Command_SetMyBossH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!param2)
			{
				xIncoming[param1][0] = 0;
				CanBossVs[param1] = 0;
				CanBossTeam[param1] = 0;
				IgnoreValid[param1] = false;
				SaveKeepBossCookie(param1);
				FReplyToCommand(param1, "%t", "to0_comfirmrandom");
				return;
			}

			int option[5];
			for(int choices=1; choices<6; choices++)
			{
				if(!option[0] && cvarToggleBoss.BoolValue)
				{
					option[0] = choices;
					continue;
				}
				if(!option[1] && cvarDuoBoss.BoolValue)
				{
					option[1] = choices;
					continue;
				}
				if(!option[2] && kvDiffMods!=null && CheckCommandAccess(param1, "ff2_difficulty", 0, true))
				{
					option[2] = choices;
					continue;
				}
				if(!option[3] && cvarSkipBoss.BoolValue)
				{
					option[3] = choices;
					continue;
				}
				if(!option[4] && HasCharSets && !CharSetOldPath)
				{
					option[4] = choices;
					continue;
				}
			}

			if(param2 == option[0])
			{
				BossMenu(param1, 0);
			}
			else if(param2 == option[1])
			{
				CompanionMenu(param1, 0);
			}
			else if(param2 == option[2])
			{
				DiffMenu(param1, 0);
			}
			else if(param2 == option[3])
			{
				SkipBossPanel(param1);
			}
			else if(param2 == option[4])
			{
				PackMenu(param1);
			}
			else if(!cvarBossDesc.BoolValue || !ToggleInfo[param1])
			{
				static char name[64], bossName[64];
				menu.GetItem(param2, name, sizeof(name), _, bossName, sizeof(bossName));
				if(CheckValidBoss(param1, name))
				{
					strcopy(xIncoming[param1], sizeof(xIncoming[]), name);
					IgnoreValid[param1] = false;
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
				menu.GetItem(param2, cIncoming[param1], sizeof(cIncoming[]));
				ConfirmBoss(param1);
			}
		}
	}
}

public Action ConfirmBoss(int client)
{
	char text[512];
	static char language[20], boss[64];
	GetLanguageInfo(GetClientLanguage(client), language, sizeof(language), text, sizeof(text));
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
					FormatEx(text, sizeof(text), "%t", "to0_nodesc");
			}
			ReplaceString(text, sizeof(text), "\\n", "\n");
			GetBossSpecial(config, boss, sizeof(boss), client);
			break;
		}
	}

	Menu menu = new Menu(ConfirmBossH);
	menu.SetTitle(text);

	FormatEx(text, sizeof(text), "%t", "to0_confirm", boss);
	menu.AddItem(boss, text);

	FormatEx(text, sizeof(text), "%t", "to0_cancel");
	menu.AddItem(text, text);

	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int ConfirmBossH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!param2 && CheckValidBoss(param1, cIncoming[param1]))
			{
				static char bossName[64];
				menu.GetItem(param2, bossName, sizeof(bossName));
				strcopy(xIncoming[param1], sizeof(xIncoming[]), cIncoming[param1]);
				IgnoreValid[param1] = false;
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

public void PackMenu(int client)
{
	static char pack[128], num[4], config[PLATFORM_MAX_PATH];
	Menu menu = new Menu(PackMenuH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "to0_packmenu");

	BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	int total;
	static char cookies[454];
	char cookieValues[MAXCHARSETS][64];
	if(AreClientCookiesCached(client))
	{
		GetClientCookie(client, SelectionCookie, cookies, sizeof(cookies));
		ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
	}

	do
	{
		total++;
		if(KvGetNum(Kv, "hidden"))
			continue;

		KvGetSectionName(Kv, pack, sizeof(pack));
		IntToString(total, num, sizeof(num));
		if(total < (MAXCHARSETS+1))
			Format(pack, sizeof(pack), "%s: %s", pack, cookieValues[total-1]);

		menu.AddItem(num, pack, (CurrentCharSet==total-1 || total>MAXCHARSETS) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	while(KvGotoNextKey(Kv));
	delete Kv;

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PackMenuH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			static char pack[4];
			menu.GetItem(param2, pack, sizeof(pack));
			PackBoss(param1, StringToInt(pack)-1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Command_SetMyBoss(param1, 0);
		}
	}
}

public void PackBoss(int client, int pack)
{
	char boss[66], bossName[64];
	Menu menu = new Menu(PackBossH);
	SetGlobalTransTarget(client);

	if(AreClientCookiesCached(client))
	{
		static char cookies[454];
		char cookieValues[MAXCHARSETS][64];
		GetClientCookie(client, SelectionCookie, cookies, sizeof(cookies));
		ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
		if(cookieValues[pack][0])
			strcopy(boss, sizeof(boss), cookieValues[pack]);
	}

	menu.SetTitle("%t", "to0_viewpack", CharSetString[pack], boss);

	FormatEx(boss, sizeof(boss), ";%i", pack);
	FormatEx(bossName, sizeof(bossName), "%t", "to0_random");
	menu.AddItem(boss, bossName);

	for(int config; config<PackSpecials[pack]; config++)
	{
		KvRewind(PackKV[config][pack]);
		if(KvGetNum(PackKV[config][pack], "blocked"))
			continue;

		KvGetString(PackKV[config][pack], "name", boss, sizeof(boss));
		GetBossSpecial(config, bossName, sizeof(bossName), client, pack);
		if((KvGetNum(PackKV[config][pack], "donator") && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
		   (KvGetNum(PackKV[config][pack], "admin") && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)))
		{
			if(!KvGetNum(PackKV[config][pack], "hidden"))
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(PackKV[config][pack], "owner") && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true))
		{
			if(!KvGetNum(PackKV[config][pack], "hidden", 1))
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(PackKV[config][pack], "hidden") &&
		      !(KvGetNum(PackKV[config][pack], "donator") ||
		        KvGetNum(PackKV[config][pack], "theme") ||
			KvGetNum(PackKV[config][pack], "admin") ||
			KvGetNum(PackKV[config][pack], "owner")))
		{
			// Don't show
		}
		else
		{
			Format(boss, sizeof(boss), "%s;%i", boss, pack);
			menu.AddItem(boss, bossName);
		}
	}

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PackBossH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!AreClientCookiesCached(param1))
			{
				PrintToChat(param1, "[SM] %t", "Could not connect to database");
				PackMenu(param1);
				return;
			}

			static char name[2][64];
			static char cookies[454];
			menu.GetItem(param2, cookies, sizeof(cookies));
			int pack = ExplodeString(cookies, ";", name, 2, 64);
			if(pack < 1)
			{
				PackMenu(param1);
				return;
			}

			pack = StringToInt(name[1]);
			if(pack < MAXCHARSETS)
			{
				if(param2 && cvarBossDesc.BoolValue && ToggleInfo[param1])
				{
					strcopy(cIncoming[param1], sizeof(cIncoming[]), cookies);
					PackConfirmBoss(param1, pack);
					return;
				}

				char cookieValues[MAXCHARSETS][64];
				GetClientCookie(param1, SelectionCookie, cookies, sizeof(cookies));
				ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
				strcopy(cookieValues[pack], 64, name[0]);

				strcopy(cookies, sizeof(cookies), cookieValues[0]);
				for(int i=1; i<MAXCHARSETS; i++)
				{
					Format(cookies, sizeof(cookies), "%s;%s", cookies, cookieValues[i]);
				}
				SetClientCookie(param1, SelectionCookie, cookies);
			}

			PackMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				PackMenu(param1);
		}
	}
}

public void PackConfirmBoss(int client, int pack)
{
	static char name[2][64];
	if(ExplodeString(cIncoming[client], ";", name, 2, 64) < 1)
	{
		PackMenu(client);
		return;
	}

	char text[512];
	static char language[20], boss[64];
	GetLanguageInfo(GetClientLanguage(client), language, sizeof(language), text, sizeof(text));
	Format(language, sizeof(language), "description_%s", language);
	SetGlobalTransTarget(client);

	for(int config; config<PackSpecials[pack]; config++)
	{
		KvRewind(PackKV[config][pack]);
		KvGetString(PackKV[config][pack], "name", boss, sizeof(boss));
		if(StrEqual(boss, name[0], false))
		{
			KvRewind(PackKV[config][pack]);
			KvGetString(PackKV[config][pack], language, text, sizeof(text));
			if(!text[0])
			{
				KvGetString(PackKV[config][pack], "description_en", text, sizeof(text));  //Default to English if their language isn't available
				if(!text[0])
					FormatEx(text, sizeof(text), "%t", "to0_nodesc");
			}
			ReplaceString(text, sizeof(text), "\\n", "\n");
			GetBossSpecial(config, boss, sizeof(boss), client, pack);
			break;
		}
	}

	Menu menu = new Menu(PackConfirmBossH);
	menu.SetTitle(text);

	FormatEx(text, sizeof(text), "%t", "to0_confirmpack", boss, CharSetString[pack]);
	menu.AddItem(boss, text);

	FormatEx(text, sizeof(text), "%t", "to0_cancel");
	menu.AddItem(text, text);

	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int PackConfirmBossH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			static char name[2][64];
			int pack = ExplodeString(cIncoming[param1], ";", name, 2, 64);
			if(pack < 1)
			{
				PackMenu(param1);
				return;
			}

			pack = StringToInt(name[1]);
			if(!param2)
			{
				if(!AreClientCookiesCached(param1))
				{
					PrintToChat(param1, "[SM] %t", "Could not connect to database");
					PackMenu(param1);
					return;
				}

				if(pack < MAXCHARSETS)
				{
					static char cookies[454];
					char cookieValues[MAXCHARSETS][64];
					GetClientCookie(param1, SelectionCookie, cookies, sizeof(cookies));
					ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
					strcopy(cookieValues[pack], 64, name[0]);

					strcopy(cookies, sizeof(cookies), cookieValues[0]);
					for(int i=1; i<MAXCHARSETS; i++)
					{
						Format(cookies, sizeof(cookies), "%s;%s", cookies, cookieValues[i]);
					}
					SetClientCookie(param1, SelectionCookie, cookies);
				}
			}
			else if(pack < MAXCHARSETS)
			{
				PackBoss(param1, pack);	
				return;
			}

			PackMenu(param1);
		}
	}
}

bool BossTheme(int config)
{
	KvRewind(BossKV[config]);
	int theme = RoundFloat(Pow(KvGetFloat(BossKV[config], "theme"), 2.0));
	if(theme < 1)
		return false;

	return !(cvarTheme.IntValue & theme);
}

void SaveKeepBossCookie(int client)
{
	if(!AreClientCookiesCached(client))
		return;

	static char cookies[454];
	if(!IgnoreValid[client] && CurrentCharSet>=0 && CurrentCharSet<MAXCHARSETS && cvarSelectBoss.BoolValue)
	{
		char cookieValues[MAXCHARSETS][64];
		GetClientCookie(client, SelectionCookie, cookies, sizeof(cookies));
		ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
		strcopy(cookieValues[CurrentCharSet], 64, xIncoming[client]);

		strcopy(cookies, sizeof(cookies), cookieValues[0]);
		for(int i=1; i<MAXCHARSETS; i++)
		{
			Format(cookies, sizeof(cookies), "%s;%s", cookies, cookieValues[i]);
		}
		SetClientCookie(client, SelectionCookie, cookies);
	}

	if(!cvarDifficulty.BoolValue)
		SetClientCookie(client, DiffCookie, dIncoming[client]);
}

bool CheckValidBoss(int client=0, char[] SpecialName, bool CompanionCheck=false)
{
	if(!Enabled2)
		return false;

	static char boss[64], companionName[64];
	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		if(KvGetNum(BossKV[config], "blocked"))
			continue;

		KvGetString(BossKV[config], "companion", companionName, sizeof(companionName));
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrEqual(boss, SpecialName, false))
		{
			if(companionName[0] && CompanionCheck)
				return false;

			if(client)
			{
				if((KvGetNum(BossKV[config], "donator") && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
				   (KvGetNum(BossKV[config], "admin") && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
				   (KvGetNum(BossKV[config], "owner") && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true)))
					return false;

				if(BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true))
					return false;
			}

			if(KvGetNum(BossKV[config], "nofirst") && (RoundCount<arenaRounds || (RoundCount==arenaRounds && CheckRoundState()!=1)))
				return false;

			if(client)
			{
				CanBossVs[client] = KvGetNum(BossKV[config], "noversus");
				CanBossTeam[client] = KvGetNum(BossKV[config], "bossteam");
			}

			return true;
		}
	}
	return false;
}

public Action FF2_OnSpecialSelected(int boss, int &SpecialNum, char[] SpecialName, bool preset)
{
	int client = Boss[boss];
	if((!boss || boss==MAXBOSSES) && (IgnoreValid[client] || CheckValidBoss(client, xIncoming[client], !DuoMin)) && cvarSelectBoss.BoolValue && CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		if(preset)
		{
			FPrintToChat(client, "%t", "boss_selection_overridden");
		}
		else
		{
			strcopy(SpecialName, sizeof(xIncoming[]), xIncoming[client]);
			if(cvarKeepBoss.IntValue<1 || !cvarSelectBoss.BoolValue || IsFakeClient(client))
			{
				xIncoming[client][0] = 0;
				CanBossVs[client] = 0;
				CanBossTeam[client] = 0;
				IgnoreValid[client] = false;
				SaveKeepBossCookie(client);
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

stock int CreateAttachedAnnotation(int client, int entity, bool effect=true, float time, const char[] buffer, any ...)
{
	static char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 6);
	ReplaceString(message, sizeof(message), "\n", "");  //Get rid of newlines

	Event event = CreateEvent("show_annotation");
	if(event == INVALID_HANDLE)
		return -1;

	event.SetInt("follow_entindex", entity);
	event.GetFloat("lifetime", time);
	event.SetInt("visibilityBitfield", (1<<client));
	event.SetBool("show_effect", effect);
	event.SetString("text", message);
	event.SetString("play_sound", "vo/null.wav");
	event.SetInt("id", entity); //What to enter inside? Need a way to identify annotations by entindex!
	event.Fire();
	return entity;
}

stock bool ShowGameText(int client, const char[] icon="leaderboard_streak", int color=0, const char[] buffer, any ...)
{
	BfWrite bf;
	if(!client)
	{
		bf = view_as<BfWrite>(StartMessageAll("HudNotifyCustom"));
	}
	else
	{
		bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
	}

	if(bf == null)
		return false;

	static char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 5);
	ReplaceString(message, sizeof(message), "\n", "");

	bf.WriteString(message);
	bf.WriteString(icon);
	bf.WriteByte(color);
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

		if(!IsBoss(client) && !xIncoming[client][0])
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

	char[][] text = new char[MaxClients+1][512];
	char textChat[512];
	static char name[64];
	if(Enabled3)
	{
		bool boss1, boss2;
		char[][] text2 = new char[MaxClients+1][512];
		for(int boss; boss<=MaxClients; boss++)
		{
			if(IsValidClient(Boss[boss]))
			{
				char lives[8];
				if(BossLives[boss] > 1)
					FormatEx(lives, sizeof(lives), "x%i", BossLives[boss]);

				for(int client=1; client<=MaxClients; client++)
				{
					if(!IsValidClient(client))
						continue;
					
					SetGlobalTransTarget(client);
					GetBossSpecial(Special[boss], name, sizeof(name));
					if(BossSwitched[boss])
					{
						Format(text2[client], 512, "%s\n%t", boss2 ? text2[client] : "", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
					}
					else
					{
						Format(text[client], 512, "%s\n%t", boss1 ? text[client] : "", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
					}
					FormatEx(textChat, sizeof(textChat), "%t", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
					ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
					FPrintToChat(client, textChat);
				}

				if(BossSwitched[boss])
				{
					boss2 = true;
				}
				else
				{
					boss1 = true;
				}
			}
		}

		SetHudTextParams(0.25, 0.3, 10.0, 100, 100, 255, 255);
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client) || HudSettings[client][2] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
				continue;

			ShowSyncHudText(client, infoHUD, text[client]);
		}

		SetHudTextParams(0.6, 0.3, 10.0, 255, 100, 100, 255);
		for(int client=1; client<=MaxClients; client++)
		{
			if(!IsValidClient(client) || HudSettings[client][2] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
				continue;

			ShowSyncHudText(client, abilitiesHUD, text2[client]);
		}
		CreateTimer(10.0, Timer_ShowHealthText, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}

	bool multi;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(IsValidClient(Boss[boss]))
		{
			char lives[8];
			if(BossLives[boss] > 1)
				FormatEx(lives, sizeof(lives), "x%i", BossLives[boss]);

			for(int client=1; client<=MaxClients; client++)
			{
				if(!IsValidClient(client))
					continue;

				SetGlobalTransTarget(client);
				GetBossSpecial(Special[boss], name, sizeof(name), client);
				Format(text[client], 512, "%s\n%t", multi ? text[client] : "", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
				FormatEx(textChat, sizeof(textChat), "%t", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
				ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
				FPrintToChat(client, textChat);
				if(SpecialRound && cvarGameText.IntValue<2)
					Format(text[client], 512, "%s\n(%s)", text[client], dIncoming[Boss[boss]]);
			}

			if(SpecialRound)
			{
				FormatEx(textChat, sizeof(textChat), "%t", "ff2_boss_selection_diff", dIncoming[Boss[boss]]);
				ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
				FPrintToChatAll(textChat);
				break;
			}

			multi = true;
		}
	}

	SetHudTextParams(-1.0, 0.2, 10.0, 255, 255, 255, 255);
	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || HudSettings[client][2] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
			continue;

		if(bosses<2 && cvarGameText.IntValue>1)
		{
			if(BossIcon[0])
			{
				ShowGameText(client, BossIcon, SpecialRound ? BossTeam : 0, text[client]);
			}
			else
			{
				ShowGameText(client, "leaderboard_streak", SpecialRound ? BossTeam : 0, text[client]);
			}
			CreateTimer(1.5, Timer_ShowHealthText, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			ShowSyncHudText(client, infoHUD, text[client]);
			CreateTimer(10.0, Timer_ShowHealthText, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action Timer_ShowHealthText(Handle timer)
{
	ShowHealthText = true;
	return Plugin_Continue;
}

public Action MakeModelTimer(Handle timer, int boss)
{
	if(IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]) && CheckRoundState()!=2)
	{
		static char model[PLATFORM_MAX_PATH];
		KvRewind(BossKV[Special[boss]]);
		KvGetString(BossKV[Special[boss]], "model", model, PLATFORM_MAX_PATH);
		SetVariantString(model);
		AcceptEntityInput(Boss[boss], "SetCustomModel");
		SetEntProp(Boss[boss], Prop_Send, "m_bUseClassAnimations", 1);
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

void EquipBoss(int boss)
{
	int client = Boss[boss];
	DoOverlay(client, "");
	TF2_RemoveAllWeapons(client);
	char attributes[256], key[10];
	static char classname[64], wModel[PLATFORM_MAX_PATH];
	int weapon, strangerank, weaponlevel, index, strangekills;
	bool strangewep, overridewep;
	static int rgba[4];
	for(int i=1; ; i++)
	{
		KvRewind(BossKV[Special[boss]]);
		FormatEx(key, sizeof(key), "weapon%i", i);
		if(KvJumpToKey(BossKV[Special[boss]], key))
		{
			KvGetString(BossKV[Special[boss]], "name", classname, sizeof(classname));
			KvGetString(BossKV[Special[boss]], "attributes", attributes, sizeof(attributes));
			strangerank = KvGetNum(BossKV[Special[boss]], "rank", 21);
			weaponlevel = KvGetNum(BossKV[Special[boss]], "level", -1);
			index = KvGetNum(BossKV[Special[boss]], "index");
			overridewep = view_as<bool>(KvGetNum(BossKV[Special[boss]], "override"));
			strangekills = -1;
			strangewep = true;
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
					if(!cvarStrangeWep.BoolValue || weaponlevel!=-1 || overridewep)
						strangewep = false;
				}
			}

			if(weaponlevel < 0)
				weaponlevel = 101;

			#if defined _tf2attributes_included
			if(!tf2attributes && strangewep)
			#else
			if(strangewep)
			#endif
			{
				if(attributes[0])
				{
					if(overridewep)
					{
						Format(attributes, sizeof(attributes), "214 ; %d ; %s", strangekills, attributes);
					}
					else
					{
						Format(attributes, sizeof(attributes), "%s ; 68 ; %i ; 214 ; %d ; %s", Attributes, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, strangekills, attributes);
					}
				}
				else
				{
					if(overridewep)
					{
						FormatEx(attributes, sizeof(attributes), "214 ; %d", strangekills);
					}
					else
					{
						FormatEx(attributes, sizeof(attributes), "%s ; 68 ; %i ; 214 ; %d", Attributes, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, strangekills);
					}
				}
			}
			else if(!overridewep)
			{
				if(attributes[0])
				{
					Format(attributes, sizeof(attributes), "%s ; 68 ; %i ; %s", Attributes, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, attributes);
				}
				else
				{
					FormatEx(attributes, sizeof(attributes), "%s ; 68 ; %i", Attributes, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2);
				}
			}

			weapon = FF2_SpawnWeapon(client, classname, index, weaponlevel, KvGetNum(BossKV[Special[boss]], "quality", QualityWep), attributes);
			if(weapon == -1)
				continue;

			#if defined _tf2attributes_included
			if(tf2attributes && strangewep)
				TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(strangekills));
			#endif

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

			if(KvGetNum(BossKV[Special[boss]], "show"))
			{
				KvGetString(BossKV[Special[boss]], "worldmodel", wModel, sizeof(wModel));
				if(wModel[0])
					ConfigureWorldModelOverride(weapon, wModel);

				rgba[0] = KvGetNum(BossKV[Special[boss]], "alpha", 255);
				rgba[1] = KvGetNum(BossKV[Special[boss]], "red", 255);
				rgba[2] = KvGetNum(BossKV[Special[boss]], "green", 255);
				rgba[3] = KvGetNum(BossKV[Special[boss]], "blue", 255);

				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, rgba[1], rgba[2], rgba[3], rgba[0]);
			}
			else
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
			}

			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
		else
		{
			break;
		}
	}

	if(SDKEquipWearable != null)
	{
		for(int i=1; ; i++)
		{
			KvRewind(BossKV[Special[boss]]);
			FormatEx(key, sizeof(key), "wearable%i", i);
			if(KvJumpToKey(BossKV[Special[boss]], key))
			{
				KvGetString(BossKV[Special[boss]], "name", classname, sizeof(classname));
				KvGetString(BossKV[Special[boss]], "attributes", attributes, sizeof(attributes));
				strangerank = KvGetNum(BossKV[Special[boss]], "rank", 21);
				weaponlevel = KvGetNum(BossKV[Special[boss]], "level", -1);
				index = KvGetNum(BossKV[Special[boss]], "index");
				strangekills = -1;
				strangewep = true;
				switch(strangerank)
				{
					case 0:
					{
						if(index==133 || index==444 || index==655)	// Gunboats, Mantreads, or Spirit of Giving
						{
							strangekills = 0;
						}
						else
						{
							strangekills = GetRandomInt(0, 14);
						}
					}
					case 1:
					{
						if(index==133 || index==444 || index==655)	// Gunboats, Mantreads, or Spirit of Giving
						{
							strangekills = GetRandomInt(1, 2);
						}
						else
						{
							strangekills = GetRandomInt(15, 29);
						}
					}
					case 2:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(3, 4);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(3, 6);
						}
						else
						{
							strangekills = GetRandomInt(30, 49);
						}
					}
					case 3:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(5, 6);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(7, 11);
						}
						else
						{
							strangekills = GetRandomInt(50, 74);
						}
					}
					case 4:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(7, 9);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(12, 19);
						}
						else
						{
							strangekills = GetRandomInt(75, 99);
						}
					}
					case 5:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(10, 13);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(20, 27);
						}
						else
						{
							strangekills =  GetRandomInt(100, 134);
						}
					}
					case 6:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(14, 17);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(28, 36);
						}
						else
						{
							strangekills = GetRandomInt(135, 174);
						}
					}
					case 7:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(18, 22);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(37, 46);
						}
						else
						{
							strangekills = GetRandomInt(175, 249);
						}
					}
					case 8:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(23, 27);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(47, 56);
						}
						else
						{
							strangekills = GetRandomInt(250, 374);
						}
					}
					case 9:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(28, 34);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(57, 67);
						}
						else
						{
							strangekills = GetRandomInt(375, 499);
						}
					}
					case 10:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(35, 49);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(68, 78);
						}
						else
						{
							strangekills = GetRandomInt(500, 724);
						}
					}
					case 11:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(50, 74);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(79, 90);
						}
						else
						{
							strangekills = GetRandomInt(725, 999);
						}
					}
					case 12:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(75, 98);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(91, 103);
						}
						else
						{
							strangekills = GetRandomInt(1000, 1499);
						}
					}
					case 13:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = 99;
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(104, 119);
						}
						else
						{
							strangekills = GetRandomInt(1500, 1999);
						}
					}
					case 14:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(100, 149);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(120, 137);
						}
						else
						{
							strangekills = GetRandomInt(2000, 2749);
						}
					}
					case 15:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(150, 249);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(138, 157);
						}
						else
						{
							strangekills = GetRandomInt(2750, 3999);
						}
					}
					case 16:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(250, 499);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(158, 178);
						}
						else
						{
							strangekills = GetRandomInt(4000, 5499);
						}
					}
					case 17:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(500, 749);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(179, 209);
						}
						else
						{
							strangekills = GetRandomInt(5500, 7499);
						}
					}
					case 18:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(750, 783);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(210, 249);
						}
						else
						{
							strangekills = GetRandomInt(7500, 9999);
						}
					}
					case 19:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(784, 849);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(250, 299);
						}
						else
						{
							strangekills = GetRandomInt(10000, 14999);
						}
					}
					case 20:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(850, 999);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(300, 399);
						}
						else
						{
							strangekills = GetRandomInt(15000, 19999);
						}
					}
					default:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(0, 999);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(0, 399);
						}
						else
						{
							strangekills = GetRandomInt(0, 19999);
						}

						if(!cvarStrangeWep.BoolValue || weaponlevel!=-1)
							strangewep = false;
					}
				}

				if(weaponlevel < 0)
					weaponlevel = 101;

				#if defined _tf2attributes_included
				if(!tf2attributes && strangewep)
				#else
				if(strangewep)
				#endif
				{
					if(attributes[0])
					{
						Format(attributes, sizeof(attributes), "214 ; %d ; %s", strangekills, attributes);
					}
					else
					{
						FormatEx(attributes, sizeof(attributes), "214 ; %d", strangekills);
					}
				}

				weapon = TF2_CreateAndEquipWearable(client, classname, index, weaponlevel, KvGetNum(BossKV[Special[boss]], "quality", QualityWep), attributes);
				if(!IsValidEntity(weapon))
					continue;

				#if defined _tf2attributes_included
				if(tf2attributes && strangewep)
					TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(strangekills));
				#endif

				if(KvGetNum(BossKV[Special[boss]], "show", 1))
				{
					KvGetString(BossKV[Special[boss]], "worldmodel", wModel, sizeof(wModel));
					if(wModel[0])
						ConfigureWorldModelOverride(weapon, wModel, true);

					rgba[0] = KvGetNum(BossKV[Special[boss]], "alpha", 255);
					rgba[1] = KvGetNum(BossKV[Special[boss]], "red", 255);
					rgba[2] = KvGetNum(BossKV[Special[boss]], "green", 255);
					rgba[3] = KvGetNum(BossKV[Special[boss]], "blue", 255);

					SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
					SetEntityRenderColor(weapon, rgba[1], rgba[2], rgba[3], rgba[0]);
				}
				else
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
					SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
					SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
				}
			}
			else
			{
				break;
			}
		}
	}

	KvGoBack(BossKV[Special[boss]]);
	TFClassType class = KvGetClass(BossKV[Special[boss]], "class");
	HasEquipped[boss] = true;
	if(TF2_GetPlayerClass(client) != class)
		TF2_SetPlayerClass(client, class, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
}

stock bool ConfigureWorldModelOverride(int entity, const char[] model, bool wearable=false)
{
	if(!FileExists(model, true))
		return false;

	int modelIndex = PrecacheModel(model);
	SetEntProp(entity, Prop_Send, "m_nModelIndex", modelIndex);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 1);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 2);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 3);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", (wearable ? GetEntProp(entity, Prop_Send, "m_nModelIndex") : GetEntProp(entity, Prop_Send, "m_iWorldModelIndex")), _, 0);
	return true;
}

stock int TF2_CreateAndEquipWearable(int client, const char[] classname, int index, int level, int quality, char[] attributes)
{
	int wearable;
	if(classname[0])
	{
		wearable = CreateEntityByName(classname);
	}
	else
	{
		wearable = CreateEntityByName("tf_wearable");
	}

	if(!IsValidEntity(wearable))
		return -1;

	SetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex", index);
	SetEntProp(wearable, Prop_Send, "m_bInitialized", 1);
		
	// Allow quality / level override by updating through the offset.
	SetEntData(wearable, GetEntSendPropOffs(wearable, "m_iEntityQuality", true), quality);
	SetEntData(wearable, GetEntSendPropOffs(wearable, "m_iEntityLevel", true), level);

	SetEntProp(wearable, Prop_Send, "m_iEntityQuality", quality);
	SetEntProp(wearable, Prop_Send, "m_iEntityLevel", level);

	#if defined _tf2attributes_included
	if(attributes[0] && tf2attributes)
	{
		char atts[32][32];
		int count = ExplodeString(attributes, " ; ", atts, 32, 32);
		if(count > 1)
		{
			for(int i; i<count; i+=2)
			{
				TF2Attrib_SetByDefIndex(wearable, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			}
		}
	}
	#endif
		
	DispatchSpawn(wearable);
	SDK_EquipWearable(client, wearable);
	return wearable;
}

stock void SDK_EquipWearable(int client, int wearable)
{
	if(SDKEquipWearable != null)
		SDKCall(SDKEquipWearable, client, wearable);
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

	BossRageDamage[boss] = ParseFormula(boss, "ragedamage", RageDamage, 1900);
	if(BossRageDamage[boss] < 1)	// 0 or below, disable RAGE
		BossRageDamage[boss] = 99999;

	BossLivesMax[boss] = KvGetNum(BossKV[Special[boss]], "lives", 1);
	if(BossLivesMax[boss] < 1)
	{
		char bossName[64];
		KvGetString(BossKV[Special[boss]], "filename", bossName, sizeof(bossName));
		LogToFile(eLog, "[Boss] Warning: Boss %s has an invalid amount of lives, setting to 1", bossName);
		BossLivesMax[boss] = 1;
	}
	BossHealthMax[boss] = ParseFormula(boss, "health_formula", HealthFormula, RoundFloat(Pow((760.8+float(playing))*(float(playing)-1.0), 1.0341)+2046.0));
	BossLives[boss] = BossLivesMax[boss];
	BossHealth[boss] = BossHealthMax[boss]*BossLivesMax[boss];
	BossHealthLast[boss] = BossHealth[boss];

	if(KvGetNum(BossKV[Special[boss]], "triple", -1) >= 0)
	{
		dmgTriple[client] = view_as<bool>(KvGetNum(BossKV[Special[boss]], "triple", -1));
	}
	else
	{
		dmgTriple[client] = cvarTripleWep.BoolValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "knockback", -1) >= 0)
	{
		SelfKnockback[client] = KvGetNum(BossKV[Special[boss]], "knockback", -1);
	}
	else if(KvGetNum(BossKV[Special[boss]], "rocketjump", -1) >= 0)
	{
		SelfKnockback[client] = KvGetNum(BossKV[Special[boss]], "rocketjump", -1);
	}
	else
	{
		SelfKnockback[client] = cvarSelfKnockback.IntValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "crits", -1) >= 0)
	{
		randomCrits[client] = view_as<bool>(KvGetNum(BossKV[Special[boss]], "crits", -1));
	}
	else
	{
		randomCrits[client] = cvarCrits.BoolValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "healing", -1) >= 0)
	{
		SelfHealing[client] = KvGetNum(BossKV[Special[boss]], "healing", -1);
	}
	else
	{
		SelfHealing[client] = cvarSelfHealing.IntValue;
	}

	LifeHealing[client] = KvGetFloat(BossKV[Special[boss]], "healing_lives");
	OverHealing[client] = KvGetFloat(BossKV[Special[boss]], "healing_over");
	rageMode[client] = KvGetNum(BossKV[Special[boss]], "ragemode");
	KvGetString(BossKV[Special[boss]], "icon", BossIcon, sizeof(BossIcon));
	rageMax[client] = KvGetFloat(BossKV[Special[boss]], "ragemax", 100.0);
	rageMin[client] = KvGetFloat(BossKV[Special[boss]], "ragemin", 100.0);
	GoombaMode = KvGetNum(BossKV[Special[boss]], "goomba", GOOMBA_ALL);
	CapMode = KvGetNum(BossKV[Special[boss]], "blockcap", CAP_ALL);
	TimerMode = view_as<bool>(KvGetNum(BossKV[Special[boss]], "miniontimer"));

	// Timer/point settings
	if(KvGetNum(BossKV[Special[boss]], "pointtype", -1)>=0 && KvGetNum(BossKV[Special[boss]], "pointtype", -1)<=2)
	{
		PointType = KvGetNum(BossKV[Special[boss]], "pointtype", -1);
	}
	else
	{
		PointType = cvarPointType.IntValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "pointdelay", -9999) != -9999)	// Can be below 0 so...
	{
		PointDelay = KvGetNum(BossKV[Special[boss]], "pointdelay", -9999);
	}
	else
	{
		PointDelay = cvarPointDelay.IntValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "pointtime", -9999) != -9999)	// Same here, in-case of some weird boss logic
	{
		PointTime = KvGetNum(BossKV[Special[boss]], "pointtime", -9999);
	}
	else
	{
		PointTime = cvarPointTime.IntValue;
	}

	if(KvGetFloat(BossKV[Special[boss]], "pointalive", -1.0) >= 0)	// Can't be below 0, it's players/ratio
	{
		AliveToEnable = KvGetFloat(BossKV[Special[boss]], "pointalive", -1.0);
	}
	else
	{
		AliveToEnable = cvarAliveToEnable.FloatValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "countdownhealth", -1) >= 0)	// Also can't be below 0, it's health
	{
		countdownHealth = KvGetNum(BossKV[Special[boss]], "countdownhealth", -1);
	}
	else
	{
		countdownHealth = cvarCountdownHealth.IntValue;
	}

	if(KvGetFloat(BossKV[Special[boss]], "countdownalive", -1.0) >= 0)	// Yet again, can't be below 0
	{
		countdownPlayers = KvGetFloat(BossKV[Special[boss]], "countdownalive", -1.0);
	}
	else
	{
		countdownPlayers = cvarCountdownPlayers.FloatValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "countdowntime", -1) >= 0)	// .w.
	{
		countdownTime = KvGetNum(BossKV[Special[boss]], "countdowntime", -1);
	}
	else
	{
		countdownTime = cvarCountdownTime.IntValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "countdownovertime", -1) >= 0)	// OVERTIME!
	{
		countdownOvertime = view_as<bool>(KvGetNum(BossKV[Special[boss]], "countdownovertime", -1));
	}
	else
	{
		countdownOvertime = cvarCountdownOvertime.BoolValue;
	}

	if((KvGetNum(BossKV[Special[boss]], "sapper", -1)<0 && (cvarSappers.IntValue==1 || cvarSappers.IntValue>2)) || KvGetNum(BossKV[Special[boss]], "sapper", -1)==1 || KvGetNum(BossKV[Special[boss]], "sapper", -1)>2)
	{
		SapperBoss[client] = true;
	}
	else
	{
		SapperBoss[client] = false;
	}

	if((KvGetNum(BossKV[Special[boss]], "sapper", -1)<0 && cvarSappers.IntValue>1) || KvGetNum(BossKV[Special[boss]], "sapper", -1)>1)
		SapperMinion = true;

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
	KvRewind(BossKV[Special[boss]]);
	TF2_RemovePlayerDisguise(client);
	TF2_SetPlayerClass(client, KvGetClass(BossKV[Special[boss]], "class"), _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal

	switch(KvGetNum(BossKV[Special[boss]], "pickups"))  //Check if the boss is allowed to pickup health/ammo
	{
		case 0:
			FF2flags[client] &= ~(FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS);

		case 1:
			FF2flags[client] &= ~FF2FLAG_ALLOW_AMMO_PICKUPS;

		case 2:
			FF2flags[client] &= ~FF2FLAG_ALLOW_HEALTH_PICKUPS;
	}

	if(!HasSwitched && !Enabled3)
	{
		switch(KvGetNum(BossKV[Special[boss]], "bossteam"))
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
		HasSwitched = true;
	}

	CreateTimer(0.2, MakeModelTimer, boss, TIMER_FLAG_NO_MAPCHANGE);
	if(!IsVoteInProgress() && ToggleInfo[client])
		HelpPanelBoss(boss);

	if(!IsPlayerAlive(client))
		return Plugin_Continue;

	bool cosmetics = view_as<bool>(KvGetNum(BossKV[Special[boss]], "cosmetics"));
	int entity = -1;
	while((entity=FindEntityByClassname2(entity, "tf_wear*")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
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
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
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
	if(((!GetBossIndex(client) || GetBossIndex(client)==MAXBOSSES) && cvarDuoRestore.BoolValue) || !cvarDuoRestore.BoolValue)
		QueuePoints[client] = 0;

	if(AreClientCookiesCached(client))
	{
		static char cookie[64];
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
	int iSkip[MAXTF2PLAYERS]={0,...};
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
		int wepIdx, wepIndex, weaponIdxcount, isOverride;
		char weapon[64];
		for(int i=1; ; i++)
		{
			KvRewind(kvWeaponMods);
			FormatEx(weapon, sizeof(weapon), "weapon%i", i);
			if(KvJumpToKey(kvWeaponMods, weapon))
			{
				static char wepIndexStr[768], attributes[768];
				isOverride = KvGetNum(kvWeaponMods, "mode");
				KvGetString(kvWeaponMods, "classname", weapon, sizeof(weapon));
				KvGetString(kvWeaponMods, "index", wepIndexStr, sizeof(wepIndexStr));
				KvGetString(kvWeaponMods, "attributes", attributes, sizeof(attributes));

				if(isOverride)
				{
					if(StrContains(wepIndexStr, "-2")!=-1 && StrContains(classname, weapon, false)!=-1 || StrContains(wepIndexStr, "-1")!=-1 && StrEqual(classname, weapon, false))
					{
						if(isOverride != 3)
						{
							Handle itemOverride = PrepareItemHandle(item, _, _, attributes, isOverride!=1);
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
						static char wepIndexes[768][32];
						weaponIdxcount = ExplodeString(wepIndexStr, " ; ", wepIndexes, sizeof(wepIndexes), 32);
						for(wepIdx=0; wepIdx<=weaponIdxcount; wepIdx++)
						{
							if(!wepIndexes[wepIdx][0])
								continue;

							wepIndex = StringToInt(wepIndexes[wepIdx]);
							if(wepIndex != iItemDefinitionIndex)
								continue;

							switch(isOverride)
							{
								case 3:
								{
									return Plugin_Stop;
								}
								case 2, 1:
								{
									Handle itemOverride = PrepareItemHandle(item, _, _, attributes, isOverride!=1);
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
			else
			{
				break;
			}
		}
		KvGoBack(kvWeaponMods);
	}

	if(cvarHardcodeWep.IntValue > 0)
	{
		switch(iItemDefinitionIndex)
		{
			case 39, 1081:  //Flaregun
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "6 ; 0.67");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 40, 1146:  //Backburner, Festive Backburner
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "170 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 41:  //Natascha
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "32 ; 0 ; 75 ; 1.34");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 43:  //Killing Gloves of Boxing
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "16 ; 50 ; 69 ; 0.2 ; 77 ; 0 ; 109 ; 0.5 ; 177 ; 2 ; 205 ; 0.7 ; 206 ; 0.7 ; 239 ; 0.6 ; 442 ; 1.35 ; 443 ; 1.1 ; 800 ; 0");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 44:  //Sandman
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "773 ; 1.15");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 56, 1005, 1092:  //Huntsman, Festive Huntsman, Fortified Compound
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "76 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 57:  //Razorback
			{
				if(cvarShieldType.IntValue > 1)
				{
					Handle itemOverride = PrepareItemHandle(item, _, _, _, true);
					if(itemOverride != INVALID_HANDLE)
					{
						item = itemOverride;
						return Plugin_Changed;
					}
				}
			}
			case 127:  //Direct Hit
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "179 ; 1.0");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 128:  //Equalizer
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "740 ; 0 ; 239 ; 0.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 129:  //Buff Banner
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "319 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 131, 1144:  //Chargin' Targe
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "396 ; 0.95", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 140, 1086, 30668:  //Wrangler
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "54 ; 0.75 ; 128 ; 1 ; 206 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 153, 466:  //Homewrecker
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "394 ; 3 ; 215 ; 10 ; 522 ; 1 ; 216 ; 10");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 154:  //Pain Train
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "20 ; 1 ; 149 ; 6 ; 204 ; 1 ; 408 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 155:  //Southern Hospitality
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.6 ; 20 ; 1 ; 61 ; 1 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 171:  //Tribalman's Shiv
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "20 ; 1 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 173:  //Vita-Saw
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "125 ; -10 ; 17 ; 0.15 ; 737 ; 1.25", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 220:  //Shortstop
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "868 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 224:  //L'etranger
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "166 ; 5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 231:  //Darwin's Danger Shield
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "26 ; 85 ; 800 ; 0.19 ; 69 ; 0.6 ; 109 ; 0.6", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 232:  //Bushwacka
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "58 ; 1.35");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 237:  //Rocket Jumper
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.3 ; 15 ; 0 ; 135 ; 0.5 ; 206 ; 2 ; 400 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 239, 1084, 1100:  //GRU, Festive GRU, Bread Bite
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 191 ; -7 ; 772 ; 1.5", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 265:  //Sticky Jumper
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.3 ; 15 ; 0 ; 89 ; -6 ; 135 ; 0.5 ; 206 ; 2 ; 280 ; 14 ; 400 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 305, 1079:  //Crusader's Crossbow, Festive Crusader's Crossbow
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "17 ; 0.2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 312:  //Brass Beast
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "206 ; 1.35");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 317:  //Candy Cane
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "740 ; 0.5 ; 239 ; 0.75", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 325, 452, 812, 833:  //Boston Basher, Three-Rune Blade, Flying Guillotine(s)
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "20 ; 1 ; 138 ; 0.67 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 327:  //Claidheamh Mor
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "412 ; 1.2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 329:  //Jag
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "92 ; 1.3 ; 6 ; 0.85 ; 95 ; 0.6 ; 1 ; 0.5 ; 137 ; 1.34", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 331:  //Fists of Steel
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "205 ; 0.65 ; 206 ; 0.65 ; 772 ; 2.0 ; 800 ; 0.6 ; 854 ; 0.6", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 348:  //Sharpened Volcano Fragment
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "16 ; 30 ; 69 ; 0.34 ; 77 ; 0 ; 109 ; 0.5 ; 773 ; 1.5 ; 205 ; 0.8 ; 206 ; 0.6 ; 239 ; 0.67 ; 442 ; 1.15 ; 443 ; 1.15 ; 800 ; 0.34");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 349:  //Sun-on-a-Stick
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.75 ; 795 ; 2", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 351:  //Detonator
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "25 ; 0.5 ; 58 ; 3.2 ; 79 ; 0.75 ; 144 ; 1.0 ; 207 ; 1.33", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 355:  //Fan O'War
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.25 ; 6 ; 0.5 ; 49 ; 1 ; 137 ; 4 ; 107 ; 1.1 ; 201 ; 1.1 ; 77 ; 0.38", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 404:  //Persian Persuader
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "772 ; 1.15 ; 249 ; 0.6 ; 781 ; 1 ; 778 ; 0.5 ; 782 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 405, 608:  //Ali Baba's Wee Booties, Bootlegger
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "26 ; 25 ; 246 ; 3 ; 107 ; 1.10", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 406:  //Splendid Screen
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "248 ; 2.6", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 414:  //Liberty Launcher
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.65 ; 206 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 415:  //Reserve Shooter
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "2 ; 1.1 ; 3 ; 0.5 ; 114 ; 1 ; 179 ; 1 ; 547 ; 0.6", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 416:  //Market Gardener
			{
				Handle itemOverride;
				if(cvarMarket.FloatValue)
				{
					itemOverride = PrepareItemHandle(item, _, _, "5 ; 2");
				}
				else
				{
					itemOverride = PrepareItemHandle(item, _, _, "", true);
				}

				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 426:  //Eviction Notice
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.2 ; 6 ; 0.25 ; 107 ; 1.2 ; 737 ; 2.25", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 441:  //Cow Mangler
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "71 ; 2.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
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
					Handle itemOverride = PrepareItemHandle(item, _, _, "58 ; 1.5");
					if(itemOverride != INVALID_HANDLE)
					{
						item = itemOverride;
						return Plugin_Changed;
					}
				}
				#else
				Handle itemOverride = PrepareItemHandle(item, _, _, "58 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
				#endif
			}
			case 442, 588:  //Bison, Pomson
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "182 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 528:  //Short Circuit
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "20 ; 1 ; 182 ; 2 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 589:  //Eureka Effect
			{
				if(!cvarEnableEurekaEffect.BoolValue)  //Disabled
				{
					Handle itemOverride = PrepareItemHandle(item, _, _, "93 ; 0.75 ; 276 ; 1 ; 790 ; 0.5 ; 732 ; 0.9", true);
					if(itemOverride != INVALID_HANDLE)
					{
						item = itemOverride;
						return Plugin_Changed;
					}
				}
			}
			case 593:  //Third Degree
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "853 ; 0.8 ; 854 ; 0.8");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 595:  //Manmelter
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "6 ; 0.35");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 648:  //Wrap Assassin
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.53 ; 20 ; 1 ; 138 ; 0.67 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 656:  //Holiday Punch
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "178 ; 0.001", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 730:  //Beggar's Bazooka
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "76 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 740:  //Scorch Shot
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "79 ; 0.75");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 772:  //Baby Face's Blaster
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "532 ; 1.2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 775:  //Escape Plan
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "740 ; 0 ; 206 ; 1.5 ; 239 ; 0.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 811, 832:  //Huo-Long Heater
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "71 ; 2.75");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 813, 834:  //Neon Annihilator
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "182 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1099:  //Tide Turner
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "639 ; 50", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1103:  //Back Scatter
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "179 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1104:  //Air Strike
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.82 ; 206 ; 1.25");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1179:  //Thermal Thruster
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "872 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1180:  //Gas Passer
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "875 ; 1 ; 2059 ; 3000");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1181:  //Hot Hand
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "877 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
		}

		if(!StrContains(classname, "tf_weapon_syringegun_medic"))  //Syringe guns
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "17 ; 0.05");
			if(itemOverride != INVALID_HANDLE)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		else if(!StrContains(classname, "tf_weapon_medigun"))  //Medi Gun
		{
			Handle itemOverride;
			switch(iItemDefinitionIndex)
			{
				case 35:
					itemOverride = PrepareItemHandle(item, _, _, "10 ; 2.25 ; 11 ; 1.5 ; 18 ; 1 ; 199 ; 0.75 ; 314 ; 3 ; 547 ; 0.75");

				case 411:  //Quick-Fix
					itemOverride = PrepareItemHandle(item, _, _, "8 ; 1.0 ; 10 ; 2 ; 105 ; 1 ; 144 ; 2 ; 199 ; 0.75 ; 231 ; 2 ; 493 ; 2 ; 547 ; 0.75");

				case 998:  //Vaccinator
					itemOverride = PrepareItemHandle(item, _, _, "10 ; 2.5 ; 11 ; 1.5 ; 199 ; 0.75 ; 314 ; -3 ; 479 ; 0.34 ; 499 ; 1 ; 547 ; 0.75 ; 739 ; 0.34", true);

				default:
					itemOverride = PrepareItemHandle(item, _, _, "10 ; 1.75 ; 11 ; 1.5 ; 144 ; 2.0 ; 199 ; 0.75 ; 547 ; 0.75");
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

	static char weaponAttribsArray[32][32];
	int attribCount = ExplodeString(att, ";", weaponAttribsArray, 32, 32);

	if(attribCount % 2)
		--attribCount;

	int flags = OVERRIDE_ATTRIBUTES;
	if(!dontPreserve)
		flags |= PRESERVE_ATTRIBUTES;

	if(!weapon)	weapon = TF2Items_CreateItem(flags);
	else		TF2Items_SetFlags(weapon, flags);

	if(item != INVALID_HANDLE)
	{
		addattribs = TF2Items_GetNumAttributes(item);
		if(addattribs > 0)
		{
			for(int i; i<2*addattribs; i+=2)
			{
				bool dontAdd;
				int attribIndex = TF2Items_GetAttributeId(item, i);
				for(int z; z<attribCount+i; z+=2)
				{
					if(StringToInt(weaponAttribsArray[z]) == attribIndex)
					{
						dontAdd = true;
						break;
					}
				}

				if(!dontAdd)
				{
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
					FloatToString(TF2Items_GetAttributeValue(item, i), weaponAttribsArray[i+1+attribCount], 32);
				}
			}
			attribCount += 2*addattribs;
		}

		if(weapon != item)  //FlaminSarge: Item might be equal to weapon, so closing item's handle would also close weapon's
			delete item;  //probably returns false but whatever (rswallen-apparently not)
	}

	if(name[0])
	{
		flags |= OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(weapon, name);
	}

	if(index != -1)
	{
		flags |= OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(weapon, index);
	}

	if(attribCount > 0)
	{
		TF2Items_SetNumAttributes(weapon, attribCount/2);
		int i2;
		for(int i; i<attribCount && i2<16; i+=2)
		{
			int attrib = StringToInt(weaponAttribsArray[i]);
			if(!attrib)
			{
				LogToFile(eLog, "[Weapons] Bad weapon attribute passed: %s ; %s", weaponAttribsArray[i], weaponAttribsArray[i+1]);
				delete weapon;
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
	static int civilianCheck[MAXTF2PLAYERS];

	int weapon = GetPlayerWeaponSlot(client, 4);
	if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==60 && (kvWeaponMods == null || cvarHardcodeWep.IntValue>0))  //Cloak and Dagger
	{
		TF2_RemoveWeaponSlot(client, 4);
		FF2_SpawnWeapon(client, "tf_weapon_invis", 60, 1, 0, "35 ; 1.65 ; 728 ; 1 ; 729 ; 0.65");
	}

	for(int i; i<3; i++)
	{
		CritBoosted[client][i] = -1;
	}

	if(bMedieval)
		return Plugin_Continue;

	int slot, index, wepIdx, wepIndex, weaponIdxcount;
	char format[64];
	static char classname[32], wepIndexStr[768], wepIndexes[768][32];
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(weapon))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(index==402 && (kvWeaponMods==null || cvarHardcodeWep.IntValue>0))
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			if(FF2_SpawnWeapon(client, "tf_weapon_sniperrifle", 402, 1, 6, "91 ; 0.5 ; 75 ; 3.75 ; 178 ; 0.8") == -1)
				civilianCheck[client]++;
		}

		GetEntityClassname(weapon, classname, sizeof(classname));
		if(kvWeaponMods!=null && ConfigWeapons)
		{
			for(int i=1; ; i++)
			{
				KvRewind(kvWeaponMods);
				FormatEx(format, sizeof(format), "weapon%i", i);
				if(KvJumpToKey(kvWeaponMods, format))
				{
					KvGetString(kvWeaponMods, "classname", format, sizeof(format));
					KvGetString(kvWeaponMods, "index", wepIndexStr, sizeof(wepIndexStr));
					slot = KvGetNum(kvWeaponMods, "slot", -1);
					if(slot<0 || slot>2)
						slot = 0;

					if(StrContains(wepIndexStr, "-2")!=-1 && StrContains(classname, format, false)!=-1 || StrContains(wepIndexStr, "-1")!=-1 && StrEqual(classname, format, false))
					{
						CritBoosted[client][slot] = KvGetNum(kvWeaponMods, "crits", -1);
						break;
					}

					if(StrContains(wepIndexStr, "-1")==-1 && StrContains(wepIndexStr, "-2")==-1)
					{
						weaponIdxcount = ExplodeString(wepIndexStr, " ; ", wepIndexes, sizeof(wepIndexes), 32);
						for(wepIdx=0; wepIdx<=weaponIdxcount ; wepIdx++)
						{
							if(!wepIndexes[wepIdx][0])
								continue;

							wepIndex = StringToInt(wepIndexes[wepIdx]);
							if(wepIndex != index)
								continue;

							CritBoosted[client][slot] = KvGetNum(kvWeaponMods, "crits", -1);
							break;
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

		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		GetEntityClassname(weapon, classname, sizeof(classname));
		if(kvWeaponMods!=null && ConfigWeapons)
		{
			for(int i=1; ; i++)
			{
				KvRewind(kvWeaponMods);
				FormatEx(format, sizeof(format), "weapon%i", i);
				if(KvJumpToKey(kvWeaponMods, format))
				{
					KvGetString(kvWeaponMods, "classname", format, sizeof(format));
					KvGetString(kvWeaponMods, "index", wepIndexStr, sizeof(wepIndexStr));
					slot = KvGetNum(kvWeaponMods, "slot", -1);
					if(slot<0 || slot>2)
						slot = 1;

					if(StrContains(wepIndexStr, "-2")!=-1 && StrContains(classname, format, false)!=-1 || StrContains(wepIndexStr, "-1")!=-1 && StrEqual(classname, format, false))
					{
						CritBoosted[client][slot] = KvGetNum(kvWeaponMods, "crits", -1);
						break;
					}

					if(StrContains(wepIndexStr, "-1")==-1 && StrContains(wepIndexStr, "-2")==-1)
					{
						weaponIdxcount = ExplodeString(wepIndexStr, " ; ", wepIndexes, sizeof(wepIndexes), 32);
						for(wepIdx=0; wepIdx<=weaponIdxcount ; wepIdx++)
						{
							if(!wepIndexes[wepIdx][0])
								continue;

							wepIndex = StringToInt(wepIndexes[wepIdx]);
							if(wepIndex != index)
								continue;

							CritBoosted[client][slot] = KvGetNum(kvWeaponMods, "crits", -1);
							break;
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
	}
	else
	{
		civilianCheck[client]++;
	}

	int playerBack = FindPlayerBack(client, 57);  //Razorback
	shield[client] = IsValidEntity(playerBack) ? playerBack : 0;
	hadshield[client] = IsValidEntity(playerBack) ? true : false;
	if(IsValidEntity(FindPlayerBack(client, 642)))  //Cozy Camper
		FF2_SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "149 ; 1.5 ; 15 ; 0.0 ; 1 ; 0.75");

	#if defined _tf2attributes_included
	if(tf2attributes && (kvWeaponMods == null || cvarHardcodeWep.IntValue>0))
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
		shieldHP[client] = cvarShieldHealth.FloatValue;
		shDmgReduction[client] = 1.0-cvarShieldResist.FloatValue;
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(weapon))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		GetEntityClassname(weapon, classname, sizeof(classname));
		if(kvWeaponMods!=null && ConfigWeapons)
		{
			for(int i=1; ; i++)
			{
				KvRewind(kvWeaponMods);
				FormatEx(format, 10, "weapon%i", i);
				if(KvJumpToKey(kvWeaponMods, format))
				{
					KvGetString(kvWeaponMods, "classname", format, sizeof(format));
					KvGetString(kvWeaponMods, "index", wepIndexStr, sizeof(wepIndexStr));
					slot = KvGetNum(kvWeaponMods, "slot", -1);
					if(slot<0 || slot>2)
						slot = 2;

					if(StrContains(wepIndexStr, "-2")!=-1 && StrContains(classname, format, false)!=-1 || StrContains(wepIndexStr, "-1")!=-1 && StrEqual(classname, format, false))
					{
						CritBoosted[client][slot] = KvGetNum(kvWeaponMods, "crits", -1);
						break;
					}

					if(StrContains(wepIndexStr, "-1")==-1 && StrContains(wepIndexStr, "-2")==-1)
					{
						weaponIdxcount = ExplodeString(wepIndexStr, " ; ", wepIndexes, sizeof(wepIndexes), 32);
						for(wepIdx=0; wepIdx<=weaponIdxcount ; wepIdx++)
						{
							if(!wepIndexes[wepIdx][0])
								continue;

							wepIndex = StringToInt(wepIndexes[wepIdx]);
							if(wepIndex != index)
								continue;

							CritBoosted[client][slot] = KvGetNum(kvWeaponMods, "crits", -1);
							break;
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
	}
	else
	{
		civilianCheck[client]++;
	}

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
	int entity = MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)
	{
		int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			if(index==131 || index==406 || index==1099 || index==1144)  //Chargin' Targe, Splendid Screen, Tide Turner, Festive Chargin' Targe
				TF2_RemoveWearable(client, entity);
		}
	}
}

stock int RemovePlayerBack(int client, int[] indices, int length)
{
	if(length < 1)
		return;

	int entity = MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		static char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(int i; i<length; i++)
				{
					if(index == indices[i])
						TF2_RemoveWearable(client, entity);
				}
			}
		}
	}
}

stock int FindPlayerBack(int client, int index)
{
	int entity = MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable*"))!=-1)
	{
		static char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrContains(netclass, "CTFWearable")>-1 && GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")==index && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			return entity;
	}
	return -1;
}

public Action OnObjectDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(GetRandomInt(0, 2) || !IsBoss(attacker))
		return Plugin_Continue;

	static char sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_kill_buildable", sound, sizeof(sound), GetBossIndex(attacker)))
		EmitSoundToAllExcept(sound);

	return Plugin_Continue;
}

public void OnUberDeployed(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client) || !IsPlayerAlive(client) || (FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED) || GetBossIndex(client)>=0)
		return;

	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!IsValidEntity(medigun))
		return;

	static char classname[64];
	GetEntityClassname(medigun, classname, sizeof(classname));
	if(!StrEqual(classname, "tf_weapon_medigun"))
		return;

	//TF2_AddCondition(client, TFCond_UberchargedCanteen, 0.5);
	TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5, client);
	int target = GetHealingTarget(client);
	if(IsValidClient(target, false) && IsPlayerAlive(target))
	{
		//TF2_AddCondition(client, TFCond_UberchargedCanteen, 0.5);
		TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
		uberTarget[client] = target;
	}
	else
	{
		uberTarget[client] = -1;
	}
	CreateTimer(0.4, Timer_Uber, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
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
				//TF2_AddCondition(client, TFCond_UberchargedCanteen, 0.5);
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5);
				if(IsValidClient(target, false) && IsPlayerAlive(target))
				{
					//TF2_AddCondition(client, TFCond_UberchargedCanteen, 0.5);
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

	if(CheckRoundState()!=1 || cvarHealthHud.IntValue>1)
		return Plugin_Handled;

	Command_GetHP(client);
	return Plugin_Handled;
}

public Action Command_GetHP(int client)  //TODO: This can rarely show a very large negative number if you time it right
{
	if(IsBoss(client) || GetGameTime()>=HPTime)
	{
		char[][] text = new char[MaxClients+1][512];
		static char name[64];
		bool multi;
		for(int boss; boss<=MaxClients; boss++)
		{
			if(IsValidClient(Boss[boss]))
			{
				char lives[8];
				if(BossLives[boss] > 1)
					FormatEx(lives, sizeof(lives), "x%i", BossLives[boss]);

				for(int target; target<=MaxClients; target++)
				{
					if(IsValidClient(target))
					{
						GetBossSpecial(Special[boss], name, sizeof(name), target);
						Format(text[target], 512, "%s\n%t", multi ? text[target] : "", "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
						FPrintToChat(target, "%t", "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
					}
				}
				multi = true;
				BossHealthLast[boss] = BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			}
		}

		if((IsPlayerAlive(client) || IsClientObserver(client)) && !HudSettings[client][4] && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
		{
			for(int target; target<=MaxClients; target++)
			{
				if(IsValidClient(target))
				{
					if(bosses<2 && cvarGameText.IntValue>0)
					{
						if(BossIcon[0])
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
		}

		if(GetGameTime() >= HPTime)
		{
			healthcheckused++;
			HPTime = GetGameTime()+(healthcheckused<3 ? 20.0 : 80.0);
		}
		return Plugin_Continue;
	}

	static char waitTime[128];
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
	static char boss[64];
	if(args < 1)
	{
		if(!IsValidClient(client))
		{
			ReplyToCommand(client, "[SM] Usage: ff2_special <boss>");
			return Plugin_Handled;
		}

		GetBossSpecial(Incoming[0], boss, sizeof(boss), client);

		Menu menu = new Menu(Command_SetNextBossH);
		menu.SetTitle("Override Next Boss\n  Current Selection: %s", boss);

		strcopy(boss, sizeof(boss), "No Override");
		menu.AddItem(boss, boss);

		for(int config; config<Specials; config++)
		{
			GetBossSpecial(config, boss, sizeof(boss), client);
			menu.AddItem(boss, boss);
		}

		menu.ExitButton = true;
		menu.Display(client, 20);
		return Plugin_Handled;
	}

	static char name[64];
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

public int Command_SetNextBossH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			switch(choice)
			{
				case 0:
				{
					Incoming[0] = 0;
					FReplyToCommand(client, "No override to the next boss");
				}
				default:
				{
					int choice2 = choice-1;
					Incoming[0] = choice2;
					static char boss[64];
					GetBossSpecial(choice2, boss, sizeof(boss), client);
					FReplyToCommand(client, "Set the next boss to %s", boss);
				}
			}
		}
	}
}

public Action Command_Points(int client, int args)
{
	if(args != 2)
	{
		FReplyToCommand(client, "Usage: ff2_addpoints <target> <points>");
		return Plugin_Handled;
	}

	static char stringPoints[8], pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, stringPoints, sizeof(stringPoints));
	int points = StringToInt(stringPoints);

	static char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches > 1)
	{
		for(int target; target<matches; target++)
		{
			if(IsClientSourceTV(targets[target]) || IsClientReplay(targets[target]))
				continue;

			QueuePoints[targets[target]] += points;
			LogAction(client, targets[target], "\"%L\" added %d queue points to \"%L\"", client, points, targets[target]);
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
			static char pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			static char targetName[MAX_TARGET_LENGTH];
			int targets[MAXPLAYERS], matches;
			bool targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches > 1)
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
	if(!Enabled2)
		return Plugin_Handled;

	if(args)
	{
		static char pattern[MAX_TARGET_LENGTH];
		GetCmdArg(1, pattern, sizeof(pattern));
		static char targetName[MAX_TARGET_LENGTH];
		int targets[MAXPLAYERS], matches;
		bool targetNounIsMultiLanguage;
		if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
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
		return Plugin_Handled;
	}

	StopMusic(_, true);
	FReplyToCommand(client, "Stopped boss music for all clients.");
	return Plugin_Handled;
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

		Menu menu = new Menu(Command_CharsetH);
		menu.SetTitle("Charset");

		static char config[PLATFORM_MAX_PATH], charset[64];
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

		Handle Kv = CreateKeyValues("");
		FileToKeyValues(Kv, config);
		int total;
		do
		{
			total++;
			KvGetSectionName(Kv, charset, sizeof(charset));
			menu.AddItem(charset, charset);
		}
		while(KvGotoNextKey(Kv));
		delete Kv;

		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}

	static char charset[32], rawText[16][16];
	GetCmdArgString(charset, sizeof(charset));
	int amount = ExplodeString(charset, " ", rawText, 16, 16);
	for(int i; i<amount; i++)
	{
		StripQuotes(rawText[i]);
	}
	ImplodeStrings(rawText, amount, " ", charset, sizeof(charset));

	static char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(int i; ; i++)
	{
		KvGetSectionName(Kv, config, sizeof(config));
		if(StrContains(config, charset, false) >= 0)
		{
			FReplyToCommand(client, "Charset for nextmap is %s", config);
			isCharSetSelected = true;
			cvarCharset.IntValue = i;
			break;
		}

		if(!KvGotoNextKey(Kv))
		{
			FReplyToCommand(client, "Charset not found");
			break;
		}
	}
	delete Kv;
	return Plugin_Handled;
}

public int Command_CharsetH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			cvarCharset.IntValue = choice;

			static char nextmap[32];
			cvarNextmap.GetString(nextmap, sizeof(nextmap));
			menu.GetItem(choice, FF2CharSetString, sizeof(FF2CharSetString));
			FPrintToChat(client, "%t", "nextmap_charset", nextmap, FF2CharSetString);
			isCharSetSelected = true;
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

		Menu menu = new Menu(Command_LoadCharsetH);
		menu.SetTitle("Charset");

		static char config[PLATFORM_MAX_PATH], charset[64];
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

		Handle Kv = CreateKeyValues("");
		FileToKeyValues(Kv, config);
		int total;
		do
		{
			total++;
			KvGetSectionName(Kv, charset, sizeof(charset));
			menu.AddItem(charset, charset);
		}
		while(KvGotoNextKey(Kv));
		delete Kv;

		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}

	static char charset[32], rawText[16][16];
	GetCmdArgString(charset, sizeof(charset));
	int amount=ExplodeString(charset, " ", rawText, 16, 16);
	for(int i; i<amount; i++)
	{
		StripQuotes(rawText[i]);
	}
	ImplodeStrings(rawText, amount, " ", charset, sizeof(charset));

	static char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(int i; ; i++)
	{
		KvGetSectionName(Kv, config, sizeof(config));
		if(StrContains(config, charset, false) >= 0)
		{
			cvarCharset.IntValue = i;
			LoadCharset = true;
			if(!CheckRoundState() || CheckRoundState()==1)
			{
				FReplyToCommand(client, "The current character set is set to be switched to %s!", config);
				return Plugin_Handled;
			}

			FReplyToCommand(client, "Character set has been switched to %s", config);
			FindCharacters();
			FF2CharSetString[0] = 0;
			LoadCharset = false;
			break;
		}

		if(!KvGotoNextKey(Kv))
		{
			FReplyToCommand(client, "Charset not found");
			break;
		}
	}
	delete Kv;
	return Plugin_Handled;
}

public int Command_LoadCharsetH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			cvarCharset.IntValue = choice;
			LoadCharset = true;
			if(!CheckRoundState() || CheckRoundState()==1)
			{
				FReplyToCommand(client, "The current character set is set to be switched!");
			}
			else
			{
				FReplyToCommand(client, "Character set has been switched");
				FindCharacters();
				FF2CharSetString[0] = 0;
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
	if(!CheckRoundState() || CheckRoundState()==1)
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
	if(!CheckRoundState() || CheckRoundState()==1)
	{
		FReplyToCommand(client, "Current character set is set to reload!");
		return Plugin_Handled;
	}
	FReplyToCommand(client, "Current character set has been reloaded!");
	FindCharacters();
	FF2CharSetString[0] = 0;
	LoadCharset = false;
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
	if(!CheckRoundState() || CheckRoundState()==1)
	{
		FReplyToCommand(client, "%s is set to reload!", WeaponCFG);
		return Plugin_Handled;
	}
	FReplyToCommand(client, "%s has been reloaded!", WeaponCFG);
	CacheWeapons();
	ReloadWeapons = false;
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
	if(!CheckRoundState() || CheckRoundState()==1)
	{
		FReplyToCommand(client, "All configs are set to be reloaded!");
		return Plugin_Handled;
	}
	CacheWeapons();
	CacheDifficulty();
	CheckToChangeMapDoors();
	CheckToTeleportToSpawn();
	FindCharacters();
	FF2CharSetString[0] = 0;
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

	static char pluginName[PLATFORM_MAX_PATH];
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
	int controlPoint = MaxClients+1;
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
	int entity = -1;
	if((entity=FindEntityByClassname2(-1, "tf_logic_arena"))!=-1 && IsValidEntity(entity))
	{
		static char timeString[32];
		FloatToString(time, timeString, sizeof(timeString));
		DispatchKeyValue(entity, "CapEnableDelay", timeString);
	}
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	if(part == AdminCache_Overrides)
		CheckDuoMin();
}

public void OnClientPostAdminCheck(int client)
{
	// TODO: Hook these inside of EnableFF2() or somewhere instead
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

	FF2flags[client] = 0;
	Damage[client] = 0;
	uberTarget[client] = -1;
	xIncoming[client][0] = 0;
	dIncoming[client][0] = 0;
	CanBossVs[client] = 0;
	CanBossTeam[client] = 0;
	IgnoreValid[client] = false;

	if(AreClientCookiesCached(client))
	{
		static char buffer[24];
		GetClientCookie(client, FF2Cookies, buffer, sizeof(buffer));
		if(!buffer[0])
			SetClientCookie(client, FF2Cookies, "0 1 1 1 0 0 0 3");
			//Queue points | music exception | voice exception | class info | companion toggle | boss toggle | special toggle | UNUSED

		GetClientCookie(client, StatCookies, buffer, sizeof(buffer));
		if(!buffer[0])
			SetClientCookie(client, StatCookies, "0 0 0 0 0 0 0 0");
			//Boss wins | boss losses | boss kills | boss deaths | player kills | player MVPs | UNUSED | UNUSED

		GetClientCookie(client, HudCookies, buffer, sizeof(buffer));
		if(!buffer[0])
			SetClientCookie(client, HudCookies, "0 0 0 0 0 0 0 0");
			//Damage | extra | messages | countdown | boss health | UNUSED | UNUSED | UNUSED

		SetupClientCookies(client);
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
	if(IsBoss(client) && !CheckRoundState() && cvarPreroundBossDisconnect.BoolValue)
	{
		int boss = GetBossIndex(client);
		bool[] omit = new bool[MaxClients+1];
		omit[client] = true;
		Boss[boss] = GetClientWithoutBlacklist(omit, BossSwitched[boss] ? BossTeam : OtherTeam);
		HasEquipped[boss] = false;
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

	if(IsBoss(client) && (!CheckRoundState() || CheckRoundState()==1))
		AddClientStats(client, Cookie_BossLosses, 1);

	if(Enabled && IsClientInGame(client) && IsPlayerAlive(client) && CheckRoundState()==1)
		CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);

	FF2flags[client] = 0;
	Damage[client] = 0;
	uberTarget[client] = -1;
	xIncoming[client][0] = 0;
	dIncoming[client][0] = 0;
	CanBossVs[client] = 0;
	SaveClientStats(client);
	SaveClientPreferences(client);

	CheckDuoMin();

	if(MusicTimer[client] != null)
	{
		delete MusicTimer[client];
	}
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;

	if(CheckRoundState() == 1)
		CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client))
		return Plugin_Continue;

	LastAliveClass[client] = TF2_GetPlayerClass(client);
	for(int i; i<3; i++)
	{
		CritBoosted[client][i] = -1;
	}
	return Plugin_Continue;
}

public Action OnPostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;

	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client))
		return Plugin_Continue;

	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");

	if(IsBoss(client))
	{
		int boss = GetBossIndex(client);
		HasEquipped[boss] = false;
		CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
	}

	if(!(FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		if(!(FF2flags[client] & FF2FLAG_HASONGIVED))
		{
			FF2flags[client] |= FF2FLAG_HASONGIVED;
			RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
			RemovePlayerTarge(client);
			TF2_RemoveAllWeapons(client);
			TF2_RegeneratePlayer(client);
			CreateTimer(0.1, Timer_RegenPlayer, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
		CreateTimer(0.2, Timer_MakeNotBoss, userid, TIMER_FLAG_NO_MAPCHANGE);
	}

	FF2flags[client] &= ~(FF2FLAG_UBERREADY|FF2FLAG_ISBUFFED|FF2FLAG_TALKING|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_USINGABILITY|FF2FLAG_CLASSHELPED|FF2FLAG_CHANGECVAR|FF2FLAG_ROCKET_JUMPING);
	FF2flags[client] |= FF2FLAG_USEBOSSTIMER|FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
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

	int client = 1;
	#if defined _tf2attributes_included
	if(tf2attributes && cvarDisguise.BoolValue)
	{
		int iDisguisedTarget;
		for(; client<=MaxClients; client++)
		{
			//custom model disguise code sorta taken from stop that tank, let's see how well this goes!
			//this will actually let spies disguise as the boss, and bosses should have the same disguise
			//model as the players they potentially disguise as if they have a custom model (tf2attributes required)
			if(IsValidClient(client))
			{
				iDisguisedTarget = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
				VisionFlags_Update(client);

				if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && IsValidClient(iDisguisedTarget) && TF2_GetPlayerClass(iDisguisedTarget)==view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass")))
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

	int observer, index;
	int best[10];
	int SapperAmount;
	bool SapperEnabled = SapperMinion;
	for(client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client))
			continue;

		if(IsBoss(client))
		{
			if(!SapperEnabled)
				SapperEnabled = SapperBoss[client];

			continue;
		}

		if(Enabled3 || Damage[client]<1)
			continue;

		for(observer=0; observer<10; observer++)
		{
			if(best[observer] && Damage[client]<Damage[best[observer]])
				continue;

			index = 9;
			while(index > observer)
			{
				best[index] = best[--index];
			}
			best[observer] = client;
			break;
		}
	}

	char bestHud[10][48];
	if(!Enabled3)
	{
		for(index=0; index<10; index++)
		{
			if(!best[index])
				break;

			FormatEx(bestHud[index], sizeof(bestHud[]), "[%i] %N: %i", index+1, best[index], Damage[best[index]]);
		}
	}

	char top[384];
	static char classname[64];
	TFCond cond;
	bool alive, validwep;
	int weapon, buttons;
	int StatHud = cvarStatHud.IntValue;
	int HealHud = cvarHealingHud.IntValue;
	float LookHud = cvarLookHud.FloatValue;
	for(client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || IsBoss(client) || (FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED))
			continue;

		alive = IsPlayerAlive(client);
		if(!Enabled3 && alive && TimerMode && GetClientTeam(client)==BossTeam)
			continue;

		SetGlobalTransTarget(client);
		buttons = GetClientButtons(client);
		if((alive || IsClientObserver(client)) && !HudSettings[client][0] && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE))
		{
			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
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

				if(observer)
					GetClientName(observer, classname, sizeof(classname));
			}
			else if(IsClientObserver(client))
			{
				observer = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if(!IsValidClient(observer) || observer==client)
				{
					observer = 0;
				}
				else
				{
					GetClientName(observer, classname, sizeof(classname));
				}
			}

			if(StatHud>-1 && (CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>0))
			{
				if((CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>1) && (LookHud!=0 || !alive))
				{
					if((Healing[client]>0 && HealHud==1) || HealHud>1)
					{
						FormatEx(top, sizeof(top), "%t", "Self Stats Healing", Damage[client], Healing[client], PlayerKills[client], PlayerMVPs[client]);
					}
					else
					{
						FormatEx(top, sizeof(top), "%t", "Self Stats", Damage[client], PlayerKills[client], PlayerMVPs[client]);
					}
				}
				else
				{
					if((Healing[client]>0 && HealHud==1) || HealHud>1)
					{
						FormatEx(top, sizeof(top), "%t", "Stats Healing", Damage[client], Healing[client], PlayerKills[client], PlayerMVPs[client]);
					}
					else
					{
						FormatEx(top, sizeof(top), "%t", "Stats", Damage[client], PlayerKills[client], PlayerMVPs[client]);
					}
				}
			}
			else
			{
				if(IsValidClient(observer) && !IsBoss(observer))
				{
					if((Healing[client]>0 && HealHud==1) || HealHud>1)
					{
						FormatEx(top, sizeof(top), "%t %t | ", "Your Damage Dealt", Damage[client], "Healing", Healing[client]);
					}
					else
					{
						FormatEx(top, sizeof(top), "%t | ", "Your Damage Dealt", Damage[client]);
					}
				}
				else
				{
					if((Healing[client]>0 && HealHud==1) || HealHud>1)
					{
						FormatEx(top, sizeof(top), "%t %t", "Your Damage Dealt", Damage[client], "Healing", Healing[client]);
					}
					else
					{
						FormatEx(top, sizeof(top), "%t", "Your Damage Dealt", Damage[client]);
					}
				}
			}

			if(IsValidClient(observer))
			{
				if(StatHud>-1 && (CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>1))
				{
					if(IsBoss(observer))
					{
						ShowSyncHudText(client, statHUD, "%s%t", top, "Player Stats Boss", classname, BossWins[observer], BossLosses[observer], BossKills[observer], BossDeaths[observer]);
					}
					else if((Healing[observer]>0 && HealHud==1) || HealHud>1)
					{
						ShowSyncHudText(client, statHUD, "%s%t", top, "Player Stats Healing", classname, Damage[observer], Healing[observer], PlayerKills[observer], PlayerMVPs[observer]);
					}
					else
					{
						ShowSyncHudText(client, statHUD, "%s%t", top, "Player Stats", classname, Damage[observer], PlayerKills[observer], PlayerMVPs[observer]);
					}
				}
				else if(!IsBoss(observer))
				{
					if((Healing[observer]>0 && HealHud==1) || HealHud>1)
					{
						ShowSyncHudText(client, statHUD, "%s%t", top, "Spectator Damage Dealt", classname, Damage[observer], "Healing", Healing[observer]);
					}
					else
					{
						ShowSyncHudText(client, statHUD, "%s%t", top, "Spectator Damage Dealt", classname, Damage[observer]);
					}
				}
				else
				{
					ShowSyncHudText(client, statHUD, top);
				}
			}
			else
			{
				ShowSyncHudText(client, statHUD, top);
			}
		}

		if((ShowHealthText || HudSettings[client][2]) && !Enabled3 && HudSettings[client][HUDTYPES-1]!=1 && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE))
		{
			index = HudSettings[client][HUDTYPES-1];
			if(index < 1)
				index = cvarDamageHud.IntValue;

			if(index > 2)
			{
				strcopy(top, sizeof(top), bestHud[0]);
				for(int i=1; i<index && i<10; i++)
				{
					Format(top, sizeof(top), "%s\n%s", top, bestHud[i]);
				}

				if(LastAliveClass[client] == TFClass_Engineer)
				{
					SetHudTextParams(0.0, 0.35, 0.35, 200, 255, 200, 255, 0, 0.35, 0.0, 0.1);
				}
				else
				{
					SetHudTextParams(0.0, 0.0, 0.35, 200, 255, 200, 255, 0, 0.35, 0.0, 0.1);
				}

				ShowSyncHudText(client, infoHUD, top);
			}
		}

		if(!alive)
			continue;

		TFClassType class = TF2_GetPlayerClass(client);
		weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(weapon<=MaxClients || !IsValidEntity(weapon) || !GetEntityClassname(weapon, classname, sizeof(classname)))
			classname[0] = 0;

		validwep = !StrContains(classname, "tf_weapon", false);

		index = (validwep ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
		if((FF2flags[client] & FF2FLAG_ISBUFFED) && !(GetEntProp(client, Prop_Send, "m_bRageDraining")))
		{
			FF2flags[client] &= ~FF2FLAG_ISBUFFED;
		}
		else if(HudSettings[client][1] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (buttons & IN_SCORE))
		{
		}
		else if(class==TFClass_Spy && SapperEnabled && SapperCooldown[client]>0.0)
		{
			SapperAmount = RoundToFloor((SapperCooldown[client]-cvarSapperCooldown.FloatValue)*(Pow(cvarSapperCooldown.FloatValue, -1.0)*-100.0));
			if(SapperAmount < 0)
				SapperAmount = 0;

			SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0);
			ShowSyncHudText(client, jumpHUD, "%t", "Sapper Cooldown", SapperAmount);
		}
		else if(shield[client] && (cvarShieldType.IntValue==3 || cvarShieldType.IntValue==4))
		{
			SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0);
			ShowSyncHudText(client, jumpHUD, "%t", "Shield HP", RoundToFloor(shieldHP[client]/cvarShieldHealth.FloatValue*100.0));
		}
		else if(cvarDeadRingerHud.BoolValue && GetClientCloakIndex(client)==59)
		{
			if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				SetHudTextParams(-1.0, 0.83, 0.35, 255, 64, 64, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, jumpHUD, "%t", "Dead Ringer Active");
			}
			else if(GetEntProp(client, Prop_Send, "m_bFeignDeathReady"))
			{
				SetHudTextParams(-1.0, 0.83, 0.35, 90, 255, 90, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, jumpHUD, "%t", "Dead Ringer Ready");
			}
			else
			{
				SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, jumpHUD, "%t", "Dead Ringer Inactive");
			}
		}

		int aliveTeammates = Enabled3 ? BossAlivePlayers+MercAlivePlayers-1 : MercAlivePlayers;

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

		aliveTeammates = Enabled3 ? GetClientTeam(client)==OtherTeam ? MercAlivePlayers : BossAlivePlayers : MercAlivePlayers;

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

		SetClientGlow(client, -0.2);

		if(Enabled3 || bMedieval)
			continue;

		cond = TFCond_HalloweenCritCandy;
		if(TF2_IsPlayerInCondition(client, TFCond_CritCola) && (class==TFClass_Scout || class==TFClass_Sniper))
		{
			TF2_AddCondition(client, cond, 0.3);
			continue;
		}

		int healer = -1;
		for(int healtarget=1; healtarget<=MaxClients; healtarget++)
		{
			if(IsValidClient(healtarget) && IsPlayerAlive(healtarget) && GetHealingTarget(healtarget, true)==client)
			{
				healer = healtarget;
				break;
			}
		}

		bool addthecrit;
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Stealthed))
		{
			addthecrit = false;
		}
		else if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Melee))
		{
			switch(CritBoosted[client][2])
			{
				case -1:
				{
					if(index==416 && cvarMarket.FloatValue)  //Market Gardener
					{
						addthecrit = FF2flags[client] & FF2FLAG_ROCKET_JUMPING ? true : false;
					}
					else if(index==44 || index==656 || !StrContains(classname, "tf_weapon_knife", false))  //Sandman, Holiday Punch, Knives
					{
						addthecrit = false;
					}
					else if(index == 307)	//Ullapool Caber
					{
						addthecrit = GetEntProp(weapon, Prop_Send, "m_iDetonated") ? false : true;
					}
					else
					{
						addthecrit = true;
					}
				}
				case 1:
				{
						addthecrit = true;
						if(cond == TFCond_HalloweenCritCandy)
							cond = TFCond_Buffed;
				}
				case 2:
				{
					addthecrit = true;
				}
			}
		}
		else if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
		{
			switch(CritBoosted[client][1])
			{
				case -1:
				{
					if(!StrContains(classname, "tf_weapon_smg"))  //SMGs
					{
						if(index!=16 || !IsValidEntity(FindPlayerBack(client, 642)) || SniperClimbDelay<=0)	//Nerf Cozy Camper SMGs if Wall Climb is on
						{
							addthecrit = true;
							if(cond == TFCond_HalloweenCritCandy)
								cond = TFCond_Buffed;
						}
					}
					else if(!StrContains(classname, "tf_weapon_cleaver") ||
						!StrContains(classname, "tf_weapon_mechanical_arm") ||
						!StrContains(classname, "tf_weapon_raygun"))  //Cleaver, Short Circuit, Righteous Bison
					{
						addthecrit = true;
					}
					else if(class==TFClass_Scout &&
					       (!StrContains(classname, "tf_weapon_pistol") ||
						!StrContains(classname, "tf_weapon_handgun_scout_secondary")))	//Scout Pistols
					{
						addthecrit = true;
						if(cond == TFCond_HalloweenCritCandy)
							cond = TFCond_Buffed;
					}
				}
				case 1:
				{
					addthecrit = true;
					if(cond == TFCond_HalloweenCritCandy)
						cond = TFCond_Buffed;
				}
				case 2:
				{
					addthecrit = true;
				}
			}
		}
		else if(validwep && weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
		{
			switch(CritBoosted[client][0])
			{
				case -1:
				{
					if(!StrContains(classname, "tf_weapon_compound_bow"))  //Huntsmans
					{
						if(BowDamageNon <= 0)	//If non-crit boosted damage cvar is off
						{
							addthecrit = true;
							if(cond==TFCond_HalloweenCritCandy && BowDamageMini>0)	//If mini-crit boosted damage cvar is on
								cond = TFCond_Buffed;
						}
					}
					else if(!StrContains(classname, "tf_weapon_revolver"))  //Revolver
					{
						addthecrit = true;
						if(cond == TFCond_HalloweenCritCandy)
							cond = TFCond_Buffed;
					}
					else if(!StrContains(classname, "tf_weapon_crossbow") || !StrContains(classname, "tf_weapon_drg_pomson"))  //Crusader's Crossbow, Pomson 6000
					{
						addthecrit = true;
					}
				}
				case 1:
				{
					addthecrit = true;
					if(cond == TFCond_HalloweenCritCandy)
						cond = TFCond_Buffed;
				}
				case 2:
				{
					addthecrit = true;
				}
			}
		}

		switch(class)
		{
			case TFClass_Medic:
			{
				int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
				if(IsValidEntity(medigun))
				{
					int charge = RoundToFloor(GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")*100);
					char mediclassname[64];
					if(weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
					{
						if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
						{
							if(!HudSettings[client][1] && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE))
							{
								SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
								ShowSyncHudText(client, jumpHUD, "%t", "uber-charge", charge);
							}

							if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
							{
								FakeClientCommandEx(client, "voicemenu 1 7");
								FF2flags[client] |= FF2FLAG_UBERREADY;
							}
						}
					}
					else if(weapon == GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary))
					{
						if(IsValidEntity(medigun) && GetEntityClassname(medigun, mediclassname, sizeof(mediclassname)) && !StrContains(mediclassname, "tf_weapon_medigun", false))
						{
							if(charge==100 && !(FF2flags[client] & FF2FLAG_UBERREADY))
								FF2flags[client] |= FF2FLAG_UBERREADY;
						}
					}
				}
			}
			case TFClass_DemoMan:
			{
				if(CritBoosted[client][0]==-1 &&
				   weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) &&
				  !IsValidEntity(GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary)) &&
				   shieldCrits)  //Demoshields
				{
					addthecrit = true;
					if(shieldCrits == 1)
						cond = TFCond_CritCola;
				}
			}
			case TFClass_Spy:
			{
				if(validwep &&
				   weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) &&
				  !TF2_IsPlayerInCondition(client, TFCond_Cloaked) &&
				   TF2_IsPlayerInCondition(client, TFCond_Disguised) &&
				  !TF2_IsPlayerInCondition(client, TFCond_Stealthed) &&
				   index==460)
					TF2_AddCondition(client, TFCond_CritOnDamage, 0.3);
			}
			case TFClass_Engineer:
			{
				if(validwep &&
				   weapon==GetPlayerWeaponSlot(client, TFWeaponSlot_Primary) &&
				   StrEqual(classname, "tf_weapon_sentry_revenge", false))
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
	if(!tf2attributes || !cvarDisguise.BoolValue)
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

	static char strPlayerModel[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", strPlayerModel, sizeof(strPlayerModel));
	static char strEnemyModel[128];
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

	int client, observer, buttons, target, aliveTeammates;
	bool validBoss;
	int StatHud = cvarStatHud.IntValue;
	int HealHud = cvarHealingHud.IntValue;
	static char sound[PLATFORM_MAX_PATH];
	for(int boss; boss<=MaxClients; boss++)
	{
		client = Boss[boss];
		if(!IsValidClient(client) || !(FF2flags[client] & FF2FLAG_USEBOSSTIMER))
			continue;

		buttons = GetClientButtons(client);
		if(GetClientTeam(client) != (BossSwitched[boss] ? OtherTeam : BossTeam))
		{
			TF2_ChangeClientTeam(client, BossSwitched[boss] ? view_as<TFTeam>(OtherTeam) : view_as<TFTeam>(BossTeam));
		}

		if(!IsPlayerAlive(client))
		{
			if(!IsClientObserver(client) || HudSettings[client][0] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (buttons & IN_SCORE))
				continue;

			observer = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if(!IsValidClient(observer) || observer==client)
			{
				observer = 0;
			}
			else
			{
				GetClientName(observer, sound, sizeof(sound));
			}

			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255);
			if(StatHud<0 || (!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<1))
			{
				if(observer && !IsBoss(observer))
				{
					if((Healing[observer]>0 && HealHud==1) || HealHud>1)
					{
						ShowSyncHudText(client, statHUD, "%t %t", "Spectator Damage Dealt", sound, Damage[observer], "Healing", Healing[observer]);
					}
					else
					{
						ShowSyncHudText(client, statHUD, "%t", "Spectator Damage Dealt", sound, Damage[observer]);
					}
				}
			}
			else if(observer && IsBoss(observer))
			{
				if(!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<2)
				{
					ShowSyncHudText(client, statHUD, "%t", "Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client]);
				}
				else
				{
					ShowSyncHudText(client, statHUD, "%t%t", "Self Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client], "Player Stats Boss", sound, BossWins[observer], BossLosses[observer], BossKillsF[observer], BossDeaths[observer]);
				}
			}
			else if(observer)
			{
				if((Healing[observer]>0 && HealHud==1) || HealHud>1)
				{
					if(!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<2)
					{
						ShowSyncHudText(client, statHUD, "%t\n%t %t", "Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client], "Spectator Damage Dealt", sound, Damage[observer], "Healing", Healing[observer]);
					}
					else
					{
						ShowSyncHudText(client, statHUD, "%t%t", "Self Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client], "Player Stats Healing", sound, Damage[observer], Healing[observer], PlayerKills[observer], PlayerMVPs[observer]);
					}
				}
				else
				{
					if(!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<2)
					{
						ShowSyncHudText(client, statHUD, "%t\n%t", "Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client], "Spectator Damage Dealt", sound, Damage[observer]);
					}
					else
					{
						ShowSyncHudText(client, statHUD, "%t%t", "Self Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client], "Player Stats", sound, Damage[observer], PlayerKills[observer], PlayerMVPs[observer]);
					}
				}
			}
			else if(StatHud>-1 && (CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>0))
			{
				ShowSyncHudText(client, statHUD, "%t", "Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client]);
			}
			continue;
		}

		if(!HudSettings[client][0] && StatHud>-1 && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE) && (StatHud>0 || CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true)))
		{
			SetHudTextParams(-1.0, 0.99, 0.35, 90, 255, 90, 255);
			ShowSyncHudText(client, statHUD, "%t", "Stats Boss", BossWins[client], BossLosses[client], BossKillsF[client], BossDeaths[client]);
		}

		validBoss = true;

		if(BossSpeed[Special[boss]] > 0)	// Above 0, uses the classic FF2 method
		{
			SetEntPropFloat(client, Prop_Data, "m_flMaxspeed", BossSpeed[Special[boss]]+0.7*(100-BossHealth[boss]*100/BossLivesMax[boss]/BossHealthMax[boss]));
		}
		else if(!BossSpeed[Special[boss]] && GetEntityMoveType(client)!=MOVETYPE_NONE) // Is 0, freeze movement (some uses)
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
		}
		// Below 0, TF2's default speeds and whatever attributes or conditions

		if(BossHealth[boss]<1 && IsPlayerAlive(client))  // In case the boss hits a hazard and goes into neagtive numbers
			BossHealth[boss] = 1;

		if(BossLivesMax[boss]>1 && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE))
		{
			SetHudTextParams(-1.0, 0.77, 0.15, 255, 255, 255, 255);
			ShowSyncHudText(client, livesHUD, "%t", "Boss Lives Left", BossLives[boss], BossLivesMax[boss]);
		}

		if(BossRageDamage[boss] < 2)	// When RAGE is infinite
			BossCharge[boss][0] = 100.0;

		if(BossRageDamage[boss] > 99998)	// When RAGE is disabled
		{
			BossCharge[boss][0] = 0.0;	// We don't want things like Sydney Sleeper acting up
		}
		else if(RoundFloat(BossCharge[boss][0]) == 100.0)
		{
			if(IsFakeClient(client) && !(FF2flags[client] & FF2FLAG_BOTRAGE) && cvarBotRage.BoolValue)
			{
				CreateTimer(1.0, Timer_BotRage, boss, TIMER_FLAG_NO_MAPCHANGE);
				FF2flags[client] |= FF2FLAG_BOTRAGE;
			}
			else
			{
				if(!(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE))
				{
					SetHudTextParams(-1.0, 0.83, 0.15, 255, 64, 64, 255);
					ShowSyncHudText(client, rageHUD, "%t", "do_rage");
				}

				if(RandomSound("sound_full_rage", sound, sizeof(sound), boss) && emitRageSound[boss])
				{
					static float position[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

					FF2flags[client] |= FF2FLAG_TALKING;
					EmitSoundToAllExcept(sound);

					for(target=1; target<=MaxClients; target++)
					{
						if(IsClientInGame(target) && target!=client && ToggleVoice[target])
							EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
					}
					FF2flags[client] &= ~FF2FLAG_TALKING;
					emitRageSound[boss] = false;
				}
			}
		}
		else if(!(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE))	// RAGE is not infinite, disabled, full
		{
			SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255);
			ShowSyncHudText(client, rageHUD, "%t", "rage_meter", RoundFloat(BossCharge[boss][0]));
		}

		SetClientGlow(client, -0.2);

		for(target=1; target<4; target++)
		{
			ActivateAbilitySlot(boss, target, true);
		}

		aliveTeammates = Enabled3 ? BossAlivePlayers+MercAlivePlayers-1 : MercAlivePlayers;

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

		if(aliveTeammates<2 && cvarHealthHud.IntValue<2 && (bosses>1 || Enabled3 || !cvarGameText.IntValue || !executed2))
		{
			char message[MAXTF2PLAYERS][512], name[64];
			for(int boss2; boss2<=MaxClients; boss2++)
			{
				if(IsValidClient(Boss[boss2]))
				{
					char bossLives[8];
					if(BossLives[boss2] > 1)
						FormatEx(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);

					for(int clients; clients<=MaxClients; clients++)
					{
						if(IsValidClient(clients))
						{
							GetBossSpecial(Special[boss2], name, sizeof(name), clients);
							Format(message[clients], sizeof(message[]), "%s\n%t", message[clients], "ff2_hp", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives);
						}
					}
				}
			}

			for(target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && (IsPlayerAlive(client) || IsClientObserver(client)) && !HudSettings[client][4] && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					if(bosses<2 && cvarGameText.IntValue>0)
					{
						if(BossIcon[0])
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

		for(target=0; target<=MaxClients; target++)
		{
			if(KSpreeTimer[target] > 0)
				KSpreeTimer[target] -= 0.2;
		}
	}

	if(!validBoss)
		return Plugin_Stop;

	return Plugin_Continue;
}

public Action GlobalTimer(Handle timer)
{
	int HealthHud = cvarHealthHud.IntValue;

	if(!Enabled || CheckRoundState()==2 || CheckRoundState()==-1 || HealthHud<1)
		return Plugin_Stop;

	char healthString[64];
	int current, boss;
	int lives = 1;
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
					lives += BossLives[boss]-1;
				}
			}

			if(lives > 1)
			{
				FormatEx(healthString, sizeof(healthString), "%ix%i", current, lives);
			}
			else
			{
				FormatEx(healthString, sizeof(healthString), "%i", current);
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
					lives += BossLives[boss]-1;
				}
			}

			if(lives > 1)
				FormatEx(healthString, sizeof(healthString), "x%i", lives);
		}

		current = 0;
		lives = 1;
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
					lives += BossLives[boss]-1;
				}
			}

			if(lives > 1)
			{
				FormatEx(healthString2, sizeof(healthString2), "%ix%i", current, lives);
			}
			else
			{
				FormatEx(healthString2, sizeof(healthString2), "%i", current);
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
					lives += BossLives[boss]-1;
				}
			}

			if(lives > 1)
				FormatEx(healthString2, sizeof(healthString2), "x%i", lives);
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				if((!IsPlayerAlive(client) && !IsClientObserver(client)) || (!HudSettings[client][2] && !ShowHealthText) || HudSettings[client][4] || (GetClientButtons(client) & IN_SCORE))
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
					lives += BossLives[boss]-1;
				}
			}

			if(lives > 1)
			{
				FormatEx(healthString, sizeof(healthString), "%i / %ix%i", current, max, lives);
			}
			else
			{
				FormatEx(healthString, sizeof(healthString), "%i / %i", current, max);
			}
		}
		else
		{
			for(int clients=1; clients<=MaxClients; clients++)
			{
				if(IsBoss(clients))
				{
					boss = GetBossIndex(clients);
					lives += BossLives[boss]-1;
					max += BossLivesMax[boss];
				}
			}

			if(lives > 1)
			{
				FormatEx(healthString, sizeof(healthString), "%t", "Boss Lives Left", lives, max);
			}
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				if((!IsPlayerAlive(client) && !IsClientObserver(client)) || (!HudSettings[client][2] && !ShowHealthText) || HudSettings[client][4] || (GetClientButtons(client) & IN_SCORE))
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

				ShowSyncHudText(client, healthHUD, healthString);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_RPS(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client))
		return Plugin_Continue;

	int boss = GetBossIndex(client);
	if(boss==-1 || !IsPlayerAlive(client))
		return Plugin_Continue;

	RPSLosses[client]++;

	if(RPSLosses[client] < 0)
		RPSLosses[client] = 0;

	if(RPSHealth[client] == -1)
		RPSHealth[client] = BossHealth[boss];

	if(RPSLosses[client] >= cvarRPSLimit.IntValue)
	{
		if(IsValidClient(RPSWinner) && BossHealth[boss]>1349)
		{
			SDKHooks_TakeDamage(client, RPSWinner, RPSWinner, float(BossHealth[boss]), DMG_GENERIC, -1);
		}
		else // Winner disconnects?
		{
			ForcePlayerSuicide(client);
		}
	}
	else if(BossHealth[boss]>(1349*cvarRPSLimit.IntValue) && cvarRPSDivide.BoolValue)
	{
		if(IsValidClient(RPSWinner))
			SDKHooks_TakeDamage(client, RPSWinner, RPSWinner, float((RPSHealth[client]/cvarRPSLimit.IntValue)-999)/1.35, DMG_GENERIC, -1);
	}
	return Plugin_Continue;
}

public Action Timer_BotRage(Handle timer, any bot)
{
	if(IsValidClient(Boss[bot], false))
		FakeClientCommandEx(Boss[bot], "voicemenu 0 0");
}

stock int OnlyScoutsLeft(int team)
{
	int scouts;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)!=team)
		{
			if(TF2_GetPlayerClass(client)==TFClass_Scout || IsBoss(client))
			{
				scouts++;
			}
			else
			{
				return 0;
			}
		}
	}
	return scouts;
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon)) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(!Enabled)
		return;

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
		FF2flags[client] |= FF2FLAG_ROCKET_JUMPING;
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(!Enabled)
		return;

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
		FF2flags[client] &= ~FF2FLAG_ROCKET_JUMPING;
	}
}

public Action OnCallForMedic(int client, const char[] command, int args)
{
	if(!IsPlayerAlive(client) || CheckRoundState()!=1 || !IsBoss(client) || args!=2)
		return Plugin_Continue;

	int boss = GetBossIndex(client);
	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]) || BossRageDamage[0]>99998 || rageMode[client]==2)
		return Plugin_Continue;

	static char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
		return Plugin_Continue;

	if(RoundFloat(BossCharge[boss][0]) >= rageMin[client])
	{
		ActivateAbilitySlot(boss, 0);

		static float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

		static char sound[PLATFORM_MAX_PATH];
		if(RandomSound("sound_ability_serverwide", sound, sizeof(sound), boss))
			EmitSoundToAllExcept(sound);

		if(RandomSoundAbility("sound_ability", sound, sizeof(sound), boss))
		{
			FF2flags[Boss[boss]] |= FF2FLAG_TALKING;
			EmitSoundToAllExcept(sound);

			for(int target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && target!=Boss[boss] && ToggleVoice[target])
				{
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
				}
			}
			FF2flags[Boss[boss]] &= ~FF2FLAG_TALKING;
		}
		emitRageSound[boss]=true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void ActivateAbilitySlot(int boss, int slot, bool buttonmodeactive=false)
{
	int ability_slot, buttonmode, count, j;
	char ability[12];
	static char lives[MAXRANDOMS][3];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		FormatEx(ability, sizeof(ability), "ability%i", i);
		KvRewind(BossKV[Special[boss]]);
		if(KvJumpToKey(BossKV[Special[boss]], ability))
		{
			if(KvGetNum(BossKV[Special[boss]], "noversus") && Enabled3)
				continue;

			ability_slot = KvGetNum(BossKV[Special[boss]], "slot", -2);
			if(ability_slot == -2)
				ability_slot = KvGetNum(BossKV[Special[boss]], "arg0");

			if(ability_slot != slot)
				continue;
	
			buttonmode = (buttonmodeactive) ? (KvGetNum(BossKV[Special[boss]], "buttonmode")) : 0;

			KvGetString(BossKV[Special[boss]], "life", ability, sizeof(ability));
			static char abilityName[64], pluginName[64];
			if(!ability[0])
			{
				KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
				KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
				if(!UseAbility(abilityName, pluginName, boss, slot, buttonmode))
					return;
			}
			else
			{
				count = ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
				for(j=0; j<count; j++)
				{
					if(StringToInt(lives[j]) == BossLives[boss])
					{
						KvGetString(BossKV[Special[boss]], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(BossKV[Special[boss]], "name", abilityName, sizeof(abilityName));
						if(!UseAbility(abilityName, pluginName, boss, slot, buttonmode))
							return;

						break;
					}
				}
			}
		}
	}
}

public Action OnSuicide(int client, const char[] command, int args)
{
	bool canBossSuicide = cvarBossSuicide.BoolValue;
	if(IsBoss(client) && (!canBossSuicide || !CheckRoundState()) && CheckRoundState()!=2)
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
	static char class[16];
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
			return IsPlayerAlive(client) ? Plugin_Handled : Plugin_Continue;

		int team = view_as<int>(TFTeam_Unassigned);
		int oldTeam = GetClientTeam(client);
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

	int team = view_as<int>(TFTeam_Unassigned);
	int oldTeam = GetClientTeam(client);
	static char teamString[10];
	GetCmdArg(1, teamString, sizeof(teamString));

	if(StrEqual(teamString, "red", false))
	{
		team = view_as<int>(TFTeam_Red);
	}
	else if(StrEqual(teamString, "blue", false))
	{
		team = view_as<int>(TFTeam_Blue);
	}
	else if(StrEqual(teamString, "auto", false))
	{
		team = OtherTeam;
	}
	else if(StrEqual(teamString, "spectate", false) && !IsBoss(client) && GetConVarBool(FindConVar("mp_allowspectators")))
	{
		team = view_as<int>(TFTeam_Spectator);
	}

	if(team==BossTeam && (!IsBoss(client) || BossSwitched[boss]))
	{
		team = OtherTeam;
	}
	else if(team==OtherTeam && (IsBoss(client) && !BossSwitched[boss]))
	{
		team = BossTeam;
	}

	if(team>view_as<int>(TFTeam_Unassigned) && team!=oldTeam)
		ChangeClientTeam(client, team);

	if(CheckRoundState()!=1 && !IsBoss(client) || !IsPlayerAlive(client))  //No point in showing the VGUI if they can't change teams
	{
		switch(team)
		{
			case view_as<int>(TFTeam_Red):
				ShowVGUIPanel(client, "class_red");

			case view_as<int>(TFTeam_Blue):
				ShowVGUIPanel(client, "class_blue");
		}
	}
	return Plugin_Handled;
}

public void OnRPS(Event event, const char[] name, bool dontBroadcast)
{
	int winner = event.GetInt("winner");
	if(!IsValidClient(winner))
		return;

	int loser = event.GetInt("loser");
	if(!IsValidClient(loser))
		return;

	if(!IsBoss(winner) && IsBoss(loser) && cvarRPSLimit.IntValue>0)	// Boss Loses on RPS?
	{
		RPSWinner = winner;
		TF2_AddCondition(RPSWinner, TFCond_NoHealingDamageBuff, 3.4);	// I'm not bothered checking for mini-crit boost or not during damage
		CreateTimer(3.1, Timer_RPS, GetClientUserId(loser), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	int points = cvarRPSPoints.IntValue;	// Teammate or Minion loses?
	if(ToggleBoss[winner]==Setting_Off || ToggleBoss[loser]==Setting_Off || IsBoss(winner) || IsBoss(loser) || QueuePoints[winner]<points || QueuePoints[loser]<points || points<1)
		return;

	FPrintToChat(winner, "%t", "rps_won", points, loser);
	QueuePoints[winner] += points;

	FPrintToChat(loser, "%t", "rps_lost", points, winner);
	QueuePoints[loser] -= points;
}

public void OnStartCapture(Event event, const char[] name, bool dontBroadcast)
{
	isCapping = true;
}

public void OnBreakCapture(Event event, const char[] name, bool dontBroadcast)
{
	if(!event.GetFloat("time_remaining"))
		isCapping = false;
}

public void EndBossRound()
{
	if(!cvarCountdownResult.BoolValue)
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
	static int OTCount;
	if(CheckRoundState() != 1)
	{
		OTCount = 0;
		return Plugin_Stop;
	}

	if(!isCapping)
	{
		EndBossRound();
		OTCount = 0;
		return Plugin_Stop;
	}

	if(OTCount > 0)
	{
		EmitGameSoundToAll("Game.Overtime");
		if(GetConVarInt(FindConVar("tf_overtime_nag")))
			OTCount = GetRandomInt(-3, 0);

		return Plugin_Continue;
	}

	OTCount++;
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;

	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Continue;

	int flags = event.GetInt("death_flags");
	if(Enabled3 && !(flags & TF_DEATHFLAG_DEADRINGER)) // Because those damn subplugins
	{
		int reds, blus;
		if(CheckRoundState() == 1)
		{
			reds = MercAlivePlayers;
			blus = BossAlivePlayers;
		}
		else
		{
			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(target))
					continue;

				if(GetClientTeam(target) == OtherTeam)
				{
					reds++;
				}
				else if(GetClientTeam(target) == BossTeam)
				{
					blus++;
				}
			}
		}

		if(reds>blus || (reds==blus && GetRandomInt(0, 1))) // More reds or their equal with 50/50 chance
		{
			TF2_ChangeClientTeam(client, view_as<TFTeam>(BossTeam));
		}
		else
		{
			TF2_ChangeClientTeam(client, view_as<TFTeam>(OtherTeam));
		}
	}

	if(CheckRoundState() != 1)
		return Plugin_Continue;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	static char sound[PLATFORM_MAX_PATH];
	CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	DoOverlay(client, "");

	if(!IsBoss(client))
	{
		if(!(flags & TF_DEATHFLAG_DEADRINGER) && (Enabled3 || GetClientTeam(client)!=BossTeam))
			CreateTimer(1.0, Timer_Damage, userid, TIMER_FLAG_NO_MAPCHANGE);

		if(IsBoss(attacker))
		{
			int boss = GetBossIndex(attacker);
			bool firstBloodSound = true;
			if(firstBlood)	//TF_DEATHFLAG_FIRSTBLOOD is broken
			{
				if(RandomSound("sound_first_blood", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(sound);
					firstBloodSound = false;
				}
				firstBlood = false;
			}

			int alivePlayers = GetClientTeam(attacker)==BossTeam ? MercAlivePlayers : BossAlivePlayers;
			if(alivePlayers>2 && KSpreeCount[boss]<2 && firstBloodSound)  //Don't conflict with end-of-round sounds, killing spree, or first blood
			{
				if(GetRandomInt(0, 1))
				{
					char class[32];
					static char classnames[][] = {"custom", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
					FormatEx(class, sizeof(class), "sound_kill_%s", classnames[LastAliveClass[client]]);
					if(RandomSound(class, sound, sizeof(sound), boss))
					{
						EmitSoundToAllExcept(sound);
					}
					else if(RandomSound("sound_hit", sound, sizeof(sound), boss))
					{
						EmitSoundToAllExcept(sound);
					}
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

			if(alivePlayers>2 && KSpreeCount[boss]==3)
			{
				if(RandomSound("sound_kspree", sound, sizeof(sound), boss))
					EmitSoundToAllExcept(sound);

				KSpreeCount[boss] = 0;
			}
			else
			{
				KSpreeTimer[boss] = GetGameTime()+5.0;
			}

			if(!IsFakeClient(client) || IsFakeClient(attacker))
			{
				BossKillsF[attacker]++;
				if(!(flags & TF_DEATHFLAG_DEADRINGER))
					AddClientStats(attacker, Cookie_BossKills, 1);
			}

			ActivateAbilitySlot(boss, 4);
		}
	}
	else if(attacker)
	{
		int boss = GetBossIndex(client);
		if(boss==-1 || (flags & TF_DEATHFLAG_DEADRINGER))
			return Plugin_Continue;

		if(RandomSound("sound_death", sound, sizeof(sound), boss))
			EmitSoundToAllExcept(sound);

		if(!IsFakeClient(client) || IsFakeClient(attacker))
			AddClientStats(attacker, Cookie_PlayerKills, 1);

		if(IsFakeClient(client) || !IsFakeClient(attacker))
			AddClientStats(client, Cookie_BossDeaths, 1);

		ActivateAbilitySlot(boss, 5);

		BossHealth[boss] = 0;
		UpdateHealthBar();
		Stabbed[boss] = 0.0;
		Marketed[boss] = 0.0;
		Cabered[boss] = 0.0;
	}

	if(!(flags & TF_DEATHFLAG_DEADRINGER))
	{
		static char classname[PLATFORM_MAX_PATH];
		FakeClientCommand(client, "destroy 2");
		for(int entity=MAXENTITIES-1; entity>MaxClients; entity--)
		{
			if(IsValidEntity(entity))
			{
				GetEntityClassname(entity, classname, sizeof(classname));
				if(!StrContains(classname, "obj_sentrygun") && (GetEntPropEnt(entity, Prop_Send, "m_hBuilder")==client))
				{
					SetVariantInt(GetEntPropEnt(entity, Prop_Send, "m_iMaxHealth")+1);
					AcceptEntityInput(entity, "RemoveHealth");

					Event boom = CreateEvent("object_removed", true);
					boom.SetInt("userid", userid);
					boom.SetInt("index", entity);
					boom.Fire();
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

public Action OnObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || event.GetInt("weaponid"))  // 0 means that the client was airblasted, which is what we want
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("ownerid"));
	int boss = GetBossIndex(client);
	if(boss!=-1 && BossCharge[boss][0]<rageMax[client])
	{
		BossCharge[boss][0] += rageMax[client]*7.0/rageMin[client];  //TODO: Allow this to be customizable
		if(BossCharge[boss][0] > rageMax[client])
			BossCharge[boss][0] = rageMax[client];
	}
	return Plugin_Continue;
}

public Action OnJarate(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int client = bf.ReadByte();
	int victim = bf.ReadByte();
	int boss = GetBossIndex(victim);
	if(boss == -1)
		return Plugin_Continue;

	int jarate = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(jarate==-1 || GetEntProp(jarate, Prop_Send, "m_iEntityLevel")==-122)	// -122 is the Jar of Ants which isn't really Jarate
		return Plugin_Continue;

	int index = GetEntProp(jarate, Prop_Send, "m_iItemDefinitionIndex");
	if(!(index==58 && index==1083 && index==1105))
		return Plugin_Continue;

	BossCharge[boss][0] -= rageMax[victim]*8.0/rageMin[victim];	//TODO: Allow this to be customizable
	if(BossCharge[boss][0] < 0.0)
		BossCharge[boss][0] = 0.0;

	return Plugin_Continue;
}

public void OnDeployBackup(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled && event.GetInt("buff_type")==2)
		FF2flags[GetClientOfUserId(event.GetInt("buff_owner"))] |= FF2FLAG_ISBUFFED;
}

public Action Timer_CheckAlivePlayers(Handle timer)
{
	if(CheckRoundState() == 2)
		return Plugin_Continue;

	MercAlivePlayers = 0;
	BossAlivePlayers = 0;
	RedAliveBosses = 0;
	BlueAliveBosses = 0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(GetClientTeam(client) == OtherTeam)
			{
				MercAlivePlayers++;
				if(IsBoss(client))
					RedAliveBosses++;
			}
			else if(GetClientTeam(client) == BossTeam)
			{
				BossAlivePlayers++;
				if(IsBoss(client))
					BlueAliveBosses++;
			}
		}
	}

	Call_StartForward(OnAlivePlayersChanged);  //Let subplugins know that the number of alive players just changed
	Call_PushCell(MercAlivePlayers);
	Call_PushCell(BossAlivePlayers);
	Call_Finish();

	if(!MercAlivePlayers && !BossAlivePlayers)
	{
		ForceTeamWin(0);
		return Plugin_Continue;
	}
	if(!MercAlivePlayers)
	{
		ForceTeamWin(BossTeam);
		return Plugin_Continue;
	}
	if(!BossAlivePlayers)
	{
		ForceTeamWin(OtherTeam);
		return Plugin_Continue;
	}

	if(Enabled3 && cvarBvBLose.IntValue)
	{
		switch(cvarBvBLose.IntValue)
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
				if(!(MercAlivePlayers - RedAliveBosses) && !(BossAlivePlayers - BlueAliveBosses))
				{
					ForceTeamWin(BossTeam);
					return Plugin_Continue;
				}
				if(!(MercAlivePlayers - RedAliveBosses))
				{
					ForceTeamWin(BossTeam);
					return Plugin_Continue;
				}
				if(!(BossAlivePlayers - BlueAliveBosses))
				{
					ForceTeamWin(OtherTeam);
					return Plugin_Continue;
				}
			}
		}
	}

	if(MercAlivePlayers==1 && BossAlivePlayers && Boss[0] && playingmerc>1 && !DrawGameTimer && LastMan && !Enabled3)
	{
		static char sound[PLATFORM_MAX_PATH];
		if(RandomSound("sound_lastman", sound, sizeof(sound)))
			EmitSoundToAllExcept(sound);

		LastMan=false;
	}

	float alivePlayers = Enabled3 ? float(MercAlivePlayers + BossAlivePlayers - 1) : float(MercAlivePlayers);
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
					if(cvarGameText.IntValue > 0)
					{
						ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "point_enable", RoundFloat(alivePlayers));
					}
					else
					{
						PrintHintText(client, "%t", "point_enable", RoundFloat(alivePlayers));
					}
				}
			}

			if(GetRandomInt(0, 1))
			{
				EmitGameSoundToAll("Announcer.AM_CapEnabledRandom");
			}
			else
			{
				char sound[64];
				FormatEx(sound, sizeof(sound), "Announcer.AM_CapIncite0%i", GetRandomInt(1, 4));
				EmitGameSoundToAll(sound);
			}
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

	float alivePlayers = Enabled3 ? float(MercAlivePlayers + BossAlivePlayers - 1) : float(MercAlivePlayers);
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

	int time = timeleft--;
	char timeDisplay[6];
	if(time/60 > 9)
	{
		IntToString(time/60, timeDisplay, sizeof(timeDisplay));
	}
	else
	{
		FormatEx(timeDisplay, sizeof(timeDisplay), "0%i", time/60);
	}

	if(time%60 > 9)
	{
		FormatEx(timeDisplay, sizeof(timeDisplay), "%s:%i", timeDisplay, time%60);
	}
	else
	{
		FormatEx(timeDisplay, sizeof(timeDisplay), "%s:0%i", timeDisplay, time%60);
	}

	int client;
	static char message[MAXTF2PLAYERS][512], name[64];
	if(bosses<2 && cvarGameText.IntValue>0 && alivePlayers==1 && cvarHealthHud.IntValue<2)
	{
		int boss2, clients;
		for(client=1; client<=MaxClients; client++)
		{
			if(!IsBoss(client))
				continue;

			boss2 = GetBossIndex(client);
			char bossLives[8];
			if(BossLives[boss2] > 1)
				FormatEx(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);

			for(clients=1; clients<=MaxClients; clients++)
			{
				if(!IsValidClient(clients))
					continue;

				SetGlobalTransTarget(clients);
				GetBossSpecial(Special[boss2], name, sizeof(name), clients);
				Format(message[clients], sizeof(message[]), "%s\n%t", message[clients], "ff2_hp", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives);
			}
		}
	}

	SetHudTextParams(-1.0, 0.17, 1.1, 255, 255, 255, 255);
	for(client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (!IsPlayerAlive(client) && !IsClientObserver(client)))
			continue;

		SetGlobalTransTarget(client);
		if(!HudSettings[client][3] && !HudSettings[client][4] && bosses<2 && cvarGameText.IntValue>0 && alivePlayers==1 && cvarHealthHud.IntValue<2)
		{
			if(timeleft<=countdownTime && timeleft>=countdownTime/2)
			{
				ShowGameText(client, "ico_notify_sixty_seconds", _, "%s | %s", message[client], timeDisplay);
			}
			else if(timeleft<countdownTime/2 && timeleft>=countdownTime/6)
			{
				ShowGameText(client, "ico_notify_thirty_seconds", _, "%s | %s", message[client], timeDisplay);
			}
			else if(timeleft<countdownTime/6 && timeleft>=0)
			{
				ShowGameText(client, "ico_notify_ten_seconds", _, "%s | %s", message[client], timeDisplay);
			}
			else if(isCapping)
			{
				ShowGameText(client, "ico_notify_flag_moving_alt", _, "%s | %t", message[client], "Overtime");
			}
			else if(BossIcon[0])
			{
				ShowGameText(client, BossIcon, _, "%s | %s", message[client], timeDisplay);
			}
			else
			{
				ShowGameText(client, "leaderboard_streak", _, "%s | %s", message[client], timeDisplay);
			}
		}
		else if(HudSettings[client][3])
		{
		}
		else if(bosses<2 && cvarGameText.IntValue>1)
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
			else if(BossIcon[0])
			{
				ShowGameText(client, BossIcon, _, timeDisplay);
			}
			else
			{
				ShowGameText(client, "leaderboard_streak", _, timeDisplay);
			}
		}
		else if(GetClientButtons(client) & IN_SCORE)
		{
		}
		else if(isCapping && timeleft<1)
		{
			ShowSyncHudText(client, timeleftHUD, "%t", "Overtime");
		}
		else
		{
			ShowSyncHudText(client, timeleftHUD, timeDisplay);
		}
	}

	switch(time)
	{
		case 300:
		{
			EmitGameSoundToAll("Announcer.RoundEnds5minutes");
		}
		case 120:
		{
			EmitGameSoundToAll("Announcer.RoundEnds2minutes");
		}
		case 60:
		{
			EmitGameSoundToAll("Announcer.RoundEnds60seconds");
		}
		case 30:
		{
			EmitGameSoundToAll("Announcer.RoundEnds30seconds");
		}
		case 10:
		{
			EmitGameSoundToAll("Announcer.RoundEnds10seconds");
		}
		case 1, 2, 3, 4, 5:
		{
			char sound[PLATFORM_MAX_PATH];
			FormatEx(sound, sizeof(sound), "Announcer.RoundEnds%iseconds", time);
			EmitGameSoundToAll(sound);
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

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=1)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("damageamount");
	int weapon = event.GetInt("weaponid");

	if(IsValidClient(attacker) && GetClientTeam(attacker)!=GetClientTeam(client) && damage && shield[client])
	{
		int preHealth = GetClientHealth(client)+damage;
		int health = GetClientHealth(client);
		switch(cvarShieldType.IntValue)
		{
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
				if(GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee)!=weapon && shieldHP[client]>0 && damage<preHealth)
				{
					int damageresist = RoundFloat(float(damage)*shDmgReduction[client]);

					shieldHP[client] -= damage;		// take a small portion of shield health away

					SetEntityHealth(client, health+damageresist);

					shDmgReduction[client] = shieldHP[client]/cvarShieldHealth.FloatValue*(1.0-cvarShieldResist.FloatValue);

					if(shieldHP[client] > 0)
					{
						char ric[PLATFORM_MAX_PATH];
						FormatEx(ric, sizeof(ric), "weapons/fx/rics/ric%i.wav", GetRandomInt(1,5));
						EmitSoundToClient(client, ric, _, _, _, _, 0.7, _, _, _, _, false);
						EmitSoundToClient(attacker, ric, _, _, _, _, 0.7, _, _, _, _, false);
						event.SetInt("damageamount", damage-damageresist);
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

				shDmgReduction[client] = shieldHP[client]/cvarShieldHealth.FloatValue*(1.0-cvarShieldResist.FloatValue);

				if(shieldHP[client]<=0.0 || (health+damageresist)<=damage)
				{
					SetEntityHealth(client, preHealth);
					RemoveShield(client, attacker);
					return Plugin_Handled;
				}

				char ric[PLATFORM_MAX_PATH];
				FormatEx(ric, sizeof(ric), "weapons/fx/rics/ric%i.wav", GetRandomInt(1,5));
				EmitSoundToClient(client, ric, _, _, _, _, 0.7, _, _, _, _, false);
				EmitSoundToClient(attacker, ric, _, _, _, _, 0.7, _, _, _, _, false);
				event.SetInt("damageamount", damage-damageresist);
				return Plugin_Changed;
			}
		}
	}

	int boss = GetBossIndex(client);
	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]) || (client==attacker && SelfKnockback[client]<2))
		return Plugin_Continue;

	int custom = event.GetInt("custom");
	if(custom == TF_CUSTOM_TELEFRAG)
	{
		damage = IsPlayerAlive(attacker) ? TimesTen ? RoundFloat(cvarTelefrag.IntValue*cvarTimesTen.FloatValue) : cvarTelefrag.IntValue : 1;
	}
	else if(custom == TF_CUSTOM_BOOTS_STOMP)
	{
		damage *= 5;
	}

	if(event.GetBool("minicrit") && event.GetBool("allseecrit"))
		event.SetBool("allseecrit", false);

	if(custom==TF_CUSTOM_TELEFRAG || custom==TF_CUSTOM_BOOTS_STOMP)
		event.SetInt("damageamount", damage);

	for(int lives=1; lives<BossLives[boss]; lives++)
	{
		if(BossHealth[boss]-damage <= BossHealthMax[boss]*lives)
		{
			SetEntityHealth(client, (BossHealth[boss]-damage)-BossHealthMax[boss]*(lives-1)); //Set the health early to avoid the boss dying from fire, etc.

			Action action = Plugin_Continue;  //Used for the forward
			int bossLives = BossLives[boss];
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

			ActivateAbilitySlot(boss, -1);

			BossLives[boss] = lives;

			static char bossName[64], ability[PLATFORM_MAX_PATH];
			strcopy(ability, sizeof(ability), BossLives[boss]==1 ? "ff2_life_left" : "ff2_lives_left");
			for(int target=1; target<=MaxClients; target++)
			{
				if(!IsValidClient(target) || HudSettings[target][2] || (FF2flags[target] & FF2FLAG_HUDDISABLED) || (!IsPlayerAlive(target) && !IsClientObserver(target)))
					continue;
	
				if(cvarGameText.IntValue > 0)
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

	int healers[MAXTF2PLAYERS];
	int healerCount;
	for(int target; target<=MaxClients; target++)
	{
		if(IsValidClient(target) && IsPlayerAlive(target) && (GetHealingTarget(target, true)==attacker))
		{
			healers[healerCount] = target;
			healerCount++;
		}
	}

	for(int target; target<healerCount; target++)
	{
		if(IsValidClient(healers[target]) && IsPlayerAlive(healers[target]))
		{
			if(damage<10 || uberTarget[healers[target]]==attacker)
			{
				Damage[healers[target]] += damage;
			}
			else
			{
				Damage[healers[target]] += damage/(healerCount+1);
			}
		}
	}

	if(IsValidClient(attacker) && IsValidClient(client) && client!=attacker && damage>0 && !IsBoss(attacker))
	{
		int i;
		if(cvarAirStrike.FloatValue > 0)  //Air Strike-moved from OTD
		{
			int primary = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
			if(IsValidEntity(primary) && GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex")==1104)
			{
				AirstrikeDamage[attacker] += damage;
				while(AirstrikeDamage[attacker]>=cvarAirStrike.FloatValue && i<5)
				{
					i++;
					SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
					AirstrikeDamage[attacker] -= cvarAirStrike.FloatValue;
				}
			}
		}
		i = 0;
		if(cvarDmg2KStreak.FloatValue > 0)
		{
			KillstreakDamage[attacker] += damage;
			int streak = GetEntProp(attacker, Prop_Send, "m_nStreaks");
			while(KillstreakDamage[attacker]>=cvarDmg2KStreak.FloatValue && i<21)
			{
				i++;
				KillstreakDamage[attacker] -= cvarDmg2KStreak.FloatValue;
			}
			SetEntProp(attacker, Prop_Send, "m_nStreaks", streak+i);
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

public Action OnPlayerHealed(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || CheckRoundState()!=1)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("patient"));
	int healer = GetClientOfUserId(event.GetInt("healer"));
	int heals = event.GetInt("amount");

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
	if(IsValidEntity(entity) && IsValidEdict(entity) && (GetClientTeam(client)==OtherTeam || Enabled3) && SapperCooldown[client]<=0)
	{
		index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

		if((buttons & IN_ATTACK) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !GetEntProp(client, Prop_Send, "m_bFeignDeathReady") && (index==735 || index==736 || index==810 || index==831 || index==933 || index==1080 || index==1102))
		{
			float position[3], position2[3], distance;
			int boss;
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
			for(int target=1; target<=MaxClients; target++)
			{
				if(IsValidClient(target) && IsPlayerAlive(target) && (GetClientTeam(target)==BossTeam || Enabled3))
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

							SapperCooldown[client] = cvarSapperCooldown.FloatValue;
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
							SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+1.0);
							SetEntPropFloat(client, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+1.0);
							return Plugin_Handled;
						}
						else if(boss<0 && SapperMinion)
						{
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

							SapperCooldown[client] = cvarSapperCooldown.FloatValue;
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

	if((attacker<1 || client==attacker) && IsBoss(client) && damagetype & DMG_FALL)
	{
		return Plugin_Handled;
	}
	else if((attacker<1 || client==attacker) && IsBoss(client) && !SelfKnockback[client])
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
			if(shield[client] && cvarShieldType.IntValue==1)
			{
				RemoveShield(client, attacker);
				return Plugin_Handled;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);
				damage *= 0.5;
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
			{
				damage *= 0.33;
				return Plugin_Changed;
			}

			if(GetEntProp(client, Prop_Send, "m_bFeignDeathReady") || TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
			{
				if(cvarRinger.FloatValue < 1)
				{
					damage *= cvarRinger.FloatValue;
					return Plugin_Changed;
				}
				else if(cvarRinger.FloatValue > 1)
				{
					damage = cvarRinger.FloatValue;
					return Plugin_Changed;
				}
			}
			else if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				if(cvarCloak.FloatValue < 1)
				{
					damage *= cvarCloak.FloatValue;
					return Plugin_Changed;
				}
				else if(cvarCloak.FloatValue > 1)
				{
					damage = cvarCloak.FloatValue;
					return Plugin_Changed;
				}
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
				static char classname[32];
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
					damage = BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.1-Stabbed[boss]/90)/(cvarTimesTen.FloatValue*3);
				}
				else if(cvarLowStab.BoolValue)
				{
					damage = (BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.11-Stabbed[boss]/90)+(750/float(playing)))/5;
				}
				else
				{
					damage = BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.12-Stabbed[boss]/90)/5;
				}
				damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
				damagecustom = 0;

				Action action = Plugin_Continue;
				Call_StartForward(OnBackstabbed);
				Call_PushCell(boss);
				Call_PushCell(client);
				Call_PushCell(attacker);
				Call_Finish(action);
				if(action == Plugin_Stop)
				{
					damage = 0.0;
					return Plugin_Handled;
				}

				EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
				EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+1.5);
				SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+1.5);
				SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+(cvarCloakStun.FloatValue*0.75));

				int viewmodel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
				if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
				{
					int melee = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
					int animation = 42;
					switch(melee)
					{
						case 225, 356, 423, 461, 574, 649, 1071, 30758:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan, Prinny Machete
							animation = 16;

						case 638:  //Sharp Dresser
							animation = 32;
					}
					SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
				}

				if(!HudSettings[attacker][2] && !(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
				{
					if(TellName)
					{
						char spcl[64];
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

					if(!HudSettings[client][2] && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							char spcl[64];
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
						static char sound[PLATFORM_MAX_PATH];
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

				ActivateAbilitySlot(boss, 6);

				if(Stabbed[boss] < 3)
					Stabbed[boss]++;

				if(action == Plugin_Handled)
				{
					damage = 0.0;
					return Plugin_Handled;
				}
				return Plugin_Changed;
			}

			if(bIsTelefrag)
			{
				if(!IsPlayerAlive(attacker))
				{
					damage = 1.0;
					return Plugin_Changed;
				}
				damage = BossHealth[boss]*1.005;
				damagecustom = 0;

				for(int all=1; all<=MaxClients; all++)
				{
					if(IsValidClient(all) && IsPlayerAlive(all))
					{
						if(!HudSettings[all][2] && !(FF2flags[all] & FF2FLAG_HUDDISABLED))
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

					if(!HudSettings[teleowner][2] && !(FF2flags[teleowner] & FF2FLAG_HUDDISABLED))
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

				static char spcl[64];
				if(!HudSettings[attacker][2] && !(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
				{
					if(TellName)
					{
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

				if(!HudSettings[client][2] && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
				{
					if(TellName)
					{
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

				static char sound[PLATFORM_MAX_PATH];
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
					static char classname[32];
					if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_knife", false))
						bIsBackstab = true;
				}
				else if(!IsValidEntity(weapon) && (damagetype & DMG_CRUSH) && damage==1000.0)
				{
					bIsTelefrag = true;
				}

				int index;
				static char classname[64];
				if(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients)
				{
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(!HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))  //Dang spell Monoculuses
					{
						index = -1;
						classname[0] = 0;
					}
					else
					{
						index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					}
				}
				else
				{
					index = -1;
					classname[0] = 0;
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
						if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
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
						if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
						{
							int health = GetClientHealth(attacker);
							int newhealth = health+25;
							if(newhealth <= GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
								SetEntityHealth(attacker, newhealth);
						}
					}
					case 307:  //Ullapool Caber
					{
						if(!GetEntProp(weapon, Prop_Send, "m_iDetonated") && allowedDetonations<4)	// If using ullapool caber, only trigger if bomb hasn't been detonated
						{
							if(TimesTen)
							{
								damage = ((Pow(float(BossHealthMax[boss]), 0.74074)-(Cabered[client]/128.0*float(BossHealthMax[boss])))/(3+(cvarTimesTen.FloatValue*allowedDetonations*3)))*bosses;
							}
							else if(cvarLowStab.BoolValue)
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
								if(!HudSettings[attacker][2] && !(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
								{
									if(TellName)
									{
										static char spcl[64];
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
								if(!HudSettings[client][2] && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
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
									static char sound[PLATFORM_MAX_PATH];
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
						if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
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
						if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
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
						if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
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
						if(RemoveCond(attacker, TFCond_BlastJumping) && cvarMarket.FloatValue)	// New way to check explosive jumping status
						//if((FF2flags[attacker] & FF2FLAG_ROCKET_JUMPING) && cvarMarket.FloatValue)
						{
							if(TimesTen)
							{
								damage = ((Pow(float(BossHealthMax[boss]), 0.74074)-(Marketed[client]/128.0*float(BossHealthMax[boss])))/(cvarTimesTen.FloatValue*3))*bosses*cvarMarket.FloatValue;
							}
							else if(cvarLowStab.BoolValue)
							{
								damage = ((Pow(float(BossHealthMax[boss]), 0.74074)+(1750.0/float(playing))+206.0-(Marketed[client]/128.0*float(BossHealthMax[boss])))/3)*bosses*cvarMarket.FloatValue;
							}
							else
							{
								damage = ((Pow(float(BossHealthMax[boss]), 0.74074)+512.0-(Marketed[client]/128.0*float(BossHealthMax[boss])))/3)*bosses*cvarMarket.FloatValue;
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
									static char spcl[64];
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
								static char sound[PLATFORM_MAX_PATH];
								if(RandomSound("sound_marketed", sound, sizeof(sound)))
									EmitSoundToAllExcept(sound);
							}

							ActivateAbilitySlot(boss, 7);
							HealthBarMode = true;
							CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
							return Plugin_Changed;
						}
					}
					case 525, 595:  //Diamondback, Manmelter
					{
						if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
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
						int healers[MAXTF2PLAYERS];
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
								int medigun = GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
								if(IsValidEntity(medigun))
								{
									static char medigunClassname[64];
									GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
									if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
									{
										float uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(0.1/healerCount);
										if(uber > 1.0)
											uber = 1.0;

										SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
									}
								}
							}
						}
					}
					case 594:  //Phlogistinator
					{
						if(kvWeaponMods == null || cvarHardcodeWep.IntValue>0)
						{
							if(!TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))
							{
								damage/=2.0;
								return Plugin_Changed;
							}
						}
					}
					case 44:	//Sandman
					{
						if(cvarEnableSandmanStun.BoolValue)
						{
							float fClientLocation[3];
							float fClientEyePosition[3];
							GetClientAbsOrigin(attacker, fClientEyePosition); 
							GetClientAbsOrigin(client, fClientLocation); 
							float fDistance[3]; 
							MakeVectorFromPoints(fClientLocation, fClientEyePosition, fDistance); 
							float dist = GetVectorLength(fDistance); 
							if (dist >= 128.0 && dist <= 256.0) 
							{
								TF2_StunPlayer(client, 1.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 256.0 && dist < 512.0) 
							{
								TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 512.0 && dist < 768.0)
							{
								TF2_StunPlayer(client, 3.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 768.0 && dist < 1024.0)
							{
								TF2_StunPlayer(client, 4.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 1024.0 && dist < 1280.0) 
							{
								TF2_StunPlayer(client, 5.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 1280.0 && dist < 1536.0) 
							{
								TF2_StunPlayer(client, 6.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 1536.0 && dist < 1792.0) 
							{
								TF2_StunPlayer(client, 7.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 1792.0)
							{
								TF2_StunPlayer(client, 7.0, 0.0, TF_STUNFLAGS_BIGBONK, attacker); 
							}
							return Plugin_Changed; 
						}
					}
				}

				if(bIsBackstab)
				{
					if(Enabled3)
					{
						if(TimesTen)
						{
							damage = BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.1-Stabbed[boss]/90)/(cvarTimesTen.FloatValue*3);
						}
						else if(cvarLowStab.BoolValue)
						{
							damage = (BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.11-Stabbed[boss]/90)+(1500/float(playing)))/3;
						}
						else
						{
							damage = BossHealthMax[boss]*(LastBossIndex()+1)*BossLivesMax[boss]*(0.12-Stabbed[boss]/90)/3;
						}
					}
					else if(TimesTen)
					{
						damage = BossHealthMax[boss]*bosses*(LastBossIndex()+1)*BossLivesMax[boss]*(0.1-Stabbed[boss]/90)/(cvarTimesTen.FloatValue*3);
					}
					else if(cvarLowStab.BoolValue)
					{
						damage = (BossHealthMax[boss]*bosses*(LastBossIndex()+1)*BossLivesMax[boss]*(0.11-Stabbed[boss]/90)+(1500/float(playing)))/3;
					}
					else
					{
						damage = BossHealthMax[boss]*bosses*(LastBossIndex()+1)*BossLivesMax[boss]*(0.12-Stabbed[boss]/90)/3;
					}
					damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
					damagecustom = 0;

					Action action = Plugin_Continue;
					Call_StartForward(OnBackstabbed);
					Call_PushCell(boss);
					Call_PushCell(client);
					Call_PushCell(attacker);
					Call_Finish(action);
					if(action == Plugin_Stop)
					{
						damage = 0.0;
						return Plugin_Handled;
					}

					EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+cvarCloakStun.FloatValue);

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

					if(!HudSettings[attacker][2] && !(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
							static char spcl[64];
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

						if(!HudSettings[client][2] && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
						{
							if(TellName)
							{
								static char spcl[64];
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
							static char sound[PLATFORM_MAX_PATH];
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
							int overheal = cvarKunaiMax.IntValue;
							int health = GetClientHealth(attacker)+cvarKunai.IntValue;
							if(health > overheal)
								health = overheal;

							SetEntityHealth(attacker, health);
						}
						case 461:	//Big Earner
						{
							SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);  //Full cloak
							TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);  //Speed boost
						}
					}

					if(GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 525)  //Diamondback
						SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+cvarDiamond.IntValue);

					ActivateAbilitySlot(boss, 6);

					if(Stabbed[boss] < 3)
						Stabbed[boss]++;

					if(action == Plugin_Handled)
					{
						damage = 0.0;
						return Plugin_Handled;
					}
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
					damage = (TimesTen ? cvarTelefrag.FloatValue*cvarTimesTen.FloatValue : cvarTelefrag.FloatValue);

					for(int all=1; all<=MaxClients; all++)
					{
						if(IsValidClient(all) && IsPlayerAlive(all))
						{
							if(!HudSettings[all][2] && !(FF2flags[all] & FF2FLAG_HUDDISABLED))
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
							Damage[teleowner] += RoundFloat(TimesTen ? 3000.0*cvarTimesTen.FloatValue : 5401.0);

							if(!HudSettings[teleowner][2] && !(FF2flags[teleowner] & FF2FLAG_HUDDISABLED))
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

					static char spcl[64];
					if(!HudSettings[attacker][2] && !(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
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

					if(!HudSettings[client][2] && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
					{
						if(TellName)
						{
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

				if((damagetype & DMG_CLUB) && CritBoosted[client][2]!=0 && CritBoosted[client][2]!=1 && (TF2_GetPlayerClass(attacker)!=TFClass_Spy || CritBoosted[client][2]>1))
				{
					int melee = GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
					if(CritBoosted[client][2]>1 || (melee!=416 && melee!=307 && melee!=44))
					{
						damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
						return Plugin_Changed;
					}
				}
			}
			else
			{
				char classname[64];
				if(GetEntityClassname(attacker, classname, sizeof(classname)) && StrEqual(classname, "trigger_hurt", false))
				{
					if(SpawnTeleOnTriggerHurt && IsBoss(client) && CheckRoundState()==1)
					{
						HazardDamage[client] += damage;
						if(HazardDamage[client] >= cvarDamageToTele.FloatValue)
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
						if(BossHealth[boss] < 1)
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
			if(allowedDetonations != 1)
			{
				int index = (IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") && attacker<=MaxClients) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
				if(index == 307)  //Ullapool Caber
				{
					if(allowedDetonations<1 || allowedDetonations-detonations[attacker]>1)
					{
						detonations[attacker]++;
						if(allowedDetonations > 1)
							PrintHintText(attacker, "%t", "Detonations Left", allowedDetonations-detonations[attacker]);
	
						SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
						SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
					}
				}
			}

			if(IsValidClient(client, false) && TF2_GetPlayerClass(client)==TFClass_Soldier)  //TODO: LOOK AT THIS
			{
				if(damagetype & DMG_FALL)
				{
					int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(secondary<1 || !IsValidEntity(secondary))
					{
						damage /= 10.0;
						return Plugin_Changed;
					}
				}
			}

			if(Enabled3 && cvarBvBMerc.FloatValue!=1 && RedAliveBosses && BlueAliveBosses)
			{
				if(IsValidClient(client) && IsValidClient(attacker) && GetClientTeam(attacker)!=GetClientTeam(client))
				{
					damage *= cvarBvBMerc.FloatValue;
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

public Action OnCPTouch(int entity, int client)
{
	if(IsValidClient(client))
	{
		switch(CapMode)
		{
			case CAP_NONE:
			{
				return Plugin_Handled;		// nobody can cap
			}
			case CAP_BOSS_ONLY:
			{
				if(!IsBoss(client))			// non bosses can't cap
					return Plugin_Handled;
			}
			case CAP_BOSS_TEAM:
			{
				if(!Enabled3 && GetClientTeam(client)==OtherTeam)	// merc team can't cap
					return Plugin_Handled;
			}
			case CAP_NOT_BOSS:
			{
				if(IsBoss(client))			// bosses can't cap
					return Plugin_Handled;
			}
			case CAP_MERC_TEAM:
			{
				if(!Enabled3 && GetClientTeam(client)==BossTeam)	// boss team can't cap
					return Plugin_Handled;
			}
			case CAP_NO_MINIONS:
			{
				if(!Enabled3 && GetClientTeam(client)==BossTeam && !IsBoss(client))
					return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action OnStomp(int attacker, int victim, float &damageMultiplier, float &damageBonus, float &JumpPower)
{
	if(!Enabled || !IsValidClient(attacker) || !IsValidClient(victim) || attacker==victim)
		return Plugin_Continue;

	switch(GoombaMode)
	{
		case GOOMBA_NONE:					// none allowed
		{
			return Plugin_Handled;
		}
		case GOOMBA_BOSSTEAM:				// boss team only
		{
			if(!Enabled3 && GetClientTeam(attacker)==OtherTeam)	// they are on non-boss team
				return Plugin_Handled;
		}
		case GOOMBA_OTHERTEAM:				// non boss team only
		{
			if(!Enabled3 && GetClientTeam(attacker)==BossTeam)		// they are on boss team
				return Plugin_Handled;
		}
		case GOOMBA_NOTBOSS:				// all but boss
		{
			if(IsBoss(attacker))					// they are boss
				return Plugin_Handled;
		}
		case GOOMBA_NOMINION:				// all but minions
		{
			if(!Enabled3 && !IsBoss(attacker) && GetClientTeam(attacker)==BossTeam)	// they are a minion
				return Plugin_Handled;
		}
		case GOOMBA_BOSS:					// boss only
		{
			if(!IsBoss(attacker))
				return Plugin_Handled;
		}
	}

	if(IsBoss(victim))
	{
		damageMultiplier = GoombaDamage;
		JumpPower = reboundPower;
		if(TimesTen)
		{
			damageMultiplier /= cvarTimesTen.FloatValue;
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
	static char spcl[64];
	if(IsBoss(victim))
	{
		if(!HudSettings[attacker][2] && !(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
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

		if(!HudSettings[victim][2] && !(FF2flags[victim] & FF2FLAG_HUDDISABLED))
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
		if(!HudSettings[attacker][2] && !(FF2flags[attacker] & FF2FLAG_HUDDISABLED))
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

		if(!HudSettings[victim][2] && !(FF2flags[victim] & FF2FLAG_HUDDISABLED))
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

void GetBossSpecial(int boss=0, char[] buffer, int bufferLength, int client=0, int pack=-1)
{
	if(boss < 0)
		return;

	Handle kv;
	if(pack < 0)
	{
		kv = BossKV[boss];
	}
	else
	{
		kv = PackKV[boss][pack];
	}

	if(!kv)
		return;

	static char name[64], language[20];
	GetLanguageInfo(IsValidClient(client) ? GetClientLanguage(client) : GetServerLanguage(), language, sizeof(language), name, sizeof(name));
	Format(language, sizeof(language), "name_%s", language);

	KvRewind(kv);
	KvGetString(kv, language, name, bufferLength);
	if(!name[0])
	{
		if(IsValidClient(client))	// Don't check server's lanuage twice
		{
			GetLanguageInfo(GetServerLanguage(), language, 8, name, 8);
			Format(language, sizeof(language), "name_%s", language);
			KvGetString(kv, language, name, bufferLength);
		}

		if(!name[0])
			KvGetString(kv, "name", name, bufferLength, "=Failed name=");
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

	static char classname[64];
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
		velocity[0] = float(GetRandomInt(-10, 10));
		velocity[1] = float(GetRandomInt(-10, 10));
		velocity[2] = 50.0;  //I did this because setting it on the creation of the vel variable was creating a compiler error for me.
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
	static char classname[32];
	if(IsValidEntity(teleporter) && GetEntityClassname(teleporter, classname, sizeof(classname)) && StrEqual(classname, "obj_teleporter", false))
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

stock TFClassType KvGetClass(Handle keyvalue, const char[] string)
{
	TFClassType class;
	static char buffer[24];
	KvGetString(keyvalue, string, buffer, sizeof(buffer));
	class = view_as<TFClassType>(StringToInt(buffer));
	if(class == TFClass_Unknown)
	{
		class = TF2_GetClass(buffer);
		if(class == TFClass_Unknown)
			class = TFClass_Scout;
	}
	return class;
}

stock void AssignTeam(int client, int team)
{
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))  //Living spectator check: 0 means that no class is selected
	{
		//PrintToConsoleAll("%N does not have a desired class", client);
		if(IsBoss(client))
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(KvGetClass(BossKV[Special[GetBossIndex(client)]], "class")));  //So we assign one to prevent living spectators
		}
		/*else
		{
			PrintToConsoleAll("%N was not a boss and did not have a desired class", client);
		}*/
	}

	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);

	if(GetEntProp(client, Prop_Send, "m_iObserverMode") && IsPlayerAlive(client))  //Welp
	{
		//PrintToConsoleAll("%N is a living spectator", client);
		if(IsBoss(client))
		{
			TF2_SetPlayerClass(client, KvGetClass(BossKV[Special[GetBossIndex(client)]], "class"));
		}
		else
		{
			//PrintToConsoleAll("Additional information: %N was not a boss", client);
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

		ArrayList disguiseArray = new ArrayList();
		for(int clientcheck=1; clientcheck<=MaxClients; clientcheck++)
		{
			if(IsValidClient(clientcheck) && GetClientTeam(clientcheck)==team && clientcheck!=client)
				disguiseArray.Push(clientcheck);
		}

		if(disguiseArray.Length < 1)
		{
			disguiseTarget = client;
		}
		else
		{
			disguiseTarget = disguiseArray.Get(GetRandomInt(0, disguiseArray.Length-1));
			if(!IsValidClient(disguiseTarget))
				disguiseTarget = client;
		}
		delete disguiseArray;

		if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			TF2_DisguisePlayer(client, view_as<TFTeam>(team), GetRandomInt(0, 1) ? TFClass_Medic : TFClass_Scout, disguiseTarget);
		}
		else
		{
			TF2_AddCondition(client, TFCond_Disguised, -1.0);
			SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
			SetEntProp(client, Prop_Send, "m_nDisguiseClass", GetRandomInt(0, 1) ? view_as<int>(TFClass_Medic) : view_as<int>(TFClass_Scout));
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

	static char classname[64];
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
		if(IsValidClient(client) && (!Enabled3 || !CheckCommandAccess(client, "ff2_boss", 0, true) || (CanBossVs[client]<2 && CanBossTeam[client]!=enemyTeam) || !ignorePrefs) && QueuePoints[client]>=QueuePoints[winner] && !omit[client])
		{
			if(cvarToggleBoss.BoolValue && view_as<int>(ToggleBoss[client])>1)	// Skip clients who have disabled being able to be a boss
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
			if(IsValidClient(client) && (!Enabled3 || !CheckCommandAccess(client, "ff2_boss", 0, true) || (CanBossVs[client]<2 && CanBossTeam[client]!=enemyTeam)) && !omit[client])
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
				if(cvarToggleBoss.BoolValue && view_as<int>(ToggleBoss[client])>1)	// Skip clients who have disabled being able to be a boss
					continue;

				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = 0;
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					IgnoreValid[client] = false;
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
					xIncoming[client][0] = 0;
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					IgnoreValid[client] = false;
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
		if(IsValidClient(client) && (!Enabled3 || !CheckCommandAccess(client, "ff2_boss", 0, true) || (!CanBossVs[client] && CanBossTeam[client]!=enemyTeam)) && QueuePoints[client]>=QueuePoints[winner] && !omit[client])
		{
			if(cvarToggleBoss.BoolValue && view_as<int>(ToggleBoss[client])>1)	// Skip clients who have disabled being able to be a boss
				continue;

			if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				winner=client;
		}
	}

	if(!winner)	// Ignore the boss toggle pref if we can't find available clients
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && (!Enabled3 || !CheckCommandAccess(client, "ff2_boss", 0, true) || (!CanBossVs[client] && CanBossTeam[client]!=enemyTeam)) && !omit[client])
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
				if(cvarToggleBoss.BoolValue && view_as<int>(ToggleBoss[client])>1)	// Skip clients who have disabled being able to be a boss
					continue;

				if(SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = 0;
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					IgnoreValid[client] = false;
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
					xIncoming[client][0] = 0;
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					IgnoreValid[client] = false;
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
		if(IsValidClient(client) && !omit[client] && (QueuePoints[client]>=QueuePoints[companion] || (cvarDuoRandom.BoolValue && !GetRandomInt(0, RoundToCeil(MaxClients/5.0)))))
		{
			if(cvarDuoBoss.BoolValue && view_as<int>(ToggleDuo[client])>1)	// Skip clients who have disabled being able to be selected as a companion
				continue;

			if(cvarToggleBoss.BoolValue && view_as<int>(ToggleBoss[client])>1)	// Skip clients who have disabled being able to be a boss
				continue;

			if((SpecForceBoss && !cvarDuoRandom.BoolValue) || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				companion=client;
		}
	}

	if(!companion)	// Ignore the companion toggle pref if we can't find available clients
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(IsValidClient(client) && !omit[client] && (QueuePoints[client]>=QueuePoints[companion] || (cvarDuoRandom.BoolValue && !GetRandomInt(0, RoundToCeil(MaxClients/5.0)))))
			{
				if(cvarToggleBoss.BoolValue && view_as<int>(ToggleBoss[client])>1) // Skip clients who have disabled being able to be a boss
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
			if(IsValidClient(client) && !omit[client] && (QueuePoints[client]>=QueuePoints[companion] || (cvarDuoRandom.BoolValue && !GetRandomInt(0, RoundToCeil(MaxClients/5.0)))))
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

stock int Operate(ArrayList sumArray, int &bracket, float value, ArrayList _operator)
{
	float sum = sumArray.Get(bracket);
	switch(_operator.Get(bracket))
	{
		case Operator_Add:
		{
			sumArray.Set(bracket, sum+value);
		}
		case Operator_Subtract:
		{
			sumArray.Set(bracket, sum-value);
		}
		case Operator_Multiply:
		{
			sumArray.Set(bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				LogToFile(eLog, "[Boss] Detected a divide by 0!");
				bracket = 0;
				return;
			}
			sumArray.Set(bracket, sum/value);
		}
		case Operator_Exponent:
		{
			sumArray.Set(bracket, Pow(sum, value));
		}
		default:
		{
			sumArray.Set(bracket, value);  //This means we're dealing with a constant
		}
	}
	_operator.Set(bracket, Operator_None);
}

stock void OperateString(ArrayList sumArray, int &bracket, char[] value, int size, ArrayList _operator)
{
	if(!value[0])  //Make sure 'value' isn't blank
		return;

	Operate(sumArray, bracket, StringToFloat(value), _operator);
	strcopy(value, size, "");
}

stock int ParseFormula(int boss, const char[] key, const char[] defaultFormula, int defaultValue)
{
	static char formula[1024], bossName[64];
	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], "filename", bossName, sizeof(bossName));
	KvGetString(BossKV[Special[boss]], key, formula, sizeof(formula), defaultFormula);

	float players = 1.0;
	if(Enabled3)
	{
		if(BossSwitched[boss])
		{
			players += bosses + playingboss - playingmerc*0.75;
		}
		else
		{
			players += bosses + playingmerc - playingboss*0.75;
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

	ArrayList sumArray = new ArrayList(_, size);
	ArrayList _operator = new ArrayList(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	sumArray.Set(0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	_operator.Set(bracket, Operator_None);

	char character[2], value[16];
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
				sumArray.Set(bracket, 0.0);
				_operator.Set(bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(_operator.Get(bracket) != Operator_None)  //Something like (5*)
				{
					LogToFile(eLog, "[Boss] %s's %s formula has an invalid operator at character %i", bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogToFile(eLog, "[Boss] %s's %s formula has an unbalanced parentheses at character %i", bossName, key, i+1);
					delete sumArray;
					delete _operator;
					return defaultValue;
				}

				Operate(sumArray, bracket, sumArray.Get(bracket+1), _operator);
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
						_operator.Set(bracket, Operator_Add);
					}
					case '-':
					{
						_operator.Set(bracket, Operator_Subtract);
					}
					case '*':
					{
						_operator.Set(bracket, Operator_Multiply);
					}
					case '/':
					{
						_operator.Set(bracket, Operator_Divide);
					}
					case '^':
					{
						_operator.Set(bracket, Operator_Exponent);
					}
				}
			}
		}
	}

	float result = sumArray.Get(0);
	delete sumArray;
	delete _operator;

	float addition = cvarTimesTen.FloatValue;
	if(result < 1)
	{
		LogToFile(eLog, "[Boss] %s has an invalid %s, using default!", bossName, key);
		if(TimesTen && addition!=1 && addition>0)
			return RoundFloat(defaultValue*addition);

		return defaultValue;
	}

	if(TimesTen && addition!=1 && addition>0)
		result *= addition;

	if(StrContains(key, "ragedamage", false))
	{
		if(bMedieval)
			return RoundFloat(result/3.6);  //TODO: Make this configurable
	}
	return RoundFloat(result);
}

stock int GetAbilityArgument(int index, const char[] plugin_name, const char[] ability_name, int arg, int defvalue=0)
{
	char str[10];
	FormatEx(str, sizeof(str), "arg%i", arg);
	return GetArgumentI(index, plugin_name, ability_name, str, defvalue);
}

stock float GetAbilityArgumentFloat(int index, const char[] plugin_name, const char[] ability_name, int arg, float defvalue=0.0)
{
	char str[10];
	FormatEx(str, sizeof(str), "arg%i", arg);
	return GetArgumentF(index, plugin_name, ability_name, str, defvalue);
}

stock void GetAbilityArgumentString(int index, const char[] plugin_name, const char[] ability_name, int arg, char[] buffer, int buflen)
{
	char str[10];
	FormatEx(str, sizeof(str), "arg%i", arg);
	GetArgumentS(index, plugin_name, ability_name, str, buffer, buflen);
}

stock int GetArgumentI(int index, const char[] plugin_name, const char[] ability_name, const char[] arg, int defvalue=0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return defvalue;
	
	FF2Data data = FF2Data(index, plugin_name, ability_name);
	return data.Invalid ? defvalue:data.GetArgI(arg, defvalue);
}

stock float GetArgumentF(int index, const char[] plugin_name, const char[] ability_name, const char[] arg, float defvalue=0.0)
{
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return defvalue;

	FF2Data data = FF2Data(index, plugin_name, ability_name);
	return data.Invalid ? defvalue:data.GetArgF(arg, defvalue);
}

stock void GetArgumentS(int index, const char[] plugin_name, const char[] ability_name, const char[] arg, char[] buffer, int buflen)
{
	buffer[0] = '\0';
	if(index==-1 || Special[index]==-1 || !BossKV[Special[index]])
		return;
	
	FF2Data data = FF2Data(index, plugin_name, ability_name);
	if(!data.Invalid)
		data.GetArgS(arg, buffer, buflen);
}

stock bool RandomSound(const char[] sound, char[] file, int length, int boss=0)
{
	if(boss<0 || Special[boss]<0 || !BossKV[Special[boss]])
		return false;

	KvRewind(BossKV[Special[boss]]);
	if(!KvJumpToKey(BossKV[Special[boss]], sound))
	{
		KvRewind(BossKV[Special[boss]]);
		return false;  // Requested sound not implemented for this boss
	}

	char key[10];
	int sounds;
	while(++sounds)  // Just keep looping until there's no keys left
	{
		IntToString(sounds, key, sizeof(key));
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
		{
			sounds--;  // This sound wasn't valid, so don't include it
			break;  // Assume that there's no more sounds
		}
	}

	if(!sounds)
		return false;  //Found sound, but no sounds inside of it

	char path[PLATFORM_MAX_PATH];
	static char temp[6];
	int choosen = GetRandomInt(1, sounds);
	FormatEx(key, sizeof(key), "%i_overlay", choosen);	// Don't ask me why this format just go with it
	KvGetString(BossKV[Special[boss]], key, path, sizeof(path));
	if(path[0])
	{
		TFTeam team = TF2_GetClientTeam(Boss[boss]);
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && TF2_GetClientTeam(client)!=team)
				DoOverlay(client, path);
		}

		FormatEx(path, sizeof(path), "%i_overlay_time", choosen);
		float time = KvGetFloat(BossKV[Special[boss]], path);
		if(time > 0)
			CreateTimer(time, Timer_RemoveOverlay, team, TIMER_FLAG_NO_MAPCHANGE);

		//PrintToConsoleAll("%s | %i | %f", path, view_as<int>(team), time);
	}

	FormatEx(key, sizeof(key), "%imusic", choosen);	// And this...
	KvGetString(BossKV[Special[boss]], key, temp, sizeof(temp));
	if(temp[0])
	{
		float time = KvGetFloat(BossKV[Special[boss]], key);

		static char name[64], artist[64];

		IntToString(choosen, key, sizeof(key));
		KvGetString(BossKV[Special[boss]], key, path, sizeof(path));

		FormatEx(key, sizeof(key), "%iname", choosen);
		KvGetString(BossKV[Special[boss]], key, name, sizeof(name));

		FormatEx(key, sizeof(key), "%iartist", choosen);
		KvGetString(BossKV[Special[boss]], key, artist, sizeof(artist));

		for(int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client))
			{
				StopMusic(client);
				strcopy(currentBGM[client], sizeof(currentBGM[]), path);
				PlayBGM(client, path, time, name, artist);
			}
		}
		return false; // Don't return to play sound
	}

	IntToString(choosen, key, sizeof(key));
	KvGetString(BossKV[Special[boss]], key, file, length);  // Populate file
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

		FormatEx(key, sizeof(key), "slot%i", sounds);
		if(KvGetNum(BossKV[Special[boss]], key)==slot)
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

	char key[10];
	static char replacement[PLATFORM_MAX_PATH];
	int sounds, matches, match[MAXRANDOMS];
	while(++sounds)
	{
		IntToString(sounds, key, 4);
		KvGetString(BossKV[Special[boss]], key, file, length);
		if(!file[0])
			break;  //Assume that there's no more sounds

		FormatEx(key, sizeof(key), "vo%i", sounds);
		KvGetString(BossKV[Special[boss]], key, replacement, sizeof(replacement));
		if(!StrContains(replacement, oldFile, false))
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
	static char temp[PLATFORM_MAX_PATH];
	GetCurrentMap(temp, sizeof(temp));
	if(!temp[0])
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
	static char characterName[64];
	if(boss == companion)
	{
		Special[boss] = Incoming[boss];
		Incoming[boss] = -1;
		if(Special[boss] != -1)  //We've already picked a boss through Command_SetNextBoss
		{
			static char newName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", newName, sizeof(newName));
			
			Action action;
			Call_StartForward(OnSpecialSelected);
			Call_PushCell(boss);
			int characterIndex = Special[boss];
			Call_PushCellRef(characterIndex);
			Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
			Call_PushCell(true);  //Preset
			Call_Finish(action);
			if(action == Plugin_Changed)
			{
				if(newName[0])
				{
					int foundExactMatch = -1;
					int foundPartialMatch = -1;
					for(int character; BossKV[character] && character<MAXSPECIALS; character++)
					{
						KvRewind(BossKV[character]);
						KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch = character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false)!=-1)
						{
							foundPartialMatch = character;
						}

						//Do the same thing as above here, but look at the filename instead of the boss name
						KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch = character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false) != -1)
						{
							foundPartialMatch = character;
						}
					}

					if(foundExactMatch != -1)
					{
						Special[boss] = foundExactMatch;
					}
					else if(foundPartialMatch != -1)
					{
						Special[boss] = foundPartialMatch;
					}
					else
					{
						return false;
					}
					_FF2Save.RegisterCharacter(characterName, boss);
					PrecacheCharacter(Special[boss]);
					return true;
				}
				Special[boss] = characterIndex;
				KvGetString(BossKV[Special[boss]], "filename", characterName, sizeof(characterName));
				_FF2Save.RegisterCharacter(characterName, boss);
				PrecacheCharacter(Special[boss]);
				return true;
			}
			/*else
			{
				int client = Boss[boss];
				if(xIncoming[client][0])
				{
					static char characterName[64];
					int foundExactMatch = -1, foundPartialMatch = -1;
					for(int character; BossKV[character] && character<MAXSPECIALS; character++)
					{
						KvRewind(BossKV[character]);
						KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
						if(StrEqual(xIncoming[client], characterName, false))
						{
							foundExactMatch = character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(xIncoming[client], characterName, false) != -1)
						{
							foundPartialMatch=character;
						}

						//Do the same thing as above here, but look at the filename instead of the boss name
						KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
						if(StrEqual(xIncoming[client], characterName, false))
						{
							foundExactMatch = character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(xIncoming[client], characterName, false) != -1)
						{
							foundPartialMatch = character;
						}
					}

					if(foundExactMatch != -1)
					{
						Special[boss] = foundExactMatch;
					}
					else if(foundPartialMatch != -1)
					{
						Special[boss] = foundPartialMatch;
					}
					else
					{
						return false;
					}
					PrecacheCharacter(Special[boss]);
					return true;
				}
				Special[boss] = characterIndex;
				PrecacheCharacter(Special[boss]);
				return true;
			}*/
			
			KvGetString(BossKV[Special[boss]], "filename", characterName, sizeof(characterName));
			_FF2Save.RegisterCharacter(characterName, boss);
			PrecacheCharacter(Special[boss]);
			return true;
		}

		for(int tries; tries<100; tries++)
		{
			if(ChancesString[0])
			{
				int characterIndex = chancesIndex;  //Don't touch chancesIndex since it doesn't get reset
				int i = GetRandomInt(0, chances[characterIndex-1]);

				while(characterIndex>=2 && i<chances[characterIndex-1])
				{
					Special[boss] = chances[characterIndex-2]-1;
					characterIndex -= 2;
				}
			}
			else
			{
				Special[boss] = GetRandomInt(0, Specials-1);
			}

			static char companionName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName));
			if(MapBlocked[Special[boss]] ||
			   KvGetNum(BossKV[Special[boss]], "blocked") ||
			   KvGetNum(BossKV[Special[boss]], "donator") ||
			   KvGetNum(BossKV[Special[boss]], "admin") ||
			   KvGetNum(BossKV[Special[boss]], "owner") ||
			   KvGetNum(BossKV[Special[boss]], "theme") ||
			  (KvGetNum(BossKV[Special[boss]], "nofirst") && RoundCount<=arenaRounds) ||
			  (companionName[0] && !DuoMin) ||
			  (Enabled3 && (KvGetNum(BossKV[Special[boss]], "noversus")==2 ||
			  (KvGetNum(BossKV[Special[boss]], "noversus")==1 && BossSwitched[boss]) ||
			  (KvGetNum(BossKV[Special[boss]], "bossteam")==BossTeam && BossSwitched[boss]) ||
			  (KvGetNum(BossKV[Special[boss]], "bossteam")==OtherTeam && !BossSwitched[boss]))))
			{
				Special[boss] = -1;
				continue;
			}
			break;
		}
	}
	else
	{
		static char bossName[64], companionName[64];
		KvRewind(BossKV[Special[boss]]);
		KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName), "=Failed companion name=");

		int character;
		while(character < Specials)  //Loop through all the bosses to find the companion we're looking for
		{
			KvRewind(BossKV[character]);
			KvGetString(BossKV[character], "name", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				Special[companion] = character;
				break;
			}

			KvGetString(BossKV[character], "filename", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				Special[companion] = character;
				break;
			}
			character++;
		}

		if(character == Specials)  //Companion not found
			return false;
	}

	//All of the following uses `companion` because it will always be the boss index we want
	Action action;
	Call_StartForward(OnSpecialSelected);
	Call_PushCell(companion);
	int characterIndex = Special[companion];
	Call_PushCellRef(characterIndex);
	static char newName[64];
	KvRewind(BossKV[Special[companion]]);
	KvGetString(BossKV[Special[companion]], "name", newName, sizeof(newName));
	Call_PushStringEx(newName, sizeof(newName), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCell(false);  //Not preset
	Call_Finish(action);
	if(action == Plugin_Changed)
	{
		if(newName[0])
		{
			int foundExactMatch = -1;
			int foundPartialMatch = -1;
			for(int character; BossKV[character] && character<MAXSPECIALS; character++)
			{
				KvRewind(BossKV[character]);
				KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch = character;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch = character;
				}

				//Do the same thing as above here, but look at the filename instead of the boss name
				KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch = character;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch = character;
				}
			}

			if(foundExactMatch != -1)
			{
				Special[companion] = foundExactMatch;
			}
			else if(foundPartialMatch != -1)
			{
				Special[companion] = foundPartialMatch;
			}
			else
			{
				return false;
			}
			KvGetString(BossKV[Special[companion]], "filename", characterName, sizeof(characterName));
			_FF2Save.RegisterCharacter(characterName, companion);
			PrecacheCharacter(Special[companion]);
			return true;
		}
		Special[companion] = characterIndex;
		KvGetString(BossKV[Special[companion]], "filename", characterName, sizeof(characterName));
		_FF2Save.RegisterCharacter(characterName, companion);
		PrecacheCharacter(Special[companion]);
		return true;
	}
	KvGetString(BossKV[Special[companion]], "filename", characterName, sizeof(characterName));
	_FF2Save.RegisterCharacter(characterName, companion);
	PrecacheCharacter(Special[companion]);
	return true;
}

void FindCompanion(int boss, int players, bool[] omit)
{
	static int playersNeeded = 2;
	static char companionName[64];
	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName));
	if(playersNeeded<players && companionName[0])  //Only continue if we have enough players and if the boss has a companion
	{
		int companion = GetRandomValidClient(omit);
		Boss[companion] = companion;
		BossSwitched[companion] = BossSwitched[boss];
		omit[companion] = true;
		int client = Boss[boss];
		if(PickCharacter(boss, companion))  //TODO: This is a bit misleading
		{
			if(BossRageDamage[companion] == 1)	// If 1, toggle infinite rage
			{
				InfiniteRageActive[client] = true;
				CreateTimer(0.2, Timer_InfiniteRage, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				BossRageDamage[companion] = 1;
			}
			else if(BossRageDamage[companion] == -1)	// If -1, never rage
			{
				BossRageDamage[companion] = 99999;
			}
			else	// Use formula or straight value
			{
				BossRageDamage[companion] = ParseFormula(companion, "ragedamage", RageDamage, 1900);
			}
			BossLivesMax[companion] = KvGetNum(BossKV[Special[companion]], "lives", 1);
			if(BossLivesMax[companion] < 1)
			{
				LogToFile(eLog, "[Boss] Boss %s has an invalid amount of lives, setting to 1", companionName);
				BossLivesMax[companion] = 1;
			}
			playersNeeded++;
			FindCompanion(companion, players, omit);  //Make sure this companion doesn't have a companion of their own
		}
	}
	playersNeeded = 2;  //Reset the amount of players needed back after we're done
}

public int HintPanelH(Menu menu, MenuAction action, int client, int selection)
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
	else if(action==MenuAction_Select || (action==MenuAction_Cancel && selection==MenuCancel_Exit))
	{
		FF2flags[client] |= FF2FLAG_CLASSHELPED;
	}
}

public int QueuePanelH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(selection == 9)
				TurnToZeroPanel(client, client);
		}
	}
}

public Action QueuePanelCmd(int client, int args)
{
	bool[] added = new bool[MaxClients+1];
	for(int boss; boss<=MaxClients; boss++)
	{	// Don't want the bosses to show up again in the actual queue list
		if(IsBoss(boss))
			added[boss] = true;
	}

	Menu menu = new Menu(QueuePanelH);
	menu.SetTitle("%T", "thequeue", client);
	char text[64];
	for(int i; i<9; i++)
	{
		int target = GetClientWithMostQueuePoints(added, _, false);  //Get whoever has the highest queue points out of those who haven't been listed yet
		if(!IsValidClient(target))  //When there's no players left, fill up the rest of the list with blank lines
		{
			menu.AddItem("", "");
			continue;
		}

		FormatEx(text, sizeof(text), "%N-%i", target, QueuePoints[target]);
		menu.AddItem(text, text, client==target ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		added[target] = true;
	}

	FormatEx(text, sizeof(text), "%T (%T)", "your_points", client, QueuePoints[client], "to0", client);  //"Your queue point(s) is {1} (set to 0)"
	menu.AddItem(text, text);

	menu.Pagination = false;
	menu.Display(client, MENU_TIME_FOREVER);
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
		TurnToZeroPanelH(view_as<Menu>(INVALID_HANDLE), MenuAction_Select, client, 0);
		return Plugin_Handled;
	}

	AdminId admin = GetUserAdmin(client);	 //Normal players
	if((admin==INVALID_ADMIN_ID) || !GetAdminFlag(admin, Admin_Cheats))
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(args != 1)  //Admins
	{
		FReplyToCommand(client, "Usage: ff2_resetqueuepoints <target>");
		return Plugin_Handled;
	}

	static char pattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof(pattern));
	static char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, 1, 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches > 1)
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

public int TurnToZeroPanelH(Menu menu, MenuAction action, int client, int position)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{	
			if(!position)
			{
				if(shortname[client] == client)
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

	Menu menu = new Menu(TurnToZeroPanelH);
	char text[128];
	if(client == target)
	{
		FormatEx(text, sizeof(text), "%T", "to0_title", client);  //Do you really want to set your queue points to 0?
	}
	else
	{
		FormatEx(text, sizeof(text), "%T", "to0_title_admin", client, target);  //Do you really want to set {1}'s queue points to 0?
	}

	PrintToChat(client, text);
	menu.SetTitle(text);
	FormatEx(text, sizeof(text), "%T", "Yes", client);
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%T", "No", client);
	menu.AddItem(text, text);
	shortname[client] = target;
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

stock bool IsBoss(int client)
{
	if(IsValidClient(client) && Enabled)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Boss[boss] == client)
				return true;
		}
	}
	return false;
}

public Action Timer_RemoveOverlay(Handle timer, TFTeam bossTeam)
{
	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && TF2_GetClientTeam(target)!=bossTeam)
			ClientCommand(target, "r_screenoverlay off");
	}
	SetCommandFlags("r_screenoverlay", flags);
	return Plugin_Continue;
}

void DoOverlay(int client, const char[] overlay)
{
	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	if(overlay[0])
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	}
	else
	{
		ClientCommand(client, "r_screenoverlay off");
	}
	SetCommandFlags("r_screenoverlay", flags);
}

public void CheckDuoMin()
{
	int i;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
		{
			i++;
			if(i >= cvarDuoMin.IntValue)
			{
				DuoMin = true;
				return;
			}
		}
	}
	DuoMin = false;
}

public int FF2PanelH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			switch(selection)
			{
				case 0:
					Command_GetHPCmd(client, 0);

				case 1:
					Command_SetMyBoss(client, 0);

				case 2:
					Command_HelpPanelClass(client, 0);

				case 3:
					NewPanelCmd(client, 0);

				case 4:
					QueuePanelCmd(client, 0);

				case 5:
					Command_HudMenu(client, 0);

				case 6:
					MusicTogglePanelCmd(client, 0);

				case 7:
					VoiceTogglePanelCmd(client, 0);

				case 8:
					HelpPanel3Cmd(client, 0);
			}
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

	Menu menu = new Menu(FF2PanelH);
	char text[256];
	SetGlobalTransTarget(client);
	FormatEx(text, sizeof(text), "%t", "menu_1");  //What's up?
	menu.SetTitle(text);
	FormatEx(text, sizeof(text), "%t", "menu_2");  //Investigate the boss's current health level (/ff2hp)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_3");  //Boss Preferences (/ff2boss)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_7");  //Changes to my class in FF2 (/ff2classinfo)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_4");  //What's new? (/ff2new).
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_5");  //Queue points
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_0");  //Toggle HUDs (/ff2hud)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_8");  //Toggle music (/ff2music)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_9");  //Toggle monologues (/ff2voice)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_9a");  //Toggle info about changes of classes in FF2
	menu.AddItem(text, text);
	menu.Pagination = false;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action NewPanelCmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	static char url[192];
	cvarChangelog.GetString(url, sizeof(url));
	Format(url, sizeof(url), "%s#%s.%s.%s", url, FORK_MAJOR_REVISION, FORK_MINOR_REVISION, FORK_STABLE_REVISION);
	KeyValues kv = CreateKeyValues("data");
	kv.SetString("title", "Unofficial FF2 Changelog");
	kv.SetString("msg", url);
	kv.SetNum("customsvr", 1);
	kv.SetNum("type", MOTDPANEL_TYPE_URL);
	ShowVGUIPanel(client, "info", kv, true);
	delete kv;
	return Plugin_Handled;
}

public Action HelpPanel3Cmd(int client, int args)
{
	if(!IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!cvarAdvancedMusic.BoolValue)
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
	Menu menu = new Menu(ClassInfoTogglePanelH);
	menu.SetTitle("Turn the Freak Fortress 2 class info...");
	menu.AddItem("On", "On");
	menu.AddItem("Off", "Off");
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int ClassInfoTogglePanelH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(selection)
			{
				ToggleInfo[client] = false;
			}
			else
			{
				ToggleInfo[client] = true;
			}
			FPrintToChat(client, "%t", "ff2_classinfo", selection ? "off" : "on");	// TODO: Make this more multi-language friendly
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

	int boss = GetBossIndex(client);
	if(boss != -1)
	{
		HelpPanelBoss(boss);
		return Plugin_Continue;
	}

	TFClassType class = TF2_GetPlayerClass(client);
	char text[512], translation[64];

	SetGlobalTransTarget(client);
	int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(weapon))
	{
		FormatEx(translation, sizeof(translation), "primary_%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		if(TranslationPhraseExists(translation))
		{
			FormatEx(text, sizeof(text), "%t\n", translation);
		}
		else
		{
			switch(class)
			{
				case TFClass_Scout:
					FormatEx(text, sizeof(text), "%t\n", "primary_scout");

				case TFClass_Soldier:
					FormatEx(text, sizeof(text), "%t\n", "primary_soldier");

				case TFClass_Pyro:
					FormatEx(text, sizeof(text), "%t\n", "primary_pyro");

				case TFClass_DemoMan:
					FormatEx(text, sizeof(text), "%t\n", "primary_demo");

				case TFClass_Heavy:
					FormatEx(text, sizeof(text), "%t\n", "primary_heavy");

				case TFClass_Engineer:
					FormatEx(text, sizeof(text), "%t\n", "primary_engineer");

				case TFClass_Medic:
					FormatEx(text, sizeof(text), "%t\n", "primary_medic");

				case TFClass_Sniper:
					FormatEx(text, sizeof(text), "%t\n", "primary_sniper");

				case TFClass_Spy:
					FormatEx(text, sizeof(text), "%t\n", "primary_spy");

				default:
					FormatEx(text, sizeof(text), "%t\n", "primary_merc");
			}
		}
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(weapon))
	{
		FormatEx(translation, sizeof(translation), "secondary_%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		if(TranslationPhraseExists(translation))
		{
			Format(text, sizeof(text), "%s%t\n", text, translation);
		}
		else
		{
			switch(class)
			{
				case TFClass_Scout:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_scout");

				case TFClass_Soldier:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_soldier");

				case TFClass_Pyro:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_pyro");

				case TFClass_DemoMan:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_demo");

				case TFClass_Heavy:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_heavy");

				case TFClass_Engineer:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_engineer");

				case TFClass_Medic:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_medic");

				case TFClass_Sniper:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_sniper");

				case TFClass_Spy:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_spy");

				default:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_merc");
			}
		}
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(weapon))
	{
		FormatEx(translation, sizeof(translation), "melee_%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		if(TranslationPhraseExists(translation))
		{
			Format(text, sizeof(text), "%s%t\n", text, translation);
		}
		else
		{
			switch(class)
			{
				case TFClass_Scout:
					Format(text, sizeof(text), "%s%t\n", text, "melee_scout");

				case TFClass_Soldier:
					Format(text, sizeof(text), "%s%t\n", text, "melee_soldier");

				case TFClass_Pyro:
					Format(text, sizeof(text), "%s%t\n", text, "melee_pyro");

				case TFClass_DemoMan:
					Format(text, sizeof(text), "%s%t\n", text, "melee_demo");

				case TFClass_Heavy:
					Format(text, sizeof(text), "%s%t\n", text, "melee_heavy");

				case TFClass_Engineer:
					Format(text, sizeof(text), "%s%t\n", text, "melee_engineer");

				case TFClass_Medic:
					Format(text, sizeof(text), "%s%t\n", text, "melee_medic");

				case TFClass_Sniper:
					Format(text, sizeof(text), "%s%t\n", text, "melee_sniper");

				case TFClass_Spy:
					Format(text, sizeof(text), "%s%t\n", text, "melee_spy");

				default:
					Format(text, sizeof(text), "%s%t\n", text, "melee_merc");
			}
		}
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Building);
	if(IsValidEntity(weapon))
	{
		FormatEx(translation, sizeof(translation), "pda_%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		if(TranslationPhraseExists(translation))
		{
			Format(text, sizeof(text), "%s%t\n", text, translation);
		}
		else
		{
			switch(class)
			{
				case TFClass_Engineer:
					Format(text, sizeof(text), "%s%t\n", text, "pda_engineer");

				case TFClass_Spy:
					Format(text, sizeof(text), "%s%t\n", text, "pda_spy");
			}
		}
	}

	if(text[0])
	{
		Format(text, sizeof(text), "%t\n\n%s", "info_title", text);
		Menu menu = new Menu(HintPanelH);
		menu.SetTitle(text);
		FormatEx(text, sizeof(text), "%t", "Exit");
		menu.AddItem(text, text);
		menu.ExitButton = false;
		menu.OptionFlags |= MENUFLAG_NO_SOUND;
		menu.Display(client, 25);
	}
	return Plugin_Continue;
}

void HelpPanelBoss(int boss)
{
	if(!IsValidClient(Boss[boss]))
		return;

	char text[512], language[20];
	GetLanguageInfo(GetClientLanguage(Boss[boss]), language, 8, text, 8);
	FormatEx(language, sizeof(language), "description_%s", language);

	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], language, text, sizeof(text));
	if(!text[0])
	{
		KvGetString(BossKV[Special[boss]], "description_en", text, sizeof(text));  //Default to English if their language isn't available
		if(!text[0])
			return;
	}
	ReplaceString(text, sizeof(text), "\\n", "\n");

	Menu menu = new Menu(HintPanelH);
	menu.SetTitle(text);
	FormatEx(text, sizeof(text), "%T", "Exit", Boss[boss]);
	menu.AddItem(text, text);
	menu.ExitButton = false;
	menu.OptionFlags |= MENUFLAG_NO_SOUND;
	menu.Display(Boss[boss], 25);
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
		static char cmd[64];
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
	if(!cvarAdvancedMusic.BoolValue)
	{
		Menu menu = new Menu(MusicTogglePanelH);
		menu.SetTitle("Turn the Freak Fortress 2 music...");
		menu.AddItem("On", "On");
		menu.AddItem("Off", "Off");
		menu.ExitButton = false;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		char title[128];
		Menu menu = new Menu(MusicTogglePanelH);
		SetGlobalTransTarget(client);
		FormatEx(title, sizeof(title), "%t", "theme_menu");
		menu.SetTitle(title, title);
		if(ToggleMusic[client])
		{
			FormatEx(title, sizeof(title), "%t", "themes_disable");
			menu.AddItem(title, title);
			FormatEx(title, sizeof(title), "%t", "theme_skip");
			menu.AddItem(title, title);
			FormatEx(title, sizeof(title), "%t", "theme_shuffle");
			menu.AddItem(title, title);
			if(cvarSongInfo.IntValue >= 0)
			{
				FormatEx(title, sizeof(title), "%t", "theme_select");
				menu.AddItem(title, title);
			}
		}
		else
		{
			FormatEx(title, sizeof(title), "%t", "themes_enable");
			menu.AddItem(title, title);
		}
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Continue;
}

public int MusicTogglePanelH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!cvarAdvancedMusic.BoolValue)
			{
				if(selection)  //Off
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

	if(!cvarAdvancedMusic.BoolValue)
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

	if(CheckRoundState() != 1)
	{
		FReplyToCommand(client, "%t", "ff2_please wait");
		return Plugin_Handled;
	}

	FReplyToCommand(client, "%t", "track_skipped");

	StopMusic(client, true);

	KvRewind(BossKV[Special[0]]);
	if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH], id3[6][256];
		int index;
		do
		{
			index++;
			FormatEx(music, 10, "time%i", index);
		}
		while(KvGetFloat(BossKV[Special[0]], music) > 1);

		if(!index)
		{
			FReplyToCommand(client, "%t", "ff2_no_music");
			return Plugin_Handled;
		}

		cursongId[client]++;
		if(cursongId[client] >= index)
			cursongId[client] = 1;

		char lives[256];
		FormatEx(lives, sizeof(lives), "life%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
		if(lives[0])
		{
			if(StringToInt(lives) != BossLives[0])
			{
				for(int i; i<index-1; i++)
				{
					if(StringToInt(lives) != BossLives[0])
					{
						cursongId[client] = i;
						continue;
					}
					break;
				}
			}
		}

		FormatEx(music, 10, "time%i", cursongId[client]);
		float time = KvGetFloat(BossKV[Special[0]], music);
		FormatEx(music, 10, "path%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], music, music, sizeof(music));

		FormatEx(id3[0], sizeof(id3[]), "name%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
		FormatEx(id3[1], sizeof(id3[]), "artist%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));

		char temp[PLATFORM_MAX_PATH];
		FormatEx(temp, sizeof(temp), "sound/%s", music);
		if(FileExists(temp, true))
		{
			PlayBGM(client, music, time, id3[2], id3[3]);
		}
		else
		{
			KvGetString(BossKV[Special[0]], "filename", lives, sizeof(lives));
			LogToFile(eLog, "[Boss] Character %s is missing BGM file '%s'!", lives, temp);
			if(MusicTimer[client] != null) {
				delete MusicTimer[client];
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

	if(!cvarAdvancedMusic.BoolValue)
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

	if(!cvarAdvancedMusic.BoolValue || cvarSongInfo.IntValue<0)
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

	Menu menu = new Menu(Command_TrackListH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "track_select");
	KvRewind(BossKV[Special[0]]);
	if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH], id3[6][256];
		int index;
		do
		{
			index++;
			FormatEx(music, 10, "time%i", index);
		}
		while(KvGetFloat(BossKV[Special[0]], music) > 1);

		if(!index)
		{
			FReplyToCommand(client, "%t", "ff2_no_music");
			return Plugin_Handled;
		}

		char lives[256];
		for(int trackIdx=1; trackIdx<=index-1; trackIdx++)
		{
			FormatEx(lives, sizeof(lives), "life%i", trackIdx);
			KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
			if(lives[0])
			{
				if(StringToInt(lives) != BossLives[0])
					continue;
			}
			FormatEx(id3[0], sizeof(id3[]), "name%i", trackIdx);
			KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
			FormatEx(id3[1], sizeof(id3[]), "artist%i", trackIdx);
			KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));
			GetSongTime(trackIdx, id3[5], sizeof(id3[]));
			if(!id3[3])
				FormatEx(id3[3], sizeof(id3[]), "%t", "unknown_artist");

			if(!id3[2])
				FormatEx(id3[2], sizeof(id3[]), "%t", "unknown_song");

			FormatEx(id3[4], sizeof(id3[]), "%s - %s (%s)", id3[3], id3[2], id3[5]);
			CRemoveTags(id3[4], sizeof(id3[]));
			menu.AddItem(id3[4], id3[4]);
		}
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

stock float GetSongLength(char[] trackIdx)
{
	float duration;
	static char bgmTime[128];
	KvGetString(BossKV[Special[0]], trackIdx, bgmTime, sizeof(bgmTime));
	if(StrContains(bgmTime, ":", false)!=-1) // new-style MM:SS:MSMS
	{
		static char time2[32][32];
		int count = ExplodeString(bgmTime, ":", time2, sizeof(time2), sizeof(time2));
		if(count > 0)
		{
			char newTime[64];
			for(int i; i<count; i+=3)
			{
				int mins = StringToInt(time2[i])*60;
				int secs = StringToInt(time2[i+1]);
				int milsecs = StringToInt(time2[i+2]);
				FormatEx(newTime, sizeof(newTime), "%i.%i", mins+secs, milsecs);
				duration = StringToFloat(newTime);
			}
		}
	}
	else // old style seconds
	{
		duration = KvGetFloat(BossKV[Special[0]], trackIdx);
	}
	return duration;
}

stock void GetSongTime(int trackIdx, char[] timeStr, int length)
{
	char songIdx[32];
	FormatEx(songIdx, sizeof(songIdx), "time%i", trackIdx);
	int time = RoundToFloor(GetSongLength(songIdx));
	if(time/60 > 9)
	{
		IntToString(time/60, timeStr, length);
	}
	else
	{
		Format(timeStr, length, "0%i", time/60);
	}

	if(time%60 > 9)
	{
		Format(timeStr, length, "%s:%i", timeStr, time%60);
	}
	else
	{
		Format(timeStr, length, "%s:0%i", timeStr, time%60);
	}
}

public int Command_TrackListH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			StopMusic(param1, true);
			KvRewind(BossKV[Special[0]]);
			if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
			{
				char music[PLATFORM_MAX_PATH];
				int track = param2+1;
				FormatEx(music, 10, "time%i", track);

				float time = GetSongLength(music);
				FormatEx(music, 10, "path%i", track);
				KvGetString(BossKV[Special[0]], music, music, sizeof(music));

				char id3[4][256];
				FormatEx(id3[0], sizeof(id3[]), "name%i", track);
				KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
				FormatEx(id3[1], sizeof(id3[]), "artist%i", track);
				KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));

				char temp[PLATFORM_MAX_PATH], lives[256];
				FormatEx(temp, sizeof(temp), "sound/%s", music);
				if(FileExists(temp, true))
				{
					FormatEx(lives, sizeof(lives), "life%i", track);
					KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
					if(lives[0])
					{
						if(StringToInt(lives) != BossLives[0])
						{
							if(MusicTimer[param1] != INVALID_HANDLE)
								KillTimer(MusicTimer[param1]);

							return;
						}
					}
					PlayBGM(param1, music, time, id3[2], id3[3]);
				}
				else
				{
					char bossName[64];
					KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
					LogToFile(eLog, "[Boss] Character %s is missing BGM file '%s'!", bossName, temp);
					if(MusicTimer[param1] != INVALID_HANDLE)
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

	if(!cvarAdvancedMusic.BoolValue)
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
	Menu menu = new Menu(VoiceTogglePanelH);
	menu.SetTitle("Turn the Freak Fortress 2 voices...");
	menu.AddItem("On", "On");
	menu.AddItem("Off", "Off");
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

public int VoiceTogglePanelH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
		}
		case MenuAction_Select:
		{
			if(selection)
			{
				ToggleVoice[client] = false;
			}
			else
			{
				ToggleVoice[client] = true;
			}

			FPrintToChat(client, "%t", "ff2_voice", selection ? "off" : "on");	// TODO: Make this more multi-language friendly
			if(selection)
				FPrintToChat(client, "%t", "ff2_voice2");
		}
	}
}

public Action HookSound(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
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

		if(channel==SNDCHAN_VOICE || (channel==SNDCHAN_STATIC && !StrContains(sound, "vo")))
		{
			if(FF2flags[Boss[disguiseboss]] & FF2FLAG_TALKING)
				return Plugin_Continue;
	
			static char newSound[PLATFORM_MAX_PATH];
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

	if(channel==SNDCHAN_VOICE || (channel==SNDCHAN_STATIC && !StrContains(sound, "vo")))
	{
		if(FF2flags[Boss[boss]] & FF2FLAG_TALKING)
			return Plugin_Continue;

		static char newSound[PLATFORM_MAX_PATH];
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
	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");

		return -1;
	}

	if(IsValidEntity(medigun))
	{
		static char classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(StrEqual(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		}
	}
	return -1;
}

stock bool IsValidClient(int client, bool replaycheck=true)
{
	if(client<1 || client>MaxClients)
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

public void CvarChangeNextmap(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(IsFF2Map(newValue))
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

	Menu menu = new Menu(Handler_VoteCharset, view_as<MenuAction>(MENU_ACTIONS_ALL));
	menu.SetTitle("%t", "select_charset");

	char config[PLATFORM_MAX_PATH], index[8];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	int total, charsets;

	do
	{
		total++;
		if(!KvGetNum(Kv, "hidden"))
			charsets++;
	}
	while(KvGotoNextKey(Kv));

	delete Kv;
	//PrintToConsoleAll("%i", total);
	if(total < 2)
		return Plugin_Continue;

	//PrintToConsoleAll("Rewind");
	char[][] charset = new char[total][42];
	int[] validCharsets = new int[total];
	int shuffle = cvarShuffleCharset.IntValue;
	//PrintToConsoleAll("%i", shuffle);
	total = 0;
	charsets = 0;
	// KvRewind hates me...
	Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	do
	{
		if(KvGetNum(Kv, "hidden"))	//Hidden charsets are hidden for a reason :P
		{
			//PrintToConsoleAll("Skip %i %i", total, charsets);
			total++;
			continue;
		}

		validCharsets[charsets] = total;
		KvGetSectionName(Kv, charset[total], 42);
		//PrintToConsoleAll("%s %i %i", charset[total], total, charsets);
		charsets++;
		total++;
	}
	while(KvGotoNextKey(Kv));

	delete Kv;

	if(shuffle)
	{
		int choosen, current;
		int packs = charsets-1;
		for(int i; i<shuffle && packs>=0; i++)	// We keep doing this until we reached shuffle limit or were're out of packs
		{
			choosen = GetRandomInt(0, packs);	// Get a random pack
			current = validCharsets[choosen];	// Get the pack's index
			//PrintToConsoleAll("%i %s %i %i", i, charset[current], choosen, current);
			if(current!=CurrentCharSet || charsets<=shuffle)	// If shuffle is more then the max charsets, exclude the current pack
			{
				IntToString(current, index, sizeof(index));
				menu.AddItem(index, charset[current]);	// Add menu option
			}

			for(; choosen<packs; choosen++)
			{
				validCharsets[choosen] = validCharsets[choosen+1];	// Remove choosen pack and move other packs down
			}
			packs--;
		}
		menu.NoVoteButton = true;
	}
	else
	{
		IntToString(validCharsets[GetRandomInt(0, charsets-1)], index, sizeof(index));
		menu.AddItem(index, "Random");
		//PrintToConsoleAll("Random %s", index);

		for(int i; i<charsets; i++)
		{
			IntToString(validCharsets[i], index, sizeof(index));
			menu.AddItem(index, charset[i]);
			//PrintToConsoleAll("%i %s %s", i, charset[i], index);
		}
	}

	menu.ExitButton = false;
	ConVar voteDuration = FindConVar("sm_mapvote_voteduration");
	menu.DisplayVoteToAll(voteDuration ? voteDuration.IntValue : 20);
	return Plugin_Continue;
}

public int Handler_VoteCharset(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_VoteEnd:
		{
			char index[8], nextmap[32];
			menu.GetItem(param1, index, sizeof(index), _, FF2CharSetString, sizeof(FF2CharSetString));
			cvarCharset.IntValue = StringToInt(index);

			cvarNextmap.GetString(nextmap, sizeof(nextmap));
			FPrintToChatAll("%t", "nextmap_charset", nextmap, FF2CharSetString);	//"The character set for {1} will be {2}."
			isCharSetSelected = true;
		}
	}
}

public Action Command_Nextmap(int client, int args)
{
	if(FF2CharSetString[0])
	{
		static char nextmap[42];
		cvarNextmap.GetString(nextmap, sizeof(nextmap));
		FReplyToCommand(client, "%t", "nextmap_charset", nextmap, FF2CharSetString);
	}
	return Plugin_Handled;
}

public Action Command_Say(int client, int args)
{
	static char chat[32];
	if(GetCmdArgString(chat, sizeof(chat))<1 || !client)
		return Plugin_Continue;

	if(FF2CharSetString[0] && StrEqual(chat, "\"nextmap\""))
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
	if(slot<0 || slot>3)
	{
		Call_PushCell(3);  // Status - we're assuming here a non-rage or passive ability will always be in use if it gets called
		Call_Finish(action);
	}
	else if(!slot)
	{
		FF2flags[Boss[boss]] &= ~FF2FLAG_BOTRAGE;
		Call_PushCell(3);  // Status - we're assuming here a rage ability will always be in use if it gets called
		Call_Finish(action);

		if(BossRageDamage[boss] > 1)
		{
			if(rageMode[client] == 1)
			{
				BossCharge[boss][slot] -= rageMin[client];
			}
			else if(!rageMode[client])
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
				button = IN_DUCK|IN_ATTACK2;

			case 2:
				button = IN_RELOAD;

			case 3:
				button = IN_ATTACK3;

			case 4:
				button = IN_DUCK;

			case 5:
				button = IN_SCORE;

			default:
				button = IN_ATTACK2;
		}

		if(GetClientButtons(Boss[boss]) & button)
		{
			if(BossCharge[boss][slot] >= 0.0)
			{
				Call_PushCell(2);  //Status
				Call_Finish(action);
				float charge;
				if(GetArgumentI(boss, plugin_name, ability_name, "slot", -2) != -2)
				{
					charge = 100.0*0.2/GetArgumentF(boss, plugin_name, ability_name, "charge time", 1.5);
				}
				else
				{
					charge = 100.0*0.2/GetAbilityArgumentFloat(boss, plugin_name, ability_name, 1, 1.5);
				}

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
			if(angles[0] < ChargeAngle*-1.0)
			{
				Call_PushCell(3);
				Call_Finish(action);
				DataPack data;
				CreateDataTimer(0.1, Timer_UseBossCharge, data);
				data.WriteCell(boss);
				data.WriteCell(slot);
				if(GetArgumentI(boss, plugin_name, ability_name, "slot", -2) != -2)
				{
					data.WriteFloat(-1.0*GetArgumentF(boss, plugin_name, ability_name, "cooldown", 5.0));
				}
				else
				{
					data.WriteFloat(-1.0*GetAbilityArgumentFloat(boss, plugin_name, ability_name, 2, 5.0));
				}
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
	OtherTeam = otherteam;
	BossTeam = bossteam;

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

public Action Timer_UseBossCharge(Handle timer, DataPack data)
{
	data.Reset();
	BossCharge[data.ReadCell()][data.ReadCell()] = data.ReadFloat();
	return Plugin_Continue;
}

stock void RemoveShield(int client, int attacker)
{
	if(IsValidEntity(shield[client]))
	{
		TF2_RemoveWearable(client, shield[client]);
		EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
		EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
		if(cvarShieldType.IntValue == 3)
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
		}
		else
		{
			EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
			EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
		}
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
	int boss = GetNativeCell(1);
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

	static char language[20];
	GetLanguageInfo(client ? GetClientLanguage(client) : GetServerLanguage(), language, sizeof(language), s, dstrlen);
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
				GetLanguageInfo(GetServerLanguage(), language, sizeof(language), s, dstrlen);
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
				GetLanguageInfo(GetServerLanguage(), language, sizeof(language), s, dstrlen);
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
	BossHealth[GetNativeCell(1)] = GetNativeCell(2);
	UpdateHealthBar();
}

public int Native_GetBossMaxHealth(Handle plugin, int numParams)
{
	return BossHealthMax[GetNativeCell(1)];
}

public int Native_SetBossMaxHealth(Handle plugin, int numParams)
{
	BossHealthMax[GetNativeCell(1)] = GetNativeCell(2);
	UpdateHealthBar();
}

public int Native_GetBossLives(Handle plugin, int numParams)
{
	return BossLives[GetNativeCell(1)];
}

public int Native_SetBossLives(Handle plugin, int numParams)
{
	BossLives[GetNativeCell(1)] = GetNativeCell(2);
}

public int Native_GetBossMaxLives(Handle plugin, int numParams)
{
	return BossLivesMax[GetNativeCell(1)];
}

public int Native_SetBossMaxLives(Handle plugin, int numParams)
{
	BossLivesMax[GetNativeCell(1)] = GetNativeCell(2);
}

public int Native_GetBossCharge(Handle plugin, int numParams)
{
	return view_as<int>(BossCharge[GetNativeCell(1)][GetNativeCell(2)]);
}

public int Native_SetBossCharge(Handle plugin, int numParams)  //TODO: This duplicates logic found in Timer_UseBossCharge
{
	BossCharge[GetNativeCell(1)][GetNativeCell(2)] = GetNativeCell(3);
}

public int Native_GetBossRageDamage(Handle plugin, int numParams)
{
	return BossRageDamage[GetNativeCell(1)];
}

public int Native_SetBossRageDamage(Handle plugin, int numParams)
{
	BossRageDamage[GetNativeCell(1)] = GetNativeCell(2);
}

public int Native_GetRoundState(Handle plugin, int numParams)
{
	if(CheckRoundState() < 1)
		return 0;

	return CheckRoundState();
}

public int Native_GetRageDist(Handle plugin, int numParams)
{
	int index = GetNativeCell(1);
	static char plugin_name[64];
	GetNativeString(2, plugin_name, 64);
	static char ability_name[64];
	GetNativeString(3, ability_name, 64);

	if(!BossKV[Special[index]])
		return view_as<int>(0.0);

	KvRewind(BossKV[Special[index]]);
	float see;
	if(!ability_name[0])
		return view_as<int>(KvGetFloat(BossKV[Special[index]], "ragedist", 400.0));

	char s[10];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		FormatEx(s, sizeof(s), "ability%i", i);
		if(KvJumpToKey(BossKV[Special[index]], s))
		{
			static char ability_name2[64];
			KvGetString(BossKV[Special[index]], "name", ability_name2, 64);
			if(strcmp(ability_name, ability_name2))
			{
				KvGoBack(BossKV[Special[index]]);
				continue;
			}
	
			if((see=KvGetFloat(BossKV[Special[index]], "dist", -1.0)) < 0)
			{
				KvRewind(BossKV[Special[index]]);
				see = KvGetFloat(BossKV[Special[index]], "ragedist", 400.0);
			}
			return view_as<int>(see);
		}
	}
	return view_as<int>(0.0);
}

bool _HasAbility(int boss, const char[] plugin_name, const char[] ability_name)
{
	FF2QueryData data;
	if (!FF2Cache.Request(boss, data)) {
		return false;
	}

	KeyValues kv;

	char abkey[24];
	const int size_of_lookup = 132;
	char[] key = new char[size_of_lookup];

	FF2Cache.FormatToHasAbility(key, plugin_name, ability_name);
	FF2Cache actual = view_as<FF2Cache>(data.cache);

	bool res;

	if (actual.GetValue(key, res))
		return res;

	kv = BossKV[Special[boss]];
	kv.Rewind();

	for (int ab = 1; ab <= MAXRANDOMS; ab++)
	{
		FormatEx(abkey, sizeof(abkey), "ability%i", ab);
		if (!kv.JumpToKey(abkey)) {
			continue;
		}

		kv.GetString("name", key, 64);
		if (!StrEqual(key, ability_name)) {
			kv.GoBack();
			continue;
		}

		kv.GetString("plugin_name", key, 64);
		if (!StrEqual(key, plugin_name) && plugin_name[0]) {
			kv.GoBack();
			continue;
		}

		FF2Cache.FormatToHasAbility(key, plugin_name, ability_name);
		actual.SetValue(key, true);
		return true;
	}

	FF2Cache.FormatToHasAbility(key, plugin_name, ability_name);
	actual.SetValue(key, false);
	return false;
}

public int Native_HasAbility(Handle plugin, int numParams)
{
	int boss = GetNativeCell(1);
	if(boss==-1 || boss>=MAXTF2PLAYERS || Special[boss]==-1 || !BossKV[Special[boss]])
		return false;
	
	char pluginName[64], abilityName[64];

	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	
	return _HasAbility(boss, pluginName, abilityName);
}

public int Native_DoAbility(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	UseAbility(ability_name, plugin_name, GetNativeCell(1), GetNativeCell(4), GetNativeCell(5));
}

public int Native_GetAbilityArgument(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	return GetAbilityArgument(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5));
}

public any Native_GetAbilityArgumentFloat(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	return GetAbilityArgumentFloat(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5));
}

public int Native_GetAbilityArgumentString(Handle plugin, int numParams)
{
	static char plugin_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	static char ability_name[64];
	GetNativeString(3, ability_name, sizeof(ability_name));
	int dstrlen = GetNativeCell(6);
	char[] s = new char[dstrlen+1];
	GetAbilityArgumentString(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), s, dstrlen);
	SetNativeString(5, s, dstrlen);
}

public int Native_GetArgNamedI(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	return GetArgumentI(GetNativeCell(1), plugin_name, ability_name, argument, GetNativeCell(5));
}

public any Native_GetArgNamedF(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	return GetArgumentF(GetNativeCell(1), plugin_name, ability_name, argument, GetNativeCell(5));
}

public int Native_GetArgNamedS(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	int dstrlen = GetNativeCell(6);
	char[] s = new char[dstrlen+1];
	GetArgumentS(GetNativeCell(1), plugin_name, ability_name, argument, s, dstrlen);
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
	FF2flags[GetNativeCell(1)] = GetNativeCell(2);
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
	int index = GetNativeCell(1);
	bool isNumOfSpecial = view_as<bool>(GetNativeCell(2));
	if(isNumOfSpecial)
	{
		if(index!=-1 && index<Specials)
		{
			if(BossKV[index] != INVALID_HANDLE)
				KvRewind(BossKV[index]);

			return view_as<int>(BossKV[index]);
		}
	}
	else
	{
		if(index!=-1 && index<=MaxClients && Special[index]!=-1 && Special[index]<MAXSPECIALS)
		{
			if(BossKV[Special[index]] != INVALID_HANDLE)
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
		return view_as<int>(-1.0);
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
			if(cvarShieldType.IntValue > 2)
			{
				return RoundToFloor(shieldHP[client]/cvarShieldHealth.FloatValue*100.0);
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
			shieldHP[client] = GetNativeCell(3)*cvarShieldHealth.FloatValue/100.0;

		if(GetNativeCell(4) > 0)
		{
			shDmgReduction[client] = (1.0-GetNativeCell(4));
		}
		else if(GetNativeCell(3) > 0)
		{
			shDmgReduction[client] = shieldHP[client]/cvarShieldHealth.FloatValue*(1.0-cvarShieldResist.FloatValue);
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
	char buffer[256];
	int error = FormatNativeString(0, 1, 2, sizeof(buffer), _, buffer);
	if(error != SP_ERROR_NONE)
	{
		ThrowNativeError(error, "Failed to format");
		return;
	}
	LogToFile(eLog, buffer);
}

public int Native_Debug(Handle plugin, int numParams)
{
	return cvarDebug.BoolValue;
}

public int Native_SetCheats(Handle plugin, int numParams)
{
	CheatsUsed = GetNativeCell(1);
}

public int Native_GetCheats(Handle plugin, int numParams)
{
	return (CheatsUsed || SpecialRound);
}

public int Native_MakeBoss(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsValidClient(client))
		return;

	int boss = GetNativeCell(2);
	if(boss == -1)
	{
		boss = GetBossIndex(client);
		if(boss < 0)
			return;

		Boss[boss] = 0;
		BossSwitched[boss] = false;
		CreateTimer(0.1, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	int special = GetNativeCell(3);
	if(special >= 0)
		Incoming[boss] = special;

	Boss[boss] = client;
	HasEquipped[boss] = false;
	BossSwitched[boss] = GetNativeCell(4);
	PickCharacter(boss, boss);
	CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
}

public int Native_ChooseBoss(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<1 || client>=MAXTF2PLAYERS)
	{
		GetNativeString(2, xIncoming[0], sizeof(xIncoming[]));
		return CheckValidBoss(0, xIncoming[0]);
	}

	GetNativeString(2, xIncoming[client], sizeof(xIncoming[]));
	IgnoreValid[client] = GetNativeCell(3);
	return CheckValidBoss(client, xIncoming[client]);
}

public int Native_IsVSHMap(Handle plugin, int numParams)
{
	return false;
}

public int Native_ReportError(Handle plugin, int params)
{
	int boss = GetNativeCell(1);
	char name[48] = "Unknown";
	if(boss >= 0 && BossKV[Special[boss]])
	{
		BossKV[Special[boss]].Rewind();
		BossKV[Special[boss]].GetString("name", name, sizeof(name), "Unknown");
	}
	
	LogToFile(eLog, "[FF2] Exception reported: Boss: %i - Name: %s", boss, name);
	char actual[PLATFORM_MAX_PATH];
	
	int error;
	if((error = FormatNativeString(0, 2, 3, sizeof(actual), .out_string=actual)) != SP_ERROR_NONE)
	{
		return ThrowNativeError(error, "Failed to format");
	}
	Format(actual, sizeof(actual), "[FF2] %s", actual);
	LogToFile(eLog, actual);
	
	return 1;
}

public any FF2Data_Unknown(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(!IsClientInGame(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client: %i is not ingame", client);
	}
	
	return FF2Data.Unknown(client);
}

public any FF2Data_FF2Data(Handle plugin, int params)
{
	int boss = GetNativeCell(1);
	if(boss < 0 || boss > 12) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid boss index: %i", boss);
	}
	
	char plugin_name[64]; GetNativeString(2, plugin_name, sizeof(plugin_name));
	char ability_name[64]; GetNativeString(3, ability_name, sizeof(ability_name));
	
	FF2Data data = FF2Data(boss, plugin_name, ability_name);
	return data;
}

public int FF2Data_boss(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	return data.boss;
}

public int FF2Data_client(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	return data.client;
}

public any FF2Data_GetConfig(Handle plugin, int params)
{
	FF2Data boss = GetNativeCell(1);
	if(boss.Invalid)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid boss index: %i", boss);
	
	return BossKV[boss.boss];
}

public any FF2Data_Change(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	if(data.Invalid)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid boss index: %i", data.boss);
	
	char plugin_name[64]; GetNativeString(2, plugin_name, sizeof(plugin_name));
	char ability_name[64]; GetNativeString(3, ability_name, sizeof(ability_name));
	
	data.Change(plugin_name, ability_name);
	return 1;
}

public any FF2Data_GetArgI(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	char arg[32]; GetNativeString(2, arg, sizeof(arg));
	return data.GetArgI(arg, GetNativeCell(3), GetNativeCell(4));
}

public any FF2Data_GetArgF(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	char arg[32]; GetNativeString(2, arg, sizeof(arg));
	return data.GetArgF(arg, GetNativeCell(3));
}

public any FF2Data_GetArgB(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	char arg[32]; GetNativeString(2, arg, sizeof(arg));
	return data.GetArgB(arg, GetNativeCell(3));
}

public any FF2Data_GetArgS(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	char arg[32]; GetNativeString(2, arg, sizeof(arg));
	
	int len = GetNativeCell(4);
	char[] res = new char[len];
	int bytes = data.GetArgS(arg, res, len);
	SetNativeString(3, res, len);

	return bytes;
}

public any FF2Data_HasAbility(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	if (data.Invalid) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid boss index: %i", data.boss);
	}
	
	FF2QueryData cd;
	FF2Cache.Request(data.boss, cd);
	
	return _HasAbility(data.boss, cd.current_plugin_name, cd.current_ability_name);
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
		UpdateHealthBar();
}

stock void MyAddServerTag(const char[] tag)
{
	if(cvarTags == view_as<ConVar>(INVALID_HANDLE))
		return;

	static char currtags[128];
	cvarTags.GetString(currtags, sizeof(currtags));
	if(StrContains(currtags, tag) > -1)
		return;

	char newtags[128];
	FormatEx(newtags, sizeof(newtags), "%s%s%s", currtags, currtags[0] ? "," : "", tag);
	int flags = GetConVarFlags(cvarTags);
	SetConVarFlags(cvarTags, flags & ~FCVAR_NOTIFY);
	cvarTags.SetString(newtags);
	SetConVarFlags(cvarTags, flags);
}

stock void MyRemoveServerTag(const char[] tag)
{
	if(cvarTags == view_as<ConVar>(INVALID_HANDLE))
		return;

	static char newtags[128];
	cvarTags.GetString(newtags, sizeof(newtags));
	if(StrContains(newtags, tag) == -1)
		return;

	ReplaceString(newtags, sizeof(newtags), tag, "");
	ReplaceString(newtags, sizeof(newtags), ",,", "");
	int flags = GetConVarFlags(cvarTags);
	SetConVarFlags(cvarTags, flags & ~FCVAR_NOTIFY);
	cvarTags.SetString(newtags);
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
	if(cvarHealthBar.IntValue > 0)
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
	if(entity == g_Monoculus)
	{
		g_Monoculus = FindEntityByClassname2(-1, MONOCULUS);
		if(g_Monoculus == entity)
		{
			g_Monoculus = FindEntityByClassname2(entity, MONOCULUS);
			if(!IsValidEntity(g_Monoculus) || g_Monoculus==-1)
				FindHealthBar();
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
	if(Enabled && IsValidClient(client))
	{
		static char classname[32];
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
			return -1;

		case RoundState_StartGame, RoundState_Preround:
			return 0;

		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
			return 1;
	}
	return 2;
}

void FindHealthBar()
{
	healthBar = FindEntityByClassname2(-1, HEALTHBAR_CLASS);
	if(!IsValidEntity(healthBar))
		healthBar = CreateEntityByName(HEALTHBAR_CLASS);
}

public void HealthbarEnableChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(Enabled && cvarHealthBar.IntValue>0 && IsValidEntity(healthBar))
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
	if(!Enabled || cvarHealthBar.IntValue<1 || IsValidEntity(g_Monoculus) || !IsValidEntity(healthBar) || CheckRoundState()!=1)
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
				if(cvarHealthBar.IntValue > 1)
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
		else if(healthPercent < 1)
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
		GlowTimer[client] += time1;
		if(time2 >= 0)
			GlowTimer[client] = time2;

		if(GlowTimer[client] <= 0.0)
		{
			GlowTimer[client] = 0.0;
			if(IsGlowing[client])	// Prevent removing outlines from other plugins
			{
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
				IsGlowing[client] = false;
			}
		}
		else if(CheckRoundState() == 1)
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
			IsGlowing[client] = true;
		}
	}
}

public bool UTIL_FindCharArg(FF2QueryData data, const char[] args, char[] res, int maxlen)
{
	KeyValues kv;

	const int size_of_key = 24;

	char abkey[size_of_key];
	char[] key = new char[132];
	FF2Cache.FormatToKey(key, data.current_plugin_name, data.current_ability_name);
	FF2Cache actual = view_as<FF2Cache>(data.cache);

	kv = BossKV[data.char_idx];
	kv.Rewind();

	if (actual.GetString(key, abkey, sizeof(abkey)))
	{
		if (!abkey[0]) {
			// lookup failed, return default value.
			return false;
		}

		kv.JumpToKey(abkey);
		kv.GetString(args, res, maxlen);
		
		return res[0] != '\0';
	}

	for (int ab = 1; ab <= MAXRANDOMS; ab++)
	{
		FormatEx(abkey, sizeof(abkey), "ability%i", ab);
		if (!kv.JumpToKey(abkey)) {
			continue;
		}

		kv.GetString("name", key, 64);
		if (!StrEqual(key, data.current_ability_name)) {
			kv.GoBack();
			continue;
		}

		kv.GetString("plugin_name", key, 64);
		if (!StrEqual(key, data.current_plugin_name) && data.current_plugin_name[0]) {
			kv.GoBack();
			continue;
		}

		kv.GetString(args, res, maxlen);

		FF2Cache.FormatToKey(key, data.current_plugin_name, data.current_ability_name);
		actual.SetString(key, abkey);

		return res[0] != '\0';
	}

	FF2Cache.FormatToKey(key, data.current_plugin_name, data.current_ability_name);
	actual.SetString(key, "");
	return false;
}


/*< freak_fortress_2.inc >*/
stock void FPrintToChat(int client, const char[] message, any ...)
{
	SetGlobalTransTarget(client);
	char buffer[192];
	VFormat(buffer, sizeof(buffer), message, 3);
	CPrintToChat(client, "%t%s", "Prefix", buffer);
}

stock void FPrintToChatAll(const char[] message, any ...)
{
	char buffer[192];
	VFormat(buffer, sizeof(buffer), message, 2);
	CPrintToChatAll("%t%s", "Prefix", buffer);
}

stock void FReplyToCommand(int client, const char[] message, any ...)
{
	SetGlobalTransTarget(client);
	char buffer[192];
	VFormat(buffer, sizeof(buffer), message, 3);
	if(!client)
	{
		CRemoveTags(buffer, sizeof(buffer));
		PrintToServer("[FF2] %s", buffer);
	}
	else if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		CRemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, "[FF2] %s", buffer);
	}
	else
	{
		CPrintToChat(client, "%t%s", "Prefix", buffer);
	}
}

stock int FF2_SpawnWeapon(int client, char[] name, int index, int level, int qual, const char[] att, bool visible=true)
{
	#if defined _tf2items_included
	if(StrEqual(name, "saxxy", false))	// if "saxxy" is specified as the name, replace with appropiate name
	{ 
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:	ReplaceString(name, 64, "saxxy", "tf_weapon_bat", false);
			case TFClass_Pyro:	ReplaceString(name, 64, "saxxy", "tf_weapon_fireaxe", false);
			case TFClass_DemoMan:	ReplaceString(name, 64, "saxxy", "tf_weapon_bottle", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "saxxy", "tf_weapon_fists", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "saxxy", "tf_weapon_wrench", false);
			case TFClass_Medic:	ReplaceString(name, 64, "saxxy", "tf_weapon_bonesaw", false);
			case TFClass_Sniper:	ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
			case TFClass_Spy:	ReplaceString(name, 64, "saxxy", "tf_weapon_knife", false);
			default:		ReplaceString(name, 64, "saxxy", "tf_weapon_shovel", false);
		}
	}
	else if(StrEqual(name, "tf_weapon_shotgun", false))	// If using tf_weapon_shotgun for Soldier/Pyro/Heavy/Engineer
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Pyro:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_pyro", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_hwg", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_primary", false);
			default:		ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
		}
	}

	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon == INVALID_HANDLE)
		return -1;

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
		--count;

	if(count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib = StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				delete hWeapon;
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

	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	delete hWeapon;
	if(entity == -1)
		return -1;

	EquipPlayerWeapon(client, entity);

	if(visible)
	{
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	}
	else
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	return entity;
	#else
	return -1;
	#endif
}

stock void FF2_SetAmmo(int client, int weapon, int ammo=-1, int clip=-1)
{
	if(IsValidEntity(weapon))
	{
		if(clip > -1)
			SetEntProp(weapon, Prop_Data, "m_iClip1", clip);

		int ammoType = (ammo>-1 ? GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") : -1);
		if(ammoType != -1)
			SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, ammoType);
	}
}
/*< >*/

#include <freak_fortress_2_vsh_feedback>

#file "Unofficial Freak Fortress"
