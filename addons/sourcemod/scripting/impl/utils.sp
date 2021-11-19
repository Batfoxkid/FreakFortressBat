bool Utils_UseAbility(const char[] ability_name, const char[] plugin_name, int boss, int slot, int buttonMode=0)
{
	int client = FF2BossInfo[boss].Boss;
	bool enabled = true;

	char plugin_name2[64];
	FormatEx(plugin_name2, sizeof(plugin_name2), "%s.smx", plugin_name);

	Forwards_Call_PreAbility(boss, plugin_name2, ability_name, slot, enabled);

	if(!enabled)
		return false;

	Forwards_BeginCall_OnAbility(boss, plugin_name2, ability_name);
	if(slot<0 || slot>3)
	{
		// we're assuming here a non-rage or passive ability will always be in use if it gets called
		Forwards_EndCall_OnAbility(3);
	}
	else if(!slot)
	{
		FF2PlayerInfo[FF2BossInfo[boss].Boss].FF2Flags &= ~FF2FLAG_BOTRAGE;
		Forwards_EndCall_OnAbility(3);

		if(FF2BossInfo[boss].RageDamage > 1)
		{
			if(FF2BossVar[client].RageMode == 1)
			{
				FF2BossInfo[boss].Charge[slot] -= FF2BossVar[client].RageMin;
			}
			else if(!FF2BossVar[client].RageMode)
			{
				FF2BossInfo[boss].Charge[slot] = 0.0;
			}
		}
	}
	else
	{
		SetHudTextParams(-1.0, 0.88, 0.15, 255, 255, 255, 255);
		int button;
		switch(buttonMode)
		{
			case 1:
				button = IN_DUCK|IN_ATTACK2;

			case 2:
				button = IN_RELOAD;

			case 3:
				button = IN_ATTACK3;

			case 4:
				button = IN_DUCK;

			case 5:
				button = IN_SCORE;

			default:
				button = IN_ATTACK2;
		}

		if(GetClientButtons(FF2BossInfo[boss].Boss) & button)
		{
			if(FF2BossInfo[boss].Charge[slot] >= 0.0)
			{
				Forwards_EndCall_OnAbility(2);
				float charge;
				if(GetArgumentI(boss, plugin_name, ability_name, "slot", -2) != -2)
				{
					charge = 100.0*0.2/GetArgumentF(boss, plugin_name, ability_name, "charge time", 1.5);
				}
				else
				{
					charge = 100.0*0.2/GetAbilityArgumentFloat(boss, plugin_name, ability_name, 1, 1.5);
				}

				if(FF2BossInfo[boss].Charge[slot]+charge < 100.0)
				{
					FF2BossInfo[boss].Charge[slot] += charge;
				}
				else
				{
					FF2BossInfo[boss].Charge[slot] = 100.0;
				}
			}
			else
			{
				//Status
				Forwards_EndCall_OnAbility(1);
				FF2BossInfo[boss].Charge[slot] += 0.2;
			}
		}
		else if(FF2BossInfo[boss].Charge[slot] > 0.3)
		{
			float angles[3];
			GetClientEyeAngles(FF2BossInfo[boss].Boss, angles);
			if(angles[0] < FF2GlobalsCvars.ChargeAngle*-1.0)
			{
				Forwards_EndCall_OnAbility(3);
				DataPack data;
				CreateDataTimer(0.1, Timer_UseBossCharge, data);
				data.WriteCell(boss);
				data.WriteCell(slot);
				if(GetArgumentI(boss, plugin_name, ability_name, "slot", -2) != -2)
				{
					data.WriteFloat(-1.0*GetArgumentF(boss, plugin_name, ability_name, "cooldown", 5.0));
				}
				else
				{
					data.WriteFloat(-1.0*GetAbilityArgumentFloat(boss, plugin_name, ability_name, 2, 5.0));
				}
			}
			else
			{
				Forwards_EndCall_OnAbility(0);
				FF2BossInfo[boss].Charge[slot] = 0.0;
			}
		}
		else if(FF2BossInfo[boss].Charge[slot] < 0.0)
		{
			Forwards_EndCall_OnAbility(1);
			FF2BossInfo[boss].Charge[slot] += 0.2;
		}
		else
		{
			Forwards_EndCall_OnAbility(0);
		}
	}
	return true;
}

bool Utils_HasAbility(int boss, const char[] plugin_name, const char[] ability_name)
{
	FF2QueryData data;
	if (!FF2Cache.Request(boss, data)) {
		return false;
	}
	return Utils_HasAbilityEx(data, boss, plugin_name, ability_name);
}

bool Utils_HasAbilityEx(const FF2QueryData data, int boss, const char[] plugin_name, const char[] ability_name)
{
	const int size_of_lookup = 132;
	char[] key = new char[size_of_lookup];

	FF2Cache.FormatToHasAbility(key, plugin_name, ability_name);
	FF2Cache actual = view_as<FF2Cache>(data.cache);

	bool res;

	if (actual.GetValue(key, res))
		return res;

	KeyValues kv = FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special];
	kv.Rewind();

	char abkey[24];
	for (int ab = 1; ab <= MAXRANDOMS; ab++)
	{
		FormatEx(abkey, sizeof(abkey), "ability%i", ab);
		if (!kv.JumpToKey(abkey)) {
			continue;
		}

		kv.GetString("name", key, 64);
		if (!StrEqual(key, ability_name)) {
			kv.GoBack();
			continue;
		}

		kv.GetString("plugin_name", key, 64);
		if (!StrEqual(key, plugin_name) && plugin_name[0]) {
			kv.GoBack();
			continue;
		}

		FF2Cache.FormatToHasAbility(key, plugin_name, ability_name);
		actual.SetValue(key, true);
		return true;
	}

	FF2Cache.FormatToHasAbility(key, plugin_name, ability_name);
	actual.SetValue(key, false);
	return false;
}

void Utils_AddServerTag(const char[] tag)
{
	if(ConVars.Tags == view_as<ConVar>(INVALID_HANDLE))
		return;

	static char currtags[128];
	ConVars.Tags.GetString(currtags, sizeof(currtags));
	if(StrContains(currtags, tag) > -1)
		return;

	char newtags[128];
	FormatEx(newtags, sizeof(newtags), "%s%s%s", currtags, currtags[0] ? "," : "", tag);
	int flags = GetConVarFlags(ConVars.Tags);
	SetConVarFlags(ConVars.Tags, flags & ~FCVAR_NOTIFY);
	ConVars.Tags.SetString(newtags);
	SetConVarFlags(ConVars.Tags, flags);
}

void Utils_RemoveServerTag(const char[] tag)
{
	if(ConVars.Tags == view_as<ConVar>(INVALID_HANDLE))
		return;

	static char newtags[128];
	ConVars.Tags.GetString(newtags, sizeof(newtags));
	if(StrContains(newtags, tag) == -1)
		return;

	ReplaceString(newtags, sizeof(newtags), tag, "");
	ReplaceString(newtags, sizeof(newtags), ",,", "");
	int flags = GetConVarFlags(ConVars.Tags);
	SetConVarFlags(ConVars.Tags, flags & ~FCVAR_NOTIFY);
	ConVars.Tags.SetString(newtags);
	SetConVarFlags(ConVars.Tags, flags);
}


bool Utils_IsValidClient(int client, bool replaycheck=true)
{
	if(client<1 || client>MaxClients)
		return false;

	if(!IsClientInGame(client))
		return false;

	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
		return false;

	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}


#if defined _tf2attributes_included
int g_teamOverrides[4] = {0, 0, 3, 0}; // This is the m_nModelIndexOverrides index for each team.

void Utils_ModelOverrides_Clear(int client)
{
	for(int i=0; i<4; i++)
	{
		SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", 0, _, i);
	}
}

void Utils_VisionFlags_Update(int client)
{
	if(!FF2Globals.TF2Attrib || !ConVars.Disguise.BoolValue)
		return;

	// RED will see index 4 (rome vision)
	// BLU will see index 0 (normal, everyone sees this, but RED won't see their index unless index 0 is non-zero)
	TF2Attrib_RemoveByDefIndex(client, 406);

	if(TF2_GetClientTeam(client) == TFTeam_Red)
		TF2Attrib_SetByDefIndex(client, 406, 4.0);
}

