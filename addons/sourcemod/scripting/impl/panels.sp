int HintPanelH(Menu menu, MenuAction action, int client, int selection)
{
	if(action == MenuAction_End)
	{
		delete menu;
	}
	else if(action==MenuAction_Select || (action==MenuAction_Cancel && selection==MenuCancel_Exit))
	{
		FF2flags[client] |= FF2FLAG_CLASSHELPED;
	}
}

int QueuePanelH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(selection == 9)
				TurnToZeroPanel(client, client);
		}
	}
}

int TurnToZeroPanelH(Menu menu, MenuAction action, int client, int position)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{	
			if(!position)
			{
				if(shortname[client] == client)
				{
					FPrintToChat(client, "%t", "to0_done");  //Your queue points have been reset to {olive}0{default}
				}
				else
				{
					FPrintToChat(client, "%t", "to0_done_admin", shortname[client]);  //{olive}{1}{default}'s queue points have been reset to {olive}0{default}
					FPrintToChat(shortname[client], "%t", "to0_done_by_admin", client);  //{olive}{1}{default} reset your queue points to {olive}0{default}
					LogAction(client, shortname[client], "\"%L\" reset \"%L\"'s queue points to 0", client, shortname[client]);
				}
				QueuePoints[shortname[client]] = 0;
			}
		}
	}
}

Action TurnToZeroPanel(int client, int target)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	if(QueuePoints[client]<0 && client==target)
	{
		ReplyToCommand(client, "[SM] %t", "No Access");
		return Plugin_Continue;
	}

	Menu menu = new Menu(TurnToZeroPanelH);
	char text[128];
	if(client == target)
	{
		FormatEx(text, sizeof(text), "%T", "to0_title", client);  //Do you really want to set your queue points to 0?
	}
	else
	{
		FormatEx(text, sizeof(text), "%T", "to0_title_admin", client, target);  //Do you really want to set {1}'s queue points to 0?
	}

	PrintToChat(client, text);
	menu.SetTitle(text);
	FormatEx(text, sizeof(text), "%T", "Yes", client);
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%T", "No", client);
	menu.AddItem(text, text);
	shortname[client] = target;
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}


Action SkipBossPanel(int client)
{
	if(!Enabled2)
		return Plugin_Continue;

	Menu menu = new Menu(SkipBossPanelH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "to0_resetpts");

	char text[128];
	FormatEx(text, sizeof(text), "%t", "Yes");
	menu.AddItem(text, text);
	FormatEx(text, sizeof(text), "%t", "No");
	menu.AddItem(text, text);
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

int SkipBossPanelH(Menu menu, MenuAction action, int client, int position)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!position)
			{
				if(shortname[client] == client)
					FPrintToChat(client, "%t", "to0_resetpts");

				if(QueuePoints[client] >= 10)
					QueuePoints[client] -= 10;
			}
		}
	}
}

int Command_SetMyBossH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!param2)
			{
				xIncoming[param1][0] = 0;
				CanBossVs[param1] = 0;
				CanBossTeam[param1] = 0;
				IgnoreValid[param1] = false;
				DataBase_SaveKeepBossCookie(param1);
				FReplyToCommand(param1, "%t", "to0_comfirmrandom");
				return;
			}

			int option[5];
			for(int choices=1; choices<6; choices++)
			{
				if(!option[0] && cvarToggleBoss.BoolValue)
				{
					option[0] = choices;
					continue;
				}
				if(!option[1] && cvarDuoBoss.BoolValue)
				{
					option[1] = choices;
					continue;
				}
				if(!option[2] && kvDiffMods!=null && CheckCommandAccess(param1, "ff2_difficulty", 0, true))
				{
					option[2] = choices;
					continue;
				}
				if(!option[3] && cvarSkipBoss.BoolValue)
				{
					option[3] = choices;
					continue;
				}
				if(!option[4] && HasCharSets && !CharSetOldPath)
				{
					option[4] = choices;
					continue;
				}
			}

			if(param2 == option[0])
			{
				BossMenu(param1, 0);
			}
			else if(param2 == option[1])
			{
				CompanionMenu(param1, 0);
			}
			else if(param2 == option[2])
			{
				DiffMenu(param1, 0);
			}
			else if(param2 == option[3])
			{
				SkipBossPanel(param1);
			}
			else if(param2 == option[4])
			{
				PackMenu(param1);
			}
			else if(!cvarBossDesc.BoolValue || !ToggleInfo[param1])
			{
				static char name[64], bossName[64];
				menu.GetItem(param2, name, sizeof(name), _, bossName, sizeof(bossName));
				if(Utils_CheckValidBoss(param1, name))
				{
					strcopy(xIncoming[param1], sizeof(xIncoming[]), name);
					IgnoreValid[param1] = false;
					DataBase_SaveKeepBossCookie(param1);
					FReplyToCommand(param1, "%t", "to0_boss_selected", bossName);
				}
				else
				{
					Command_SetMyBoss(param1, 0);
				}
			}
			else
			{
				menu.GetItem(param2, cIncoming[param1], sizeof(cIncoming[]));
				ConfirmBoss(param1);
			}
		}
	}
}


