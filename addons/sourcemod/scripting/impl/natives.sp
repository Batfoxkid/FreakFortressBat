
void Natives_Create()
{
	CreateNative("FF2_IsFF2Enabled", Native_IsEnabled);
	CreateNative("FF2_GetFF2Version", Native_FF2Version);
	CreateNative("FF2_IsBossVsBoss", Native_IsVersus);
	CreateNative("FF2_GetForkVersion", Native_ForkVersion);
	CreateNative("FF2_GetBossUserId", Native_GetBoss);
	CreateNative("FF2_GetBossIndex", Native_GetIndex);
	CreateNative("FF2_GetBossTeam", Native_GetTeam);
	CreateNative("FF2_GetBossSpecial", Native_GetSpecial);
	CreateNative("FF2_GetBossName", Native_GetName);
	CreateNative("FF2_GetBossHealth", Native_GetBossHealth);
	CreateNative("FF2_SetBossHealth", Native_SetBossHealth);
	CreateNative("FF2_GetBossMaxHealth", Native_GetBossMaxHealth);
	CreateNative("FF2_SetBossMaxHealth", Native_SetBossMaxHealth);
	CreateNative("FF2_GetBossLives", Native_GetBossLives);
	CreateNative("FF2_SetBossLives", Native_SetBossLives);
	CreateNative("FF2_GetBossMaxLives", Native_GetBossMaxLives);
	CreateNative("FF2_SetBossMaxLives", Native_SetBossMaxLives);
	CreateNative("FF2_GetBossCharge", Native_GetBossCharge);
	CreateNative("FF2_SetBossCharge", Native_SetBossCharge);
	CreateNative("FF2_GetBossRageDamage", Native_GetBossRageDamage);
	CreateNative("FF2_SetBossRageDamage", Native_SetBossRageDamage);
	CreateNative("FF2_GetClientDamage", Native_GetDamage);
	CreateNative("FF2_GetRoundState", Native_GetRoundState);
	CreateNative("FF2_GetSpecialKV", Native_GetSpecialKV);
	CreateNative("FF2_StartMusic", Native_StartMusic);
	CreateNative("FF2_StopMusic", Native_StopMusic);
	CreateNative("FF2_GetRageDist", Native_GetRageDist);
	CreateNative("FF2_HasAbility", Native_HasAbility);
	CreateNative("FF2_DoAbility", Native_DoAbility);
	CreateNative("FF2_GetAbilityArgument", Native_GetAbilityArgument);
	CreateNative("FF2_GetAbilityArgumentFloat", Native_GetAbilityArgumentFloat);
	CreateNative("FF2_GetAbilityArgumentString", Native_GetAbilityArgumentString);
	CreateNative("FF2_GetArgNamedI", Native_GetArgNamedI);
	CreateNative("FF2_GetArgNamedF", Native_GetArgNamedF);
	CreateNative("FF2_GetArgNamedS", Native_GetArgNamedS);
	CreateNative("FF2_RandomSound", Native_RandomSound);
	CreateNative("FF2_EmitVoiceToAll", Native_EmitVoiceToAll);
	CreateNative("FF2_GetFF2flags", Native_GetFF2flags);
	CreateNative("FF2_SetFF2flags", Native_SetFF2flags);
	CreateNative("FF2_GetQueuePoints", Native_GetQueuePoints);
	CreateNative("FF2_SetQueuePoints", Native_SetQueuePoints);
	CreateNative("FF2_GetClientGlow", Native_GetClientGlow);
	CreateNative("FF2_SetClientGlow", Native_SetClientGlow);
	CreateNative("FF2_GetClientShield", Native_GetClientShield);
	CreateNative("FF2_SetClientShield", Native_SetClientShield);
	CreateNative("FF2_RemoveClientShield", Native_RemoveClientShield);
	CreateNative("FF2_LogError", Native_LogError);
	CreateNative("FF2_Debug", Native_Debug);
	CreateNative("FF2_SetCheats", Native_SetCheats);
	CreateNative("FF2_GetCheats", Native_GetCheats);
	CreateNative("FF2_MakeBoss", Native_MakeBoss);
	CreateNative("FF2_SelectBoss", Native_ChooseBoss);
	CreateNative("FF2_ReportError", Native_ReportError);
	
	CreateNative("FF2Data.Unknown", FF2Data_Unknown);
	CreateNative("FF2Data.FF2Data", FF2Data_FF2Data);
	CreateNative("FF2Data.boss.get", FF2Data_boss);
	CreateNative("FF2Data.client.get", FF2Data_client);
	CreateNative("FF2Data.Config.get", FF2Data_GetConfig);
	CreateNative("FF2Data.Health.get", Native_GetBossHealth);
	CreateNative("FF2Data.Health.set", Native_SetBossHealth);
	CreateNative("FF2Data.MaxHealth.get", Native_GetBossMaxHealth);
	CreateNative("FF2Data.MaxHealth.set", Native_SetBossMaxHealth);
	CreateNative("FF2Data.Lives.get", Native_SetBossLives);
	CreateNative("FF2Data.Lives.set", Native_GetBossLives);
	CreateNative("FF2Data.MaxLives.get", Native_GetBossMaxLives);
	CreateNative("FF2Data.MaxLives.set", Native_SetBossMaxLives);
	CreateNative("FF2Data.RageDmg.get", Native_GetBossRageDamage);
	CreateNative("FF2Data.RageDmg.set", Native_SetBossRageDamage);
	CreateNative("FF2Data.Change", FF2Data_Change);
	CreateNative("FF2Data.GetArgI", FF2Data_GetArgI);
	CreateNative("FF2Data.GetArgF", FF2Data_GetArgF);
	CreateNative("FF2Data.GetArgB", FF2Data_GetArgB);
	CreateNative("FF2Data.GetArgS", FF2Data_GetArgS);
	CreateNative("FF2Data.HasAbility", FF2Data_HasAbility);
	CreateNative("FF2Data.BossTeam", Native_GetTeam);
}


