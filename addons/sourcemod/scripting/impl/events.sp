void Events_HookGameEvents()
{
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
	
	HookUserMessage(GetUserMessageId("PlayerJarated"), OnJarate);	//Used to subtract rage when a boss is jarated (not through Sydney Sleeper)
}

// Callbacks

// Round Events
public void OnRoundSetup(Event event, const char[] name, bool dontBroadcast)
{
	teamplay_round_start_TeleportToMultiMapSpawn(); // Cache spawns
	FF2Globals.IsCapping = false;
	FF2Globals.IsSpecialRound = false;
	if(FF2ModsInfo.ChangeGamemode == 1)
	{
		EnableFF2();
	}
	else if(FF2ModsInfo.ChangeGamemode == 2)
	{
		DisableFF2();
	}

	if(!ConVars.Enabled.BoolValue)
	{
		FF2Globals.Enabled2 = false;
		FF2Globals.Enabled3 = false;
		if(FF2Globals.ChangedDescription && ConVars.SteamTools.BoolValue)
		{
			#if defined _SteamWorks_Included
			if(FF2Globals.SteamWorks)
			{
				SteamWorks_SetGameDescription("Team Fortress");
				FF2Globals.Enabled = false;
				FF2Globals.ChangedDescription = false;
				return;
			}
			#endif

			#if defined _steamtools_included
			if(FF2Globals.SteamTools)
				Steam_SetGameDescription("Team Fortress");
			#endif
		}
		FF2Globals.ChangedDescription = false;
	}

	FF2Globals.Enabled = FF2Globals.Enabled2;
	if(!FF2Globals.Enabled)
		return;

	if(FileExists("bNextMapToFF2"))
		DeleteFile("bNextMapToFF2");

	FF2Globals.CurrentBossTeam = GetRandomInt(1, 2);
	switch(ConVars.ForceBossTeam.IntValue)
	{
		case 1:
			FF2Globals.IsBossBlue = view_as<bool>(GetRandomInt(0, 1));

		case 2:
			FF2Globals.IsBossBlue = false;

		default:
			FF2Globals.IsBossBlue = true;
	}

	if(FF2Globals.IsBossBlue)
	{
		SetTeamScore(view_as<int>(TFTeam_Red), GetTeamScore(FF2Globals.OtherTeam));
		SetTeamScore(view_as<int>(TFTeam_Blue), GetTeamScore(FF2Globals.BossTeam));
		FF2Globals.OtherTeam = view_as<int>(TFTeam_Red);
		FF2Globals.BossTeam = view_as<int>(TFTeam_Blue);
	}
	else
	{
		SetTeamScore(view_as<int>(TFTeam_Red), GetTeamScore(FF2Globals.BossTeam));
		SetTeamScore(view_as<int>(TFTeam_Blue), GetTeamScore(FF2Globals.OtherTeam));
		FF2Globals.OtherTeam = view_as<int>(TFTeam_Blue);
		FF2Globals.BossTeam = view_as<int>(TFTeam_Red);
	}

	FF2Globals.TotalPlayers = 0;
	FF2Globals.TotalRealPlayers = 0;
	FF2Globals.BossTeamPlayers = 0;
	FF2Globals.MercsPlayers = 0;
	FF2Globals.Bosses = 0;
	for(int client; client<=MaxClients; client++)
	{
		FF2PlayerInfo[client].Damage = 0;
		FF2PlayerInfo[client].HealingAmount = 0;
		FF2PlayerInfo[client].UberTarget = -1;
		FF2BossInfo[client].EmitRageSound = true;
		FF2PlayerInfo[client].AirstrikeDamage = 0.0;
		FF2PlayerInfo[client].KillstreakDamage = 0.0;
		if(Utils_IsValidClient(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
		{
			FF2Globals.TotalPlayers++;
			if(!IsFakeClient(client))
				FF2Globals.TotalRealPlayers++;

			if(Utils_IsBoss(client))
				FF2Globals.Bosses++;

			if(GetClientTeam(client)==FF2Globals.BossTeam)
			{
				FF2Globals.BossTeamPlayers++;
			}
			else
			{
				FF2Globals.MercsPlayers++;
			}
		}
	}

	if(GetClientCount()<=1 || FF2Globals.TotalPlayers<=1)  //Not enough players D:
	{
		FPrintToChatAll("%t", "needmoreplayers");
		FF2ModsInfo.cvarHostName.SetString(FF2ModsInfo.OldHostName);
		FF2Globals.Enabled = false;
		DisableSubPlugins();
		Utils_SetControlPoint(true);
		return;
	}
	else if(FF2Globals.RoundCount<FF2GlobalsCvars.ArenaRounds)  //We're still in arena mode
	{
		FPrintToChatAll("%t", "arena_round", FF2GlobalsCvars.ArenaRounds-FF2Globals.RoundCount);
		FF2Globals.Enabled = false;
		DisableSubPlugins();
		Utils_SetArenaCapEnableTime(60.0);
		CreateTimer(71.0, Timer_EnableCap, _, TIMER_FLAG_NO_MAPCHANGE);
		bool toRed;
		TFTeam team;
		for(int client=1; client<=MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && (team=view_as<TFTeam>(GetClientTeam(client)))>TFTeam_Spectator)
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
		FF2BossInfo[client].Boss = 0;
		FF2BossInfo[client].HasSwitched = false;
		FF2BossInfo[client].HasEquipped = false;
		if(Utils_IsValidClient(client) && IsPlayerAlive(client) && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HASONGIVED))
			TF2_RespawnPlayer(client);
	}

	FF2Globals.Enabled = true;
	EnableSubPlugins();
	CheckArena();
	StopMusic();

	bool[] omit = new bool[MaxClients+1];
	FF2BossInfo[0].Boss = Utils_GetClientWithMostQueuePoints(omit, FF2Globals.OtherTeam);
	omit[FF2BossInfo[0].Boss] = true;
	if(FF2Globals.Enabled3)
	{
		FF2BossInfo[MAXBOSSES].Boss = Utils_GetClientWithoutBlacklist(omit, FF2Globals.BossTeam);
		omit[FF2BossInfo[MAXBOSSES].Boss] = true;
		FF2BossInfo[MAXBOSSES].HasSwitched = true;

		if(ConVars.BvBChaos.IntValue > 1)
		{
			int bossCount = 0;
			while(bossCount < (ConVars.BvBChaos.IntValue-1))
			{
				bossCount++;
				FF2BossInfo[bossCount].Boss = Utils_GetClientWithMostQueuePoints(omit, FF2Globals.OtherTeam);
				omit[FF2BossInfo[bossCount].Boss] = true;
				FF2BossInfo[MAXBOSSES+bossCount].Boss = Utils_GetClientWithoutBlacklist(omit, FF2Globals.BossTeam);
				omit[FF2BossInfo[MAXBOSSES+bossCount].Boss] = true;
				FF2BossInfo[MAXBOSSES+bossCount].HasSwitched = true;
			}
		}
		FF2Globals.CheatsUsed = true;
	}

	bool teamHasPlayers[2];
	for(int client=1; client<=MaxClients; client++)  //Find out if each team has at least one player on it
	{
		if(Utils_IsValidClient(client))
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
			if(Utils_IsValidClient(FF2BossInfo[boss].Boss))
				Utils_AssignTeam(FF2BossInfo[boss].Boss, FF2BossInfo[boss].HasSwitched ? FF2Globals.OtherTeam : FF2Globals.BossTeam);
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && !Utils_IsBoss(client) && (GetClientTeam(client)!=FF2Globals.OtherTeam && !FF2Globals.Enabled3))
				CreateTimer(0.1, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		return;  //NOTE: This is needed because OnRoundSetup gets fired a second time once both teams have players
	}

	PickCharacter(0, 0);
	if((FF2BossInfo[0].Special<0) || !FF2CharSetInfo.BossKV[FF2BossInfo[0].Special])
	{
		LogToFile(FF2LogsPaths.Errors, "[!!!] Couldn't find a boss for index 0!");
		return;
	}

	if(FF2Globals.Enabled3)
	{
		PickCharacter(MAXBOSSES, MAXBOSSES);
		if((FF2BossInfo[MAXBOSSES].Special<0) || !FF2CharSetInfo.BossKV[FF2BossInfo[MAXBOSSES].Special])
		{
			LogToFile(FF2LogsPaths.Errors, "[!!!] Couldn't find a boss for index %i!", MAXBOSSES);
			return;
		}

		if(ConVars.BvBChaos.IntValue > 1)
		{
			int bossCount = 0;
			while(bossCount<(ConVars.BvBChaos.IntValue-1) && bossCount<(FF2Globals.TotalPlayers-1))
			{
				bossCount++;
				PickCharacter(bossCount, bossCount);
				if((FF2BossInfo[bossCount].Special<0) || !FF2CharSetInfo.BossKV[FF2BossInfo[bossCount].Special])
				{
					LogToFile(FF2LogsPaths.Errors, "[!!!] Couldn't find a boss for index %i!", bossCount);
					return;
				}

				PickCharacter(MAXBOSSES+bossCount, MAXBOSSES+bossCount);
				if((FF2BossInfo[MAXBOSSES+bossCount].Special<0) || !FF2CharSetInfo.BossKV[FF2BossInfo[MAXBOSSES+bossCount].Special])
				{
					LogToFile(FF2LogsPaths.Errors, "[!!!] Couldn't find a boss for index %i!", MAXBOSSES+bossCount);
					return;
				}
			}
		}
	}

	FindCompanion(0, FF2Globals.TotalPlayers, omit);  //Find companions for the boss!
	if(FF2Globals.Enabled3)
	{
		FindCompanion(MAXBOSSES, FF2Globals.TotalPlayers, omit);
		if(ConVars.BvBChaos.IntValue > 1)
		{
			int bossCount = 0;
			while(bossCount<(ConVars.BvBChaos.IntValue-1) && bossCount<(FF2Globals.TotalPlayers-1))
			{
				bossCount++;
				FindCompanion(bossCount, FF2Globals.TotalPlayers, omit);
				FindCompanion(MAXBOSSES+bossCount, FF2Globals.TotalPlayers, omit);
			}
		}
	}

	for(int boss; boss<=MaxClients; boss++)
	{
		if(FF2BossInfo[boss].Boss)
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

	if(ConVars.ToggleBoss.BoolValue)
	{
		for(int client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsValidClient(client))
				continue;

			ClientQueue[client][0] = client;
			ClientQueue[client][1] = FF2PlayerCookie[client].QueuePoints;
		}

		SortCustom2D(ClientQueue, sizeof(ClientQueue), Utils_SortQueueDesc);

		for(int client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsValidClient(client) || Utils_IsBoss(client))
				continue;

			if(FF2PlayerCookie[client].Boss != Setting_On)
			{
				static char nick[64];
				GetClientName(client, nick, sizeof(nick));
				if(FF2PlayerCookie[client].Boss == Setting_Off)
				{
					FPrintToChat(client, "%t", "FF2 Toggle Disabled Notification");
				}
				else if(FF2PlayerCookie[client].Boss == Setting_Temp)
				{
					FPrintToChat(client, "%t", "FF2 Toggle Disabled Notification For Map");
				}
				else
				{
					CreateTimer(ConVars.FF2TogglePrefDelay.FloatValue, BossMenuTimer, GetClientUserId(client));
				}
				continue;
			}

			ClientID[client] = ClientQueue[client][0];
			ClientPoint[client] = ClientQueue[client][1];

			if(FF2PlayerCookie[client].Boss == Setting_On)
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
					FPrintToChat(client, "%t", "FF2 Toggle Queue Notification", index, FF2PlayerCookie[client].QueuePoints);
				}
				else
				{
					FPrintToChat(client, "%t", "FF2 Toggle Enabled Notification");
				}
				continue;
			}
		}
	}

	FF2Globals.HealthCheckCounter = 0;
	FF2Globals.FirstBlood = true;
	FF2Globals.CheatsUsed = false;
	FF2Globals.ShowHealthText = false;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2Globals.Enabled)
		return;

	CreateTimer(0.5, MessageTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Timer_Move, _, TIMER_FLAG_NO_MAPCHANGE);
	bool isBossAlive;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(Utils_IsValidClient(FF2BossInfo[boss].Boss) && IsPlayerAlive(FF2BossInfo[boss].Boss))
		{
			isBossAlive = true;
			SetEntityMoveType(FF2BossInfo[boss].Boss, MOVETYPE_NONE);
		}
	}

	if(!isBossAlive)
		return;

	int point = MaxClients+1;
	while((point=Utils_FindEntityByClassname2(point, "trigger_capture_area")) != -1)
	{
		SDKHook(point, SDKHook_StartTouch, OnCPTouch);
		SDKHook(point, SDKHook_Touch, OnCPTouch);
	}

	FF2Globals.TotalPlayers = 0;
	FF2Globals.TotalRealPlayers = 0;
	FF2Globals.BossTeamPlayers = 0;
	FF2Globals.MercsPlayers = 0;
	FF2Globals.Bosses = 0;
	int medigun, boss;
	static char command[512];
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client))
		{
			CreateTimer(2.0, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			if(!Utils_IsBoss(client) && IsPlayerAlive(client))
			{
				FF2Globals.TotalPlayers++;
				CreateTimer(0.15, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);  //TODO:  Is this needed?
				if(!IsFakeClient(client))
					FF2Globals.TotalRealPlayers++;

				if(TF2_GetPlayerClass(client) == TFClass_Medic)
				{
					medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(IsValidEntity(medigun))
						SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", FF2GlobalsCvars.StartingUber/100.0);
				}

				if(GetClientTeam(client) == FF2Globals.BossTeam)
				{
					FF2Globals.BossTeamPlayers++;
				}
				else
				{
					FF2Globals.MercsPlayers++;
				}
			}
			else if(Utils_IsBoss(client))
			{
				FF2Globals.Bosses++;
				boss = Utils_GetBossIndex(client);
				KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
				KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "command", command, sizeof(command));
				if(command[0])
					ServerCommand(command);
			}
		}
	}

	float players = 1.0;
	if(FF2Globals.Enabled3)
	{
		players += FF2Globals.MercsPlayers + FF2Globals.Bosses - FF2Globals.BossTeamPlayers*0.75;
		float players2 = FF2Globals.BossTeamPlayers + 1 + FF2Globals.Bosses - FF2Globals.MercsPlayers*0.75;
		for(boss=0; boss<=MaxClients; boss++)
		{
			if(Utils_IsValidClient(FF2BossInfo[boss].Boss) && IsPlayerAlive(FF2BossInfo[boss].Boss))
			{
				if(FF2BossInfo[boss].HasSwitched)
				{
					FF2BossInfo[boss].HealthMax = ParseFormula(boss, "health_formula", FF2GlobalsCvars.HealthFormula, RoundFloat(Pow((760.8+players2)*(players2-1.0), 1.0341)+2046.0));
				}
				else
				{
					FF2BossInfo[boss].HealthMax = ParseFormula(boss, "health_formula", FF2GlobalsCvars.HealthFormula, RoundFloat(Pow((760.8+players)*(players-1.0), 1.0341)+2046.0));
				}
				if(FF2BossInfo[boss].HealthMax*FF2BossInfo[boss].LivesMax < 350)
					FF2BossInfo[boss].HealthMax = RoundToFloor(350.0/FF2BossInfo[boss].LivesMax);

				FF2BossInfo[boss].Health = FF2BossInfo[boss].HealthMax*FF2BossInfo[boss].LivesMax;
				FF2BossInfo[boss].HealthLast = FF2BossInfo[boss].Health;
			}
		}
	}
	else
	{
		players += FF2Globals.TotalPlayers;
		for(boss=0; boss<=MaxClients; boss++)
		{
			if(Utils_IsValidClient(FF2BossInfo[boss].Boss) && IsPlayerAlive(FF2BossInfo[boss].Boss))
			{
				FF2BossInfo[boss].HealthMax = ParseFormula(boss, "health_formula", FF2GlobalsCvars.HealthFormula, RoundFloat(Pow((760.8+players)*(players-1.0), 1.0341)+2046.0));
				FF2BossInfo[boss].Health = FF2BossInfo[boss].HealthMax*FF2BossInfo[boss].LivesMax;
				FF2BossInfo[boss].HealthLast = FF2BossInfo[boss].Health;
			}
		}
	}

	if(FF2Globals.Bosses==1 && FF2ModsInfo.DiffCfg!=null && Utils_IsValidClient(FF2BossInfo[0].Boss) && IsPlayerAlive(FF2BossInfo[0].Boss))
	{
		if(!IsFakeClient(FF2BossInfo[0].Boss) && !ConVars.Difficulty.BoolValue && dIncoming[FF2BossInfo[0].Boss][0])
		{
			LoadDifficulty(0);
		}
		else if((IsFakeClient(FF2BossInfo[0].Boss) && !ConVars.Difficulty.BoolValue && !GetRandomInt(0, 9)) || (GetRandomFloat(0.0, 100.0)<ConVars.Difficulty.FloatValue && FF2PlayerCookie[FF2BossInfo[0].Boss].Diff!=Setting_Off  && FF2PlayerCookie[FF2BossInfo[0].Boss].Diff!=Setting_Temp))
		{
			int count;
			KvRewind(FF2ModsInfo.DiffCfg);
			KvGotoFirstSubKey(FF2ModsInfo.DiffCfg);
			while(KvGotoNextKey(FF2ModsInfo.DiffCfg))
			{
				count++;
			}

			if(count)
			{
				KvRewind(FF2ModsInfo.DiffCfg);
				KvGotoFirstSubKey(FF2ModsInfo.DiffCfg);
				for(count=GetRandomInt(0, count-1); count>0; count--)
				{
					KvGotoNextKey(FF2ModsInfo.DiffCfg);
				}

				KvGetSectionName(FF2ModsInfo.DiffCfg, dIncoming[FF2BossInfo[0].Boss], sizeof(dIncoming[]));
				LoadDifficulty(0);
			}
		}
	}

	CreateTimer(0.2, BossTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, Timer_StartRound, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.2, GlobalTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	if(!FF2GlobalsCvars.PointType)
		Utils_SetControlPoint(false);

	if(ConVars.NameChange.IntValue == 1)
	{
		char newName[256];
		static char bossName[64];
		Utils_GetBossSpecial(FF2BossInfo[0].Special, bossName, 64);
		FormatEx(newName, 256, "%s | %s", FF2ModsInfo.OldHostName, bossName);
		FF2ModsInfo.cvarHostName.SetString(newName);
	}
}

