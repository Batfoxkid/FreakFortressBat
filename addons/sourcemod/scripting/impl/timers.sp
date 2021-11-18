Action Timer_Announce(Handle timer)
{
	static int announcecount = -1;
	announcecount++;
	if(FF2GlobalsCvars.Announce>1.0 && FF2Globals.Enabled2)
	{
		if(ConVars.AnnounceAds.BoolValue)
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
					if(ConVars.ToggleBoss.BoolValue)	// Toggle Command?
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
					if(ConVars.ToggleBoss.BoolValue)	// Companion Toggle?
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
					if(ConVars.ToggleBoss.BoolValue)	// Toggle Command?
						FPrintToChatAll("%t", "FF2 Toggle Command");
				}
				case 2:
				{
					if(ConVars.ToggleBoss.BoolValue)	// Companion Toggle?
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


Action Timer_EnableCap(Handle timer)
{
	if((FF2Globals.Enabled || FF2Globals.Enabled2) && Utils_CheckRoundState()==-1)
	{
		Utils_SetControlPoint(true);
		if(FF2Globals.CheckDoors)
		{
			int ent = -1;
			while((ent=Utils_FindEntityByClassname2(ent, "func_door")) != -1)
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

Action Timer_CheckDoors(Handle timer)
{
	if(!FF2Globals.CheckDoors)
	{
		doorCheckTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if((!FF2Globals.Enabled && Utils_CheckRoundState()!=-1) || (FF2Globals.Enabled && Utils_CheckRoundState()!=1))
		return Plugin_Continue;

	int entity = -1;
	while((entity=Utils_FindEntityByClassname2(entity, "func_door")) != -1)
	{
		AcceptEntityInput(entity, "Open");
		AcceptEntityInput(entity, "Unlock");
	}
	return Plugin_Continue;
}



Action Timer_NineThousand(Handle timer)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client) && FF2PlayerCookie[client].VoiceOn)
			ClientCommand(client, "playgamesound \"saxton_hale/9000.wav\"");
	}
	return Plugin_Continue;
}

Action Timer_CalcQueuePoints(Handle timer)
{
	int damage, damage2;
	int[] add_points = new int[MaxClients+1];
	int[] add_points2 = new int[MaxClients+1];
	for(int client=1; client<=MaxClients; client++)
	{
		if(view_as<int>(FF2PlayerCookie[client].Boss)>1 && ConVars.ToggleBoss.BoolValue)	// Do not give queue points to those who have ff2 FF2Globals.Bosses disabled
			continue;

		if(Utils_IsValidClient(client))
		{
			damage = Damage[client];
			damage2 = Damage[client];
			Event event = CreateEvent("player_escort_score", true);
			event.SetInt("player", client);

			int points;
			while(damage-FF2GlobalsCvars.PointsInterval > 0)
			{
				damage -= FF2GlobalsCvars.PointsInterval;
				points++;
			}
			event.SetInt("points", points);
			event.Fire();

			if(Utils_IsBoss(client))
			{
				if(((!Utils_GetBossIndex(client) || Utils_GetBossIndex(client)==MAXBOSSES) && ConVars.DuoRestore.BoolValue) || !ConVars.DuoRestore.BoolValue)
				{
					add_points[client] = -FF2PlayerCookie[client].QueuePoints;
					add_points2[client] = add_points[client];
				}
			}
			else if(GetClientTeam(client)>view_as<int>(TFTeam_Spectator) || FF2GlobalsCvars.SpecForceBoss)
			{
				if(damage2 >= FF2GlobalsCvars.PointsDmg)
				{
					if(FF2GlobalsCvars.PointsExtra > FF2GlobalsCvars.PointsMin)
					{
						if(points > (FF2GlobalsCvars.PointsExtra-FF2GlobalsCvars.PointsMin))
						{
							add_points[client] = FF2GlobalsCvars.PointsExtra;
							add_points2[client] = FF2GlobalsCvars.PointsExtra;
						}
						else
						{
							add_points[client] = FF2GlobalsCvars.PointsMin+points;
							add_points2[client] = FF2GlobalsCvars.PointsMin+points;
						}
					}
					else
					{
						add_points[client] = FF2GlobalsCvars.PointsMin;
						add_points2[client] = FF2GlobalsCvars.PointsMin;
					}
				}
			}
		}
	}

	Action action = Forwards_Call_OnAddQueuePoints(add_points2);
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
				if(!Utils_IsValidClient(client))
					continue;

				if(IsFakeClient(client))
					add_points2[client] /= 2;

				if(add_points2[client] > 0)
					FPrintToChat(client, "%t", "add_points", add_points2[client]);

				FF2PlayerCookie[client].QueuePoints += add_points2[client];
			}
		}
		default:
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(!Utils_IsValidClient(client))
					continue;

				if(IsFakeClient(client))
					add_points[client] /= 2;

				if(add_points[client] > 0)
					FPrintToChat(client, "%t", "add_points", add_points[client]);

				FF2PlayerCookie[client].QueuePoints += add_points[client];
			}
		}
	}
}


Action StartResponseTimer(Handle timer)
{
	static char sound[PLATFORM_MAX_PATH];
	if(FF2Globals.Enabled3)
	{
		static char sound2[PLATFORM_MAX_PATH];
		bool isIntro = RandomSound("sound_begin", sound, sizeof(sound));
		bool isIntro2 = RandomSound("sound_begin", sound2, sizeof(sound2), MAXBOSSES);
		for(int client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsValidClient(client) || !FF2PlayerCookie[client].VoiceOn)
				continue;

			if(GetClientTeam(client)==FF2Globals.BossTeam && isIntro2)
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

Action StartIntroMusicTimer(Handle timer)
{
	static char sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_intromusic", sound, sizeof(sound)))
		EmitMusicToAllExcept(sound);

	return Plugin_Continue;
}


Action Timer_SetEnabled3(Handle timer, bool toggle)
{
	FF2Globals.Enabled3 = toggle;
	if(FF2Globals.Enabled3)
	{
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);

		int reds, blus;
		for(int client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsValidClient(client))
				continue;

			if(GetClientTeam(client) == FF2Globals.OtherTeam)
			{
				reds++;
			}
			else if(GetClientTeam(client) == FF2Globals.BossTeam)
			{
				blus++;
			}
		}

		int team;
		for(int client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsValidClient(client))
				continue;

			if(IsPlayerAlive(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator))
				continue;

			if(reds>blus || (reds==blus && GetRandomInt(0, 1))) // More reds or their equal with 50/50 chance
			{
				team = FF2Globals.BossTeam;
				reds--;
				blus++;
			}
			else
			{
				team = FF2Globals.OtherTeam;
				reds++;
				blus--;
			}

			ChangeClientTeam(client, team);
		}
	}
	else
	{
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), FF2GlobalsCvars.mp_teams_unbalance_limit);
	}
	return Plugin_Continue;
}

Action BossMenuTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(Utils_IsValidClient(client) && FF2PlayerCookie[client].Boss!=Setting_On && FF2PlayerCookie[client].Boss!=Setting_Off)
		BossMenu(client, 0);

	return Plugin_Continue;
}


Action Timer_RegenPlayer(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(Utils_IsValidClient(client) && IsPlayerAlive(client))
		TF2_RegeneratePlayer(client);
}

