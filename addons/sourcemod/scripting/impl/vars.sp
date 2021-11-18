enum struct FF2GlobalsCvars_t
{
	int PointDelay;
	int PointTime;

	float Announce;
	float AliveToEnable;

	int PointType;
	int ArenaRounds;

	float CircuitStun;
	float CountdownPlayers;

	int CountdownTime;
	int CountdownHealth;
	bool CountdownOvertime;

	bool SpecForceBoss;

	float LastPlayerGlow;
	
	int BossTeleportation;

	int ShieldCrits;
	int AllowedDetonation;

	float GoombaDmg;
	float ReboundPower;
	
	bool CanBossRTD;

	float SniperDmg;
	float SniperMiniDmg;
	float BowDmg;
	float BowDmgNon;
	float BowDmgMini;

	float SniperClimpDmg;
	float SniperClimpDelay;

	int WeaponQuality;
	
	int PointsInterval;
	float PointsInterval2;
	int PointsMin;
	int PointsDmg;
	int PointsExtra;

	bool DuoMin;
	bool TellName;

	int Annotations;
	char Attributes[128];

	float ChargeAngle;
	float StartingUber;

	char HealthFormula[512];
	char RageDamage[512];


	int tf_arena_use_queue;
	int mp_teams_unbalance_limit;
	int tf_arena_first_blood;
	int mp_forcecamera;
	int tf_dropped_weapon_lifetime;
	char mp_humans_must_join_team[16];


	void Init()
	{
		this.PointDelay = 6;
		this.PointTime = 45;

		this.Announce = 120.0;
		this.AliveToEnable = 0.2;

		this.CountdownPlayers = 1.0;
		this.CountdownTime = 120;
		this.CountdownHealth = 2000;

		this.LastPlayerGlow = 1.0;

		this.GoombaDmg = 0.05;
		this.ReboundPower = 300.0;

		this.SniperDmg = 2.0;
		this.SniperMiniDmg = 2.0;
		this.BowDmg = 1.25;

		this.SniperClimpDmg = 15.0;
		this.SniperClimpDelay = 1.56;

		this.WeaponQuality = 5;

		this.PointsInterval = 600;
		this.PointsInterval2 = 600.0;
		this.PointsMin = 10;
		this.PointsExtra = 10;

		this.Attributes = "2 ; 3.1 ; 275 ; 1";

		this.ChargeAngle = 30.0;
		this.StartingUber = 40.0;

		this.HealthFormula = "(((760.8+n)*(n-1))^1.0341)+2046";
		this.RageDamage = "1900";
	}
}
FF2GlobalsCvars_t FF2GlobalsCvars;


enum struct FF2Globals_t
{
	bool ChangedDescription;
#if defined _steamtools_included
	bool SteamTools;
#endif

#if defined _SteamWorks_Included
	bool SteamWorks;
#endif

#if defined _tf2attributes_included
	bool TF2Attrib;
#endif

#if defined _goomba_included
	bool Goomba;
#endif

#if !defined _smac_included
	bool SMAC;
#endif

	int TotalPlayers;
	int TotalRealPlayers;

	int MercsPlayers;
	int BossTeamPlayers;

	int Bosses;

	int HealthCheckCounter;

	int AliveMercPlayers;
	int AliveBossPlayers;

	int AliveRedPlayers;
	int AliveBluePlayers;

	int RoundCount;
	bool CheatsUsed;

	bool Isx10;
	bool IsCapping;

	int RPSWinner;
	
	int CurrentBossTeam;
	int OtherTeam;
	int BossTeam;

	bool IsBossBlue;
	bool IsLastMan;

	bool HasSwitched;
	bool LoadCharset;
	bool ReloadConfigs;

	bool ReloadFF2;
	bool FF2Executed;
	bool FF2Executed2;

	bool HasWeaponCfg;
	bool ReloadWeapons;

	int HealthBar;
	int EntMonoculus;

	float HPTime;
	char CurrentMap[99];
	bool CheckDoors;
	bool IsMedival;
	bool FirstBlood;

	bool AreSubpluginEnabled;
	bool PluginLateLoaded;

	bool Enabled;
	bool Enabled2;
	bool Enabled3;
	int Enabled_Database;

	void Init()
	{
		this.OtherTeam = 2;
		this.BossTeam = 3;
		
		this.IsLastMan = true;

		this.HealthBar = -1;
		this.EntMonoculus = -1;

		this.Enabled = true;
		this.Enabled2 = true;

		FF2GlobalsCvars.Init();
	}
}
FF2Globals_t FF2Globals;


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

Handle MusicTimer[MAXTF2PLAYERS];
Handle DrawGameTimer;
Handle doorCheckTimer;

int CurrentCharSet;
char CharSetString[MAXCHARSETS][42];
char FF2CharSetString[42];
bool isCharSetSelected = false;
bool HasCharSets;
bool CharSetOldPath = false;

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


enum struct FF2ModsInfo_t
{
	ConVar cvarHostName;
	char OldHostName[256];

	int ChangeGamemode;

	KeyValues WeaponCfg;
	KeyValues DiffCfg;

	Handle SDK_EquipWearable;
}
FF2ModsInfo_t FF2ModsInfo;


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

methodmap FF2SavedAbility_t < StringMap
{
	public FF2SavedAbility_t()
	{
		return view_as<FF2SavedAbility_t>(new StringMap());
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
FF2SavedAbility_t FF2SavedAbility;

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
			return FF2SavedAbility.GetInfos(name, data);

		kv.Rewind();
		kv.GetString("filename", name, sizeof(name), NULL_STRING);

		if (IsNullString(name)) {
			return false;
		}

		last_kv = kv;
		return FF2SavedAbility.GetInfos(name, data);
	}

	public static void Update(const FF2QueryData data)
	{
		FF2SavedAbility.SetInfos(data.key_name, data);
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