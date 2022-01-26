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

		Utils_GetBossSpecial(FF2BossInfo[0].Incoming, boss, sizeof(boss), client);

		Menu menu = new Menu(Command_SetNextBossH);
		menu.SetTitle("Override Next Boss\n  Current Selection: %s", boss);

		strcopy(boss, sizeof(boss), "No Override");
		menu.AddItem(boss, boss);

		for(int config; config<FF2CharSetInfo.SizeOfSpecials; config++)
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

	for(int config; config<FF2CharSetInfo.SizeOfSpecials; config++)
	{
		Utils_GetBossSpecial(config, boss, sizeof(boss), client);
		if(StrContains(boss, name, false) != -1)
		{
			FF2BossInfo[0].Incoming = config;
			FReplyToCommand(client, "Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvRewind(FF2CharSetInfo.BossKV[config]);
		KvGetString(FF2CharSetInfo.BossKV[config], "name", boss, sizeof(boss));
		if(StrContains(boss, name, false) != -1)
		{
			FF2BossInfo[0].Incoming = config;
			Utils_GetBossSpecial(config, boss, sizeof(boss), client);
			FReplyToCommand(client, "Set the next boss to %s", boss);
			return Plugin_Handled;
		}

		KvGetString(FF2CharSetInfo.BossKV[config], "filename", boss, sizeof(boss));
		if(StrContains(boss, name, false) != -1)
		{
			FF2BossInfo[0].Incoming = config;
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
					FF2BossInfo[0].Incoming = 0;
					FReplyToCommand(client, "No override to the next boss");
				}
				default:
				{
					int choice2 = choice-1;
					FF2BossInfo[0].Incoming = choice2;
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

			FF2PlayerCookie[targets[target]].QueuePoints += points;
			LogAction(client, targets[target], "\"%L\" added %d queue points to \"%L\"", client, points, targets[target]);
		}
	}
	else
	{
		FF2PlayerCookie[targets[0]].QueuePoints += points;
		LogAction(client, targets[0], "\"%L\" added %d queue points to \"%L\"", client, points, targets[0]);
	}
	FReplyToCommand(client, "Added %d queue points to %s", points, targetName);
	return Plugin_Handled;
}

Action Command_StartMusic(int client, int args)
{
	if(FF2Globals.Enabled2)
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
	if(!FF2Globals.Enabled2)
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
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2CharSetInfo.UseOldCharSetPath ? ConfigPath : DataPath, CharsetCFG);

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
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2CharSetInfo.UseOldCharSetPath ? ConfigPath : DataPath, CharsetCFG);

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(int i; ; i++)
	{
		KvGetSectionName(Kv, config, sizeof(config));
		if(StrContains(config, charset, false) >= 0)
		{
			FReplyToCommand(client, "Charset for nextmap is %s", config);
			FF2CharSetInfo.IsCharSetSelected = true;
			ConVars.Charset.IntValue = i;
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
			ConVars.Charset.IntValue = choice;

			static char nextmap[32];
			ConVars.Nextmap.GetString(nextmap, sizeof(nextmap));
			menu.GetItem(choice, FF2CharSetInfo.CurrentCharSet, sizeof(FF2CharSetInfo.CurrentCharSet));
			FPrintToChat(client, "%t", "nextmap_charset", nextmap, FF2CharSetInfo.CurrentCharSet);
			FF2CharSetInfo.IsCharSetSelected = true;
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
		BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2CharSetInfo.UseOldCharSetPath ? ConfigPath : DataPath, CharsetCFG);

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
	BuildPath(Path_SM, config, sizeof(config), "%s/%s", FF2CharSetInfo.UseOldCharSetPath ? ConfigPath : DataPath, CharsetCFG);

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	for(int i; ; i++)
	{
		KvGetSectionName(Kv, config, sizeof(config));
		if(StrContains(config, charset, false) >= 0)
		{
			ConVars.Charset.IntValue = i;
			FF2Globals.LoadCharset = true;
			if(!Utils_CheckRoundState() || Utils_CheckRoundState()==1)
			{
				FReplyToCommand(client, "The current character set is set to be switched to %s!", config);
				return Plugin_Handled;
			}

			FReplyToCommand(client, "Character set has been switched to %s", config);
			FindCharacters();
			FF2CharSetInfo.CurrentCharSet[0] = 0;
			FF2Globals.LoadCharset = false;
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
	if(FF2Globals.ReloadFF2)
	{
		FReplyToCommand(client, "The plugin is no longer set to reload.");
		FF2Globals.ReloadFF2 = false;
		return Plugin_Handled;
	}
	FF2Globals.ReloadFF2 = true;
	if(!Utils_CheckRoundState() || Utils_CheckRoundState()==1)
	{
		FReplyToCommand(client, "The plugin is set to reload.");
		return Plugin_Handled;
	}
	FReplyToCommand(client, "The plugin has been reloaded.");
	FF2Globals.ReloadFF2 = false;
	ServerCommand("sm plugins reload freak_fortress_2");
	return Plugin_Handled;
}

Action Command_ReloadCharset(int client, int args)
{
	if(FF2Globals.LoadCharset)
	{
		FReplyToCommand(client, "Current character set no longer set to reload!");
		FF2Globals.LoadCharset = false;
		return Plugin_Handled;
	}
	FF2Globals.LoadCharset = true;
	if(!Utils_CheckRoundState() || Utils_CheckRoundState()==1)
	{
		FReplyToCommand(client, "Current character set is set to reload!");
		return Plugin_Handled;
	}
	FReplyToCommand(client, "Current character set has been reloaded!");
	FindCharacters();
	FF2CharSetInfo.CurrentCharSet[0] = 0;
	FF2Globals.LoadCharset = false;
	return Plugin_Handled;
}

Action Command_ReloadFF2Weapons(int client, int args)
{
	if(FF2Globals.ReloadWeapons)
	{
		FReplyToCommand(client, "%s is no longer set to reload!", WeaponCFG);
		FF2Globals.ReloadWeapons = false;
		return Plugin_Handled;
	}
	FF2Globals.ReloadWeapons = true;
	if(!Utils_CheckRoundState() || Utils_CheckRoundState()==1)
	{
		FReplyToCommand(client, "%s is set to reload!", WeaponCFG);
		return Plugin_Handled;
	}
	FReplyToCommand(client, "%s has been reloaded!", WeaponCFG);
	CacheWeapons();
	FF2Globals.ReloadWeapons = false;
	return Plugin_Handled;
}

Action Command_ReloadFF2Configs(int client, int args)
{
	if(FF2Globals.ReloadConfigs)
	{
		FReplyToCommand(client, "All configs are no longer set to be reloaded!");
		FF2Globals.ReloadConfigs = false;
		return Plugin_Handled;
	}
	FF2Globals.ReloadConfigs = true;
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
	FF2CharSetInfo.CurrentCharSet[0] = 0;
	FF2Globals.ReloadConfigs = false;
	return Plugin_Handled;
}

Action Command_ReloadSubPlugins(int client, int args)
{
	if(!FF2Globals.Enabled)
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
	if(FF2Globals.Enabled)
	{
		Utils_SetControlPoint(false);
		return Plugin_Handled;
	}
	FReplyToCommand(client, "%t", "FF2 Disabled");
	return Plugin_Handled;
}

Action Command_Point_Enable(int client, int args)
{
	if(FF2Globals.Enabled)
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

	if(!FF2Globals.Enabled2)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(Utils_CheckRoundState()!=1 || ConVars.HealthHud.IntValue>1)
		return Plugin_Handled;

	Command_GetHP(client);
	return Plugin_Handled;
}

Action Command_GetHP(int client)  //TODO: This can rarely show a very large negative number if you time it right
{
	if(Utils_IsBoss(client) || GetGameTime()>=FF2Globals.HPTime)
	{
		char[][] text = new char[MaxClients+1][512];
		static char name[64];
		bool multi;
		for(int boss; boss<=MaxClients; boss++)
		{
			if(Utils_IsValidClient(FF2BossInfo[boss].Boss))
			{
				char lives[8];
				if(FF2BossInfo[boss].Lives > 1)
					FormatEx(lives, sizeof(lives), "x%i", FF2BossInfo[boss].Lives);

				for(int target; target<=MaxClients; target++)
				{
					if(Utils_IsValidClient(target))
					{
						Utils_GetBossSpecial(FF2BossInfo[boss].Special, name, sizeof(name), target);
						Format(text[target], 512, "%s\n%t", multi ? text[target] : "", "ff2_hp", name, FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1), FF2BossInfo[boss].HealthMax, lives);
						FPrintToChat(target, "%t", "ff2_hp", name, FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1), FF2BossInfo[boss].HealthMax, lives);
					}
				}
				multi = true;
				FF2BossInfo[boss].HealthLast = FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1);
			}
		}

		if((IsPlayerAlive(client) || IsClientObserver(client)) && !FF2PlayerCookie[client].HudSettings[4] && !(FF2PlayerInfo[client].FF2Flags & FF2FLAG_HUDDISABLED))
		{
			for(int target; target<=MaxClients; target++)
			{
				if(Utils_IsValidClient(target))
				{
					if(FF2Globals.Bosses<2 && ConVars.GameText.IntValue>0)
					{
						if(FF2Globals.BossIcon[0])
						{
							Utils_ShowGameText(target, FF2Globals.BossIcon, _, text[client]);
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

		if(GetGameTime() >= FF2Globals.HPTime)
		{
			FF2Globals.HealthCheckCounter++;
			FF2Globals.HPTime = GetGameTime()+(FF2Globals.HealthCheckCounter<3 ? 20.0 : 80.0);
		}
		return Plugin_Continue;
	}

	static char waitTime[128];
	for(int target; target<=MaxClients; target++)
	{
		if(Utils_IsBoss(target))
			Format(waitTime, sizeof(waitTime), "%s %i,", waitTime, FF2BossInfo[FF2BossInfo[target].Boss].HealthLast);
	}
	FPrintToChat(client, "%t", "wait_hp", RoundFloat(FF2Globals.HPTime-GetGameTime()), waitTime);
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

		FormatEx(text, sizeof(text), "%N-%i", target, FF2PlayerCookie[target].QueuePoints);
		menu.AddItem(text, text, client==target ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		added[target] = true;
	}

	FormatEx(text, sizeof(text), "%T (%T)", "your_points", client, FF2PlayerCookie[client].QueuePoints, "to0", client);  //"Your queue point(s) is {1} (set to 0)"
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
	ConVars.Changelog.GetString(url, sizeof(url));
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

	if(!ConVars.AdvancedMusic.BoolValue)
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

	if(!FF2Globals.Enabled2)
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
			if(FF2PlayerCookie[client].MusicOn)
			{
				FReplyToCommand(client, "You already have boss themes enabled...");
				return Plugin_Handled;
			}
			ToggleBGM(client, true);
		}
		FPrintToChat(client, "%t", "ff2_music", FF2PlayerCookie[client].MusicOn ? "on" : "off");	// TODO: Make this more multi-language friendly
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

	if(!ConVars.AdvancedMusic.BoolValue)
		return Plugin_Continue;

	if(!FF2Globals.Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(StrEqual(FF2PlayerInfo[client].CurrentBGM, "ff2_stop_music", true) || !FF2PlayerCookie[client].MusicOn)
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

	KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special]);
	if(KvJumpToKey(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH], id3[6][256];
		int index;
		do
		{
			index++;
			FormatEx(music, 10, "time%i", index);
		}
		while(KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], music) > 1);

		if(!index)
		{
			FReplyToCommand(client, "%t", "ff2_no_music");
			return Plugin_Handled;
		}

		FF2PlayerInfo[client].SongIdx++;
		if(FF2PlayerInfo[client].SongIdx >= index)
			FF2PlayerInfo[client].SongIdx = 1;

		char lives[256];
		FormatEx(lives, sizeof(lives), "life%i", FF2PlayerInfo[client].SongIdx);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], lives, lives, sizeof(lives));
		if(lives[0])
		{
			if(StringToInt(lives) != FF2BossInfo[0].Lives)
			{
				for(int i; i<index-1; i++)
				{
					if(StringToInt(lives) != FF2BossInfo[0].Lives)
					{
						FF2PlayerInfo[client].SongIdx = i;
						continue;
					}
					break;
				}
			}
		}

		FormatEx(music, 10, "time%i", FF2PlayerInfo[client].SongIdx);
		float time = KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], music);
		FormatEx(music, 10, "path%i", FF2PlayerInfo[client].SongIdx);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], music, music, sizeof(music));

		FormatEx(id3[0], sizeof(id3[]), "name%i", FF2PlayerInfo[client].SongIdx);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], id3[0], id3[2], sizeof(id3[]));
		FormatEx(id3[1], sizeof(id3[]), "artist%i", FF2PlayerInfo[client].SongIdx);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], id3[1], id3[3], sizeof(id3[]));

		char temp[PLATFORM_MAX_PATH];
		FormatEx(temp, sizeof(temp), "sound/%s", music);
		if(FileExists(temp, true))
		{
			PlayBGM(client, music, time, id3[2], id3[3]);
		}
		else
		{
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], "filename", lives, sizeof(lives));
			LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is missing BGM file '%s'!", lives, temp);
			if(FF2PlayerInfo[client].MusicTimer != null) {
				delete FF2PlayerInfo[client].MusicTimer;
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

	if(!ConVars.AdvancedMusic.BoolValue)
		return Plugin_Continue;

	if(!FF2Globals.Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(StrEqual(FF2PlayerInfo[client].CurrentBGM, "ff2_stop_music", true) || !FF2PlayerCookie[client].MusicOn)
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

	if(!ConVars.AdvancedMusic.BoolValue || ConVars.SongInfo.IntValue<0)
		return Plugin_Continue;

	if(!FF2Globals.Enabled)
	{
		FReplyToCommand(client, "%t", "FF2 Disabled");
		return Plugin_Handled;
	}

	if(StrEqual(FF2PlayerInfo[client].CurrentBGM, "ff2_stop_music", true) || !FF2PlayerCookie[client].MusicOn)
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
	KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special]);
	if(KvJumpToKey(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH], id3[6][256];
		int index;
		do
		{
			index++;
			FormatEx(music, 10, "time%i", index);
		}
		while(KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], music) > 1);

		if(!index)
		{
			FReplyToCommand(client, "%t", "ff2_no_music");
			return Plugin_Handled;
		}

		char lives[256];
		for(int trackIdx=1; trackIdx<=index-1; trackIdx++)
		{
			FormatEx(lives, sizeof(lives), "life%i", trackIdx);
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], lives, lives, sizeof(lives));
			if(lives[0])
			{
				if(StringToInt(lives) != FF2BossInfo[0].Lives)
					continue;
			}
			FormatEx(id3[0], sizeof(id3[]), "name%i", trackIdx);
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], id3[0], id3[2], sizeof(id3[]));
			FormatEx(id3[1], sizeof(id3[]), "artist%i", trackIdx);
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], id3[1], id3[3], sizeof(id3[]));
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

	if(!ConVars.AdvancedMusic.BoolValue)
	{
		VoiceTogglePanel(client);
	}
	else
	{
		if(FF2PlayerCookie[client].VoiceOn)
		{
			FF2PlayerCookie[client].VoiceOn = false;
			FPrintToChat(client, "%t", "ff2_voice", "off");	// TODO: Make this more multi-language friendly
		}
		else
		{
			FF2PlayerCookie[client].VoiceOn = true;
			FPrintToChat(client, "%t", "ff2_voice", "on");	// TODO: Make this more multi-language friendly
		}
	}
	return Plugin_Handled;
}

