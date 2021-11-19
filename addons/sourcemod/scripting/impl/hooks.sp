public void OnMapStart()
{
	FF2Globals.HPTime = 0.0;
	FF2Globals.DoorCheckTimer = INVALID_HANDLE;
	FF2Globals.RoundCount = 0;
	GetCurrentMap(FF2Globals.CurrentMap, sizeof(FF2Globals.CurrentMap));

	for(int client; client<=MaxClients; client++)
	{
		FF2BossInfo[client].KSpreeTimer = 0.0;
		FF2PlayerInfo[client].FF2Flags = 0;
		FF2BossInfo[client].Incoming = -1;
		delete FF2PlayerInfo[client].MusicTimer;
		FF2PlayerInfo[client].RPSHealth = -1;
		FF2PlayerInfo[client].RPSLosses = 0;
		FF2PlayerInfo[client].RPSHealth = 0;
		FF2PlayerInfo[client].RPSLoser = -1.0;
	}

	for(int specials; specials<MAXSPECIALS; specials++)
	{
		for(int i; i<MAXCHARSETS; i++)
		{
			if(!FF2BossPacks[specials][i])
				continue;

			delete FF2BossPacks[specials][i];
		}

		if(!FF2CharSetInfo.BossKV[specials])
			continue;

		delete FF2CharSetInfo.BossKV[specials];
	}
}

public void OnMapEnd()
{
	if(FF2Globals.Enabled || FF2Globals.Enabled2)
		DisableFF2();
}


