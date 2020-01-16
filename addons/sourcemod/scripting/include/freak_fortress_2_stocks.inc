#include <sdktools>
#include <tf2_stocks>
#include <tf2attributes>
#include <freak_fortress_2>

#if !defined MAXTF2PLAYERS
	#define MAXTF2PLAYERS 36
#endif

Handle SDKEquipWearable = null;

#if SOURCEMOD_V_MAJOR!=1 || SOURCEMOD_V_MINOR>=10
enum struct FF2Ability
{
	int Boss;
	char Name[64];
	char Plugin[64];

	bool Setup(int boss=0, const char[] plugin, const char[] ability)
	{
		this.Boss = boss;
		strcopy(this.Plugin, 64, plugin);
		strcopy(this.Name, 64, ability);
		return this.Valid();
	}

	bool Valid()
	{
		return FF2_HasAbility(this.Boss, this.Plugin, this.Name);
	}

	float Dist()
	{
		return FF2_GetRageDist(this.Boss, this.Plugin, this.Name);
	}

	float Do(int slot=0, int button=0)
	{
		return FF2_DoAbility(this.Boss, this.Plugin, this.Name, slot, button);
	}

	int ArgInt(const char[] argName="", int argNumber=-1, int defaultValue=0)
	{
		int junk = -321654987;
		int value = junk;
		if(argName[0] && GetFeatureStatus(FeatureType_Native, "FF2_GetArgNamedI")==FeatureStatus_Available)
		{
			value = FF2_GetArgNamedI(this.Boss, this.Plugin, this.Name, argName, junk);
			if(value != junk)
				return value;
		}

		if(argNumber >= 0)
		{
			value = FF2_GetAbilityArgument(this.Boss, this.Plugin, this.Name, argNumber, junk);
			if(value != junk)
				return value;
		}
		return defaultValue;
	}

	float ArgFloat(const char[] argName="", int argNumber=-1, float defaultValue=0.0)
	{
		float junk = -321654987.258;
		float value = junk;
		if(argName[0] && GetFeatureStatus(FeatureType_Native, "FF2_GetArgNamedF")==FeatureStatus_Available)
		{
			value = FF2_GetArgNamedF(this.Boss, this.Plugin, this.Name, argName, junk);
			if(value != junk)
				return value;
		}

		if(argNumber >= 0)
		{
			value = FF2_GetAbilityArgumentFloat(this.Boss, this.Plugin, this.Name, argNumber, junk);
			if(value != junk)
				return value;
		}
		return defaultValue;
	}

	void ArgString(const char[] argName="", int argNumber=-1, char[] buffer, int bufferLength, const char[] defaultValue="")
	{
		buffer[0] = 0;
		if(argName[0] && GetFeatureStatus(FeatureType_Native, "FF2_GetArgNamedS")==FeatureStatus_Available)
		{
			FF2_GetArgNamedS(this.Boss, this.Plugin, this.Name, argName, buffer, bufferLength);
			if(buffer[0])
				return;
		}

		if(argNumber >= 0)
		{
			FF2_GetAbilityArgumentString(this.Boss, this.Plugin, this.Name, argNumber, buffer, bufferLength);
			if(buffer[0])
				return;
		}
		strcopy(buffer, bufferLength, defautValue);
		return strlen(buffer);
	}
};

enum struct FF2Player
{
	int Client;
	int Boss;

	bool Setup(int client)
	{
		this.Client = client;
		if(client<1 || client>MaxClients || !IsClientInGame(client))
		{
			this.Boss = -1;
			return false;
		}
		this.Boss = FF2_GetBossIndex(client);
		return true;
	}

	bool Valid()
	{
		return (this.Client && IsClientInGame(this.Client));
	}

	bool Name(char[] buffer, int bufferLength, int clientLang=0)
	{
		if(this.Boss == -1)
			return GetClientName(this.Client, buffer, bufferLength);

		if(GetFeatureStatus(FeatureType_Native, "FF2_GetBossName") == FeatureStatus_Available)
			return FF2_GetBossName(this.Boss, buffer, bufferLength, 0, clientLang);

		return FF2_GetBossSpecial(this.Boss, buffer, bufferLength, 0);
	}

