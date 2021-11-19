
Action Timer_HealthBarMode(Handle timer, bool set)
{
	if(set && !FF2Globals.HealthBarMode)
	{
		FF2Globals.HealthBarMode = true;
		UpdateHealthBar();
	}
	else if(!set && FF2Globals.HealthBarMode)
	{
		FF2Globals.HealthBarMode = false;
		UpdateHealthBar();
	}
	return Plugin_Continue;
}

void FindHealthBar()
{
	FF2Globals.HealthBar = Utils_FindEntityByClassname2(-1, HEALTHBAR_CLASS);
	if(!IsValidEntity(FF2Globals.HealthBar))
		FF2Globals.HealthBar = CreateEntityByName(HEALTHBAR_CLASS);
}

public void HealthbarEnableChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(FF2Globals.Enabled && ConVars.HealthBar.IntValue>0 && IsValidEntity(FF2Globals.HealthBar))
	{
		UpdateHealthBar();
	}
	else if(!IsValidEntity(FF2Globals.EntMonoculus) && IsValidEntity(FF2Globals.HealthBar))
	{
		SetEntProp(FF2Globals.HealthBar, Prop_Send, HEALTHBAR_PROPERTY, 0);
	}
}

void UpdateHealthBar()
{
	if(!FF2Globals.Enabled || ConVars.HealthBar.IntValue<1 || IsValidEntity(FF2Globals.EntMonoculus) || !IsValidEntity(FF2Globals.HealthBar) || Utils_CheckRoundState()!=1)
		return;

	int healthAmount, maxHealthAmount, healthPercent;
	int healing = FF2Globals.HealthBarMode ? 1 : 0;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(Utils_IsValidClient(FF2BossInfo[boss].Boss) && IsPlayerAlive(FF2BossInfo[boss].Boss))
		{
			if(FF2Globals.Enabled3)
			{
				if(TF2_GetClientTeam(FF2BossInfo[boss].Boss) == TFTeam_Blue)
				{
					healthAmount += FF2BossInfo[boss].Health;
				}
				else
				{
					maxHealthAmount += FF2BossInfo[boss].Health;
				}
			}
			else
			{
				if(ConVars.HealthBar.IntValue > 1)
				{
					healthAmount += FF2BossInfo[boss].Health;
					maxHealthAmount += FF2BossInfo[boss].HealthMax*FF2BossInfo[boss].LivesMax;
				}
				else
				{
					healthAmount += FF2BossInfo[boss].Health-FF2BossInfo[boss].HealthMax*(FF2BossInfo[boss].Lives-1);
					maxHealthAmount += FF2BossInfo[boss].HealthMax;
				}
			}
			if(FF2BossVar[boss].IsHealthbarIncreasing)
				healing = 1;
		}
	}

	if(maxHealthAmount)
	{
		if(FF2Globals.Enabled3)
		{
			if(maxHealthAmount > healthAmount)
			{
				healthPercent = RoundToCeil(float(healthAmount)/float(maxHealthAmount)*float(HEALTHBAR_MAX)*0.5);
			}
			else
			{
				healthPercent = RoundToCeil((1.0-(float(maxHealthAmount)/float(healthAmount)*0.5))*float(HEALTHBAR_MAX));
			}
		}
		else
		{
			healthPercent = RoundToCeil(float(healthAmount)/float(maxHealthAmount)*float(HEALTHBAR_MAX));
		}

		if(healthPercent > HEALTHBAR_MAX)
		{
			healthPercent = HEALTHBAR_MAX;
		}
		else if(healthPercent < 1)
		{
			healthPercent = 1;
		}
	}
	SetEntProp(FF2Globals.HealthBar, Prop_Send, HEALTHBAR_COLOR, healing);
	SetEntProp(FF2Globals.HealthBar, Prop_Send, HEALTHBAR_PROPERTY, healthPercent);
}