Action ClientTimer(Handle timer)
{
	if(!FF2Globals.Enabled)
		return Plugin_Stop;

	int client = 1;
	#if defined _tf2attributes_included
	if(FF2Globals.TF2Attrib && ConVars.Disguise.BoolValue)
	{
		int iDisguisedTarget;
		for(; client<=MaxClients; client++)
		{
			//custom model disguise code sorta taken from stop that tank, let's see how well this goes!
			//this will actually let spies disguise as the boss, and FF2Globals.Bosses should have the same disguise
			//model as the players they potentially disguise as if they have a custom model (FF2Globals.TF2Attrib required)
			if(Utils_IsValidClient(client))
			{
				iDisguisedTarget = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
				Utils_VisionFlags_Update(client);

				if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && Utils_IsValidClient(iDisguisedTarget) && TF2_GetPlayerClass(iDisguisedTarget)==view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass")))
				{
					Utils_ModelOverrides_Think(client, iDisguisedTarget);
				}
				else
				{
					Utils_ModelOverrides_Clear(client);
				}
			}
		}
	}
	#endif

	if(Utils_CheckRoundState()==2 || Utils_CheckRoundState()==-1)
		return Plugin_Stop;

	int observer, index;
	int best[10];
	int SapperAmount;
	bool SapperEnabled = SapperMinion;
	for(client=1; client<=MaxClients; client++)
	{
		if(!Utils_IsValidClient(client))
			continue;

		if(Utils_IsBoss(client))
		{
			if(!SapperEnabled)
				SapperEnabled = SapperBoss[client];

			continue;
		}

		if(FF2Globals.Enabled3 || Damage[client]<1)
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
	if(!FF2Globals.Enabled3)
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
	int StatHud = ConVars.StatHud.IntValue;
	int HealHud = ConVars.HealingHud.IntValue;
	float LookHud = ConVars.LookHud.FloatValue;
	for(client=1; client<=MaxClients; client++)
	{
		if(!Utils_IsValidClient(client) || Utils_IsBoss(client) || (FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED))
			continue;

		alive = IsPlayerAlive(client);
		if(!FF2Globals.Enabled3 && alive && TimerMode && GetClientTeam(client)==FF2Globals.BossTeam)
			continue;

		SetGlobalTransTarget(client);
		buttons = GetClientButtons(client);
		if((alive || IsClientObserver(client)) && !FF2PlayerCookie[client].HudSettings[0] && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE))
		{
			SetHudTextParams(-1.0, 0.88, 0.35, 90, 255, 90, 255, 0, 0.35, 0.0, 0.1);
			if(alive && LookHud!=0)
			{
				observer = GetClientAimTarget(client, true);
				if(!Utils_IsValidClient(observer) || observer==client)
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
				if(!Utils_IsValidClient(observer) || observer==client)
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
						FormatEx(top, sizeof(top), "%t", "Self Stats Healing", Damage[client], Healing[client], FF2PlayerCookie[client].PlayerKills, FF2PlayerCookie[client].PlayerMVPs);
					}
					else
					{
						FormatEx(top, sizeof(top), "%t", "Self Stats", Damage[client], FF2PlayerCookie[client].PlayerKills, FF2PlayerCookie[client].PlayerMVPs);
					}
				}
				else
				{
					if((Healing[client]>0 && HealHud==1) || HealHud>1)
					{
						FormatEx(top, sizeof(top), "%t", "Stats Healing", Damage[client], Healing[client], FF2PlayerCookie[client].PlayerKills, FF2PlayerCookie[client].PlayerMVPs);
					}
					else
					{
						FormatEx(top, sizeof(top), "%t", "Stats", Damage[client], FF2PlayerCookie[client].PlayerKills, FF2PlayerCookie[client].PlayerMVPs);
					}
				}
			}
			else
			{
				if(Utils_IsValidClient(observer) && !Utils_IsBoss(observer))
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

			if(Utils_IsValidClient(observer))
			{
				if(StatHud>-1 && (CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>1))
				{
					if(Utils_IsBoss(observer))
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%s%t", top, "Player Stats Boss", classname, FF2PlayerCookie[observer].BossWins, FF2PlayerCookie[observer].BossLosses, FF2PlayerCookie[observer].BossKills, FF2PlayerCookie[observer].BossDeaths);
					}
					else if((Healing[observer]>0 && HealHud==1) || HealHud>1)
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%s%t", top, "Player Stats Healing", classname, Damage[observer], Healing[observer], FF2PlayerCookie[observer].PlayerKills, FF2PlayerCookie[observer].PlayerMVPs);
					}
					else
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%s%t", top, "Player Stats", classname, Damage[observer], FF2PlayerCookie[observer].PlayerKills, FF2PlayerCookie[observer].PlayerMVPs);
					}
				}
				else if(!Utils_IsBoss(observer))
				{
					if((Healing[observer]>0 && HealHud==1) || HealHud>1)
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%s%t", top, "Spectator Damage Dealt", classname, Damage[observer], "Healing", Healing[observer]);
					}
					else
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%s%t", top, "Spectator Damage Dealt", classname, Damage[observer]);
					}
				}
				else
				{
					ShowSyncHudText(client, FF2Huds.PlayerStat, top);
				}
			}
			else
			{
				ShowSyncHudText(client, FF2Huds.PlayerStat, top);
			}
		}

		if((ShowHealthText || FF2PlayerCookie[client].HudSettings[2]) && !FF2Globals.Enabled3 && FF2PlayerCookie[client].HudSettings[HUDTYPES-1]!=1 && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE))
		{
			index = FF2PlayerCookie[client].HudSettings[HUDTYPES-1];
			if(index < 1)
				index = ConVars.DamageHud.IntValue;

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

				ShowSyncHudText(client, FF2Huds.PlayerInfo, top);
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
		else if(FF2PlayerCookie[client].HudSettings[1] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (buttons & IN_SCORE))
		{
		}
		else if(class==TFClass_Spy && SapperEnabled && SapperCooldown[client]>0.0)
		{
			SapperAmount = RoundToFloor((SapperCooldown[client]-ConVars.SapperCooldown.FloatValue)*(Pow(ConVars.SapperCooldown.FloatValue, -1.0)*-100.0));
			if(SapperAmount < 0)
				SapperAmount = 0;

			SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0);
			ShowSyncHudText(client, FF2Huds.Jump, "%t", "Sapper Cooldown", SapperAmount);
		}
		else if(shield[client] && (ConVars.ShieldType.IntValue==3 || ConVars.ShieldType.IntValue==4))
		{
			SetHudTextParams(-1.0, 0.83, 0.15, 255, 255, 255, 255, 0);
			ShowSyncHudText(client, FF2Huds.Jump, "%t", "Shield HP", RoundToFloor(shieldHP[client]/ConVars.ShieldHealth.FloatValue*100.0));
		}
		else if(ConVars.DeadRingerHud.BoolValue && Utils_GetClientCloakIndex(client)==59)
		{
			if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				SetHudTextParams(-1.0, 0.83, 0.35, 255, 64, 64, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, FF2Huds.Jump, "%t", "Dead Ringer Active");
			}
			else if(GetEntProp(client, Prop_Send, "m_bFeignDeathReady"))
			{
				SetHudTextParams(-1.0, 0.83, 0.35, 90, 255, 90, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, FF2Huds.Jump, "%t", "Dead Ringer Ready");
			}
			else
			{
				SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(client, FF2Huds.Jump, "%t", "Dead Ringer Inactive");
			}
		}

		int aliveTeammates = FF2Globals.Enabled3 ? FF2Globals.AliveBossPlayers+FF2Globals.AliveMercPlayers-1 : FF2Globals.AliveMercPlayers;

		if(FF2GlobalsCvars.LastPlayerGlow > 0)
		{
			if(FF2GlobalsCvars.LastPlayerGlow < 1)
			{
				if(float(aliveTeammates)/FF2Globals.TotalPlayers <= FF2GlobalsCvars.LastPlayerGlow)
					Utils_SetClientGlow(client, 0.5, 3.0);
			}
			else if(aliveTeammates <= FF2GlobalsCvars.LastPlayerGlow)
			{
				Utils_SetClientGlow(client, 0.5, 3.0);
			}
		}

		aliveTeammates = FF2Globals.Enabled3 ? GetClientTeam(client)==FF2Globals.OtherTeam ? FF2Globals.AliveMercPlayers : FF2Globals.AliveBossPlayers : FF2Globals.AliveMercPlayers;

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

		Utils_SetClientGlow(client, -0.2);

		if(FF2Globals.Enabled3 || FF2Globals.IsMedival)
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
			if(Utils_IsValidClient(healtarget) && IsPlayerAlive(healtarget) && Utils_GetHealingTarget(healtarget, true)==client)
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
					if(index==416 && ConVars.Market.FloatValue)  //Market Gardener
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
						if(index!=16 || !IsValidEntity(Utils_FindPlayerBack(client, 642)) || FF2GlobalsCvars.SniperClimpDelay<=0)	//Nerf Cozy Camper SMGs if Wall Climb is on
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
						if(FF2GlobalsCvars.BowDmgNon <= 0)	//If non-crit boosted damage cvar is off
						{
							addthecrit = true;
							if(cond==TFCond_HalloweenCritCandy && FF2GlobalsCvars.BowDmgMini>0)	//If mini-crit boosted damage cvar is on
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
							if(!FF2PlayerCookie[client].HudSettings[1] && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE))
							{
								SetHudTextParams(-1.0, 0.83, 0.35, 255, 255, 255, 255, 0, 0.2, 0.0, 0.1);
								ShowSyncHudText(client, FF2Huds.Jump, "%t", "uber-charge", charge);
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
				   FF2GlobalsCvars.ShieldCrits)  //Demoshields
				{
					addthecrit = true;
					if(FF2GlobalsCvars.ShieldCrits == 1)
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
					int sentry = Utils_FindSentry(client);
					if(IsValidEntity(sentry) && Utils_IsBoss(GetEntPropEnt(sentry, Prop_Send, "m_hEnemy")))
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

Action Timer_MakeBoss(Handle timer, any boss)
{
	int client = Boss[boss];
	if(!Utils_IsValidClient(client) || Utils_CheckRoundState()==-1)
		return Plugin_Continue;

	if(!IsPlayerAlive(client))
	{
		if(!Utils_CheckRoundState())
		{
			TF2_RespawnPlayer(client);
		}
		else
		{
			return Plugin_Continue;
		}
	}

	KvRewind(BossKV[Special[boss]]);
	int ForcedTeam = BossSwitched[boss] ? FF2Globals.OtherTeam : FF2Globals.BossTeam;
	if(GetClientTeam(client) != ForcedTeam)
		Utils_AssignTeam(client, ForcedTeam);

	BossRageDamage[boss] = ParseFormula(boss, "ragedamage", FF2GlobalsCvars.RageDamage, 1900);
	if(BossRageDamage[boss] < 1)	// 0 or below, disable RAGE
		BossRageDamage[boss] = 99999;

	BossLivesMax[boss] = KvGetNum(BossKV[Special[boss]], "lives", 1);
	if(BossLivesMax[boss] < 1)
	{
		char bossName[64];
		KvGetString(BossKV[Special[boss]], "filename", bossName, sizeof(bossName));
		LogToFile(FF2LogsPaths.Errors, "[Boss] Warning: Boss %s has an invalid amount of lives, setting to 1", bossName);
		BossLivesMax[boss] = 1;
	}
	BossHealthMax[boss] = ParseFormula(boss, "health_formula", FF2GlobalsCvars.HealthFormula, RoundFloat(Pow((760.8+float(FF2Globals.TotalPlayers))*(float(FF2Globals.TotalPlayers)-1.0), 1.0341)+2046.0));
	BossLives[boss] = BossLivesMax[boss];
	BossHealth[boss] = BossHealthMax[boss]*BossLivesMax[boss];
	BossHealthLast[boss] = BossHealth[boss];

	if(KvGetNum(BossKV[Special[boss]], "triple", -1) >= 0)
	{
		dmgTriple[client] = view_as<bool>(KvGetNum(BossKV[Special[boss]], "triple", -1));
	}
	else
	{
		dmgTriple[client] = ConVars.TripleWep.BoolValue;
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
		SelfKnockback[client] = ConVars.SelfKnockback.IntValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "crits", -1) >= 0)
	{
		randomCrits[client] = view_as<bool>(KvGetNum(BossKV[Special[boss]], "crits", -1));
	}
	else
	{
		randomCrits[client] = ConVars.Crits.BoolValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "healing", -1) >= 0)
	{
		SelfHealing[client] = KvGetNum(BossKV[Special[boss]], "healing", -1);
	}
	else
	{
		SelfHealing[client] = ConVars.SelfHealing.IntValue;
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
		FF2GlobalsCvars.PointType = KvGetNum(BossKV[Special[boss]], "pointtype", -1);
	}
	else
	{
		FF2GlobalsCvars.PointType = ConVars.PointType.IntValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "pointdelay", -9999) != -9999)	// Can be below 0 so...
	{
		FF2GlobalsCvars.PointDelay = KvGetNum(BossKV[Special[boss]], "pointdelay", -9999);
	}
	else
	{
		FF2GlobalsCvars.PointDelay = ConVars.PointDelay.IntValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "pointtime", -9999) != -9999)	// Same here, in-case of some weird boss logic
	{
		FF2GlobalsCvars.PointTime = KvGetNum(BossKV[Special[boss]], "pointtime", -9999);
	}
	else
	{
		FF2GlobalsCvars.PointTime = ConVars.PointTime.IntValue;
	}

	if(KvGetFloat(BossKV[Special[boss]], "pointalive", -1.0) >= 0)	// Can't be below 0, it's players/ratio
	{
		FF2GlobalsCvars.AliveToEnable = KvGetFloat(BossKV[Special[boss]], "pointalive", -1.0);
	}
	else
	{
		FF2GlobalsCvars.AliveToEnable = ConVars.AliveToEnable.FloatValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "countdownhealth", -1) >= 0)	// Also can't be below 0, it's health
	{
		FF2GlobalsCvars.CountdownHealth = KvGetNum(BossKV[Special[boss]], "countdownhealth", -1);
	}
	else
	{
		FF2GlobalsCvars.CountdownHealth = ConVars.CountdownHealth.IntValue;
	}

	if(KvGetFloat(BossKV[Special[boss]], "countdownalive", -1.0) >= 0)	// Yet again, can't be below 0
	{
		FF2GlobalsCvars.CountdownPlayers = KvGetFloat(BossKV[Special[boss]], "countdownalive", -1.0);
	}
	else
	{
		FF2GlobalsCvars.CountdownPlayers = ConVars.CountdownPlayers.FloatValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "countdowntime", -1) >= 0)	// .w.
	{
		FF2GlobalsCvars.CountdownTime = KvGetNum(BossKV[Special[boss]], "countdowntime", -1);
	}
	else
	{
		FF2GlobalsCvars.CountdownTime = ConVars.CountdownTime.IntValue;
	}

	if(KvGetNum(BossKV[Special[boss]], "countdownovertime", -1) >= 0)	// OVERTIME!
	{
		FF2GlobalsCvars.CountdownOvertime = view_as<bool>(KvGetNum(BossKV[Special[boss]], "countdownovertime", -1));
	}
	else
	{
		FF2GlobalsCvars.CountdownOvertime = ConVars.CountdownOvertime.BoolValue;
	}

	if((KvGetNum(BossKV[Special[boss]], "sapper", -1)<0 && (ConVars.Sappers.IntValue==1 || ConVars.Sappers.IntValue>2)) || KvGetNum(BossKV[Special[boss]], "sapper", -1)==1 || KvGetNum(BossKV[Special[boss]], "sapper", -1)>2)
	{
		SapperBoss[client] = true;
	}
	else
	{
		SapperBoss[client] = false;
	}

	if((KvGetNum(BossKV[Special[boss]], "sapper", -1)<0 && ConVars.Sappers.IntValue>1) || KvGetNum(BossKV[Special[boss]], "sapper", -1)>1)
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

	if(!FF2Globals.HasSwitched && !FF2Globals.Enabled3)
	{
		switch(KvGetNum(BossKV[Special[boss]], "bossteam"))
		{
			case 1: // Always Random
				Utils_SwitchTeams((FF2Globals.CurrentBossTeam==1) ? (view_as<int>(TFTeam_Blue)) : (view_as<int>(TFTeam_Red)) , (FF2Globals.CurrentBossTeam==1) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)), true);

			case 2: // RED Boss
				Utils_SwitchTeams(view_as<int>(TFTeam_Red), view_as<int>(TFTeam_Blue), true);

			case 3: // BLU Boss
				Utils_SwitchTeams(view_as<int>(TFTeam_Blue), view_as<int>(TFTeam_Red), true);

			default: // Determined by "ff2_force_team" ConVar
				Utils_SwitchTeams((FF2Globals.IsBossBlue) ? (view_as<int>(TFTeam_Blue)) : (view_as<int>(TFTeam_Red)), (FF2Globals.IsBossBlue) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)), true);
		}
		FF2Globals.HasSwitched = true;
	}

	CreateTimer(0.2, MakeModelTimer, boss, TIMER_FLAG_NO_MAPCHANGE);
	if(!IsVoteInProgress() && FF2PlayerCookie[client].InfoOn)
		HelpPanelBoss(boss);

	if(!IsPlayerAlive(client))
		return Plugin_Continue;

	bool cosmetics = view_as<bool>(KvGetNum(BossKV[Special[boss]], "cosmetics"));
	int entity = -1;
	while((entity=Utils_FindEntityByClassname2(entity, "tf_wear*")) != -1)
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
	while((entity=Utils_FindEntityByClassname2(entity, "tf_powerup_bottle")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client)
			TF2_RemoveWearable(client, entity);
	}

	Utils_EquipBoss(boss);
	KSpreeCount[boss] = 0;
	BossCharge[boss][0] = 0.0;
	RPSHealth[client] = -1;
	RPSLosses[client] = 0;
	RPSHealth[client] = 0;
	RPSLoser[client] = -1.0;
	HazardDamage[client] = 0.0;
	FF2PlayerCookie[client].BossKillsF = FF2PlayerCookie[client].BossKills;
	HealthBarModeC[client] = false;
	if(((!Utils_GetBossIndex(client) || Utils_GetBossIndex(client)==MAXBOSSES) && ConVars.DuoRestore.BoolValue) || !ConVars.DuoRestore.BoolValue)
		FF2PlayerCookie[client].QueuePoints = 0;

	if(AreClientCookiesCached(client))
	{
		static char cookie[64];
		KvGetString(BossKV[Special[boss]], "name", cookie, sizeof(cookie));
		SetClientCookie(client, FF2DataBase.LastPlayer, cookie);
	}
	return Plugin_Continue;
}

