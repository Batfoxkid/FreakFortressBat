bool BossTargetFilter(const char[] pattern, Handle clients)
{
	bool non = StrContains(pattern, "!", false)!=-1;
	for(int client=1; client<=MaxClients; client++)
	{
		if(!Utils_IsValidClient(client) || FindValueInArray(clients, client)!=-1)
			continue;

		if(Utils_IsBoss(client))
		{
			if(!non)
				PushArrayCell(clients, client);
		}
		else if(non)
		{
			PushArrayCell(clients, client);
		}
	}
	return true;
}

Action Command_SetNextBoss(int client, int args)
{
	static char boss[64];
	if(args < 1)
	{
		if(!Utils_IsValidClient(client))
		{
			ReplyToCommand(client, "[SM] Usage: ff2_special <boss>");
			return Plugin_Handled;
		}

		Utils_GetBossSpecial(Incoming[0], boss, sizeof(boss), client);

		Menu menu = new Menu(Command_SetNextBossH);
		menu.SetTitle("Override Next Boss\n  Current Selection: %s", boss);

		strcopy(boss, sizeof(boss), "No Override");
		menu.AddItem(boss, boss);

		for(int config; config<Specials; config++)
		{
			Utils_GetBossSpecial(config, boss, sizeof(boss), client);
			menu.AddItem(boss, boss);
		}

		menu.ExitButton = true;
		menu.Display(client, 20);
		return Plugin_Handled;
	}

	static char name[64];
	GetCmdArgString(name, sizeof(name));

	for(int config; config<Specials; config++)
	{
		Utils_GetBossSpecial(config, boss, sizeof(boss), client);
		if(StrContains(boss, name, false) != -1)
		{
			Incoming[0] = config;
			FReplyToCommand(client, "Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrContains(boss, name, false) != -1)
		{
			Incoming[0] = config;
			Utils_GetBossSpecial(config, boss, sizeof(boss), client);
			FReplyToCommand(client, "Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvGetString(BossKV[config], "filename", boss, sizeof(boss));
		if(StrContains(boss, name, false) != -1)
		{
			Incoming[0] = config;
			Utils_GetBossSpecial(config, boss, sizeof(boss), client);
			FReplyToCommand(client, "Set the next boss to %s", boss);
			return Plugin_Handled;
		}
	}
	FReplyToCommand(client, "Boss could not be found!");
	return Plugin_Handled;
}

int Command_SetNextBossH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			switch(choice)
			{
				case 0:
				{
					Incoming[0] = 0;
					FReplyToCommand(client, "No override to the next boss");
				}
				default:
				{
					int choice2 = choice-1;
					Incoming[0] = choice2;
					static char boss[64];
					Utils_GetBossSpecial(choice2, boss, sizeof(boss), client);
					FReplyToCommand(client, "Set the next boss to %s", boss);
				}
			}
		}
	}
}

Action Command_Points(int client, int args)
{
	if(args != 2)
	{
		FReplyToCommand(client, "Usage: ff2_addpoints <target> <points>");
		return Plugin_Handled;
	}

	static char stringPoints[8], pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, stringPoints, sizeof(stringPoints));
	int points = StringToInt(stringPoints);

	static char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches > 1)
	{
		for(int target; target<matches; target++)
		{
			if(IsClientSourceTV(targets[target]) || IsClientReplay(targets[target]))
				continue;

			QueuePoints[targets[target]] += points;
			LogAction(client, targets[target], "\"%L\" added %d queue points to \"%L\"", client, points, targets[target]);
		}
	}
	else
	{
		QueuePoints[targets[0]] += points;
		LogAction(client, targets[0], "\"%L\" added %d queue points to \"%L\"", client, points, targets[0]);
	}
	FReplyToCommand(client, "Added %d queue points to %s", points, targetName);
	return Plugin_Handled;
}

