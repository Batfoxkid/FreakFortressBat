Action Timer_Announce(Handle timer)
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


Action Timer_EnableCap(Handle timer)
{
	if((Enabled || Enabled2) && Utils_CheckRoundState()==-1)
	{
		Utils_SetControlPoint(true);
		if(checkDoors)
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
	if(!checkDoors)
	{
		doorCheckTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if((!Enabled && Utils_CheckRoundState()!=-1) || (Enabled && Utils_CheckRoundState()!=1))
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
		if(Utils_IsValidClient(client) && ToggleVoice[client])
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
		if(view_as<int>(ToggleBoss[client])>1 && cvarToggleBoss.BoolValue)	// Do not give queue points to those who have ff2 bosses disabled
			continue;

		if(Utils_IsValidClient(client))
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

			if(Utils_IsBoss(client))
			{
				if(((!Utils_GetBossIndex(client) || Utils_GetBossIndex(client)==MAXBOSSES) && cvarDuoRestore.BoolValue) || !cvarDuoRestore.BoolValue)
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

				QueuePoints[client] += add_points2[client];
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

				QueuePoints[client] += add_points[client];
			}
		}
	}
}


Action StartResponseTimer(Handle timer)
{
	static char sound[PLATFORM_MAX_PATH];
	if(Enabled3)
	{
		static char sound2[PLATFORM_MAX_PATH];
		bool isIntro = RandomSound("sound_begin", sound, sizeof(sound));
		bool isIntro2 = RandomSound("sound_begin", sound2, sizeof(sound2), MAXBOSSES);
		for(int client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsValidClient(client) || !ToggleVoice[client])
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

Action StartIntroMusicTimer(Handle timer)
{
	static char sound[PLATFORM_MAX_PATH];
	if(RandomSound("sound_intromusic", sound, sizeof(sound)))
		EmitMusicToAllExcept(sound);

	return Plugin_Continue;
}


Action Timer_SetEnabled3(Handle timer, bool toggle)
{
	Enabled3 = toggle;
	if(Enabled3)
	{
		SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);

		int reds, blus;
		for(int client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsValidClient(client))
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
			if(!Utils_IsValidClient(client))
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

Action BossMenuTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(Utils_IsValidClient(client) && ToggleBoss[client]!=Setting_On && ToggleBoss[client]!=Setting_Off)
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
		if(!Utils_IsValidClient(client) || Utils_IsBoss(client) || (FF2flags[client] & FF2FLAG_CLASSTIMERDISABLED))
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
				else if(!Utils_IsBoss(observer))
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
		else if(cvarDeadRingerHud.BoolValue && Utils_GetClientCloakIndex(client)==59)
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
					Utils_SetClientGlow(client, 0.5, 3.0);
			}
			else if(aliveTeammates <= lastPlayerGlow)
			{
				Utils_SetClientGlow(client, 0.5, 3.0);
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

		Utils_SetClientGlow(client, -0.2);

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
						if(index!=16 || !IsValidEntity(Utils_FindPlayerBack(client, 642)) || SniperClimbDelay<=0)	//Nerf Cozy Camper SMGs if Wall Climb is on
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
	int ForcedTeam = BossSwitched[boss] ? OtherTeam : BossTeam;
	if(GetClientTeam(client) != ForcedTeam)
		Utils_AssignTeam(client, ForcedTeam);

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
				Utils_SwitchTeams((currentBossTeam==1) ? (view_as<int>(TFTeam_Blue)) : (view_as<int>(TFTeam_Red)) , (currentBossTeam==1) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)), true);

			case 2: // RED Boss
				Utils_SwitchTeams(view_as<int>(TFTeam_Red), view_as<int>(TFTeam_Blue), true);

			case 3: // BLU Boss
				Utils_SwitchTeams(view_as<int>(TFTeam_Blue), view_as<int>(TFTeam_Red), true);

			default: // Determined by "ff2_force_team" ConVar
				Utils_SwitchTeams((blueBoss) ? (view_as<int>(TFTeam_Blue)) : (view_as<int>(TFTeam_Red)), (blueBoss) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)), true);
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
	BossKillsF[client] = BossKills[client];
	HealthBarModeC[client] = false;
	if(((!Utils_GetBossIndex(client) || Utils_GetBossIndex(client)==MAXBOSSES) && cvarDuoRestore.BoolValue) || !cvarDuoRestore.BoolValue)
		QueuePoints[client] = 0;

	if(AreClientCookiesCached(client))
	{
		static char cookie[64];
		KvGetString(BossKV[Special[boss]], "name", cookie, sizeof(cookie));
		SetClientCookie(client, LastPlayedCookie, cookie);
	}
	return Plugin_Continue;
}

