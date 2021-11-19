void FindCharacters()
{
	char filepath[PLATFORM_MAX_PATH], config[PLATFORM_MAX_PATH], key[4], charset[42];
	FF2CharSetInfo.SizeOfSpecials = 0;
	int i;
	for(; i<MAXCHARSETS; i++)
	{
		FF2Packs_NumBosses[i] = 0;
	}
	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, "%s/%s", DataPath, CharsetCFG);

	if(!FileExists(filepath))
	{
		BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, "%s/%s", ConfigPath, CharsetCFG);
		if(!FileExists(filepath))
		{
			LogToFile(FF2LogsPaths.Errors, "[!!!] Unable to find '%s'", CharsetCFG);
			FF2Globals.Enabled2 = false;
			return;
		}
		FF2CharSetInfo.UseOldCharSetPath = true;
	}
	else
	{
		FF2CharSetInfo.UseOldCharSetPath = false;
	}

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, filepath);
	int FF2CharSet = ConVars.Charset.IntValue;
	if(!FF2Globals.Enabled2)
	{
		int amount;
		do
		{
			KvGetSectionName(Kv, FF2Packs_Names[amount], sizeof(FF2Packs_Names[]));
			KvGetString(Kv, "1", config, PLATFORM_MAX_PATH);
			if(config[0])
			{
				for(i=1; FF2Packs_NumBosses[amount]<MAXSPECIALS && i<=MAXSPECIALS; i++)
				{
					IntToString(i, key, sizeof(key));
					KvGetString(Kv, key, config, PLATFORM_MAX_PATH);
					if(!config[0])
						continue;

					if(StrContains(config, "*") >= 0)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						Utils_ProcessDirectory(filepath, "", config, amount);
						continue;
					}
					LoadSideCharacter(config, amount);
				}
			}
			else
			{
				KvGotoFirstSubKey(Kv);
				do
				{
					KvGetSectionName(Kv, config, PLATFORM_MAX_PATH);
					if(!config[0])
						break;

					if(StrContains(config, "*") >= 0)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						Utils_ProcessDirectory(filepath, "", config, amount);
						continue;
					}
					LoadSideCharacter(config, amount);
				} while(KvGotoNextKey(Kv) && FF2Packs_NumBosses[amount]<MAXSPECIALS);
				KvGoBack(Kv);
			}
			amount++;
		} while(amount<MAXCHARSETS && KvGotoNextKey(Kv));

		delete Kv;
		FF2CharSetInfo.CurrentCharSetIdx = -1;
		return;
	}

	int NumOfCharSet = FF2CharSet;
	strcopy(charset, sizeof(charset), FF2CharSetInfo.CurrentCharSet);
	Action action = Forwards_Call_OnLoadCharSet(NumOfCharSet, charset, sizeof(charset));
	if(action == Plugin_Changed)
	{
		i = -1;
		if(charset[0])
		{
			KvRewind(Kv);
			for(i=0; ; i++)
			{
				KvGetSectionName(Kv, config, sizeof(config));
				if(StrEqual(config, charset, false))
				{
					FF2CharSet = i;
					strcopy(FF2CharSetInfo.CurrentCharSet, PLATFORM_MAX_PATH, charset);
					KvGotoFirstSubKey(Kv);
					break;
				}

				if(!KvGotoNextKey(Kv))
				{
					i = -1;
					break;
				}
			}
		}

		if(i == -1)
		{
			FF2CharSet = NumOfCharSet;
			for(i=0; i<FF2CharSet; i++)
			{
				KvGotoNextKey(Kv);
			}
			KvGotoFirstSubKey(Kv);
			KvGetSectionName(Kv, FF2CharSetInfo.CurrentCharSet, sizeof(FF2CharSetInfo.CurrentCharSet));
		}
	}

	KvRewind(Kv);
	for(i=0; i<FF2CharSet; i++)
	{
		if(!KvGotoNextKey(Kv))
			break;
	}

	FF2CharSetInfo.CurrentCharSetIdx = i;
	KvGetSectionName(Kv, FF2Packs_Names[FF2CharSetInfo.CurrentCharSetIdx], sizeof(FF2Packs_Names[]));

	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, ConfigPath);
	KvGetString(Kv, "1", config, PLATFORM_MAX_PATH);
	if(config[0])
	{
		for(i=1; FF2CharSetInfo.SizeOfSpecials<MAXSPECIALS && i<=MAXSPECIALS; i++)
		{
			IntToString(i, key, sizeof(key));
			KvGetString(Kv, key, config, PLATFORM_MAX_PATH);
			if(!config[0])
				continue;

			if(StrContains(config, "*") >= 0)
			{
				ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
				Utils_ProcessDirectory(filepath, "", config, -1);
				continue;
			}
			LoadCharacter(config);
		}
	}
	else
	{
		KvGotoFirstSubKey(Kv);
		do
		{
			KvGetSectionName(Kv, config, PLATFORM_MAX_PATH);
			if(!config[0])
				break;

			if(StrContains(config, "*") >= 0)
			{
				ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
				Utils_ProcessDirectory(filepath, "", config, -1);
				continue;
			}
			LoadCharacter(config);
		} while(KvGotoNextKey(Kv) && FF2CharSetInfo.SizeOfSpecials<MAXSPECIALS);
		KvGoBack(Kv);
	}

	KvGetString(Kv, "FF2Packs_iChances", FF2Packs_sChances, sizeof(FF2Packs_sChances));

	// Check if the current charset is not the first
	// one or if there's a charset after this one
	FF2CharSetInfo.HasMultiCharSets = FF2CharSetInfo.CurrentCharSetIdx>0;
	if(!FF2CharSetInfo.HasMultiCharSets)
		FF2CharSetInfo.HasMultiCharSets = KvGotoNextKey(Kv);

	delete Kv;

	int amount;
	if(FF2CharSetInfo.HasMultiCharSets)
	{
		if(ConVars.NameChange.IntValue == 2)
		{
			char newName[256];
			FormatEx(newName, 256, "%s | %s", FF2ModsInfo.OldHostName, FF2Packs_Names[FF2CharSetInfo.CurrentCharSetIdx]);
			FF2ModsInfo.cvarHostName.SetString(newName);
		}

		// KvRewind, you son of a-
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2CharSetInfo.UseOldCharSetPath ? ConfigPath : DataPath, CharsetCFG);
		Kv = CreateKeyValues("");
		FileToKeyValues(Kv, config);
		do
		{
			if(amount == FF2CharSetInfo.CurrentCharSetIdx)	// Skip the current pack
			{
				amount++;
				continue;
			}

			KvGetSectionName(Kv, FF2Packs_Names[amount], sizeof(FF2Packs_Names[]));
			KvGetString(Kv, "1", config, PLATFORM_MAX_PATH);
			if(config[0])
			{
				for(i=1; FF2Packs_NumBosses[amount]<MAXSPECIALS && i<=MAXSPECIALS; i++)
				{
					IntToString(i, key, sizeof(key));
					KvGetString(Kv, key, config, PLATFORM_MAX_PATH);
					if(!config[0])
						continue;

					if(StrContains(config, "*") >= 0)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						Utils_ProcessDirectory(filepath, "", config, amount);
						continue;
					}
					LoadSideCharacter(config, amount);
				}
			}
			else
			{
				KvGotoFirstSubKey(Kv);
				do
				{
					KvGetSectionName(Kv, config, PLATFORM_MAX_PATH);
					if(!config[0])
						break;

					if(StrContains(config, "*") >= 0)
					{
						ReplaceString(config, PLATFORM_MAX_PATH, "*", "");
						Utils_ProcessDirectory(filepath, "", config, amount);
						continue;
					}
					LoadSideCharacter(config, amount);
				} while(KvGotoNextKey(Kv) && FF2Packs_NumBosses[amount]<MAXSPECIALS);
				KvGoBack(Kv);
			}
			amount++;
		} while(amount<MAXCHARSETS && KvGotoNextKey(Kv));

		delete Kv;
	}

	if(FF2Packs_sChances[0])
	{
		char stringChances[MAXSPECIALS*2][8];
		amount = ExplodeString(FF2Packs_sChances, ";", stringChances, MAXSPECIALS*2, 8);
		if(amount % 2)
		{
			LogToFile(FF2LogsPaths.Errors, "[Characters] Invalid FF2Packs_iChances string, disregarding FF2Packs_iChances");
			FF2Packs_sChances[0] = 0;
			amount = 0;
		}

		FF2Packs_iChances[0] = StringToInt(stringChances[0]);
		FF2Packs_iChances[1] = StringToInt(stringChances[1]);
		for(FF2Packs_ChanceIdx=2; FF2Packs_ChanceIdx<amount; FF2Packs_ChanceIdx++)
		{
			if(FF2Packs_ChanceIdx % 2)
			{
				if(StringToInt(stringChances[FF2Packs_ChanceIdx]) < 1)
				{
					LogToFile(FF2LogsPaths.Errors, "[Characters] Character %i cannot have a zero or negative chance, disregarding FF2Packs_iChances", FF2Packs_ChanceIdx-1);
					strcopy(FF2Packs_sChances, sizeof(FF2Packs_sChances), "");
					break;
				}
				FF2Packs_iChances[FF2Packs_ChanceIdx] = StringToInt(stringChances[FF2Packs_ChanceIdx])+FF2Packs_iChances[FF2Packs_ChanceIdx-2];
			}
			else
			{
				FF2Packs_iChances[FF2Packs_ChanceIdx] = StringToInt(stringChances[FF2Packs_ChanceIdx]);
			}
		}
	}

	if(FileExists("sound/saxton_hale/9000.wav", true))
	{
		AddFileToDownloadsTable("sound/saxton_hale/9000.wav");
		PrecacheSound("saxton_hale/9000.wav", true);
	}
	PrecacheScriptSound("Announcer.AM_CapEnabledRandom");
	PrecacheScriptSound("Announcer.AM_CapIncite01.mp3");
	PrecacheScriptSound("Announcer.AM_CapIncite02.mp3");
	PrecacheScriptSound("Announcer.AM_CapIncite03.mp3");
	PrecacheScriptSound("Announcer.AM_CapIncite04.mp3");
	PrecacheScriptSound("Announcer.RoundEnds5minutes");
	PrecacheScriptSound("Announcer.RoundEnds2minutes");
	PrecacheSound("weapons/barret_arm_zap.wav", true);
	PrecacheSound("player/doubledonk.wav", true);
	PrecacheSound("ambient/lightson.wav", true);
	PrecacheSound("ambient/lightsoff.wav", true);
	FF2CharSetInfo.IsCharSetSelected = false;
}