Action Command_StartMusic(int client, int args)
{
	if(Enabled2)
	{
		if(args)
		{
			static char pattern[MAX_TARGET_LENGTH];
			GetCmdArg(1, pattern, sizeof(pattern));
			static char targetName[MAX_TARGET_LENGTH];
			int targets[MAXPLAYERS], matches;
			bool targetNounIsMultiLanguage;
			if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
			{
				ReplyToTargetError(client, matches);
				return Plugin_Handled;
			}

			if(matches > 1)
			{
				for(int target; target<matches; target++)
				{
					StartMusic(targets[target]);
				}
			}
			else
			{
				StartMusic(targets[0]);
			}
			FReplyToCommand(client, "Started boss music for %s.", targetName);
		}
		else
		{
			StartMusic();
			FReplyToCommand(client, "Started boss music for all clients.");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action Command_StopMusic(int client, int args)
{
	if(!Enabled2)
		return Plugin_Handled;

	if(args)
	{
		static char pattern[MAX_TARGET_LENGTH];
		GetCmdArg(1, pattern, sizeof(pattern));
		static char targetName[MAX_TARGET_LENGTH];
		int targets[MAXPLAYERS], matches;
		bool targetNounIsMultiLanguage;
		if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
		{
			ReplyToTargetError(client, matches);
			return Plugin_Handled;
		}

		if(matches>1)
		{
			for(int target; target<matches; target++)
			{
				StopMusic(targets[target], true);
			}
		}
		else
		{
			StopMusic(targets[0], true);
		}
		FReplyToCommand(client, "Stopped boss music for %s.", targetName);
		return Plugin_Handled;
	}

	StopMusic(_, true);
	FReplyToCommand(client, "Stopped boss music for all clients.");
	return Plugin_Handled;
}

Action Command_Charset(int client, int args)
{
	if(!args)
	{
		if(!client)
		{
			ReplyToCommand(client, "[SM] Usage: ff2_charset <charset>");
			return Plugin_Handled;
		}
		if(IsVoteInProgress())
		{
			ReplyToCommand(client, "[SM] %t", "Vote in Progress");
			return Plugin_Handled;
		}

		Menu menu = new Menu(Command_CharsetH);
		menu.SetTitle("Charset");

		static char config[PLATFORM_MAX_PATH], charset[64];
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

		Handle Kv = CreateKeyValues("");
		FileToKeyValues(Kv, config);
		int total;
		do
		{
			total++;
			KvGetSectionName(Kv, charset, sizeof(charset));
			menu.AddItem(charset, charset);
		}
		while(KvGotoNextKey(Kv));
		delete Kv;

		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}

	static char charset[32], rawText[16][16];
	GetCmdArgString(charset, sizeof(charset));
	int amount = ExplodeString(charset, " ", rawText, 16, 16);
	for(int i; i<amount; i++)
	{
		StripQuotes(rawText[i]);
	}
	ImplodeStrings(rawText, amount, " ", charset, sizeof(charset));

	static char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(int i; ; i++)
	{
		KvGetSectionName(Kv, config, sizeof(config));
		if(StrContains(config, charset, false) >= 0)
		{
			FReplyToCommand(client, "Charset for nextmap is %s", config);
			isCharSetSelected = true;
			cvarCharset.IntValue = i;
			break;
		}

		if(!KvGotoNextKey(Kv))
		{
			FReplyToCommand(client, "Charset not found");
			break;
		}
	}
	delete Kv;
	return Plugin_Handled;
}

int Command_CharsetH(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			cvarCharset.IntValue = choice;

			static char nextmap[32];
			cvarNextmap.GetString(nextmap, sizeof(nextmap));
			menu.GetItem(choice, FF2CharSetString, sizeof(FF2CharSetString));
			FPrintToChat(client, "%t", "nextmap_charset", nextmap, FF2CharSetString);
			isCharSetSelected = true;
		}
	}
}

Action Command_LoadCharset(int client, int args)
{
	if(!args)
	{
		if(!client)
		{
			ReplyToCommand(client, "[SM] Usage: ff2_loadcharset <charset>");
			return Plugin_Handled;
		}
		if(IsVoteInProgress())
		{
			ReplyToCommand(client, "[SM] %t", "Vote in Progress");
			return Plugin_Handled;
		}

		Menu menu = new Menu(Command_LoadCharsetH);
		menu.SetTitle("Charset");

		static char config[PLATFORM_MAX_PATH], charset[64];
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

		Handle Kv = CreateKeyValues("");
		FileToKeyValues(Kv, config);
		int total;
		do
		{
			total++;
			KvGetSectionName(Kv, charset, sizeof(charset));
			menu.AddItem(charset, charset);
		}
		while(KvGotoNextKey(Kv));
		delete Kv;

		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}

	static char charset[32], rawText[16][16];
	GetCmdArgString(charset, sizeof(charset));
	int amount=ExplodeString(charset, " ", rawText, 16, 16);
	for(int i; i<amount; i++)
	{
		StripQuotes(rawText[i]);
	}
	ImplodeStrings(rawText, amount, " ", charset, sizeof(charset));

	static char config[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(int i; ; i++)
	{
		KvGetSectionName(Kv, config, sizeof(config));
		if(StrContains(config, charset, false) >= 0)
		{
			cvarCharset.IntValue = i;
			LoadCharset = true;
			if(!Utils_CheckRoundState() || Utils_CheckRoundState()==1)
			{
				FReplyToCommand(client, "The current character set is set to be switched to %s!", config);
				return Plugin_Handled;
			}

			FReplyToCommand(client, "Character set has been switched to %s", config);
			FindCharacters();
			FF2CharSetString[0] = 0;
			LoadCharset = false;
			break;
		}

		if(!KvGotoNextKey(Kv))
		{
			FReplyToCommand(client, "Charset not found");
			break;
		}
	}
	delete Kv;
	return Plugin_Handled;
}

Action Command_ReloadFF2(int client, int args)
{
	if(ReloadFF2)
	{
		FReplyToCommand(client, "The plugin is no longer set to reload.");
		ReloadFF2 = false;
		return Plugin_Handled;
	}
	ReloadFF2 = true;
	if(!Utils_CheckRoundState() || Utils_CheckRoundState()==1)
	{
		FReplyToCommand(client, "The plugin is set to reload.");
		return Plugin_Handled;
	}
	FReplyToCommand(client, "The plugin has been reloaded.");
	ReloadFF2 = false;
	ServerCommand("sm plugins reload freak_fortress_2");
	return Plugin_Handled;
}

Action Command_ReloadCharset(int client, int args)
{
	if(LoadCharset)
	{
		FReplyToCommand(client, "Current character set no longer set to reload!");
		LoadCharset = false;
		return Plugin_Handled;
	}
	LoadCharset = true;
	if(!Utils_CheckRoundState() || Utils_CheckRoundState()==1)
	{
		FReplyToCommand(client, "Current character set is set to reload!");
		return Plugin_Handled;
	}
	FReplyToCommand(client, "Current character set has been reloaded!");
	FindCharacters();
	FF2CharSetString[0] = 0;
	LoadCharset = false;
	return Plugin_Handled;
}

Action Command_ReloadFF2Weapons(int client, int args)
{
	if(ReloadWeapons)
	{
		FReplyToCommand(client, "%s is no longer set to reload!", WeaponCFG);
		ReloadWeapons = false;
		return Plugin_Handled;
	}
	ReloadWeapons = true;
	if(!Utils_CheckRoundState() || Utils_CheckRoundState()==1)
	{
		FReplyToCommand(client, "%s is set to reload!", WeaponCFG);
		return Plugin_Handled;
	}
	FReplyToCommand(client, "%s has been reloaded!", WeaponCFG);
	CacheWeapons();
	ReloadWeapons = false;
	return Plugin_Handled;
}

Action Command_ReloadFF2Configs(int client, int args)
{
	if(ReloadConfigs)
	{
		FReplyToCommand(client, "All configs are no longer set to be reloaded!");
		ReloadConfigs = false;
		return Plugin_Handled;
	}
	ReloadConfigs = true;
	if(!Utils_CheckRoundState() || Utils_CheckRoundState()==1)
	{
		FReplyToCommand(client, "All configs are set to be reloaded!");
		return Plugin_Handled;
	}
	CacheWeapons();
	CacheDifficulty();
	Utils_CheckToChangeMapDoors();
	Utils_CheckToTeleportToSpawn();
	FindCharacters();
	FF2CharSetString[0] = 0;
	ReloadConfigs = false;
	return Plugin_Handled;
}

Action Command_ReloadSubPlugins(int client, int args)
{
	if(!Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(!args) // Reload ALL subplugins
	{
		DisableSubPlugins(true);
		EnableSubPlugins(true);
		FReplyToCommand(client, "Reloaded all subplugins!");
		return Plugin_Handled;
	}

	static char pluginName[80], filepath[PLATFORM_MAX_PATH];
	GetCmdArg(1, pluginName, sizeof(pluginName));
	BuildPath(Path_SM, filepath, sizeof(filepath), "plugins/freaks/%s.smx", pluginName);
	if(!FileExists(filepath))
	{
		FReplyToCommand(client, "Subplugin %s does not exist!", pluginName);
		return Plugin_Handled;
	}
	ServerCommand("sm plugins unload freaks/%s", pluginName);
	ServerCommand("sm plugins load freaks/%s", pluginName);
	FReplyToCommand(client, "Reloaded subplugin %s!", pluginName);
	return Plugin_Handled;
}

Action Command_Point_Disable(int client, int args)
{
	if(Enabled)
	{
		Utils_SetControlPoint(false);
		return Plugin_Handled;
	}
	FReplyToCommand(client, "%t", "FF2 Disabled");
	return Plugin_Handled;
}

Action Command_Point_Enable(int client, int args)
{
	if(Enabled)
	{
		Utils_SetControlPoint(true);
		return Plugin_Handled;
	}
	FReplyToCommand(client, "%t", "FF2 Disabled");
	return Plugin_Handled;
}

Action Command_GetHPCmd(int client, int args)
{
	if(!Utils_IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!Enabled2)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(Utils_CheckRoundState()!=1 || cvarHealthHud.IntValue>1)
		return Plugin_Handled;

	Command_GetHP(client);
	return Plugin_Handled;
}

Action Command_GetHP(int client)  //TODO: This can rarely show a very large negative number if you time it right
{
	if(Utils_IsBoss(client) || GetGameTime()>=HPTime)
	{
		char[][] text = new char[MaxClients+1][512];
		static char name[64];
		bool multi;
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Utils_IsValidClient(Boss[boss]))
			{
				char lives[8];
				if(BossLives[boss] > 1)
					FormatEx(lives, sizeof(lives), "x%i", BossLives[boss]);

				for(int target; target<=MaxClients; target++)
				{
					if(Utils_IsValidClient(target))
					{
						Utils_GetBossSpecial(Special[boss], name, sizeof(name), target);
						Format(text[target], 512, "%s\n%t", multi ? text[target] : "", "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
						FPrintToChat(target, "%t", "ff2_hp", name, BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1), BossHealthMax[boss], lives);
					}
				}
				multi = true;
				BossHealthLast[boss] = BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
			}
		}

		if((IsPlayerAlive(client) || IsClientObserver(client)) && !HudSettings[client][4] && !(FF2flags[client] & FF2FLAG_HUDDISABLED))
		{
			for(int target; target<=MaxClients; target++)
			{
				if(Utils_IsValidClient(target))
				{
					if(bosses<2 && cvarGameText.IntValue>0)
					{
						if(BossIcon[0])
						{
							Utils_ShowGameText(target, BossIcon, _, text[client]);
						}
						else
						{
							Utils_ShowGameText(target, "leaderboard_streak", _, text[client]);
						}
					}
					else
					{
						PrintCenterText(target, text[client]);
					}
				}
			}
		}

		if(GetGameTime() >= HPTime)
		{
			healthcheckused++;
			HPTime = GetGameTime()+(healthcheckused<3 ? 20.0 : 80.0);
		}
		return Plugin_Continue;
	}

	static char waitTime[128];
	for(int target; target<=MaxClients; target++)
	{
		if(Utils_IsBoss(target))
			Format(waitTime, sizeof(waitTime), "%s %i,", waitTime, BossHealthLast[Boss[target]]);
	}
	FPrintToChat(client, "%t", "wait_hp", RoundFloat(HPTime-GetGameTime()), waitTime);
	return Plugin_Continue;
}

Action QueuePanelCmd(int client, int args)
{
	bool[] added = new bool[MaxClients+1];
	for(int boss; boss<=MaxClients; boss++)
	{	// Don't want the bosses to show up again in the actual queue list
		if(Utils_IsBoss(boss))
			added[boss] = true;
	}

	Menu menu = new Menu(QueuePanelH);
	menu.SetTitle("%T", "thequeue", client);
	char text[64];
	for(int i; i<9; i++)
	{
		int target = Utils_GetClientWithMostQueuePoints(added, _, false);  //Get whoever has the highest queue points out of those who haven't been listed yet
		if(!Utils_IsValidClient(target))  //When there's no players left, fill up the rest of the list with blank lines
		{
			menu.AddItem("", "");
			continue;
		}

		FormatEx(text, sizeof(text), "%N-%i", target, QueuePoints[target]);
		menu.AddItem(text, text, client==target ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		added[target] = true;
	}

	FormatEx(text, sizeof(text), "%T (%T)", "your_points", client, QueuePoints[client], "to0", client);  //"Your queue point(s) is {1} (set to 0)"
	menu.AddItem(text, text);

	menu.Pagination = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

Action ResetQueuePointsCmd(int client, int args)
{
	if(client && !args)  //Normal players
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(!client)  //No confirmation for console
	{
		TurnToZeroPanelH(view_as<Menu>(INVALID_HANDLE), MenuAction_Select, client, 0);
		return Plugin_Handled;
	}

	AdminId admin = GetUserAdmin(client);	 //Normal players
	if((admin==INVALID_ADMIN_ID) || !GetAdminFlag(admin, Admin_Cheats))
	{
		TurnToZeroPanel(client, client);
		return Plugin_Handled;
	}

	if(args != 1)  //Admins
	{
		FReplyToCommand(client, "Usage: ff2_resetqueuepoints <target>");
		return Plugin_Handled;
	}

	static char pattern[MAX_TARGET_LENGTH];
	GetCmdArg(1, pattern, sizeof(pattern));
	static char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, 1, 0, targetName, sizeof(targetName), targetNounIsMultiLanguage)) < 1)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	if(matches > 1)
	{
		for(int target; target<matches; target++)
		{
			TurnToZeroPanel(client, targets[target]);  //FIXME:  This can only handle one client currently and doesn't iterate through all clients
		}
	}
	else
	{
		TurnToZeroPanel(client, targets[0]);
	}
	return Plugin_Handled;
}

