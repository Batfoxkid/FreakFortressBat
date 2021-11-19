void DataBase_CreateCookies()
{
    FF2DataBase.PlayerPref 	= new Cookie("ff2_cookies_mk2", "Player's Preferences", CookieAccess_Protected);
    FF2DataBase.Stat_c 		= new Cookie("ff2_cookies_stats", "Player's Statistics", CookieAccess_Protected);
    FF2DataBase.Hud 		= new Cookie("ff2_cookies_huds", "Player's HUD Settings", CookieAccess_Protected);
    FF2DataBase.LastPlayer 	= new Cookie("ff2_boss_previous", "Player's Last Boss", CookieAccess_Protected);
    FF2DataBase.BossId 		= new Cookie("ff2_boss_selection", "Player's Boss Selection", CookieAccess_Protected);
    FF2DataBase.DiffType 	= new Cookie("ff2_boss_difficulty", "Player's Difficulty Selection", CookieAccess_Protected);
}

void DataBase_SetupDatabase()
{
	char query[256];
	FF2DataBase.Stat_d = SQL_Connect(DATATABLE, true, query, sizeof(query));
	if(FF2DataBase.Stat_d == INVALID_HANDLE)
	{
		LogToFile(FF2LogsPaths.Errors, "[Database] %s", query);
		FF2Globals.Enabled_Database = 0;
		return;
	}

	FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (steamid INT, win INT, lose INT, kill INT, death INT, slain INT, mvp INT)", DATATABLE);
	SQL_LockDatabase(FF2DataBase.Stat_d);
	if(!SQL_FastQuery(FF2DataBase.Stat_d, query))
	{
		SQL_GetError(FF2DataBase.Stat_d, query, sizeof(query));
		LogToFile(FF2LogsPaths.Errors, "[Database] %s", query);
		SQL_UnlockDatabase(FF2DataBase.Stat_d);
		FF2Globals.Enabled_Database = 0;
		return;
	}
	SQL_UnlockDatabase(FF2DataBase.Stat_d);
	FF2Globals.Enabled_Database = 2;
}