bool PickCharacter(int boss, int companion)
{
	static char characterName[64];
	static char newName[64];
	if(boss == companion)
	{
		FF2BossInfo[boss].Special = FF2BossInfo[boss].Incoming;
		FF2BossInfo[boss].Incoming = -1;
		if(FF2BossInfo[boss].Special != -1)  //We've already picked a boss through Command_SetNextBoss
		{
			KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "name", newName, sizeof(newName));
			
			int characterIndex = FF2BossInfo[boss].Special;
			Action action = Forwards_Call_OnCharSelected(boss, characterIndex, newName, sizeof(newName), true);
			if(action == Plugin_Changed)
			{
				if(newName[0])
				{
					int foundExactMatch = -1;
					int foundPartialMatch = -1;
					for(int character; FF2CharSetInfo.BossKV[character] && character<MAXSPECIALS; character++)
					{
						KvRewind(FF2CharSetInfo.BossKV[character]);
						KvGetString(FF2CharSetInfo.BossKV[character], "name", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch = character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false)!=-1)
						{
							foundPartialMatch = character;
						}

						//Do the same thing as above here, but look at the filename instead of the boss name
						KvGetString(FF2CharSetInfo.BossKV[character], "filename", characterName, sizeof(characterName));
						if(StrEqual(newName, characterName, false))
						{
							foundExactMatch = character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(newName, characterName, false) != -1)
						{
							foundPartialMatch = character;
						}
					}

					if(foundExactMatch != -1)
					{
						FF2BossInfo[boss].Special = foundExactMatch;
					}
					else if(foundPartialMatch != -1)
					{
						FF2BossInfo[boss].Special = foundPartialMatch;
					}
					else
					{
						return false;
					}
					FF2SavedAbility.RegisterCharacter(characterName, boss);
					PrecacheCharacter(FF2BossInfo[boss].Special);
					return true;
				}
				FF2BossInfo[boss].Special = characterIndex;
				KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "filename", characterName, sizeof(characterName));
				FF2SavedAbility.RegisterCharacter(characterName, boss);
				PrecacheCharacter(FF2BossInfo[boss].Special);
				return true;
			}
			/*else
			{
				int client = FF2BossInfo[boss].Boss;
				if(xIncoming[client][0])
				{
					static char characterName[64];
					int foundExactMatch = -1, foundPartialMatch = -1;
					for(int character; FF2CharSetInfo.BossKV[character] && character<MAXSPECIALS; character++)
					{
						KvRewind(FF2CharSetInfo.BossKV[character]);
						KvGetString(FF2CharSetInfo.BossKV[character], "name", characterName, sizeof(characterName));
						if(StrEqual(xIncoming[client], characterName, false))
						{
							foundExactMatch = character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(xIncoming[client], characterName, false) != -1)
						{
							foundPartialMatch=character;
						}

						//Do the same thing as above here, but look at the filename instead of the boss name
						KvGetString(FF2CharSetInfo.BossKV[character], "filename", characterName, sizeof(characterName));
						if(StrEqual(xIncoming[client], characterName, false))
						{
							foundExactMatch = character;
							break;  //If we find an exact match there's no reason to keep looping
						}
						else if(StrContains(xIncoming[client], characterName, false) != -1)
						{
							foundPartialMatch = character;
						}
					}

					if(foundExactMatch != -1)
					{
						FF2BossInfo[boss].Special = foundExactMatch;
					}
					else if(foundPartialMatch != -1)
					{
						FF2BossInfo[boss].Special = foundPartialMatch;
					}
					else
					{
						return false;
					}
					PrecacheCharacter(FF2BossInfo[boss].Special);
					return true;
				}
				FF2BossInfo[boss].Special = characterIndex;
				PrecacheCharacter(FF2BossInfo[boss].Special);
				return true;
			}*/
			
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "filename", characterName, sizeof(characterName));
			FF2SavedAbility.RegisterCharacter(characterName, boss);
			PrecacheCharacter(FF2BossInfo[boss].Special);
			return true;
		}

		for(int tries; tries<100; tries++)
		{
			if(FF2Packs_sChances[0])
			{
				int characterIndex = FF2Packs_ChanceIdx;  //Don't touch FF2Packs_ChanceIdx since it doesn't get reset
				int i = GetRandomInt(0, FF2Packs_iChances[characterIndex-1]);

				while(characterIndex>=2 && i<FF2Packs_iChances[characterIndex-1])
				{
					FF2BossInfo[boss].Special = FF2Packs_iChances[characterIndex-2]-1;
					characterIndex -= 2;
				}
			}
			else
			{
				FF2BossInfo[boss].Special = GetRandomInt(0, FF2CharSetInfo.SizeOfSpecials-1);
			}

			static char companionName[64];
			KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "companion", companionName, sizeof(companionName));
			if(FF2CharSetInfo.MapBlocked[FF2BossInfo[boss].Special] ||
			   KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "blocked") ||
			   KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "donator") ||
			   KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "admin") ||
			   KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "owner") ||
			   KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "theme") ||
			  (KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "nofirst") && FF2Globals.RoundCount<=FF2GlobalsCvars.ArenaRounds) ||
			  (companionName[0] && !FF2GlobalsCvars.DuoMin) ||
			  (FF2Globals.Enabled3 && (KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "noversus")==2 ||
			  (KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "noversus")==1 && FF2BossInfo[boss].HasSwitched) ||
			  (KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "bossteam")==FF2Globals.BossTeam && FF2BossInfo[boss].HasSwitched) ||
			  (KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "bossteam")==FF2Globals.OtherTeam && !FF2BossInfo[boss].HasSwitched))))
			{
				FF2BossInfo[boss].Special = -1;
				continue;
			}
			break;
		}
	}
	else
	{
		static char bossName[64], companionName[64];
		KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "companion", companionName, sizeof(companionName), "=Failed companion name=");

		int character;
		while(character < FF2CharSetInfo.SizeOfSpecials)  //Loop through all the FF2Globals.Bosses to find the companion we're looking for
		{
			KvRewind(FF2CharSetInfo.BossKV[character]);
			KvGetString(FF2CharSetInfo.BossKV[character], "name", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				FF2BossInfo[companion].Special = character;
				break;
			}

			KvGetString(FF2CharSetInfo.BossKV[character], "filename", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				FF2BossInfo[companion].Special = character;
				break;
			}
			character++;
		}

		if(character == FF2CharSetInfo.SizeOfSpecials)  //Companion not found
			return false;
	}

	//All of the following uses `companion` because it will always be the boss index we want
	int characterIndex = FF2BossInfo[companion].Special;
	Action action = Forwards_Call_OnCharSelected(companion, characterIndex, newName, sizeof(newName), false);
	KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[companion].Special]);
	KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[companion].Special], "name", newName, sizeof(newName));
	if(action == Plugin_Changed)
	{
		if(newName[0])
		{
			int foundExactMatch = -1;
			int foundPartialMatch = -1;
			for(int character; FF2CharSetInfo.BossKV[character] && character<MAXSPECIALS; character++)
			{
				KvRewind(FF2CharSetInfo.BossKV[character]);
				KvGetString(FF2CharSetInfo.BossKV[character], "name", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch = character;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch = character;
				}

				//Do the same thing as above here, but look at the filename instead of the boss name
				KvGetString(FF2CharSetInfo.BossKV[character], "filename", characterName, sizeof(characterName));
				if(StrEqual(newName, characterName, false))
				{
					foundExactMatch = character;
					break;  //If we find an exact match there's no reason to keep looping
				}
				else if(StrContains(newName, characterName, false)!=-1)
				{
					foundPartialMatch = character;
				}
			}

			if(foundExactMatch != -1)
			{
				FF2BossInfo[companion].Special = foundExactMatch;
			}
			else if(foundPartialMatch != -1)
			{
				FF2BossInfo[companion].Special = foundPartialMatch;
			}
			else
			{
				return false;
			}
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[companion].Special], "filename", characterName, sizeof(characterName));
			FF2SavedAbility.RegisterCharacter(characterName, companion);
			PrecacheCharacter(FF2BossInfo[companion].Special);
			return true;
		}
		FF2BossInfo[companion].Special = characterIndex;
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[companion].Special], "filename", characterName, sizeof(characterName));
		FF2SavedAbility.RegisterCharacter(characterName, companion);
		PrecacheCharacter(FF2BossInfo[companion].Special);
		return true;
	}
	KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[companion].Special], "filename", characterName, sizeof(characterName));
	FF2SavedAbility.RegisterCharacter(characterName, companion);
	PrecacheCharacter(FF2BossInfo[companion].Special);
	return true;
}