Action FF2Panel(int client, int args)  //._.
{
	if(!Utils_IsValidClient(client, false))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	Menu menu = new Menu(FF2PanelH);
	char text[256];
	SetGlobalTransTarget(client);
	FormatEx(text, sizeof(text), "%t", "menu_1");  //What's up?
	menu.SetTitle(text);
	FormatEx(text, sizeof(text), "%t", "menu_2");  //Investigate the boss's current health level (/ff2hp)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_3");  //Boss Preferences (/ff2boss)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_7");  //Changes to my class in FF2 (/ff2classinfo)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_4");  //What's new? (/ff2new).
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_5");  //Queue points
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_0");  //Toggle HUDs (/ff2hud)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_8");  //Toggle music (/ff2music)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_9");  //Toggle monologues (/ff2voice)
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "menu_9a");  //Toggle info about changes of classes in FF2
	menu.AddItem(text, text);
	menu.Pagination = false;
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

Action NewPanelCmd(int client, int args)
{
	if(!Utils_IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	static char url[192];
	cvarChangelog.GetString(url, sizeof(url));
	Format(url, sizeof(url), "%s#%s.%s.%s", url, FORK_MAJOR_REVISION, FORK_MINOR_REVISION, FORK_STABLE_REVISION);
	KeyValues kv = CreateKeyValues("data");
	kv.SetString("title", "Unofficial FF2 Changelog");
	kv.SetString("msg", url);
	kv.SetNum("customsvr", 1);
	kv.SetNum("type", MOTDPANEL_TYPE_URL);
	ShowVGUIPanel(client, "info", kv, true);
	delete kv;
	return Plugin_Handled;
}

Action HelpPanel3Cmd(int client, int args)
{
	if(!Utils_IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!cvarAdvancedMusic.BoolValue)
	{
		HelpPanel3(client);
	}
	else
	{
		ToggleClassInfo(client);
	}

	return Plugin_Handled;
}

Action Command_HelpPanelClass(int client, int args)
{
	if(!Utils_IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!Enabled2)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	HelpPanelClass(client);
	return Plugin_Handled;
}

Action MusicTogglePanelCmd(int client, int args)
{
	if(!Utils_IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(args)
	{
		static char cmd[64];
		GetCmdArgString(cmd, sizeof(cmd));
		if(StrContains(cmd, "off", false)!=-1 || StrContains(cmd, "disable", false)!=-1 || StrContains(cmd, "0", false)!=-1)
		{
			ToggleBGM(client, false);
		}
		else if(StrContains(cmd, "on", false)!=-1 || StrContains(cmd, "enable", false)!=-1 || StrContains(cmd, "1", false)!=-1)
		{
			if(ToggleMusic[client])
			{
				FReplyToCommand(client, "You already have boss themes enabled...");
				return Plugin_Handled;
			}
			ToggleBGM(client, true);
		}
		FPrintToChat(client, "%t", "ff2_music", ToggleMusic[client] ? "on" : "off");	// TODO: Make this more multi-language friendly
		return Plugin_Handled;
	}

	MusicTogglePanel(client);
	return Plugin_Handled;
}

Action Command_SkipSong(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!cvarAdvancedMusic.BoolValue)
		return Plugin_Continue;

	if(!Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(StrEqual(currentBGM[client], "ff2_stop_music", true) || !ToggleMusic[client])
	{
		FReplyToCommand(client, "%t", "ff2_music_disabled");
		return Plugin_Handled;
	}

	if(Utils_CheckRoundState() != 1)
	{
		FReplyToCommand(client, "%t", "ff2_please wait");
		return Plugin_Handled;
	}

	FReplyToCommand(client, "%t", "track_skipped");

	StopMusic(client, true);

	KvRewind(BossKV[Special[0]]);
	if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH], id3[6][256];
		int index;
		do
		{
			index++;
			FormatEx(music, 10, "time%i", index);
		}
		while(KvGetFloat(BossKV[Special[0]], music) > 1);

		if(!index)
		{
			FReplyToCommand(client, "%t", "ff2_no_music");
			return Plugin_Handled;
		}

		cursongId[client]++;
		if(cursongId[client] >= index)
			cursongId[client] = 1;

		char lives[256];
		FormatEx(lives, sizeof(lives), "life%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
		if(lives[0])
		{
			if(StringToInt(lives) != BossLives[0])
			{
				for(int i; i<index-1; i++)
				{
					if(StringToInt(lives) != BossLives[0])
					{
						cursongId[client] = i;
						continue;
					}
					break;
				}
			}
		}

		FormatEx(music, 10, "time%i", cursongId[client]);
		float time = KvGetFloat(BossKV[Special[0]], music);
		FormatEx(music, 10, "path%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], music, music, sizeof(music));

		FormatEx(id3[0], sizeof(id3[]), "name%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
		FormatEx(id3[1], sizeof(id3[]), "artist%i", cursongId[client]);
		KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));

		char temp[PLATFORM_MAX_PATH];
		FormatEx(temp, sizeof(temp), "sound/%s", music);
		if(FileExists(temp, true))
		{
			PlayBGM(client, music, time, id3[2], id3[3]);
		}
		else
		{
			KvGetString(BossKV[Special[0]], "filename", lives, sizeof(lives));
			LogToFile(eLog, "[Boss] Character %s is missing BGM file '%s'!", lives, temp);
			if(MusicTimer[client] != null) {
				delete MusicTimer[client];
			}
		}
	}
	return Plugin_Handled;
}

Action Command_ShuffleSong(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!cvarAdvancedMusic.BoolValue)
		return Plugin_Continue;

	if(!Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(StrEqual(currentBGM[client], "ff2_stop_music", true) || !ToggleMusic[client])
	{
		FReplyToCommand(client, "%t", "ff2_music_disabled");
		return Plugin_Handled;
	}

	if(Utils_CheckRoundState()!=1)
	{
		FReplyToCommand(client, "%t", "ff2_please wait");
		return Plugin_Handled;
	}

	FReplyToCommand(client, "%t", "track_shuffle");
	StartMusic(client);
	return Plugin_Handled;
}

Action Command_Tracklist(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!cvarAdvancedMusic.BoolValue || cvarSongInfo.IntValue<0)
		return Plugin_Continue;

	if(!Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(StrEqual(currentBGM[client], "ff2_stop_music", true) || !ToggleMusic[client])
	{
		FReplyToCommand(client, "%t", "ff2_music_disabled");
		return Plugin_Handled;
	}

	if(Utils_CheckRoundState()!=1)
	{
		FReplyToCommand(client, "%t", "ff2_please wait");
		return Plugin_Handled;
	}

	Menu menu = new Menu(Command_TrackListH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "track_select");
	KvRewind(BossKV[Special[0]]);
	if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH], id3[6][256];
		int index;
		do
		{
			index++;
			FormatEx(music, 10, "time%i", index);
		}
		while(KvGetFloat(BossKV[Special[0]], music) > 1);

		if(!index)
		{
			FReplyToCommand(client, "%t", "ff2_no_music");
			return Plugin_Handled;
		}

		char lives[256];
		for(int trackIdx=1; trackIdx<=index-1; trackIdx++)
		{
			FormatEx(lives, sizeof(lives), "life%i", trackIdx);
			KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
			if(lives[0])
			{
				if(StringToInt(lives) != BossLives[0])
					continue;
			}
			FormatEx(id3[0], sizeof(id3[]), "name%i", trackIdx);
			KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
			FormatEx(id3[1], sizeof(id3[]), "artist%i", trackIdx);
			KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));
			Utils_GetSongTime(trackIdx, id3[5], sizeof(id3[]));
			if(!id3[3])
				FormatEx(id3[3], sizeof(id3[]), "%t", "unknown_artist");

			if(!id3[2])
				FormatEx(id3[2], sizeof(id3[]), "%t", "unknown_song");

			FormatEx(id3[4], sizeof(id3[]), "%s - %s (%s)", id3[3], id3[2], id3[5]);
			CRemoveTags(id3[4], sizeof(id3[]));
			menu.AddItem(id3[4], id3[4]);
		}
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