public void OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	FF2Globals.RoundCount++;
	FF2Globals.IsSapperEnabled = false;
	FF2Globals.IsLastMan = true;
	if(FF2Globals.HasSwitched)
		FF2Globals.HasSwitched = false;

	CheckDuoMin();
	
	if (FF2SavedAbility)
		FF2SavedAbility.ClearAll();
	
	if(!FF2Globals.Enabled)
	{
		FF2Globals.Enabled3 = false;
		return;
	}

	int team = event.GetInt("team");
	if(ConVars.BossLog.IntValue>0 && ConVars.BossLog.IntValue<=FF2Globals.TotalRealPlayers && !FF2Globals.CheatsUsed && !FF2Globals.IsSpecialRound)
	{
		static char bossName[64], FormatedTime[64], Result[64], PlayerName[64], Authid[64];
		int CurrentTime = GetTime();
		int boss;

		FormatTime(FormatedTime, sizeof(FormatedTime), "%X", CurrentTime);
		strcopy(Result, sizeof(Result), team==FF2Globals.BossTeam ? "won" : "loss");
		for(int client=1; client<=MaxClients; client++)
		{
			boss = Utils_GetBossIndex(client);
			if(boss != -1)
			{
				if(IsFakeClient(client))
				{
					strcopy(PlayerName, sizeof(PlayerName), "Bot");
					strcopy(Authid, sizeof(Authid), "Bot");
				}
				else
				{
					GetClientName(FF2BossInfo[boss].Boss, PlayerName, sizeof(PlayerName));
					GetClientAuthId(FF2BossInfo[boss].Boss, AuthId_Steam2, Authid, sizeof(Authid), false);
				}
				KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
				KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "filename", bossName, sizeof(bossName));
				FF2LogsPaths.WriteRoundInfo(bossName, FormatedTime, PlayerName, Authid, Result);
			}
		}
	}

	FF2Globals.FF2Executed = false;
	FF2Globals.FF2Executed2 = false;
	int bossWin = 0;
	float bonusRoundTime = GetConVarFloat(FindConVar("mp_bonusroundtime"))-0.5;
	static char sound[PLATFORM_MAX_PATH];
	if(team == FF2Globals.BossTeam)
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
	else if(team == FF2Globals.OtherTeam)
	{
		if(FF2Globals.Enabled3)
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

	if(FF2Globals.Enabled3 && bossWin>-1)
	{
		int target;
		char[][] text = new char[MaxClients+1][128];
		bool multi;
		static char bossName[64];
		for(int boss; boss<=MaxClients; boss++)
		{
			target = FF2BossInfo[boss].Boss;
			if(Utils_IsValidClient(target))
			{
				if(GetClientTeam(target) == team)
				{
					char lives[8];
					if(FF2BossInfo[boss].Lives > 1)
						FormatEx(lives, sizeof(lives), "x%i", FF2BossInfo[boss].Lives);

					for(int client=1; client<=MaxClients; client++)
					{
						if(Utils_IsValidClient(client))
						{
							Utils_GetBossSpecial(FF2BossInfo[boss].Special, bossName, sizeof(bossName), client);
							Format(text[client], 128, "%s\n%t", multi ? text[client] : "", "ff2_alive", bossName, target, FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1), FF2BossInfo[boss].HealthMax, lives);
							FPrintToChat(client, "%t", "ff2_alive", bossName, target, FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1), FF2BossInfo[boss].HealthMax, lives);
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
			if(Utils_IsValidClient(client) && !FF2PlayerCookie[client].HudSettings[2] && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HUDDISABLED) && !(GetClientButtons(client) & IN_SCORE))
				ShowHudText(client, -1, text[client]);
		}
	}

	StopMusic();
	FF2Globals.DrawGameTimer = INVALID_HANDLE;

	bool isBossAlive;
	for(int client; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(FF2BossInfo[client].Boss))
		{
			Utils_SetClientGlow(FF2BossInfo[client].Boss, 0.0, 0.0);
			SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal
			if(IsPlayerAlive(FF2BossInfo[client].Boss))
				isBossAlive = true;

			for(int slot=1; slot<4; slot++)
			{
				FF2BossInfo[client].Charge[slot] = 0.0;
			}
			DataBase_SaveClientStats(client);
		}
		else if(Utils_IsValidClient(client))
		{
			Utils_SetClientGlow(client, 0.0, 0.0);
			FF2PlayerInfo[client].HasShield = false;
			FF2PlayerInfo[client].EntShield = 0;
			FF2PlayerInfo[client].Detonations = 0;
			FF2PlayerInfo[client].AirstrikeDamage = 0.0;
			FF2PlayerInfo[client].KillstreakDamage = 0.0;
			FF2PlayerInfo[client].HazardDamage = 0.0;
			FF2PlayerInfo[client].SapperCooldown = ConVars.SapperStart.FloatValue;
			DataBase_SaveClientStats(client);
		}
	}

	bool botBoss;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(Utils_IsBoss(boss) && IsFakeClient(boss))
		{
			botBoss = true;
			break;
		}
	}

	bool gainedPoint[MAXTF2PLAYERS];
	int statPlayers = ConVars.StatPlayers.IntValue;
	if(!botBoss && statPlayers<=FF2Globals.TotalRealPlayers && statPlayers>0)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Utils_IsBoss(boss))
			{
				if(bossWin > 0)
				{
					DataBase_AddClientStats(boss, Cookie_BossWins, 1);
					gainedPoint[boss] = true;
				}
				else if(!bossWin)
				{
					DataBase_AddClientStats(boss, Cookie_BossLosses, 1);
					gainedPoint[boss] = true;
				}
			}
		}
	}

	int StatWin2Lose = ConVars.StatWin2Lose.IntValue;
	if(StatWin2Lose==2 || StatWin2Lose>3)
	{
		for(int boss=1; boss<=MaxClients; boss++)
		{
			if(Utils_IsBoss(boss) && !IsFakeClient(boss))
			{
				if(gainedPoint[boss] || StatWin2Lose>2)
				{
					FPrintToChat(boss, "%t", "Win To Lose Self", FF2PlayerCookie[boss].BossWins, FF2PlayerCookie[boss].BossLosses);
					CSkipNextClient(boss);
					FPrintToChatAll("%t", "Win To Lose", boss, FF2PlayerCookie[boss].BossWins, FF2PlayerCookie[boss].BossLosses);
				}
				else
				{
					for(int client=1; client<=MaxClients; client++)
					{
						if(Utils_IsValidClient(client) && CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true))
							FPrintToChat(client, "%t", "Win To Lose", boss, FF2PlayerCookie[boss].BossWins, FF2PlayerCookie[boss].BossLosses);
					}
				}
			}
		}
	}
	else if(StatWin2Lose > -1)
	{
		for(int boss=1; boss<=MaxClients; boss++)
		{
			if(Utils_IsBoss(boss) && !IsFakeClient(boss))
			{
				if(StatWin2Lose>0 && (gainedPoint[boss] || StatWin2Lose>2))
				{
					FPrintToChat(boss, "%t", "Win To Lose Self", FF2PlayerCookie[boss].BossWins, FF2PlayerCookie[boss].BossLosses);
				}
				for(int client=1; client<=MaxClients; client++)
				{
					if(CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && Utils_IsValidClient(client) && (client!=boss || !(StatWin2Lose>0 && (gainedPoint[boss] || StatWin2Lose>3))))
						FPrintToChat(client, "%t", "Win To Lose", boss, FF2PlayerCookie[boss].BossWins, FF2PlayerCookie[boss].BossLosses);
				}
			}
		}
	}

	if(!FF2Globals.Enabled3 && isBossAlive)
	{
		int target;
		char[][] text = new char[MaxClients+1][128];
		bool multi;
		static char bossName[64];
		for(int boss; boss<=MaxClients; boss++)
		{
			target = FF2BossInfo[boss].Boss;
			if(Utils_IsValidClient(target))
			{
				char lives[8];
				if(FF2BossInfo[boss].Lives > 1)
					FormatEx(lives, sizeof(lives), "x%i", FF2BossInfo[boss].Lives);

				for(int client=1; client<=MaxClients; client++)
				{
					if(Utils_IsValidClient(client))
					{
						Utils_GetBossSpecial(FF2BossInfo[boss].Special, bossName, sizeof(bossName), client);
						Format(text[client], 128, "%s\n%t", multi ? text[client] : "", "ff2_alive", bossName, target, FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1), FF2BossInfo[boss].HealthMax, lives);
						FPrintToChat(client, "%t", "ff2_alive", bossName, target, FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1), FF2BossInfo[boss].HealthMax, lives);
						if(FF2Globals.IsSpecialRound)
							Format(text[client], 128, "%s\n(%s)", text[client], dIncoming[target]);
					}
				}
				multi = true;
			}
		}

		SetHudTextParams(-1.0, 0.25, bonusRoundTime, 255, 255, 255, 255);
		for(int client=1; client<=MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && !FF2PlayerCookie[client].HudSettings[2] && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HUDDISABLED) && !(GetClientButtons(client) & IN_SCORE))
				ShowHudText(client, -1, text[client]);
		}

		if(!bossWin && RandomSound("sound_fail", sound, sizeof(sound)))
			EmitSoundToAllExcept(sound);
	}

	int top[3];
	FF2PlayerInfo[0].Damage = 0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!Utils_IsValidClient(client) || FF2PlayerInfo[client].Damage<1 || Utils_IsBoss(client))
			continue;

		if(FF2PlayerInfo[client].Damage >= FF2PlayerInfo[top[0]].Damage)
		{
			top[2] = top[1];
			top[1] = top[0];
			top[0] = client;
		}
		else if(FF2PlayerInfo[client].Damage >= FF2PlayerInfo[top[1]].Damage)
		{
			top[2] = top[1];
			top[1] = client;
		}
		else if(FF2PlayerInfo[client].Damage >= FF2PlayerInfo[top[2]].Damage)
		{
			top[2] = client;
		}
	}

	if(!FF2Globals.Isx10 && FF2PlayerInfo[top[0]].Damage>9000)
		CreateTimer(1.0, Timer_NineThousand, _, TIMER_FLAG_NO_MAPCHANGE);

	if(!botBoss && statPlayers>0)
	{
		if(statPlayers <= FF2Globals.TotalRealPlayers)
			DataBase_AddClientStats(top[0], Cookie_PlayerMvps, 1);

		if(statPlayers*2 <= FF2Globals.TotalRealPlayers)
			DataBase_AddClientStats(top[1], Cookie_PlayerMvps, 1);

		if(statPlayers*3 <= FF2Globals.TotalRealPlayers)
			DataBase_AddClientStats(top[2], Cookie_PlayerMvps, 1);
	}

	static char leaders[3][32];
	for(int i; i<=2; i++)
	{
		if(Utils_IsValidClient(top[i]))
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
		if(!Utils_IsValidClient(client) || (FF2PlayerInfo[client].FF2Flags & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
			continue;

		SetGlobalTransTarget(client);
		if(Utils_IsBoss(client) && GetClientTeam(client)==team)
		{
			ShowSyncHudText(client, FF2Huds.PlayerInfo, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "top_3", FF2PlayerInfo[top[0]].Damage, leaders[0], FF2PlayerInfo[top[1]].Damage, leaders[1], FF2PlayerInfo[top[2]].Damage, leaders[2], "boss_win");
		}
		else if(Utils_IsBoss(client))
		{
			ShowSyncHudText(client, FF2Huds.PlayerInfo, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "top_3", FF2PlayerInfo[top[0]].Damage, leaders[0], FF2PlayerInfo[top[1]].Damage, leaders[1], FF2PlayerInfo[top[2]].Damage, leaders[2], "boss_lose");
		}
		else
		{
			ShowSyncHudText(client, FF2Huds.PlayerInfo, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t\n%t", text, "top_3", FF2PlayerInfo[top[0]].Damage, leaders[0], FF2PlayerInfo[top[1]].Damage, leaders[1], FF2PlayerInfo[top[2]].Damage, leaders[2], "damage_fx", FF2PlayerInfo[client].Damage, "scores", RoundFloat(FF2PlayerInfo[client].Damage/FF2GlobalsCvars.PointsInterval2));
		}
	}

	if(ConVars.BossVsBoss.IntValue > 0)
	{
		if(GetRandomInt(0, 99) < ConVars.BossVsBoss.IntValue)
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
		FF2Globals.Enabled3 = false;
	}

	if(FF2Globals.ReloadFF2)
	{
		ServerCommand("sm plugins reload freak_fortress_2");
		return;
	}

	if(FF2Globals.ReloadConfigs)
	{
		CacheWeapons();
		CacheDifficulty();
		Utils_CheckToChangeMapDoors();
		Utils_CheckToTeleportToSpawn();
		FindCharacters();
		FF2CharSetInfo.CurrentCharSet[0] = 0;
		FF2Globals.ReloadConfigs = false;
		FF2Globals.LoadCharset = false;
		FF2Globals.ReloadWeapons = false;
	}

	if(FF2Globals.LoadCharset)
	{
		FindCharacters();
		FF2CharSetInfo.CurrentCharSet[0] = 0;
		FF2Globals.LoadCharset = false;
	}

	if(FF2Globals.ReloadWeapons)
	{
		CacheWeapons();
		FF2Globals.ReloadWeapons = false;
	}

	CreateTimer(3.0, Timer_CalcQueuePoints, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
}


// Control Point Events
public void OnStartCapture(Event event, const char[] name, bool dontBroadcast)
{
	FF2Globals.IsCapping = true;
}

public void OnBreakCapture(Event event, const char[] name, bool dontBroadcast)
{
	if(!event.GetFloat("time_remaining"))
		FF2Globals.IsCapping = false;
}


// Player Events
public Action OnPostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2Globals.Enabled)
		return Plugin_Continue;

	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(!Utils_IsValidClient(client))
		return Plugin_Continue;

	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");

	if(Utils_IsBoss(client))
	{
		int boss = Utils_GetBossIndex(client);
		FF2BossInfo[boss].HasEquipped = false;
		CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
	}

	if(!(FF2PlayerInfo[client].FF2Flags & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		if(!(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HASONGIVED))
		{
			FF2PlayerInfo[client].FF2Flags |= FF2FLAG_HASONGIVED;
			Utils_RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
			Utils_RemovePlayerTarge(client);
			TF2_RemoveAllWeapons(client);
			TF2_RegeneratePlayer(client);
			CreateTimer(0.1, Timer_RegenPlayer, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
		CreateTimer(0.2, Timer_MakeNotBoss, userid, TIMER_FLAG_NO_MAPCHANGE);
	}

	FF2PlayerInfo[client].FF2Flags &= ~(FF2FLAG_UBERREADY|FF2FLAG_ISBUFFED|FF2FLAG_TALKING|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_USINGABILITY|FF2FLAG_CLASSHELPED|FF2FLAG_CHANGECVAR|FF2FLAG_ROCKET_JUMPING);
	FF2PlayerInfo[client].FF2Flags |= FF2FLAG_USEBOSSTIMER|FF2FLAG_ALLOW_HEALTH_PICKUPS|FF2FLAG_ALLOW_AMMO_PICKUPS;
	return Plugin_Continue;
}

public Action OnPlayerHealed(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2Globals.Enabled || Utils_CheckRoundState()!=1)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("patient"));
	int healer = GetClientOfUserId(event.GetInt("healer"));
	int heals = event.GetInt("amount");

	if(Utils_IsBoss(client))
	{
		int boss = Utils_GetBossIndex(client);
		int health = FF2BossInfo[boss].Health;
		int totalhealth = FF2BossInfo[boss].HealthMax*FF2BossInfo[boss].Lives;

		if(client==healer && (FF2BossVar[client].SelfHealing==1 || FF2BossVar[client].SelfHealing>2))
		{
			health += heals;
			if(health > totalhealth)
				health = totalhealth;
		}
		else if(client!=healer && FF2BossVar[client].SelfHealing>1)
		{
			health += heals;
			if(health > totalhealth)
				health = totalhealth;
		}
		FF2BossInfo[boss].Health = health;
		return Plugin_Continue;
	}

	if(client == healer)
		return Plugin_Continue;

	int extrahealth = GetClientHealth(client)-GetEntProp(client, Prop_Data, "m_iMaxHealth");
	if(extrahealth > 0)
		heals -= extrahealth;

	if(heals > 0)
		FF2PlayerInfo[healer].HealingAmount += heals;

	return Plugin_Continue;
}

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2Globals.Enabled)
		return Plugin_Continue;

	if(Utils_CheckRoundState() == 1)
		CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!Utils_IsValidClient(client))
		return Plugin_Continue;

	FF2PlayerInfo[client].LastAliveClass = TF2_GetPlayerClass(client);
	for(int i; i<3; i++)
	{
		FF2PlayerInfo[client].CritBoosted[i] = -1;
	}
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2Globals.Enabled)
		return Plugin_Continue;

	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Continue;

	int flags = event.GetInt("death_flags");
	if(FF2Globals.Enabled3 && !(flags & TF_DEATHFLAG_DEADRINGER)) // Because those damn subplugins
	{
		int reds, blus;
		if(Utils_CheckRoundState() == 1)
		{
			reds = FF2Globals.AliveMercPlayers;
			blus = FF2Globals.AliveBossPlayers;
		}
		else
		{
			for(int target=1; target<=MaxClients; target++)
			{
				if(!Utils_IsValidClient(target))
					continue;

				if(GetClientTeam(target) == FF2Globals.OtherTeam)
				{
					reds++;
				}
				else if(GetClientTeam(target) == FF2Globals.BossTeam)
				{
					blus++;
				}
			}
		}

		if(reds>blus || (reds==blus && GetRandomInt(0, 1))) // More reds or their equal with 50/50 chance
		{
			TF2_ChangeClientTeam(client, view_as<TFTeam>(FF2Globals.BossTeam));
		}
		else
		{
			TF2_ChangeClientTeam(client, view_as<TFTeam>(FF2Globals.OtherTeam));
		}
	}

	if(Utils_CheckRoundState() != 1)
		return Plugin_Continue;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	static char sound[PLATFORM_MAX_PATH];
	CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	Utils_DoOverlay(client, "");

	if(!Utils_IsBoss(client))
	{
		if(!(flags & TF_DEATHFLAG_DEADRINGER) && (FF2Globals.Enabled3 || GetClientTeam(client)!=FF2Globals.BossTeam))
			CreateTimer(1.0, Timer_Damage, userid, TIMER_FLAG_NO_MAPCHANGE);

		if(Utils_IsBoss(attacker))
		{
			int boss = Utils_GetBossIndex(attacker);
			bool firstBloodSound = true;
			if(FF2Globals.FirstBlood)	//TF_DEATHFLAG_FIRSTBLOOD is broken
			{
				if(RandomSound("sound_first_blood", sound, sizeof(sound), boss))
				{
					EmitSoundToAllExcept(sound);
					firstBloodSound = false;
				}
				FF2Globals.FirstBlood = false;
			}

			int alivePlayers = GetClientTeam(attacker)==FF2Globals.BossTeam ? FF2Globals.AliveMercPlayers : FF2Globals.AliveBossPlayers;
			if(alivePlayers>2 && FF2BossInfo[boss].KSpreeCount<2 && firstBloodSound)  //Don't conflict with end-of-round sounds, killing spree, or first blood
			{
				if(GetRandomInt(0, 1))
				{
					char class[32];
					static char classnames[][] = {"custom", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
					FormatEx(class, sizeof(class), "sound_kill_%s", classnames[FF2PlayerInfo[client].LastAliveClass]);
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

			if(GetGameTime() <= FF2BossInfo[boss].KSpreeTimer)
			{
				FF2BossInfo[boss].KSpreeCount++;
			}
			else
			{
				FF2BossInfo[boss].KSpreeCount = 1;
			}

			if(alivePlayers>2 && FF2BossInfo[boss].KSpreeCount==3)
			{
				if(RandomSound("sound_kspree", sound, sizeof(sound), boss))
					EmitSoundToAllExcept(sound);

				FF2BossInfo[boss].KSpreeCount = 0;
			}
			else
			{
				FF2BossInfo[boss].KSpreeTimer = GetGameTime()+5.0;
			}

			if(!IsFakeClient(client) || IsFakeClient(attacker))
			{
				FF2PlayerCookie[attacker].BossKillsF++;
				if(!(flags & TF_DEATHFLAG_DEADRINGER))
					DataBase_AddClientStats(attacker, Cookie_BossKills, 1);
			}

			ActivateAbilitySlot(boss, 4);
		}
	}
	else if(attacker)
	{
		int boss = Utils_GetBossIndex(client);
		if(boss==-1 || (flags & TF_DEATHFLAG_DEADRINGER))
			return Plugin_Continue;

		if(RandomSound("sound_death", sound, sizeof(sound), boss))
			EmitSoundToAllExcept(sound);

		if(!IsFakeClient(client) || IsFakeClient(attacker))
			DataBase_AddClientStats(attacker, Cookie_PlayerKills, 1);

		if(IsFakeClient(client) || !IsFakeClient(attacker))
			DataBase_AddClientStats(client, Cookie_BossDeaths, 1);

		ActivateAbilitySlot(boss, 5);

		FF2BossInfo[boss].Health = 0;
		UpdateHealthBar();
		FF2BossInfo[boss].Stabbed = 0.0;
		FF2PlayerInfo[boss].Marketed = 0.0;
		FF2PlayerInfo[boss].Cabered = 0.0;
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

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2Globals.Enabled || Utils_CheckRoundState()!=1)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("damageamount");
	int weapon = event.GetInt("weaponid");

	if(Utils_IsValidClient(attacker) && GetClientTeam(attacker)!=GetClientTeam(client) && damage && FF2PlayerInfo[client].EntShield)
	{
		int preHealth = GetClientHealth(client)+damage;
		int health = GetClientHealth(client);
		switch(ConVars.ShieldType.IntValue)
		{
			case 2:
			{
				if(preHealth <= damage)
				{
					SetEntityHealth(client, preHealth);
					Utils_RemoveShield(client, attacker);
					return Plugin_Handled;
				}
			}
			case 3:
			{
				if(GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee)!=weapon && FF2PlayerInfo[client].ShieldHP>0 && damage<preHealth)
				{
					int damageresist = RoundFloat(float(damage)*FF2PlayerInfo[client].ShieldDmgReduction);

					FF2PlayerInfo[client].ShieldHP -= damage;		// take a small portion of shield health away

					SetEntityHealth(client, health+damageresist);

					FF2PlayerInfo[client].ShieldDmgReduction = FF2PlayerInfo[client].ShieldHP/ConVars.ShieldHealth.FloatValue*(1.0-ConVars.ShieldResist.FloatValue);

					if(FF2PlayerInfo[client].ShieldHP > 0)
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
				Utils_RemoveShield(client, attacker);
				return Plugin_Handled;
			}
			case 4:
			{
				int damageresist = RoundFloat(float(damage)*FF2PlayerInfo[client].ShieldDmgReduction);

				FF2PlayerInfo[client].ShieldHP -= damage;		// take a small portion of shield health away

				SetEntityHealth(client, health+damageresist);

				FF2PlayerInfo[client].ShieldDmgReduction = FF2PlayerInfo[client].ShieldHP/ConVars.ShieldHealth.FloatValue*(1.0-ConVars.ShieldResist.FloatValue);

				if(FF2PlayerInfo[client].ShieldHP<=0.0 || (health+damageresist)<=damage)
				{
					SetEntityHealth(client, preHealth);
					Utils_RemoveShield(client, attacker);
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

	int boss = Utils_GetBossIndex(client);
	if(boss==-1 || !FF2BossInfo[boss].Boss || !IsValidEntity(FF2BossInfo[boss].Boss) || (client==attacker && FF2BossVar[client].SelfKnockback<2))
		return Plugin_Continue;

	int custom = event.GetInt("custom");
	if(custom == TF_CUSTOM_TELEFRAG)
	{
		damage = IsPlayerAlive(attacker) ? FF2Globals.Isx10 ? RoundFloat(ConVars.Telefrag.IntValue*ConVars.TimesTen.FloatValue) : ConVars.Telefrag.IntValue : 1;
	}
	else if(custom == TF_CUSTOM_BOOTS_STOMP)
	{
		damage *= 5;
	}

	if(event.GetBool("minicrit") && event.GetBool("allseecrit"))
		event.SetBool("allseecrit", false);

	if(custom==TF_CUSTOM_TELEFRAG || custom==TF_CUSTOM_BOOTS_STOMP)
		event.SetInt("damageamount", damage);

	for(int lives=1; lives<FF2BossInfo[boss].Lives; lives++)
	{
		if(FF2BossInfo[boss].Health-damage <= FF2BossInfo[boss].HealthMax*lives)
		{
			SetEntityHealth(client, (FF2BossInfo[boss].Health-damage)-FF2BossInfo[boss].HealthMax*(lives-1)); //Set the health early to avoid the boss dying from fire, etc.

			int bossLives = FF2BossInfo[boss].Lives;
			Action action = Forwards_Call_OnLoseLife(boss, bossLives, FF2BossInfo[boss].LivesMax);
			if(action==Plugin_Stop || action==Plugin_Handled)
			{
				return action;
			}
			else if(action == Plugin_Changed)
			{
				if(bossLives > FF2BossInfo[boss].LivesMax)
				{
					FF2BossInfo[boss].LivesMax = bossLives;
				}
				FF2BossInfo[boss].Lives = bossLives;
			}

			ActivateAbilitySlot(boss, -1);

			FF2BossInfo[boss].Lives = lives;

			static char bossName[64], ability[PLATFORM_MAX_PATH];
			strcopy(ability, sizeof(ability), FF2BossInfo[boss].Lives==1 ? "ff2_life_left" : "ff2_lives_left");
			for(int target=1; target<=MaxClients; target++)
			{
				if(!Utils_IsValidClient(target) || FF2PlayerCookie[target].HudSettings[2] || (FF2PlayerInfo[target].FF2Flags & FF2FLAG_HUDDISABLED) || (!IsPlayerAlive(target) && !IsClientObserver(target)))
					continue;
	
				if(ConVars.GameText.IntValue > 0)
				{
					Utils_GetBossSpecial(FF2BossInfo[boss].Special, bossName, sizeof(bossName), target);
					Utils_ShowGameText(target, "ico_notify_flag_moving_alt", FF2Globals.Enabled3 ? GetClientTeam(client) : 0, "%t", ability, bossName, FF2BossInfo[boss].Lives);
				}
				else
				{
					Utils_GetBossSpecial(FF2BossInfo[boss].Special, bossName, sizeof(bossName), target);
					PrintCenterText(target, "%t", ability, bossName, FF2BossInfo[boss].Lives);
				}
			}

			if(FF2BossInfo[boss].Lives==1 && RandomSound("sound_last_life", ability, sizeof(ability), boss))
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

	FF2BossInfo[boss].Health -= damage;
	FF2BossInfo[boss].Charge[0] += damage*100.0/FF2BossInfo[boss].RageDamage;
	FF2PlayerInfo[attacker].Damage += damage;

	int healers[MAXTF2PLAYERS];
	int healerCount;
	for(int target; target<=MaxClients; target++)
	{
		if(Utils_IsValidClient(target) && IsPlayerAlive(target) && (Utils_GetHealingTarget(target, true)==attacker))
		{
			healers[healerCount] = target;
			healerCount++;
		}
	}

	for(int target; target<healerCount; target++)
	{
		if(Utils_IsValidClient(healers[target]) && IsPlayerAlive(healers[target]))
		{
			if(damage<10 || FF2PlayerInfo[healers[target]].UberTarget==attacker)
			{
				FF2PlayerInfo[healers[target]].Damage += damage;
			}
			else
			{
				FF2PlayerInfo[healers[target]].Damage += damage/(healerCount+1);
			}
		}
	}

	if(Utils_IsValidClient(attacker) && Utils_IsValidClient(client) && client!=attacker && damage>0 && !Utils_IsBoss(attacker))
	{
		int i;
		if(ConVars.AirStrike.FloatValue > 0)  //Air Strike-moved from OTD
		{
			int primary = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Primary);
			if(IsValidEntity(primary) && GetEntProp(primary, Prop_Send, "m_iItemDefinitionIndex")==1104)
			{
				FF2PlayerInfo[attacker].AirstrikeDamage += damage;
				while(FF2PlayerInfo[attacker].AirstrikeDamage>=ConVars.AirStrike.FloatValue && i<5)
				{
					i++;
					SetEntProp(attacker, Prop_Send, "m_iDecapitations", GetEntProp(attacker, Prop_Send, "m_iDecapitations")+1);
					FF2PlayerInfo[attacker].AirstrikeDamage -= ConVars.AirStrike.FloatValue;
				}
			}
		}
		i = 0;
		if(ConVars.Dmg2KStreak.FloatValue > 0)
		{
			FF2PlayerInfo[attacker].KillstreakDamage += damage;
			int streak = GetEntProp(attacker, Prop_Send, "m_nStreaks");
			while(FF2PlayerInfo[attacker].KillstreakDamage>=ConVars.Dmg2KStreak.FloatValue && i<21)
			{
				i++;
				FF2PlayerInfo[attacker].KillstreakDamage -= ConVars.Dmg2KStreak.FloatValue;
			}
			SetEntProp(attacker, Prop_Send, "m_nStreaks", streak+i);
		}
		if(FF2PlayerInfo[attacker].SapperCooldown > 0.0)
			FF2PlayerInfo[attacker].SapperCooldown -= damage;
	}

	if(FF2BossInfo[boss].Charge[0] > FF2BossVar[client].RageMax)
		FF2BossInfo[boss].Charge[0] = FF2BossVar[client].RageMax;

	return Plugin_Continue;
}

public void OnUberDeployed(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2Globals.Enabled)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!Utils_IsValidClient(client) || !IsPlayerAlive(client) || (FF2PlayerInfo[client].FF2Flags & FF2FLAG_CLASSTIMERDISABLED) || Utils_GetBossIndex(client)>=0)
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
	int target = Utils_GetHealingTarget(client);
	if(Utils_IsValidClient(target, false) && IsPlayerAlive(target))
	{
		//TF2_AddCondition(client, TFCond_UberchargedCanteen, 0.5);
		TF2_AddCondition(target, TFCond_HalloweenCritCandy, 0.5, client);
		FF2PlayerInfo[client].UberTarget = target;
	}
	else
	{
		FF2PlayerInfo[client].UberTarget = -1;
	}
	CreateTimer(0.4, Timer_Uber, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2Globals.Enabled || event.GetInt("weaponid"))  // 0 means that the client was airblasted, which is what we want
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("ownerid"));
	int boss = Utils_GetBossIndex(client);
	if(boss!=-1 && FF2BossInfo[boss].Charge[0]<FF2BossVar[client].RageMax)
	{
		FF2BossInfo[boss].Charge[0] += FF2BossVar[client].RageMax*7.0/FF2BossVar[client].RageMin;  //TODO: Allow this to be customizable
		if(FF2BossInfo[boss].Charge[0] > FF2BossVar[client].RageMax)
			FF2BossInfo[boss].Charge[0] = FF2BossVar[client].RageMax;
	}
	return Plugin_Continue;
}

public void OnDeployBackup(Event event, const char[] name, bool dontBroadcast)
{
	if(FF2Globals.Enabled && event.GetInt("buff_type")==2)
		FF2PlayerInfo[GetClientOfUserId(event.GetInt("buff_owner"))].FF2Flags |= FF2FLAG_ISBUFFED;
}

public void OnRPS(Event event, const char[] name, bool dontBroadcast)
{
	int winner = event.GetInt("winner");
	if(!Utils_IsValidClient(winner))
		return;

	int loser = event.GetInt("loser");
	if(!Utils_IsValidClient(loser))
		return;

	if(!Utils_IsBoss(winner) && Utils_IsBoss(loser) && ConVars.RPSLimit.IntValue>0)	// Boss Loses on RPS?
	{
		FF2Globals.RPSWinner = winner;
		TF2_AddCondition(FF2Globals.RPSWinner, TFCond_NoHealingDamageBuff, 3.4);	// I'm not bothered checking for mini-crit boost or not during damage
		CreateTimer(3.1, Timer_RPS, GetClientUserId(loser), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	int points = ConVars.RPSPoints.IntValue;	// Teammate or Minion loses?
	if(FF2PlayerCookie[winner].Boss==Setting_Off || FF2PlayerCookie[loser].Boss==Setting_Off || Utils_IsBoss(winner) || Utils_IsBoss(loser) || FF2PlayerCookie[winner].QueuePoints<points || FF2PlayerCookie[loser].QueuePoints<points || points<1)
		return;

	FPrintToChat(winner, "%t", "rps_won", points, loser);
	FF2PlayerCookie[winner].QueuePoints += points;

	FPrintToChat(loser, "%t", "rps_lost", points, winner);
	FF2PlayerCookie[loser].QueuePoints -= points;
}

public Action OnBroadcast(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2Globals.Enabled || ConVars.Broadcast.BoolValue)
		return Plugin_Continue;

	static char sound[PLATFORM_MAX_PATH];
	event.GetString("sound", sound, sizeof(sound));
	if(!StrContains(sound, "Game.Your", false) || StrEqual(sound, "Game.Stalemate", false) || !StrContains(sound, "Announcer.AM_RoundStartRandom", false))
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action OnObjectDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	if(!FF2Globals.Enabled)
		return Plugin_Continue;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(GetRandomInt(0, 2) || !Utils_IsBoss(attacker))
		return Plugin_Continue;

	static char sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_kill_buildable", sound, sizeof(sound), Utils_GetBossIndex(attacker)))
		EmitSoundToAllExcept(sound);

	return Plugin_Continue;
}

public Action OnWinPanel(Event event, const char[] name, bool dontBroadcast)
{
	return FF2Globals.Enabled ? Plugin_Handled : Plugin_Continue;
}

public Action OnJarate(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	int client = bf.ReadByte();
	int victim = bf.ReadByte();
	int boss = Utils_GetBossIndex(victim);
	if(boss == -1)
		return Plugin_Continue;

	int jarate = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(jarate==-1 || GetEntProp(jarate, Prop_Send, "m_iEntityLevel")==-122)	// -122 is the Jar of Ants which isn't really Jarate
		return Plugin_Continue;

	int index = GetEntProp(jarate, Prop_Send, "m_iItemDefinitionIndex");
	if(!(index==58 && index==1083 && index==1105))
		return Plugin_Continue;

	FF2BossInfo[boss].Charge[0] -= FF2BossVar[victim].RageMax*8.0/FF2BossVar[victim].RageMin;	//TODO: Allow this to be customizable
	if(FF2BossInfo[boss].Charge[0] < 0.0)
		FF2BossInfo[boss].Charge[0] = 0.0;

	return Plugin_Continue;
}