void DataBase_SetupClientCookies(int client)
{
	if(!Utils_IsValidClient(client))
		return;

	if(IsFakeClient(client))
	{
		FF2PlayerCookie[client].QueuePoints = 0;
		FF2PlayerCookie[client].MusicOn = false;
		FF2PlayerCookie[client].VoiceOn = false;
		FF2PlayerCookie[client].InfoOn = false;
		FF2PlayerCookie[client].Duo = Setting_On;
		FF2PlayerCookie[client].Boss = Setting_On;
		FF2PlayerCookie[client].Diff = Setting_On;

		FF2PlayerCookie[client].BossWins = 0;
		FF2PlayerCookie[client].BossLosses = 0;
		FF2PlayerCookie[client].BossKills = 0;
		FF2PlayerCookie[client].BossKillsF = 0;
		FF2PlayerCookie[client].BossDeaths = 0;
		FF2PlayerCookie[client].PlayerKills = 0;
		FF2PlayerCookie[client].PlayerMVPs =  0;

		for(int i=0; i<(HUDTYPES-1); i++)
		{
			FF2PlayerCookie[client].HudSettings[i] = 1;
		}
		FF2PlayerCookie[client].HudSettings[HUDTYPES-1] = 0;
		return;
	}

	if(AreClientCookiesCached(client))
	{
		static char cookies[454];
		char cookieValues[MAXCHARSETS][64];
		GetClientCookie(client, FF2DataBase.PlayerPref, cookies, 48);
		ExplodeString(cookies, " ", cookieValues, MAXCHARSETS, 6);

		FF2PlayerCookie[client].QueuePoints = StringToInt(cookieValues[0][0]);
		FF2PlayerCookie[client].MusicOn = view_as<bool>(StringToInt(cookieValues[1][0]));
		FF2PlayerCookie[client].VoiceOn = view_as<bool>(StringToInt(cookieValues[2][0]));
		FF2PlayerCookie[client].InfoOn = view_as<bool>(StringToInt(cookieValues[3][0]));
		FF2PlayerCookie[client].Duo = view_as<SettingPrefs>(StringToInt(cookieValues[4][0]));
		FF2PlayerCookie[client].Boss = view_as<SettingPrefs>(StringToInt(cookieValues[5][0]));
		FF2PlayerCookie[client].Diff = view_as<SettingPrefs>(StringToInt(cookieValues[6][0]));

		if(FF2PlayerCookie[client].Duo == Setting_Temp)
			FF2PlayerCookie[client].Duo = Setting_On;

		if(FF2PlayerCookie[client].Boss == Setting_Temp)
			FF2PlayerCookie[client].Boss = Setting_Undef;

		if(FF2PlayerCookie[client].Diff == Setting_Temp)
			FF2PlayerCookie[client].Diff = Setting_On;

		if(ConVars.Database.IntValue < 2)
		{
			GetClientCookie(client, FF2DataBase.Stat_c, cookies, 48);
			ExplodeString(cookies, " ", cookieValues, MAXCHARSETS, 6);

			FF2PlayerCookie[client].BossWins = StringToInt(cookieValues[0][0]);
			FF2PlayerCookie[client].BossLosses = StringToInt(cookieValues[1][0]);
			FF2PlayerCookie[client].BossKills = StringToInt(cookieValues[2][0]);
			FF2PlayerCookie[client].BossKillsF = StringToInt(cookieValues[2][0]);
			FF2PlayerCookie[client].BossDeaths = StringToInt(cookieValues[3][0]);
			FF2PlayerCookie[client].PlayerKills = StringToInt(cookieValues[4][0]);
			FF2PlayerCookie[client].PlayerMVPs =  StringToInt(cookieValues[5][0]);
		}

		GetClientCookie(client, FF2DataBase.Hud, cookies, 48);
		ExplodeString(cookies, " ", cookieValues, MAXCHARSETS, 6);
		for(int i=0; i<HUDTYPES; i++)
		{
			FF2PlayerCookie[client].HudSettings[i] = StringToInt(cookieValues[i]);
		}

		GetClientCookie(client, FF2DataBase.BossId, cookies, sizeof(cookies));
		ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
		strcopy(xIncoming[client], sizeof(xIncoming[]), cookieValues[FF2CharSetInfo.CurrentCharSetIdx]);
		Utils_CheckValidBoss(client, xIncoming[client], !FF2GlobalsCvars.DuoMin);

		GetClientCookie(client, FF2DataBase.DiffType, dIncoming[client], sizeof(dIncoming[]));
	}
	else
	{
		FF2PlayerCookie[client].QueuePoints = 0;
		FF2PlayerCookie[client].MusicOn = true;
		FF2PlayerCookie[client].VoiceOn = true;
		FF2PlayerCookie[client].InfoOn = true;
		FF2PlayerCookie[client].Duo = Setting_Undef;
		FF2PlayerCookie[client].Boss = Setting_Undef;
		FF2PlayerCookie[client].Diff = Setting_Undef;

		FF2PlayerCookie[client].BossWins = 0;
		FF2PlayerCookie[client].BossLosses = 0;
		FF2PlayerCookie[client].BossKills = 0;
		FF2PlayerCookie[client].BossKillsF = 0;
		FF2PlayerCookie[client].BossDeaths = 0;
		FF2PlayerCookie[client].PlayerKills = 0;
		FF2PlayerCookie[client].PlayerMVPs =  0;

		for(int i=0; i<(HUDTYPES-1); i++)
		{
			FF2PlayerCookie[client].HudSettings[i] = 0;
		}
		FF2PlayerCookie[client].HudSettings[HUDTYPES-1] = 1;
	}

	if(FF2Globals.Enabled_Database != 2)
		return;

	int steamid = GetSteamAccountID(client);
	if(!steamid)
		return;

	static char query[256];
	FormatEx(query, sizeof(query), "SELECT win, lose, kill, death, slain, mvp FROM %s WHERE steamid=%d;", DATATABLE, steamid);

	SQL_LockDatabase(FF2DataBase.Stat_d);
	DBResultSet result;
	if((result = SQL_Query(FF2DataBase.Stat_d, query)) == null)
	{
		SQL_UnlockDatabase(FF2DataBase.Stat_d);
		return;
	}

	SQL_FetchRow(result);

	int stat[6];
	for(int i; i<6; i++)
	{
		stat[i] = SQL_FetchInt(result, i);
	}

	delete result;
	SQL_UnlockDatabase(FF2DataBase.Stat_d);

	if(stat[0] > FF2PlayerCookie[client].BossWins)
		FF2PlayerCookie[client].BossWins = stat[0];

	if(stat[1] > FF2PlayerCookie[client].BossLosses)
		FF2PlayerCookie[client].BossLosses = stat[1];

	if(stat[2] > FF2PlayerCookie[client].BossKills)
	{
		FF2PlayerCookie[client].BossKills = stat[2];
		FF2PlayerCookie[client].BossKillsF = stat[2];
	}

	if(stat[3] > FF2PlayerCookie[client].BossDeaths)
		FF2PlayerCookie[client].BossDeaths = stat[3];

	if(stat[4] > FF2PlayerCookie[client].PlayerKills)
		FF2PlayerCookie[client].PlayerKills = stat[4];

	if(stat[5] > FF2PlayerCookie[client].PlayerKills)
		FF2PlayerCookie[client].PlayerKills = stat[5];
}

