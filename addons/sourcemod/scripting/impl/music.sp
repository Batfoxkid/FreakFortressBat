
public Action Timer_PrepareBGM(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(!FF2Globals.Enabled || Utils_CheckRoundState()!=1 || !client || Utils_MapHasMusic() || StrEqual(FF2PlayerInfo[client].CurrentBGM, "ff2_stop_music", true))
	{
		delete FF2PlayerInfo[client].MusicTimer;
		return;
	}

	KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special]);
	if(KvJumpToKey(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], "sound_bgm"))
	{
		char music[PLATFORM_MAX_PATH];
		int index;
		do
		{
			index++;
			FormatEx(music, 10, "time%i", index);
		}
		while(KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], music)>1);

		char lives[256];
		int topIndex = index;
		for(int i; i<19; i++)
		{
			index = GetRandomInt(1, topIndex-1);
			FormatEx(lives, sizeof(lives), "life%i", index);
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], lives, lives, sizeof(lives));
			if(StringToInt(lives))
			{
				if(StringToInt(lives) != FF2BossInfo[0].Lives)
					continue;
			}
			break;
		}
		FormatEx(music, 10, "time%i", index);
		float time = KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], music);
		FormatEx(music, 10, "path%i", index);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], music, music, sizeof(music));

		FF2PlayerInfo[client].SongIdx=index;

		// manual song ID
		char id3[4][256];
		FormatEx(id3[0], sizeof(id3[]), "name%i", index);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], id3[0], id3[2], sizeof(id3[]));
		FormatEx(id3[1], sizeof(id3[]), "artist%i", index);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], id3[1], id3[3], sizeof(id3[]));

		char temp[PLATFORM_MAX_PATH];
		FormatEx(temp, sizeof(temp), "sound/%s", music);
		if(FileExists(temp, true))
		{
			PlayBGM(client, music, time, id3[2], id3[3]);
		}
		else
		{
			char bossName[64];
			KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special]);
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], "filename", bossName, sizeof(bossName));
			LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is missing BGM file '%s'!", bossName, temp);
			//PrintToConsoleAll("{red}MALFUNCTION! NEED INPUT!");
			if(FF2PlayerInfo[client].MusicTimer != null) {
				delete FF2PlayerInfo[client].MusicTimer;
			}
		}
	}
}

void PlayBGM(int client, char[] music, float time, char[] name="", char[] artist="")
{
	char temp[3][PLATFORM_MAX_PATH];
	float time2 = time;
	strcopy(temp[0], sizeof(temp[]), music);
	strcopy(temp[1], sizeof(temp[]), name);
	strcopy(temp[2], sizeof(temp[]), artist);

	Action action = Forwards_Call_OnMusic2(temp[0], time2, temp[1], temp[2], sizeof(temp[]));
	switch(action)
	{
		case Plugin_Stop, Plugin_Handled:
		{
			//PrintToConsoleAll("NEED BIGGER INPUT!");
			return;
		}
		case Plugin_Changed:
		{
			strcopy(music, PLATFORM_MAX_PATH, temp[0]);
			strcopy(name, PLATFORM_MAX_PATH, temp[1]);
			strcopy(artist, PLATFORM_MAX_PATH, temp[2]);
			time = time2;
			//PrintToConsoleAll("OOO... BIGGER INPUT! %s | %f | %s | %s", music, time, name, artist);
		}
		default:
		{
			time2 = time;
			Action action2 = Forwards_Call_OnMusic(temp[0], sizeof(temp[]), time2);
			switch(action2)
			{
				case Plugin_Stop, Plugin_Handled:
				{
					//PrintToConsoleAll("NEED INPUT!");
					return;
				}
				case Plugin_Changed:
				{
					strcopy(music, PLATFORM_MAX_PATH, temp[0]);
					time=time2;
					//PrintToConsoleAll("OOO... INPUT! %s | %f", music, time);
				}
			}
		}
	}

	FormatEx(temp[0], sizeof(temp[]), "sound/%s", music);
	if(FileExists(temp[0], true))
	{
		bool unknown1 = true;
		bool unknown2 = true;
		if(FF2PlayerCookie[client].MusicOn)
		{
			strcopy(FF2PlayerInfo[client].CurrentBGM, PLATFORM_MAX_PATH, music);

			// EmitSoundToClient can sometimes not loop correctly
			// 'playgamesound' can rarely not stop correctly
			// 'play' can be stopped or interrupted by other things
			// # before filepath effects music slider but can't stop correctly most of the time

			ClientCommand(client, "playgamesound \"%s\"", music);
			if(time > 1)
				FF2PlayerInfo[client].MusicTimer = CreateTimer(time, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}

		if(!name[0])
		{
			FormatEx(name, 256, "%T", "unknown_song", client);
			unknown1 = false;
		}

		if(!artist[0])
		{
			FormatEx(artist, 256, "%T", "unknown_artist", client);
			unknown2 = false;
		}

		if(ConVars.SongInfo.IntValue==1 || ((unknown1 || unknown2) && !ConVars.SongInfo.IntValue))
		{
			FPrintToChat(client, "%t", "track_info", artist, name);
		}
	}
	else
	{
		char bossName[64];
		KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special]);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[0].Special], "filename", bossName, sizeof(bossName));
		LogToFile(FF2LogsPaths.Errors, "[Boss] Character %s is missing BGM file '%s'!", bossName, music);
	}
}

void StartMusic(int client=0)
{
	if(!FF2Globals.Enabled)
		return;

	if(client < 1)  //Start music for all clients
	{
		StopMusic();
		for(int target; target<=MaxClients; target++)
		{
			FF2PlayerInfo[target].PlayBGM = true;  //This includes the 0th index
			if(Utils_IsValidClient(target))
			{
				CreateTimer(0.2, Timer_PrepareBGM, GetClientUserId(target), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	else
	{
		StopMusic(client);
		FF2PlayerInfo[client].PlayBGM = true;
		CreateTimer(0.1, Timer_PrepareBGM, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

void StopMusic(int client=0, bool permanent=false)
{
	if(client < 1)  //Stop music for all clients
	{
		if(permanent)
			FF2PlayerInfo[0].PlayBGM = false;

		for(client=1; client<=MaxClients; client++)
		{
			if(Utils_IsValidClient(client))
			{
				StopSound(client, SNDCHAN_AUTO, FF2PlayerInfo[client].CurrentBGM);
				if(FF2PlayerInfo[client].MusicTimer != null)
				{
					//PrintToConsoleAll("TERMINATING INPUT!");
					delete FF2PlayerInfo[client].MusicTimer;
				}
			}

			//strcopy(FF2PlayerInfo[client].CurrentBGM, PLATFORM_MAX_PATH, "");
			if(permanent)
				FF2PlayerInfo[client].PlayBGM=false;
		}
	}
	else
	{
		StopSound(client, SNDCHAN_AUTO, FF2PlayerInfo[client].CurrentBGM);
		StopSound(client, SNDCHAN_AUTO, FF2PlayerInfo[client].CurrentBGM);

		if(FF2PlayerInfo[client].MusicTimer != null)
		{
			//PrintToConsoleAll("END INPUT FOR %N!", client);
			delete FF2PlayerInfo[client].MusicTimer;
		}

		strcopy(FF2PlayerInfo[client].CurrentBGM, PLATFORM_MAX_PATH, "");
		if(permanent)
			FF2PlayerInfo[client].PlayBGM = false;
	}
}