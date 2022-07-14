// Boss Toggle
enum SettingPrefs
{
	Setting_Undef = 0,
	Setting_On,
	Setting_Off,
	Setting_Temp
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

enum struct FF2DataBase_t
{
    Cookie PlayerPref;

    Cookie Stat_c;
    Database Stat_d;

    Cookie Hud;
    Cookie LastPlayer;
    Cookie BossId;
    Cookie DiffType;
}
FF2DataBase_t FF2DataBase;

int ClientPoint[MAXTF2PLAYERS];
int ClientID[MAXTF2PLAYERS];
int ClientQueue[MAXTF2PLAYERS][2];
bool InfiniteRageActive[MAXTF2PLAYERS] = false;

// Preferences
enum struct FF2PlayerCookie_t
{
    int QueuePoints;
    
    // TODO: Disable temp for round?
    bool MusicOn;
    bool VoiceOn;
    bool InfoOn;

    SettingPrefs Duo;
    SettingPrefs Boss;
    SettingPrefs Diff;

    int BossWins;
    int BossLosses;
    int BossKills;
    int BossKillsF;
    int BossDeaths;
    
    int PlayerKills;
    int PlayerMVPs;

    int HudSettings[HUDTYPES];
}
FF2PlayerCookie_t FF2PlayerCookie[MAXTF2PLAYERS];