#if defined _smac_included
public Action SMAC_OnCheatDetected(int client, const char[] module, DetectionType type, Handle info)
{
	//PrintToConsoleAll("SMAC: Cheat detected!");
	if(type == Detection_CvarViolation)
	{
		//PrintToConsoleAll("SMAC: Cheat was a cvar violation!");
		if((FF2PlayerInfo[client].FF2Flags & FF2FLAG_CHANGECVAR))
		{
			//PrintToConsoleAll("SMAC: Ignoring violation");
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}
#endif


public void OnRebuildAdminCache(AdminCachePart part)
{
	if(part == AdminCache_Overrides)
		CheckDuoMin();
}

public void OnClientPostAdminCheck(int client)
{
	// TODO: Hook these inside of EnableFF2() or somewhere instead
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);

	FF2PlayerInfo[client].FF2Flags = 0;
	FF2PlayerInfo[client].Damage = 0;
	FF2PlayerInfo[client].UberTarget = -1;
	xIncoming[client][0] = 0;
	dIncoming[client][0] = 0;
	CanBossVs[client] = 0;
	CanBossTeam[client] = 0;
	IgnoreValid[client] = false;

	if(AreClientCookiesCached(client))
	{
		static char buffer[24];
		GetClientCookie(client, FF2DataBase.PlayerPref, buffer, sizeof(buffer));
		if(!buffer[0])
			SetClientCookie(client, FF2DataBase.PlayerPref, "0 1 1 1 0 0 0 3");
			//Queue points | music exception | voice exception | class info | companion toggle | boss toggle | special toggle | UNUSED

		GetClientCookie(client, FF2DataBase.Stat_c, buffer, sizeof(buffer));
		if(!buffer[0])
			SetClientCookie(client, FF2DataBase.Stat_c, "0 0 0 0 0 0 0 0");
			//Boss wins | boss losses | boss kills | boss deaths | player kills | player MVPs | UNUSED | UNUSED

		GetClientCookie(client, FF2DataBase.Hud, buffer, sizeof(buffer));
		if(!buffer[0])
			SetClientCookie(client, FF2DataBase.Hud, "0 0 0 0 0 0 0 0");
			//Damage | extra | messages | countdown | boss health | UNUSED | UNUSED | UNUSED

		DataBase_SetupClientCookies(client);
	}

	//We use the 0th index here because client indices can change.
	//If this is false that means music is disabled for all clients, so don't play it for new clients either.
	if(FF2PlayerInfo[0].PlayBGM)
	{
		FF2PlayerInfo[client].PlayBGM = true;
		if(FF2Globals.Enabled)
			CreateTimer(0.1, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		FF2PlayerInfo[client].PlayBGM = false;
	}
}

public void OnClientDisconnect(int client)
{
	if(Utils_IsBoss(client) && !Utils_CheckRoundState() && ConVars.PreroundBossDisconnect.BoolValue)
	{
		int boss = Utils_GetBossIndex(client);
		bool[] omit = new bool[MaxClients+1];
		omit[client] = true;
		FF2BossInfo[boss].Boss = Utils_GetClientWithoutBlacklist(omit, FF2BossInfo[boss].HasSwitched ? FF2Globals.BossTeam : FF2Globals.OtherTeam);
		FF2BossInfo[boss].HasEquipped = false;
		PickCharacter(boss, boss);
		if((FF2BossInfo[boss].Special<0) || !FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special])
			LogToFile(FF2LogsPaths.Errors, "[!!!] Couldn't find a boss for index %i!", boss);

		if(FF2BossInfo[boss].Boss)
		{
			CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
			FPrintToChat(FF2BossInfo[boss].Boss, "%t", "Replace Disconnected Boss");
			FPrintToChatAll("%t", "Boss Disconnected", client, FF2BossInfo[boss].Boss);
		}
	}

	if(Utils_IsBoss(client) && (!Utils_CheckRoundState() || Utils_CheckRoundState()==1))
		DataBase_AddClientStats(client, Cookie_BossLosses, 1);

	if(FF2Globals.Enabled && IsClientInGame(client) && IsPlayerAlive(client) && Utils_CheckRoundState()==1)
		CreateTimer(0.1, Timer_CheckAlivePlayers, _, TIMER_FLAG_NO_MAPCHANGE);

	FF2PlayerInfo[client].FF2Flags = 0;
	FF2PlayerInfo[client].Damage = 0;
	FF2PlayerInfo[client].UberTarget = -1;
	xIncoming[client][0] = 0;
	dIncoming[client][0] = 0;
	CanBossVs[client] = 0;
	DataBase_SaveClientStats(client);
	DataBase_SaveClientPreferences(client);

	CheckDuoMin();

	if(FF2PlayerInfo[client].MusicTimer != null)
	{
		delete FF2PlayerInfo[client].MusicTimer;
	}
}


public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if(!FF2Globals.Enabled)
		return;

	if(Utils_IsBoss(client) && (condition==TFCond_Jarated || condition==TFCond_MarkedForDeath || (condition==TFCond_Dazed && TF2_IsPlayerInCondition(client, view_as<TFCond>(42)))))
	{
		TF2_RemoveCondition(client, condition);
	}
	else if(Utils_IsBoss(client) && FF2BossVar[client].SelfHealing>0 && (condition==TFCond_Healing || condition==TFCond_RadiusHealOnDamage || condition==TFCond_HalloweenQuickHeal)) //|| condition==TFCond_KingAura))
	{
		FF2BossVar[client].IsHealthbarIncreasing = true;
	}
	else if(!Utils_IsBoss(client) && condition==TFCond_BlastJumping)
	{
		FF2PlayerInfo[client].FF2Flags |= FF2FLAG_ROCKET_JUMPING;
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if(!FF2Globals.Enabled)
		return;

	if(TF2_GetPlayerClass(client)==TFClass_Scout && condition==TFCond_CritHype)
	{
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
	}
	else if(Utils_IsBoss(client) && (condition==TFCond_Healing || condition== TFCond_RadiusHealOnDamage || condition==TFCond_HalloweenQuickHeal)) //|| condition==TFCond_KingAura))
	{
		FF2BossVar[client].IsHealthbarIncreasing = false;
	}
	else if(!Utils_IsBoss(client) && condition==TFCond_BlastJumping)
	{
		FF2PlayerInfo[client].FF2Flags &= ~FF2FLAG_ROCKET_JUMPING;
	}
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if(Utils_IsBoss(client) && Utils_CheckRoundState()==1 && !Utils_IsPlayerCritBuffed(client) && !FF2BossVar[client].HasRandomCrits)
	{
		result = false;
		return Plugin_Changed;
	}

	if(FF2Globals.Enabled && !Utils_IsBoss(client) && Utils_CheckRoundState()==1 && IsValidEntity(weapon) && FF2GlobalsCvars.SniperClimpDelay!=0)
	{
		if(!StrContains(weaponname, "tf_weapon_club"))
			Utils_SickleClimbWalls(client, weapon);
	}
	return Plugin_Continue;
}


public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!FF2Globals.Enabled || Utils_CheckRoundState()!=1)
		return Plugin_Continue;

	int index = -1;
	int entity = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(entity) && IsValidEdict(entity) && (GetClientTeam(client)==FF2Globals.OtherTeam || FF2Globals.Enabled3) && FF2PlayerInfo[client].SapperCooldown<=0)
	{
		index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");

		if((buttons & IN_ATTACK) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !GetEntProp(client, Prop_Send, "m_bFeignDeathReady") && (index==735 || index==736 || index==810 || index==831 || index==933 || index==1080 || index==1102))
		{
			float position[3], position2[3], distance;
			int boss;
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
			for(int target=1; target<=MaxClients; target++)
			{
				if(Utils_IsValidClient(target) && IsPlayerAlive(target) && (GetClientTeam(target)==FF2Globals.BossTeam || FF2Globals.Enabled3))
				{
					boss = Utils_GetBossIndex(target);
					GetEntPropVector(target, Prop_Send, "m_vecOrigin", position2);
					distance = GetVectorDistance(position, position2);
					if(distance<120 && target!=client &&
					  !TF2_IsPlayerInCondition(target, TFCond_Dazed) &&
					  !TF2_IsPlayerInCondition(target, TFCond_Sapped) &&
					  !TF2_IsPlayerInCondition(target, TFCond_UberchargedHidden) &&
					  !TF2_IsPlayerInCondition(target, TFCond_Ubercharged) &&
					  !TF2_IsPlayerInCondition(target, TFCond_Bonked) &&
					  !TF2_IsPlayerInCondition(target, TFCond_MegaHeal))
					{
						if(boss>=0 && FF2BossVar[target].HasSapper)
						{
							if(index==810 || index==831)
							{
								TF2_AddCondition(target, TFCond_PasstimePenaltyDebuff, 6.0);
								TF2_AddCondition(target, TFCond_Sapped, 6.0);
							}
							else
							{
								TF2_StunPlayer(target, 3.0, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
								TF2_AddCondition(target, TFCond_Sapped, 3.0);
							}

							FF2PlayerInfo[client].SapperCooldown = ConVars.SapperCooldown.FloatValue;
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
							SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+1.0);
							SetEntPropFloat(client, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+1.0);
							return Plugin_Handled;
						}
						else if(boss<0 && FF2Globals.IsSapperEnabled)
						{
							if(index==810 || index==831)
							{
								TF2_AddCondition(target, TFCond_PasstimePenaltyDebuff, 8.0);
								TF2_AddCondition(target, TFCond_Sapped, 8.0);
							}
							else
							{
								TF2_StunPlayer(target, 4.0, 0.0, TF_STUNFLAGS_NORMALBONK|TF_STUNFLAG_NOSOUNDOREFFECT, client);
								TF2_AddCondition(target, TFCond_Sapped, 4.0);
							}

							FF2PlayerInfo[client].SapperCooldown = ConVars.SapperCooldown.FloatValue;
							SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, TFWeaponSlot_Melee));
							SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+1.0);
							SetEntPropFloat(client, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+1.0);
							return Plugin_Handled;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}



public Action OnGetMaxHealth(int client, int &maxHealth)
{
	if(Utils_IsBoss(client))
	{
		int boss = Utils_GetBossIndex(client);
		SetEntityHealth(client, FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1));
		maxHealth = FF2BossInfo[boss].HealthMax;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!FF2Globals.Enabled || !IsValidEntity(attacker))
		return Plugin_Continue;

	if((attacker<1 || client==attacker) && Utils_IsBoss(client) && damagetype & DMG_FALL)
	{
		return Plugin_Handled;
	}
	else if((attacker<1 || client==attacker) && Utils_IsBoss(client) && !FF2BossVar[client].SelfKnockback)
	{
		return Plugin_Handled;
	}

	if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
		return Plugin_Continue;

	float position[3];
	GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);

	if(Utils_IsBoss(attacker) && Utils_IsValidClient(client))
	{
		int boss = Utils_GetBossIndex(client);
		if(boss==-1 && !TF2_IsPlayerInCondition(client, TFCond_Bonked))
		{
			if(FF2PlayerInfo[client].EntShield && ConVars.ShieldType.IntValue==1)
			{
				Utils_RemoveShield(client, attacker);
				return Plugin_Handled;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed))
			{
				ScaleVector(damageForce, 9.0);
				damage *= 0.5;
				return Plugin_Changed;
			}

			if(TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
			{
				damage *= 0.33;
				return Plugin_Changed;
			}

			if(GetEntProp(client, Prop_Send, "m_bFeignDeathReady") || TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
			{
				if(ConVars.Ringer.FloatValue < 1)
				{
					damage *= ConVars.Ringer.FloatValue;
					return Plugin_Changed;
				}
				else if(ConVars.Ringer.FloatValue > 1)
				{
					damage = ConVars.Ringer.FloatValue;
					return Plugin_Changed;
				}
			}
			else if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
			{
				if(ConVars.Cloak.FloatValue < 1)
				{
					damage *= ConVars.Cloak.FloatValue;
					return Plugin_Changed;
				}
				else if(ConVars.Cloak.FloatValue > 1)
				{
					damage = ConVars.Cloak.FloatValue;
					return Plugin_Changed;
				}
			}

			if(damage<=160.0 && FF2BossVar[attacker].HasTripleDamage)
			{
				damage *= 3;
				return Plugin_Changed;
			}
		}
		else if(boss != -1)
		{
			bool bIsTelefrag, bIsBackstab;
			if(damagecustom == TF_CUSTOM_BACKSTAB)
			{
				bIsBackstab = true;
			}
			else if(damagecustom == TF_CUSTOM_TELEFRAG)
			{
				bIsTelefrag = true;
			}
			else if(weapon!=4095 && IsValidEntity(weapon) && weapon==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage>1000.0)
			{
				static char classname[32];
				if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_knife", false))
					bIsBackstab = true;
			}
			else if(!IsValidEntity(weapon) && (damagetype & DMG_CRUSH)==DMG_CRUSH && damage==1000.0)
			{
				bIsTelefrag = true;
			}

			if(bIsBackstab)
			{
				if(FF2Globals.Isx10)
				{
					damage = FF2BossInfo[boss].HealthMax*(Utils_LastBossIndex()+1)*FF2BossInfo[boss].LivesMax*(0.1-FF2BossInfo[boss].Stabbed/90)/(ConVars.TimesTen.FloatValue*3);
				}
				else if(ConVars.LowStab.BoolValue)
				{
					damage = (FF2BossInfo[boss].HealthMax*(Utils_LastBossIndex()+1)*FF2BossInfo[boss].LivesMax*(0.11-FF2BossInfo[boss].Stabbed/90)+(750/float(FF2Globals.TotalPlayers)))/5;
				}
				else
				{
					damage = FF2BossInfo[boss].HealthMax*(Utils_LastBossIndex()+1)*FF2BossInfo[boss].LivesMax*(0.12-FF2BossInfo[boss].Stabbed/90)/5;
				}
				damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
				damagecustom = 0;

				Action action = Forwards_Call_OnBackstabbed(boss, client, attacker);
				if(action == Plugin_Stop)
				{
					damage = 0.0;
					return Plugin_Handled;
				}

				EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
				EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
				SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+1.5);
				SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+1.5);
				SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+(ConVars.CloakStun.FloatValue*0.75));

				int viewmodel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
				if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
				{
					int melee = Utils_GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
					int animation = 42;
					switch(melee)
					{
						case 225, 356, 423, 461, 574, 649, 1071, 30758:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan, Prinny Machete
							animation = 16;

						case 638:  //Sharp Dresser
							animation = 32;
					}
					SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
				}

				if(!FF2PlayerCookie[attacker].HudSettings[2] && !(FF2PlayerInfo[attacker].FF2Flags & FF2FLAG_HUDDISABLED))
				{
					if(FF2GlobalsCvars.TellName)
					{
						char spcl[64];
						Utils_GetBossSpecial(FF2BossInfo[boss].Special, spcl, sizeof(spcl), attacker);
						switch(FF2GlobalsCvars.Annotations)
						{
							case 1:
								CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Backstab Player", spcl);

							case 2:
								Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Backstab Player", spcl);

							default:
								PrintHintText(attacker, "%t", "Backstab Player", spcl);
						}
					}
					else
					{
						switch(FF2GlobalsCvars.Annotations)
						{
							case 1:
								CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Backstab");

							case 2:
								Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Backstab");

							default:
								PrintHintText(attacker, "%t", "Backstab");
						}
					}
				}

					/*int aList[16];
					float aValues[16];
					Address aAddress;
					bool aSlient;
					int iCount = TF2Attrib_ListDefIndices(iEntity, iAttribList);
					if(iCount > 0)
					{
						for(int i; i<iCount; i++)
						{
							aAddress = TF2Attrib_GetByDefIndex(iEntity, aList[i]);
							aValues[i] = TF2Attrib_GetValue(aAddress);
							switch(aList[i])
							{
								case 154:
								{
									if(aValues[i])
										CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
								}
								case 156:
								{
									if(aValues[i])
										aSlient = true;
								}
								case 217:
								{
									if(aValues[i]>0 && (FF2BossVar[attacker].SelfHealing==1 || FF2BossVar[attacker].SelfHealing>2))
										FF2BossInfo[Utils_GetBossIndex(attacker)].Health += RoundToFloor(damage*3.0*aValues[i]);
								}
							}
						}
					}*/

				if(/*!aSlient*/ bIsBackstab)
				{
					EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
					EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);

					if(!FF2PlayerCookie[client].HudSettings[2] && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HUDDISABLED))
					{
						if(FF2GlobalsCvars.TellName)
						{
							char spcl[64];
							Utils_GetBossSpecial(FF2BossInfo[Utils_GetBossIndex(attacker)].Special, spcl, sizeof(spcl), attacker);
							switch(FF2GlobalsCvars.Annotations)
							{
								case 1:
									CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Backstabbed Player", spcl);

								case 2:
									Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Backstabbed Player", spcl);

								default:
									PrintHintText(client, "%t", "Backstabbed Player", spcl);
							}
						}
						else
						{
							switch(FF2GlobalsCvars.Annotations)
							{
								case 1:
									CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Backstabbed");

								case 2:
									Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Backstabbed");

								default:
									PrintHintText(client, "%t", "Backstabbed");
							}
						}
					}

					if(FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1) > damage*3)
					{
						static char sound[PLATFORM_MAX_PATH];
						if(RandomSound("sound_stabbed_boss", sound, sizeof(sound), boss))
						{
							EmitSoundToAllExcept(sound, _, _, _, _, _, _, FF2BossInfo[boss].Boss, _, _, false);
						}
						else if(RandomSound("sound_stabbed", sound, sizeof(sound), boss))
						{
							EmitSoundToAllExcept(sound, _, _, _, _, _, _, FF2BossInfo[boss].Boss, _, _, false);
						}
					}

					FF2Globals.HealthBarMode = true;
					CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
				}

				ActivateAbilitySlot(boss, 6);

				if(FF2BossInfo[boss].Stabbed < 3)
					FF2BossInfo[boss].Stabbed++;

				if(action == Plugin_Handled)
				{
					damage = 0.0;
					return Plugin_Handled;
				}
				return Plugin_Changed;
			}

			if(bIsTelefrag)
			{
				if(!IsPlayerAlive(attacker))
				{
					damage = 1.0;
					return Plugin_Changed;
				}
				damage = FF2BossInfo[boss].Health*1.005;
				damagecustom = 0;

				for(int all=1; all<=MaxClients; all++)
				{
					if(Utils_IsValidClient(all) && IsPlayerAlive(all))
					{
						if(!FF2PlayerCookie[all].HudSettings[2] && !(FF2PlayerInfo[all].FF2Flags & FF2FLAG_HUDDISABLED))
						{
							switch(FF2GlobalsCvars.Annotations)
							{
								case 1:
									CreateAttachedAnnotation(all, client, true, 5.0, "%t", "Telefrag Global");

								case 2:
									Utils_ShowGameText(all, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Global");

								default:
									PrintHintText(all, "%t", "Telefrag Global");
							}
						}
					}
				}

				int teleowner = Utils_FindTeleOwner(attacker);
				if(Utils_IsValidClient(teleowner) && teleowner!=attacker)
				{
					if(GetClientTeam(teleowner) == GetClientTeam(attacker))
						FF2PlayerInfo[teleowner].Damage += FF2BossInfo[boss].Health*3/5;

					if(!FF2PlayerCookie[teleowner].HudSettings[2] && !(FF2PlayerInfo[teleowner].FF2Flags & FF2FLAG_HUDDISABLED))
					{
						switch(FF2GlobalsCvars.Annotations)
						{
							case 1:
								CreateAttachedAnnotation(teleowner, client, true, 5.0, "%t", "Telefrag Assist");

							case 2:
								Utils_ShowGameText(teleowner, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Assist");

							default:
								PrintHintText(teleowner, "%t", "Telefrag Assist");
						}
					}
				}

				static char spcl[64];
				if(!FF2PlayerCookie[attacker].HudSettings[2] && !(FF2PlayerInfo[attacker].FF2Flags & FF2FLAG_HUDDISABLED))
				{
					if(FF2GlobalsCvars.TellName)
					{
						Utils_GetBossSpecial(FF2BossInfo[boss].Special, spcl, sizeof(spcl), attacker);
						switch(FF2GlobalsCvars.Annotations)
						{
							case 1:
								CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Telefrag Player", spcl);

							case 2:
								Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Player", spcl);

							default:
								PrintHintText(attacker, "%t", "Telefrag Player", spcl);
						}
					}
					else
					{
						switch(FF2GlobalsCvars.Annotations)
						{
							case 1:
								CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Telefrag");

							case 2:
								Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Telefrag");

							default:
								PrintHintText(attacker, "%t", "Telefrag");
						}
					}
				}

				if(!FF2PlayerCookie[client].HudSettings[2] && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HUDDISABLED))
				{
					if(FF2GlobalsCvars.TellName)
					{
						Utils_GetBossSpecial(FF2BossInfo[Utils_GetBossIndex(attacker)].Special, spcl, sizeof(spcl), client);
						switch(FF2GlobalsCvars.Annotations)
						{
							case 1:
								CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Telefraged Player", spcl);

							case 2:
								Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Telefraged Player", spcl);

							default:
								PrintHintText(client, "%t", "Telefraged Player", spcl);
						}
					}
					else
					{
						switch(FF2GlobalsCvars.Annotations)
						{
							case 1:
								CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Telefraged");

							case 2:
								Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Telefraged");

							default:
								PrintHintText(client, "%t", "Telefraged");
						}
					}
				}

				static char sound[PLATFORM_MAX_PATH];
				if(RandomSound("sound_telefraged", sound, sizeof(sound)))
					EmitSoundToAllExcept(sound);

				FF2Globals.HealthBarMode = true;
				CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
				return Plugin_Changed;
			}

			bool changed;
			if(damage<=160.0 && FF2BossVar[attacker].HasTripleDamage)
			{
				damage *= 3;
				changed = true;
			}

			if(damagetype & DMG_CRIT)
			{
				if(damage > 333)
				{
					damage = 333.0;
					changed = true;
				}
			}
			else if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed) || TF2_IsPlayerInCondition(attacker, TFCond_NoHealingDamageBuff))
			{
				if(damage > 740)
				{
					damage = 740.0;
					changed = true;
				}
			}
			else if(damage > 999)
			{
				damage = 999.0;
				changed = true;
			}

			if(changed)
				return Plugin_Changed;
		}
	}
	else
	{
		int boss = Utils_GetBossIndex(client);
		if(boss != -1)
		{
			if(attacker <= MaxClients)
			{
				bool bIsTelefrag, bIsBackstab;
				if(damagecustom == TF_CUSTOM_BACKSTAB)
				{
					bIsBackstab = true;
				}
				else if(damagecustom == TF_CUSTOM_TELEFRAG)
				{
					bIsTelefrag = true;
				}
				else if(weapon!=4095 && IsValidEntity(weapon) && weapon==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee) && damage>1000.0)
				{
					static char classname[32];
					if(GetEntityClassname(weapon, classname, sizeof(classname)) && !StrContains(classname, "tf_weapon_knife", false))
						bIsBackstab = true;
				}
				else if(!IsValidEntity(weapon) && (damagetype & DMG_CRUSH) && damage==1000.0)
				{
					bIsTelefrag = true;
				}

				int index;
				static char classname[64];
				if(IsValidEntity(weapon) && weapon>MaxClients && attacker<=MaxClients)
				{
					GetEntityClassname(weapon, classname, sizeof(classname));
					if(!HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))  //Dang spell Monoculuses
					{
						index = -1;
						classname[0] = 0;
					}
					else
					{
						index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
					}
				}
				else
				{
					index = -1;
					classname[0] = 0;
				}

				//Sniper rifles aren't handled by the switch/case because of the amount of reskins there are
				if(!StrContains(classname, "tf_weapon_sniperrifle"))
				{
					if(Utils_CheckRoundState() != 2)
					{
						float charge=(IsValidEntity(weapon) && weapon>MaxClients ? GetEntPropFloat(weapon, Prop_Send, "m_flChargedDamage") : 0.0);
						if(index == 752)  //Hitman's Heatmaker
						{
							float focus = 10+(charge/10);
							if(TF2_IsPlayerInCondition(attacker, TFCond_FocusBuff))
								focus /= 3;

							float rage = GetEntPropFloat(attacker, Prop_Send, "m_flRageMeter");
							SetEntPropFloat(attacker, Prop_Send, "m_flRageMeter", (rage+focus>100) ? 100.0 : rage+focus);
						}
						else if(index!=230 && index!=402 && index!=526 && index!=30665)  //Sydney Sleeper, Bazaar Bargain, Machina, Shooting Star
						{
							float time = (FF2PlayerInfo[boss].GlowTimer>10 ? 1.0 : 2.0);
							time += (FF2PlayerInfo[boss].GlowTimer>10 ? (FF2PlayerInfo[boss].GlowTimer>20 ? 1.0 : 2.0) : 4.0)*(charge/100.0);
							Utils_SetClientGlow(FF2BossInfo[boss].Boss, time);
							if(FF2PlayerInfo[boss].GlowTimer > 25.0)
								FF2PlayerInfo[boss].GlowTimer = 25.0;
						}

						if(!(damagetype & DMG_CRIT))
						{
							if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
							{
								damage *= FF2GlobalsCvars.SniperMiniDmg;
							}
							else if(index!=230 || FF2BossInfo[boss].Charge[0]>90.0)  //Sydney Sleeper
							{
								damage *= FF2GlobalsCvars.SniperDmg;
							}
							else
							{
								damage *= (FF2GlobalsCvars.SniperDmg*0.8);
							}
							return Plugin_Changed;
						}
					}
				}
				else if(!StrContains(classname, "tf_weapon_compound_bow"))
				{
					if(Utils_CheckRoundState() != 2)
					{
						if((damagetype & DMG_CRIT))
						{
							damage *= FF2GlobalsCvars.BowDmg;
							return Plugin_Changed;
						}
						else if(TF2_IsPlayerInCondition(attacker, TFCond_CritCola) || TF2_IsPlayerInCondition(attacker, TFCond_Buffed))
						{
							if(FF2GlobalsCvars.BowDmgMini > 0)
							{
								damage *= FF2GlobalsCvars.BowDmgMini;
								return Plugin_Changed;
							}
						}
						else if(FF2GlobalsCvars.BowDmgNon>0)
						{
							damage *= FF2GlobalsCvars.BowDmgNon;
							return Plugin_Changed;
						}
					}
				}

				switch(index)
				{
					case 61, 1006:  //Ambassador, Festive Ambassador
					{
						if(FF2ModsInfo.WeaponCfg == null || ConVars.HardcodeWep.IntValue>0)
						{
							if(damagecustom == TF_CUSTOM_HEADSHOT)
							{
								damage = 85.0;  //Final damage 255
								return Plugin_Changed;
							}
						}
					}
					case 132, 266, 482, 1082:  //Eyelander, HHHH, Nessie's Nine Iron, Festive Eyelander
					{
						Utils_IncrementHeadCount(attacker);
					}
					case 214:  //Powerjack
					{
						if(FF2ModsInfo.WeaponCfg == null || ConVars.HardcodeWep.IntValue>0)
						{
							int health = GetClientHealth(attacker);
							int newhealth = health+25;
							if(newhealth <= GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
								SetEntityHealth(attacker, newhealth);
						}
					}
					case 307:  //Ullapool Caber
					{
						if(!GetEntProp(weapon, Prop_Send, "m_iDetonated") && FF2GlobalsCvars.AllowedDetonation<4)	// If using ullapool caber, only trigger if bomb hasn't been detonated
						{
							if(FF2Globals.Isx10)
							{
								damage = ((Pow(float(FF2BossInfo[boss].HealthMax), 0.74074)-(FF2PlayerInfo[client].Cabered/128.0*float(FF2BossInfo[boss].HealthMax)))/(3+(ConVars.TimesTen.FloatValue*FF2GlobalsCvars.AllowedDetonation*3)))*FF2Globals.Bosses;
							}
							else if(ConVars.LowStab.BoolValue)
							{
								damage = ((Pow(float(FF2BossInfo[boss].HealthMax), 0.74074)+(2000.0/float(FF2Globals.TotalPlayers))+206.0-(FF2PlayerInfo[client].Cabered/128.0*float(FF2BossInfo[boss].HealthMax)))/(3+(FF2GlobalsCvars.AllowedDetonation*3)))*FF2Globals.Bosses;
							}
							else
							{
								damage = ((Pow(float(FF2BossInfo[boss].HealthMax), 0.74074)+512.0-(FF2PlayerInfo[client].Cabered/128.0*float(FF2BossInfo[boss].HealthMax)))/(3+(FF2GlobalsCvars.AllowedDetonation*3)))*FF2Globals.Bosses;
							}
							damagetype |= DMG_CRIT;

							if(FF2PlayerInfo[client].Cabered < 5)
								FF2PlayerInfo[client].Cabered++;

							if(FF2GlobalsCvars.AllowedDetonation < 3)
							{
								if(!FF2PlayerCookie[attacker].HudSettings[2] && !(FF2PlayerInfo[attacker].FF2Flags & FF2FLAG_HUDDISABLED))
								{
									if(FF2GlobalsCvars.TellName)
									{
										static char spcl[64];
										Utils_GetBossSpecial(FF2BossInfo[boss].Special, spcl, sizeof(spcl), attacker);
										switch(FF2GlobalsCvars.Annotations)
										{
											case 1:
												CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Caber Player", spcl);

											case 2:
												Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Caber Player", spcl);

											default:
												PrintHintText(attacker, "%t", "Caber Player", spcl);
										}
									}
									else
									{
										switch(FF2GlobalsCvars.Annotations)
										{
											case 1:
												CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Caber");

											case 2:
												Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Caber");

											default:
												PrintHintText(attacker, "%t", "Caber");
										}
									}
								}
								if(!FF2PlayerCookie[client].HudSettings[2] && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HUDDISABLED))
								{
									if(FF2GlobalsCvars.TellName)
									{
										switch(FF2GlobalsCvars.Annotations)
										{
											case 1:
												CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Cabered Player", attacker);

											case 2:
												Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Cabered Player", attacker);

											default:
												PrintHintText(client, "%t", "Cabered Player", attacker);
										}
									}
									else
									{
										switch(FF2GlobalsCvars.Annotations)
										{
											case 1:
												CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Cabered");

											case 2:
												Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Cabered");

											default:
												PrintHintText(client, "%t", "Cabered");
										}
									}
								}

								EmitSoundToClient(attacker, "ambient/lightsoff.wav", _, _, _, _, 0.6, _, _, position, _, false);
								EmitSoundToClient(client, "ambient/lightson.wav", _, _, _, _, 0.6, _, _, position, _, false);

								if(FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1) > damage*3)
								{
									static char sound[PLATFORM_MAX_PATH];
									if(RandomSound("sound_cabered", sound, sizeof(sound)))
										EmitSoundToAllExcept(sound);
								}

								FF2Globals.HealthBarMode = true;
								CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
							}
							return Plugin_Changed;
						}
					}
					case 310:  //Warrior's Spirit
					{
						if(FF2ModsInfo.WeaponCfg == null || ConVars.HardcodeWep.IntValue>0)
						{
							int health = GetClientHealth(attacker);
							int newhealth = health+50;
							if(newhealth <= GetEntProp(attacker, Prop_Data, "m_iMaxHealth"))  //No overheal allowed
								SetEntityHealth(attacker, newhealth);
						}
					}
					case 317:  //Candycane
					{
						Utils_SpawnSmallHealthPackAt(client, GetClientTeam(attacker), attacker);
					}
					case 327:  //Claidheamh Mor
					{
						if(FF2ModsInfo.WeaponCfg == null || ConVars.HardcodeWep.IntValue>0)
						{
							float charge=GetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter");
							if(charge+25.0 >= 100.0)
							{
								SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", 100.0);
							}
							else
							{
								SetEntPropFloat(attacker, Prop_Send, "m_flChargeMeter", charge+25.0);
							}
						}
					}
					case 348:  //Sharpened Volcano Fragment
					{
						if(FF2ModsInfo.WeaponCfg == null || ConVars.HardcodeWep.IntValue>0)
						{
							int health = GetClientHealth(attacker);
							int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
							int newhealth = health+5;
							if(health < max+60)
							{
								if(newhealth > max+60)
									newhealth=max+60;

								SetEntityHealth(attacker, newhealth);
							}
						}
					}
					case 357:  //Half-Zatoichi
					{
						int health = GetClientHealth(attacker);
						int max = GetEntProp(attacker, Prop_Data, "m_iMaxHealth");
						int max2 = RoundToFloor(max*2.0);
						int newhealth;
						if(GetEntProp(weapon, Prop_Send, "m_bIsBloody"))	// Less effective used more than once
						{
							newhealth = health+25;
							if(health < max2)
							{
								if(newhealth > max2)
									newhealth = max2;

								SetEntityHealth(attacker, newhealth);
							}
						}
						else	// Most effective on first hit
						{
							newhealth = health + RoundToFloor(max/2.0);
							if(health < max2)
							{
								if(newhealth > max2)
									newhealth = max2;

								SetEntityHealth(attacker, newhealth);
							}
							if(TF2_IsPlayerInCondition(attacker, TFCond_OnFire))
								TF2_RemoveCondition(attacker, TFCond_OnFire);
						}
						SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
						if(GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy") < 1)
							SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", 1);
					}
					case 416:  //Market Gardener (courtesy of Chdata)
					{
						if(Utils_RemoveCond(attacker, TFCond_BlastJumping) && ConVars.Market.FloatValue)	// New way to check explosive jumping status
						//if((FF2PlayerInfo[attacker].FF2Flags & FF2FLAG_ROCKET_JUMPING) && ConVars.Market.FloatValue)
						{
							if(FF2Globals.Isx10)
							{
								damage = ((Pow(float(FF2BossInfo[boss].HealthMax), 0.74074)-(FF2PlayerInfo[client].Marketed/128.0*float(FF2BossInfo[boss].HealthMax)))/(ConVars.TimesTen.FloatValue*3))*FF2Globals.Bosses*ConVars.Market.FloatValue;
							}
							else if(ConVars.LowStab.BoolValue)
							{
								damage = ((Pow(float(FF2BossInfo[boss].HealthMax), 0.74074)+(1750.0/float(FF2Globals.TotalPlayers))+206.0-(FF2PlayerInfo[client].Marketed/128.0*float(FF2BossInfo[boss].HealthMax)))/3)*FF2Globals.Bosses*ConVars.Market.FloatValue;
							}
							else
							{
								damage = ((Pow(float(FF2BossInfo[boss].HealthMax), 0.74074)+512.0-(FF2PlayerInfo[client].Marketed/128.0*float(FF2BossInfo[boss].HealthMax)))/3)*FF2Globals.Bosses*ConVars.Market.FloatValue;
							}
							damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;

							if(Utils_RemoveCond(attacker, TFCond_Parachute))	// If you parachuted to do this, remove your parachute.
								damage *= 0.8;	// And nerf your damage

							if(FF2PlayerInfo[client].Marketed < 5)
								FF2PlayerInfo[client].Marketed++;

							if(!(FF2PlayerInfo[attacker].FF2Flags & FF2FLAG_HUDDISABLED))
							{
								if(FF2GlobalsCvars.TellName)
								{
									static char spcl[64];
									Utils_GetBossSpecial(FF2BossInfo[boss].Special, spcl, sizeof(spcl), attacker);
									switch(FF2GlobalsCvars.Annotations)
									{
										case 1:
											CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Market Gardener Player", spcl);

										case 2:
											Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Market Gardener Player", spcl);

										default:
											PrintHintText(attacker, "%t", "Market Gardener Player", spcl);
									}
								}
								else
								{
									switch(FF2GlobalsCvars.Annotations)
									{
										case 1:
											CreateAttachedAnnotation(attacker, client, true, 3.0, "%t", "Market Gardener");

										case 2:
											Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Market Gardener");

										default:
											PrintHintText(attacker, "%t", "Market Gardener");
									}
								}
							}

							if(!(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HUDDISABLED))
							{
								if(FF2GlobalsCvars.TellName)
								{
									switch(FF2GlobalsCvars.Annotations)
									{
										case 1:
											CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Market Gardened Player", attacker);

										case 2:
											Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Market Gardened Player", attacker);

										default:
											PrintHintText(client, "%t", "Market Gardened Player", attacker);
									}
								}
								else
								{
									switch(FF2GlobalsCvars.Annotations)
									{
										case 1:
											CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Market Gardened");

										case 2:
											Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Market Gardened");

										default:
											PrintHintText(client, "%t", "Market Gardened");
									}
								}
							}

							EmitSoundToClient(attacker, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);
							EmitSoundToClient(client, "player/doubledonk.wav", _, _, _, _, 0.6, _, _, position, _, false);

							if(FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1) > damage*3)
							{
								static char sound[PLATFORM_MAX_PATH];
								if(RandomSound("sound_marketed", sound, sizeof(sound)))
									EmitSoundToAllExcept(sound);
							}

							ActivateAbilitySlot(boss, 7);
							FF2Globals.HealthBarMode = true;
							CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
							return Plugin_Changed;
						}
					}
					case 525, 595:  //Diamondback, Manmelter
					{
						if(FF2ModsInfo.WeaponCfg == null || ConVars.HardcodeWep.IntValue>0)
						{
							if(GetEntProp(attacker, Prop_Send, "m_iRevengeCrits"))  //If a revenge crit was used, give a damage bonus
							{
								damage = 85.0;  //255 final damage
								return Plugin_Changed;
							}
						}
					}
					case 528:  //Short Circuit
					{
						if(FF2GlobalsCvars.CircuitStun)
						{
							TF2_StunPlayer(client, FF2GlobalsCvars.CircuitStun, 0.0, TF_STUNFLAGS_SMALLBONK|TF_STUNFLAG_NOSOUNDOREFFECT, attacker);
							EmitSoundToAll("weapons/barret_arm_zap.wav", client);
							EmitSoundToClient(client, "weapons/barret_arm_zap.wav");
						}
					}
					case 593:  //Third Degree
					{
						int healers[MAXTF2PLAYERS];
						int healerCount;
						for(int healer; healer<=MaxClients; healer++)
						{
							if(Utils_IsValidClient(healer) && IsPlayerAlive(healer) && (Utils_GetHealingTarget(healer, true)==attacker))
							{
								healers[healerCount]=healer;
								healerCount++;
							}
						}

						for(int healer; healer<healerCount; healer++)
						{
							if(Utils_IsValidClient(healers[healer]) && IsPlayerAlive(healers[healer]))
							{
								int medigun = GetPlayerWeaponSlot(healers[healer], TFWeaponSlot_Secondary);
								if(IsValidEntity(medigun))
								{
									static char medigunClassname[64];
									GetEntityClassname(medigun, medigunClassname, sizeof(medigunClassname));
									if(StrEqual(medigunClassname, "tf_weapon_medigun", false))
									{
										float uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel")+(0.1/healerCount);
										if(uber > 1.0)
											uber = 1.0;

										SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
									}
								}
							}
						}
					}
					case 594:  //Phlogistinator
					{
						if(FF2ModsInfo.WeaponCfg == null || ConVars.HardcodeWep.IntValue>0)
						{
							if(!TF2_IsPlayerInCondition(attacker, TFCond_CritMmmph))
							{
								damage/=2.0;
								return Plugin_Changed;
							}
						}
					}
					case 44:	//Sandman
					{
						if(ConVars.EnableSandmanStun.BoolValue)
						{
							float fClientLocation[3];
							float fClientEyePosition[3];
							GetClientAbsOrigin(attacker, fClientEyePosition); 
							GetClientAbsOrigin(client, fClientLocation); 
							float fDistance[3]; 
							MakeVectorFromPoints(fClientLocation, fClientEyePosition, fDistance); 
							float dist = GetVectorLength(fDistance); 
							if (dist >= 128.0 && dist <= 256.0) 
							{
								TF2_StunPlayer(client, 1.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 256.0 && dist < 512.0) 
							{
								TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 512.0 && dist < 768.0)
							{
								TF2_StunPlayer(client, 3.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 768.0 && dist < 1024.0)
							{
								TF2_StunPlayer(client, 4.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 1024.0 && dist < 1280.0) 
							{
								TF2_StunPlayer(client, 5.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 1280.0 && dist < 1536.0) 
							{
								TF2_StunPlayer(client, 6.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 1536.0 && dist < 1792.0) 
							{
								TF2_StunPlayer(client, 7.0, 0.0, TF_STUNFLAGS_SMALLBONK, attacker); 
							}
							else if (dist >= 1792.0)
							{
								TF2_StunPlayer(client, 7.0, 0.0, TF_STUNFLAGS_BIGBONK, attacker); 
							}
							return Plugin_Changed; 
						}
					}
				}

				if(bIsBackstab)
				{
					if(FF2Globals.Enabled3)
					{
						if(FF2Globals.Isx10)
						{
							damage = FF2BossInfo[boss].HealthMax*(Utils_LastBossIndex()+1)*FF2BossInfo[boss].LivesMax*(0.1-FF2BossInfo[boss].Stabbed/90)/(ConVars.TimesTen.FloatValue*3);
						}
						else if(ConVars.LowStab.BoolValue)
						{
							damage = (FF2BossInfo[boss].HealthMax*(Utils_LastBossIndex()+1)*FF2BossInfo[boss].LivesMax*(0.11-FF2BossInfo[boss].Stabbed/90)+(1500/float(FF2Globals.TotalPlayers)))/3;
						}
						else
						{
							damage = FF2BossInfo[boss].HealthMax*(Utils_LastBossIndex()+1)*FF2BossInfo[boss].LivesMax*(0.12-FF2BossInfo[boss].Stabbed/90)/3;
						}
					}
					else if(FF2Globals.Isx10)
					{
						damage = FF2BossInfo[boss].HealthMax*FF2Globals.Bosses*(Utils_LastBossIndex()+1)*FF2BossInfo[boss].LivesMax*(0.1-FF2BossInfo[boss].Stabbed/90)/(ConVars.TimesTen.FloatValue*3);
					}
					else if(ConVars.LowStab.BoolValue)
					{
						damage = (FF2BossInfo[boss].HealthMax*FF2Globals.Bosses*(Utils_LastBossIndex()+1)*FF2BossInfo[boss].LivesMax*(0.11-FF2BossInfo[boss].Stabbed/90)+(1500/float(FF2Globals.TotalPlayers)))/3;
					}
					else
					{
						damage = FF2BossInfo[boss].HealthMax*FF2Globals.Bosses*(Utils_LastBossIndex()+1)*FF2BossInfo[boss].LivesMax*(0.12-FF2BossInfo[boss].Stabbed/90)/3;
					}
					damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
					damagecustom = 0;

					Action action = Forwards_Call_OnBackstabbed(boss, client, attacker);
					if(action == Plugin_Stop)
					{
						damage = 0.0;
						return Plugin_Handled;
					}

					EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
					SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
					SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+ConVars.CloakStun.FloatValue);

					int viewmodel = GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
					if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
					{
						int melee = Utils_GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
						int animation = 42;
						switch(melee)
						{
							case 225, 356, 423, 461, 574, 649, 1071, 30758:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan, Prinny Machete
								animation=16;

							case 638:  //Sharp Dresser
								animation=32;
						}
						SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
					}

					if(!FF2PlayerCookie[attacker].HudSettings[2] && !(FF2PlayerInfo[attacker].FF2Flags & FF2FLAG_HUDDISABLED))
					{
						if(FF2GlobalsCvars.TellName)
						{
							static char spcl[64];
							Utils_GetBossSpecial(FF2BossInfo[boss].Special, spcl, sizeof(spcl), attacker);
							switch(FF2GlobalsCvars.Annotations)
							{
								case 1:
									CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Backstab Player", spcl);

								case 2:
									Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Backstab Player", spcl);

								default:
									PrintHintText(attacker, "%t", "Backstab Player", spcl);
							}
						}
						else
						{
							switch(FF2GlobalsCvars.Annotations)
							{
								case 1:
									CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Backstab");

								case 2:
									Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Backstab");

								default:
									PrintHintText(attacker, "%t", "Backstab");
							}
						}
					}

					if(index!=225 && index!=574)  //Your Eternal Reward, Wanga Prick
					{
						EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
						EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);

						if(!FF2PlayerCookie[client].HudSettings[2] && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HUDDISABLED))
						{
							if(FF2GlobalsCvars.TellName)
							{
								static char spcl[64];
								GetClientName(attacker, spcl, sizeof(spcl));
								switch(FF2GlobalsCvars.Annotations)
								{
									case 1:
										CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Backstabbed Player", spcl);

									case 2:
										Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Backstabbed Player", spcl);

									default:
										PrintHintText(client, "%t", "Backstabbed Player", spcl);
								}
							}
							else
							{
								switch(FF2GlobalsCvars.Annotations)
								{
									case 1:
										CreateAttachedAnnotation(client, attacker, true, 3.0, "%t", "Backstabbed");

									case 2:
										Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Backstabbed");

									default:
										PrintHintText(client, "%t", "Backstabbed");
								}
							}
						}

						if(FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1) > damage*3)
						{
							static char sound[PLATFORM_MAX_PATH];
							if(RandomSound("sound_stabbed", sound, sizeof(sound), boss))
								EmitSoundToAllExcept(sound, _, _, _, _, _, _, FF2BossInfo[boss].Boss);
						}

						FF2Globals.HealthBarMode = true;
						CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
					}

					switch(index)
					{
						case 225, 574:	//Your Eternal Reward, Wanga Prick
						{
							CreateTimer(0.3, Timer_DisguiseBackstab, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);
						}
						case 356:	//Conniver's Kunai
						{
							int overheal = ConVars.KunaiMax.IntValue;
							int health = GetClientHealth(attacker)+ConVars.Kunai.IntValue;
							if(health > overheal)
								health = overheal;

							SetEntityHealth(attacker, health);
						}
						case 461:	//Big Earner
						{
							SetEntPropFloat(attacker, Prop_Send, "m_flCloakMeter", 100.0);  //Full cloak
							TF2_AddCondition(attacker, TFCond_SpeedBuffAlly, 3.0);  //Speed boost
						}
					}

					if(Utils_GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Primary) == 525)  //Diamondback
						SetEntProp(attacker, Prop_Send, "m_iRevengeCrits", GetEntProp(attacker, Prop_Send, "m_iRevengeCrits")+ConVars.Diamond.IntValue);

					ActivateAbilitySlot(boss, 6);

					if(FF2BossInfo[boss].Stabbed < 3)
						FF2BossInfo[boss].Stabbed++;

					if(action == Plugin_Handled)
					{
						damage = 0.0;
						return Plugin_Handled;
					}
					return Plugin_Changed;
				}

				if(bIsTelefrag)
				{
					damagecustom = 0;
					if(!IsPlayerAlive(attacker))
					{
						damage = 1.0;
						return Plugin_Changed;
					}
					damage = (FF2Globals.Isx10 ? ConVars.Telefrag.FloatValue*ConVars.TimesTen.FloatValue : ConVars.Telefrag.FloatValue);

					for(int all=1; all<=MaxClients; all++)
					{
						if(Utils_IsValidClient(all) && IsPlayerAlive(all))
						{
							if(!FF2PlayerCookie[all].HudSettings[2] && !(FF2PlayerInfo[all].FF2Flags & FF2FLAG_HUDDISABLED))
							{
								switch(FF2GlobalsCvars.Annotations)
								{
									case 1:
										CreateAttachedAnnotation(all, client, true, 5.0, "%t", "Telefrag Global");

									case 2:
										Utils_ShowGameText(all, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Global");

									default:
										PrintHintText(all, "%t", "Telefrag Global");
								}
							}
						}
					}

					int teleowner = Utils_FindTeleOwner(attacker);
					if(Utils_IsValidClient(teleowner) && teleowner!=attacker)
					{
						if(GetClientTeam(teleowner) == GetClientTeam(attacker))
						{
							FF2PlayerInfo[teleowner].Damage += RoundFloat(FF2Globals.Isx10 ? 3000.0*ConVars.TimesTen.FloatValue : 5401.0);

							if(!FF2PlayerCookie[teleowner].HudSettings[2] && !(FF2PlayerInfo[teleowner].FF2Flags & FF2FLAG_HUDDISABLED))
							{
								switch(FF2GlobalsCvars.Annotations)
								{
									case 1:
										CreateAttachedAnnotation(teleowner, client, true, 5.0, "%t", "Telefrag Assist");

									case 2:
										Utils_ShowGameText(teleowner, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Assist");

									default:
										PrintHintText(teleowner, "%t", "Telefrag Assist");
								}
							}
						}
					}

					static char spcl[64];
					if(!FF2PlayerCookie[attacker].HudSettings[2] && !(FF2PlayerInfo[attacker].FF2Flags & FF2FLAG_HUDDISABLED))
					{
						if(FF2GlobalsCvars.TellName)
						{
							Utils_GetBossSpecial(FF2BossInfo[boss].Special, spcl, sizeof(spcl), attacker);
							switch(FF2GlobalsCvars.Annotations)
							{
								case 1:
									CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Telefrag Player", spcl);

								case 2:
									Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Telefrag Player", spcl);

								default:
									PrintHintText(attacker, "%t", "Telefrag Player", spcl);
							}
						}
						else
						{
							switch(FF2GlobalsCvars.Annotations)
							{
								case 1:
									CreateAttachedAnnotation(attacker, client, true, 5.0, "%t", "Telefrag");

								case 2:
									Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Telefrag");

								default:
									PrintHintText(attacker, "%t", "Telefrag");
							}
						}
					}

					if(!FF2PlayerCookie[client].HudSettings[2] && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HUDDISABLED))
					{
						if(FF2GlobalsCvars.TellName)
						{
							GetClientName(attacker, spcl, sizeof(spcl));
							switch(FF2GlobalsCvars.Annotations)
							{
								case 1:
									CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Telefraged Player", spcl);

								case 2:
									Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Telefraged Player", spcl);

								default:
									PrintHintText(client, "%t", "Telefraged Player", spcl);
							}
						}
						else
						{
							switch(FF2GlobalsCvars.Annotations)
							{
								case 1:
									CreateAttachedAnnotation(client, attacker, true, 5.0, "%t", "Telefraged");

								case 2:
									Utils_ShowGameText(client, "ico_notify_flag_moving_alt", _, "%t", "Telefraged");

								default:
									PrintHintText(client, "%t", "Telefraged");
							}
						}
					}

					char sound[PLATFORM_MAX_PATH];
					if(RandomSound("sound_telefraged", sound, sizeof(sound)))
						EmitSoundToAllExcept(sound);

					FF2Globals.HealthBarMode = true;
					CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
					return Plugin_Changed;
				}

				if((damagetype & DMG_CLUB) && FF2PlayerInfo[client].CritBoosted[2]!=0 && FF2PlayerInfo[client].CritBoosted[2]!=1 && (TF2_GetPlayerClass(attacker)!=TFClass_Spy || FF2PlayerInfo[client].CritBoosted[2]>1))
				{
					int melee = Utils_GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
					if(FF2PlayerInfo[client].CritBoosted[2]>1 || (melee!=416 && melee!=307 && melee!=44))
					{
						damagetype |= DMG_CRIT|DMG_PREVENT_PHYSICS_FORCE;
						return Plugin_Changed;
					}
				}
			}
			else
			{
				char classname[64];
				if(GetEntityClassname(attacker, classname, sizeof(classname)) && StrEqual(classname, "trigger_hurt", false))
				{
					if(FF2Globals.SpawnTeleOnTriggerHurt && Utils_IsBoss(client) && Utils_CheckRoundState()==1)
					{
						FF2PlayerInfo[client].HazardDamage += damage;
						if(FF2PlayerInfo[client].HazardDamage >= ConVars.DamageToTele.FloatValue)
						{
							TeleportToMultiMapSpawn(client);
							FF2PlayerInfo[client].HazardDamage = 0.0;
						}
					}

					float damage2 = damage;
					Action action = Forwards_Call_OnTriggerHurt(boss, attacker, damage2);
					if(action!=Plugin_Stop && action!=Plugin_Handled)
					{
						if(action == Plugin_Changed)
							damage=damage2;

						if(damage > 600.0)
							damage = 600.0;

						FF2BossInfo[boss].Health -= RoundFloat(damage);
						FF2BossInfo[boss].Charge[0] += damage*100.0/FF2BossInfo[boss].RageDamage;
						if(FF2BossInfo[boss].Health < 1)
							damage *= 5;

						if(FF2BossInfo[boss].Charge[0] > FF2BossVar[client].RageMax)
							FF2BossInfo[boss].Charge[0] = FF2BossVar[client].RageMax;

						return Plugin_Changed;
					}
					else
					{
						return action;
					}
				}
			}

			if(FF2BossInfo[boss].Charge[0] > FF2BossVar[client].RageMax)
				FF2BossInfo[boss].Charge[0] = FF2BossVar[client].RageMax;
		}
		else
		{
			if(FF2GlobalsCvars.AllowedDetonation != 1)
			{
				int index = (IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") && attacker<=MaxClients) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
				if(index == 307)  //Ullapool Caber
				{
					if(FF2GlobalsCvars.AllowedDetonation<1 || FF2GlobalsCvars.AllowedDetonation-FF2PlayerInfo[attacker].Detonations>1)
					{
						FF2PlayerInfo[attacker].Detonations++;
						if(FF2GlobalsCvars.AllowedDetonation > 1)
							PrintHintText(attacker, "%t", "Detonations Left", FF2GlobalsCvars.AllowedDetonation-FF2PlayerInfo[attacker].Detonations);
	
						SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
						SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
					}
				}
			}

			if(Utils_IsValidClient(client, false) && TF2_GetPlayerClass(client)==TFClass_Soldier)  //TODO: LOOK AT THIS
			{
				if(damagetype & DMG_FALL)
				{
					int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
					if(secondary<1 || !IsValidEntity(secondary))
					{
						damage /= 10.0;
						return Plugin_Changed;
					}
				}
			}

			if(FF2Globals.Enabled3 && ConVars.BvBMerc.FloatValue!=1 && FF2Globals.AliveRedPlayers && FF2Globals.AliveBluePlayers)
			{
				if(Utils_IsValidClient(client) && Utils_IsValidClient(attacker) && GetClientTeam(attacker)!=GetClientTeam(client))
				{
					damage *= ConVars.BvBMerc.FloatValue;
					return Plugin_Changed;
				}
			}
		}
	}
	return Plugin_Continue;
}