void Utils_ModelOverrides_Think(int client, int iDisguisedTarget)
{
	int iTeam = GetClientTeam(client);
	int iEnemyTeam = (iTeam == 2) ? 3 : 2;

	static char strPlayerModel[128];
	GetEntPropString(client, Prop_Data, "m_ModelName", strPlayerModel, sizeof(strPlayerModel));
	static char strEnemyModel[128];
	GetEntPropString(iDisguisedTarget, Prop_Data, "m_ModelName", strEnemyModel, sizeof(strEnemyModel));

	int iPlayerModel = PrecacheModel(strPlayerModel, true);
	int iEnemyModel = PrecacheModel(strEnemyModel, true);

	// Make the spy look normal to their team
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", iPlayerModel, _, g_teamOverrides[iTeam]);

	// Make the spy look different to the other team, should the disguise class be matching the disguise target's class
	SetEntProp(client, Prop_Send, "m_nModelIndexOverrides", iEnemyModel, _, g_teamOverrides[iEnemyTeam]);
}
#endif

// True if the condition was removed.
bool Utils_RemoveCond(int client, TFCond cond)
{
	if(TF2_IsPlayerInCondition(client, cond))
	{
		TF2_RemoveCondition(client, cond);
		return true;
	}
	return false;
}

void Utils_GetBossSpecial(int boss=0, char[] buffer, int bufferLength, int client=0, int pack=-1)
{
	if(boss < 0)
		return;

	Handle kv;
	if(pack < 0)
	{
		kv = FF2CharSetInfo.BossKV[boss];
	}
	else
	{
		kv = FF2BossPacks[boss][pack];
	}

	if(!kv)
		return;

	static char name[64], language[20];
	GetLanguageInfo(Utils_IsValidClient(client) ? GetClientLanguage(client) : GetServerLanguage(), language, sizeof(language), name, sizeof(name));
	Format(language, sizeof(language), "name_%s", language);

	KvRewind(kv);
	KvGetString(kv, language, name, bufferLength);
	if(!name[0])
	{
		if(Utils_IsValidClient(client))	// Don't check server's lanuage twice
		{
			GetLanguageInfo(GetServerLanguage(), language, 8, name, 8);
			Format(language, sizeof(language), "name_%s", language);
			KvGetString(kv, language, name, bufferLength);
		}

		if(!name[0])
			KvGetString(kv, "name", name, bufferLength, "=Failed name=");
	}
	strcopy(buffer, bufferLength, name);
}

int Utils_GetClientCloakIndex(int client)
{
	if(!Utils_IsValidClient(client, false))
		return -1;

	int weapon = GetPlayerWeaponSlot(client, 4);
	if(!IsValidEntity(weapon))
		return -1;

	static char classname[64];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if(strncmp(classname, "tf_wea", 6, false))
		return -1;

	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

int Utils_SpawnSmallHealthPackAt(int client, int team=0, int attacker)
{
	if(!Utils_IsValidClient(client, false) || !IsPlayerAlive(client))
		return;

	int healthpack = CreateEntityByName("item_healthkit_small");
	float position[3];
	GetClientAbsOrigin(client, position);
	position[2] += 20.0;
	if(IsValidEntity(healthpack))
	{
		DispatchKeyValue(healthpack, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(healthpack);
		SetEntProp(healthpack, Prop_Send, "m_iTeamNum", team, 4);
		SetEntityMoveType(healthpack, MOVETYPE_VPHYSICS);
		float velocity[3];//={float(GetRandomInt(-10, 10)), float(GetRandomInt(-10, 10)), 50.0};  //Q_Q
		velocity[0] = float(GetRandomInt(-10, 10));
		velocity[1] = float(GetRandomInt(-10, 10));
		velocity[2] = 50.0;  //I did this because setting it on the creation of the vel variable was creating a compiler error for me.
		TeleportEntity(healthpack, position, NULL_VECTOR, velocity);
		SetEntPropEnt(healthpack, Prop_Send, "m_hOwnerEntity", attacker);
	}
}

void Utils_IncrementHeadCount(int client)
{
	if(!TF2_IsPlayerInCondition(client, TFCond_DemoBuff))
		TF2_AddCondition(client, TFCond_DemoBuff, -1.0);

	int decapitations = GetEntProp(client, Prop_Send, "m_iDecapitations");
	int health = GetClientHealth(client);
	SetEntProp(client, Prop_Send, "m_iDecapitations", decapitations+1);
	SetEntityHealth(client, health+15);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.01);
}

int Utils_FindTeleOwner(int client)
{
	if(!Utils_IsValidClient(client) || !IsPlayerAlive(client))
		return -1;

	int teleporter = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	static char classname[32];
	if(IsValidEntity(teleporter) && GetEntityClassname(teleporter, classname, sizeof(classname)) && StrEqual(classname, "obj_teleporter", false))
	{
		int owner = GetEntPropEnt(teleporter, Prop_Send, "m_hBuilder");
		if(Utils_IsValidClient(owner, false))
			return owner;
	}
	return -1;
}

bool Utils_IsPlayerCritBuffed(int client)
{
	return (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) || TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) || TF2_IsPlayerInCondition(client, view_as<TFCond>(34)) || TF2_IsPlayerInCondition(client, view_as<TFCond>(35)) || TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) || TF2_IsPlayerInCondition(client, TFCond_CritOnWin) || TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) || TF2_IsPlayerInCondition(client, TFCond_CritOnKill) || TF2_IsPlayerInCondition(client, TFCond_CritMmmph));
}

int Utils_GetClientWithMostQueuePoints(bool[] omit, int enemyTeam=4, bool ignorePrefs=true)
{
	int winner;
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client) && (!FF2Globals.Enabled3 || !CheckCommandAccess(client, "ff2_boss", 0, true) || (CanBossVs[client]<2 && CanBossTeam[client]!=enemyTeam) || !ignorePrefs) && FF2PlayerCookie[client].QueuePoints>=FF2PlayerCookie[winner].QueuePoints && !omit[client])
		{
			if(ConVars.ToggleBoss.BoolValue && view_as<int>(FF2PlayerCookie[client].Boss)>1)	// Skip clients who have disabled being able to be a boss
				continue;

			if(FF2GlobalsCvars.SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				winner=client;
		}
	}

	if(!winner)	// Ignore the boss toggle pref if we can't find available clients
	{
		if(!ignorePrefs)
			return -1;

		for(int client=1; client<MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && (!FF2Globals.Enabled3 || !CheckCommandAccess(client, "ff2_boss", 0, true) || (CanBossVs[client]<2 && CanBossTeam[client]!=enemyTeam)) && !omit[client])
			{
				if(FF2GlobalsCvars.SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
					winner=client;
			}
		}
	}

	if(!winner)	// Ignore players who have a boss who can't play Boss vs Boss
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && !omit[client])
			{
				if(ConVars.ToggleBoss.BoolValue && view_as<int>(FF2PlayerCookie[client].Boss)>1)	// Skip clients who have disabled being able to be a boss
					continue;

				if(FF2GlobalsCvars.SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = 0;
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					IgnoreValid[client] = false;
					winner = client;
				}
			}
		}
	}

	if(!winner)	// Ignore everything!
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && !omit[client])
			{
				if(FF2GlobalsCvars.SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = 0;
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					IgnoreValid[client] = false;
					winner = client;
				}
			}
		}
	}
	return winner;
}

int Utils_GetClientWithoutBlacklist(bool[] omit, int enemyTeam=4)
{
	int winner;
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client) && (!FF2Globals.Enabled3 || !CheckCommandAccess(client, "ff2_boss", 0, true) || (!CanBossVs[client] && CanBossTeam[client]!=enemyTeam)) && FF2PlayerCookie[client].QueuePoints>=FF2PlayerCookie[winner].QueuePoints && !omit[client])
		{
			if(ConVars.ToggleBoss.BoolValue && view_as<int>(FF2PlayerCookie[client].Boss)>1)	// Skip clients who have disabled being able to be a boss
				continue;

			if(FF2GlobalsCvars.SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				winner=client;
		}
	}

	if(!winner)	// Ignore the boss toggle pref if we can't find available clients
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && (!FF2Globals.Enabled3 || !CheckCommandAccess(client, "ff2_boss", 0, true) || (!CanBossVs[client] && CanBossTeam[client]!=enemyTeam)) && !omit[client])
			{
				if(FF2GlobalsCvars.SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
					winner=client;
			}
		}
	}

	if(!winner)	// Ignore players who have a boss who can't play Boss vs Boss
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && !omit[client])
			{
				if(ConVars.ToggleBoss.BoolValue && view_as<int>(FF2PlayerCookie[client].Boss)>1)	// Skip clients who have disabled being able to be a boss
					continue;

				if(FF2GlobalsCvars.SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = 0;
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					IgnoreValid[client] = false;
					winner = client;
				}
			}
		}
	}

	if(!winner)	// Ignore everything!
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && !omit[client])
			{
				if(FF2GlobalsCvars.SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				{
					FPrintToChat(client, "%t", "boss_selection_reset");
					xIncoming[client][0] = 0;
					CanBossVs[client] = 0;
					CanBossTeam[client] = 0;
					IgnoreValid[client] = false;
					winner = client;
				}
			}
		}
	}
	return winner;
}

