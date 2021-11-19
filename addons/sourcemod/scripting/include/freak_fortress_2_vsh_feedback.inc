void AskPluginLoad_VSH()
{
	CreateNative("VSH_IsSaxtonHaleModeMap", Native_VSHIsVSHMap);
	CreateNative("VSH_IsSaxtonHaleModeEnabled", Native_VSHIsEnabled);
	CreateNative("VSH_GetSaxtonHaleUserId", Native_VSHGetHale);
	CreateNative("VSH_GetSaxtonHaleTeam", Native_VSHGetTeam);
	CreateNative("VSH_GetSpecialRoundIndex", Native_VSHGetSpecial);
	CreateNative("VSH_GetSaxtonHaleHealth", Native_VSHGetHealth);
	CreateNative("VSH_GetSaxtonHaleHealthMax", Native_VSHGetHealthMax);
	CreateNative("VSH_GetClientDamage", Native_VSHGetDamage);
	CreateNative("VSH_GetRoundState", Native_VSHGetRoundState);
	RegPluginLibrary("saxtonhale");
}

int Native_VSHIsVSHMap(Handle plugin, int numParams)
{
	return Utils_IsFF2Map(FF2Globals.CurrentMap);
}

int Native_VSHIsEnabled(Handle plugin, int numParams)
{
	return (FF2Globals.Enabled ? 2 : 0);
}

int Native_VSHGetHale(Handle plugin, int numParams)
{
	return (Utils_IsValidClient(FF2BossInfo[0].Boss) ? GetClientUserId(FF2BossInfo[0].Boss) : -1);
}

int Native_VSHGetTeam(Handle plugin, int numParams)
{
	return FF2Globals.BossTeam;
}

int Native_VSHGetSpecial(Handle plugin, int numParams)
{
	return FF2BossInfo[0].Special;
}

int Native_VSHGetHealth(Handle plugin, int numParams)
{
	return FF2BossInfo[0].Health;
}

int Native_VSHGetHealthMax(Handle plugin, int numParams)
{
	return FF2BossInfo[0].HealthMax;
}

int Native_VSHGetRoundState(Handle plugin, int numParams)
{
	return Utils_CheckRoundState();
}

int Native_VSHGetDamage(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return (Utils_IsValidClient(client) ? FF2PlayerInfo[client].Damage : 0);
}