	int Health(int newValue=0)
	{
		if(this.Boss == -1)
		{
			if(newValue > 0)
			{
				SetEntityHealth(this.Client, newValue);
				return newValue;
			}

			return GetClientHealth(this.Client);
		}

		if(newValue > 0)
		{
			FF2_SetBossHealth(this.Boss, newValue+(FF2_GetBossLives(this.Boss)*FF2_GetBossMaxHealth(this.Boss));
			return newValue;
		}

		return FF2_GetBossHealth(this.Boss)/FF2_GetBossLives(this.Boss);
	}

	int MaxHealth(int newValue=0)
	{
		if(this.Boss == -1)
		{
			if(newValue > 0)
			{
				SetEntProp(this.Client, Prop_Data, "m_iMaxHealth", newValue);
				return newValue;
			}

			return GetEntProp(this.Client, Prop_Data, "m_iMaxHealth");
		}

		if(newValue > 0)
		{
			FF2_SetBossMaxHealth(this.Boss, newValue);
			return newValue;
		}

		return FF2_GetBossMaxHealth(this.Boss);
	}

	int Lives(int newValue=0)
	{
		if(this.Boss == -1)
			return 1;

		if(newValue > 0)
		{
			FF2_SetBossLives(this.Boss, newValue);
			return newValue;
		}

		return FF2_GetBossLives(this.Boss);
	}

	int MaxLives(int newValue=0)
	{
		if(this.Boss == -1)
			return 1;

		if(newValue > 0)
		{
			FF2_SetBossMaxLives(this.Boss, newValue);
			return newValue;
		}

		return FF2_GetBossMaxLives(this.Boss);
	}

	float Rage(float newValue=-1.0)
	{
		return this.Charge(0, newValue);
	}

	int Damage(int newValue=-1)
	{
		if(this.Boss == -1)
			return FF2_GetClientDamage(this.Client);

		if(newValue >= 0)
		{
			FF2_SetBossRageDamage(this.Boss, newValue);
			return newValue;
		}

		return FF2_GetBossRageDamage(this.Boss);
	}

	float Charge(int slot=1, float newValue=-1.0)
	{
		if(slot<0 || slot>3)
			return 0.0;

		if(this.Boss == -1)
		{
			switch(slot)
			{
				case 1:
				{
					if(newValue >= 0)
					{
						SetEntPropFloat(this.Client, Prop_Send, "m_flEnergyDrinkMeter", newValue);
						return newValue;
					}

					return GetEntPropFloat(this.Client, Prop_Send, "m_flEnergyDrinkMeter");
				}
				case 2:
				{
					if(newValue >= 0)
					{
						SetEntPropFloat(this.Client, Prop_Send, "m_flHypeMeter", newValue);
						return newValue;
					}

					return GetEntPropFloat(this.Client, Prop_Send, "m_flHypeMeter");
				}
				case 3:
				{
					if(newValue >= 0)
					{
						SetEntPropFloat(this.Client, Prop_Send, "m_flChargeMeter", newValue);
						return newValue;
					}

					return GetEntPropFloat(this.Client, Prop_Send, "m_flChargeMeter");
				}
				default:
				{
					if(newValue >= 0)
					{
						SetEntPropFloat(this.Client, Prop_Send, "m_flRageMeter", newValue);
						return newValue;
					}

					return GetEntPropFloat(this.Client, Prop_Send, "m_flRageMeter");
				}
			}
		}

		if(newValue >= 0)
		{
			FF2_SetBossCharge(this.Boss, slot, newValue);
			return newValue;
		}

		return FF2_GetBossCharge(this.Boss, slot);
	}

	float Dist()
	{
		if(this.Boss == -1)
			return 0.0;

		return FF2_GetRageDist(this.Boss);
	}

	bool Sound(const char[] keyvalue, char[] buffer, int bufferLength, int slot=0)
	{
		if(this.Boss == -1)
			return false;

		return FF2_RandomSound(keyvalue, buffer, bufferLength, this.Boss, slot);
	}

	void Music(bool toggle=true)
	{
		if(toggle)
		{
			FF2_StartMusic(this.Client);
			return;
		}
		FF2_StopMusic(this.Client);
	}

	Handle Kv()
	{
		if(this.Boss == -1)
			return INVALID_HANDLE;

		return FF2_GetSpecialKV(this.Boss, 0);
	}

	int Flags(int newValue=-1)
	{
		if(newValue >= 0)
		{
			FF2_SetFF2flags(this.Client, newValue);
			return newValue;
		}

		return FF2_GetFF2flags(this.Client);
	}

	int Queue(int newValue=-321654987)
	{
		if(newValue != -321654987)
		{
			FF2_SetQueuePoints(this.Client, newValue);
			return newValue;
		}

		return FF2_GetQueuePoints(this.Client);
	}

	float Glow(float newValue=-321654987.258, bool override=false)
	{
		if(newValue != -321654987.258)
			return FF2_GetClientGlow(this.Client);

		if(override)
		{
			FF2_SetClientGlow(this.Client, newValue, newValue);
			return newValue;
		}

		FF2_SetClientGlow(this.Client, newValue, -1.0);
		return newValue;
	}

	float Shield(float newValue=-1.0, int entity=0, float reduction=-1.0)
	{
		if(!newValue && !entity)
		{
			FF2_RemoveClientShield(this.Client);
			return newValue;
		}

		if(newValue>=0 || entity || reduction>=0)
		{
			FF2_SetClientShield(this.Client, entity, newValue, reduction);
			return newValue;
		}

		return FF2_GetClientShield(this.Client);
	}
};
#endif

/**
 * Created an Annotation message attached to an entity.
 *
 * @param client	The client that can see the message
 * @param entity	The entity that the Annotation is attached to
 * @param effect
 * @param time		Annotation lifetime
 * @param buffer	Message string to display
 * @param ...		Formatting rules
 *
 * @return		Entity index of Annotation, -1 on failure.
 */
stock int CreateAttachedAnnotation(int client, int entity, bool effect=true, float time, const char[] buffer, any ...)
{
	char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 6);
	ReplaceString(message, sizeof(message), "\n", "");  //Get rid of newlines