int Utils_GetRandomValidClient(bool[] omit)
{
	int companion;
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client) && !omit[client] && (FF2PlayerCookie[client].QueuePoints>=FF2PlayerCookie[companion].QueuePoints || (ConVars.DuoRandom.BoolValue && !GetRandomInt(0, RoundToCeil(MaxClients/5.0)))))
		{
			if(ConVars.ToggleBoss.BoolValue && view_as<int>(FF2PlayerCookie[client].Duo)>1)	// Skip clients who have disabled being able to be selected as a companion
				continue;

			if(ConVars.ToggleBoss.BoolValue && view_as<int>(FF2PlayerCookie[client].Boss)>1)	// Skip clients who have disabled being able to be a boss
				continue;

			if((FF2GlobalsCvars.SpecForceBoss && !ConVars.DuoRandom.BoolValue) || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
				companion=client;
		}
	}

	if(!companion)	// Ignore the companion toggle pref if we can't find available clients
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && !omit[client] && (FF2PlayerCookie[client].QueuePoints>=FF2PlayerCookie[companion].QueuePoints || (ConVars.DuoRandom.BoolValue && !GetRandomInt(0, RoundToCeil(MaxClients/5.0)))))
			{
				if(ConVars.ToggleBoss.BoolValue && view_as<int>(FF2PlayerCookie[client].Boss)>1) // Skip clients who have disabled being able to be a boss
					continue;

				if(FF2GlobalsCvars.SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
					companion=client;
			}
		}
	}

	if(!companion)	// Ignore the boss toggle pref if we can't find available clients
	{
		for(int client=1; client<MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && !omit[client] && (FF2PlayerCookie[client].QueuePoints>=FF2PlayerCookie[companion].QueuePoints || (ConVars.DuoRandom.BoolValue && !GetRandomInt(0, RoundToCeil(MaxClients/5.0)))))
			{
				if(FF2GlobalsCvars.SpecForceBoss || GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
					companion=client;
			}
		}
	}
	return companion;
}

int Utils_LastBossIndex()
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(!FF2BossInfo[client].Boss)
			return client-1;
	}
	return 0;
}

int Utils_GetBossIndex(int client)
{
	if(client>0 && client<=MaxClients)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(FF2BossInfo[boss].Boss == client)
				return boss;
		}
	}
	return -1;
}


bool Utils_IsFF2Map(const char[] mapName)
{
	if(FileExists("bNextMapToFF2"))
		return true;

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, MapCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, MapCFG);
		if(!FileExists(config))
		{
			LogToFile(FF2LogsPaths.Errors, "[Maps] Unable to find '%s'", MapCFG);
			return true;
		}
	}

	File file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogToFile(FF2LogsPaths.Errors, "[Maps] Error reading from '%s'", config);
		return true;
	}

	int tries;
	while(file.ReadLine(config, sizeof(config)))
	{
		tries++;
		if(tries >= 100)
		{
			LogToFile(FF2LogsPaths.Errors, "[Maps] An infinite loop occurred while trying to check the map");
			delete file;
			return true;
		}

		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(!StrContains(mapName, config, false) || !StrContains(config, "all", false))
		{
			delete file;
			return true;
		}
	}
	delete file;
	return false;
}

bool Utils_MapHasMusic(bool forceRecalc=false)  //SAAAAAARGE
{
	static bool hasMusic;
	static bool found;
	if(forceRecalc)
	{
		found = false;
		hasMusic = false;
	}

	if(!found)
	{
		int entity = -1;
		char name[64];
		while((entity=Utils_FindEntityByClassname2(entity, "info_target")) != -1)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(StrEqual(name, "hale_no_music", false))
			{
				//PrintToConsoleAll("Detected Map Music");
				hasMusic = true;
			}
		}
		found = true;
	}
	return hasMusic;
}


void Utils_CheckToChangeMapDoors()
{
	if(!FF2Globals.Enabled || !FF2Globals.Enabled2)
		return;

	char config[PLATFORM_MAX_PATH];
	FF2Globals.CheckDoors = false;
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, DoorCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, DoorCFG);
		if(!FileExists(config))
		{
			LogToFile(FF2LogsPaths.Errors, "[Doors] Unable to find '%s'", DoorCFG);
			return;
		}
	}

	File file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogToFile(FF2LogsPaths.Errors, "[Doors] Error reading from '%s'", config);
		return;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(StrContains(FF2Globals.CurrentMap, config, false)!=-1 || !StrContains(config, "all", false))
		{
			delete file;
			FF2Globals.CheckDoors = true;
			return;
		}
	}
	delete file;
}

void Utils_CheckToTeleportToSpawn()
{
	char config[PLATFORM_MAX_PATH];
	GetCurrentMap(FF2Globals.CurrentMap, sizeof(FF2Globals.CurrentMap));
	FF2Globals.SpawnTeleOnTriggerHurt = false;
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, SpawnTeleportCFG);

	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, SpawnTeleportCFG);
		if(!FileExists(config))
		{
			LogToFile(FF2LogsPaths.Errors, "[TTS] Unable to find '%s'", SpawnTeleportCFG);
			return;
		}
	}

	File file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogToFile(FF2LogsPaths.Errors, "[TTS] Error reading from '%s'", SpawnTeleportCFG);
		return;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(StrContains(FF2Globals.CurrentMap, config, false)>=0 || !StrContains(config, "all", false))
		{
			FF2Globals.SpawnTeleOnTriggerHurt = true;
			delete file;
			return;
		}
	}
	delete file;

	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, SpawnTeleportBlacklistCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, SpawnTeleportBlacklistCFG);
		if(!FileExists(config))
		{
			LogToFile(FF2LogsPaths.Errors, "[TTS] Unable to find '%s'", SpawnTeleportBlacklistCFG);
			return;
		}
	}

	file = OpenFile(config, "r");
	if(file == INVALID_HANDLE)
	{
		LogToFile(FF2LogsPaths.Errors, "[TTS] Error reading from '%s'", SpawnTeleportBlacklistCFG);
		return;
	}

	while(!file.EndOfFile() && file.ReadLine(config, sizeof(config)))
	{
		strcopy(config, strlen(config)-1, config);
		if(!strncmp(config, "//", 2, false))
			continue;

		if(StrContains(FF2Globals.CurrentMap, config, false)>=0 || !StrContains(config, "all", false))
		{
			FF2Globals.SpawnTeleOnTriggerHurt = false;
			break;
		}
	}
	delete file;
}


 void Utils_ProcessDirectory(const char[] directory, const char[] current, const char[] config, int pack)
{
	char file[PLATFORM_MAX_PATH];
	FormatEx(file, PLATFORM_MAX_PATH, "%s\\%s", directory, current);
	if(!DirExists(file))
		return;

	DirectoryListing listing = OpenDirectory(file);
	if(listing == null)
		return;

	FileType type;
	while((((pack<0 && FF2CharSetInfo.SizeOfSpecials<MAXSPECIALS) || (pack>=0 && FF2Packs_NumBosses[pack]<MAXSPECIALS))) && listing.GetNext(file, PLATFORM_MAX_PATH, type))
	{
		if(type == FileType_File)
		{
			if(ReplaceString(file, PLATFORM_MAX_PATH, ".cfg", "", false) != 1)
				continue;

			if(current[0])
			{
				Format(file, PLATFORM_MAX_PATH, "%s\\%s", current, file);
				ReplaceString(file, PLATFORM_MAX_PATH, "\\", "/");
			}

			if(!StrContains(file, config))
			{
				if(pack < 0)
				{
					LoadCharacter(file);
				}
				else
				{
					LoadSideCharacter(file, pack);
				}
			}
			continue;
		}

		if(type!=FileType_Directory || !StrContains(file, "."))
			continue;

		if(current[0])
		{
			Format(file, PLATFORM_MAX_PATH, "%s/%s", current, file);
			Utils_ProcessDirectory(directory, file, config, pack);
		}
		else
		{
			Utils_ProcessDirectory(directory, file, config, pack);
		}
	}
	delete listing;
}