void LoadCharacter(const char[] character)
{
	static char extensions[][] = {".mdl", ".dx80.vtx", ".dx90.vtx", ".sw.vtx", ".vvd", ".phy"};
	static char config[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, config, sizeof(config), "%s/%s.cfg", ConfigPath, character);
	if(!FileExists(config))
	{
		LogToFile(FF2LogsPaths.Errors, "[Characters] Character %s does not exist!", character);
		return;
	}
	FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials] = CreateKeyValues("character");
	FileToKeyValues(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], config);

	FF2CharSetInfo.MapBlocked[FF2CharSetInfo.SizeOfSpecials] = false;
	if(KvJumpToKey(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "map_only"))
	{
		char item[6];
		static char buffer[34];
		bool shouldBlock = true;
		for(int size=1; ; size++)
		{
			FormatEx(item, sizeof(item), "map%d", size);
			KvGetString(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], item, buffer, sizeof(buffer));
			if(!buffer[0])
			{
				if(size==1)
				{
					shouldBlock = false;
				}
				break;
			}
            
			if(StrContains(FF2Globals.CurrentMap, buffer)>=0)
			{
				shouldBlock = false;
				break;
			}
		}
		FF2CharSetInfo.MapBlocked[FF2CharSetInfo.SizeOfSpecials] = shouldBlock;
	}
	KvRewind(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials]);
	if(KvJumpToKey(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "map_exclude"))
	{
		char item[6];
		static char buffer[34];
		for(int size=1; ; size++)
		{
			FormatEx(item, sizeof(item), "map%d", size);
			KvGetString(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], item, buffer, sizeof(buffer));
			if(!buffer[0])
				break;

			if(!StrContains(FF2Globals.CurrentMap, buffer))
			{
				FF2CharSetInfo.MapBlocked[FF2CharSetInfo.SizeOfSpecials] = true;
				break;
			}
		}
	}
	KvRewind(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials]);

	int version = KvGetNum(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "version", StringToInt(MAJOR_REVISION));
	if(version!=StringToInt(MAJOR_REVISION) && version!=99) // 99 for FF2Globals.Bosses made ONLY for this fork
	{
		LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is only compatible with FF2 v%i!", character, version);
		return;
	}

	version = KvGetNum(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "version_minor", StringToInt(MINOR_REVISION));
	int version2 = KvGetNum(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "version_stable", StringToInt(STABLE_REVISION));
	if(version>StringToInt(MINOR_REVISION) || (version2>StringToInt(STABLE_REVISION) && version==StringToInt(MINOR_REVISION)))
	{
		LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s requires newer version of FF2 (at least %s.%i.%i)!", character, MAJOR_REVISION, version, version2);
		return;
	}

	version = KvGetNum(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "fversion", StringToInt(FORK_MAJOR_REVISION));
	if(version != StringToInt(FORK_MAJOR_REVISION))
	{
		LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is only compatible with %s FF2 v%i!", character, FORK_SUB_REVISION, version);
		return;
	}

	version = KvGetNum(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "fversion_minor", StringToInt(FORK_MINOR_REVISION));
	version2 = KvGetNum(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "fversion_stable", StringToInt(FORK_STABLE_REVISION));
	if(version>StringToInt(FORK_MINOR_REVISION) || (version2>StringToInt(FORK_STABLE_REVISION) && version==StringToInt(FORK_MINOR_REVISION)))
	{
		LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s requires newer version of %s FF2 (at least %s.%i.%i)!", character, FORK_SUB_REVISION, FORK_MAJOR_REVISION, version, version2);
		return;
	}

	for(int i=1; ; i++)
	{
		Format(config, sizeof(config), "ability%i", i);
		if(KvJumpToKey(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], config))
		{
			static char plugin_name[64];
			KvGetString(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "plugin_name", plugin_name, 64);
			BuildPath(Path_SM, config, sizeof(config), "plugins/freaks/%s.smx", plugin_name);
			if(!FileExists(config))
			{
				LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s needs plugin %s!", character, plugin_name);
				return;
			}
			KvRewind(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials]);
		}
		else
		{
			break;
		}
	}


	char key[PLATFORM_MAX_PATH];
	static char section[64];
	KvSetString(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "filename", character);
	KvGetString(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "name", config, sizeof(config));
	FF2CharSetInfo.VoiceBlocked[FF2CharSetInfo.SizeOfSpecials] = view_as<bool>(KvGetNum(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "sound_block_vo"));
	FF2CharSetInfo.BossSpeed[FF2CharSetInfo.SizeOfSpecials] = KvGetFloat(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], "maxspeed", 340.0);
	KvGotoFirstSubKey(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials]);

	while(KvGotoNextKey(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials]))
	{
		KvGetSectionName(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], section, sizeof(section));
		if(StrEqual(section, "download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], key, config, sizeof(config));
				if(!config[0])
					break;

				if(FileExists(config, true))
				{
					AddFileToDownloadsTable(config);
				}
				else
				{
					LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is missing file '%s'!", character, config);
				}
			}
		}
		else if(StrEqual(section, "mod_download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], key, config, sizeof(config));
				if(!config[0])
					break;

				for(int extension; extension<sizeof(extensions); extension++)
				{
					FormatEx(key, PLATFORM_MAX_PATH, "%s%s", config, extensions[extension]);
					if(FileExists(key, true))
					{
						AddFileToDownloadsTable(key);
					}
					else if(StrContains(key, ".phy") == -1)
					{
						LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is missing file '%s'!", character, key);
					}
				}
			}
		}
		else if(StrEqual(section, "mat_download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(FF2CharSetInfo.BossKV[FF2CharSetInfo.SizeOfSpecials], key, config, sizeof(config));
				if(!config[0])
					break;

				FormatEx(key, sizeof(key), "%s.vtf", config);
				if(FileExists(key, true))
				{
					AddFileToDownloadsTable(key);
				}
				else
				{
					LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is missing file '%s'!", character, key);
				}

				FormatEx(key, sizeof(key), "%s.vmt", config);
				if(FileExists(key, true))
				{
					AddFileToDownloadsTable(key);
				}
				else
				{
					LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is missing file '%s'!", character, key);
				}
			}
		}
	}
	FF2CharSetInfo.SizeOfSpecials++;
}