int MenuHandlerCompanion(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		int choice = param2 + 1;
		ToggleDuo[param1] = view_as<SettingPrefs>(choice);

		switch(choice)
		{
			case 1:
				FPrintToChat(param1, "%t", "FF2 Companion Enabled");
			case 2:
				FPrintToChat(param1, "%t", "FF2 Companion Disabled");
			case 3:
				FPrintToChat(param1, "%t", "FF2 Companion Disabled For Map");
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

int MenuHandlerBoss(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		int choice = param2 + 1;
		ToggleBoss[param1] = view_as<SettingPrefs>(choice);

		switch(choice)
		{
			case 1:
				FPrintToChat(param1, "%t", "FF2 Toggle Enabled Notification");
			case 2:
				FPrintToChat(param1, "%t", "FF2 Toggle Disabled Notification");
			case 3:
				FPrintToChat(param1, "%t", "FF2 Toggle Disabled Notification For Map");
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
}

int Command_HudMenuH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(param2 == HUDTYPES-1)
			{
				if(++HudSettings[param1][param2] < 3)
					HudSettings[param1][param2] = 3;

				if(HudSettings[param1][param2] > 9)
					HudSettings[param1][param2] = 1;
			}
			else
			{
				HudSettings[param1][param2] = HudSettings[param1][param2] ? 0 : 1;
			}
			Command_HudMenu(param1, 0);
		}
	}
}


int MenuHandlerDifficulty(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			int choice = param2 + 1;
			ToggleDiff[param1] = view_as<SettingPrefs>(choice);

			switch(choice)
			{
				case 1:
					FPrintToChat(param1, "%t", "FF2 Special Enabled");
				case 2:
					FPrintToChat(param1, "%t", "FF2 Special Disabled");
				case 3:
					FPrintToChat(param1, "%t", "FF2 Special Disabled For Map");
			}
			
		}
	}
}

int DiffMenuH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!param2)
			{
				dIncoming[param1][0] = 0;
				DataBase_SaveKeepBossCookie(param1);
				ToggleDiff[param1] = Setting_Off;
				Command_SetMyBoss(param1, 0);
				return;
			}

			if(!cvarBossDesc.BoolValue)
			{
				if(Utils_IsBoss(param1) && Utils_CheckRoundState()!=2)
				{
					FReplyToCommand(param1, "%t", "ff2_changedifficulty_denied");
					DiffMenu(param1, 0);
					return;
				}

				menu.GetItem(param2, dIncoming[param1], sizeof(dIncoming[]));
				DataBase_SaveKeepBossCookie(param1);
				ToggleDiff[param1] = Setting_On;
				Command_SetMyBoss(param1, 0);
				return;
			}

			menu.GetItem(param2, cIncoming[param1], sizeof(cIncoming[]));
			ConfirmDiff(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Command_SetMyBoss(param1, 0);
		}
	}
}