Action VoiceTogglePanelCmd(int client, int args)
{
	if(!Utils_IsValidClient(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!cvarAdvancedMusic.BoolValue)
	{
		VoiceTogglePanel(client);
	}
	else
	{
		if(ToggleVoice[client])
		{
			ToggleVoice[client] = false;
			FPrintToChat(client, "%t", "ff2_voice", "off");	// TODO: Make this more multi-language friendly
		}
		else
		{
			ToggleVoice[client] = true;
			FPrintToChat(client, "%t", "ff2_voice", "on");	// TODO: Make this more multi-language friendly
		}
	}
	return Plugin_Handled;
}

Action Command_Nextmap(int client, int args)
{
	if(FF2CharSetString[0])
	{
		static char nextmap[42];
		cvarNextmap.GetString(nextmap, sizeof(nextmap));
		FReplyToCommand(client, "%t", "nextmap_charset", nextmap, FF2CharSetString);
	}
	return Plugin_Handled;
}

public Action Command_Say(int client, int args)
{
	static char chat[32];
	if(GetCmdArgString(chat, sizeof(chat))<1 || !client)
		return Plugin_Continue;

	if(FF2CharSetString[0] && StrEqual(chat, "\"nextmap\""))
	{
		Command_Nextmap(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action Command_SetRage(int client, int args)
{
	if(args != 2)
	{
		if(args != 1)
		{
			FReplyToCommand(client, "Usage: ff2_setrage or hale_setrage <target> <percent>");
		}
		else
		{
			if(!Utils_IsValidClient(client))
			{
				ReplyToCommand(client, "[SM] %t", "Command is in-game only");
				return Plugin_Handled;
			}

			if(!Utils_IsBoss(client) || !IsPlayerAlive(client) || Utils_CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to set your RAGE!");
				return Plugin_Handled;
			}

			static char ragePCT[80];
			GetCmdArg(1, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);

			BossCharge[Utils_GetBossIndex(client)][0] = rageMeter;
			FReplyToCommand(client, "You now have %i percent RAGE", RoundFloat(BossCharge[client][0]));
			LogAction(client, client, "\"%L\" gave themselves %i RAGE", client, RoundFloat(rageMeter));
			CheatsUsed = true;
		}
		return Plugin_Handled;
	}

	static char ragePCT[80];
	static char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		if(!Utils_IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || Utils_CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to set RAGE!", target_name);
			return Plugin_Handled;
		}

		BossCharge[Utils_GetBossIndex(target_list[target])][0] = rageMeter;
		LogAction(client, target_list[target], "\"%L\" set %d RAGE to \"%L\"", client, RoundFloat(rageMeter), target_list[target]);
		FReplyToCommand(client, "Set %d rage to %s", RoundFloat(rageMeter), target_name);
		CheatsUsed = true;
	}
	return Plugin_Handled;
}

Action Command_AddRage(int client, int args)
{
	if(args != 2)
	{
		if(args != 1)
		{
			FReplyToCommand(client, "Usage: ff2_addrage or hale_addrage <target> <percent>");
		}
		else
		{
			if(!Utils_IsValidClient(client))
			{
				ReplyToCommand(client, "[SM] %t", "Command is in-game only");
				return Plugin_Handled;
			}

			if(!Utils_IsBoss(client) || !IsPlayerAlive(client) || Utils_CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to give yourself RAGE!");
				return Plugin_Handled;
			}

			static char ragePCT[80];
			GetCmdArg(1, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);

			BossCharge[Utils_GetBossIndex(client)][0] += rageMeter;
			FReplyToCommand(client, "You now have %i percent RAGE (%i percent added)", RoundFloat(BossCharge[client][0]), RoundFloat(rageMeter));
			LogAction(client, client, "\"%L\" gave themselves %i more RAGE", client, RoundFloat(rageMeter));
			CheatsUsed = true;
		}
		return Plugin_Handled;
	}

	static char ragePCT[80];
	static char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		if(!Utils_IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || Utils_CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to add RAGE!", target_name);
			return Plugin_Handled;
		}

		BossCharge[Utils_GetBossIndex(target_list[target])][0] += rageMeter;
		LogAction(client, target_list[target], "\"%L\" added %d RAGE to \"%L\"", client, RoundFloat(rageMeter), target_list[target]);
		FReplyToCommand(client, "Added %d rage to %s", RoundFloat(rageMeter), target_name);
		CheatsUsed = true;
	}
	return Plugin_Handled;
}

Action Command_AddCharge(int client, int args)
{
	if(args != 3)
	{
		if(args != 2)
		{
			FReplyToCommand(client, "Usage: ff2_addcharge or hale_addcharge <target> <slot> <percent>");
		}
		else
		{
			if(!Utils_IsValidClient(client))
			{
				ReplyToCommand(client, "[SM] %t", "Command is in-game only");
				return Plugin_Handled;
			}

			if(!Utils_IsBoss(client) || !IsPlayerAlive(client) || Utils_CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to add your charge!");
				return Plugin_Handled;
			}

			static char ragePCT[80], slotCharge[10];
			GetCmdArg(1, slotCharge, sizeof(slotCharge));
			GetCmdArg(2, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);
			int abilitySlot = StringToInt(slotCharge);

			if(abilitySlot>=0 && abilitySlot<4)
			{
				BossCharge[Utils_GetBossIndex(client)][abilitySlot] += rageMeter;
				FReplyToCommand(client, "Slot %i's charge: %i percent (added %i percent)!", abilitySlot, RoundFloat(BossCharge[Utils_GetBossIndex(client)][abilitySlot]), RoundFloat(rageMeter));
				LogAction(client, client, "\"%L\" gave themselves %i more charge to slot %i", client, RoundFloat(rageMeter), abilitySlot);
				CheatsUsed = true;
			}
			else
			{
				FReplyToCommand(client, "Invalid slot!");
			}
		}
		return Plugin_Handled;
	}

	static char ragePCT[80], slotCharge[10];
	static char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, slotCharge, sizeof(slotCharge));
	GetCmdArg(3, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);
	int abilitySlot = StringToInt(slotCharge);

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		if(!Utils_IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || Utils_CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to add their charge!", target_name);
			return Plugin_Handled;
		}

		if(abilitySlot>=0 || abilitySlot<4)
		{
			BossCharge[Utils_GetBossIndex(target_list[target])][abilitySlot] += rageMeter;
			FReplyToCommand(client, "%s's ability slot %i's charge: %i percent (added %i percent)!", target_name, abilitySlot, RoundFloat(BossCharge[Utils_GetBossIndex(target_list[target])][abilitySlot]), RoundFloat(rageMeter));
			LogAction(client, target_list[target], "\"%L\" gave \"%L\" %i more charge to slot %i", client, target_list[target], RoundFloat(rageMeter), abilitySlot);
			CheatsUsed = true;
		}
		else
		{
			FReplyToCommand(client, "Invalid slot!");
		}
	}
	return Plugin_Handled;
}