Action Timer_MakeNotBoss(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!Utils_IsValidClient(client) || !IsPlayerAlive(client) || Utils_CheckRoundState()==2 || Utils_IsBoss(client) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
		return Plugin_Continue;

	if(!IsVoteInProgress() && FF2PlayerCookie[client].InfoOn && !(FF2flags[client] & FF2FLAG_CLASSHELPED))
		HelpPanelClass(client);

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);  //This really shouldn't be needed but I've been noticing players who still have glow

	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client)); //Temporary: Reset health to avoid an overheal bug
	if(!FF2Globals.Enabled3 && GetClientTeam(client)==FF2Globals.BossTeam)
		Utils_AssignTeam(client, FF2Globals.OtherTeam);

	CreateTimer(0.1, Timer_CheckItems, userid, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

Action Timer_CheckItems(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!Utils_IsValidClient(client) || !IsPlayerAlive(client) || Utils_CheckRoundState()==2 || Utils_IsBoss(client) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
		return Plugin_Continue;

	SetEntityRenderColor(client, 255, 255, 255, 255);
	hadshield[client] = false;
	shield[client] = 0;
	static int civilianCheck[MAXTF2PLAYERS];

	int weapon = GetPlayerWeaponSlot(client, 4);
	if(IsValidEntity(weapon) && GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")==60 && (FF2ModsInfo.WeaponCfg == null || ConVars.HardcodeWep.IntValue>0))  //Cloak and Dagger
	{
		TF2_RemoveWeaponSlot(client, 4);
		FF2_SpawnWeapon(client, "tf_weapon_invis", 60, 1, 0, "35 ; 1.65 ; 728 ; 1 ; 729 ; 0.65");
	}

	for(int i; i<3; i++)
	{
		CritBoosted[client][i] = -1;
	}

	if(FF2Globals.IsMedival)
		return Plugin_Continue;

	int slot, index, wepIdx, wepIndex, weaponIdxcount;
	char format[64];
	static char classname[32], wepIndexStr[768], wepIndexes[768][32];
	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(weapon))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		if(index==402 && (FF2ModsInfo.WeaponCfg==null || ConVars.HardcodeWep.IntValue>0))
		{
			TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
			if(FF2_SpawnWeapon(client, "tf_weapon_sniperrifle", 402, 1, 6, "91 ; 0.5 ; 75 ; 3.75 ; 178 ; 0.8") == -1)
				civilianCheck[client]++;
		}

		GetEntityClassname(weapon, classname, sizeof(classname));
		if(FF2ModsInfo.WeaponCfg!=null && FF2Globals.HasWeaponCfg)
		{
			for(int i=1; ; i++)
			{
				KvRewind(FF2ModsInfo.WeaponCfg);
				FormatEx(format, sizeof(format), "weapon%i", i);
				if(KvJumpToKey(FF2ModsInfo.WeaponCfg, format))
				{
					KvGetString(FF2ModsInfo.WeaponCfg, "classname", format, sizeof(format));
					KvGetString(FF2ModsInfo.WeaponCfg, "index", wepIndexStr, sizeof(wepIndexStr));
					slot = KvGetNum(FF2ModsInfo.WeaponCfg, "slot", -1);
					if(slot<0 || slot>2)
						slot = 0;

					if(StrContains(wepIndexStr, "-2")!=-1 && StrContains(classname, format, false)!=-1 || StrContains(wepIndexStr, "-1")!=-1 && StrEqual(classname, format, false))
					{
						CritBoosted[client][slot] = KvGetNum(FF2ModsInfo.WeaponCfg, "crits", -1);
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

							CritBoosted[client][slot] = KvGetNum(FF2ModsInfo.WeaponCfg, "crits", -1);
							break;
						}
					}
				}
				else
				{
					break;
				}
			}
			KvGoBack(FF2ModsInfo.WeaponCfg);
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
			if(Utils_GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 142)  //Gunslinger (Randomizer, etc. compatability)
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, 75);
			}
		}

		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		GetEntityClassname(weapon, classname, sizeof(classname));
		if(FF2ModsInfo.WeaponCfg!=null && FF2Globals.HasWeaponCfg)
		{
			for(int i=1; ; i++)
			{
				KvRewind(FF2ModsInfo.WeaponCfg);
				FormatEx(format, sizeof(format), "weapon%i", i);
				if(KvJumpToKey(FF2ModsInfo.WeaponCfg, format))
				{
					KvGetString(FF2ModsInfo.WeaponCfg, "classname", format, sizeof(format));
					KvGetString(FF2ModsInfo.WeaponCfg, "index", wepIndexStr, sizeof(wepIndexStr));
					slot = KvGetNum(FF2ModsInfo.WeaponCfg, "slot", -1);
					if(slot<0 || slot>2)
						slot = 1;

					if(StrContains(wepIndexStr, "-2")!=-1 && StrContains(classname, format, false)!=-1 || StrContains(wepIndexStr, "-1")!=-1 && StrEqual(classname, format, false))
					{
						CritBoosted[client][slot] = KvGetNum(FF2ModsInfo.WeaponCfg, "crits", -1);
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

							CritBoosted[client][slot] = KvGetNum(FF2ModsInfo.WeaponCfg, "crits", -1);
							break;
						}
					}
				}
				else
				{
					break;
				}
			}
			KvGoBack(FF2ModsInfo.WeaponCfg);
		}
	}
	else
	{
		civilianCheck[client]++;
	}

	int playerBack = Utils_FindPlayerBack(client, 57);  //Razorback
	shield[client] = IsValidEntity(playerBack) ? playerBack : 0;
	hadshield[client] = IsValidEntity(playerBack) ? true : false;
	if(IsValidEntity(Utils_FindPlayerBack(client, 642)))  //Cozy Camper
		FF2_SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "149 ; 1.5 ; 15 ; 0.0 ; 1 ; 0.75");

	#if defined _tf2attributes_included
	if(FF2Globals.TF2Attrib && (FF2ModsInfo.WeaponCfg == null || ConVars.HardcodeWep.IntValue>0))
	{
		if(IsValidEntity(Utils_FindPlayerBack(client, 444)))  //Mantreads
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
	while((entity=Utils_FindEntityByClassname2(entity, "tf_wearable_demoshield")) != -1)  //Demoshields
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			shield[client] = entity;
			hadshield[client] = true;
		}
	}

	if(IsValidEntity(shield[client]))
	{
		shieldHP[client] = ConVars.ShieldHealth.FloatValue;
		shDmgReduction[client] = 1.0-ConVars.ShieldResist.FloatValue;
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(weapon))
	{
		index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		GetEntityClassname(weapon, classname, sizeof(classname));
		if(FF2ModsInfo.WeaponCfg!=null && FF2Globals.HasWeaponCfg)
		{
			for(int i=1; ; i++)
			{
				KvRewind(FF2ModsInfo.WeaponCfg);
				FormatEx(format, 10, "weapon%i", i);
				if(KvJumpToKey(FF2ModsInfo.WeaponCfg, format))
				{
					KvGetString(FF2ModsInfo.WeaponCfg, "classname", format, sizeof(format));
					KvGetString(FF2ModsInfo.WeaponCfg, "index", wepIndexStr, sizeof(wepIndexStr));
					slot = KvGetNum(FF2ModsInfo.WeaponCfg, "slot", -1);
					if(slot<0 || slot>2)
						slot = 2;

					if(StrContains(wepIndexStr, "-2")!=-1 && StrContains(classname, format, false)!=-1 || StrContains(wepIndexStr, "-1")!=-1 && StrEqual(classname, format, false))
					{
						CritBoosted[client][slot] = KvGetNum(FF2ModsInfo.WeaponCfg, "crits", -1);
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

							CritBoosted[client][slot] = KvGetNum(FF2ModsInfo.WeaponCfg, "crits", -1);
							break;
						}
					}
				}
				else
				{
					break;
				}
			}
			KvGoBack(FF2ModsInfo.WeaponCfg);
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

Action Timer_RPS(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!Utils_IsValidClient(client))
		return Plugin_Continue;

	int boss = Utils_GetBossIndex(client);
	if(boss==-1 || !IsPlayerAlive(client))
		return Plugin_Continue;

	RPSLosses[client]++;

	if(RPSLosses[client] < 0)
		RPSLosses[client] = 0;

	if(RPSHealth[client] == -1)
		RPSHealth[client] = BossHealth[boss];

	if(RPSLosses[client] >= ConVars.RPSLimit.IntValue)
	{
		if(Utils_IsValidClient(FF2Globals.RPSWinner) && BossHealth[boss]>1349)
		{
			SDKHooks_TakeDamage(client, FF2Globals.RPSWinner, FF2Globals.RPSWinner, float(BossHealth[boss]), DMG_GENERIC, -1);
		}
		else // Winner disconnects?
		{
			ForcePlayerSuicide(client);
		}
	}
	else if(BossHealth[boss]>(1349*ConVars.RPSLimit.IntValue) && ConVars.RPSDivide.BoolValue)
	{
		if(Utils_IsValidClient(FF2Globals.RPSWinner))
			SDKHooks_TakeDamage(client, FF2Globals.RPSWinner, FF2Globals.RPSWinner, float((RPSHealth[client]/ConVars.RPSLimit.IntValue)-999)/1.35, DMG_GENERIC, -1);
	}
	return Plugin_Continue;
}