Action ConfirmDiff(int client)
{
	char text[512];
	static char language[20], name[64];
	GetLanguageInfo(GetClientLanguage(client), language, sizeof(language), text, sizeof(text));
	Format(language, sizeof(language), "description_%s", language);
	SetGlobalTransTarget(client);

	KvRewind(kvDiffMods);
	KvGotoFirstSubKey(kvDiffMods);
	do
	{
		KvGetSectionName(kvDiffMods, name, sizeof(name));
		if(StrEqual(name, cIncoming[client], false))
		{
			KvGetString(kvDiffMods, language, text, sizeof(text));
			if(!text[0])
			{
				KvGetString(kvDiffMods, "description_en", text, sizeof(text));  //Default to English if their language isn't available
				if(!text[0])
					FormatEx(text, sizeof(text), "%t", "to0_nodesc");
			}
			ReplaceString(text, sizeof(text), "\\n", "\n");
			break;
		}
	} while(KvGotoNextKey(kvDiffMods));

	Menu menu = new Menu(ConfirmDiffH);
	menu.SetTitle(text);

	FormatEx(text, sizeof(text), "%t", "to0_confirm", name);
	menu.AddItem(name, text, (Utils_IsBoss(client) && Utils_CheckRoundState()!=2) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

	FormatEx(text, sizeof(text), "%t", "to0_cancel");
	menu.AddItem(text, text);

	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

int ConfirmDiffH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(param2)
			{
				DiffMenu(param1, 0);
			}
			else if(Utils_IsBoss(param1) && Utils_CheckRoundState()!=2)
			{
				FReplyToCommand(param1, "%t", "ff2_changedifficulty_denied");
				DiffMenu(param1, 0);
			}
			else
			{
				strcopy(dIncoming[param1], sizeof(dIncoming[]), cIncoming[param1]);
				DataBase_SaveKeepBossCookie(param1);
				ToggleDiff[param1] = Setting_On;
				Command_SetMyBoss(param1, 0);
			}
		}
	}
}


void PackMenu(int client)
{
	static char pack[128], num[4], config[PLATFORM_MAX_PATH];
	Menu menu = new Menu(PackMenuH);
	SetGlobalTransTarget(client);
	menu.SetTitle("%t", "to0_packmenu");

	BuildPath(Path_SM, config, sizeof(config), "%s/%s", CharSetOldPath ? ConfigPath : DataPath, CharsetCFG);

	Handle Kv = CreateKeyValues("");
	FileToKeyValues(Kv, config);
	int total;
	static char cookies[454];
	char cookieValues[MAXCHARSETS][64];
	if(AreClientCookiesCached(client))
	{
		GetClientCookie(client, SelectionCookie, cookies, sizeof(cookies));
		ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
	}

	do
	{
		total++;
		if(KvGetNum(Kv, "hidden"))
			continue;

		KvGetSectionName(Kv, pack, sizeof(pack));
		IntToString(total, num, sizeof(num));
		if(total < (MAXCHARSETS+1))
			Format(pack, sizeof(pack), "%s: %s", pack, cookieValues[total-1]);

		menu.AddItem(num, pack, (CurrentCharSet==total-1 || total>MAXCHARSETS) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	while(KvGotoNextKey(Kv));
	delete Kv;

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int PackMenuH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			static char pack[4];
			menu.GetItem(param2, pack, sizeof(pack));
			PackBoss(param1, StringToInt(pack)-1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				Command_SetMyBoss(param1, 0);
		}
	}
}

void PackBoss(int client, int pack)
{
	char boss[66], bossName[64];
	Menu menu = new Menu(PackBossH);
	SetGlobalTransTarget(client);

	if(AreClientCookiesCached(client))
	{
		static char cookies[454];
		char cookieValues[MAXCHARSETS][64];
		GetClientCookie(client, SelectionCookie, cookies, sizeof(cookies));
		ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
		if(cookieValues[pack][0])
			strcopy(boss, sizeof(boss), cookieValues[pack]);
	}

	menu.SetTitle("%t", "to0_viewpack", CharSetString[pack], boss);

	FormatEx(boss, sizeof(boss), ";%i", pack);
	FormatEx(bossName, sizeof(bossName), "%t", "to0_random");
	menu.AddItem(boss, bossName);

	for(int config; config<PackSpecials[pack]; config++)
	{
		KvRewind(PackKV[config][pack]);
		if(KvGetNum(PackKV[config][pack], "blocked"))
			continue;

		KvGetString(PackKV[config][pack], "name", boss, sizeof(boss));
		Utils_GetBossSpecial(config, bossName, sizeof(bossName), client, pack);
		if((KvGetNum(PackKV[config][pack], "donator") && !CheckCommandAccess(client, "ff2_donator_bosses", ADMFLAG_RESERVATION, true)) ||
		   (KvGetNum(PackKV[config][pack], "admin") && !CheckCommandAccess(client, "ff2_admin_bosses", ADMFLAG_GENERIC, true)))
		{
			if(!KvGetNum(PackKV[config][pack], "hidden"))
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(PackKV[config][pack], "owner") && !CheckCommandAccess(client, "ff2_owner_bosses", ADMFLAG_ROOT, true))
		{
			if(!KvGetNum(PackKV[config][pack], "hidden", 1))
				menu.AddItem(boss, bossName, ITEMDRAW_DISABLED);
		}
		else if(KvGetNum(PackKV[config][pack], "hidden") &&
		      !(KvGetNum(PackKV[config][pack], "donator") ||
		        KvGetNum(PackKV[config][pack], "theme") ||
			KvGetNum(PackKV[config][pack], "admin") ||
			KvGetNum(PackKV[config][pack], "owner")))
		{
			// Don't show
		}
		else
		{
			Format(boss, sizeof(boss), "%s;%i", boss, pack);
			menu.AddItem(boss, bossName);
		}
	}

	menu.ExitButton = true;
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int PackBossH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!AreClientCookiesCached(param1))
			{
				PrintToChat(param1, "[SM] %t", "Could not connect to database");
				PackMenu(param1);
				return;
			}

			static char name[2][64];
			static char cookies[454];
			menu.GetItem(param2, cookies, sizeof(cookies));
			int pack = ExplodeString(cookies, ";", name, 2, 64);
			if(pack < 1)
			{
				PackMenu(param1);
				return;
			}

			pack = StringToInt(name[1]);
			if(pack < MAXCHARSETS)
			{
				if(param2 && cvarBossDesc.BoolValue && ToggleInfo[param1])
				{
					strcopy(cIncoming[param1], sizeof(cIncoming[]), cookies);
					PackConfirmBoss(param1, pack);
					return;
				}

				char cookieValues[MAXCHARSETS][64];
				GetClientCookie(param1, SelectionCookie, cookies, sizeof(cookies));
				ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
				strcopy(cookieValues[pack], 64, name[0]);

				strcopy(cookies, sizeof(cookies), cookieValues[0]);
				for(int i=1; i<MAXCHARSETS; i++)
				{
					Format(cookies, sizeof(cookies), "%s;%s", cookies, cookieValues[i]);
				}
				SetClientCookie(param1, SelectionCookie, cookies);
			}

			PackMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				PackMenu(param1);
		}
	}
}