Action Command_SetCharge(int client, int args)
{
	if(args != 3)
	{
		if(args != 2)
		{
			FReplyToCommand(client, "Usage: ff2_setcharge or hale_setcharge <target> <slot> <percent>");
		}
		else
		{
			if(!Utils_IsValidClient(client))
			{
				ReplyToCommand(client, "[SM] %t", "Command is in-game only");
				return Plugin_Handled;
			}

			if(!Utils_IsBoss(client) || !IsPlayerAlive(client) || Utils_CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to set your charge!");
				return Plugin_Handled;
			}

			static char ragePCT[80], slotCharge[10];
			GetCmdArg(1, slotCharge, sizeof(slotCharge));
			GetCmdArg(2, ragePCT, sizeof(ragePCT));
			float rageMeter = StringToFloat(ragePCT);
			int abilitySlot = StringToInt(slotCharge);

			if(abilitySlot>=0 || abilitySlot<4)
			{
				BossCharge[Utils_GetBossIndex(client)][abilitySlot] = rageMeter;
				FReplyToCommand(client, "Slot %i's charge: %i percent!", abilitySlot, RoundFloat(BossCharge[Utils_GetBossIndex(client)][abilitySlot]));
				LogAction(client, client, "\"%L\" gave themselves %i charge to slot %i", client, RoundFloat(rageMeter), abilitySlot);
				CheatsUsed = true;
			}
			else
			{
				FReplyToCommand(client, "Invalid slot!");
			}
		}
		return Plugin_Handled;
	}

	static char ragePCT[80], slotCharge[10];
	static char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, slotCharge, sizeof(slotCharge));
	GetCmdArg(3, ragePCT, sizeof(ragePCT));
	float rageMeter = StringToFloat(ragePCT);
	int abilitySlot = StringToInt(slotCharge);

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		if(!Utils_IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || Utils_CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to set their charge!", target_name);
			return Plugin_Handled;
		}

		if(abilitySlot>=0 || abilitySlot<4)
		{
			BossCharge[Utils_GetBossIndex(target_list[target])][abilitySlot] = rageMeter;
			FReplyToCommand(client, "%s's ability slot %i's charge: %i percent!", target_name, abilitySlot, RoundFloat(BossCharge[Utils_GetBossIndex(target_list[target])][abilitySlot]));
			LogAction(client, target_list[target], "\"%L\" gave \"%L\" %i charge to slot %i", client, target_list[target], RoundFloat(rageMeter), abilitySlot);
			CheatsUsed = true;
		}
		else
		{
			FReplyToCommand(client, "Invalid slot!");
		}
	}
	return Plugin_Handled;
}