Action Timer_MakeNotBoss(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!Utils_IsValidClient(client) || !IsPlayerAlive(client) || Utils_CheckRoundState()==2 || Utils_IsBoss(client) || (FF2flags[client] & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
		return Plugin_Continue;

	if(!IsVoteInProgress() && ToggleInfo[client] && !(FF2flags[client] & FF2FLAG_CLASSHELPED))
		HelpPanelClass(client);

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);  //This really shouldn't be needed but I've been noticing players who still have glow

	SetEntityHealth(client, GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client)); //Temporary: Reset health to avoid an overheal bug
	if(!Enabled3 && GetClientTeam(client)==BossTeam)
		Utils_AssignTeam(client, OtherTeam);

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
			if(Utils_GetIndexOfWeaponSlot(client, TFWeaponSlot_Melee) == 142)  //Gunslinger (Randomizer, etc. compatability)
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

	int playerBack = Utils_FindPlayerBack(client, 57);  //Razorback
	shield[client] = IsValidEntity(playerBack) ? playerBack : 0;
	hadshield[client] = IsValidEntity(playerBack) ? true : false;
	if(IsValidEntity(Utils_FindPlayerBack(client, 642)))  //Cozy Camper
		FF2_SpawnWeapon(client, "tf_weapon_smg", 16, 1, 6, "149 ; 1.5 ; 15 ; 0.0 ; 1 ; 0.75");

	#if defined _tf2attributes_included
	if(tf2attributes && (kvWeaponMods == null || cvarHardcodeWep.IntValue>0))
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

	if(RPSLosses[client] >= cvarRPSLimit.IntValue)
	{
		if(Utils_IsValidClient(RPSWinner) && BossHealth[boss]>1349)
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
		if(Utils_IsValidClient(RPSWinner))
			SDKHooks_TakeDamage(client, RPSWinner, RPSWinner, float((RPSHealth[client]/cvarRPSLimit.IntValue)-999)/1.35, DMG_GENERIC, -1);
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
	if(!Enabled || Utils_CheckRoundState()==2)
		return Plugin_Stop;

	int client, observer, buttons, target, aliveTeammates;
	bool validBoss;
	int StatHud = cvarStatHud.IntValue;
	int HealHud = cvarHealingHud.IntValue;
	static char sound[PLATFORM_MAX_PATH];
	for(int boss; boss<=MaxClients; boss++)
	{
		client = Boss[boss];
		if(!Utils_IsValidClient(client) || !(FF2flags[client] & FF2FLAG_USEBOSSTIMER))
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
						ShowSyncHudText(client, statHUD, "%t %t", "Spectator Damage Dealt", sound, Damage[observer], "Healing", Healing[observer]);
					}
					else
					{
						ShowSyncHudText(client, statHUD, "%t", "Spectator Damage Dealt", sound, Damage[observer]);
					}
				}
			}
			else if(observer && Utils_IsBoss(observer))
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

		Utils_SetClientGlow(client, -0.2);

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
					Utils_SetClientGlow(client, 0.3, 3.0);
			}
			else if(aliveTeammates <= lastPlayerGlow)
			{
				Utils_SetClientGlow(client, 0.3, 3.0);
			}
		}

		if(aliveTeammates<2 && cvarHealthHud.IntValue<2 && (bosses>1 || Enabled3 || !cvarGameText.IntValue || !FF2Executed2))
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
				if(Utils_IsValidClient(target) && (IsPlayerAlive(client) || IsClientObserver(client)) && !HudSettings[client][4] && !(FF2flags[target] & FF2FLAG_HUDDISABLED))
				{
					if(bosses<2 && cvarGameText.IntValue>0)
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

Action GlobalTimer(Handle timer)
{
	int HealthHud = cvarHealthHud.IntValue;

	if(!Enabled || Utils_CheckRoundState()==2 || Utils_CheckRoundState()==-1 || HealthHud<1)
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

	if(!isCapping)
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
		FPrintToChat(client, "{olive}%t. %t{default}", "damage", Damage[client], "scores", RoundToFloor(Damage[client]/PointsInterval2));

	return Plugin_Continue;
}


Action Timer_CheckAlivePlayers(Handle timer)
{
	if(Utils_CheckRoundState() == 2)
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
				if(Utils_IsBoss(client))
					RedAliveBosses++;
			}
			else if(GetClientTeam(client) == BossTeam)
			{
				BossAlivePlayers++;
				if(Utils_IsBoss(client))
					BlueAliveBosses++;
			}
		}
	}

	Forwards_Call_AlivePlayersCountChanged(MercAlivePlayers, BossAlivePlayers);

	if(!MercAlivePlayers && !BossAlivePlayers)
	{
		Utils_ForceTeamWin(0);
		return Plugin_Continue;
	}
	if(!MercAlivePlayers)
	{
		Utils_ForceTeamWin(BossTeam);
		return Plugin_Continue;
	}
	if(!BossAlivePlayers)
	{
		Utils_ForceTeamWin(OtherTeam);
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
					Utils_ForceTeamWin(0);
					return Plugin_Continue;
				}
				if(!RedAliveBosses)
				{
					Utils_ForceTeamWin(BossTeam);
					return Plugin_Continue;
				}
				if(!BlueAliveBosses)
				{
					Utils_ForceTeamWin(OtherTeam);
					return Plugin_Continue;
				}
			}
			case 2:
			{
				if(!(MercAlivePlayers - RedAliveBosses) && !(BossAlivePlayers - BlueAliveBosses))
				{
					Utils_ForceTeamWin(BossTeam);
					return Plugin_Continue;
				}
				if(!(MercAlivePlayers - RedAliveBosses))
				{
					Utils_ForceTeamWin(BossTeam);
					return Plugin_Continue;
				}
				if(!(BossAlivePlayers - BlueAliveBosses))
				{
					Utils_ForceTeamWin(OtherTeam);
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
	if(countdownPlayers>0 && BossHealth[0]>=countdownHealth && (BossHealth[MAXBOSSES]>=countdownHealth || !Enabled3) && countdownTime>1 && !FF2Executed2)
	{
		if(countdownPlayers < 1)
		{
			if(alivePlayers/playing <= countdownPlayers)
			{
				if(Utils_FindEntityByClassname2(-1, "team_control_point") != -1)
				{
					timeleft = countdownTime;
					DrawGameTimer = CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				FF2Executed2 = true;
			}
		}
		else
		{
			if(alivePlayers <= countdownPlayers)
			{
				if(Utils_FindEntityByClassname2(-1, "team_control_point") != -1)
				{
					timeleft = countdownTime;
					DrawGameTimer = CreateTimer(1.0, Timer_DrawGame, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				FF2Executed2 = true;
			}
		}
	}

	if(PointType!=1 && AliveToEnable>0 && !FF2Executed)
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
		FF2Executed = true;
	}
	return Plugin_Continue;
}

Action Timer_DrawGame(Handle timer)
{
	if((BossHealth[0]<countdownHealth && (BossHealth[MAXBOSSES]<countdownHealth || !Enabled3)) || Utils_CheckRoundState()!=1)
	{
		FF2Executed2 = false;
		return Plugin_Stop;
	}

	float alivePlayers = Enabled3 ? float(MercAlivePlayers + BossAlivePlayers - 1) : float(MercAlivePlayers);
	if(countdownPlayers < 1)
	{
		if(alivePlayers/playing > countdownPlayers)
		{
			FF2Executed2 = false;
			return Plugin_Stop;
		}
	}
	else if(alivePlayers > countdownPlayers)
	{
		FF2Executed2 = false;
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
		if(!HudSettings[client][3] && !HudSettings[client][4] && bosses<2 && cvarGameText.IntValue>0 && alivePlayers==1 && cvarHealthHud.IntValue<2)
		{
			if(timeleft<=countdownTime && timeleft>=countdownTime/2)
			{
				Utils_ShowGameText(client, "ico_notify_sixty_seconds", _, "%s | %s", message[client], timeDisplay);
			}
			else if(timeleft<countdownTime/2 && timeleft>=countdownTime/6)
			{
				Utils_ShowGameText(client, "ico_notify_thirty_seconds", _, "%s | %s", message[client], timeDisplay);
			}
			else if(timeleft<countdownTime/6 && timeleft>=0)
			{
				Utils_ShowGameText(client, "ico_notify_ten_seconds", _, "%s | %s", message[client], timeDisplay);
			}
			else if(isCapping)
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
		else if(HudSettings[client][3])
		{
		}
		else if(bosses<2 && cvarGameText.IntValue>1)
		{
			if(timeleft<=countdownTime && timeleft>=countdownTime/2)
			{
				Utils_ShowGameText(client, "ico_notify_sixty_seconds", _, "%t", "Time Left", timeDisplay);
			}
			else if(timeleft<countdownTime/2 && timeleft>=countdownTime/6)
			{
				Utils_ShowGameText(client, "ico_notify_thirty_seconds", _, "%t", "Time Left", timeDisplay);
			}
			else if(timeleft<countdownTime/6 && timeleft>=0)
			{
				Utils_ShowGameText(client, "ico_notify_ten_seconds", _, "%t", "Time Left", timeDisplay);
			}
			else if(isCapping)
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
	Utils_SetNextAttack(weapon, SniperClimbDelay);
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
	if(checkDoors)
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
	if(Enabled3)
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
			if(!Utils_IsValidClient(client) || HudSettings[client][2] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
				continue;

			ShowSyncHudText(client, infoHUD, text[client]);
		}

		SetHudTextParams(0.6, 0.3, 10.0, 255, 100, 100, 255);
		for(int client=1; client<=MaxClients; client++)
		{
			if(!Utils_IsValidClient(client) || HudSettings[client][2] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
				continue;

			ShowSyncHudText(client, abilitiesHUD, text2[client]);
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
		if(!Utils_IsValidClient(client) || HudSettings[client][2] || (FF2flags[client] & FF2FLAG_HUDDISABLED) || (GetClientButtons(client) & IN_SCORE))
			continue;

		if(bosses<2 && cvarGameText.IntValue>1)
		{
			if(BossIcon[0])
			{
				Utils_ShowGameText(client, BossIcon, SpecialRound ? BossTeam : 0, text[client]);
			}
			else
			{
				Utils_ShowGameText(client, "leaderboard_streak", SpecialRound ? BossTeam : 0, text[client]);
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