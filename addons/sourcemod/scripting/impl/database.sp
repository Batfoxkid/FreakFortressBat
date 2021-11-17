void DataBase_CreateCookies()
{
    FF2Cookies = RegClientCookie("ff2_cookies_mk2", "Player's Preferences", CookieAccess_Protected);
    StatCookies = RegClientCookie("ff2_cookies_stats", "Player's Statistics", CookieAccess_Protected);
    HudCookies = RegClientCookie("ff2_cookies_huds", "Player's HUD Settings", CookieAccess_Protected);
    LastPlayedCookie = RegClientCookie("ff2_boss_previous", "Player's Last Boss", CookieAccess_Protected);
    SelectionCookie = RegClientCookie("ff2_boss_selection", "Player's Boss Selection", CookieAccess_Protected);
    DiffCookie = RegClientCookie("ff2_boss_difficulty", "Player's Difficulty Selection", CookieAccess_Protected);
}

void DataBase_SetupDatabase()
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

void DataBase_SetupClientCookies(int client)
{
	if(!Utils_IsValidClient(client))
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
		Utils_CheckValidBoss(client, xIncoming[client], !DuoMin);

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

void DataBase_SaveClientPreferences(int client)
{
	if(!Utils_IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client))
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

void DataBase_SaveClientStats(int client)
{
	if(SpecialRound || !Utils_IsValidClient(client) || IsFakeClient(client) || cvarStatPlayers.IntValue<1 || (!cvarBvBStat.BoolValue && Enabled3))
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

void DataBase_AddClientStats(int client, CookieStats cookie, int num)
{
	if(SpecialRound || !Utils_IsValidClient(client) || cvarStatPlayers.IntValue<1)
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

void DataBase_SaveKeepBossCookie(int client)
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