	Handle event = CreateEvent("show_annotation");
	if(event == INVALID_HANDLE)
		return -1;

	SetEventInt(event, "follow_entindex", entity);
	SetEventFloat(event, "lifetime", time);
	SetEventInt(event, "visibilityBitfield", (1<<client));
	SetEventBool(event, "show_effect", effect);
	SetEventString(event, "text", message);
	SetEventString(event, "play_sound", "vo/null.wav");
	SetEventInt(event, "id", entity); //What to enter inside? Need a way to identify annotations by entindex!
	FireEvent(event);
	return entity;
}

/**
 * Displays a HUD-styled message.
 *
 * @param client	The client that sees the message (0 for all players)
 * @param icon		Icon that the message displays
 * @param color		Team color of the message
 * @param buffer	Message string to display
 * @param ...		Formatting rules
 *
 * @return		True on success, false on failure.
 */
stock bool ShowGameText(int client=0, const char[] icon="leaderboard_streak", int color=0, const char[] buffer, any ...)
{
	Handle bf;
	if(!client)
	{
		bf = StartMessageAll("HudNotifyCustom");
	}
	else
	{
		bf = StartMessageOne("HudNotifyCustom", client);
	}

	if(bf == null)
		return false;

	char message[512];
	SetGlobalTransTarget(client);
	VFormat(message, sizeof(message), buffer, 5);
	ReplaceString(message, sizeof(message), "\n", "");

	BfWriteString(bf, message);
	BfWriteString(bf, icon);
	BfWriteByte(bf, color);
	EndMessage();
	return true;
}

/**
 * Changes the worldmodel of a entity.
 *
 * @param entity	Entity index
 * @param model		Model filepath
 * @param wearable	Is the entity an wearable
 *
 * @return		True on success, false on failure.
 */
stock bool ConfigureWorldModelOverride(int entity, const char[] model, bool wearable=false)
{
	if(!FileExists(model, true))
		return false;

	int modelIndex = PrecacheModel(model);
	SetEntProp(entity, Prop_Send, "m_nModelIndex", modelIndex);
	for(int i=1; i<4; i++)
	{
		SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", modelIndex, _, i);
	}
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", (wearable ? GetEntProp(entity, Prop_Send, "m_nModelIndex") : GetEntProp(entity, Prop_Send, "m_iWorldModelIndex")), _, 0);
	return true;
}

/**
 * Creates and gives a wearable to a client.
 *
 * @param client	Client index
 * @param classname	Classname of wearable
 * @param index		Wearable index
 * @param level		Wearable level
 * @param quality	Wearable quality
 * @param attributes	Wearable attributes
 *
 * @return		Entity index of wearable, -1 on failure.
 */