int Native_IsEnabled(Handle plugin, int numParams)
{
	return FF2Globals.Enabled;
}

int Native_FF2Version(Handle plugin, int numParams)
{
	int version[3];  //Blame the compiler for this mess -.-
	version[0] = StringToInt(MAJOR_REVISION);
	version[1] = StringToInt(MINOR_REVISION);
	version[2] = StringToInt(STABLE_REVISION);
	SetNativeArray(1, version, sizeof(version));
	#if defined DEV_REVISION
	return true;
	#else
	return false;
	#endif
}

int Native_IsVersus(Handle plugin, int numParams)
{
	return FF2Globals.Enabled3;
}

int Native_ForkVersion(Handle plugin, int numParams)
{
	int fversion[3];
	fversion[0] = StringToInt(FORK_MAJOR_REVISION);
	fversion[1] = StringToInt(FORK_MINOR_REVISION);
	fversion[2] = StringToInt(FORK_STABLE_REVISION);
	SetNativeArray(1, fversion, sizeof(fversion));
	#if defined FORK_DEV_REVISION
	return true;
	#else
	return false;
	#endif
}

int Native_GetBoss(Handle plugin, int numParams)
{
	int boss = GetNativeCell(1);
	if(boss>=0 && boss<=MaxClients && Utils_IsValidClient(FF2BossInfo[boss].Boss))
		return GetClientUserId(FF2BossInfo[boss].Boss);

	return -1;
}

int Native_GetIndex(Handle plugin, int numParams)
{
	return Utils_GetBossIndex(GetNativeCell(1));
}

int Native_GetTeam(Handle plugin, int numParams)
{
	return FF2Globals.BossTeam;
}