bool Utils_IsBoss(int client)
{
	if(Utils_IsValidClient(client) && FF2Globals.Enabled)
	{
		for(int boss; boss<=MaxClients; boss++)
		{
			if(FF2BossInfo[boss].Boss == client)
				return true;
		}
	}
	return false;
}

void Utils_EquipBoss(int boss)
{
	int client = FF2BossInfo[boss].Boss;
	Utils_DoOverlay(client, "");
	TF2_RemoveAllWeapons(client);
	char attributes[256], key[10];
	static char classname[64], wModel[PLATFORM_MAX_PATH];
	int weapon, strangerank, weaponlevel, index, strangekills;
	bool strangewep, overridewep;
	static int rgba[4];
	for(int i=1; ; i++)
	{
		KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
		FormatEx(key, sizeof(key), "weapon%i", i);
		if(KvJumpToKey(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key))
		{
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "name", classname, sizeof(classname));
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "attributes", attributes, sizeof(attributes));
			strangerank = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "rank", 21);
			weaponlevel = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "level", -1);
			index = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "index");
			overridewep = view_as<bool>(KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "override"));
			strangekills = -1;
			strangewep = true;
			switch(strangerank)
			{
				case 0:
				{
					strangekills = GetRandomInt(0, 9);
				}
				case 1:
				{
					strangekills = GetRandomInt(10, 24);
				}
				case 2:
				{
					strangekills = GetRandomInt(25, 44);
				}
				case 3:
				{
					strangekills = GetRandomInt(45, 69);
				}
				case 4:
				{
					strangekills = GetRandomInt(70, 99);
				}
				case 5:
				{
					strangekills = GetRandomInt(100, 134);
				}
				case 6:
				{
					strangekills = GetRandomInt(135, 174);
				}
				case 7:
				{
					strangekills = GetRandomInt(175, 224);
				}
				case 8:
				{
					strangekills = GetRandomInt(225, 274);
				}
				case 9:
				{
					strangekills = GetRandomInt(275, 349);
				}
				case 10:
				{
					strangekills = GetRandomInt(350, 499);
				}
				case 11:
				{
					if(index == 656)	// Holiday Punch is different
					{
						strangekills = GetRandomInt(500, 748);
					}
					else
					{
						strangekills = GetRandomInt(500, 749);
					}
				}
				case 12:
				{
					if(index == 656)
					{
						strangekills = 749;
					}
					else
					{
						strangekills = GetRandomInt(750, 998);
					}
				}
				case 13:
				{
					if(index == 656)
					{
						strangekills = GetRandomInt(750, 999);
					}
					else
					{
						strangekills = 999;
					}
				}
				case 14:
				{
					strangekills = GetRandomInt(1000, 1499);
				}
				case 15:
				{
					strangekills = GetRandomInt(1500, 2499);
				}
				case 16:
				{
					strangekills = GetRandomInt(2500, 4999);
				}
				case 17:
				{
					strangekills = GetRandomInt(5000, 7499);
				}
				case 18:
				{
					if(index == 656)
					{
						strangekills = GetRandomInt(7500, 7922);
					}
					else
					{
						strangekills = GetRandomInt(7500, 7615);
					}
				}
				case 19:
				{
					if(index == 656)
					{
						strangekills = GetRandomInt(7923, 8499);
					}
					else
					{
						strangekills = GetRandomInt(7616, 8499);
					}
				}
				case 20:
				{
					strangekills = GetRandomInt(8500, 9999);
				}
				default:
				{
					strangekills = GetRandomInt(0, 9999);
					if(!ConVars.StrangeWep.BoolValue || weaponlevel!=-1 || overridewep)
						strangewep = false;
				}
			}

			if(weaponlevel < 0)
				weaponlevel = 101;

			#if defined _tf2attributes_included
			if(!FF2Globals.TF2Attrib && strangewep)
			#else
			if(strangewep)
			#endif
			{
				if(attributes[0])
				{
					if(overridewep)
					{
						Format(attributes, sizeof(attributes), "214 ; %d ; %s", strangekills, attributes);
					}
					else
					{
						Format(attributes, sizeof(attributes), "%s ; 68 ; %i ; 214 ; %d ; %s", FF2GlobalsCvars.Attributes, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, strangekills, attributes);
					}
				}
				else
				{
					if(overridewep)
					{
						FormatEx(attributes, sizeof(attributes), "214 ; %d", strangekills);
					}
					else
					{
						FormatEx(attributes, sizeof(attributes), "%s ; 68 ; %i ; 214 ; %d", FF2GlobalsCvars.Attributes, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, strangekills);
					}
				}
			}
			else if(!overridewep)
			{
				if(attributes[0])
				{
					Format(attributes, sizeof(attributes), "%s ; 68 ; %i ; %s", FF2GlobalsCvars.Attributes, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2, attributes);
				}
				else
				{
					FormatEx(attributes, sizeof(attributes), "%s ; 68 ; %i", FF2GlobalsCvars.Attributes, TF2_GetPlayerClass(client)==TFClass_Scout ? 1 : 2);
				}
			}

			weapon = FF2_SpawnWeapon(client, classname, index, weaponlevel, KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "quality", FF2GlobalsCvars.WeaponQuality), attributes);
			if(weapon == -1)
				continue;

			#if defined _tf2attributes_included
			if(FF2Globals.TF2Attrib && strangewep)
				TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(strangekills));
			#endif

			FF2_SetAmmo(client, weapon, KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "ammo", -1), KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "clip", -1));
			if(StrEqual(classname, "tf_weapon_builder", false) && index!=735)  //PDA, normal sapper
			{
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
			}
			else if(StrEqual(classname, "tf_weapon_sapper", false) || index==735)  //Sappers
			{
				SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
				SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
				SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
			}

			if(KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "show"))
			{
				KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "worldmodel", wModel, sizeof(wModel));
				if(wModel[0])
					Utils_ConfigureWorldModelOverride(weapon, wModel);

				rgba[0] = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "alpha", 255);
				rgba[1] = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "red", 255);
				rgba[2] = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "green", 255);
				rgba[3] = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "blue", 255);

				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, rgba[1], rgba[2], rgba[3], rgba[0]);
			}
			else
			{
				SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
			}

			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
		}
		else
		{
			break;
		}
	}

	if(FF2ModsInfo.SDK_EquipWearable != null)
	{
		for(int i=1; ; i++)
		{
			KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
			FormatEx(key, sizeof(key), "wearable%i", i);
			if(KvJumpToKey(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key))
			{
				KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "name", classname, sizeof(classname));
				KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "attributes", attributes, sizeof(attributes));
				strangerank = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "rank", 21);
				weaponlevel = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "level", -1);
				index = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "index");
				strangekills = -1;
				strangewep = true;
				switch(strangerank)
				{
					case 0:
					{
						if(index==133 || index==444 || index==655)	// Gunboats, Mantreads, or Spirit of Giving
						{
							strangekills = 0;
						}
						else
						{
							strangekills = GetRandomInt(0, 14);
						}
					}
					case 1:
					{
						if(index==133 || index==444 || index==655)	// Gunboats, Mantreads, or Spirit of Giving
						{
							strangekills = GetRandomInt(1, 2);
						}
						else
						{
							strangekills = GetRandomInt(15, 29);
						}
					}
					case 2:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(3, 4);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(3, 6);
						}
						else
						{
							strangekills = GetRandomInt(30, 49);
						}
					}
					case 3:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(5, 6);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(7, 11);
						}
						else
						{
							strangekills = GetRandomInt(50, 74);
						}
					}
					case 4:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(7, 9);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(12, 19);
						}
						else
						{
							strangekills = GetRandomInt(75, 99);
						}
					}
					case 5:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(10, 13);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(20, 27);
						}
						else
						{
							strangekills =  GetRandomInt(100, 134);
						}
					}
					case 6:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(14, 17);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(28, 36);
						}
						else
						{
							strangekills = GetRandomInt(135, 174);
						}
					}
					case 7:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(18, 22);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(37, 46);
						}
						else
						{
							strangekills = GetRandomInt(175, 249);
						}
					}
					case 8:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(23, 27);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(47, 56);
						}
						else
						{
							strangekills = GetRandomInt(250, 374);
						}
					}
					case 9:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(28, 34);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(57, 67);
						}
						else
						{
							strangekills = GetRandomInt(375, 499);
						}
					}
					case 10:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(35, 49);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(68, 78);
						}
						else
						{
							strangekills = GetRandomInt(500, 724);
						}
					}
					case 11:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(50, 74);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(79, 90);
						}
						else
						{
							strangekills = GetRandomInt(725, 999);
						}
					}
					case 12:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(75, 98);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(91, 103);
						}
						else
						{
							strangekills = GetRandomInt(1000, 1499);
						}
					}
					case 13:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = 99;
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(104, 119);
						}
						else
						{
							strangekills = GetRandomInt(1500, 1999);
						}
					}
					case 14:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(100, 149);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(120, 137);
						}
						else
						{
							strangekills = GetRandomInt(2000, 2749);
						}
					}
					case 15:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(150, 249);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(138, 157);
						}
						else
						{
							strangekills = GetRandomInt(2750, 3999);
						}
					}
					case 16:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(250, 499);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(158, 178);
						}
						else
						{
							strangekills = GetRandomInt(4000, 5499);
						}
					}
					case 17:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(500, 749);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(179, 209);
						}
						else
						{
							strangekills = GetRandomInt(5500, 7499);
						}
					}
					case 18:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(750, 783);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(210, 249);
						}
						else
						{
							strangekills = GetRandomInt(7500, 9999);
						}
					}
					case 19:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(784, 849);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(250, 299);
						}
						else
						{
							strangekills = GetRandomInt(10000, 14999);
						}
					}
					case 20:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(850, 999);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(300, 399);
						}
						else
						{
							strangekills = GetRandomInt(15000, 19999);
						}
					}
					default:
					{
						if(index==133 || index==444)	// Gunboats or Mantreads
						{
							strangekills = GetRandomInt(0, 999);
						}
						else if(index==655)	// Spirit of Giving
						{
							strangekills = GetRandomInt(0, 399);
						}
						else
						{
							strangekills = GetRandomInt(0, 19999);
						}

						if(!ConVars.StrangeWep.BoolValue || weaponlevel!=-1)
							strangewep = false;
					}
				}

				if(weaponlevel < 0)
					weaponlevel = 101;

				#if defined _tf2attributes_included
				if(!FF2Globals.TF2Attrib && strangewep)
				#else
				if(strangewep)
				#endif
				{
					if(attributes[0])
					{
						Format(attributes, sizeof(attributes), "214 ; %d ; %s", strangekills, attributes);
					}
					else
					{
						FormatEx(attributes, sizeof(attributes), "214 ; %d", strangekills);
					}
				}

				weapon = TF2_CreateAndEquipWearable(client, classname, index, weaponlevel, KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "quality", FF2GlobalsCvars.WeaponQuality), attributes);
				if(!IsValidEntity(weapon))
					continue;

				#if defined _tf2attributes_included
				if(FF2Globals.TF2Attrib && strangewep)
					TF2Attrib_SetByDefIndex(weapon, 214, view_as<float>(strangekills));
				#endif

				if(KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "show", 1))
				{
					KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "worldmodel", wModel, sizeof(wModel));
					if(wModel[0])
						Utils_ConfigureWorldModelOverride(weapon, wModel, true);

					rgba[0] = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "alpha", 255);
					rgba[1] = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "red", 255);
					rgba[2] = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "green", 255);
					rgba[3] = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "blue", 255);

					SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
					SetEntityRenderColor(weapon, rgba[1], rgba[2], rgba[3], rgba[0]);
				}
				else
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flModelScale", 0.001);
					SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
					SetEntProp(weapon, Prop_Send, "m_nModelIndexOverrides", -1, _, 0);
				}
			}
			else
			{
				break;
			}
		}
	}

	KvGoBack(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
	TFClassType class = KvGetClass(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "class");
	FF2BossInfo[boss].HasEquipped = true;
	if(TF2_GetPlayerClass(client) != class)
		TF2_SetPlayerClass(client, class, _, !GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass") ? true : false);
}

bool Utils_ConfigureWorldModelOverride(int entity, const char[] model, bool wearable=false)
{
	if(!FileExists(model, true))
		return false;

	int modelIndex = PrecacheModel(model);
	SetEntProp(entity, Prop_Send, "m_nModelIndex", modelIndex);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 1);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 2);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, 3);
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", (wearable ? GetEntProp(entity, Prop_Send, "m_nModelIndex") : GetEntProp(entity, Prop_Send, "m_iWorldModelIndex")), _, 0);
	return true;
}

