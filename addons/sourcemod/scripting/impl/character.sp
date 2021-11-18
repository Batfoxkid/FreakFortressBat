void FindCharacters()
{
	char filepath[PLATFORM_MAX_PATH], config[PLATFORM_MAX_PATH], key[4], charset[42];
	Specials = 0;
	int i;
	for(; i<MAXCHARSETS; i++)
	{
		PackSpecials[i] = 0;
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
		CharSetOldPath = true;
	}
	else
	{
		CharSetOldPath = false;
	}

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, filepath);
	int FF2CharSet = ConVars.Charset.IntValue;
	if(!FF2Globals.Enabled2)
	{
		int amount;
		do
		{
			KvGetSectionName(Kv, CharSetString[amount], sizeof(CharSetString[]));
			KvGetString(Kv, "1", config, PLATFORM_MAX_PATH);
			if(config[0])
			{
				for(i=1; PackSpecials[amount]<MAXSPECIALS && i<=MAXSPECIALS; i++)
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
				} while(KvGotoNextKey(Kv) && PackSpecials[amount]<MAXSPECIALS);
				KvGoBack(Kv);
			}
			amount++;
		} while(amount<MAXCHARSETS && KvGotoNextKey(Kv));

		delete Kv;
		CurrentCharSet = -1;
		return;
	}

	int NumOfCharSet = FF2CharSet;
	strcopy(charset, sizeof(charset), FF2CharSetString);
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
					strcopy(FF2CharSetString, PLATFORM_MAX_PATH, charset);
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
			KvGetSectionName(Kv, FF2CharSetString, sizeof(FF2CharSetString));
		}
	}

	KvRewind(Kv);
	for(i=0; i<FF2CharSet; i++)
	{
		if(!KvGotoNextKey(Kv))
			break;
	}

	CurrentCharSet = i;
	KvGetSectionName(Kv, CharSetString[CurrentCharSet], sizeof(CharSetString[]));

	BuildPath(Path_SM, filepath, PLATFORM_MAX_PATH, ConfigPath);
	KvGetString(Kv, "1", config, PLATFORM_MAX_PATH);
	if(config[0])
	{
		for(i=1; Specials<MAXSPECIALS && i<=MAXSPECIALS; i++)
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
		} while(KvGotoNextKey(Kv) && Specials<MAXSPECIALS);
		KvGoBack(Kv);
	}

	KvGetString(Kv, "chances", ChancesString, sizeof(ChancesString));

	// Check if the current charset is not the first
	// one or if there's a charset after this one
	HasCharSets = CurrentCharSet>0;
	if(!HasCharSets)
		HasCharSets = KvGotoNextKey(Kv);

	delete Kv;

	int amount;
	if(HasCharSets)
	{
		if(ConVars.NameChange.IntValue == 2)
		{
			char newName[256];
			FormatEx(newName, 256, "%s | %s", FF2ModsInfo.OldHostName, CharSetString[CurrentCharSet]);
			FF2ModsInfo.cvarHostName.SetString(newName);
		}

		// KvRewind, you son of a-
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);
		Kv = CreateKeyValues("");
		FileToKeyValues(Kv, config);
		do
		{
			if(amount == CurrentCharSet)	// Skip the current pack
			{
				amount++;
				continue;
			}

			KvGetSectionName(Kv, CharSetString[amount], sizeof(CharSetString[]));
			KvGetString(Kv, "1", config, PLATFORM_MAX_PATH);
			if(config[0])
			{
				for(i=1; PackSpecials[amount]<MAXSPECIALS && i<=MAXSPECIALS; i++)
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
				} while(KvGotoNextKey(Kv) && PackSpecials[amount]<MAXSPECIALS);
				KvGoBack(Kv);
			}
			amount++;
		} while(amount<MAXCHARSETS && KvGotoNextKey(Kv));

		delete Kv;
	}

	if(ChancesString[0])
	{
		char stringChances[MAXSPECIALS*2][8];
		amount = ExplodeString(ChancesString, ";", stringChances, MAXSPECIALS*2, 8);
		if(amount % 2)
		{
			LogToFile(FF2LogsPaths.Errors, "[Characters] Invalid chances string, disregarding chances");
			ChancesString[0] = 0;
			amount = 0;
		}

		chances[0] = StringToInt(stringChances[0]);
		chances[1] = StringToInt(stringChances[1]);
		for(chancesIndex=2; chancesIndex<amount; chancesIndex++)
		{
			if(chancesIndex % 2)
			{
				if(StringToInt(stringChances[chancesIndex]) < 1)
				{
					LogToFile(FF2LogsPaths.Errors, "[Characters] Character %i cannot have a zero or negative chance, disregarding chances", chancesIndex-1);
					strcopy(ChancesString, sizeof(ChancesString), "");
					break;
				}
				chances[chancesIndex] = StringToInt(stringChances[chancesIndex])+chances[chancesIndex-2];
			}
			else
			{
				chances[chancesIndex] = StringToInt(stringChances[chancesIndex]);
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
	isCharSetSelected = false;
}


bool PickCharacter(int boss, int companion)
{
	static char characterName[64];
	static char newName[64];
	if(boss == companion)
	{
		Special[boss] = Incoming[boss];
		Incoming[boss] = -1;
		if(Special[boss] != -1)  //We've already picked a boss through Command_SetNextBoss
		{
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "name", newName, sizeof(newName));
			
			int characterIndex = Special[boss];
			Action action = Forwards_Call_OnCharSelected(boss, characterIndex, newName, sizeof(newName), true);
			if(action == Plugin_Changed)
			{
				if(newName[0])
				{
					int foundExactMatch = -1;
					int foundPartialMatch = -1;
					for(int character; BossKV[character] && character<MAXSPECIALS; character++)
					{
						KvRewind(BossKV[character]);
						KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
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
						KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
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
						Special[boss] = foundExactMatch;
					}
					else if(foundPartialMatch != -1)
					{
						Special[boss] = foundPartialMatch;
					}
					else
					{
						return false;
					}
					FF2SavedAbility.RegisterCharacter(characterName, boss);
					PrecacheCharacter(Special[boss]);
					return true;
				}
				Special[boss] = characterIndex;
				KvGetString(BossKV[Special[boss]], "filename", characterName, sizeof(characterName));
				FF2SavedAbility.RegisterCharacter(characterName, boss);
				PrecacheCharacter(Special[boss]);
				return true;
			}
			/*else
			{
				int client = Boss[boss];
				if(xIncoming[client][0])
				{
					static char characterName[64];
					int foundExactMatch = -1, foundPartialMatch = -1;
					for(int character; BossKV[character] && character<MAXSPECIALS; character++)
					{
						KvRewind(BossKV[character]);
						KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
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
						KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
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
						Special[boss] = foundExactMatch;
					}
					else if(foundPartialMatch != -1)
					{
						Special[boss] = foundPartialMatch;
					}
					else
					{
						return false;
					}
					PrecacheCharacter(Special[boss]);
					return true;
				}
				Special[boss] = characterIndex;
				PrecacheCharacter(Special[boss]);
				return true;
			}*/
			
			KvGetString(BossKV[Special[boss]], "filename", characterName, sizeof(characterName));
			FF2SavedAbility.RegisterCharacter(characterName, boss);
			PrecacheCharacter(Special[boss]);
			return true;
		}

		for(int tries; tries<100; tries++)
		{
			if(ChancesString[0])
			{
				int characterIndex = chancesIndex;  //Don't touch chancesIndex since it doesn't get reset
				int i = GetRandomInt(0, chances[characterIndex-1]);

				while(characterIndex>=2 && i<chances[characterIndex-1])
				{
					Special[boss] = chances[characterIndex-2]-1;
					characterIndex -= 2;
				}
			}
			else
			{
				Special[boss] = GetRandomInt(0, Specials-1);
			}

			static char companionName[64];
			KvRewind(BossKV[Special[boss]]);
			KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName));
			if(MapBlocked[Special[boss]] ||
			   KvGetNum(BossKV[Special[boss]], "blocked") ||
			   KvGetNum(BossKV[Special[boss]], "donator") ||
			   KvGetNum(BossKV[Special[boss]], "admin") ||
			   KvGetNum(BossKV[Special[boss]], "owner") ||
			   KvGetNum(BossKV[Special[boss]], "theme") ||
			  (KvGetNum(BossKV[Special[boss]], "nofirst") && FF2Globals.RoundCount<=FF2GlobalsCvars.ArenaRounds) ||
			  (companionName[0] && !FF2GlobalsCvars.DuoMin) ||
			  (FF2Globals.Enabled3 && (KvGetNum(BossKV[Special[boss]], "noversus")==2 ||
			  (KvGetNum(BossKV[Special[boss]], "noversus")==1 && BossSwitched[boss]) ||
			  (KvGetNum(BossKV[Special[boss]], "bossteam")==FF2Globals.BossTeam && BossSwitched[boss]) ||
			  (KvGetNum(BossKV[Special[boss]], "bossteam")==FF2Globals.OtherTeam && !BossSwitched[boss]))))
			{
				Special[boss] = -1;
				continue;
			}
			break;
		}
	}
	else
	{
		static char bossName[64], companionName[64];
		KvRewind(BossKV[Special[boss]]);
		KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName), "=Failed companion name=");

		int character;
		while(character < Specials)  //Loop through all the FF2Globals.Bosses to find the companion we're looking for
		{
			KvRewind(BossKV[character]);
			KvGetString(BossKV[character], "name", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				Special[companion] = character;
				break;
			}

			KvGetString(BossKV[character], "filename", bossName, sizeof(bossName), "=Failed name=");
			if(StrEqual(bossName, companionName, false))
			{
				Special[companion] = character;
				break;
			}
			character++;
		}

		if(character == Specials)  //Companion not found
			return false;
	}

	//All of the following uses `companion` because it will always be the boss index we want
	int characterIndex = Special[companion];
	Action action = Forwards_Call_OnCharSelected(companion, characterIndex, newName, sizeof(newName), false);
	KvRewind(BossKV[Special[companion]]);
	KvGetString(BossKV[Special[companion]], "name", newName, sizeof(newName));
	if(action == Plugin_Changed)
	{
		if(newName[0])
		{
			int foundExactMatch = -1;
			int foundPartialMatch = -1;
			for(int character; BossKV[character] && character<MAXSPECIALS; character++)
			{
				KvRewind(BossKV[character]);
				KvGetString(BossKV[character], "name", characterName, sizeof(characterName));
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
				KvGetString(BossKV[character], "filename", characterName, sizeof(characterName));
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
				Special[companion] = foundExactMatch;
			}
			else if(foundPartialMatch != -1)
			{
				Special[companion] = foundPartialMatch;
			}
			else
			{
				return false;
			}
			KvGetString(BossKV[Special[companion]], "filename", characterName, sizeof(characterName));
			FF2SavedAbility.RegisterCharacter(characterName, companion);
			PrecacheCharacter(Special[companion]);
			return true;
		}
		Special[companion] = characterIndex;
		KvGetString(BossKV[Special[companion]], "filename", characterName, sizeof(characterName));
		FF2SavedAbility.RegisterCharacter(characterName, companion);
		PrecacheCharacter(Special[companion]);
		return true;
	}
	KvGetString(BossKV[Special[companion]], "filename", characterName, sizeof(characterName));
	FF2SavedAbility.RegisterCharacter(characterName, companion);
	PrecacheCharacter(Special[companion]);
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
	BossKV[Specials] = CreateKeyValues("character");
	FileToKeyValues(BossKV[Specials], config);

	MapBlocked[Specials] = false;
	if(KvJumpToKey(BossKV[Specials], "map_only"))
	{
		char item[6];
		static char buffer[34];
		bool shouldBlock = true;
		for(int size=1; ; size++)
		{
			FormatEx(item, sizeof(item), "map%d", size);
			KvGetString(BossKV[Specials], item, buffer, sizeof(buffer));
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
		MapBlocked[Specials] = shouldBlock;
	}
	KvRewind(BossKV[Specials]);
	if(KvJumpToKey(BossKV[Specials], "map_exclude"))
	{
		char item[6];
		static char buffer[34];
		for(int size=1; ; size++)
		{
			FormatEx(item, sizeof(item), "map%d", size);
			KvGetString(BossKV[Specials], item, buffer, sizeof(buffer));
			if(!buffer[0])
				break;

			if(!StrContains(FF2Globals.CurrentMap, buffer))
			{
				MapBlocked[Specials] = true;
				break;
			}
		}
	}
	KvRewind(BossKV[Specials]);

	int version = KvGetNum(BossKV[Specials], "version", StringToInt(MAJOR_REVISION));
	if(version!=StringToInt(MAJOR_REVISION) && version!=99) // 99 for FF2Globals.Bosses made ONLY for this fork
	{
		LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is only compatible with FF2 v%i!", character, version);
		return;
	}

	version = KvGetNum(BossKV[Specials], "version_minor", StringToInt(MINOR_REVISION));
	int version2 = KvGetNum(BossKV[Specials], "version_stable", StringToInt(STABLE_REVISION));
	if(version>StringToInt(MINOR_REVISION) || (version2>StringToInt(STABLE_REVISION) && version==StringToInt(MINOR_REVISION)))
	{
		LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s requires newer version of FF2 (at least %s.%i.%i)!", character, MAJOR_REVISION, version, version2);
		return;
	}

	version = KvGetNum(BossKV[Specials], "fversion", StringToInt(FORK_MAJOR_REVISION));
	if(version != StringToInt(FORK_MAJOR_REVISION))
	{
		LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is only compatible with %s FF2 v%i!", character, FORK_SUB_REVISION, version);
		return;
	}

	version = KvGetNum(BossKV[Specials], "fversion_minor", StringToInt(FORK_MINOR_REVISION));
	version2 = KvGetNum(BossKV[Specials], "fversion_stable", StringToInt(FORK_STABLE_REVISION));
	if(version>StringToInt(FORK_MINOR_REVISION) || (version2>StringToInt(FORK_STABLE_REVISION) && version==StringToInt(FORK_MINOR_REVISION)))
	{
		LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s requires newer version of %s FF2 (at least %s.%i.%i)!", character, FORK_SUB_REVISION, FORK_MAJOR_REVISION, version, version2);
		return;
	}

	for(int i=1; ; i++)
	{
		Format(config, sizeof(config), "ability%i", i);
		if(KvJumpToKey(BossKV[Specials], config))
		{
			static char plugin_name[64];
			KvGetString(BossKV[Specials], "plugin_name", plugin_name, 64);
			BuildPath(Path_SM, config, sizeof(config), "plugins/freaks/%s.smx", plugin_name);
			if(!FileExists(config))
			{
				LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s needs plugin %s!", character, plugin_name);
				return;
			}
			KvRewind(BossKV[Specials]);
		}
		else
		{
			break;
		}
	}


	char key[PLATFORM_MAX_PATH];
	static char section[64];
	KvSetString(BossKV[Specials], "filename", character);
	KvGetString(BossKV[Specials], "name", config, sizeof(config));
	bBlockVoice[Specials] = view_as<bool>(KvGetNum(BossKV[Specials], "sound_block_vo"));
	BossSpeed[Specials] = KvGetFloat(BossKV[Specials], "maxspeed", 340.0);
	KvGotoFirstSubKey(BossKV[Specials]);

	while(KvGotoNextKey(BossKV[Specials]))
	{
		KvGetSectionName(BossKV[Specials], section, sizeof(section));
		if(StrEqual(section, "download"))
		{
			for(int i=1; ; i++)
			{
				IntToString(i, key, sizeof(key));
				KvGetString(BossKV[Specials], key, config, sizeof(config));
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
				KvGetString(BossKV[Specials], key, config, sizeof(config));
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
				KvGetString(BossKV[Specials], key, config, sizeof(config));
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
	Specials++;
}

void LoadSideCharacter(const char[] character, int pack)
{
	static char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s.cfg", ConfigPath, character);
	if(!FileExists(config))
		return;

	PackKV[PackSpecials[pack]][pack] = CreateKeyValues("character");
	FileToKeyValues(PackKV[PackSpecials[pack]][pack], config);
	KvSetString(PackKV[PackSpecials[pack]][pack], "filename", character);

	int version = KvGetNum(PackKV[PackSpecials[pack]][pack], "version", StringToInt(MAJOR_REVISION));
	if(version!=StringToInt(MAJOR_REVISION) && version!=99) // 99 for FF2Globals.Bosses made ONLY for this fork
		return;

	version = KvGetNum(PackKV[PackSpecials[pack]][pack], "version_minor", StringToInt(MINOR_REVISION));
	if(version > StringToInt(MINOR_REVISION))
		return;

	int version2 = KvGetNum(PackKV[PackSpecials[pack]][pack], "version_stable", StringToInt(STABLE_REVISION));
	if(version2>StringToInt(STABLE_REVISION) && version==StringToInt(MINOR_REVISION))
		return;

	version = KvGetNum(PackKV[PackSpecials[pack]][pack], "fversion", StringToInt(FORK_MAJOR_REVISION));
	if(version != StringToInt(FORK_MAJOR_REVISION))
		return;

	version = KvGetNum(PackKV[PackSpecials[pack]][pack], "fversion_minor", StringToInt(FORK_MINOR_REVISION));
	if(version > StringToInt(FORK_MINOR_REVISION))
		return;

	version2 = KvGetNum(PackKV[PackSpecials[pack]][pack], "fversion_stable", StringToInt(FORK_STABLE_REVISION));
	if(version2>StringToInt(FORK_STABLE_REVISION) && version==StringToInt(FORK_MINOR_REVISION))
		return;

	PackSpecials[pack]++;
}

void PrecacheCharacter(int characterIndex)
{
	char filePath[PLATFORM_MAX_PATH], key[8];
	static char file[PLATFORM_MAX_PATH], section[16], bossName[64];
	KvRewind(BossKV[characterIndex]);
	KvGetString(BossKV[characterIndex], "filename", bossName, sizeof(bossName));
	KvGotoFirstSubKey(BossKV[characterIndex]);
	while(KvGotoNextKey(BossKV[characterIndex]))
	{
		KvGetSectionName(BossKV[characterIndex], section, sizeof(section));
		if(StrEqual(section, "sound_bgm"))
		{
			for(int i=1; ; i++)
			{
				FormatEx(key, sizeof(key), "path%d", i);
				KvGetString(BossKV[characterIndex], key, file, sizeof(file));
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
				KvGetString(BossKV[characterIndex], key, file, sizeof(file));
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
	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], "companion", companionName, sizeof(companionName));
	if(playersNeeded<players && companionName[0])  //Only continue if we have enough players and if the boss has a companion
	{
		int companion = Utils_GetRandomValidClient(omit);
		Boss[companion] = companion;
		BossSwitched[companion] = BossSwitched[boss];
		omit[companion] = true;
		int client = Boss[boss];
		if(PickCharacter(boss, companion))  //TODO: This is a bit misleading
		{
			if(BossRageDamage[companion] == 1)	// If 1, toggle infinite rage
			{
				InfiniteRageActive[client] = true;
				CreateTimer(0.2, Timer_InfiniteRage, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				BossRageDamage[companion] = 1;
			}
			else if(BossRageDamage[companion] == -1)	// If -1, never rage
			{
				BossRageDamage[companion] = 99999;
			}
			else	// Use formula or straight value
			{
				BossRageDamage[companion] = ParseFormula(companion, "ragedamage", FF2GlobalsCvars.RageDamage, 1900);
			}
			BossLivesMax[companion] = KvGetNum(BossKV[Special[companion]], "lives", 1);
			if(BossLivesMax[companion] < 1)
			{
				LogToFile(FF2LogsPaths.Errors, "[Boss] Boss %s has an invalid amount of lives, setting to 1", companionName);
				BossLivesMax[companion] = 1;
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
		if(!StrEqual(section, dIncoming[Boss[boss]]))
			continue;

		static char plugin[80];
		KvRewind(BossKV[Special[boss]]);
		KvGetString(BossKV[Special[boss]], "filename", plugin, sizeof(plugin));
		if(!KvGetNum(FF2ModsInfo.DiffCfg, plugin, KvGetNum(FF2ModsInfo.DiffCfg, "default", 1)))
			break;

		SpecialRound = true;
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