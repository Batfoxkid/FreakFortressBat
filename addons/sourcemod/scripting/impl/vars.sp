
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

bool LoadCharset = false;
bool ReloadFF2 = false;
bool FF2Executed = false;
bool FF2Executed2 = false;
bool ReloadWeapons = false;
bool ConfigWeapons = false;
bool ReloadConfigs = false;
bool HasSwitched = false;

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
char HudTypes[][] =	// Names used in translation files
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
		return view_as<FF2Data>(Utils_GetBossIndex(client));
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
		if (!Utils_FindCharArg(data, arg, res, sizeof(res))) {
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
		if (!Utils_FindCharArg(data, arg, res, sizeof(res))) {
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

		if (!Utils_FindCharArg(data, arg, res, maxlen)) {
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
		if (!Utils_FindCharArg(data, arg, res, 1)) {
			return def;
		}

		return res[0] != '0';
	}
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

int ClientPoint[MAXTF2PLAYERS];
int ClientID[MAXTF2PLAYERS];
int ClientQueue[MAXTF2PLAYERS][2];
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