stock int TF2_CreateAndEquipWearable(int client, const char[] classname="tf_wearable", int index=0, int level=0, int quality=6, const char[] attributes="")
{
	if(!SetupWearableSDK())
		return -1;

	int wearable = CreateEntityByName(classname);
	if(!IsValidEntity(wearable))
		return -1;

	SetEntProp(wearable, Prop_Send, "m_iItemDefinitionIndex", index);
	SetEntProp(wearable, Prop_Send, "m_bInitialized", 1);
		
	// Allow quality / level override by updating through the offset.
	char netClass[64];
	GetEntityNetClass(wearable, netClass, sizeof(netClass));
	SetEntData(wearable, FindSendPropInfo(netClass, "m_iEntityQuality"), quality);
	SetEntData(wearable, FindSendPropInfo(netClass, "m_iEntityLevel"), level);

	SetEntProp(wearable, Prop_Send, "m_iEntityQuality", quality);
	SetEntProp(wearable, Prop_Send, "m_iEntityLevel", level);

	if(attributes[0])
	{
		char atts[32][32];
		int count = ExplodeString(attributes, " ; ", atts, 32, 32);
		if(count > 1)
		{
			for(int i; i<count; i+=2)
			{
				TF2Attrib_SetByDefIndex(wearable, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			}
		}
	}
		
	DispatchSpawn(wearable);
	SDKCall(SDKEquipWearable, client, wearable);
	return wearable;
}

/**
 * Setups SDKEquipWearable handle.
 *
 * @return		True on success or already setup, false on failure.
 */
stock bool SetupWearableSDK()
{
	if(SDKEquipWearable != null)
		return true;

	Handle gameData = LoadGameConfigFile("equipwearable");
	if(gameData == null)
	{
		LogError("Failed to find equipwearable.txt");
		return false;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(SDKEquipWearable == null)
	{
		LogError("Failed to create call: CBasePlayer::EquipWearable");
		return false;
	}
	return true;
}

/**
 * Checks if the map has it's own music playing.
 *
 * @return		True if the map has music, false otherwise.
 */
stock bool MapHasMusic()
{
	int entity = -1;
	char name[64];
	while((entity=FindEntityByClassname2(entity, "info_target")) != -1)
	{
		GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
		if(StrEqual(name, "hale_no_music", false))
			return true;
	
	}
	return false;
}

/**
 * Gets the closest player to an entity.
 *
 * @param entity	Entity index
 * @param team		If to filter a specific team
 *
 * @return		Client index of nearest player
 */
stock int GetClosestPlayerTo(int entity, TFTeam team=TFTeam_Unassigned)
{
	int best;
	float dist, temp, loc[3], pos[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", loc);
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && entity!=client)
		{
			if(team>TFTeam_Unassigned && TF2_GetClientTeam(client)!=team)
				continue;

			GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
			temp = GetVectorDistance(loc, pos);
			if(!best || temp<dist)
			{
				dist = temp;
				best = client;
			}
		}
	}
	return best;
}

/**
 * Teleports an entity to another entity.
 *
 * @param entity	Entity index to teleport
 * @param target	Entity index to teleport to
 * @param angles	If to rotate the entity
 *
 * @return		True if a client was forced to duck
 */
stock bool TeleMeToYou(int entity, int target, bool angles=false)
{
	float pos[3], ang[3];
	GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos);
	if(angles)
	{
		GetEntPropVector(target, Prop_Send, "m_angRotation", ang);
	}
	else
	{
		ang = NULL_VECTOR;
	}

	bool ducked = false;
	if(IsValidClient(entity) && IsValidClient(target) && GetEntProp(target, Prop_Send, "m_bDucked"))
	{
		float vec[3];
		vec[0] = 24.0;
		vec[1] = 24.0;
		vec[2] = 62.0;
		SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vec);
		SetEntProp(entity, Prop_Send, "m_bDucked", 1);
		SetEntityFlags(entity, GetEntityFlags(entity)|FL_DUCKING);
		ducked = true;
	}
	TeleportEntity(entity, pos, ang, NULL_VECTOR);
	return ducked;
}

#file "FF2 Include: Stocks"