void DataBase_SaveClientPreferences(int client)
{
	if(!Utils_IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client))
		return;

	char cookies[24];
	char cookieValues[8][5];
	GetClientCookie(client, FF2DataBase.PlayerPref, cookies, sizeof(cookies));
	ExplodeString(cookies, " ", cookieValues, 8, 5);

	FormatEx(cookies, sizeof(cookies), "%i %i %i %i %i %i %i 3", FF2PlayerCookie[client].QueuePoints, FF2PlayerCookie[client].MusicOn ? 1 : 0, FF2PlayerCookie[client].VoiceOn ? 1 : 0, FF2PlayerCookie[client].InfoOn ? 1 : 0, view_as<int>(FF2PlayerCookie[client].Duo), view_as<int>(FF2PlayerCookie[client].Boss), view_as<int>(FF2PlayerCookie[client].Diff));
	SetClientCookie(client, FF2DataBase.PlayerPref, cookies);

	IntToString(FF2PlayerCookie[client].HudSettings[0], cookies, sizeof(cookies));
	for(int i=1; i<HUDTYPES; i++)
	{
		Format(cookies, sizeof(cookies), "%s %i", cookies, FF2PlayerCookie[client].HudSettings[i]);
	}
	SetClientCookie(client, FF2DataBase.Hud, cookies);
}