Action ConfirmBoss(int client)
{
	char text[512];
	static char language[20], boss[64];
	GetLanguageInfo(GetClientLanguage(client), language, sizeof(language), text, sizeof(text));
	Format(language, sizeof(language), "description_%s", language);
	SetGlobalTransTarget(client);

	for(int config; config<Specials; config++)
	{
		KvRewind(BossKV[config]);
		KvGetString(BossKV[config], "name", boss, sizeof(boss));
		if(StrEqual(boss, cIncoming[client], false))
		{
			KvRewind(BossKV[config]);
			KvGetString(BossKV[config], language, text, sizeof(text));
			if(!text[0])
			{
				KvGetString(BossKV[config], "description_en", text, sizeof(text));  //Default to English if their language isn't available
				if(!text[0])
					FormatEx(text, sizeof(text), "%t", "to0_nodesc");
			}
			ReplaceString(text, sizeof(text), "\\n", "\n");
			Utils_GetBossSpecial(config, boss, sizeof(boss), client);
			break;
		}
	}

	Menu menu = new Menu(ConfirmBossH);
	menu.SetTitle(text);

	FormatEx(text, sizeof(text), "%t", "to0_confirm", boss);
	menu.AddItem(boss, text);

	FormatEx(text, sizeof(text), "%t", "to0_cancel");
	menu.AddItem(text, text);

	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

int ConfirmBossH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!param2 && Utils_CheckValidBoss(param1, cIncoming[param1]))
			{
				static char bossName[64];
				menu.GetItem(param2, bossName, sizeof(bossName));
				strcopy(xIncoming[param1], sizeof(xIncoming[]), cIncoming[param1]);
				IgnoreValid[param1] = false;
				DataBase_SaveKeepBossCookie(param1);
				FReplyToCommand(param1, "%t", "to0_boss_selected", bossName);
			}
			else
			{
				Command_SetMyBoss(param1, 0);
			}
		}
	}
}