stock int TF2_CreateAndEquipWearable(int client, const char[] classname, int index, int level, int quality, char[] attributes)
{
	int wearable;
	if(classname[0])
	{
		wearable = CreateEntityByName(classname);
	}
	else
	{
		wearable = CreateEntityByName("tf_wearable");
	}

	if(!IsValidEntity(wearable))
		return -1;

	SetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex", index);
	SetEntProp(wearable, Prop_Send, "m_bInitialized", 1);
		
	// Allow quality / level override by updating through the offset.
	SetEntData(wearable, GetEntSendPropOffs(wearable, "m_iEntityQuality", true), quality);
	SetEntData(wearable, GetEntSendPropOffs(wearable, "m_iEntityLevel", true), level);

	SetEntProp(wearable, Prop_Send, "m_iEntityQuality", quality);
	SetEntProp(wearable, Prop_Send, "m_iEntityLevel", level);

	#if defined _tf2attributes_included
	if(attributes[0] && FF2Globals.TF2Attrib)
	{
		char atts[32][32];
		int count = ExplodeString(attributes, " ; ", atts, 32, 32);
		if(count > 1)
		{
			for(int i; i<count; i+=2)
			{
				TF2Attrib_SetByDefIndex(wearable, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			}
		}
	}
	#endif
		
	DispatchSpawn(wearable);
	SDK_EquipWearable(client, wearable);
	return wearable;
}

void SDK_EquipWearable(int client, int wearable)
{
	if(FF2ModsInfo.SDK_EquipWearable != null)
		SDKCall(FF2ModsInfo.SDK_EquipWearable, client, wearable);
}

/*
    Returns the the TeamNum of an entity.
    Works for both clients and things like healthpacks.
    Returns -1 if the entity doesn't have the m_iTeamNum prop.
    Utils_GetEntityTeamNum() doesn't always return properly when tf_arena_use_queue is set to 0
*/

TFTeam Utils_GetEntityTeamNum(int iEnt)
{
	return view_as<TFTeam>(GetEntProp(iEnt, Prop_Send, "m_iTeamNum"));
}

void Utils_SetEntityTeamNum(int iEnt, int iTeam)
{
	SetEntProp(iEnt, Prop_Send, "m_iTeamNum", iTeam);
}


/*
    Returns 0 if no client was found.
*/
int Utils_GetClosestPlayerTo(int iEnt, TFTeam iTeam=TFTeam_Unassigned)
{
	int iBest;
	float flDist, flTemp, vLoc[3], vPos[3];
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vLoc);
	for(int iClient=1; iClient<=MaxClients; iClient++)
	{
		if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
		{
			if(iTeam>TFTeam_Unassigned && Utils_GetEntityTeamNum(iClient)!=iTeam)
				continue;

			GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", vPos);
			flTemp = GetVectorDistance(vLoc, vPos);
			if(!iBest || flTemp<flDist)
			{
				flDist = flTemp;
				iBest = iClient;
			}
		}
	}
	return iBest;
}

/*
    Teleports one entity to another.
    Doesn't necessarily have to be players.
    Returns true if a player teleported to a ducking player
*/
bool Utils_TeleMeToYou(int iMe, int iYou, bool bAngles=false)
{
	float vPos[3], vAng[3];
	vAng = NULL_VECTOR;
	GetEntPropVector(iYou, Prop_Send, "m_vecOrigin", vPos);
	if(bAngles)
		GetEntPropVector(iYou, Prop_Send, "m_angRotation", vAng);

	bool bDucked = false;
	if(Utils_IsValidClient(iMe) && Utils_IsValidClient(iYou) && GetEntProp(iYou, Prop_Send, "m_bDucked"))
	{
		float vCollisionVec[3];
		vCollisionVec[0] = 24.0;
		vCollisionVec[1] = 24.0;
		vCollisionVec[2] = 62.0;
		SetEntPropVector(iMe, Prop_Send, "m_vecMaxs", vCollisionVec);
		SetEntProp(iMe, Prop_Send, "m_bDucked", 1);
		SetEntityFlags(iMe, GetEntityFlags(iMe)|FL_DUCKING);
		bDucked = true;
	}
	TeleportEntity(iMe, vPos, vAng, NULL_VECTOR);
	return bDucked;
}