void DataBase_SaveClientStats(int client)
{
	if(FF2Globals.IsSpecialRound || !Utils_IsValidClient(client) || IsFakeClient(client) || ConVars.StatPlayers.IntValue<1 || (!ConVars.BvBStat.BoolValue && FF2Globals.Enabled3))
		return;

	if(ConVars.StatWin2Lose.IntValue > 2)
	{
		if(FF2Globals.CheatsUsed)
		{
			PrintToConsole(client, "%t", "Cheats Used");
			return;
		}

		if(ConVars.StatPlayers.IntValue > FF2Globals.TotalRealPlayers)
		{
			PrintToConsole(client, "%t", "Low Players");
			return;
		}
	}
	else if(ConVars.StatWin2Lose.IntValue>0 || ConVars.StatHud.IntValue>0)
	{
		if(FF2Globals.CheatsUsed)
		{
			FPrintToChat(client, "%t", "Cheats Used");
			return;
		}

		if(ConVars.StatPlayers.IntValue > FF2Globals.TotalRealPlayers)
		{
			FPrintToChat(client, "%t", "Low Players");
			return;
		}
	}
	else
	{
		if(FF2Globals.CheatsUsed || ConVars.StatPlayers.IntValue>FF2Globals.TotalRealPlayers)
			return;
	}

	if(AreClientCookiesCached(client) && ConVars.Database.IntValue<2)
	{
		char cookies[48];
		FormatEx(cookies, sizeof(cookies), "%i %i %i %i %i %i 0 0", FF2PlayerCookie[client].BossWins, FF2PlayerCookie[client].BossLosses, FF2PlayerCookie[client].BossKills, FF2PlayerCookie[client].BossDeaths, FF2PlayerCookie[client].PlayerKills, FF2PlayerCookie[client].PlayerMVPs);
		SetClientCookie(client, FF2DataBase.Stat_c, cookies);
	}

	if(FF2Globals.Enabled_Database != 2)
		return;

	int steamid = GetSteamAccountID(client);
	if(!steamid)
		return;

	char query[256];
	FormatEx(query, sizeof(query), "UPDATE %s SET win=%d, lose=%d, kill=%d, death=%d, slain=%d, mvp=%d WHERE steamid=%d);", DATATABLE, FF2PlayerCookie[client].BossWins, FF2PlayerCookie[client].BossLosses, FF2PlayerCookie[client].BossKills, FF2PlayerCookie[client].BossDeaths, FF2PlayerCookie[client].PlayerKills, FF2PlayerCookie[client].PlayerMVPs, steamid);

	SQL_LockDatabase(FF2DataBase.Stat_d);
	if(!SQL_FastQuery(FF2DataBase.Stat_d, query))
	{
		SQL_GetError(FF2DataBase.Stat_d, query, sizeof(query));
		LogToFile(FF2LogsPaths.Errors, "[Database] %s", query);
	}
	SQL_UnlockDatabase(FF2DataBase.Stat_d);
}

void DataBase_AddClientStats(int client, CookieStats cookie, int num)
{
	if(FF2Globals.IsSpecialRound || !Utils_IsValidClient(client) || ConVars.StatPlayers.IntValue<1)
		return;

	if(!IsFakeClient(client) && (FF2Globals.CheatsUsed || ConVars.StatPlayers.IntValue>FF2Globals.TotalRealPlayers || (!ConVars.BvBStat.BoolValue && FF2Globals.Enabled3)))
		return;

	switch(cookie)
	{
		case Cookie_BossWins:
		{
			FF2PlayerCookie[client].BossWins += num;
		}
		case Cookie_BossLosses:
		{
			FF2PlayerCookie[client].BossLosses += num;
		}
		case Cookie_BossKills:
		{
			FF2PlayerCookie[client].BossKills += num;
		}
		case Cookie_BossDeaths:
		{
			FF2PlayerCookie[client].BossDeaths += num;
		}
		case Cookie_PlayerKills:
		{
			FF2PlayerCookie[client].PlayerKills += num;
		}
		case Cookie_PlayerMvps:
		{
			FF2PlayerCookie[client].PlayerMVPs += num;
		}
	}
}

void DataBase_SaveKeepBossCookie(int client)
{
	if(!AreClientCookiesCached(client))
		return;

	static char cookies[454];
	if(!IgnoreValid[client] && FF2CharSetInfo.CurrentCharSetIdx>=0 && FF2CharSetInfo.CurrentCharSetIdx<MAXCHARSETS && ConVars.SelectBoss.BoolValue)
	{
		char cookieValues[MAXCHARSETS][64];
		GetClientCookie(client, FF2DataBase.BossId, cookies, sizeof(cookies));
		ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
		strcopy(cookieValues[FF2CharSetInfo.CurrentCharSetIdx], 64, xIncoming[client]);

		strcopy(cookies, sizeof(cookies), cookieValues[0]);
		for(int i=1; i<MAXCHARSETS; i++)
		{
			Format(cookies, sizeof(cookies), "%s;%s", cookies, cookieValues[i]);
		}
		SetClientCookie(client, FF2DataBase.BossId, cookies);
	}

	if(!ConVars.Difficulty.BoolValue)
		SetClientCookie(client, FF2DataBase.DiffType, dIncoming[client]);
}