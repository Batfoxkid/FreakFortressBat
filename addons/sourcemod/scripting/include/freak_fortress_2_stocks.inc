#include <tf2attributes>

Handle SDKEquipWearable = null;

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
	static char message[512];
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
 * Displays a HUD-styled message
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

	static char message[512];
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
 * Changes the worldmodel of a entity
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
 * Creates and gives a wearable to a client
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
	static char netClass[64];
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
 * Setups SDKEquipWearable handle
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
