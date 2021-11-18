
Action Timer_HealthBarMode(Handle timer, bool set)
{
	if(set && !HealthBarMode)
	{
		HealthBarMode = true;
		UpdateHealthBar();
	}
	else if(!set && HealthBarMode)
	{
		HealthBarMode = false;
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
	int healing = HealthBarMode ? 1 : 0;
	for(int boss; boss<=MaxClients; boss++)
	{
		if(Utils_IsValidClient(Boss[boss]) && IsPlayerAlive(Boss[boss]))
		{
			if(FF2Globals.Enabled3)
			{
				if(TF2_GetClientTeam(Boss[boss]) == TFTeam_Blue)
				{
					healthAmount += BossHealth[boss];
				}
				else
				{
					maxHealthAmount += BossHealth[boss];
				}
			}
			else
			{
				if(ConVars.HealthBar.IntValue > 1)
				{
					healthAmount += BossHealth[boss];
					maxHealthAmount += BossHealthMax[boss]*BossLivesMax[boss];
				}
				else
				{
					healthAmount += BossHealth[boss]-BossHealthMax[boss]*(BossLives[boss]-1);
					maxHealthAmount += BossHealthMax[boss];
				}
			}
			if(HealthBarModeC[boss])
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