Action Command_Nextmap(int client, int args)
{
	if(FF2CharSetInfo.CurrentCharSet[0])
	{
		static char nextmap[42];
		ConVars.Nextmap.GetString(nextmap, sizeof(nextmap));
		FReplyToCommand(client, "%t", "nextmap_charset", nextmap, FF2CharSetInfo.CurrentCharSet);
	}
	return Plugin_Handled;
}

public Action Command_Say(int client, int args)
{
	static char chat[32];
	if(GetCmdArgString(chat, sizeof(chat))<1 || !client)
		return Plugin_Continue;

	if(FF2CharSetInfo.CurrentCharSet[0] && StrEqual(chat, "\"nextmap\""))
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

			FF2BossInfo[Utils_GetBossIndex(client)].Charge[0] = rageMeter;
			FReplyToCommand(client, "You now have %i percent RAGE", RoundFloat(FF2BossInfo[client].Charge[0]));
			LogAction(client, client, "\"%L\" gave themselves %i RAGE", client, RoundFloat(rageMeter));
			FF2Globals.CheatsUsed = true;
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

		FF2BossInfo[Utils_GetBossIndex(target_list[target])].Charge[0] = rageMeter;
		LogAction(client, target_list[target], "\"%L\" set %d RAGE to \"%L\"", client, RoundFloat(rageMeter), target_list[target]);
		FReplyToCommand(client, "Set %d rage to %s", RoundFloat(rageMeter), target_name);
		FF2Globals.CheatsUsed = true;
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

			FF2BossInfo[Utils_GetBossIndex(client)].Charge[0] += rageMeter;
			FReplyToCommand(client, "You now have %i percent RAGE (%i percent added)", RoundFloat(FF2BossInfo[client].Charge[0]), RoundFloat(rageMeter));
			LogAction(client, client, "\"%L\" gave themselves %i more RAGE", client, RoundFloat(rageMeter));
			FF2Globals.CheatsUsed = true;
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

		FF2BossInfo[Utils_GetBossIndex(target_list[target])].Charge[0] += rageMeter;
		LogAction(client, target_list[target], "\"%L\" added %d RAGE to \"%L\"", client, RoundFloat(rageMeter), target_list[target]);
		FReplyToCommand(client, "Added %d rage to %s", RoundFloat(rageMeter), target_name);
		FF2Globals.CheatsUsed = true;
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
				FF2BossInfo[Utils_GetBossIndex(client)].Charge[abilitySlot] += rageMeter;
				FReplyToCommand(client, "Slot %i's charge: %i percent (added %i percent)!", abilitySlot, RoundFloat(FF2BossInfo[Utils_GetBossIndex(client)].Charge[abilitySlot]), RoundFloat(rageMeter));
				LogAction(client, client, "\"%L\" gave themselves %i more charge to slot %i", client, RoundFloat(rageMeter), abilitySlot);
				FF2Globals.CheatsUsed = true;
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
			FF2BossInfo[Utils_GetBossIndex(target_list[target])].Charge[abilitySlot] += rageMeter;
			FReplyToCommand(client, "%s's ability slot %i's charge: %i percent (added %i percent)!", target_name, abilitySlot, RoundFloat(FF2BossInfo[Utils_GetBossIndex(target_list[target])].Charge[abilitySlot]), RoundFloat(rageMeter));
			LogAction(client, target_list[target], "\"%L\" gave \"%L\" %i more charge to slot %i", client, target_list[target], RoundFloat(rageMeter), abilitySlot);
			FF2Globals.CheatsUsed = true;
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
				FF2BossInfo[Utils_GetBossIndex(client)].Charge[abilitySlot] = rageMeter;
				FReplyToCommand(client, "Slot %i's charge: %i percent!", abilitySlot, RoundFloat(FF2BossInfo[Utils_GetBossIndex(client)].Charge[abilitySlot]));
				LogAction(client, client, "\"%L\" gave themselves %i charge to slot %i", client, RoundFloat(rageMeter), abilitySlot);
				FF2Globals.CheatsUsed = true;
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
			FF2BossInfo[Utils_GetBossIndex(target_list[target])].Charge[abilitySlot] = rageMeter;
			FReplyToCommand(client, "%s's ability slot %i's charge: %i percent!", target_name, abilitySlot, RoundFloat(FF2BossInfo[Utils_GetBossIndex(target_list[target])].Charge[abilitySlot]));
			LogAction(client, target_list[target], "\"%L\" gave \"%L\" %i charge to slot %i", client, target_list[target], RoundFloat(rageMeter), abilitySlot);
			FF2Globals.CheatsUsed = true;
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
				FF2BossInfo[boss].Boss = 0;
				boss = index;
				FF2BossInfo[boss].Boss = target_list[target];
			}
			else
			{
				boss = Utils_GetBossIndex(target_list[target]);
			}

			if(team > 1)
			{
				FF2BossInfo[boss].HasSwitched = team==FF2Globals.OtherTeam ? true : false;
			}
			else if(team > 0)
			{
				FF2BossInfo[boss].HasSwitched = GetRandomInt(0, 1) ? true : false;
			}

			if(special >= 0)
				FF2BossInfo[boss].Incoming = special;

			FF2BossInfo[boss].HasEquipped = false;
			PickCharacter(boss, boss);
			CreateTimer(0.3, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			if(index >= 0)
			{
				FF2BossInfo[index].Boss = target_list[target];
				if(team > 1)
				{
					FF2BossInfo[index].HasSwitched = team==FF2Globals.OtherTeam ? true : false;
				}
				else if(team > 0)
				{
					FF2BossInfo[index].HasSwitched = GetRandomInt(0, 1) ? true : false;
				}

				if(special >= 0)
					FF2BossInfo[index].Incoming = special;

				FF2BossInfo[boss].HasEquipped = false;
				PickCharacter(index, index);
				CreateTimer(0.3, Timer_MakeBoss, index, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				while(boss2 <= MaxClients)
				{
					if(!Utils_IsValidClient(FF2BossInfo[boss2].Boss))
					{
						FF2BossInfo[boss2].Boss = target_list[target];
						if(team > 1)
						{
							FF2BossInfo[boss].HasSwitched = team==FF2Globals.OtherTeam;
						}
						else if(team > 0)
						{
							FF2BossInfo[boss].HasSwitched = GetRandomInt(0, 1)==1;
						}

						if(special >= 0)
							FF2BossInfo[boss].Incoming = special;

						FF2BossInfo[boss].HasEquipped = false;
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
				FF2BossInfo[Utils_GetBossIndex(client)].Charge[0] = FF2BossVar[client].RageMax;
				FReplyToCommand(client, "Infinite RAGE activated");
				LogAction(client, client, "\"%L\" activated infinite RAGE on themselves", client);
				CreateTimer(0.2, Timer_InfiniteRage, GetClientUserId(client), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				FF2Globals.CheatsUsed = true;
			}
			else
			{
				InfiniteRageActive[client] = false;
				FReplyToCommand(client, "Infinite RAGE deactivated");
				LogAction(client, client, "\"%L\" deactivated infinite RAGE on themselves", client);
				FF2Globals.CheatsUsed = true;
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
			FF2BossInfo[Utils_GetBossIndex(target_list[target])].Charge[0] = FF2BossVar[target_list[target]].RageMax;
			FReplyToCommand(client, "Infinite RAGE activated for %s", target_name);
			LogAction(client, target_list[target], "\"%L\" activated infinite RAGE on \"%L\"", client, target_list[target]);
			CreateTimer(0.2, Timer_InfiniteRage, GetClientUserId(target_list[target]), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			FF2Globals.CheatsUsed = true;
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
	if(Utils_IsValidClient(client) && ConVars.ToggleBoss.BoolValue)
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
		if(FF2Globals.Enabled2)
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
		FormatEx(menuOption, sizeof(menuOption), "%t [%t]", HudTypes[i], FF2PlayerCookie[client].HudSettings[i] ? "Off" : "On");
		menu.AddItem(menuOption, menuOption);
	}

	int value = FF2PlayerCookie[client].HudSettings[HUDTYPES-1] ? FF2PlayerCookie[client].HudSettings[HUDTYPES-1] : ConVars.DamageHud.IntValue;
	FormatEx(menuOption, sizeof(menuOption), "%t [%i]", HudTypes[HUDTYPES-1], value<3 ? 0 : value);
	menu.AddItem(menuOption, menuOption);

	menu.ExitButton = true;
	menu.Display(client, 20);
	return Plugin_Handled;
}

public Action BossMenu(int client, int args)
{
	if(Utils_IsValidClient(client) && ConVars.ToggleBoss.BoolValue)
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
		if(FF2Globals.Enabled2)
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

	if(ConVars.Difficulty.BoolValue)
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
		if(FF2Globals.Enabled2 && FF2ModsInfo.DiffCfg!=null)
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

	if(FF2ModsInfo.DiffCfg == null)
		return Plugin_Handled;

	if(!CheckCommandAccess(client, "ff2_difficulty", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}

	bool denyAll = (!ConVars.BossDesc.BoolValue || !FF2PlayerCookie[client].InfoOn) && (Utils_IsBoss(client) && Utils_CheckRoundState()!=2);

	char name[64];
	Menu menu = new Menu(DiffMenuH);
	SetGlobalTransTarget(client);

	menu.SetTitle("%t\n %t", "FF2 Difficulty Settings Menu Title", "ff2_boss_selection_diff", dIncoming[client][0] ? dIncoming[client] : "-");

	FormatEx(name, sizeof(name), "%t", "Off");
	menu.AddItem("", name, (!dIncoming[client][0] || denyAll || (Utils_IsBoss(client) && Utils_CheckRoundState()!=2)) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	KvRewind(FF2ModsInfo.DiffCfg);
	KvGotoFirstSubKey(FF2ModsInfo.DiffCfg);
	do
	{
		KvGetSectionName(FF2ModsInfo.DiffCfg, name, sizeof(name));
		menu.AddItem(name, name, denyAll ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	} while(KvGotoNextKey(FF2ModsInfo.DiffCfg));

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

	if(!ConVars.SelectBoss.BoolValue)
		return Plugin_Handled;

	if(!CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Handled;
	}

	if(args)
	{
		if(!FF2Globals.Enabled2)
		{
			FReplyToCommand(client, "%t", "FF2 Disabled");
			return Plugin_Handled;
		}

		static char name[64], boss[64], bossName[64], fileName[64], companionName[64];
		GetCmdArgString(name, sizeof(name));

		for(int config; config<FF2CharSetInfo.SizeOfSpecials; config++)
		{
			KvRewind(FF2CharSetInfo.BossKV[config]);
			if(KvGetNum(FF2CharSetInfo.BossKV[config], "blocked"))
			{
				if(config == FF2CharSetInfo.SizeOfSpecials-1)
				{
					FReplyToCommand(client, "%t", "deny_unknown");
					return Plugin_Handled;
				}
				continue;
			}

			Utils_GetBossSpecial(config, bossName, sizeof(bossName), client);
			KvGetString(FF2CharSetInfo.BossKV[config], "name", boss, sizeof(boss));
			if(StrContains(bossName, name, false))
			{
				if(StrContains(boss, name, false))
				{
					KvGetString(FF2CharSetInfo.BossKV[config], "filename", fileName, sizeof(fileName));
					if(StrContains(fileName, name, false))
					{
						if(config == FF2CharSetInfo.SizeOfSpecials-1)
						{
							FReplyToCommand(client, "%t", "deny_unknown");
							return Plugin_Handled;
						}
						continue;
					}
				}
			}

			if((KvGetNum(FF2CharSetInfo.BossKV[config], "donator") && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
			   (KvGetNum(FF2CharSetInfo.BossKV[config], "admin") && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
			   (Utils_BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true)))
			{
				if(KvGetNum(FF2CharSetInfo.BossKV[config], "hidden"))
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
			else if(KvGetNum(FF2CharSetInfo.BossKV[config], "owner") && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true))
			{
				if(KvGetNum(FF2CharSetInfo.BossKV[config], "hidden", 1))
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
			else if(KvGetNum(FF2CharSetInfo.BossKV[config], "hidden") &&
			      !(KvGetNum(FF2CharSetInfo.BossKV[config], "donator") ||
			        KvGetNum(FF2CharSetInfo.BossKV[config], "theme") ||
				KvGetNum(FF2CharSetInfo.BossKV[config], "admin") ||
				KvGetNum(FF2CharSetInfo.BossKV[config], "owner")))
			{
				FReplyToCommand(client, "%t", "deny_unknown");
				return Plugin_Handled;
			}

			if(FF2CharSetInfo.MapBlocked[config])
			{
				if(!ConVars.ShowBossBlocked.BoolValue)
				{
					FReplyToCommand(client, "%t", "deny_unknown");
				}
				else 
				{
					FReplyToCommand(client, "%t", "deny_map");
				}
				return Plugin_Handled;
			}

			if(KvGetNum(FF2CharSetInfo.BossKV[config], "nofirst") && (FF2Globals.RoundCount < FF2GlobalsCvars.ArenaRounds || (FF2Globals.RoundCount==FF2GlobalsCvars.ArenaRounds && Utils_CheckRoundState()!=1)))
			{
				FReplyToCommand(client, "%t", "deny_nofirst");
				return Plugin_Handled;
			}

			KvGetString(FF2CharSetInfo.BossKV[config], "companion", companionName, sizeof(companionName));
			if(companionName[0] && !FF2GlobalsCvars.DuoMin)
			{
				FReplyToCommand(client, "%t", "deny_duo_short");
				return Plugin_Handled;
			}

			if(companionName[0] && ConVars.ToggleBoss.BoolValue && view_as<int>(FF2PlayerCookie[client].Duo)>1)
			{
				FReplyToCommand(client, "%t", "deny_duo_off");
				return Plugin_Handled;
			}

			if(AreClientCookiesCached(client) && ConVars.KeepBoss.IntValue<0)
			{
				static char cookie1[64], cookie2[64];
				KvGetString(FF2CharSetInfo.BossKV[config], "name", cookie1, sizeof(cookie1));
				FF2DataBase.LastPlayer.Get(client, cookie2, sizeof(cookie2));
				if(StrEqual(cookie1, cookie2, false))
				{
					FReplyToCommand(client, "%t", "deny_recent");
					return Plugin_Handled;
				}
			}
			strcopy(xIncoming[client], sizeof(xIncoming[]), boss);
			CanBossVs[client] = KvGetNum(FF2CharSetInfo.BossKV[config], "noversus");
			CanBossTeam[client] = KvGetNum(FF2CharSetInfo.BossKV[config], "bossteam");
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
	if(FF2PlayerCookie[client].Boss == Setting_On)
	{
		for(int config; config<=FF2CharSetInfo.SizeOfSpecials; config++)
		{
			if(config == FF2CharSetInfo.SizeOfSpecials)
			{
				FormatEx(boss, sizeof(boss), "%t", "to0_random");
				break;
			}

			KvRewind(FF2CharSetInfo.BossKV[config]);
			if(KvGetNum(FF2CharSetInfo.BossKV[config], "blocked"))
				continue;

			KvGetString(FF2CharSetInfo.BossKV[config], "name", bossName, sizeof(bossName));
			if(StrEqual(bossName, xIncoming[client], false))
			{
				if(IgnoreValid[client] || Utils_CheckValidBoss(client, xIncoming[client], !FF2GlobalsCvars.DuoMin))
					Utils_GetBossSpecial(config, boss, sizeof(boss), client);

				break;
			}
		}
	}

	if(FF2Globals.Enabled2 && FF2CharSetInfo.HasMultiCharSets && FF2CharSetInfo.CurrentCharSetIdx<MAXCHARSETS)
	{
		if(FF2ModsInfo.DiffCfg!=null && !ConVars.Difficulty.BoolValue && CheckCommandAccess(client, "ff2_difficulty", 0, true))
		{
			menu.SetTitle("%t%t", "ff2_boss_selection_pack", FF2Packs_Names[FF2CharSetInfo.CurrentCharSetIdx], boss, "ff2_boss_selection_diff", dIncoming[client][0] ? dIncoming[client] : "-");
		}
		else
		{
			menu.SetTitle("%t", "ff2_boss_selection_pack", FF2Packs_Names[FF2CharSetInfo.CurrentCharSetIdx], boss);
		}
	}
	else
	{
		if(FF2ModsInfo.DiffCfg!=null && !ConVars.Difficulty.BoolValue && CheckCommandAccess(client, "ff2_difficulty", 0, true))
		{
			menu.SetTitle("%t%t", "ff2_boss_selection", boss, "ff2_boss_selection_diff", dIncoming[client][0] ? dIncoming[client] : "-");
		}
		else
		{
			menu.SetTitle("%t", "ff2_boss_selection", boss);
		}
	}

	FormatEx(boss, sizeof(boss), "%t", "to0_random");
	if(!FF2Globals.Enabled2)
	{
		menu.AddItem(boss, boss, ITEMDRAW_DISABLED);
	}
	else
	{
		menu.AddItem(boss, boss);
	}

	if(ConVars.ToggleBoss.BoolValue)
	{
		if(view_as<int>(FF2PlayerCookie[client].Boss) < 2)
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_disablepts");
		}
		else
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_enablepts");
		}
		menu.AddItem(boss, boss);
	}

	if(ConVars.ToggleBoss.BoolValue)
	{
		if(view_as<int>(FF2PlayerCookie[client].Duo) < 2)
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_disableduo");
		}
		else
		{
			FormatEx(boss, sizeof(boss), "%t", "to0_enableduo");
		}
		menu.AddItem(boss, boss);
	}

	if(FF2ModsInfo.DiffCfg!=null && CheckCommandAccess(client, "ff2_difficulty", 0, true))
	{
		if(ConVars.Difficulty.BoolValue)
		{
			if(view_as<int>(FF2PlayerCookie[client].Diff) < 2)
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

	if(ConVars.SkipBoss.BoolValue)
	{
		FormatEx(boss, sizeof(boss), "%t", "to0_resetpts");
		if(FF2PlayerCookie[client].QueuePoints<10 || !FF2Globals.Enabled2)
		{
			menu.AddItem(boss, boss, ITEMDRAW_DISABLED);
		}
		else
		{
			menu.AddItem(boss, boss);
		}
	}

	if(FF2CharSetInfo.HasMultiCharSets)
	{
		FormatEx(boss, sizeof(boss), "%t", "to0_viewall");
		menu.AddItem(boss, boss);
	}

	if(!FF2Globals.Enabled2)
	{
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}

	static char companionName[64];
	for(int config; config<FF2CharSetInfo.SizeOfSpecials; config++)
	{
		KvRewind(FF2CharSetInfo.BossKV[config]);
		if(KvGetNum(FF2CharSetInfo.BossKV[config], "blocked"))
			continue;

		KvGetString(FF2CharSetInfo.BossKV[config], "name", boss, sizeof(boss));
		Utils_GetBossSpecial(config, bossName, sizeof(bossName), client);
		KvGetString(FF2CharSetInfo.BossKV[config], "companion", companionName, sizeof(companionName));
		if((KvGetNum(FF2CharSetInfo.BossKV[config], "donator") && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
		   (KvGetNum(FF2CharSetInfo.BossKV[config], "admin") && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)) ||
		   (Utils_BossTheme(config) && !CheckCommandAccess(client, "ff2_theme_bosses", ADMFLAG_CONVARS, true)))
		{
			if(!KvGetNum(FF2CharSetInfo.BossKV[config], "hidden"))
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(FF2CharSetInfo.BossKV[config], "owner") && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true))
		{
			if(!KvGetNum(FF2CharSetInfo.BossKV[config], "hidden", 1))
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(FF2CharSetInfo.BossKV[config], "hidden") &&
		      !(KvGetNum(FF2CharSetInfo.BossKV[config], "donator") ||
		        KvGetNum(FF2CharSetInfo.BossKV[config], "theme") ||
			KvGetNum(FF2CharSetInfo.BossKV[config], "admin") ||
			KvGetNum(FF2CharSetInfo.BossKV[config], "owner")))
		{
			// Don't show
		}
		else if(FF2CharSetInfo.MapBlocked[config])
		{
			if(ConVars.ShowBossBlocked.BoolValue)
			{
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
			}
		}
		else if(KvGetNum(FF2CharSetInfo.BossKV[config], "nofirst") && (FF2Globals.RoundCount<FF2GlobalsCvars.ArenaRounds || (FF2Globals.RoundCount==FF2GlobalsCvars.ArenaRounds && Utils_CheckRoundState()!=1)))
		{
			menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(companionName[0] && ((ConVars.ToggleBoss.BoolValue && view_as<int>(FF2PlayerCookie[client].Duo)>1) || !FF2GlobalsCvars.DuoMin))
		{
			menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else
		{
			if(AreClientCookiesCached(client) && ConVars.KeepBoss.IntValue<0 && !CheckCommandAccess(client, "ff2_replay_bosses", ADMFLAG_CHEATS, true))
			{
				FF2DataBase.LastPlayer.Get(client, companionName, sizeof(companionName));
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
	if(boss==-1 || !FF2BossInfo[boss].Boss || !IsValidEntity(FF2BossInfo[boss].Boss) || FF2BossInfo[0].RageDamage>99998 || FF2BossVar[client].RageMode==2)
		return Plugin_Continue;

	static char arg1[4], arg2[4];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if(StringToInt(arg1) || StringToInt(arg2))  //We only want "voicemenu 0 0"-thanks friagram for pointing out edge cases
		return Plugin_Continue;

	if(RoundFloat(FF2BossInfo[boss].Charge[0]) >= FF2BossVar[client].RageMin)
	{
		ActivateAbilitySlot(boss, 0);

		static float position[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

		static char sound[PLATFORM_MAX_PATH];
		if(RandomSound("sound_ability_serverwide", sound, sizeof(sound), boss))
			EmitSoundToAllExcept(sound);

		if(RandomSoundAbility("sound_ability", sound, sizeof(sound), boss))
		{
			FF2PlayerInfo[FF2BossInfo[boss].Boss].FF2Flags |= FF2FLAG_TALKING;
			EmitSoundToAllExcept(sound);

			for(int target=1; target<=MaxClients; target++)
			{
				if(IsClientInGame(target) && target!=FF2BossInfo[boss].Boss && FF2PlayerCookie[target].VoiceOn)
				{
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
					EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
				}
			}
			FF2PlayerInfo[FF2BossInfo[boss].Boss].FF2Flags &= ~FF2FLAG_TALKING;
		}
		FF2BossInfo[boss].EmitRageSound=true;
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action OnSuicide(int client, const char[] command, int args)
{
	bool canBossSuicide = ConVars.BossSuicide.BoolValue;
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
	if(!FF2Globals.Enabled || FF2Globals.RoundCount<FF2GlobalsCvars.ArenaRounds || Utils_CheckRoundState()==-1)
		return Plugin_Continue;

	int boss = Utils_GetBossIndex(client);
	// autoteam doesn't come with arguments
	if(StrEqual(command, "autoteam", false))
	{
		if(FF2Globals.Enabled3)
			return IsPlayerAlive(client) ? Plugin_Handled : Plugin_Continue;

		int team = view_as<int>(TFTeam_Unassigned);
		int oldTeam = GetClientTeam(client);
		if(Utils_IsBoss(client) && !FF2BossInfo[boss].HasSwitched)
		{
			team = FF2Globals.BossTeam;
		}
		else
		{
			team = FF2Globals.OtherTeam;
		}

		if(team != oldTeam)
			ChangeClientTeam(client, team);

		return Plugin_Handled;
	}

	if(!args || (FF2Globals.Enabled3 && !Utils_IsBoss(client)))
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
		team = FF2Globals.OtherTeam;
	}
	else if(StrEqual(teamString, "spectate", false) && !Utils_IsBoss(client) && GetConVarBool(FindConVar("mp_allowspectators")))
	{
		team = view_as<int>(TFTeam_Spectator);
	}

	if(team==FF2Globals.BossTeam && (!Utils_IsBoss(client) || FF2BossInfo[boss].HasSwitched))
	{
		team = FF2Globals.OtherTeam;
	}
	else if(team==FF2Globals.OtherTeam && (Utils_IsBoss(client) && !FF2BossInfo[boss].HasSwitched))
	{
		team = FF2Globals.BossTeam;
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