void LoadSideCharacter(const char[] character, int pack)
{
	static char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s.cfg", ConfigPath, character);
	if(!FileExists(config))
		return;

	FF2BossPacks[FF2Packs_NumBosses[pack]][pack] = CreateKeyValues("character");
	FileToKeyValues(FF2BossPacks[FF2Packs_NumBosses[pack]][pack], config);
	KvSetString(FF2BossPacks[FF2Packs_NumBosses[pack]][pack], "filename", character);

	int version = KvGetNum(FF2BossPacks[FF2Packs_NumBosses[pack]][pack], "version", StringToInt(MAJOR_REVISION));
	if(version!=StringToInt(MAJOR_REVISION) && version!=99) // 99 for FF2Globals.Bosses made ONLY for this fork
		return;

	version = KvGetNum(FF2BossPacks[FF2Packs_NumBosses[pack]][pack], "version_minor", StringToInt(MINOR_REVISION));
	if(version > StringToInt(MINOR_REVISION))
		return;

	int version2 = KvGetNum(FF2BossPacks[FF2Packs_NumBosses[pack]][pack], "version_stable", StringToInt(STABLE_REVISION));
	if(version2>StringToInt(STABLE_REVISION) && version==StringToInt(MINOR_REVISION))
		return;

	version = KvGetNum(FF2BossPacks[FF2Packs_NumBosses[pack]][pack], "fversion", StringToInt(FORK_MAJOR_REVISION));
	if(version != StringToInt(FORK_MAJOR_REVISION))
		return;

	version = KvGetNum(FF2BossPacks[FF2Packs_NumBosses[pack]][pack], "fversion_minor", StringToInt(FORK_MINOR_REVISION));
	if(version > StringToInt(FORK_MINOR_REVISION))
		return;

	version2 = KvGetNum(FF2BossPacks[FF2Packs_NumBosses[pack]][pack], "fversion_stable", StringToInt(FORK_STABLE_REVISION));
	if(version2>StringToInt(FORK_STABLE_REVISION) && version==StringToInt(FORK_MINOR_REVISION))
		return;

	FF2Packs_NumBosses[pack]++;
}