int Native_GetSpecial(Handle plugin, int numParams)
{
	int index=GetNativeCell(1), dstrlen=GetNativeCell(3), see=GetNativeCell(4);
	char[] s = new char[dstrlen];
	if(see)
	{
		if(index<0)
			return false;

		if(!FF2CharSetInfo.BossKV[index])
			return false;

		KvRewind(FF2CharSetInfo.BossKV[index]);
		KvGetString(FF2CharSetInfo.BossKV[index], "name", s, dstrlen);
	}
	else
	{
		if(index<0)
			return false;

		if(FF2BossInfo[index].Special<0)
			return false;

		if(!FF2CharSetInfo.BossKV[FF2BossInfo[index].Special])
			return false;

		KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special]);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special], "name", s, dstrlen);
	}
	SetNativeString(2, s, dstrlen);
	return true;
}

int Native_GetName(Handle plugin, int numParams)
{
	int index=GetNativeCell(1), dstrlen=GetNativeCell(3), see=GetNativeCell(4), client=GetNativeCell(5);
	char[] s = new char[dstrlen];

	static char language[20];
	GetLanguageInfo(client ? GetClientLanguage(client) : GetServerLanguage(), language, sizeof(language), s, dstrlen);
	Format(language, sizeof(language), "name_%s", language);

	if(see)
	{
		if(index < 0)
			return false;

		if(!FF2CharSetInfo.BossKV[index])
			return false;

		KvRewind(FF2CharSetInfo.BossKV[index]);
		KvGetString(FF2CharSetInfo.BossKV[index], language, s, dstrlen);
		if(!s[0])
		{
			if(client)
			{
				GetLanguageInfo(GetServerLanguage(), language, sizeof(language), s, dstrlen);
				Format(language, sizeof(language), "name_%s", language);
				KvGetString(FF2CharSetInfo.BossKV[index], language, s, dstrlen);
			}

			if(!s[0])
				KvGetString(FF2CharSetInfo.BossKV[index], "name", s, dstrlen);
		}
	}
	else
	{
		if(index < 0)
			return false;

		if(FF2BossInfo[index].Special<0)
			return false;

		if(!FF2CharSetInfo.BossKV[FF2BossInfo[index].Special])
			return false;

		KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special]);
		KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special], language, s, dstrlen);
		if(!s[0])
		{
			if(client)
			{
				GetLanguageInfo(GetServerLanguage(), language, sizeof(language), s, dstrlen);
				Format(language, sizeof(language), "name_%s", language);
				KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special], language, s, dstrlen);
			}

			if(!s[0])
				KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special], "name", s, dstrlen);
		}
	}

	if(!s[0])
		return false;

	SetNativeString(2, s, dstrlen);
	return true;
}

int Native_GetBossHealth(Handle plugin, int numParams)
{
	return FF2BossInfo[GetNativeCell(1)].Health;
}

int Native_SetBossHealth(Handle plugin, int numParams)
{
	FF2BossInfo[GetNativeCell(1)].Health = GetNativeCell(2);
	UpdateHealthBar();
}

int Native_GetBossMaxHealth(Handle plugin, int numParams)
{
	return FF2BossInfo[GetNativeCell(1)].HealthMax;
}

int Native_SetBossMaxHealth(Handle plugin, int numParams)
{
	FF2BossInfo[GetNativeCell(1)].HealthMax = GetNativeCell(2);
	UpdateHealthBar();
}

int Native_GetBossLives(Handle plugin, int numParams)
{
	return FF2BossInfo[GetNativeCell(1)].Lives;
}

int Native_SetBossLives(Handle plugin, int numParams)
{
	FF2BossInfo[GetNativeCell(1)].Lives = GetNativeCell(2);
}

int Native_GetBossMaxLives(Handle plugin, int numParams)
{
	return FF2BossInfo[GetNativeCell(1)].LivesMax;
}

int Native_SetBossMaxLives(Handle plugin, int numParams)
{
	FF2BossInfo[GetNativeCell(1)].LivesMax = GetNativeCell(2);
}

int Native_GetBossCharge(Handle plugin, int numParams)
{
	return view_as<int>(FF2BossInfo[GetNativeCell(1)].Charge[GetNativeCell(2)]);
}

