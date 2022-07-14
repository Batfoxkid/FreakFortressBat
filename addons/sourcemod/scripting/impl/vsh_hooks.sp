
public Action VSH_OnIsSaxtonHaleModeEnabled(int &result)
{
	if((!result || result==1) && FF2Globals.Enabled)
	{
		result = 2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleTeam(int &result)
{
	if(FF2Globals.Enabled)
	{
		result = FF2Globals.BossTeam;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleUserId(int &result)
{
	if(FF2Globals.Enabled && IsClientConnected(FF2BossInfo[0].Boss))
	{
		result = GetClientUserId(FF2BossInfo[0].Boss);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSpecialRoundIndex(int &result)
{
	if(FF2Globals.Enabled)
	{
		result = FF2BossInfo[0].Special;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleHealth(int &result)
{
	if(FF2Globals.Enabled)
	{
		result = FF2BossInfo[0].Health;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleHealthMax(int &result)
{
	if(FF2Globals.Enabled)
	{
		result = FF2BossInfo[0].HealthMax;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetClientDamage(int client, int &result)
{
	if(FF2Globals.Enabled)
	{
		result = FF2PlayerInfo[client].Damage;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetRoundState(int &result)
{
	if(FF2Globals.Enabled)
	{
		result = Utils_CheckRoundState();
		return Plugin_Changed;
	}
	return Plugin_Continue;
}