void PrecacheCharacter(int characterIndex)
{
	char filePath[PLATFORM_MAX_PATH], key[8];
	static char file[PLATFORM_MAX_PATH], section[16], bossName[64];
	KvRewind(FF2CharSetInfo.BossKV[characterIndex]);
	KvGetString(FF2CharSetInfo.BossKV[characterIndex], "filename", bossName, sizeof(bossName));
	KvGotoFirstSubKey(FF2CharSetInfo.BossKV[characterIndex]);
	while(KvGotoNextKey(FF2CharSetInfo.BossKV[characterIndex]))
	{
		KvGetSectionName(FF2CharSetInfo.BossKV[characterIndex], section, sizeof(section));
		if(StrEqual(section, "sound_bgm"))
		{
			for(int i=1; ; i++)
			{
				FormatEx(key, sizeof(key), "path%d", i);
				KvGetString(FF2CharSetInfo.BossKV[characterIndex], key, file, sizeof(file));
				if(!file[0])
					break;

				FormatEx(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
				if(FileExists(filePath, true))
				{
					PrecacheSound(file);
				}
				else
				{
					LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
				}
			}
		}
		else if(StrEqual(section, "mod_precache") || !StrContains(section, "sound_") || !StrContains(section, "catch_"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(FF2CharSetInfo.BossKV[characterIndex], key, file, sizeof(file));
				if(!file[0])
					break;

				if(StrEqual(section, "mod_precache"))
				{
					if(FileExists(file, true))
					{
						PrecacheModel(file);
					}
					else
					{
						LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
					}
				}
				else
				{
					FormatEx(filePath, sizeof(filePath), "sound/%s", file);  //Sounds doesn't include the sound/ prefix, so add that
					if(FileExists(filePath, true))
					{
						PrecacheSound(file);
					}
					else
					{
						LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is missing file '%s' in section '%s'!", bossName, filePath, section);
					}
				}
			}
		}
	}
}


void FindCompanion(int boss, int players, bool[] omit)
{
	static int playersNeeded = 2;
	static char companionName[64];
	KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
	KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "companion", companionName, sizeof(companionName));
	if(playersNeeded<players && companionName[0])  //Only continue if we have enough players and if the boss has a companion
	{
		int companion = Utils_GetRandomValidClient(omit);
		FF2BossInfo[companion].Boss = companion;
		FF2BossInfo[companion].HasSwitched = FF2BossInfo[boss].HasSwitched;
		omit[companion] = true;
		int client = FF2BossInfo[boss].Boss;
		if(PickCharacter(boss, companion))  //TODO: This is a bit misleading
		{
			if(FF2BossInfo[companion].RageDamage == 1)	// If 1, toggle infinite rage
			{
				InfiniteRageActive[client] = true;
				CreateTimer(0.2, Timer_InfiniteRage, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				FF2BossInfo[companion].RageDamage = 1;
			}
			else if(FF2BossInfo[companion].RageDamage == -1)	// If -1, never rage
			{
				FF2BossInfo[companion].RageDamage = 99999;
			}
			else	// Use formula or straight value
			{
				FF2BossInfo[companion].RageDamage = ParseFormula(companion, "ragedamage", FF2GlobalsCvars.RageDamage, 1900);
			}
			FF2BossInfo[companion].LivesMax = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[companion].Special], "lives", 1);
			if(FF2BossInfo[companion].LivesMax < 1)
			{
				LogToFile(FF2LogsPaths.Errors, "[Boss] Boss %s has an invalid amount of lives, setting to 1", companionName);
				FF2BossInfo[companion].LivesMax = 1;
			}
			playersNeeded++;
			FindCompanion(companion, players, omit);  //Make sure this companion doesn't have a companion of their own
		}
	}
	playersNeeded = 2;  //Reset the amount of players needed back after we're done
}