void PackConfirmBoss(int client, int pack)
{
	static char name[2][64];
	if(ExplodeString(cIncoming[client], ";", name, 2, 64) < 1)
	{
		PackMenu(client);
		return;
	}

	char text[512];
	static char language[20], boss[64];
	GetLanguageInfo(GetClientLanguage(client), language, sizeof(language), text, sizeof(text));
	Format(language, sizeof(language), "description_%s", language);
	SetGlobalTransTarget(client);

	for(int config; config<PackSpecials[pack]; config++)
	{
		KvRewind(PackKV[config][pack]);
		KvGetString(PackKV[config][pack], "name", boss, sizeof(boss));
		if(StrEqual(boss, name[0], false))
		{
			KvRewind(PackKV[config][pack]);
			KvGetString(PackKV[config][pack], language, text, sizeof(text));
			if(!text[0])
			{
				KvGetString(PackKV[config][pack], "description_en", text, sizeof(text));  //Default to English if their language isn't available
				if(!text[0])
					FormatEx(text, sizeof(text), "%t", "to0_nodesc");
			}
			ReplaceString(text, sizeof(text), "\\n", "\n");
			Utils_GetBossSpecial(config, boss, sizeof(boss), client, pack);
			break;
		}
	}

	Menu menu = new Menu(PackConfirmBossH);
	menu.SetTitle(text);

	FormatEx(text, sizeof(text), "%t", "to0_confirmpack", boss, CharSetString[pack]);
	menu.AddItem(boss, text);

	FormatEx(text, sizeof(text), "%t", "to0_cancel");
	menu.AddItem(text, text);

	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

int PackConfirmBossH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			static char name[2][64];
			int pack = ExplodeString(cIncoming[param1], ";", name, 2, 64);
			if(pack < 1)
			{
				PackMenu(param1);
				return;
			}

			pack = StringToInt(name[1]);
			if(!param2)
			{
				if(!AreClientCookiesCached(param1))
				{
					PrintToChat(param1, "[SM] %t", "Could not connect to database");
					PackMenu(param1);
					return;
				}

				if(pack < MAXCHARSETS)
				{
					static char cookies[454];
					char cookieValues[MAXCHARSETS][64];
					GetClientCookie(param1, SelectionCookie, cookies, sizeof(cookies));
					ExplodeString(cookies, ";", cookieValues, MAXCHARSETS, 64);
					strcopy(cookieValues[pack], 64, name[0]);

					strcopy(cookies, sizeof(cookies), cookieValues[0]);
					for(int i=1; i<MAXCHARSETS; i++)
					{
						Format(cookies, sizeof(cookies), "%s;%s", cookies, cookieValues[i]);
					}
					SetClientCookie(param1, SelectionCookie, cookies);
				}
			}
			else if(pack < MAXCHARSETS)
			{
				PackBoss(param1, pack);	
				return;
			}

			PackMenu(param1);
		}
	}
}


int FF2PanelH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			switch(selection)
			{
				case 0:
					Command_GetHPCmd(client, 0);

				case 1:
					Command_SetMyBoss(client, 0);

				case 2:
					Command_HelpPanelClass(client, 0);

				case 3:
					NewPanelCmd(client, 0);

				case 4:
					QueuePanelCmd(client, 0);

				case 5:
					Command_HudMenu(client, 0);

				case 6:
					MusicTogglePanelCmd(client, 0);

				case 7:
					VoiceTogglePanelCmd(client, 0);

				case 8:
					HelpPanel3Cmd(client, 0);
			}
		}
	}
}


Action HelpPanel3(int client)
{
	Menu menu = new Menu(ClassInfoTogglePanelH);
	menu.SetTitle("Turn the Freak Fortress 2 class info...");
	menu.AddItem("On", "On");
	menu.AddItem("Off", "Off");
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}


int ClassInfoTogglePanelH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(selection)
			{
				ToggleInfo[client] = false;
			}
			else
			{
				ToggleInfo[client] = true;
			}
			FPrintToChat(client, "%t", "ff2_classinfo", selection ? "off" : "on");	// TODO: Make this more multi-language friendly
		}
	}
}