int Native_SetBossCharge(Handle plugin, int numParams)  //TODO: This duplicates logic found in Timer_UseBossCharge
{
	FF2BossInfo[GetNativeCell(1)].Charge[GetNativeCell(2)] = GetNativeCell(3);
}

int Native_GetBossRageDamage(Handle plugin, int numParams)
{
	return FF2BossInfo[GetNativeCell(1)].RageDamage;
}

int Native_SetBossRageDamage(Handle plugin, int numParams)
{
	FF2BossInfo[GetNativeCell(1)].RageDamage = GetNativeCell(2);
}

int Native_GetRoundState(Handle plugin, int numParams)
{
	if(Utils_CheckRoundState() < 1)
		return 0;

	return Utils_CheckRoundState();
}

int Native_GetRageDist(Handle plugin, int numParams)
{
	int index = GetNativeCell(1);
	static char ability_name[64];
	GetNativeString(3, ability_name, 64);

	if(!FF2CharSetInfo.BossKV[FF2BossInfo[index].Special])
		return view_as<int>(0.0);

	KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special]);
	float see;
	if(!ability_name[0])
		return view_as<int>(KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special], "ragedist", 400.0));

	char s[10];
	for(int i=1; i<=MAXRANDOMS; i++)
	{
		FormatEx(s, sizeof(s), "ability%i", i);
		if(KvJumpToKey(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special], s))
		{
			static char ability_name2[64];
			KvGetString(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special], "name", ability_name2, 64);
			if(strcmp(ability_name, ability_name2))
			{
				KvGoBack(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special]);
				continue;
			}
	
			if((see=KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special], "dist", -1.0)) < 0)
			{
				KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special]);
				see = KvGetFloat(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special], "ragedist", 400.0);
			}
			return view_as<int>(see);
		}
	}
	return view_as<int>(0.0);
}


int Native_HasAbility(Handle plugin, int numParams)
{
	int boss = GetNativeCell(1);
	if(boss==-1 || boss>=MAXTF2PLAYERS || FF2BossInfo[boss].Special==-1 || !FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special])
		return false;
	
	char pluginName[64], abilityName[64];

	GetNativeString(2, pluginName, sizeof(pluginName));
	GetNativeString(3, abilityName, sizeof(abilityName));
	ReplaceString(pluginName, sizeof(pluginName), ".smx", "");
	
	return Utils_HasAbility(boss, pluginName, abilityName);
}

int Native_DoAbility(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	ReplaceString(plugin_name, sizeof(plugin_name), ".smx", "");
	Utils_UseAbility(ability_name, plugin_name, GetNativeCell(1), GetNativeCell(4), GetNativeCell(5));
}

int Native_GetAbilityArgument(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	ReplaceString(plugin_name, sizeof(plugin_name), ".smx", "");
	return GetAbilityArgument(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5));
}

any Native_GetAbilityArgumentFloat(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	ReplaceString(plugin_name, sizeof(plugin_name), ".smx", "");
	return GetAbilityArgumentFloat(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), GetNativeCell(5));
}

int Native_GetAbilityArgumentString(Handle plugin, int numParams)
{
	static char plugin_name[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	static char ability_name[64];
	GetNativeString(3, ability_name, sizeof(ability_name));
	ReplaceString(plugin_name, sizeof(plugin_name), ".smx", "");
	int dstrlen = GetNativeCell(6);
	char[] s = new char[dstrlen+1];
	GetAbilityArgumentString(GetNativeCell(1), plugin_name, ability_name, GetNativeCell(4), s, dstrlen);
	SetNativeString(5, s, dstrlen);
}

int Native_GetArgNamedI(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	ReplaceString(plugin_name, sizeof(plugin_name), ".smx", "");
	return GetArgumentI(GetNativeCell(1), plugin_name, ability_name, argument, GetNativeCell(5));
}

any Native_GetArgNamedF(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	ReplaceString(plugin_name, sizeof(plugin_name), ".smx", "");
	return GetArgumentF(GetNativeCell(1), plugin_name, ability_name, argument, GetNativeCell(5));
}

int Native_GetArgNamedS(Handle plugin, int numParams)
{
	static char plugin_name[64];
	static char ability_name[64];
	static char argument[64];
	GetNativeString(2, plugin_name, sizeof(plugin_name));
	GetNativeString(3, ability_name, sizeof(ability_name));
	GetNativeString(4, argument, sizeof(argument));
	ReplaceString(plugin_name, sizeof(plugin_name), ".smx", "");
	int dstrlen = GetNativeCell(6);
	char[] s = new char[dstrlen+1];
	GetArgumentS(GetNativeCell(1), plugin_name, ability_name, argument, s, dstrlen);
	SetNativeString(5, s, dstrlen);
}

int Native_GetDamage(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!Utils_IsValidClient(client))
		return 0;

	return FF2PlayerInfo[client].Damage;
}