void CacheWeapons()
{
	if(ConVars.HardcodeWep.IntValue > 1)
	{
		FF2Globals.HasWeaponCfg = false;
		return;
	}

	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, WeaponCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, WeaponCFG);
		if(!FileExists(config))
		{
			LogToFile(FF2LogsPaths.Errors, "[Weapons] Could not find '%s'!", WeaponCFG);
			FF2Globals.HasWeaponCfg = false;
			return;
		}
	}

	FF2ModsInfo.WeaponCfg = CreateKeyValues("Weapons");
	if(!FileToKeyValues(FF2ModsInfo.WeaponCfg, config))
	{
		LogToFile(FF2LogsPaths.Errors, "[Weapons] '%s' is improperly formatted!", WeaponCFG);
		FF2Globals.HasWeaponCfg = false;
		return;
	}
	FF2Globals.HasWeaponCfg = true;
}

void CacheDifficulty()
{
	char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", DataPath, DifficultyCFG);
	if(!FileExists(config))
	{
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", ConfigPath, DifficultyCFG);
		if(!FileExists(config))
		{
			FF2ModsInfo.DiffCfg = null;
			return;
		}
	}

	FF2ModsInfo.DiffCfg = CreateKeyValues("difficulty");
	if(!FileToKeyValues(FF2ModsInfo.DiffCfg, config))
	{
		LogToFile(FF2LogsPaths.Errors, "[Difficulty] '%s' is improperly formatted!", DifficultyCFG);
		FF2ModsInfo.DiffCfg = null;
		return;
	}
}


