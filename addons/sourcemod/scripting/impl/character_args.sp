int GetAbilityArgument(int index, const char[] plugin_name, const char[] ability_name, int arg, int defvalue=0)
{
	char str[10];
	FormatEx(str, sizeof(str), "arg%i", arg);
	return GetArgumentI(index, plugin_name, ability_name, str, defvalue);
}

float GetAbilityArgumentFloat(int index, const char[] plugin_name, const char[] ability_name, int arg, float defvalue=0.0)
{
	char str[10];
	FormatEx(str, sizeof(str), "arg%i", arg);
	return GetArgumentF(index, plugin_name, ability_name, str, defvalue);
}

void GetAbilityArgumentString(int index, const char[] plugin_name, const char[] ability_name, int arg, char[] buffer, int buflen)
{
	char str[10];
	FormatEx(str, sizeof(str), "arg%i", arg);
	GetArgumentS(index, plugin_name, ability_name, str, buffer, buflen);
}

int GetArgumentI(int index, const char[] plugin_name, const char[] ability_name, const char[] arg, int defvalue=0)
{
	if(index==-1 || FF2BossInfo[index].Special==-1 || !FF2CharSetInfo.BossKV[FF2BossInfo[index].Special])
		return defvalue;
	
	FF2Data data = FF2Data(index, plugin_name, ability_name);
	return data.Invalid ? defvalue:data.GetArgI(arg, defvalue);
}

float GetArgumentF(int index, const char[] plugin_name, const char[] ability_name, const char[] arg, float defvalue=0.0)
{
	if(index==-1 || FF2BossInfo[index].Special==-1 || !FF2CharSetInfo.BossKV[FF2BossInfo[index].Special])
		return defvalue;

	FF2Data data = FF2Data(index, plugin_name, ability_name);
	return data.Invalid ? defvalue:data.GetArgF(arg, defvalue);
}

void GetArgumentS(int index, const char[] plugin_name, const char[] ability_name, const char[] arg, char[] buffer, int buflen)
{
	buffer[0] = '\0';
	if(index==-1 || FF2BossInfo[index].Special==-1 || !FF2CharSetInfo.BossKV[FF2BossInfo[index].Special])
		return;
	
	FF2Data data = FF2Data(index, plugin_name, ability_name);
	if(!data.Invalid)
		data.GetArgS(arg, buffer, buflen);
}

bool RandomSound(const char[] sound, char[] file, int length, int boss=0)
{
	if(boss<0 || FF2BossInfo[boss].Special<0 || !FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special])
		return false;

	KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
	if(!KvJumpToKey(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], sound))
	{
		KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
		return false;  // Requested sound not implemented for this boss
	}

	char key[10];
	int sounds;
	while(++sounds)  // Just keep looping until there's no keys left
	{
		IntToString(sounds, key, sizeof(key));
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, file, length);
		if(!file[0])
		{
			sounds--;  // This sound wasn't valid, so don't include it
			break;  // Assume that there's no more sounds
		}
	}

	if(!sounds)
		return false;  //Found sound, but no sounds inside of it

	char path[PLATFORM_MAX_PATH];
	static char temp[6];
	int choosen = GetRandomInt(1, sounds);
	FormatEx(key, sizeof(key), "%i_overlay", choosen);	// Don't ask me why this format just go with it
	KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, path, sizeof(path));
	if(path[0])
	{
		TFTeam team = TF2_GetClientTeam(FF2BossInfo[boss].Boss);
		for(int client=1; client<=MaxClients; client++)
		{
			if(Utils_IsValidClient(client) && TF2_GetClientTeam(client)!=team)
				Utils_DoOverlay(client, path);
		}

		FormatEx(path, sizeof(path), "%i_overlay_time", choosen);
		float time = KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], path);
		if(time > 0)
			CreateTimer(time, Timer_RemoveOverlay, team, TIMER_FLAG_NO_MAPCHANGE);

		//PrintToConsoleAll("%s | %i | %f", path, view_as<int>(team), time);
	}

	FormatEx(key, sizeof(key), "%imusic", choosen);	// And this...
	KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, temp, sizeof(temp));
	if(temp[0])
	{
		float time = KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key);

		static char name[64], artist[64];

		IntToString(choosen, key, sizeof(key));
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, path, sizeof(path));

		FormatEx(key, sizeof(key), "%iname", choosen);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, name, sizeof(name));

		FormatEx(key, sizeof(key), "%iartist", choosen);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, artist, sizeof(artist));

		for(int client=1; client<=MaxClients; client++)
		{
			if(Utils_IsValidClient(client))
			{
				StopMusic(client);
				strcopy(FF2PlayerInfo[client].CurrentBGM, sizeof(FF2PlayerInfo[].CurrentBGM), path);
				PlayBGM(client, path, time, name, artist);
			}
		}
		return false; // Don't return to play sound
	}

	IntToString(choosen, key, sizeof(key));
	KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, file, length);  // Populate file
	return true;
}

