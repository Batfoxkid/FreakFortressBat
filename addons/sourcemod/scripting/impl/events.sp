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
		if(Utils_IsValidClient(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
		{
			playing++;
			if(!IsFakeClient(client))
				playing2++;

			if(Utils_IsBoss(client))
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
		Utils_SetControlPoint(true);
		return;
	}
	else if(RoundCount<arenaRounds)  //We're still in arena mode
	{
		FPrintToChatAll("%t", "arena_round", arenaRounds-RoundCount);
		Enabled = false;
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
		Boss[client] = 0;
		BossSwitched[client] = false;
		HasEquipped[client] = false;
		if(Utils_IsValidClient(client) && IsPlayerAlive(client) && !(FF2flags[client] & FF2FLAG_HASONGIVED))
			TF2_RespawnPlayer(client);
	}

	Enabled = true;
	EnableSubPlugins();
	CheckArena();
	StopMusic();

	bool[] omit = new bool[MaxClients+1];
	Boss[0] = Utils_GetClientWithMostQueuePoints(omit, OtherTeam);
	omit[Boss[0]] = true;
	if(Enabled3)
	{
		Boss[MAXBOSSES] = Utils_GetClientWithoutBlacklist(omit, BossTeam);
		omit[Boss[MAXBOSSES]] = true;
		BossSwitched[MAXBOSSES] = true;

		if(cvarBvBChaos.IntValue > 1)
		{
			int bossCount = 0;
			while(bossCount < (cvarBvBChaos.IntValue-1))
			{
				bossCount++;
				Boss[bossCount] = Utils_GetClientWithMostQueuePoints(omit, OtherTeam);
				omit[Boss[bossCount]] = true;
				Boss[MAXBOSSES+bossCount] = Utils_GetClientWithoutBlacklist(omit, BossTeam);
				omit[Boss[MAXBOSSES+bossCount]] = true;
				BossSwitched[MAXBOSSES+bossCount] = true;
			}
		}
		CheatsUsed = true;
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
			if(Utils_IsValidClient(Boss[boss]))
				Utils_AssignTeam(Boss[boss], BossSwitched[boss] ? OtherTeam : BossTeam);
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && !Utils_IsBoss(client) && (GetClientTeam(client)!=OtherTeam && !Enabled3))
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
			if(!Utils_IsValidClient(client))
				continue;

			ClientQueue[client][0] = client;
			ClientQueue[client][1] = QueuePoints[client];
		}

		SortCustom2D(ClientQueue, sizeof(ClientQueue), Utils_SortQueueDesc);

		for(int client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsValidClient(client) || Utils_IsBoss(client))
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
		if(Utils_IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			isBossAlive = true;
			SetEntityMoveType(Boss[boss], MOVETYPE_NONE);
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

	playing = 0;
	playing2 = 0;
	playingboss = 0;
	playingmerc = 0;
	bosses = 0;
	int medigun, boss;
	static char command[512];
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client))
		{
			CreateTimer(2.0, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			if(!Utils_IsBoss(client) && IsPlayerAlive(client))
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
			else if(Utils_IsBoss(client))
			{
				bosses++;
				boss = Utils_GetBossIndex(client);
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
			if(Utils_IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
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
			if(Utils_IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
			{
				BossHealthMax[boss] = ParseFormula(boss, "health_formula", HealthFormula, RoundFloat(Pow((760.8+players)*(players-1.0), 1.0341)+2046.0));
				BossHealth[boss] = BossHealthMax[boss]*BossLivesMax[boss];
				BossHealthLast[boss] = BossHealth[boss];
			}
		}
	}

	if(bosses==1 && kvDiffMods!=null && Utils_IsValidClient(Boss[0]) && IsPlayerAlive(Boss[0]))
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
		Utils_SetControlPoint(false);

	if(cvarNameChange.IntValue == 1)
	{
		char newName[256];
		static char bossName[64];
		Utils_GetBossSpecial(Special[0], bossName, 64);
		FormatEx(newName, 256, "%s | %s", oldName, bossName);
		hostName.SetString(newName);
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
		File bossLog;
		static char bossName[64], FormatedTime[64], Result[64], PlayerName[64], Authid[64];
		int CurrentTime = GetTime();
		int boss;

		FormatTime(FormatedTime, sizeof(FormatedTime), "%X", CurrentTime);
		strcopy(Result, sizeof(Result), team==BossTeam ? "won" : "loss");
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
					GetClientName(Boss[boss], PlayerName, sizeof(PlayerName));
					GetClientAuthId(Boss[boss], AuthId_Steam2, Authid, sizeof(Authid), false);
				}
				KvRewind(BossKV[Special[boss]]);
				KvGetString(BossKV[Special[boss]], "filename", bossName, sizeof(bossName));
				BuildPath(Path_SM, bLog, sizeof(bLog), "%s/%s.txt", BossLogPath, bossName);
				
				bossLog = OpenFile(bLog, "a+");
				if(bossLog != INVALID_HANDLE)
				{
					bossLog.WriteLine("%s on %s - %s <%s> has %s", FormatedTime, currentmap, PlayerName, Authid, Result);
					bossLog.WriteLine("");
					delete bossLog;
				}
			}
		}
	}

	FF2Executed = false;
	FF2Executed2 = false;
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
			if(Utils_IsValidClient(target))
			{
				if(GetClientTeam(target) == team)
				{
					char lives[8];
					if(BossLives[boss] > 1)
						FormatEx(lives, sizeof(lives), "x%i", BossLives[boss]);

					for(int client=1; client<=MaxClients; client++)
					{
						if(Utils_IsValidClient(client))
						{
							Utils_GetBossSpecial(Special[boss], bossName, sizeof(bossName), client);
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
			if(Utils_IsValidClient(client) && !HudSettings[client][2] && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(GetClientButtons(client) & IN_SCORE))
				ShowHudText(client, -1, text[client]);
		}
	}

	StopMusic();
	DrawGameTimer = INVALID_HANDLE;

	bool isBossAlive;
	for(int client; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(Boss[client]))
		{
			Utils_SetClientGlow(Boss[client], 0.0, 0.0);
			SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);  //Temporary:  Used to prevent boss overheal
			if(IsPlayerAlive(Boss[client]))
				isBossAlive = true;

			for(int slot=1; slot<4; slot++)
			{
				BossCharge[client][slot] = 0.0;
			}
			DataBase_SaveClientStats(client);
		}
		else if(Utils_IsValidClient(client))
		{
			Utils_SetClientGlow(client, 0.0, 0.0);
			hadshield[client] = false;
			shield[client] = 0;
			detonations[client] = 0;
			AirstrikeDamage[client] = 0.0;
			KillstreakDamage[client] = 0.0;
			HazardDamage[client] = 0.0;
			SapperCooldown[client] = cvarSapperStart.FloatValue;
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
	int statPlayers = cvarStatPlayers.IntValue;
	if(!botBoss && statPlayers<=playing2 && statPlayers>0)
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

	int StatWin2Lose = cvarStatWin2Lose.IntValue;
	if(StatWin2Lose==2 || StatWin2Lose>3)
	{
		for(int boss=1; boss<=MaxClients; boss++)
		{
			if(Utils_IsBoss(boss) && !IsFakeClient(boss))
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
						if(Utils_IsValidClient(client) && CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true))
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
			if(Utils_IsBoss(boss) && !IsFakeClient(boss))
			{
				if(StatWin2Lose>0 && (gainedPoint[boss] || StatWin2Lose>2))
				{
					FPrintToChat(boss, "%t", "Win To Lose Self", BossWins[boss], BossLosses[boss]);
				}
				for(int client=1; client<=MaxClients; client++)
				{
					if(CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && Utils_IsValidClient(client) && (client!=boss || !(StatWin2Lose>0 && (gainedPoint[boss] || StatWin2Lose>3))))
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
			if(Utils_IsValidClient(target))
			{
				char lives[8];
				if(BossLives[boss] > 1)
					FormatEx(lives, sizeof(lives), "x%i", BossLives[boss]);

				for(int client=1; client<=MaxClients; client++)
				{
					if(Utils_IsValidClient(client))
					{
						Utils_GetBossSpecial(Special[boss], bossName, sizeof(bossName), client);
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
			if(Utils_IsValidClient(client) && !HudSettings[client][2] && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(GetClientButtons(client) & IN_SCORE))
				ShowHudText(client, -1, text[client]);
		}

		if(!bossWin && RandomSound("sound_fail", sound, sizeof(sound)))
			EmitSoundToAllExcept(sound);
	}

	int top[3];
	Damage[0] = 0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!Utils_IsValidClient(client) || Damage[client]<1 || Utils_IsBoss(client))
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
			DataBase_AddClientStats(top[0], Cookie_PlayerMvps, 1);

		if(statPlayers*2 <= playing2)
			DataBase_AddClientStats(top[1], Cookie_PlayerMvps, 1);

		if(statPlayers*3 <= playing2)
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
		if(!Utils_IsValidClient(client) || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
			continue;

		SetGlobalTransTarget(client);
		if(Utils_IsBoss(client) && GetClientTeam(client)==team)
		{
			ShowSyncHudText(client, infoHUD, "%s\n%t:\n1) %i-%s\n2) %i-%s\n3) %i-%s\n\n%t", text, "top_3", Damage[top[0]], leaders[0], Damage[top[1]], leaders[1], Damage[top[2]], leaders[2], "boss_win");
		}
		else if(Utils_IsBoss(client))
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
		Utils_CheckToChangeMapDoors();
		Utils_CheckToTeleportToSpawn();
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


// Control Point Events
public void OnStartCapture(Event event, const char[] name, bool dontBroadcast)
{
	isCapping = true;
}

public void OnBreakCapture(Event event, const char[] name, bool dontBroadcast)
{
	if(!event.GetFloat("time_remaining"))
		isCapping = false;
}


// Player Events
public Action OnPostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
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
		HasEquipped[boss] = false;
		CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
	}

	if(!(FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
	{
		if(!(FF2flags[client] & FF2FLAG_HASONGIVED))
		{
			FF2flags[client] |= FF2FLAG_HASONGIVED;
			Utils_RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
			Utils_RemovePlayerTarge(client);
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

public Action OnPlayerHealed(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || Utils_CheckRoundState()!=1)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("patient"));
	int healer = GetClientOfUserId(event.GetInt("healer"));
	int heals = event.GetInt("amount");

	if(Utils_IsBoss(client))
	{
		int boss = Utils_GetBossIndex(client);
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

public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return Plugin_Continue;

	if(Utils_CheckRoundState() == 1)
		CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!Utils_IsValidClient(client))
		return Plugin_Continue;

	LastAliveClass[client] = TF2_GetPlayerClass(client);
	for(int i; i<3; i++)
	{
		CritBoosted[client][i] = -1;
	}
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
		if(Utils_CheckRoundState() == 1)
		{
			reds = MercAlivePlayers;
			blus = BossAlivePlayers;
		}
		else
		{
			for(int target=1; target<=MaxClients; target++)
			{
				if(!Utils_IsValidClient(target))
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

	if(Utils_CheckRoundState() != 1)
		return Plugin_Continue;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	static char sound[PLATFORM_MAX_PATH];
	CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
	Utils_DoOverlay(client, "");

	if(!Utils_IsBoss(client))
	{
		if(!(flags & TF_DEATHFLAG_DEADRINGER) && (Enabled3 || GetClientTeam(client)!=BossTeam))
			CreateTimer(1.0, Timer_Damage, userid, TIMER_FLAG_NO_MAPCHANGE);

		if(Utils_IsBoss(attacker))
		{
			int boss = Utils_GetBossIndex(attacker);
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

public Action OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || Utils_CheckRoundState()!=1)
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("damageamount");
	int weapon = event.GetInt("weaponid");

	if(Utils_IsValidClient(attacker) && GetClientTeam(attacker)!=GetClientTeam(client) && damage && shield[client])
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
					Utils_RemoveShield(client, attacker);
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
				Utils_RemoveShield(client, attacker);
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

			int bossLives = BossLives[boss];
			Action action = Forwards_Call_OnLoseLife(boss, bossLives, BossLivesMax[boss]);
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
				if(!Utils_IsValidClient(target) || HudSettings[target][2] || (FF2flags[target] & FF2FLAG_HUDDISABLED) || (!IsPlayerAlive(target) && !IsClientObserver(target)))
					continue;
	
				if(cvarGameText.IntValue > 0)
				{
					Utils_GetBossSpecial(Special[boss], bossName, sizeof(bossName), target);
					Utils_ShowGameText(target, "ico_notify_flag_moving_alt", Enabled3 ? GetClientTeam(client) : 0, "%t", ability, bossName, BossLives[boss]);
				}
				else
				{
					Utils_GetBossSpecial(Special[boss], bossName, sizeof(bossName), target);
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

	if(Utils_IsValidClient(attacker) && Utils_IsValidClient(client) && client!=attacker && damage>0 && !Utils_IsBoss(attacker))
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

public void OnUberDeployed(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!Utils_IsValidClient(client) || !IsPlayerAlive(client) || (FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED) || Utils_GetBossIndex(client)>=0)
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
		uberTarget[client] = target;
	}
	else
	{
		uberTarget[client] = -1;
	}
	CreateTimer(0.4, Timer_Uber, EntIndexToEntRef(medigun), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnObjectDeflected(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled || event.GetInt("weaponid"))  // 0 means that the client was airblasted, which is what we want
		return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("ownerid"));
	int boss = Utils_GetBossIndex(client);
	if(boss!=-1 && BossCharge[boss][0]<rageMax[client])
	{
		BossCharge[boss][0] += rageMax[client]*7.0/rageMin[client];  //TODO: Allow this to be customizable
		if(BossCharge[boss][0] > rageMax[client])
			BossCharge[boss][0] = rageMax[client];
	}
	return Plugin_Continue;
}

public void OnDeployBackup(Event event, const char[] name, bool dontBroadcast)
{
	if(Enabled && event.GetInt("buff_type")==2)
		FF2flags[GetClientOfUserId(event.GetInt("buff_owner"))] |= FF2FLAG_ISBUFFED;
}

public void OnRPS(Event event, const char[] name, bool dontBroadcast)
{
	int winner = event.GetInt("winner");
	if(!Utils_IsValidClient(winner))
		return;

	int loser = event.GetInt("loser");
	if(!Utils_IsValidClient(loser))
		return;

	if(!Utils_IsBoss(winner) && Utils_IsBoss(loser) && cvarRPSLimit.IntValue>0)	// Boss Loses on RPS?
	{
		RPSWinner = winner;
		TF2_AddCondition(RPSWinner, TFCond_NoHealingDamageBuff, 3.4);	// I'm not bothered checking for mini-crit boost or not during damage
		CreateTimer(3.1, Timer_RPS, GetClientUserId(loser), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	int points = cvarRPSPoints.IntValue;	// Teammate or Minion loses?
	if(ToggleBoss[winner]==Setting_Off || ToggleBoss[loser]==Setting_Off || Utils_IsBoss(winner) || Utils_IsBoss(loser) || QueuePoints[winner]<points || QueuePoints[loser]<points || points<1)
		return;

	FPrintToChat(winner, "%t", "rps_won", points, loser);
	QueuePoints[winner] += points;

	FPrintToChat(loser, "%t", "rps_lost", points, winner);
	QueuePoints[loser] -= points;
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

public Action OnObjectDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	if(!Enabled)
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
	return Enabled ? Plugin_Handled : Plugin_Continue;
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

	BossCharge[boss][0] -= rageMax[victim]*8.0/rageMin[victim];	//TODO: Allow this to be customizable
	if(BossCharge[boss][0] < 0.0)
		BossCharge[boss][0] = 0.0;

	return Plugin_Continue;
}