int Utils_GetRandBlockCell(ArrayList hArray, int &iSaveIndex, int iBlock=0, bool bAsChar=false, int iDefault=0)
{
	int iSize = hArray.Length;
	if(iSize > 0)
	{
		iSaveIndex = GetRandomInt(0, iSize - 1);
		return hArray.Get(iSaveIndex, iBlock, bAsChar);
	}
	iSaveIndex = -1;
	return iDefault;
}

// Get a random value while ignoring the save index.
int GetRandBlockCellEx(ArrayList hArray, int iBlock=0, bool bAsChar=false, int iDefault=0)
{
	int iIndex;
	return Utils_GetRandBlockCell(hArray, iIndex, iBlock, bAsChar, iDefault);
}


int Utils_FindSentry(int client)
{
	int entity = -1;
	while((entity=Utils_FindEntityByClassname2(entity, "obj_sentrygun")) != -1)
	{
		if(GetEntPropEnt(entity, Prop_Send, "m_hBuilder") == client)
			return entity;
	}
	return -1;
}

int Utils_OnlyScoutsLeft(int team)
{
	int scouts;
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client)!=team)
		{
			if(TF2_GetPlayerClass(client)==TFClass_Scout || Utils_IsBoss(client))
			{
				scouts++;
			}
			else
			{
				return 0;
			}
		}
	}
	return scouts;
}

int Utils_GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon)) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
}


void Utils_SetClientGlow(int client, float time1, float time2=-1.0)
{
	if(Utils_IsValidClient(client))
	{
		FF2PlayerInfo[client].GlowTimer += time1;
		if(time2 >= 0)
			FF2PlayerInfo[client].GlowTimer = time2;

		if(FF2PlayerInfo[client].GlowTimer <= 0.0)
		{
			FF2PlayerInfo[client].GlowTimer = 0.0;
			if(FF2PlayerInfo[client].IsGlowing)	// Prevent removing outlines from other plugins
			{
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
				FF2PlayerInfo[client].IsGlowing = false;
			}
		}
		else if(Utils_CheckRoundState() == 1)
		{
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
			FF2PlayerInfo[client].IsGlowing = true;
		}
	}
}

bool Utils_FindCharArg(FF2QueryData data, const char[] args, char[] res, int maxlen)
{
	KeyValues kv;

	const int size_of_key = 24;

	char abkey[size_of_key];
	char[] key = new char[132];
	FF2Cache.FormatToKey(key, data.current_plugin_name, data.current_ability_name);
	FF2Cache actual = view_as<FF2Cache>(data.cache);

	kv = FF2CharSetInfo.BossKV[data.char_idx];
	kv.Rewind();

	if (actual.GetString(key, abkey, sizeof(abkey)))
	{
		if (!abkey[0]) {
			// lookup failed, return default value.
			return false;
		}

		kv.JumpToKey(abkey);
		kv.GetString(args, res, maxlen);
		
		return res[0] != '\0';
	}

	for (int ab = 1; ab <= MAXRANDOMS; ab++)
	{
		FormatEx(abkey, sizeof(abkey), "ability%i", ab);
		if (!kv.JumpToKey(abkey)) {
			continue;
		}

		kv.GetString("name", key, 64);
		if (!StrEqual(key, data.current_ability_name)) {
			kv.GoBack();
			continue;
		}

		kv.GetString("plugin_name", key, 64);
		if (!StrEqual(key, data.current_plugin_name) && data.current_plugin_name[0]) {
			kv.GoBack();
			continue;
		}

		kv.GetString(args, res, maxlen);

		FF2Cache.FormatToKey(key, data.current_plugin_name, data.current_ability_name);
		actual.SetString(key, abkey);

		return res[0] != '\0';
	}

	FF2Cache.FormatToKey(key, data.current_plugin_name, data.current_ability_name);
	actual.SetString(key, "");
	return false;
}



int Utils_FindEntityByClassname2(int startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

void Utils_SwitchEntityTeams(char[] entityname, int bossteam, int otherteam)
{
	int ent = -1;
	while((ent=Utils_FindEntityByClassname2(ent, entityname)) != -1)
	{
		Utils_SetEntityTeamNum(ent, view_as<int>(Utils_GetEntityTeamNum(ent))==otherteam ? bossteam : otherteam);
	}
}

void Utils_SwitchTeams(int bossteam, int otherteam, bool respawn)
{
	SetTeamScore(bossteam, GetTeamScore(bossteam));
	SetTeamScore(otherteam, GetTeamScore(otherteam));
	FF2Globals.OtherTeam = otherteam;
	FF2Globals.BossTeam = bossteam;

	if(FF2Globals.Enabled)
	{
		if(bossteam==view_as<int>(TFTeam_Red) && otherteam==view_as<int>(TFTeam_Blue))
		{
			Utils_SwitchEntityTeams("info_player_teamspawn", bossteam, otherteam);
			Utils_SwitchEntityTeams("obj_sentrygun", bossteam, otherteam);
			Utils_SwitchEntityTeams("obj_dispenser", bossteam, otherteam);
			Utils_SwitchEntityTeams("obj_teleporter", bossteam, otherteam);
			Utils_SwitchEntityTeams("filter_activator_tfteam", bossteam, otherteam);

			if(respawn)
			{
				for(int client=1; client<=MaxClients; client++)
				{
					if(!Utils_IsValidClient(client) || GetClientTeam(client)<=view_as<int>(TFTeam_Spectator) || TF2_GetPlayerClass(client)==TFClass_Unknown)
						continue;

					TF2_RespawnPlayer(client);
				}
			}
		}
	}
}

void Utils_RemoveShield(int client, int attacker)
{
	if(IsValidEntity(FF2PlayerInfo[client].EntShield))
	{
		TF2_RemoveWearable(client, FF2PlayerInfo[client].EntShield);
		EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
		EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
		if(ConVars.ShieldType.IntValue == 3)
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 1.0);
		}
		else
		{
			EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
			EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, _, _, false);
		}
	}

	FF2PlayerInfo[client].ShieldHP = 0.0;
	FF2PlayerInfo[client].EntShield = 0;
}

int Utils_CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
			return -1;

		case RoundState_StartGame, RoundState_Preround:
			return 0;

		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
			return 1;
	}
	return 2;
}



int Utils_GetHealingTarget(int client, bool checkgun=false)
{
	int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(!checkgun)
	{
		if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
			return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");

		return -1;
	}

	if(IsValidEntity(medigun))
	{
		static char classname[64];
		GetEntityClassname(medigun, classname, sizeof(classname));
		if(StrEqual(classname, "tf_weapon_medigun", false))
		{
			if(GetEntProp(medigun, Prop_Send, "m_bHealing"))
				return GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
		}
	}
	return -1;
}

void Utils_ForceTeamWin(int team)
{
	static char temp[PLATFORM_MAX_PATH];
	GetCurrentMap(temp, sizeof(temp));
	if(!temp[0])
		return;

	int entity = Utils_FindEntityByClassname2(-1, "team_control_point_master");
	if(!IsValidEntity(entity))
	{
		entity = CreateEntityByName("team_control_point_master");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(entity, "SetWinner");
}

void Utils_EndBossRound()
{
	if(!ConVars.CountdownResult.BoolValue)
	{
		for(int client=1; client<=MaxClients; client++)  //Thx MasterOfTheXP
		{
			if(IsClientInGame(client) && IsPlayerAlive(client))
				ForcePlayerSuicide(client);
		}
	}
	else
	{
		Utils_ForceTeamWin(0);  //Stalemate
	}
}

void Utils_AssignTeam(int client, int team)
{
	if(!GetEntProp(client, Prop_Send, "m_iDesiredPlayerClass"))  //Living spectator check: 0 means that no class is selected
	{
		//PrintToConsoleAll("%N does not have a desired class", client);
		if(Utils_IsBoss(client))
		{
			SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", view_as<int>(KvGetClass(FF2CharSetInfo.BossKV[FF2BossInfo[Utils_GetBossIndex(client)].Special], "class")));  //So we assign one to prevent living spectators
		}
		/*else
		{
			PrintToConsoleAll("%N was not a boss and did not have a desired class", client);
		}*/
	}

	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);

	if(GetEntProp(client, Prop_Send, "m_iObserverMode") && IsPlayerAlive(client))  //Welp
	{
		//PrintToConsoleAll("%N is a living spectator", client);
		if(Utils_IsBoss(client))
		{
			TF2_SetPlayerClass(client, KvGetClass(FF2CharSetInfo.BossKV[FF2BossInfo[Utils_GetBossIndex(client)].Special], "class"));
		}
		else
		{
			//PrintToConsoleAll("Additional information: %N was not a boss", client);
			TF2_SetPlayerClass(client, TFClass_Heavy);
		}
		TF2_RespawnPlayer(client);
	}
}