int Native_GetFF2flags(Handle plugin, int numParams)
{
	return FF2PlayerInfo[GetNativeCell(1)].FF2Flags;
}

int Native_SetFF2flags(Handle plugin, int numParams)
{
	FF2PlayerInfo[GetNativeCell(1)].FF2Flags = GetNativeCell(2);
}

int Native_GetQueuePoints(Handle plugin, int numParams)
{
	return FF2PlayerCookie[GetNativeCell(1)].QueuePoints;
}

int Native_SetQueuePoints(Handle plugin, int numParams)
{
	FF2PlayerCookie[GetNativeCell(1)].QueuePoints = GetNativeCell(2);
}

int Native_GetSpecialKV(Handle plugin, int numParams)
{
	int index = GetNativeCell(1);
	bool isNumOfSpecial = view_as<bool>(GetNativeCell(2));
	if(isNumOfSpecial)
	{
		if(index!=-1 && index<FF2CharSetInfo.SizeOfSpecials)
		{
			if(FF2CharSetInfo.BossKV[index] != INVALID_HANDLE)
				KvRewind(FF2CharSetInfo.BossKV[index]);

			return view_as<int>(FF2CharSetInfo.BossKV[index]);
		}
	}
	else
	{
		if(index!=-1 && index<=MaxClients && FF2BossInfo[index].Special!=-1 && FF2BossInfo[index].Special<MAXSPECIALS)
		{
			if(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special] != INVALID_HANDLE)
				KvRewind(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special]);

			return view_as<int>(FF2CharSetInfo.BossKV[FF2BossInfo[index].Special]);
		}
	}
	return view_as<int>(INVALID_HANDLE);
}

int Native_StartMusic(Handle plugin, int numParams)
{
	StartMusic(GetNativeCell(1));
}

int Native_StopMusic(Handle plugin, int numParams)
{
	StopMusic(GetNativeCell(1));
}

int Native_RandomSound(Handle plugin, int numParams)
{
	int length = GetNativeCell(3)+1;
	int boss = GetNativeCell(4);
	int slot = GetNativeCell(5);
	char[] sound = new char[length];
	int kvLength;

	GetNativeStringLength(1, kvLength);
	kvLength++;

	char[] keyvalue = new char[kvLength];
	GetNativeString(1, keyvalue, kvLength);

	bool soundExists;
	if(!StrContains(keyvalue, "sound_ability", false))
	{
		soundExists = RandomSoundAbility(keyvalue, sound, length, boss, slot);
	}
	else
	{
		soundExists = RandomSound(keyvalue, sound, length, boss);
	}
	SetNativeString(2, sound, length);
	return soundExists;
}

int Native_EmitVoiceToAll(Handle plugin, int numParams)
{
	int kvLength;
	GetNativeStringLength(1, kvLength);
	kvLength++;
	char[] keyvalue = new char[kvLength];
	GetNativeString(1, keyvalue, kvLength);

	float origin[3], dir[3];
	GetNativeArray(9, origin, 3);
	GetNativeArray(10, dir, 3);

	EmitSoundToAllExcept(keyvalue, GetNativeCell(2), GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), GetNativeCell(6), GetNativeCell(7), GetNativeCell(8), origin, dir, GetNativeCell(11), GetNativeCell(12));
}