void ToggleClassInfo(int client)
{
	if(ToggleInfo[client])
	{
		ToggleInfo[client] = false;
	}
	else
	{
		ToggleInfo[client] = true;
	}
	FPrintToChat(client, "%t", "ff2_classinfo", ToggleInfo[client] ? "on" : "off");	// TODO: Make this more multi-language friendly
}

Action HelpPanelClass(int client)
{
	if(!Enabled)
		return Plugin_Continue;

	int boss = Utils_GetBossIndex(client);
	if(boss != -1)
	{
		HelpPanelBoss(boss);
		return Plugin_Continue;
	}

	TFClassType class = TF2_GetPlayerClass(client);
	char text[512], translation[64];

	SetGlobalTransTarget(client);
	int weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(weapon))
	{
		FormatEx(translation, sizeof(translation), "primary_%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		if(TranslationPhraseExists(translation))
		{
			FormatEx(text, sizeof(text), "%t\n", translation);
		}
		else
		{
			switch(class)
			{
				case TFClass_Scout:
					FormatEx(text, sizeof(text), "%t\n", "primary_scout");

				case TFClass_Soldier:
					FormatEx(text, sizeof(text), "%t\n", "primary_soldier");

				case TFClass_Pyro:
					FormatEx(text, sizeof(text), "%t\n", "primary_pyro");

				case TFClass_DemoMan:
					FormatEx(text, sizeof(text), "%t\n", "primary_demo");

				case TFClass_Heavy:
					FormatEx(text, sizeof(text), "%t\n", "primary_heavy");

				case TFClass_Engineer:
					FormatEx(text, sizeof(text), "%t\n", "primary_engineer");

				case TFClass_Medic:
					FormatEx(text, sizeof(text), "%t\n", "primary_medic");

				case TFClass_Sniper:
					FormatEx(text, sizeof(text), "%t\n", "primary_sniper");

				case TFClass_Spy:
					FormatEx(text, sizeof(text), "%t\n", "primary_spy");

				default:
					FormatEx(text, sizeof(text), "%t\n", "primary_merc");
			}
		}
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(weapon))
	{
		FormatEx(translation, sizeof(translation), "secondary_%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		if(TranslationPhraseExists(translation))
		{
			Format(text, sizeof(text), "%s%t\n", text, translation);
		}
		else
		{
			switch(class)
			{
				case TFClass_Scout:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_scout");

				case TFClass_Soldier:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_soldier");

				case TFClass_Pyro:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_pyro");

				case TFClass_DemoMan:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_demo");

				case TFClass_Heavy:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_heavy");

				case TFClass_Engineer:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_engineer");

				case TFClass_Medic:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_medic");

				case TFClass_Sniper:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_sniper");

				case TFClass_Spy:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_spy");

				default:
					Format(text, sizeof(text), "%s%t\n", text, "secondary_merc");
			}
		}
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(weapon))
	{
		FormatEx(translation, sizeof(translation), "melee_%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		if(TranslationPhraseExists(translation))
		{
			Format(text, sizeof(text), "%s%t\n", text, translation);
		}
		else
		{
			switch(class)
			{
				case TFClass_Scout:
					Format(text, sizeof(text), "%s%t\n", text, "melee_scout");

				case TFClass_Soldier:
					Format(text, sizeof(text), "%s%t\n", text, "melee_soldier");

				case TFClass_Pyro:
					Format(text, sizeof(text), "%s%t\n", text, "melee_pyro");

				case TFClass_DemoMan:
					Format(text, sizeof(text), "%s%t\n", text, "melee_demo");

				case TFClass_Heavy:
					Format(text, sizeof(text), "%s%t\n", text, "melee_heavy");

				case TFClass_Engineer:
					Format(text, sizeof(text), "%s%t\n", text, "melee_engineer");

				case TFClass_Medic:
					Format(text, sizeof(text), "%s%t\n", text, "melee_medic");

				case TFClass_Sniper:
					Format(text, sizeof(text), "%s%t\n", text, "melee_sniper");

				case TFClass_Spy:
					Format(text, sizeof(text), "%s%t\n", text, "melee_spy");

				default:
					Format(text, sizeof(text), "%s%t\n", text, "melee_merc");
			}
		}
	}

	weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Building);
	if(IsValidEntity(weapon))
	{
		FormatEx(translation, sizeof(translation), "pda_%i", GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		if(TranslationPhraseExists(translation))
		{
			Format(text, sizeof(text), "%s%t\n", text, translation);
		}
		else
		{
			switch(class)
			{
				case TFClass_Engineer:
					Format(text, sizeof(text), "%s%t\n", text, "pda_engineer");

				case TFClass_Spy:
					Format(text, sizeof(text), "%s%t\n", text, "pda_spy");
			}
		}
	}

	if(text[0])
	{
		Format(text, sizeof(text), "%t\n\n%s", "info_title", text);
		Menu menu = new Menu(HintPanelH);
		menu.SetTitle(text);
		FormatEx(text, sizeof(text), "%t", "Exit");
		menu.AddItem(text, text);
		menu.ExitButton = false;
		menu.OptionFlags |= MENUFLAG_NO_SOUND;
		menu.Display(client, 25);
	}
	return Plugin_Continue;
}

void HelpPanelBoss(int boss)
{
	if(!Utils_IsValidClient(Boss[boss]))
		return;

	char text[512], language[20];
	GetLanguageInfo(GetClientLanguage(Boss[boss]), language, 8, text, 8);
	FormatEx(language, sizeof(language), "description_%s", language);

	KvRewind(BossKV[Special[boss]]);
	KvGetString(BossKV[Special[boss]], language, text, sizeof(text));
	if(!text[0])
	{
		KvGetString(BossKV[Special[boss]], "description_en", text, sizeof(text));  //Default to English if their language isn't available
		if(!text[0])
			return;
	}
	ReplaceString(text, sizeof(text), "\\n", "\n");

	Menu menu = new Menu(HintPanelH);
	menu.SetTitle(text);
	FormatEx(text, sizeof(text), "%T", "Exit", Boss[boss]);
	menu.AddItem(text, text);
	menu.ExitButton = false;
	menu.OptionFlags |= MENUFLAG_NO_SOUND;
	menu.Display(Boss[boss], 25);
}


Action MusicTogglePanel(int client)
{
	if(!cvarAdvancedMusic.BoolValue)
	{
		Menu menu = new Menu(MusicTogglePanelH);
		menu.SetTitle("Turn the Freak Fortress 2 music...");
		menu.AddItem("On", "On");
		menu.AddItem("Off", "Off");
		menu.ExitButton = false;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		char title[128];
		Menu menu = new Menu(MusicTogglePanelH);
		SetGlobalTransTarget(client);
		FormatEx(title, sizeof(title), "%t", "theme_menu");
		menu.SetTitle(title, title);
		if(ToggleMusic[client])
		{
			FormatEx(title, sizeof(title), "%t", "themes_disable");
			menu.AddItem(title, title);
			FormatEx(title, sizeof(title), "%t", "theme_skip");
			menu.AddItem(title, title);
			FormatEx(title, sizeof(title), "%t", "theme_shuffle");
			menu.AddItem(title, title);
			if(cvarSongInfo.IntValue >= 0)
			{
				FormatEx(title, sizeof(title), "%t", "theme_select");
				menu.AddItem(title, title);
			}
		}
		else
		{
			FormatEx(title, sizeof(title), "%t", "themes_enable");
			menu.AddItem(title, title);
		}
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Continue;
}

int MusicTogglePanelH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			if(!cvarAdvancedMusic.BoolValue)
			{
				if(selection)  //Off
				{
					ToggleMusic[client] = false;
					StopMusic(client, true);
				}
				else  //On
				{
					//If they already have music enabled don't do anything
					if(!ToggleMusic[client])
					{
						ToggleMusic[client] = true;
						StartMusic(client);
					}
				}
				FPrintToChat(client, "%t", "ff2_music", selection==2 ? "off" : "on");	// TODO: Make this more multi-language friendly
			}
			else
			{
				switch(selection)
				{
					case 0:
					{
						ToggleBGM(client, ToggleMusic[client] ? false : true);
						FPrintToChat(client, "%t", "ff2_music", ToggleVoice[client] ? "on" : "off");	// And here too
					}
					case 1:
					{
						Command_SkipSong(client, 0);
					}
					case 2:
					{
						Command_ShuffleSong(client, 0);
					}
					case 3:
					{
						Command_Tracklist(client, 0);
					}
				}
			}
		}
	}
}