void Utils_RandomlyDisguise(int client)	//Original code was mecha's, but the original code is broken and this uses a better method now.
{
	if(Utils_IsValidClient(client) && IsPlayerAlive(client))
	{
		int disguiseTarget = -1;
		int team = GetClientTeam(client);

		ArrayList disguiseArray = new ArrayList();
		for(int clientcheck=1; clientcheck<=MaxClients; clientcheck++)
		{
			if(Utils_IsValidClient(clientcheck) && GetClientTeam(clientcheck)==team && clientcheck!=client)
				disguiseArray.Push(clientcheck);
		}

		if(disguiseArray.Length < 1)
		{
			disguiseTarget = client;
		}
		else
		{
			disguiseTarget = disguiseArray.Get(GetRandomInt(0, disguiseArray.Length-1));
			if(!Utils_IsValidClient(disguiseTarget))
				disguiseTarget = client;
		}
		delete disguiseArray;

		if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			TF2_DisguisePlayer(client, view_as<TFTeam>(team), GetRandomInt(0, 1) ? TFClass_Medic : TFClass_Scout, disguiseTarget);
		}
		else
		{
			TF2_AddCondition(client, TFCond_Disguised, -1.0);
			SetEntProp(client, Prop_Send, "m_nDisguiseTeam", team);
			SetEntProp(client, Prop_Send, "m_nDisguiseClass", GetRandomInt(0, 1) ? view_as<int>(TFClass_Medic) : view_as<int>(TFClass_Scout));
			SetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex", disguiseTarget);
			SetEntProp(client, Prop_Send, "m_iDisguiseHealth", 200);
		}
	}
}

int Utils_SickleClimbWalls(int client, int weapon)	 //Credit to Mecha the Slag
{
	if(!Utils_IsValidClient(client) || (GetClientHealth(client)<=FF2GlobalsCvars.SniperClimpDmg))
		return;

	static char classname[64];
	float vecClientEyePos[3];
	float vecClientEyeAng[3];
	GetClientEyePosition(client, vecClientEyePos);   // Get the position of the player's eyes
	GetClientEyeAngles(client, vecClientEyeAng);	   // Get the angle the player is looking

	//Check for colliding entities
	TR_TraceRayFilter(vecClientEyePos, vecClientEyeAng, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if(!TR_DidHit(INVALID_HANDLE))
		return;

	int TRIndex = TR_GetEntityIndex(INVALID_HANDLE);
	GetEdictClassname(TRIndex, classname, sizeof(classname));
	if(!StrEqual(classname, "worldspawn"))
		return;

	float fNormal[3];
	TR_GetPlaneNormal(INVALID_HANDLE, fNormal);
	GetVectorAngles(fNormal, fNormal);

	if(fNormal[0]>=30.0 && fNormal[0]<=330.0)
		return;
	if(fNormal[0] <= -30.0)
		return;

	float pos[3];
	TR_GetEndPosition(pos);
	float distance = GetVectorDistance(vecClientEyePos, pos);

	if(distance >= 100.0)
		return;

	float fVelocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);

	fVelocity[2] = 600.0;

	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);

	SDKHooks_TakeDamage(client, client, client, FF2GlobalsCvars.SniperClimpDmg, DMG_CLUB, 0);

	if(!Utils_IsBoss(client))
		ClientCommand(client, "playgamesound \"%s\"", "player\\taunt_clip_spin.wav");

	RequestFrame(Timer_NoAttacking, EntIndexToEntRef(weapon));
}

int Utils_SetNextAttack(int weapon, float duration=0.0)
{
	if(weapon <= MaxClients)
		return;

	if(!IsValidEntity(weapon))
		return;

	float next = GetGameTime() + duration;
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", next);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", next);
}

static bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return (entity != data);
}


void EmitSoundToAllExcept(
    const char[] sample, 
    int entity=SOUND_FROM_PLAYER, 
    int channel=SNDCHAN_AUTO, 
    int level=SNDLEVEL_NORMAL, 
    int flags=SND_NOFLAGS,
    float volume=SNDVOL_NORMAL, 
    int pitch=SNDPITCH_NORMAL, 
    int speakerentity=-1, 
    const float origin[3]=NULL_VECTOR, 
    const float dir[3]=NULL_VECTOR, 
    bool updatePos=false, 
    float soundtime=0.0
)
{
	int[] clients = new int[MaxClients];
	int total;
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client))
		{
			if(FF2PlayerCookie[client].VoiceOn)
				clients[total++] = client;
		}
	}

	if(!total)
		return;

	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}

void EmitMusicToAllExcept(
    const char[] sample, 
    int entity=SOUND_FROM_PLAYER, 
    int channel=SNDCHAN_AUTO, 
    int level=SNDLEVEL_NORMAL, 
    int flags=SND_NOFLAGS, 
    float volume=SNDVOL_NORMAL, 
    int pitch=SNDPITCH_NORMAL, 
    int speakerentity=-1, 
    const float origin[3]=NULL_VECTOR, 
    const float dir[3]=NULL_VECTOR, 
    bool updatePos=false, 
    float soundtime=0.0
)
{
	int[] clients = new int[MaxClients];
	int total;
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client))
		{
			if(FF2PlayerCookie[client].MusicOn)
				clients[total++] = client;
		}
	}

	if(!total)
		return;

	EmitSound(clients, total, sample, entity, channel, level, flags, volume, pitch, speakerentity, origin, dir, updatePos, soundtime);
}


int Utils_SortQueueDesc(const int[] x, const int[] y, const int[][] array, Handle data)
{
	if(x[1] > y[1])
	{
		return -1;
	}
	else if(x[1] < y[1])
	{
		return 1;
	}
	return 0;
}


int CreateAttachedAnnotation(int client, int entity, bool effect=true, float time, const char[] buffer, any ...)
{
	static char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 6);
	ReplaceString(message, sizeof(message), "\n", "");  //Get rid of newlines

	Event event = CreateEvent("show_annotation");
	if(event == INVALID_HANDLE)
		return -1;

	event.SetInt("follow_entindex", entity);
	event.GetFloat("lifetime", time);
	event.SetInt("visibilityBitfield", (1<<client));
	event.SetBool("show_effect", effect);
	event.SetString("text", message);
	event.SetString("play_sound", "vo/null.wav");
	event.SetInt("id", entity); //What to enter inside? Need a way to identify annotations by entindex!
	event.Fire();
	return entity;
}

bool Utils_ShowGameText(int client, const char[] icon="leaderboard_streak", int color=0, const char[] buffer, any ...)
{
	BfWrite bf;
	if(!client)
	{
		bf = view_as<BfWrite>(StartMessageAll("HudNotifyCustom"));
	}
	else
	{
		bf = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
	}

	if(bf == null)
		return false;

	static char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 5);
	ReplaceString(message, sizeof(message), "\n", "");

	bf.WriteString(message);
	bf.WriteString(icon);
	bf.WriteByte(color);
	EndMessage();
	return true;
}


void Utils_RemovePlayerTarge(int client)
{
	int entity = MaxClients+1;
	while((entity=Utils_FindEntityByClassname2(entity, "tf_wearable_demoshield"))!=-1)
	{
		int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			if(index==131 || index==406 || index==1099 || index==1144)  //Chargin' Targe, Splendid Screen, Tide Turner, Festive Chargin' Targe
				TF2_RemoveWearable(client, entity);
		}
	}
}



bool Utils_CheckValidBoss(int client=0, char[] SpecialName, bool CompanionCheck=false)
{
	if(!FF2Globals.Enabled2)
		return false;

	static char boss[64], companionName[64];
	for(int config; config<FF2CharSetInfo.SizeOfSpecials; config++)
	{
		KvRewind(FF2CharSetInfo.BossKV[config]);
		if(KvGetNum(FF2CharSetInfo.BossKV[config], "blocked"))
			continue;

		KvGetString(FF2CharSetInfo.BossKV[config], "companion", companionName, sizeof(companionName));
		KvGetString(FF2CharSetInfo.BossKV[config], "name", boss, sizeof(boss));
		if(StrEqual(boss, SpecialName, false))
		{
			if(companionName[0] && CompanionCheck)
				return false;

			if(client)
			{
				if((KvGetNum(FF2CharSetInfo.BossKV[config], "donator") && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
				   (KvGetNum(FF2CharSetInfo.BossKV[config], "admin") && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
				   (KvGetNum(FF2CharSetInfo.BossKV[config], "owner") && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true)))
					return false;

				if(Utils_BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true))
					return false;
			}

			if(KvGetNum(FF2CharSetInfo.BossKV[config], "nofirst") && (FF2Globals.RoundCount<FF2GlobalsCvars.ArenaRounds || (FF2Globals.RoundCount==FF2GlobalsCvars.ArenaRounds && Utils_CheckRoundState()!=1)))
				return false;

			if(client)
			{
				CanBossVs[client] = KvGetNum(FF2CharSetInfo.BossKV[config], "noversus");
				CanBossTeam[client] = KvGetNum(FF2CharSetInfo.BossKV[config], "bossteam");
			}

			return true;
		}
	}
	return false;
}