Action Command_MakeBoss(int client, int args)
{
	if(args < 1)
	{
		FReplyToCommand(client, "Usage: ff2_makeboss or hale_makeboss <target> [team] [special] [index]");
		return Plugin_Handled;
	}

	static char targetName[PLATFORM_MAX_PATH], teamString[4], specialString[4], indexString[4];
	GetCmdArg(1, targetName, sizeof(targetName));
	GetCmdArg(2, teamString, sizeof(teamString));
	int team = StringToInt(teamString);

	int special = -1;
	if(args > 2)
	{
		GetCmdArg(3, specialString, sizeof(specialString));
		special = StringToInt(specialString);
	}

	int index = -1;
	if(args > 3)
	{
		GetCmdArg(4, indexString, sizeof(indexString));
		index = StringToInt(indexString);
		if(index < 0)
		{
			FReplyToCommand(client, "Boss index can not be below 0!");
			return Plugin_Handled;
		}
		if(index > MaxClients)
		{
			FReplyToCommand(client, "Boss index can not be above %i!", MaxClients);
			return Plugin_Handled;
		}
	}

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	bool[] omit = new bool[MaxClients+1];
	int boss, boss2;
	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		omit[target_list[target]] = true;
		if(Utils_IsBoss(target_list[target]))
		{
			if(index >= 0)
			{
				Boss[boss] = 0;
				boss = index;
				Boss[boss] = target_list[target];
			}
			else
			{
				boss = Utils_GetBossIndex(target_list[target]);
			}

			if(team > 1)
			{
				BossSwitched[boss] = team==OtherTeam ? true : false;
			}
			else if(team > 0)
			{
				BossSwitched[boss] = GetRandomInt(0, 1) ? true : false;
			}

			if(special >= 0)
				Incoming[boss] = special;

			HasEquipped[boss] = false;
			PickCharacter(boss, boss);
			CreateTimer(0.3, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			if(index >= 0)
			{
				Boss[index] = target_list[target];
				if(team > 1)
				{
					BossSwitched[index] = team==OtherTeam ? true : false;
				}
				else if(team > 0)
				{
					BossSwitched[index] = GetRandomInt(0, 1) ? true : false;
				}

				if(special >= 0)
					Incoming[index] = special;

				HasEquipped[boss] = false;
				PickCharacter(index, index);
				CreateTimer(0.3, Timer_MakeBoss, index, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				while(boss2 <= MaxClients)
				{
					if(!Utils_IsValidClient(Boss[boss2]))
					{
						Boss[boss2] = target_list[target];
						if(team > 1)
						{
							BossSwitched[boss] = team==OtherTeam;
						}
						else if(team > 0)
						{
							BossSwitched[boss] = GetRandomInt(0, 1)==1;
						}

						if(special >= 0)
							Incoming[boss] = special;

						HasEquipped[boss] = false;
						PickCharacter(boss2, boss2);
						CreateTimer(0.3, Timer_MakeBoss, boss2, TIMER_FLAG_NO_MAPCHANGE);
						boss2++;
						break;
					}
					boss2++;
				}
				if(boss2 > MaxClients)
				{
					FReplyToCommand(client, "All boss indexes have been used!");
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Handled;
}

Action Command_SetInfiniteRage(int client, int args)
{
	if(args != 1)
	{
		if(args > 1)
		{
			FReplyToCommand(client, "Usage: ff2_setinfiniterage or hale_setinfiniterage <target>");
		}
		else
		{
			if(!Utils_IsValidClient(client))
			{
				ReplyToCommand(client, "[SM] %t", "Command is in-game only");
				return Plugin_Handled;
			}

			if(!Utils_IsBoss(client) || !IsPlayerAlive(client) || Utils_CheckRoundState()!=1)
			{
				FReplyToCommand(client, "You must be a boss to enable/disable infinite RAGE!");
				return Plugin_Handled;
			}

			if(!InfiniteRageActive[client])
			{
				InfiniteRageActive[client] = true;
				BossCharge[Utils_GetBossIndex(client)][0] = rageMax[client];
				FReplyToCommand(client, "Infinite RAGE activated");
				LogAction(client, client, "\"%L\" activated infinite RAGE on themselves", client);
				CreateTimer(0.2, Timer_InfiniteRage, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				CheatsUsed = true;
			}
			else
			{
				InfiniteRageActive[client] = false;
				FReplyToCommand(client, "Infinite RAGE deactivated");
				LogAction(client, client, "\"%L\" deactivated infinite RAGE on themselves", client);
				CheatsUsed = true;
			}
		}
		return Plugin_Handled;
	}

	static char targetName[PLATFORM_MAX_PATH];
	GetCmdArg(1, targetName, sizeof(targetName));

	static char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if((target_count=ProcessTargetString(targetName, client, target_list, MaxClients, 0, target_name, sizeof(target_name), tn_is_ml)) < 1)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int target; target<target_count; target++)
	{
		if(IsClientSourceTV(target_list[target]) || IsClientReplay(target_list[target]))
			continue;

		if(!Utils_IsBoss(target_list[target]) || !IsPlayerAlive(target_list[target]) || Utils_CheckRoundState()!=1)
		{
			FReplyToCommand(client, "%s must be a boss to enable/disable infinite RAGE!", target_name);
			return Plugin_Handled;
		}

		if(!InfiniteRageActive[target_list[target]])
		{
			InfiniteRageActive[target_list[target]] = true;
			BossCharge[Utils_GetBossIndex(target_list[target])][0] = rageMax[target_list[target]];
			FReplyToCommand(client, "Infinite RAGE activated for %s", target_name);
			LogAction(client, target_list[target], "\"%L\" activated infinite RAGE on \"%L\"", client, target_list[target]);
			CreateTimer(0.2, Timer_InfiniteRage, GetClientUserId(target_list[target]), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			CheatsUsed = true;
		}
		else
		{
			InfiniteRageActive[target_list[target]] = false;
			FReplyToCommand(client, "Infinite RAGE deactivated for %s", target_name);
			LogAction(client, target_list[target], "\"%L\" deactivated infinite RAGE on \"%L\"", client, target_list[target]);
		}
	}
	return Plugin_Handled;
}

Action CompanionMenu(int client, int args)
{
	if(Utils_IsValidClient(client) && cvarDuoBoss.BoolValue)
	{
		Menu menu = new Menu(MenuHandlerCompanion);
		SetGlobalTransTarget(client);
		menu.SetTitle("%t", "FF2 Companion Toggle Menu Title");

		char menuoption[128];
		FormatEx(menuoption, sizeof(menuoption), "%t", "Enable Companion Selection");
		menu.AddItem("FF2 Companion Toggle Menu", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Companion Selection");
		menu.AddItem("FF2 Companion Toggle Menu", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Companion Selection For Map");
		if(Enabled2)
		{
			menu.AddItem("FF2 Companion Toggle Menu", menuoption);
		}
		else
		{
			menu.AddItem("FF2 Companion Toggle Menu", menuoption, ITEMDRAW_DISABLED);
		}

		menu.ExitButton = true;
		menu.Display(client, 20);
	}
	return Plugin_Handled;
}

Action Command_HudMenu(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	Menu menu = new Menu(Command_HudMenuH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "FF2 Hud Menu Title");

	char menuOption[64];
	for(int i; i<(HUDTYPES-1); i++)
	{
		FormatEx(menuOption, sizeof(menuOption), "%t [%t]", HudTypes[i], HudSettings[client][i] ? "Off" : "On");
		menu.AddItem(menuOption, menuOption);
	}

	int value = HudSettings[client][HUDTYPES-1] ? HudSettings[client][HUDTYPES-1] : cvarDamageHud.IntValue;
	FormatEx(menuOption, sizeof(menuOption), "%t [%i]", HudTypes[HUDTYPES-1], value<3 ? 0 : value);
	menu.AddItem(menuOption, menuOption);

	menu.ExitButton = true;
	menu.Display(client, 20);
	return Plugin_Handled;
}

public Action BossMenu(int client, int args)
{
	if(Utils_IsValidClient(client) && cvarToggleBoss.BoolValue)
	{
		Menu menu = new Menu(MenuHandlerBoss);
		SetGlobalTransTarget(client);
		menu.SetTitle("%t", "FF2 Toggle Menu Title");

		char menuoption[128];
		FormatEx(menuoption, sizeof(menuoption), "%t", "Enable Queue Points");
		menu.AddItem("Boss Toggle", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Queue Points");
		menu.AddItem("Boss Toggle", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Queue Points For This Map");
		if(Enabled2)
		{
			menu.AddItem("Boss Toggle", menuoption);
		}
		else
		{
			menu.AddItem("Boss Toggle", menuoption, ITEMDRAW_DISABLED);
		}

		menu.ExitButton = true;
		menu.Display(client, 20);
	}
	return Plugin_Handled;
}

Action DiffMenu(int client, int args)
{
#pragma unused args
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(cvarDifficulty.BoolValue)
	{
		Menu menu = new Menu(MenuHandlerDifficulty);
		SetGlobalTransTarget(client);
		menu.SetTitle("%t", "FF2 Special Menu Title");

		char menuoption[128];
		FormatEx(menuoption, sizeof(menuoption), "%t", "Enable Special");
		menu.AddItem("FF2 Special Toggle Menu", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Special");
		menu.AddItem("FF2 Special Toggle Menu", menuoption);
		FormatEx(menuoption, sizeof(menuoption), "%t", "Disable Special For This Map");
		if(Enabled2 && kvDiffMods!=null)
		{
			menu.AddItem("FF2 Special Toggle Menu", menuoption);
		}
		else
		{
			menu.AddItem("FF2 Special Toggle Menu", menuoption, ITEMDRAW_DISABLED);
		}

		menu.ExitButton = true;
		menu.Display(client, 20);
		return Plugin_Handled;
	}

	if(kvDiffMods == null)
		return Plugin_Handled;

	if(!CheckCommandAccess(client, "ff2_difficulty", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}

	bool denyAll = (!cvarBossDesc.BoolValue || !ToggleInfo[client]) && (Utils_IsBoss(client) && Utils_CheckRoundState()!=2);

	char name[64];
	Menu menu = new Menu(DiffMenuH);
	SetGlobalTransTarget(client);

	menu.SetTitle("%t\n %t", "FF2 Difficulty Settings Menu Title", "ff2_boss_selection_diff", dIncoming[client][0] ? dIncoming[client] : "-");

	FormatEx(name, sizeof(name), "%t", "Off");
	menu.AddItem("", name, (!dIncoming[client][0] || denyAll || (Utils_IsBoss(client) && Utils_CheckRoundState()!=2)) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	KvRewind(kvDiffMods);
	KvGotoFirstSubKey(kvDiffMods);
	do
	{
		KvGetSectionName(kvDiffMods, name, sizeof(name));
		menu.AddItem(name, name, denyAll ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	} while(KvGotoNextKey(kvDiffMods));

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

Action Command_SetMyBoss(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(!cvarSelectBoss.BoolValue)
		return Plugin_Handled;

	if(!CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}

	if(args)
	{
		if(!Enabled2)
		{
			FReplyToCommand(client, "%t", "FF2 Disabled");
			return Plugin_Handled;
		}

		static char name[64], boss[64], bossName[64], fileName[64], companionName[64];
		GetCmdArgString(name, sizeof(name));

		for(int config; config<Specials; config++)
		{
			KvRewind(BossKV[config]);
			if(KvGetNum(BossKV[config], "blocked"))
			{
				if(config == Specials-1)
				{
					FReplyToCommand(client, "%t", "deny_unknown");
					return Plugin_Handled;
				}
				continue;
			}

			Utils_GetBossSpecial(config, bossName, sizeof(bossName), client);
			KvGetString(BossKV[config], "name", boss, sizeof(boss));
			if(StrContains(bossName, name, false))
			{
				if(StrContains(boss, name, false))
				{
					KvGetString(BossKV[config], "filename", fileName, sizeof(fileName));
					if(StrContains(fileName, name, false))
					{
						if(config == Specials-1)
						{
							FReplyToCommand(client, "%t", "deny_unknown");
							return Plugin_Handled;
						}
						continue;
					}
				}
			}

			if((KvGetNum(BossKV[config], "donator") && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
			   (KvGetNum(BossKV[config], "admin") && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
			   (Utils_BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true)))
			{
				if(KvGetNum(BossKV[config], "hidden"))
				{
					FReplyToCommand(client, "%t", "deny_unknown");
					return Plugin_Handled;
				}
				else
				{
					FReplyToCommand(client, "%t", "deny_donator");
					return Plugin_Handled;
				}
			}
			else if(KvGetNum(BossKV[config], "owner") && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true))
			{
				if(KvGetNum(BossKV[config], "hidden", 1))
				{
					FReplyToCommand(client, "%t", "deny_unknown");
					return Plugin_Handled;
				}
				else
				{
					FReplyToCommand(client, "%t", "deny_donator");
					return Plugin_Handled;
				}
			}
			else if(KvGetNum(BossKV[config], "hidden") &&
			      !(KvGetNum(BossKV[config], "donator") ||
			        KvGetNum(BossKV[config], "theme") ||
				KvGetNum(BossKV[config], "admin") ||
				KvGetNum(BossKV[config], "owner")))
			{
				FReplyToCommand(client, "%t", "deny_unknown");
				return Plugin_Handled;
			}

			if(MapBlocked[config])
			{
				if(!cvarShowBossBlocked.BoolValue)
				{
					FReplyToCommand(client, "%t", "deny_unknown");
				}
				else 
				{
					FReplyToCommand(client, "%t", "deny_map");
				}
				return Plugin_Handled;
			}

			if(KvGetNum(BossKV[config], "nofirst") && (RoundCount<arenaRounds || (RoundCount==arenaRounds && Utils_CheckRoundState()!=1)))
			{
				FReplyToCommand(client, "%t", "deny_nofirst");
				return Plugin_Handled;
			}

			KvGetString(BossKV[config], "companion", companionName, sizeof(companionName));
			if(companionName[0] && !DuoMin)
			{
				FReplyToCommand(client, "%t", "deny_duo_short");
				return Plugin_Handled;
			}

			if(companionName[0] && cvarDuoBoss.BoolValue && view_as<int>(ToggleDuo[client])>1)
			{
				FReplyToCommand(client, "%t", "deny_duo_off");
				return Plugin_Handled;
			}

			if(AreClientCookiesCached(client) && cvarKeepBoss.IntValue<0)
			{
				static char cookie1[64], cookie2[64];
				KvGetString(BossKV[config], "name", cookie1, sizeof(cookie1));
				GetClientCookie(client, LastPlayedCookie, cookie2, sizeof(cookie2));
				if(StrEqual(cookie1, cookie2, false))
				{
					FReplyToCommand(client, "%t", "deny_recent");
					return Plugin_Handled;
				}
			}
			strcopy(xIncoming[client], sizeof(xIncoming[]), boss);
			CanBossVs[client] = KvGetNum(BossKV[config], "noversus");
			CanBossTeam[client] = KvGetNum(BossKV[config], "bossteam");
			IgnoreValid[client] = false;
			DataBase_SaveKeepBossCookie(client);
			FReplyToCommand(client, "%t", "to0_boss_selected", bossName);
			return Plugin_Handled;
		}
	}

	char boss[64];
	static char bossName[64];
	Menu menu = new Menu(Command_SetMyBossH);
	SetGlobalTransTarget(client);
	if(ToggleBoss[client] == Setting_On)
	{
		for(int config; config<=Specials; config++)
		{
			if(config == Specials)
			{
				FormatEx(boss, sizeof(boss), "%t", "to0_random");
				break;
			}

			KvRewind(BossKV[config]);
			if(KvGetNum(BossKV[config], "blocked"))
				continue;

			KvGetString(BossKV[config], "name", bossName, sizeof(bossName));
			if(StrEqual(bossName, xIncoming[client], false))
			{
				if(IgnoreValid[client] || Utils_CheckValidBoss(client, xIncoming[client], !DuoMin))
					Utils_GetBossSpecial(config, boss, sizeof(boss), client);

				break;
			}
		}
	}

	if(Enabled2 && HasCharSets && CurrentCharSet<MAXCHARSETS)
	{
		if(kvDiffMods!=null && !cvarDifficulty.BoolValue && CheckCommandAccess(client, "ff2_difficulty", 0, true))
		{
			menu.SetTitle("%t%t", "ff2_boss_selection_pack", CharSetString[CurrentCharSet], boss, "ff2_boss_selection_diff", dIncoming[client][0] ? dIncoming[client] : "-");
		}
		else
		{
			menu.SetTitle("%t", "ff2_boss_selection_pack", CharSetString[CurrentCharSet], boss);
		}
	}
	else
	{
		if(kvDiffMods!=null && !cvarDifficulty.BoolValue && CheckCommandAccess(client, "ff2_difficulty", 0, true))
		{
			menu.SetTitle("%t%t", "ff2_boss_selection", boss, "ff2_boss_selection_diff", dIncoming[client][0] ? dIncoming[client] : "-");
		}
		else
		{
			menu.SetTitle("%t", "ff2_boss_selection", boss);
		}
	}

	FormatEx(boss, sizeof(boss), "%t", "to0_random");
	if(!Enabled2)
	{
		menu.AddItem(boss, boss, ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem(boss, boss);
	}

	if(cvarToggleBoss.BoolValue)
	{
		if(view_as<int>(ToggleBoss[client]) < 2)
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_disablepts");
		}
		else
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_enablepts");
		}
		menu.AddItem(boss, boss);
	}

	if(cvarDuoBoss.BoolValue)
	{
		if(view_as<int>(ToggleDuo[client]) < 2)
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_disableduo");
		}
		else
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_enableduo");
		}
		menu.AddItem(boss, boss);
	}

	if(kvDiffMods!=null && CheckCommandAccess(client, "ff2_difficulty", 0, true))
	{
		if(cvarDifficulty.BoolValue)
		{
			if(view_as<int>(ToggleDiff[client]) < 2)
			{
				FormatEx(boss, sizeof(boss), "%t", "to0_disablediff");
			}
			else
			{
				FormatEx(boss, sizeof(boss), "%t", "to0_enablediff");
			}
		}
		else
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_difficulty");
		}
		menu.AddItem(boss, boss);
	}

	if(cvarSkipBoss.BoolValue)
	{
		FormatEx(boss, sizeof(boss), "%t", "to0_resetpts");
		if(QueuePoints[client]<10 || !Enabled2)
		{
			menu.AddItem(boss, boss, ITEMDRAW_DISABLED);
		}
		else
		{
			menu.AddItem(boss, boss);
		}
	}

	if(HasCharSets)
	{
		FormatEx(boss, sizeof(boss), "%t", "to0_viewall");
		menu.AddItem(boss, boss);
	}

	if(!Enabled2)
	{
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}

	static char companionName[64];
	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		if(KvGetNum(BossKV[config], "blocked"))
			continue;

		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		Utils_GetBossSpecial(config, bossName, sizeof(bossName), client);
		KvGetString(BossKV[config], "companion", companionName, sizeof(companionName));
		if((KvGetNum(BossKV[config], "donator") && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
		   (KvGetNum(BossKV[config], "admin") && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
		   (Utils_BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true)))
		{
			if(!KvGetNum(BossKV[config], "hidden"))
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(BossKV[config], "owner") && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true))
		{
			if(!KvGetNum(BossKV[config], "hidden", 1))
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(BossKV[config], "hidden") &&
		      !(KvGetNum(BossKV[config], "donator") ||
		        KvGetNum(BossKV[config], "theme") ||
			KvGetNum(BossKV[config], "admin") ||
			KvGetNum(BossKV[config], "owner")))
		{
			// Don't show
		}
		else if(MapBlocked[config])
		{
			if(cvarShowBossBlocked.BoolValue)
			{
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
			}
		}
		else if(KvGetNum(BossKV[config], "nofirst") && (RoundCount<arenaRounds || (RoundCount==arenaRounds && Utils_CheckRoundState()!=1)))
		{
			menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(companionName[0] && ((cvarDuoBoss.BoolValue && view_as<int>(ToggleDuo[client])>1) || !DuoMin))
		{
			menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else
		{
			if(AreClientCookiesCached(client) && cvarKeepBoss.IntValue<0 && !CheckCommandAccess(client, "ff2_replay_bosses", ADMFLAG_CHEATS, true))
			{
				GetClientCookie(client, LastPlayedCookie, companionName, sizeof(companionName));
				if(StrEqual(boss, companionName, false))
				{
					menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
					continue;
				}
			}
			menu.AddItem(boss, bossName);
		}
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

// Command hooks
public Action OnCallForMedic(int client, const char[] command, int args)
{
	if(!IsPlayerAlive(client) || Utils_CheckRoundState()!=1 || !Utils_IsBoss(client) || args!=2)
		return Plugin_Continue;

	int boss = Utils_GetBossIndex(client);
	if(boss==-1 || !Boss[boss] || !IsValidEntity(Boss[boss]) || BossRageDamage[0]>99998 || rageMode[client]==2)
		return Plugin_Continue;

	static char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
		return Plugin_Continue;

	if(RoundFloat(BossCharge[boss][0]) >= rageMin[client])
	{
		ActivateAbilitySlot(boss, 0);

		static float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

		static char sound[PLATFORM_MAX_PATH];
		if(RandomSound("sound_ability_serverwide", sound, sizeof(sound), boss))
			EmitSoundToAllExcept(sound);

		if(RandomSoundAbility("sound_ability", sound, sizeof(sound), boss))
		{
			FF2flags[Boss[boss]] |= FF2FLAG_TALKING;
			EmitSoundToAllExcept(sound);

			for(int target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && target!=Boss[boss] && ToggleVoice[target])
				{
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
				}
			}
			FF2flags[Boss[boss]] &= ~FF2FLAG_TALKING;
		}
		emitRageSound[boss]=true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action OnSuicide(int client, const char[] command, int args)
{
	bool canBossSuicide = cvarBossSuicide.BoolValue;
	if(Utils_IsBoss(client) && (!canBossSuicide || !Utils_CheckRoundState()) && Utils_CheckRoundState()!=2)
	{
		FPrintToChat(client, "%t", canBossSuicide ? "Boss Suicide Pre-round" : "Boss Suicide Denied");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action OnJoinTeam(int client, const char[] command, int args)
{
	// Only block the commands when FF2 is actively running
	if(!Enabled || RoundCount<arenaRounds || Utils_CheckRoundState()==-1)
		return Plugin_Continue;

	int boss = Utils_GetBossIndex(client);
	// autoteam doesn't come with arguments
	if(StrEqual(command, "autoteam", false))
	{
		if(Enabled3)
			return IsPlayerAlive(client) ? Plugin_Handled : Plugin_Continue;

		int team = view_as<int>(TFTeam_Unassigned);
		int oldTeam = GetClientTeam(client);
		if(Utils_IsBoss(client) && !BossSwitched[boss])
		{
			team = BossTeam;
		}
		else
		{
			team = OtherTeam;
		}

		if(team != oldTeam)
			ChangeClientTeam(client, team);

		return Plugin_Handled;
	}

	if(!args || (Enabled3 && !Utils_IsBoss(client)))
		return Plugin_Continue;

	int team = view_as<int>(TFTeam_Unassigned);
	int oldTeam = GetClientTeam(client);
	static char teamString[10];
	GetCmdArg(1, teamString, sizeof(teamString));

	if(StrEqual(teamString, "red", false))
	{
		team = view_as<int>(TFTeam_Red);
	}
	else if(StrEqual(teamString, "blue", false))
	{
		team = view_as<int>(TFTeam_Blue);
	}
	else if(StrEqual(teamString, "auto", false))
	{
		team = OtherTeam;
	}
	else if(StrEqual(teamString, "spectate", false) && !Utils_IsBoss(client) && GetConVarBool(FindConVar("mp_allowspectators")))
	{
		team = view_as<int>(TFTeam_Spectator);
	}

	if(team==BossTeam && (!Utils_IsBoss(client) || BossSwitched[boss]))
	{
		team = OtherTeam;
	}
	else if(team==OtherTeam && (Utils_IsBoss(client) && !BossSwitched[boss]))
	{
		team = BossTeam;
	}

	if(team>view_as<int>(TFTeam_Unassigned) && team!=oldTeam)
		ChangeClientTeam(client, team);

	if(Utils_CheckRoundState()!=1 && !Utils_IsBoss(client) || !IsPlayerAlive(client))  //No point in showing the VGUI if they can't change teams
	{
		switch(team)
		{
			case view_as<int>(TFTeam_Red):
				ShowVGUIPanel(client, "class_red");

			case view_as<int>(TFTeam_Blue):
				ShowVGUIPanel(client, "class_blue");
		}
	}
	return Plugin_Handled;
}

Action OnChangeClass(int client, const char[] command, int args)
{
	if(!Utils_IsBoss(client) || !IsPlayerAlive(client))
		return Plugin_Continue;

	//Don't allow the boss to switch classes but instead set their *desired* class (for the next round)
	static char class[16];
	GetCmdArg(1, class, sizeof(class));
	if(TF2_GetClass(class) != TFClass_Unknown)  //Ignore cases where the client chooses an invalid class through the console
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TF2_GetClass(class));

	return Plugin_Handled;
}