void ToggleBGM(int client, bool enable)
{
	if(enable)
	{
		ToggleMusic[client] = true;
		StartMusic(client);
	}
	else
	{
		ToggleMusic[client] = false;
		StopMusic(client, true);
	}
}


int Command_TrackListH(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			StopMusic(param1, true);
			KvRewind(BossKV[Special[0]]);
			if(KvJumpToKey(BossKV[Special[0]], "sound_bgm"))
			{
				char music[PLATFORM_MAX_PATH];
				int track = param2+1;
				FormatEx(music, 10, "time%i", track);

				float time = Utils_GetSongLength(music);
				FormatEx(music, 10, "path%i", track);
				KvGetString(BossKV[Special[0]], music, music, sizeof(music));

				char id3[4][256];
				FormatEx(id3[0], sizeof(id3[]), "name%i", track);
				KvGetString(BossKV[Special[0]], id3[0], id3[2], sizeof(id3[]));
				FormatEx(id3[1], sizeof(id3[]), "artist%i", track);
				KvGetString(BossKV[Special[0]], id3[1], id3[3], sizeof(id3[]));

				char temp[PLATFORM_MAX_PATH], lives[256];
				FormatEx(temp, sizeof(temp), "sound/%s", music);
				if(FileExists(temp, true))
				{
					FormatEx(lives, sizeof(lives), "life%i", track);
					KvGetString(BossKV[Special[0]], lives, lives, sizeof(lives));
					if(lives[0])
					{
						if(StringToInt(lives) != BossLives[0])
						{
							if(MusicTimer[param1] != INVALID_HANDLE)
								KillTimer(MusicTimer[param1]);

							return;
						}
					}
					PlayBGM(param1, music, time, id3[2], id3[3]);
				}
				else
				{
					char bossName[64];
					KvGetString(BossKV[Special[0]], "filename", bossName, sizeof(bossName));
					LogToFile(eLog, "[Boss] Character %s is missing BGM file '%s'!", bossName, temp);
					if(MusicTimer[param1] != INVALID_HANDLE)
						KillTimer(MusicTimer[param1]);
				}
			}
		}
	}
	return;
}