public void OnTakeDamagePost(int client, int attacker, int inflictor, float damage, int damagetype)
{
	if(Utils_IsBoss(client))
		UpdateHealthBar();
}


public Action TF2_OnPlayerTeleport(int client, int teleporter, bool &result)
{
	if(Utils_IsBoss(client))
	{
		switch(FF2GlobalsCvars.BossTeleportation)
		{
			case -1:  //No FF2Globals.Bosses are allowed to use teleporters
				result = false;

			case 1:  //All FF2Globals.Bosses are allowed to use teleporters
				result = true;
		}
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &item)
{
	if(!FF2Globals.Enabled)
		return Plugin_Continue;

	if(!FF2Globals.HasWeaponCfg)
	{
		// Nothin
	}
	else if(FF2ModsInfo.WeaponCfg == null)
	{
		LogToFile(FF2LogsPaths.Errors, "[Weapons] Critical Error! Unable to configure weapons from '%s!", WeaponCFG);
	}
	else
	{
		int wepIdx, wepIndex, weaponIdxcount, isOverride;
		char weapon[64];
		for(int i=1; ; i++)
		{
			KvRewind(FF2ModsInfo.WeaponCfg);
			FormatEx(weapon, sizeof(weapon), "weapon%i", i);
			if(KvJumpToKey(FF2ModsInfo.WeaponCfg, weapon))
			{
				static char wepIndexStr[768], attributes[768];
				isOverride = KvGetNum(FF2ModsInfo.WeaponCfg, "mode");
				KvGetString(FF2ModsInfo.WeaponCfg, "classname", weapon, sizeof(weapon));
				KvGetString(FF2ModsInfo.WeaponCfg, "index", wepIndexStr, sizeof(wepIndexStr));
				KvGetString(FF2ModsInfo.WeaponCfg, "attributes", attributes, sizeof(attributes));

				if(isOverride)
				{
					if(StrContains(wepIndexStr, "-2")!=-1 && StrContains(classname, weapon, false)!=-1 || StrContains(wepIndexStr, "-1")!=-1 && StrEqual(classname, weapon, false))
					{
						if(isOverride != 3)
						{
							Handle itemOverride = PrepareItemHandle(item, _, _, attributes, isOverride!=1);
							if(itemOverride != null)
							{
								item = itemOverride;
								return Plugin_Changed;
							}
						}
						else
						{
							return Plugin_Stop;
						}
					}

					if(StrContains(wepIndexStr, "-1")==-1 && StrContains(wepIndexStr, "-2")==-1)
					{
						static char wepIndexes[768][32];
						weaponIdxcount = ExplodeString(wepIndexStr, " ; ", wepIndexes, sizeof(wepIndexes), 32);
						for(wepIdx=0; wepIdx<=weaponIdxcount; wepIdx++)
						{
							if(!wepIndexes[wepIdx][0])
								continue;

							wepIndex = StringToInt(wepIndexes[wepIdx]);
							if(wepIndex != iItemDefinitionIndex)
								continue;

							switch(isOverride)
							{
								case 3:
								{
									return Plugin_Stop;
								}
								case 2, 1:
								{
									Handle itemOverride = PrepareItemHandle(item, _, _, attributes, isOverride!=1);
									if(itemOverride != null)
									{
										item = itemOverride;
										return Plugin_Changed;
									}
								}
							}
						}
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

	if(ConVars.HardcodeWep.IntValue > 0)
	{
		switch(iItemDefinitionIndex)
		{
			case 39, 1081:  //Flaregun
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "6 ; 0.67");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 40, 1146:  //Backburner, Festive Backburner
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "170 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 41:  //Natascha
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "32 ; 0 ; 75 ; 1.34");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 43:  //Killing Gloves of Boxing
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "16 ; 50 ; 69 ; 0.2 ; 77 ; 0 ; 109 ; 0.5 ; 177 ; 2 ; 205 ; 0.7 ; 206 ; 0.7 ; 239 ; 0.6 ; 442 ; 1.35 ; 443 ; 1.1 ; 800 ; 0");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 44:  //Sandman
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "773 ; 1.15");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 56, 1005, 1092:  //Huntsman, Festive Huntsman, Fortified Compound
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "76 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 57:  //Razorback
			{
				if(ConVars.ShieldType.IntValue > 1)
				{
					Handle itemOverride = PrepareItemHandle(item, _, _, _, true);
					if(itemOverride != INVALID_HANDLE)
					{
						item = itemOverride;
						return Plugin_Changed;
					}
				}
			}
			case 127:  //Direct Hit
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "179 ; 1.0");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 128:  //Equalizer
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "740 ; 0 ; 239 ; 0.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 129:  //Buff Banner
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "319 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 131, 1144:  //Chargin' Targe
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "396 ; 0.95", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 140, 1086, 30668:  //Wrangler
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "54 ; 0.75 ; 128 ; 1 ; 206 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 153, 466:  //Homewrecker
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "394 ; 3 ; 215 ; 10 ; 522 ; 1 ; 216 ; 10");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 154:  //Pain Train
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "20 ; 1 ; 149 ; 6 ; 204 ; 1 ; 408 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 155:  //Southern Hospitality
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.6 ; 20 ; 1 ; 61 ; 1 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 171:  //Tribalman's Shiv
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "20 ; 1 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 173:  //Vita-Saw
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "125 ; -10 ; 17 ; 0.15 ; 737 ; 1.25", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 220:  //Shortstop
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "868 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 224:  //L'etranger
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "166 ; 5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 231:  //Darwin's Danger Shield
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "26 ; 85 ; 800 ; 0.19 ; 69 ; 0.6 ; 109 ; 0.6", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 232:  //Bushwacka
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "58 ; 1.35");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 237:  //Rocket Jumper
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.3 ; 15 ; 0 ; 135 ; 0.5 ; 206 ; 2 ; 400 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 239, 1084, 1100:  //GRU, Festive GRU, Bread Bite
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.5 ; 107 ; 1.5 ; 128 ; 1 ; 191 ; -7 ; 772 ; 1.5", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 265:  //Sticky Jumper
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.3 ; 15 ; 0 ; 89 ; -6 ; 135 ; 0.5 ; 206 ; 2 ; 280 ; 14 ; 400 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 305, 1079:  //Crusader's Crossbow, Festive Crusader's Crossbow
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "17 ; 0.2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 312:  //Brass Beast
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "206 ; 1.35");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 317:  //Candy Cane
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "740 ; 0.5 ; 239 ; 0.75", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 325, 452, 812, 833:  //Boston Basher, Three-Rune Blade, Flying Guillotine(s)
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "20 ; 1 ; 138 ; 0.67 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 327:  //Claidheamh Mor
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "412 ; 1.2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 329:  //Jag
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "92 ; 1.3 ; 6 ; 0.85 ; 95 ; 0.6 ; 1 ; 0.5 ; 137 ; 1.34", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 331:  //Fists of Steel
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "205 ; 0.65 ; 206 ; 0.65 ; 772 ; 2.0 ; 800 ; 0.6 ; 854 ; 0.6", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 348:  //Sharpened Volcano Fragment
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "16 ; 30 ; 69 ; 0.34 ; 77 ; 0 ; 109 ; 0.5 ; 773 ; 1.5 ; 205 ; 0.8 ; 206 ; 0.6 ; 239 ; 0.67 ; 442 ; 1.15 ; 443 ; 1.15 ; 800 ; 0.34");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 349:  //Sun-on-a-Stick
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.75 ; 795 ; 2", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 351:  //Detonator
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "25 ; 0.5 ; 58 ; 3.2 ; 79 ; 0.75 ; 144 ; 1.0 ; 207 ; 1.33", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 355:  //Fan O'War
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.25 ; 6 ; 0.5 ; 49 ; 1 ; 137 ; 4 ; 107 ; 1.1 ; 201 ; 1.1 ; 77 ; 0.38", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 404:  //Persian Persuader
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "772 ; 1.15 ; 249 ; 0.6 ; 781 ; 1 ; 778 ; 0.5 ; 782 ; 1", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 405, 608:  //Ali Baba's Wee Booties, Bootlegger
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "26 ; 25 ; 246 ; 3 ; 107 ; 1.10", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 406:  //Splendid Screen
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "248 ; 2.6", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 414:  //Liberty Launcher
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.65 ; 206 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 415:  //Reserve Shooter
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "2 ; 1.1 ; 3 ; 0.5 ; 114 ; 1 ; 179 ; 1 ; 547 ; 0.6", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 416:  //Market Gardener
			{
				Handle itemOverride;
				if(ConVars.Market.FloatValue)
				{
					itemOverride = PrepareItemHandle(item, _, _, "5 ; 2");
				}
				else
				{
					itemOverride = PrepareItemHandle(item, _, _, "", true);
				}

				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 426:  //Eviction Notice
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.2 ; 6 ; 0.25 ; 107 ; 1.2 ; 737 ; 2.25", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 441:  //Cow Mangler
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "71 ; 2.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 444:  //Mantreads
			{
				#if defined _tf2attributes_included
				if(FF2Globals.TF2Attrib)
				{
					TF2Attrib_SetByDefIndex(client, 58, 1.5);
				}
				else
				{
					Handle itemOverride = PrepareItemHandle(item, _, _, "58 ; 1.5");
					if(itemOverride != INVALID_HANDLE)
					{
						item = itemOverride;
						return Plugin_Changed;
					}
				}
				#else
				Handle itemOverride = PrepareItemHandle(item, _, _, "58 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
				#endif
			}
			case 442, 588:  //Bison, Pomson
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "182 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 528:  //Short Circuit
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "20 ; 1 ; 182 ; 2 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 589:  //Eureka Effect
			{
				if(!ConVars.EnableEurekaEffect.BoolValue)  //Disabled
				{
					Handle itemOverride = PrepareItemHandle(item, _, _, "93 ; 0.75 ; 276 ; 1 ; 790 ; 0.5 ; 732 ; 0.9", true);
					if(itemOverride != INVALID_HANDLE)
					{
						item = itemOverride;
						return Plugin_Changed;
					}
				}
			}
			case 593:  //Third Degree
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "853 ; 0.8 ; 854 ; 0.8");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 595:  //Manmelter
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "6 ; 0.35");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 648:  //Wrap Assassin
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.53 ; 20 ; 1 ; 138 ; 0.67 ; 408 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 656:  //Holiday Punch
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "178 ; 0.001", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 730:  //Beggar's Bazooka
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "76 ; 1.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 740:  //Scorch Shot
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "79 ; 0.75");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 772:  //Baby Face's Blaster
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "532 ; 1.2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 775:  //Escape Plan
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "740 ; 0 ; 206 ; 1.5 ; 239 ; 0.5");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 811, 832:  //Huo-Long Heater
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "71 ; 2.75");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 813, 834:  //Neon Annihilator
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "182 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1099:  //Tide Turner
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "639 ; 50", true);
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1103:  //Back Scatter
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "179 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1104:  //Air Strike
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "1 ; 0.82 ; 206 ; 1.25");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1179:  //Thermal Thruster
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "872 ; 1");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1180:  //Gas Passer
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "875 ; 1 ; 2059 ; 3000");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
			case 1181:  //Hot Hand
			{
				Handle itemOverride = PrepareItemHandle(item, _, _, "877 ; 2");
				if(itemOverride != INVALID_HANDLE)
				{
					item = itemOverride;
					return Plugin_Changed;
				}
			}
		}

		if(!StrContains(classname, "tf_weapon_syringegun_medic"))  //Syringe guns
		{
			Handle itemOverride = PrepareItemHandle(item, _, _, "17 ; 0.05");
			if(itemOverride != INVALID_HANDLE)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
		else if(!StrContains(classname, "tf_weapon_medigun"))  //Medi Gun
		{
			Handle itemOverride;
			switch(iItemDefinitionIndex)
			{
				case 35:
					itemOverride = PrepareItemHandle(item, _, _, "10 ; 2.25 ; 11 ; 1.5 ; 18 ; 1 ; 199 ; 0.75 ; 314 ; 3 ; 547 ; 0.75");

				case 411:  //Quick-Fix
					itemOverride = PrepareItemHandle(item, _, _, "8 ; 1.0 ; 10 ; 2 ; 105 ; 1 ; 144 ; 2 ; 199 ; 0.75 ; 231 ; 2 ; 493 ; 2 ; 547 ; 0.75");

				case 998:  //Vaccinator
					itemOverride = PrepareItemHandle(item, _, _, "10 ; 2.5 ; 11 ; 1.5 ; 199 ; 0.75 ; 314 ; -3 ; 479 ; 0.34 ; 499 ; 1 ; 547 ; 0.75 ; 739 ; 0.34", true);

				default:
					itemOverride = PrepareItemHandle(item, _, _, "10 ; 1.75 ; 11 ; 1.5 ; 144 ; 2.0 ; 199 ; 0.75 ; 547 ; 0.75");
			}

			if(itemOverride != INVALID_HANDLE)
			{
				item = itemOverride;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}



public void OnEntityCreated(int entity, const char[] classname)
{
	if(ConVars.HealthBar.IntValue > 0)
	{
		if(StrEqual(classname, HEALTHBAR_CLASS))
			FF2Globals.HealthBar = entity;

		if(!IsValidEntity(FF2Globals.EntMonoculus) && StrEqual(classname, MONOCULUS))
			FF2Globals.EntMonoculus = entity;
	}

	if(StrContains(classname, "item_healthkit")!=-1 || StrContains(classname, "item_ammopack")!=-1 || StrEqual(classname, "tf_ammo_pack"))
		SDKHook(entity, SDKHook_Spawn, OnItemSpawned);
}

public void OnEntityDestroyed(int entity)
{
	if(entity == FF2Globals.EntMonoculus)
	{
		FF2Globals.EntMonoculus = Utils_FindEntityByClassname2(-1, MONOCULUS);
		if(FF2Globals.EntMonoculus == entity)
		{
			FF2Globals.EntMonoculus = Utils_FindEntityByClassname2(entity, MONOCULUS);
			if(!IsValidEntity(FF2Globals.EntMonoculus) || FF2Globals.EntMonoculus==-1)
				FindHealthBar();
		}
	}
}

public void OnItemSpawned(int entity)
{
	SDKHook(entity, SDKHook_StartTouch, OnPickup);
	SDKHook(entity, SDKHook_Touch, OnPickup);
}

public Action OnPickup(int entity, int client)  //Thanks friagram!
{
	if(FF2Globals.Enabled && Utils_IsValidClient(client))
	{
		static char classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(!StrContains(classname, "item_healthkit") && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_ALLOW_HEALTH_PICKUPS))
		{
			return Plugin_Handled;
		}
		else if((!StrContains(classname, "item_ammopack") || StrEqual(classname, "tf_ammo_pack")) && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_ALLOW_AMMO_PICKUPS))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}


public Action OnStomp(int attacker, int victim, float &damageMultiplier, float &damageBonus, float &JumpPower)
{
	if(!FF2Globals.Enabled || !Utils_IsValidClient(attacker) || !Utils_IsValidClient(victim) || attacker==victim)
		return Plugin_Continue;

	switch(FF2Globals.GoombaMode)
	{
		case GOOMBA_NONE:					// none allowed
		{
			return Plugin_Handled;
		}
		case GOOMBA_BOSSTEAM:				// boss team only
		{
			if(!FF2Globals.Enabled3 && GetClientTeam(attacker)==FF2Globals.OtherTeam)	// they are on non-boss team
				return Plugin_Handled;
		}
		case GOOMBA_OTHERTEAM:				// non boss team only
		{
			if(!FF2Globals.Enabled3 && GetClientTeam(attacker)==FF2Globals.BossTeam)		// they are on boss team
				return Plugin_Handled;
		}
		case GOOMBA_NOTBOSS:				// all but boss
		{
			if(Utils_IsBoss(attacker))					// they are boss
				return Plugin_Handled;
		}
		case GOOMBA_NOMINION:				// all but minions
		{
			if(!FF2Globals.Enabled3 && !Utils_IsBoss(attacker) && GetClientTeam(attacker)==FF2Globals.BossTeam)	// they are a minion
				return Plugin_Handled;
		}
		case GOOMBA_BOSS:					// boss only
		{
			if(!Utils_IsBoss(attacker))
				return Plugin_Handled;
		}
	}

	if(Utils_IsBoss(victim))
	{
		damageMultiplier = FF2GlobalsCvars.GoombaDmg;
		JumpPower = FF2GlobalsCvars.ReboundPower;
		if(FF2Globals.Isx10)
		{
			damageMultiplier /= ConVars.TimesTen.FloatValue;
			JumpPower *= 2.0;
		}
		return Plugin_Changed;
	}
	else if(Utils_IsBoss(attacker))
	{
		if(FF2PlayerInfo[victim].EntShield)
		{
			float position[3];
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", position);
			Utils_RemoveShield(victim, attacker);
			damageMultiplier = 0.0;
			damageBonus = 0.0;
			return Plugin_Changed;
		}
		damageMultiplier = 3.0;
		damageBonus = 201.5;
		JumpPower = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public int OnStompPost(int attacker, int victim, float damageMultiplier, float damageBonus, float jumpPower)
{
	int boss;
	static char spcl[64];
	if(Utils_IsBoss(victim))
	{
		if(!FF2PlayerCookie[attacker].HudSettings[2] && !(FF2PlayerInfo[attacker].FF2Flags & FF2FLAG_HUDDISABLED))
		{
			if(FF2GlobalsCvars.TellName)
			{
				boss = Utils_GetBossIndex(victim);
				Utils_GetBossSpecial(FF2BossInfo[boss].Special, spcl, sizeof(spcl), attacker);
				switch(FF2GlobalsCvars.Annotations)
				{
					case 1:
						CreateAttachedAnnotation(attacker, victim, true, 3.0, "%t", "Goomba Stomp Player", spcl);

					case 2:
						Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp Player", spcl);

					default:
						PrintHintText(attacker, "%t", "Goomba Stomp Player", spcl);
				}
			}
			else
			{
				switch(FF2GlobalsCvars.Annotations)
				{
					case 1:
						CreateAttachedAnnotation(attacker, victim, true, 3.0, "%t", "Goomba Stomp");

					case 2:
						Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp");

					default:
						PrintHintText(attacker, "%t", "Goomba Stomp");
				}
			}
		}

		if(!FF2PlayerCookie[victim].HudSettings[2] && !(FF2PlayerInfo[victim].FF2Flags & FF2FLAG_HUDDISABLED))
		{
			if(FF2GlobalsCvars.TellName)
			{
				if(Utils_IsBoss(attacker))
				{
					boss = Utils_GetBossIndex(attacker);
					Utils_GetBossSpecial(FF2BossInfo[boss].Special, spcl, sizeof(spcl), victim);
				}
				else
				{
					GetClientName(attacker, spcl, sizeof(spcl));
				}
				switch(FF2GlobalsCvars.Annotations)
				{
					case 1:
						CreateAttachedAnnotation(victim, attacker, true, 3.0, "%t", "Goomba Stomped Boss Player", spcl);

					case 2:
						Utils_ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped Boss Player", spcl);

					default:
						PrintHintText(victim, "%t", "Goomba Stomped Boss Player", spcl);
				}
			}
			else
			{
				switch(FF2GlobalsCvars.Annotations)
				{
					case 1:
						CreateAttachedAnnotation(victim, attacker, true, 3.0, "%t", "Goomba Stomped Boss");

					case 2:
						Utils_ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped Boss");

					default:
						PrintHintText(victim, "%t", "Goomba Stomped Boss");
				}
			}
		}
		FF2Globals.HealthBarMode = true;
		CreateTimer(1.5, Timer_HealthBarMode, false, TIMER_FLAG_NO_MAPCHANGE);
		UpdateHealthBar();
	}
	else if(Utils_IsBoss(attacker))
	{
		if(!FF2PlayerCookie[attacker].HudSettings[2] && !(FF2PlayerInfo[attacker].FF2Flags & FF2FLAG_HUDDISABLED))
		{
			if(FF2GlobalsCvars.TellName)
			{
				if(Utils_IsBoss(victim))
				{
					boss = Utils_GetBossIndex(victim);
					Utils_GetBossSpecial(FF2BossInfo[boss].Special, spcl, sizeof(spcl), attacker);
				}
				else
				{
					GetClientName(victim, spcl, sizeof(spcl));
				}
				switch(FF2GlobalsCvars.Annotations)
				{
					case 1:
						CreateAttachedAnnotation(attacker, victim, true, 3.0, "%t", "Goomba Stomp Boss Player", spcl);

					case 2:
						Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp Boss Player", spcl);

					default:
						PrintHintText(attacker, "%t", "Goomba Stomp Boss Player", spcl);
				}
			}
			else
			{
				switch(FF2GlobalsCvars.Annotations)
				{
					case 1:
						CreateAttachedAnnotation(attacker, victim, true, 3.0, "%t", "Goomba Stomp Boss");

					case 2:
						Utils_ShowGameText(attacker, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomp Boss");

					default:
						PrintHintText(attacker, "%t", "Goomba Stomp Boss");
				}
			}
		}

		if(!FF2PlayerCookie[victim].HudSettings[2] && !(FF2PlayerInfo[victim].FF2Flags & FF2FLAG_HUDDISABLED))
		{
			if(FF2GlobalsCvars.TellName)
			{
				boss = Utils_GetBossIndex(attacker);
				Utils_GetBossSpecial(FF2BossInfo[boss].Special, spcl, sizeof(spcl), victim);
				switch(FF2GlobalsCvars.Annotations)
				{
					case 1:
						CreateAttachedAnnotation(victim, attacker, true, 3.0, "%t", "Goomba Stomped Player", spcl);

					case 2:
						Utils_ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped Player", spcl);

					default:
						PrintHintText(victim, "%t", "Goomba Stomped Player", spcl);
				}
			}
			else
			{
				switch(FF2GlobalsCvars.Annotations)
				{
					case 1:
						CreateAttachedAnnotation(victim, attacker, true, 3.0, "%t", "Goomba Stomped");

					case 2:
						Utils_ShowGameText(victim, "ico_notify_flag_moving_alt", _, "%t", "Goomba Stomped");

					default:
						PrintHintText(victim, "%t", "Goomba Stomped");
				}
			}
		}
	}
}


public Action OnCPTouch(int entity, int client)
{
	if(Utils_IsValidClient(client))
	{
		switch(FF2Globals.CapMode)
		{
			case CAP_NONE:
			{
				return Plugin_Handled;		// nobody can cap
			}
			case CAP_BOSS_ONLY:
			{
				if(!Utils_IsBoss(client))			// non FF2Globals.Bosses can't cap
					return Plugin_Handled;
			}
			case CAP_BOSS_TEAM:
			{
				if(!FF2Globals.Enabled3 && GetClientTeam(client)==FF2Globals.OtherTeam)	// merc team can't cap
					return Plugin_Handled;
			}
			case CAP_NOT_BOSS:
			{
				if(Utils_IsBoss(client))			// FF2Globals.Bosses can't cap
					return Plugin_Handled;
			}
			case CAP_MERC_TEAM:
			{
				if(!FF2Globals.Enabled3 && GetClientTeam(client)==FF2Globals.BossTeam)	// boss team can't cap
					return Plugin_Handled;
			}
			case CAP_NO_MINIONS:
			{
				if(!FF2Globals.Enabled3 && GetClientTeam(client)==FF2Globals.BossTeam && !Utils_IsBoss(client))
					return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

public Action RTD_CanRollDice(int client)
{
	if(Utils_IsBoss(client) && !FF2GlobalsCvars.CanBossRTD)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action RTD2_CanRollDice(int client)
{
	if(Utils_IsBoss(client) && !FF2GlobalsCvars.CanBossRTD)
		return Plugin_Handled;

	return Plugin_Continue;
}

public void CW3_OnWeaponSpawned(int weapon, int slot, int client)
{
	if(!Utils_IsBoss(client))
		return;

	TF2_RemoveWeaponSlot(client, slot);
	int boss = Utils_GetBossIndex(client);
	if(FF2BossInfo[boss].HasEquipped)
		Utils_EquipBoss(boss);
}


public Action HookSound(int clients[64], int &numClients, char sound[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if(!FF2Globals.Enabled || !Utils_IsValidClient(client) || channel<1)
		return Plugin_Continue;

	if(TF2_IsPlayerInCondition(client, TFCond_Disguised))
	{
		int iDisguisedTarget = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
		int iDisguisedClass = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
		int disguiseboss = Utils_GetBossIndex(iDisguisedTarget);

		if(disguiseboss==-1 || TF2_GetPlayerClass(iDisguisedTarget)!=view_as<TFClassType>(iDisguisedClass))
			return Plugin_Continue;

		if(channel==SNDCHAN_VOICE || (channel==SNDCHAN_STATIC && !StrContains(sound, "vo")))
		{
			if(FF2PlayerInfo[FF2BossInfo[disguiseboss].Boss].FF2Flags & FF2FLAG_TALKING)
				return Plugin_Continue;
	
			static char newSound[PLATFORM_MAX_PATH];
			if(RandomSoundVo("catch_replace", newSound, PLATFORM_MAX_PATH, disguiseboss, sound))
			{
				strcopy(sound, PLATFORM_MAX_PATH, newSound);
				return Plugin_Changed;
			}

			if(RandomSound("catch_phrase", newSound, PLATFORM_MAX_PATH, disguiseboss))
			{
				strcopy(sound, PLATFORM_MAX_PATH, newSound);
				return Plugin_Changed;
			}

			if(FF2CharSetInfo.VoiceBlocked[FF2BossInfo[disguiseboss].Special])
				return Plugin_Stop;
		}
	}

	int boss = Utils_GetBossIndex(client);
	if(boss == -1)
		return Plugin_Continue;

	if(channel==SNDCHAN_VOICE || (channel==SNDCHAN_STATIC && !StrContains(sound, "vo")))
	{
		if(FF2PlayerInfo[FF2BossInfo[boss].Boss].FF2Flags & FF2FLAG_TALKING)
			return Plugin_Continue;

		static char newSound[PLATFORM_MAX_PATH];
		if(RandomSoundVo("catch_replace", newSound, PLATFORM_MAX_PATH, boss, sound))
		{
			strcopy(sound, PLATFORM_MAX_PATH, newSound);
			return Plugin_Changed;
		}

		if(RandomSound("catch_phrase", newSound, PLATFORM_MAX_PATH, boss))
		{
			strcopy(sound, PLATFORM_MAX_PATH, newSound);
			return Plugin_Changed;
		}

		if(FF2CharSetInfo.VoiceBlocked[FF2BossInfo[boss].Special])
			return Plugin_Stop;
	}
	return Plugin_Continue;
}


static Handle PrepareItemHandle(Handle item, char[] name="", int index=-1, const char[] att="", bool dontPreserve=false)
{
	static Handle weapon;
	int addattribs;

	static char weaponAttribsArray[32][32];
	int attribCount = ExplodeString(att, ";", weaponAttribsArray, 32, 32);

	if(attribCount % 2)
		--attribCount;

	int flags = OVERRIDE_ATTRIBUTES;
	if(!dontPreserve)
		flags |= PRESERVE_ATTRIBUTES;

	if(!weapon)	weapon = TF2Items_CreateItem(flags);
	else		TF2Items_SetFlags(weapon, flags);

	if(item != INVALID_HANDLE)
	{
		addattribs = TF2Items_GetNumAttributes(item);
		if(addattribs > 0)
		{
			for(int i; i<2*addattribs; i+=2)
			{
				bool dontAdd;
				int attribIndex = TF2Items_GetAttributeId(item, i);
				for(int z; z<attribCount+i; z+=2)
				{
					if(StringToInt(weaponAttribsArray[z]) == attribIndex)
					{
						dontAdd = true;
						break;
					}
				}

				if(!dontAdd)
				{
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
					FloatToString(TF2Items_GetAttributeValue(item, i), weaponAttribsArray[i+1+attribCount], 32);
				}
			}
			attribCount += 2*addattribs;
		}

		if(weapon != item)  //FlaminSarge: Item might be equal to weapon, so closing item's handle would also close weapon's
			delete item;  //probably returns false but whatever (rswallen-apparently not)
	}

	if(name[0])
	{
		flags |= OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(weapon, name);
	}

	if(index != -1)
	{
		flags |= OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(weapon, index);
	}

	if(attribCount > 0)
	{
		TF2Items_SetNumAttributes(weapon, attribCount/2);
		int i2;
		for(int i; i<attribCount && i2<16; i+=2)
		{
			int attrib = StringToInt(weaponAttribsArray[i]);
			if(!attrib)
			{
				LogToFile(FF2LogsPaths.Errors, "[Weapons] Bad weapon attribute passed: %s ; %s", weaponAttribsArray[i], weaponAttribsArray[i+1]);
				delete weapon;
				return INVALID_HANDLE;
			}

			TF2Items_SetAttribute(weapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}
	TF2Items_SetFlags(weapon, flags);
	return weapon;
}