void EnableSubPlugins(bool force=false)
{
	if(FF2Globals.AreSubpluginEnabled && !force)
		return;

	FF2Globals.AreSubpluginEnabled = true;
	char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH], filename_old[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "plugins/freaks");
	FileType filetype;
	DirectoryListing directory = OpenDirectory(path);
	while(directory.GetNext(filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".ff2", false)!=-1)
		{
			FormatEx(filename_old, sizeof(filename_old), "%s/%s", path, filename);
			ReplaceString(filename, sizeof(filename), ".ff2", ".smx", false);
			Format(filename, sizeof(filename), "%s/%s", path, filename);
			DeleteFile(filename); // Just in case filename.smx also exists: delete it and replace it with the new .smx version
			RenameFile(filename, filename_old);
			ServerCommand("sm plugins load freaks/%s", filename);
		}
	}
	delete directory;
}

void DisableSubPlugins(bool force=false)
{
	if(!FF2Globals.AreSubpluginEnabled && !force)
		return;

	char path[PLATFORM_MAX_PATH], filename[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "plugins/freaks");
	FileType filetype;
	DirectoryListing directory = OpenDirectory(path);
	while(directory.GetNext(filename, sizeof(filename), filetype))
	{
		if(filetype==FileType_File && StrContains(filename, ".smx", false)!=-1)
		{
			InsertServerCommand("sm plugins unload freaks/%s", filename);  // ServerCommand will not work when switching maps

			Format(filename, sizeof(filename), "%s/%s", path, filename);
			DeleteFile(filename);	// Remove smx so we don't load it in automatically
		}
	}
	ServerExecute();
	FF2Globals.AreSubpluginEnabled = false;
	delete directory;
}