bool RandomSoundAbility(const char[] sound, char[] file, int length, int boss=0, int slot=0)
{
	if(boss<0 || FF2BossInfo[boss].Special<0 || !FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special])
		return false;

	KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
	if(!KvJumpToKey(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], sound))
		return false;  //Sound doesn't exist

	char key[10];
	int sounds, matches, match[MAXRANDOMS];
	while(++sounds)
	{
		IntToString(sounds, key, 4);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, file, length);
		if(!file[0])
			break;  //Assume that there's no more sounds

		FormatEx(key, sizeof(key), "slot%i", sounds);
		if(KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key)==slot)
		{
			match[matches] = sounds;  //Found a match: let's store it in the array
			matches++;
		}
	}

	if(!matches)
		return false;  //Found sound, but no sounds inside of it

	IntToString(match[GetRandomInt(0, matches-1)], key, 4);
	KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, file, length);  //Populate file
	return true;
}

bool RandomSoundVo(const char[] sound, char[] file, int length, int boss=0, const char[] oldFile)
{
	if(boss<0 || FF2BossInfo[boss].Special<0 || !FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special])
		return false;

	KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
	if(!KvJumpToKey(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], sound))
		return false;  //Sound doesn't exist

	char key[10];
	static char replacement[PLATFORM_MAX_PATH];
	int sounds, matches, match[MAXRANDOMS];
	while(++sounds)
	{
		IntToString(sounds, key, 4);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, file, length);
		if(!file[0])
			break;  //Assume that there's no more sounds

		FormatEx(key, sizeof(key), "vo%i", sounds);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, replacement, sizeof(replacement));
		if(!StrContains(replacement, oldFile, false))
		{
			match[matches] = sounds;  //Found a match: let's store it in the array
			matches++;
		}
	}

	if(!matches)
		return false;  //Found sound, but no sounds inside of it

	IntToString(match[GetRandomInt(0, matches-1)], key, 4);
	KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], key, file, length);  //Populate file
	return true;
}


TFClassType KvGetClass(Handle keyvalue, const char[] string)
{
	TFClassType class;
	static char buffer[24];
	KvGetString(keyvalue, string, buffer, sizeof(buffer));
	class = view_as<TFClassType>(StringToInt(buffer));
	if(class == TFClass_Unknown)
	{
		class = TF2_GetClass(buffer);
		if(class == TFClass_Unknown)
			class = TFClass_Scout;
	}
	return class;
}


void ActivateAbilitySlot(int boss, int slot, bool buttonmodeactive=false)
{
	int ability_slot, buttonmode, count, j;
	char ability[12];
	static char lives[MAXRANDOMS][3];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		FormatEx(ability, sizeof(ability), "ability%i", i);
		KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special]);
		if(KvJumpToKey(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], ability))
		{
			if(KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "noversus") && FF2Globals.Enabled3)
				continue;

			ability_slot = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "slot", -2);
			if(ability_slot == -2)
				ability_slot = KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "arg0");

			if(ability_slot != slot)
				continue;
	
			buttonmode = (buttonmodeactive) ? (KvGetNum(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "buttonmode")) : 0;

			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "life", ability, sizeof(ability));
			static char abilityName[64], pluginName[64];
			if(!ability[0])
			{
				KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "plugin_name", pluginName, sizeof(pluginName));
				KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "name", abilityName, sizeof(abilityName));
				if(!Utils_UseAbility(abilityName, pluginName, boss, slot, buttonmode))
					return;
			}
			else
			{
				count = ExplodeString(ability, " ", lives, MAXRANDOMS, 3);
				for(j=0; j<count; j++)
				{
					if(StringToInt(lives[j]) == FF2BossInfo[boss].Lives)
					{
						KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "plugin_name", pluginName, sizeof(pluginName));
						KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special], "name", abilityName, sizeof(abilityName));
						if(!Utils_UseAbility(abilityName, pluginName, boss, slot, buttonmode))
							return;

						break;
					}
				}
			}
		}
	}
}