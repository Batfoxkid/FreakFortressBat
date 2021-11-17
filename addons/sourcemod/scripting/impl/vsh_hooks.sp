
public Action VSH_OnIsSaxtonHaleModeEnabled(int &result)
{
	if((!result || result==1) && Enabled)
	{
		result = 2;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleTeam(int &result)
{
	if(Enabled)
	{
		result = BossTeam;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleUserId(int &result)
{
	if(Enabled && IsClientConnected(Boss[0]))
	{
		result = GetClientUserId(Boss[0]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSpecialRoundIndex(int &result)
{
	if(Enabled)
	{
		result = Special[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleHealth(int &result)
{
	if(Enabled)
	{
		result = BossHealth[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetSaxtonHaleHealthMax(int &result)
{
	if(Enabled)
	{
		result = BossHealthMax[0];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetClientDamage(int client, int &result)
{
	if(Enabled)
	{
		result = Damage[client];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action VSH_OnGetRoundState(int &result)
{
	if(Enabled)
	{
		result = Utils_CheckRoundState();
		return Plugin_Changed;
	}
	return Plugin_Continue;
}