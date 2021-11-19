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

	int TimeLeft;
	char CurrentMap[100];

	Handle DrawGameTimer;
	Handle DoorCheckTimer;
	int CapMode;
	bool CheckDoors;
	bool IsMedival;
	bool FirstBlood;
	bool IsSpecialRound;
	bool IsSapperEnabled;
	bool TimerMode;

	bool AreSubpluginEnabled;
	bool PluginLateLoaded;

	bool Enabled;
	bool Enabled2;
	bool Enabled3;
	int Enabled_Database;

	bool SpawnTeleOnTriggerHurt;

	float HPTime;
	bool ShowHealthText;
	bool HealthBarMode;

	char BossIcon[64];

	int GoombaMode;

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

enum struct FF2CharSetInfo_t
{
	int CurrentCharSetIdx;
	char CurrentCharSet[42];

	int SizeOfSpecials;

	KeyValues BossKV[MAXSPECIALS];
	bool VoiceBlocked[MAXSPECIALS];
	bool MapBlocked[MAXSPECIALS];
	float BossSpeed[MAXSPECIALS];

	bool IsCharSetSelected;
	bool HasMultiCharSets;
	bool UseOldCharSetPath;
}
FF2CharSetInfo_t FF2CharSetInfo;

char FF2Packs_Names[MAXCHARSETS][42];
int FF2Packs_NumBosses[MAXCHARSETS];
Handle FF2BossPacks[MAXSPECIALS][MAXCHARSETS];
char FF2Packs_sChances[512];

int FF2Packs_iChances[MAXSPECIALS*2];  //This is multiplied by two because it has to hold both the boss indices and FF2Packs_iChances
int FF2Packs_ChanceIdx;


// Only Accessible with boss's index
enum struct FF2BossInfo_t
{
	// Incoming boss KV index
	int Incoming;
	// Current boss KV index
	int Special;
	// Current client's index
	int Boss;

	int Health;
	int HealthMax;
	int HealthLast;

	int Lives;
	int LivesMax;

	int RageDamage;
	bool HasSwitched;

	float Charge[4];
	float Stabbed;

	float KSpreeTimer;
	int KSpreeCount;

	bool HasEquipped;
	bool EmitRageSound;
}
FF2BossInfo_t FF2BossInfo[MAXTF2PLAYERS];


// Only Accessible with client's index and are boss specific
enum struct FF2BossVar_t
{
	// cfg: "ragemax"
	float RageMax;
	// cfg: "ragemin"
	float RageMin;
	// cfg: "ragemode"
	int RageMode;

	// cfg: "rocketjump"
	int SelfKnockback;

	bool IsHealthbarIncreasing;
	
	// cfg: "triple"
	bool HasTripleDamage;
	// cfg: "crits"
	bool HasRandomCrits;
	// cfg: "sapper"
	bool HasSapper;

	// cfg: "healing"
	int SelfHealing;
	// cfg: "healing_lives"
	float LifeHealing;
	// cfg: "healing_over"
	float OverHealing;
}
FF2BossVar_t FF2BossVar[MAXTF2PLAYERS];


// Only Accessible with client's index
enum struct FF2PlayerInfo_t
{
	int FF2Flags;

	TFClassType LastAliveClass;
	int Damage;

	int UberTarget;
	int HealingAmount;
	
	int CritBoosted[3];

	float ShieldHP;
	float ShieldDmgReduction;
	int EntShield;
	bool HasShield;

	float Cabered;
	int Detonations;

	float SapperCooldown;

	float AirstrikeDamage;
	float KillstreakDamage;

	float HazardDamage;
	float Marketed;

	Handle MusicTimer;
	int SongIdx;
	char CurrentBGM[PLATFORM_MAX_PATH];
	bool PlayBGM;

	float RPSLoser;
	int RPSLosses;
	int RPSHealth;

	float GlowTimer;
	bool IsGlowing;

	int ResetQueueTarget;
	
	void Init()
	{
		this.PlayBGM = true;
		this.SongIdx = 1;
	}
}
FF2PlayerInfo_t FF2PlayerInfo[MAXTF2PLAYERS];


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
		data.client_serial = GetClientSerial(FF2BossInfo[boss].Boss);
		data.char_idx = FF2BossInfo[boss].Special;
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
		if (boss < 0 || FF2BossInfo[boss].Special < 0 || !FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special])
			return false;

		static char name[48];
		static KeyValues last_kv;
		KeyValues kv = FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special];

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