void LoadDifficulty(int boss)
{
	KvRewind(FF2ModsInfo.DiffCfg);
	KvGotoFirstSubKey(FF2ModsInfo.DiffCfg);
	do
	{
		static char section[64];
		KvGetSectionName(FF2ModsInfo.DiffCfg, section, sizeof(section));
		if(!StrEqual(section, dIncoming[FF2BossInfo[boss].Boss]))
			continue;

		static char plugin[80];
		KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "filename", plugin, sizeof(plugin));
		if(!KvGetNum(FF2ModsInfo.DiffCfg, plugin, KvGetNum(FF2ModsInfo.DiffCfg, "default", 1)))
			break;

		FF2Globals.IsSpecialRound = true;
		KvGotoFirstSubKey(FF2ModsInfo.DiffCfg);
		do
		{
			static char buffer[80];
			KvGetSectionName(FF2ModsInfo.DiffCfg, plugin, sizeof(plugin));
			Format(plugin, sizeof(plugin), "%s.smx", plugin);
			Handle iter = GetPluginIterator();
			Handle pl = INVALID_HANDLE;
			while(MorePlugins(iter))
			{
				pl = ReadPlugin(iter);
				GetPluginFilename(pl, buffer, sizeof(buffer));
				if(StrContains(buffer, plugin, false) == -1)
					continue;

				Function func = GetFunctionByName(pl, "FF2_OnDifficulty");
				if(func == INVALID_FUNCTION)
					break;

				Call_StartFunction(pl, func);
				Call_PushCell(boss);
				Call_PushString(section);
				Call_PushCell(FF2ModsInfo.DiffCfg);
				Call_Finish();
				break;
			}
			delete iter;

			if(FF2ModsInfo.DiffCfg == INVALID_HANDLE)
			{
				LogToFile(FF2LogsPaths.Errors, "[Difficulty] %s closed needed Handle for difficulty!", buffer);
				CacheDifficulty();
				return;
			}

		} while(KvGotoNextKey(FF2ModsInfo.DiffCfg));
		break;
	} while(KvGotoNextKey(FF2ModsInfo.DiffCfg));
}