Action Timer_UseBossCharge(Handle timer, DataPack data)
{
	data.Reset();
	BossCharge[data.ReadCell()][data.ReadCell()] = data.ReadFloat();
	return Plugin_Continue;
}


Action Timer_Uber(Handle timer, any medigunid)
{
	int medigun = EntRefToEntIndex(medigunid);
	if(medigun && IsValidEntity(medigun) && Utils_CheckRoundState()==1)
	{
		int client = GetEntPropEnt(medigun, Prop_Send, "m_hOwnerEntity");
		float charge = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
		if(Utils_IsValidClient(client, false) && IsPlayerAlive(client) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")==medigun)
		{
			int target = Utils_GetHealingTarget(client);
			if(charge > 0.05)
			{
				//TF2_AddCondition(client, TFCond_UberchargedCanteen, 0.5);
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, 0.5);
				if(Utils_IsValidClient(target, false) && IsPlayerAlive(target))
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

Action Timer_InfiniteRage(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!Utils_IsBoss(client))
		return Plugin_Stop;

	if(Utils_CheckRoundState()!=1 || !IsPlayerAlive(client))
	{
		InfiniteRageActive[client] = false;
		return Plugin_Stop;
	}

	if(Utils_CheckRoundState() == 1)
		BossCharge[Utils_GetBossIndex(client)][0] = rageMax[client];

	return Plugin_Continue;
}

Action BossTimer(Handle timer)
{
	if(!FF2Globals.Enabled || Utils_CheckRoundState()==2)
		return Plugin_Stop;

	int client, observer, buttons, target, aliveTeammates;
	bool validBoss;
	int StatHud = ConVars.StatHud.IntValue;
	int HealHud = ConVars.HealingHud.IntValue;
	static char sound[PLATFORM_MAX_PATH];
	for(int boss; boss<=MaxClients; boss++)
	{
		client = Boss[boss];
		if(!Utils_IsValidClient(client) || !(FF2flags[client] & FF2FLAG_USEBOSSTIMER))
			continue;

		buttons = GetClientButtons(client);
		if(GetClientTeam(client) != (BossSwitched[boss] ? FF2Globals.OtherTeam : FF2Globals.BossTeam))
		{
			TF2_ChangeClientTeam(client, BossSwitched[boss] ? view_as<TFTeam>(FF2Globals.OtherTeam) : view_as<TFTeam>(FF2Globals.BossTeam));
		}

		if(!IsPlayerAlive(client))
		{
			if(!IsClientObserver(client) || FF2PlayerCookie[client].HudSettings[0] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (buttons & IN_SCORE))
				continue;

			observer = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if(!Utils_IsValidClient(observer) || observer==client)
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
				if(observer && !Utils_IsBoss(observer))
				{
					if((Healing[observer]>0 && HealHud==1) || HealHud>1)
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%t %t", "Spectator Damage Dealt", sound, Damage[observer], "Healing", Healing[observer]);
					}
					else
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%t", "Spectator Damage Dealt", sound, Damage[observer]);
					}
				}
			}
			else if(observer && Utils_IsBoss(observer))
			{
				if(!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<2)
				{
					ShowSyncHudText(client, FF2Huds.PlayerStat, "%t", "Stats Boss", FF2PlayerCookie[client].BossWins, FF2PlayerCookie[client].BossLosses, FF2PlayerCookie[client].BossKillsF, FF2PlayerCookie[client].BossDeaths);
				}
				else
				{
					ShowSyncHudText(client, FF2Huds.PlayerStat, "%t%t", "Self Stats Boss", FF2PlayerCookie[client].BossWins, FF2PlayerCookie[client].BossLosses, FF2PlayerCookie[client].BossKillsF, FF2PlayerCookie[client].BossDeaths, "Player Stats Boss", sound, FF2PlayerCookie[observer].BossWins, FF2PlayerCookie[observer].BossLosses, FF2PlayerCookie[observer].BossKillsF, FF2PlayerCookie[observer].BossDeaths);
				}
			}
			else if(observer)
			{
				if((Healing[observer]>0 && HealHud==1) || HealHud>1)
				{
					if(!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<2)
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%t\n%t %t", "Stats Boss", FF2PlayerCookie[client].BossWins, FF2PlayerCookie[client].BossLosses, FF2PlayerCookie[client].BossKillsF, FF2PlayerCookie[client].BossDeaths, "Spectator Damage Dealt", sound, Damage[observer], "Healing", Healing[observer]);
					}
					else
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%t%t", "Self Stats Boss", FF2PlayerCookie[client].BossWins, FF2PlayerCookie[client].BossLosses, FF2PlayerCookie[client].BossKillsF, FF2PlayerCookie[client].BossDeaths, "Player Stats Healing", sound, Damage[observer], Healing[observer], FF2PlayerCookie[observer].PlayerKills, FF2PlayerCookie[observer].PlayerMVPs);
					}
				}
				else
				{
					if(!CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) && StatHud<2)
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%t\n%t", "Stats Boss", FF2PlayerCookie[client].BossWins, FF2PlayerCookie[client].BossLosses, FF2PlayerCookie[client].BossKillsF, FF2PlayerCookie[client].BossDeaths, "Spectator Damage Dealt", sound, Damage[observer]);
					}
					else
					{
						ShowSyncHudText(client, FF2Huds.PlayerStat, "%t%t", "Self Stats Boss", FF2PlayerCookie[client].BossWins, FF2PlayerCookie[client].BossLosses, FF2PlayerCookie[client].BossKillsF, FF2PlayerCookie[client].BossDeaths, "Player Stats", sound, Damage[observer], FF2PlayerCookie[observer].PlayerKills, FF2PlayerCookie[observer].PlayerMVPs);
					}
				}
			}
			else if(StatHud>-1 && (CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true) || StatHud>0))
			{
				ShowSyncHudText(client, FF2Huds.PlayerStat, "%t", "Stats Boss", FF2PlayerCookie[client].BossWins, FF2PlayerCookie[client].BossLosses, FF2PlayerCookie[client].BossKillsF, FF2PlayerCookie[client].BossDeaths);
			}
			continue;
		}

		if(!FF2PlayerCookie[client].HudSettings[0] && StatHud>-1 && !(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE) && (StatHud>0 || CheckCommandAccess(client, "ff2_stats_bosses", ADMFLAG_BAN, true)))
		{
			SetHudTextParams(-1.0, 0.99, 0.35, 90, 255, 90, 255);
			ShowSyncHudText(client, FF2Huds.PlayerStat, "%t", "Stats Boss", FF2PlayerCookie[client].BossWins, FF2PlayerCookie[client].BossLosses, FF2PlayerCookie[client].BossKillsF, FF2PlayerCookie[client].BossDeaths);
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
			ShowSyncHudText(client, FF2Huds.Lives, "%t", "Boss Lives Left", BossLives[boss], BossLivesMax[boss]);
		}

		if(BossRageDamage[boss] < 2)	// When RAGE is infinite
			BossCharge[boss][0] = 100.0;

		if(BossRageDamage[boss] > 99998)	// When RAGE is disabled
		{
			BossCharge[boss][0] = 0.0;	// We don't want things like Sydney Sleeper acting up
		}
		else if(RoundFloat(BossCharge[boss][0]) == 100.0)
		{
			if(IsFakeClient(client) && !(FF2flags[client] & FF2FLAG_BOTRAGE) && ConVars.BotRage.BoolValue)
			{
				CreateTimer(1.0, Timer_BotRage, boss, TIMER_FLAG_NO_MAPCHANGE);
				FF2flags[client] |= FF2FLAG_BOTRAGE;
			}
			else
			{
				if(!(FF2flags[client] & FF2FLAG_HUDDISABLED) && !(buttons & IN_SCORE))
				{
					SetHudTextParams(-1.0, 0.83, 0.15, 255, 64, 64, 255);
					ShowSyncHudText(client, FF2Huds.Rage, "%t", "do_rage");
				}

				if(RandomSound("sound_full_rage", sound, sizeof(sound), boss) && emitRageSound[boss])
				{
					static float position[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

					FF2flags[client] |= FF2FLAG_TALKING;
					EmitSoundToAllExcept(sound);

					for(target=1; target<=MaxClients; target++)
					{
						if(IsClientInGame(target) && target!=client && FF2PlayerCookie[target].VoiceOn)
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
			ShowSyncHudText(client, FF2Huds.Rage, "%t", "rage_meter", RoundFloat(BossCharge[boss][0]));
		}

		Utils_SetClientGlow(client, -0.2);

		for(target=1; target<4; target++)
		{
			ActivateAbilitySlot(boss, target, true);
		}

		aliveTeammates = FF2Globals.Enabled3 ? FF2Globals.AliveBossPlayers+FF2Globals.AliveMercPlayers-1 : FF2Globals.AliveMercPlayers;

		if(FF2GlobalsCvars.LastPlayerGlow > 0)
		{
			if(FF2GlobalsCvars.LastPlayerGlow < 1)
			{
				if(aliveTeammates/FF2Globals.TotalPlayers <= FF2GlobalsCvars.LastPlayerGlow)
					Utils_SetClientGlow(client, 0.3, 3.0);
			}
			else if(aliveTeammates <= FF2GlobalsCvars.LastPlayerGlow)
			{
				Utils_SetClientGlow(client, 0.3, 3.0);
			}
		}

		if(aliveTeammates<2 && ConVars.HealthHud.IntValue<2 && (FF2Globals.Bosses>1 || FF2Globals.Enabled3 || !ConVars.GameText.IntValue || !FF2Globals.FF2Executed2))
		{
			char message[MAXTF2PLAYERS][512], name[64];
			for(int boss2; boss2<=MaxClients; boss2++)
			{
				if(Utils_IsValidClient(Boss[boss2]))
				{
					char bossLives[8];
					if(BossLives[boss2] > 1)
						FormatEx(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);

					for(int clients; clients<=MaxClients; clients++)
					{
						if(Utils_IsValidClient(clients))
						{
							Utils_GetBossSpecial(Special[boss2], name, sizeof(name), clients);
							Format(message[clients], sizeof(message[]), "%s\n%t", message[clients], "ff2_hp", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives);
						}
					}
				}
			}

			for(target=1; target<=MaxClients; target++)
			{
				if(Utils_IsValidClient(target) && (IsPlayerAlive(client) || IsClientObserver(client)) && !FF2PlayerCookie[client].HudSettings[4] && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					if(FF2Globals.Bosses<2 && ConVars.GameText.IntValue>0)
					{
						if(BossIcon[0])
						{
							Utils_ShowGameText(target, BossIcon, _, message[target]);
						}
						else
						{
							Utils_ShowGameText(target, "leaderboard_streak", _, message[target]);
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
			BossCharge[boss][0] += Utils_OnlyScoutsLeft(GetClientTeam(client))*0.2;
			if(BossCharge[boss][0] > rageMax[client])
				BossCharge[boss][0] = rageMax[client];
		}

		FF2Globals.HPTime -= 0.2;
		if(FF2Globals.HPTime < 0)
			FF2Globals.HPTime = 0.0;

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

Action GlobalTimer(Handle timer)
{
	int HealthHud = ConVars.HealthHud.IntValue;

	if(!FF2Globals.Enabled || Utils_CheckRoundState()==2 || Utils_CheckRoundState()==-1 || HealthHud<1)
		return Plugin_Stop;

	char healthString[64];
	int current, boss;
	int lives = 1;
	if(FF2Globals.Enabled3)
	{
		if(HealthHud > 1)
		{
			for(int clients=1; clients<=MaxClients; clients++)
			{
				if(Utils_IsBoss(clients))
				{
					if(TF2_GetClientTeam(clients) != TFTeam_Blue)
						continue;

					boss = Utils_GetBossIndex(clients);
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
				if(Utils_IsBoss(clients))
				{
					if(TF2_GetClientTeam(clients) != TFTeam_Blue)
						continue;

					boss = Utils_GetBossIndex(clients);
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
				if(Utils_IsBoss(clients))
				{
					if(TF2_GetClientTeam(clients) != TFTeam_Red)
						continue;

					boss = Utils_GetBossIndex(clients);
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
				if(Utils_IsBoss(clients))
				{
					if(TF2_GetClientTeam(clients) != TFTeam_Red)
						continue;

					boss = Utils_GetBossIndex(clients);
					lives += BossLives[boss]-1;
				}
			}

			if(lives > 1)
				FormatEx(healthString2, sizeof(healthString2), "x%i", lives);
		}

		for(int client=1; client<=MaxClients; client++)
		{
			if(Utils_IsValidClient(client))
			{
				if((!IsPlayerAlive(client) && !IsClientObserver(client)) || (!FF2PlayerCookie[client].HudSettings[2] && !ShowHealthText) || FF2PlayerCookie[client].HudSettings[4] || (GetClientButtons(client) & IN_SCORE))
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

				ShowSyncHudText(client, FF2Huds.Health, healthString);

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

				ShowSyncHudText(client, FF2Huds.Rival, healthString2);
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
				if(Utils_IsBoss(clients))
				{
					boss = Utils_GetBossIndex(clients);
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
				if(Utils_IsBoss(clients))
				{
					boss = Utils_GetBossIndex(clients);
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
			if(Utils_IsValidClient(client))
			{
				if((!IsPlayerAlive(client) && !IsClientObserver(client)) || (!FF2PlayerCookie[client].HudSettings[2] && !ShowHealthText) || FF2PlayerCookie[client].HudSettings[4] || (GetClientButtons(client) & IN_SCORE))
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

				ShowSyncHudText(client, FF2Huds.Health, healthString);
			}
		}
	}
	return Plugin_Continue;
}

Action Timer_BotRage(Handle timer, any bot)
{
	if(Utils_IsValidClient(Boss[bot], false))
		FakeClientCommandEx(Boss[bot], "voicemenu 0 0");
}


Action OverTimeAlert(Handle timer)
{
	static int OTCount;
	if(Utils_CheckRoundState() != 1)
	{
		OTCount = 0;
		return Plugin_Stop;
	}

	if(!FF2Globals.IsCapping)
	{
		Utils_EndBossRound();
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

Action Timer_Damage(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(Utils_IsValidClient(client, false))
		FPrintToChat(client, "{olive}%t. %t{default}", "damage", Damage[client], "scores", RoundToFloor(Damage[client]/FF2GlobalsCvars.PointsInterval2));

	return Plugin_Continue;
}


Action Timer_CheckAlivePlayers(Handle timer)
{
	if(Utils_CheckRoundState() == 2)
		return Plugin_Continue;

	FF2Globals.AliveMercPlayers = 0;
	FF2Globals.AliveBossPlayers = 0;
	FF2Globals.AliveRedPlayers = 0;
	FF2Globals.AliveBluePlayers = 0;
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(GetClientTeam(client) == FF2Globals.OtherTeam)
			{
				FF2Globals.AliveMercPlayers++;
				if(Utils_IsBoss(client))
					FF2Globals.AliveRedPlayers++;
			}
			else if(GetClientTeam(client) == FF2Globals.BossTeam)
			{
				FF2Globals.AliveBossPlayers++;
				if(Utils_IsBoss(client))
					FF2Globals.AliveBluePlayers++;
			}
		}
	}

	Forwards_Call_AlivePlayersCountChanged(FF2Globals.AliveMercPlayers, FF2Globals.AliveBossPlayers);

	if(!FF2Globals.AliveMercPlayers && !FF2Globals.AliveBossPlayers)
	{
		Utils_ForceTeamWin(0);
		return Plugin_Continue;
	}
	if(!FF2Globals.AliveMercPlayers)
	{
		Utils_ForceTeamWin(FF2Globals.BossTeam);
		return Plugin_Continue;
	}
	if(!FF2Globals.AliveBossPlayers)
	{
		Utils_ForceTeamWin(FF2Globals.OtherTeam);
		return Plugin_Continue;
	}

	if(FF2Globals.Enabled3 && ConVars.BvBLose.IntValue)
	{
		switch(ConVars.BvBLose.IntValue)
		{
			case 1:
			{
				if(!FF2Globals.AliveRedPlayers && !FF2Globals.AliveBluePlayers)
				{
					Utils_ForceTeamWin(0);
					return Plugin_Continue;
				}
				if(!FF2Globals.AliveRedPlayers)
				{
					Utils_ForceTeamWin(FF2Globals.BossTeam);
					return Plugin_Continue;
				}
				if(!FF2Globals.AliveBluePlayers)
				{
					Utils_ForceTeamWin(FF2Globals.OtherTeam);
					return Plugin_Continue;
				}
			}
			case 2:
			{
				if(!(FF2Globals.AliveMercPlayers - FF2Globals.AliveRedPlayers) && !(FF2Globals.AliveBossPlayers - FF2Globals.AliveBluePlayers))
				{
					Utils_ForceTeamWin(FF2Globals.BossTeam);
					return Plugin_Continue;
				}
				if(!(FF2Globals.AliveMercPlayers - FF2Globals.AliveRedPlayers))
				{
					Utils_ForceTeamWin(FF2Globals.BossTeam);
					return Plugin_Continue;
				}
				if(!(FF2Globals.AliveBossPlayers - FF2Globals.AliveBluePlayers))
				{
					Utils_ForceTeamWin(FF2Globals.OtherTeam);
					return Plugin_Continue;
				}
			}
		}
	}

	if(FF2Globals.AliveMercPlayers==1 && FF2Globals.AliveBossPlayers && Boss[0] && FF2Globals.MercsPlayers>1 && !DrawGameTimer && FF2Globals.IsLastMan && !FF2Globals.Enabled3)
	{
		static char sound[PLATFORM_MAX_PATH];
		if(RandomSound("sound_lastman", sound, sizeof(sound)))
			EmitSoundToAllExcept(sound);

		FF2Globals.IsLastMan=false;
	}

	float alivePlayers = FF2Globals.Enabled3 ? float(FF2Globals.AliveMercPlayers + FF2Globals.AliveBossPlayers - 1) : float(FF2Globals.AliveMercPlayers);
	if(FF2GlobalsCvars.CountdownPlayers>0 && BossHealth[0]>=FF2GlobalsCvars.CountdownHealth && (BossHealth[MAXBOSSES]>=FF2GlobalsCvars.CountdownHealth || !FF2Globals.Enabled3) && FF2GlobalsCvars.CountdownTime>1 && !FF2Globals.FF2Executed2)
	{
		if(FF2GlobalsCvars.CountdownPlayers < 1)
		{
			if(alivePlayers/FF2Globals.TotalPlayers <= FF2GlobalsCvars.CountdownPlayers)
			{
				if(Utils_FindEntityByClassname2(-1, "team_control_point") != -1)
				{
					timeleft = FF2GlobalsCvars.CountdownTime;
					DrawGameTimer = CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				FF2Globals.FF2Executed2 = true;
			}
		}
		else
		{
			if(alivePlayers <= FF2GlobalsCvars.CountdownPlayers)
			{
				if(Utils_FindEntityByClassname2(-1, "team_control_point") != -1)
				{
					timeleft = FF2GlobalsCvars.CountdownTime;
					DrawGameTimer = CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				FF2Globals.FF2Executed2 = true;
			}
		}
	}

	if(FF2GlobalsCvars.PointType!=1 && FF2GlobalsCvars.AliveToEnable>0 && !FF2Globals.FF2Executed)
	{
		if(FF2GlobalsCvars.AliveToEnable < 1)
		{
			if(alivePlayers/FF2Globals.TotalPlayers > FF2GlobalsCvars.AliveToEnable)
				return Plugin_Continue;
		}
		else
		{
			if(alivePlayers > FF2GlobalsCvars.AliveToEnable)
				return Plugin_Continue;
		}

		if(alivePlayers < FF2Globals.TotalPlayers)
		{
			for(int client=1; client<=MaxClients; client++)
			{
				if(IsClientInGame(client) && IsPlayerAlive(client))
				{
					if(ConVars.GameText.IntValue > 0)
					{
						Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "point_enable", RoundFloat(alivePlayers));
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
		Utils_SetArenaCapEnableTime(0.0);
		Utils_SetControlPoint(true);
		FF2Globals.FF2Executed = true;
	}
	return Plugin_Continue;
}

Action Timer_DrawGame(Handle timer)
{
	if((BossHealth[0]<FF2GlobalsCvars.CountdownHealth && (BossHealth[MAXBOSSES]<FF2GlobalsCvars.CountdownHealth || !FF2Globals.Enabled3)) || Utils_CheckRoundState()!=1)
	{
		FF2Globals.FF2Executed2 = false;
		return Plugin_Stop;
	}

	float alivePlayers = FF2Globals.Enabled3 ? float(FF2Globals.AliveMercPlayers + FF2Globals.AliveBossPlayers - 1) : float(FF2Globals.AliveMercPlayers);
	if(FF2GlobalsCvars.CountdownPlayers < 1)
	{
		if(alivePlayers/FF2Globals.TotalPlayers > FF2GlobalsCvars.CountdownPlayers)
		{
			FF2Globals.FF2Executed2 = false;
			return Plugin_Stop;
		}
	}
	else if(alivePlayers > FF2GlobalsCvars.CountdownPlayers)
	{
		FF2Globals.FF2Executed2 = false;
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
	if(FF2Globals.Bosses<2 && ConVars.GameText.IntValue>0 && alivePlayers==1 && ConVars.HealthHud.IntValue<2)
	{
		int boss2, clients;
		for(client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsBoss(client))
				continue;

			boss2 = Utils_GetBossIndex(client);
			char bossLives[8];
			if(BossLives[boss2] > 1)
				FormatEx(bossLives, sizeof(bossLives), "x%i", BossLives[boss2]);

			for(clients=1; clients<=MaxClients; clients++)
			{
				if(!Utils_IsValidClient(clients))
					continue;

				SetGlobalTransTarget(clients);
				Utils_GetBossSpecial(Special[boss2], name, sizeof(name), clients);
				Format(message[clients], sizeof(message[]), "%s\n%t", message[clients], "ff2_hp", name, BossHealth[boss2]-BossHealthMax[boss2]*(BossLives[boss2]-1), BossHealthMax[boss2], bossLives);
			}
		}
	}

	SetHudTextParams(-1.0, 0.17, 1.1, 255, 255, 255, 255);
	for(client=1; client<=MaxClients; client++)
	{
		if(!Utils_IsValidClient(client) || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (!IsPlayerAlive(client) && !IsClientObserver(client)))
			continue;

		SetGlobalTransTarget(client);
		if(!FF2PlayerCookie[client].HudSettings[3] && !FF2PlayerCookie[client].HudSettings[4] && FF2Globals.Bosses<2 && ConVars.GameText.IntValue>0 && alivePlayers==1 && ConVars.HealthHud.IntValue<2)
		{
			if(timeleft<=FF2GlobalsCvars.CountdownTime && timeleft>=FF2GlobalsCvars.CountdownTime/2)
			{
				Utils_ShowGameText(client, "ico_notify_sixty_seconds", _, "%s | %s", message[client], timeDisplay);
			}
			else if(timeleft<FF2GlobalsCvars.CountdownTime/2 && timeleft>=FF2GlobalsCvars.CountdownTime/6)
			{
				Utils_ShowGameText(client, "ico_notify_thirty_seconds", _, "%s | %s", message[client], timeDisplay);
			}
			else if(timeleft<FF2GlobalsCvars.CountdownTime/6 && timeleft>=0)
			{
				Utils_ShowGameText(client, "ico_notify_ten_seconds", _, "%s | %s", message[client], timeDisplay);
			}
			else if(FF2Globals.IsCapping)
			{
				Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%s | %t", message[client], "Overtime");
			}
			else if(BossIcon[0])
			{
				Utils_ShowGameText(client, BossIcon, _, "%s | %s", message[client], timeDisplay);
			}
			else
			{
				Utils_ShowGameText(client, "leaderboard_streak", _, "%s | %s", message[client], timeDisplay);
			}
		}
		else if(FF2PlayerCookie[client].HudSettings[3])
		{
		}
		else if(FF2Globals.Bosses<2 && ConVars.GameText.IntValue>1)
		{
			if(timeleft<=FF2GlobalsCvars.CountdownTime && timeleft>=FF2GlobalsCvars.CountdownTime/2)
			{
				Utils_ShowGameText(client, "ico_notify_sixty_seconds", _, "%t", "Time Left", timeDisplay);
			}
			else if(timeleft<FF2GlobalsCvars.CountdownTime/2 && timeleft>=FF2GlobalsCvars.CountdownTime/6)
			{
				Utils_ShowGameText(client, "ico_notify_thirty_seconds", _, "%t", "Time Left", timeDisplay);
			}
			else if(timeleft<FF2GlobalsCvars.CountdownTime/6 && timeleft>=0)
			{
				Utils_ShowGameText(client, "ico_notify_ten_seconds", _, "%t", "Time Left", timeDisplay);
			}
			else if(FF2Globals.IsCapping)
			{
				Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Overtime");
			}
			else if(BossIcon[0])
			{
				Utils_ShowGameText(client, BossIcon, _, timeDisplay);
			}
			else
			{
				Utils_ShowGameText(client, "leaderboard_streak", _, timeDisplay);
			}
		}
		else if(GetClientButtons(client) & IN_SCORE)
		{
		}
		else if(FF2Globals.IsCapping && timeleft<1)
		{
			ShowSyncHudText(client, FF2Huds.TimeLeft, "%t", "Overtime");
		}
		else
		{
			ShowSyncHudText(client, FF2Huds.TimeLeft, timeDisplay);
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
			if(FF2GlobalsCvars.CountdownOvertime && FF2Globals.IsCapping)
			{
				CreateTimer(1.0, OverTimeAlert, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				Utils_EndBossRound();
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}


void Timer_NoAttacking(any ref)
{
	int weapon = EntRefToEntIndex(ref);
	Utils_SetNextAttack(weapon, FF2GlobalsCvars.SniperClimpDelay);
}


Action Timer_Move(Handle timer)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client) && IsPlayerAlive(client))
			SetEntityMoveType(client, MOVETYPE_WALK);
	}
}


Action Timer_StartRound(Handle timer)
{
	CreateTimer(10.0, Timer_NextBossPanel, _, TIMER_FLAG_NO_MAPCHANGE);
	UpdateHealthBar();
	return Plugin_Handled;
}

Action Timer_NextBossPanel(Handle timer)
{
	int clients;
	bool[] added = new bool[MaxClients+1];
	while(clients < 3)  //TODO: Make this configurable?
	{
		int client = Utils_GetClientWithMostQueuePoints(added);
		if(!Utils_IsValidClient(client))  //No more players left on the server
			break;

		if(!Utils_IsBoss(client) && !xIncoming[client][0])
		{
			FPrintToChat(client, "%t", "to0_near");  //"You will become the Boss soon. Type {olive}/ff2next{default} to make sure."
			clients++;
		}
		added[client]=true;
	}
}

Action MessageTimer(Handle timer)
{
	if(FF2Globals.CheckDoors)
	{
		int entity = -1;
		while((entity=Utils_FindEntityByClassname2(entity, "func_door")) != -1)
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
	if(FF2Globals.Enabled3)
	{
		bool boss1, boss2;
		char[][] text2 = new char[MaxClients+1][512];
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Utils_IsValidClient(Boss[boss]))
			{
				char lives[8];
				if(BossLives[boss] > 1)
					FormatEx(lives, sizeof(lives), "x%i", BossLives[boss]);

				for(int client=1; client<=MaxClients; client++)
				{
					if(!Utils_IsValidClient(client))
						continue;
					
					SetGlobalTransTarget(client);
					Utils_GetBossSpecial(Special[boss], name, sizeof(name));
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
			if(!Utils_IsValidClient(client) || FF2PlayerCookie[client].HudSettings[2] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
				continue;

			ShowSyncHudText(client, FF2Huds.PlayerInfo, text[client]);
		}

		SetHudTextParams(0.6, 0.3, 10.0, 255, 100, 100, 255);
		for(int client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsValidClient(client) || FF2PlayerCookie[client].HudSettings[2] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
				continue;

			ShowSyncHudText(client, FF2Huds.Abilities, text2[client]);
		}
		CreateTimer(10.0, Timer_ShowHealthText, _, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}

	bool multi;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(Utils_IsValidClient(Boss[boss]))
		{
			char lives[8];
			if(BossLives[boss] > 1)
				FormatEx(lives, sizeof(lives), "x%i", BossLives[boss]);

			for(int client=1; client<=MaxClients; client++)
			{
				if(!Utils_IsValidClient(client))
					continue;

				SetGlobalTransTarget(client);
				Utils_GetBossSpecial(Special[boss], name, sizeof(name), client);
				Format(text[client], 512, "%s\n%t", multi ? text[client] : "", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
				FormatEx(textChat, sizeof(textChat), "%t", "ff2_start", Boss[boss], name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), lives);
				ReplaceString(textChat, sizeof(textChat), "\n", "");  //Get rid of newlines
				FPrintToChat(client, textChat);
				if(SpecialRound && ConVars.GameText.IntValue<2)
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
		if(!Utils_IsValidClient(client) || FF2PlayerCookie[client].HudSettings[2] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
			continue;

		if(FF2Globals.Bosses<2 && ConVars.GameText.IntValue>1)
		{
			if(BossIcon[0])
			{
				Utils_ShowGameText(client, BossIcon, SpecialRound ? FF2Globals.BossTeam : 0, text[client]);
			}
			else
			{
				Utils_ShowGameText(client, "leaderboard_streak", SpecialRound ? FF2Globals.BossTeam : 0, text[client]);
			}
			CreateTimer(1.5, Timer_ShowHealthText, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			ShowSyncHudText(client, FF2Huds.PlayerInfo, text[client]);
			CreateTimer(10.0, Timer_ShowHealthText, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}


Action Timer_ShowHealthText(Handle timer)
{
	ShowHealthText = true;
	return Plugin_Continue;
}


Action MakeModelTimer(Handle timer, int boss)
{
	if(Utils_IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]) && Utils_CheckRoundState()!=2)
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


Action Timer_DisplayCharsetVote(Handle timer)
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
	int shuffle = ConVars.ShuffleCharset.IntValue;
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


Action Timer_RemoveOverlay(Handle timer, TFTeam bossTeam)
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


Action Timer_DisguiseBackstab(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(Utils_IsValidClient(client, false))
		Utils_RandomlyDisguise(client);

	return Plugin_Continue;
}