int Native_GetClientGlow(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(Utils_IsValidClient(client))
	{
		return view_as<int>(FF2PlayerInfo[client].GlowTimer);
	}
	else
	{
		return view_as<int>(-1.0);
	}
}

int Native_SetClientGlow(Handle plugin, int numParams)
{
	Utils_SetClientGlow(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

int Native_GetClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(Utils_IsValidClient(client) && FF2PlayerInfo[client].HasShield)
	{
		if(FF2PlayerInfo[client].EntShield)
		{
			if(ConVars.ShieldType.IntValue > 2)
			{
				return RoundToFloor(FF2PlayerInfo[client].ShieldHP/ConVars.ShieldHealth.FloatValue*100.0);
			}
			else
			{
				return 100;
			}
		}
		return 0;
	}
	return -1;
}

int Native_SetClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(Utils_IsValidClient(client))
	{
		if(GetNativeCell(2) > 0)
			FF2PlayerInfo[client].EntShield = GetNativeCell(2);

		if(GetNativeCell(3) >= 0)
			FF2PlayerInfo[client].ShieldHP = GetNativeCell(3)*ConVars.ShieldHealth.FloatValue/100.0;

		if(GetNativeCell(4) > 0)
		{
			FF2PlayerInfo[client].ShieldDmgReduction = (1.0-GetNativeCell(4));
		}
		else if(GetNativeCell(3) > 0)
		{
			FF2PlayerInfo[client].ShieldDmgReduction = FF2PlayerInfo[client].ShieldHP/ConVars.ShieldHealth.FloatValue*(1.0-ConVars.ShieldResist.FloatValue);
		}
	}
}

int Native_RemoveClientShield(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(Utils_IsValidClient(client))
	{
		TF2_RemoveWearable(client, FF2PlayerInfo[client].EntShield);
		FF2PlayerInfo[client].ShieldHP = 0.0;
		FF2PlayerInfo[client].EntShield = 0;
	}
}

int Native_LogError(Handle plugin, int numParams)
{
	char buffer[256];
	int error = FormatNativeString(0, 1, 2, sizeof(buffer), _, buffer);
	if(error != SP_ERROR_NONE)
	{
		ThrowNativeError(error, "Failed to format");
		return;
	}
	LogToFile(FF2LogsPaths.Errors, buffer);
}

int Native_Debug(Handle plugin, int numParams)
{
	return ConVars.Debug.BoolValue;
}

int Native_SetCheats(Handle plugin, int numParams)
{
	FF2Globals.CheatsUsed = GetNativeCell(1);
}

int Native_GetCheats(Handle plugin, int numParams)
{
	return (FF2Globals.CheatsUsed || FF2Globals.IsSpecialRound);
}