bool Utils_BossTheme(int config)
{
	KvRewind(FF2CharSetInfo.BossKV[config]);
	int theme = RoundFloat(Pow(KvGetFloat(FF2CharSetInfo.BossKV[config], "theme"), 2.0));
	if(theme < 1)
		return false;

	return !(ConVars.Theme.IntValue & theme);
}


int Utils_RemovePlayerBack(int client, int[] indices, int length)
{
	if(length < 1)
		return;

	int entity = MaxClients+1;
	while((entity=Utils_FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		static char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(int i; i<length; i++)
				{
					if(index == indices[i])
						TF2_RemoveWearable(client, entity);
				}
			}
		}
	}
}

int Utils_FindPlayerBack(int client, int index)
{
	int entity = MaxClients+1;
	while((entity=Utils_FindEntityByClassname2(entity, "tf_wearable*"))!=-1)
	{
		static char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrContains(netclass, "CTFWearable")>-1 && GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")==index && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			return entity;
	}
	return -1;
}


float Utils_GetSongLength(char[] trackIdx)
{
	float duration;
	static char bgmTime[128];
	KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], trackIdx, bgmTime, sizeof(bgmTime));
	if(StrContains(bgmTime, ":", false)!=-1) // new-style MM:SS:MSMS
	{
		static char time2[32][32];
		int count = ExplodeString(bgmTime, ":", time2, sizeof(time2), sizeof(time2));
		if(count > 0)
		{
			char newTime[64];
			for(int i; i<count; i+=3)
			{
				int mins = StringToInt(time2[i])*60;
				int secs = StringToInt(time2[i+1]);
				int milsecs = StringToInt(time2[i+2]);
				FormatEx(newTime, sizeof(newTime), "%i.%i", mins+secs, milsecs);
				duration = StringToFloat(newTime);
			}
		}
	}
	else // old style seconds
	{
		duration = KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], trackIdx);
	}
	return duration;
}

void Utils_GetSongTime(int trackIdx, char[] timeStr, int length)
{
	char songIdx[32];
	FormatEx(songIdx, sizeof(songIdx), "time%i", trackIdx);
	int time = RoundToFloor(Utils_GetSongLength(songIdx));
	if(time/60 > 9)
	{
		IntToString(time/60, timeStr, length);
	}
	else
	{
		Format(timeStr, length, "0%i", time/60);
	}

	if(time%60 > 9)
	{
		Format(timeStr, length, "%s:%i", timeStr, time%60);
	}
	else
	{
		Format(timeStr, length, "%s:0%i", timeStr, time%60);
	}
}

stock void Utils_SetControlPoint(bool enable)
{
	int controlPoint = MaxClients+1;
	while((controlPoint=Utils_FindEntityByClassname2(controlPoint, "team_control_point"))!=-1)
	{
		if(controlPoint>MaxClients && IsValidEntity(controlPoint))
		{
			AcceptEntityInput(controlPoint, (enable ? "ShowModel" : "HideModel"));
			SetVariantInt(enable ? 0 : 1);
			AcceptEntityInput(controlPoint, "SetLocked");
		}
	}
}

stock void Utils_SetArenaCapEnableTime(float time)
{
	int entity = -1;
	if((entity=Utils_FindEntityByClassname2(-1, "tf_logic_arena"))!=-1 && IsValidEntity(entity))
	{
		static char timeString[32];
		FloatToString(time, timeString, sizeof(timeString));
		DispatchKeyValue(entity, "CapEnableDelay", timeString);
	}
}


void Utils_DoOverlay(int client, const char[] overlay)
{
	int flags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", flags & ~FCVAR_CHEAT);
	if(overlay[0])
	{
		ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	}
	else
	{
		ClientCommand(client, "r_screenoverlay off");
	}
	SetCommandFlags("r_screenoverlay", flags);
}


/*< freak_fortress_2.inc >*/
stock void FPrintToChat(int client, const char[] message, any ...)
{
	SetGlobalTransTarget(client);
	char buffer[192];
	VFormat(buffer, sizeof(buffer), message, 3);
	CPrintToChat(client, "%t%s", "Prefix", buffer);
}

stock void FPrintToChatAll(const char[] message, any ...)
{
	char buffer[192];
	VFormat(buffer, sizeof(buffer), message, 2);
	CPrintToChatAll("%t%s", "Prefix", buffer);
}

stock void FReplyToCommand(int client, const char[] message, any ...)
{
	SetGlobalTransTarget(client);
	char buffer[192];
	VFormat(buffer, sizeof(buffer), message, 3);
	if(!client)
	{
		CRemoveTags(buffer, sizeof(buffer));
		PrintToServer("[FF2] %s", buffer);
	}
	else if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
	{
		CRemoveTags(buffer, sizeof(buffer));
		PrintToConsole(client, "[FF2] %s", buffer);
	}
	else
	{
		CPrintToChat(client, "%t%s", "Prefix", buffer);
	}
}

stock int FF2_SpawnWeapon(int client, char[] name, int index, int level, int qual, const char[] att, bool visible=true)
{
	#if defined _tf2items_included
	if(StrEqual(name, "saxxy", false))	// if "saxxy" is specified as the name, replace with appropiate name
	{ 
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Scout:	ReplaceString(name, 64, "saxxy", "tf_weapon_bat", false);
			case TFClass_Pyro:	ReplaceString(name, 64, "saxxy", "tf_weapon_fireaxe", false);
			case TFClass_DemoMan:	ReplaceString(name, 64, "saxxy", "tf_weapon_bottle", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "saxxy", "tf_weapon_fists", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "saxxy", "tf_weapon_wrench", false);
			case TFClass_Medic:	ReplaceString(name, 64, "saxxy", "tf_weapon_bonesaw", false);
			case TFClass_Sniper:	ReplaceString(name, 64, "saxxy", "tf_weapon_club", false);
			case TFClass_Spy:	ReplaceString(name, 64, "saxxy", "tf_weapon_knife", false);
			default:		ReplaceString(name, 64, "saxxy", "tf_weapon_shovel", false);
		}
	}
	else if(StrEqual(name, "tf_weapon_shotgun", false))	// If using tf_weapon_shotgun for Soldier/Pyro/Heavy/Engineer
	{
		switch(TF2_GetPlayerClass(client))
		{
			case TFClass_Pyro:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_pyro", false);
			case TFClass_Heavy:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_hwg", false);
			case TFClass_Engineer:	ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_primary", false);
			default:		ReplaceString(name, 64, "tf_weapon_shotgun", "tf_weapon_shotgun_soldier", false);
		}
	}

	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	if(hWeapon == INVALID_HANDLE)
		return -1;

	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, ";", atts, 32, 32);

	if(count % 2)
		--count;

	if(count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2;
		for(int i; i<count; i+=2)
		{
			int attrib = StringToInt(atts[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", atts[i], atts[i+1]);
				delete hWeapon;
				return -1;
			}

			TF2Items_SetAttribute(hWeapon, i2, attrib, StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}

	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	delete hWeapon;
	if(entity == -1)
		return -1;

	EquipPlayerWeapon(client, entity);

	if(visible)
	{
		SetEntProp(entity, Prop_Send, "m_bValidatedAttachedEntity", 1);
	}
	else
	{
		SetEntProp(entity, Prop_Send, "m_iWorldModelIndex", -1);
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.001);
	}
	return entity;
	#else
	return -1;
	#endif
}

stock void FF2_SetAmmo(int client, int weapon, int ammo=-1, int clip=-1)
{
	if(IsValidEntity(weapon))
	{
		if(clip > -1)
			SetEntProp(weapon, Prop_Data, "m_iClip1", clip);

		int ammoType = (ammo>-1 ? GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") : -1);
		if(ammoType != -1)
			SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, ammoType);
	}
}