Action VoiceTogglePanel(int client)
{
	Menu menu = new Menu(VoiceTogglePanelH);
	menu.SetTitle("Turn the Freak Fortress 2 voices...");
	menu.AddItem("On", "On");
	menu.AddItem("Off", "Off");
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}

int VoiceTogglePanelH(Menu menu, MenuAction action, int client, int selection)
{
	switch(action)
	{
		case MenuAction_End:
		{
		}
		case MenuAction_Select:
		{
			if(selection)
			{
				ToggleVoice[client] = false;
			}
			else
			{
				ToggleVoice[client] = true;
			}

			FPrintToChat(client, "%t", "ff2_voice", selection ? "off" : "on");	// TODO: Make this more multi-language friendly
			if(selection)
				FPrintToChat(client, "%t", "ff2_voice2");
		}
	}
}


int Handler_VoteCharset(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_VoteEnd:
		{
			char index[8], nextmap[32];
			menu.GetItem(param1, index, sizeof(index), _, FF2CharSetString, sizeof(FF2CharSetString));
			cvarCharset.IntValue = StringToInt(index);

			cvarNextmap.GetString(nextmap, sizeof(nextmap));
			FPrintToChatAll("%t", "nextmap_charset", nextmap, FF2CharSetString);	//"The character set for {1} will be {2}."
			isCharSetSelected = true;
		}
	}
}


int Command_LoadCharsetH(Menu menu, MenuAction action, int client, int choice)
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
			LoadCharset = true;
			if(!Utils_CheckRoundState() || Utils_CheckRoundState()==1)
			{
				FReplyToCommand(client, "The current character set is set to be switched!");
			}
			else
			{
				FReplyToCommand(client, "Character set has been switched");
				FindCharacters();
				FF2CharSetString[0] = 0;
				LoadCharset = false;
			}
		}
	}
}