int Native_MakeBoss(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(!Utils_IsValidClient(client))
		return;

	int boss = GetNativeCell(2);
	if(boss == -1)
	{
		boss = Utils_GetBossIndex(client);
		if(boss < 0)
			return;

		FF2BossInfo[boss].Boss = 0;
		FF2BossInfo[boss].HasSwitched = false;
		CreateTimer(0.1, Timer_MakeNotBoss, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	int special = GetNativeCell(3);
	if(special >= 0)
		FF2BossInfo[boss].Incoming = special;

	FF2BossInfo[boss].Boss = client;
	FF2BossInfo[boss].HasEquipped = false;
	FF2BossInfo[boss].HasSwitched = GetNativeCell(4);
	PickCharacter(boss, boss);
	CreateTimer(0.1, Timer_MakeBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
}

int Native_ChooseBoss(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client<1 || client>=MAXTF2PLAYERS)
	{
		GetNativeString(2, xIncoming[0], sizeof(xIncoming[]));
		return Utils_CheckValidBoss(0, xIncoming[0]);
	}

	GetNativeString(2, xIncoming[client], sizeof(xIncoming[]));
	IgnoreValid[client] = GetNativeCell(3);
	return Utils_CheckValidBoss(client, xIncoming[client]);
}

// int Native_IsVSHMap(Handle plugin, int numParams)
// {
// 	return false;
// }

int Native_ReportError(Handle plugin, int params)
{
	int boss = GetNativeCell(1);
	char name[48] = "Unknown";
	if(boss >= 0 && FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special])
	{
		FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special].Rewind();
		FF2CharSetInfo.BossKV[FF2BossInfo[boss].Special].GetString("name", name, sizeof(name), "Unknown");
	}
	
	LogToFile(FF2LogsPaths.Errors, "[FF2] Exception reported: Boss: %i - Name: %s", boss, name);
	char actual[PLATFORM_MAX_PATH];
	
	int error;
	if((error = FormatNativeString(0, 2, 3, sizeof(actual), .out_string=actual)) != SP_ERROR_NONE)
	{
		return ThrowNativeError(error, "Failed to format");
	}
	Format(actual, sizeof(actual), "[FF2] %s", actual);
	LogToFile(FF2LogsPaths.Errors, actual);
	
	return 1;
}

any FF2Data_Unknown(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	if(!IsClientInGame(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client: %i is not ingame", client);
	}
	
	return FF2Data.Unknown(client);
}

any FF2Data_FF2Data(Handle plugin, int params)
{
	int boss = GetNativeCell(1);
	if(boss < 0 || boss > 12) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid boss index: %i", boss);
	}
	
	char plugin_name[64]; GetNativeString(2, plugin_name, sizeof(plugin_name));
	ReplaceString(plugin_name, sizeof(plugin_name), ".smx", "");
	char ability_name[64]; GetNativeString(3, ability_name, sizeof(ability_name));
	
	FF2Data data = FF2Data(boss, plugin_name, ability_name);
	return data;
}

int FF2Data_boss(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	return data.boss;
}

int FF2Data_client(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	return data.client;
}

any FF2Data_GetConfig(Handle plugin, int params)
{
	FF2Data boss = GetNativeCell(1);
	if(boss.Invalid)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid boss index: %i", boss);
	
	return FF2CharSetInfo.BossKV[boss.boss];
}

any FF2Data_Change(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	if(data.Invalid)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid boss index: %i", data.boss);
	
	char plugin_name[64]; GetNativeString(2, plugin_name, sizeof(plugin_name));
	ReplaceString(plugin_name, sizeof(plugin_name), ".smx", "");
	char ability_name[64]; GetNativeString(3, ability_name, sizeof(ability_name));
	
	data.Change(plugin_name, ability_name);
	return 1;
}

any FF2Data_GetArgI(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	char arg[32]; GetNativeString(2, arg, sizeof(arg));
	return data.GetArgI(arg, GetNativeCell(3), GetNativeCell(4));
}

any FF2Data_GetArgF(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	char arg[32]; GetNativeString(2, arg, sizeof(arg));
	return data.GetArgF(arg, GetNativeCell(3));
}

any FF2Data_GetArgB(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	char arg[32]; GetNativeString(2, arg, sizeof(arg));
	return data.GetArgB(arg, GetNativeCell(3));
}

any FF2Data_GetArgS(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	char arg[32]; GetNativeString(2, arg, sizeof(arg));
	
	int len = GetNativeCell(4);
	char[] res = new char[len];
	int bytes = data.GetArgS(arg, res, len);
	SetNativeString(3, res, len);

	return bytes;
}

any FF2Data_HasAbility(Handle plugin, int params)
{
	FF2Data data = GetNativeCell(1);
	if (data.Invalid) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid boss index: %i", data.boss);
	}
	
	FF2QueryData cd;
	FF2Cache.Request(data.boss, cd);
	
	return Utils_HasAbilityEx(cd, data.boss, cd.current_plugin_name, cd.current_ability_name);
}