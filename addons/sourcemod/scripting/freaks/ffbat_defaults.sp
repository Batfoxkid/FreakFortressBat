/*
	Default Abilities Pack:

	model_projectile_replace
	rage_cbs_bowrage
	rage_cloneattack
	rage_explosive_dance
	rage_instant_teleport
	rage_tradespam
	rage_matrix_attack
	rage_new_weapon
	rage_overlay
	rage_stun
	rage_stunsg
	rage_uber
	spawn_many_objects_on_death
	spawn_many_objects_on_kill
	special_cbs_multimelee
	special_democharge
	special_dissolve
	special_dropprop
	special_noanims
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#undef REQUIRE_PLUGIN
//#if SOURCEMOD_V_MAJOR==1 && SOURCEMOD_V_MINOR<=9
#tryinclude <smac>
//#endif
//#tryinclude <freak_fortress_2_kstreak>
#define REQUIRE_PLUGIN

#pragma newdecls required

#file "FF2 Unofficial Subplugin: Defaults"

#define MAJOR_REVISION	"0"
#define MINOR_REVISION	"3"
#define STABLE_REVISION	"0"
#define PLUGIN_VERSION MAJOR_REVISION..."."...MINOR_REVISION..."."...STABLE_REVISION

#define PROJECTILE	"model_projectile_replace"
#define OBJECTS		"spawn_many_objects_on_kill"
#define OBJECTS_DEATH	"spawn_many_objects_on_death"

#define SPOOK "yikes_fx"

#define CBS_MAX_ARROWS 9

#define SOUND_SLOW_MO_START	"replay/enterperformancemode.wav"	//Used when Ninja Spy enters slow mo
#define SOUND_SLOW_MO_END	"replay/exitperformancemode.wav"	//Used when Ninja Spy exits slow mo
#define SOUND_DEMOPAN_RAGE	"ui/notification_alert.wav"		//Used when Demopan rages

#define FLAG_ONSLOWMO		(1<<0)
#define FLAG_SLOWMOREADYCHANGE	(1<<1)

enum Operators
{
	Operator_None=0,
	Operator_Add,
	Operator_Subtract,
	Operator_Multiply,
	Operator_Divide,
	Operator_Exponent,
};

//	ConVars
ConVar cvarBaseJumperStun;
ConVar cvarSoloShame;
ConVar cvarTimeScale;
ConVar cvarCheats;

//	Global
Handle OnHaleRage=INVALID_HANDLE;
int BossTeam=view_as<int>(TFTeam_Blue);
int FF2Flags[MAXPLAYERS+1];

//	Clone Attack
int CloneOwnerIndex[MAXPLAYERS+1]=-1;

//	Instant Teleport
float Tslowdown;
float Tstun;
int TflagOverride;

//	Matrix Attack
Handle SlowMoTimer;
int oldTarget;
#if defined _smac_included
bool HasSlowdown[MAXPLAYERS+1]=false;
#else
bool smac=false;
bool HasSlowdown=false;
#endif

//	Stun Rage
bool Outdated=false;

//	Uber Rage
float UberRageCount[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	OnHaleRage=CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);
	return APLRes_Success;
}

public Plugin myinfo=
{
	name		=	"Unofficial Freak Fortress 2: Defaults",
	author		=	"Many many people",
	description	=	"FF2: Combined subplugin of default abilties",
	version		=	PLUGIN_VERSION
};

public void OnPluginStart2()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0]!=1 || (version[1]<10 || (version[1]==10 && version[2]<3)))
	{
		SetFailState("This subplugin depends on at least FF2 v1.10.3");
	}
	int fversion[3];
	FF2_GetForkVersion(fversion);
	if(fversion[0]==1 && fversion[1]<18)
	{
		PrintToServer("[FF2] Warning: This subplugin depends on at least Unofficial FF2 v1.18.0");
		PrintToServer("[FF2] Warning: \"rage_stun\" args 10 and up are disabled");
		Outdated=true;
	}

	HookEvent("object_deflected", OnDeflect, EventHookMode_Pre);
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);
	HookEvent("player_death", OnPlayerDeath);

	cvarTimeScale=FindConVar("host_timescale");
	cvarCheats=FindConVar("sv_cheats");

	PrecacheSound("items/pumpkin_pickup.wav");

	if(Outdated)
		LoadTranslations("ff2_1st_set.phrases");
	else
		LoadTranslations("freak_fortress_2.phrases");
}

public void OnMapStart()
{
	PrecacheSound(SOUND_SLOW_MO_START, true);
	PrecacheSound(SOUND_SLOW_MO_END, true);
	PrecacheSound(SOUND_DEMOPAN_RAGE, true);
}

public void OnAllPluginsLoaded()
{
	cvarBaseJumperStun=FindConVar("ff2_base_jumper_stun");
	if(!Outdated)
		cvarSoloShame=FindConVar("ff2_solo_shame");
}

#if !defined _smac_included
public void OnLibraryAdded(const char[] name)
{
	if(!strcmp(name, "smac", false))
	{
		smac=true;
		Debug("Smac added");
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(!strcmp(name, "smac", false))
	{
		smac=false;
		Debug("Smac removed");
	}
}
#endif

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	int slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0);
	if(!slot)  //Rage
	{
		if(!boss)
		{
			Action action=Plugin_Continue;
			Call_StartForward(OnHaleRage);
			float distance=FF2_GetRageDist(boss, this_plugin_name, ability_name);
			float newDistance=distance;
			Call_PushFloatRef(newDistance);
			Call_Finish(action);
			if(action!=Plugin_Continue && action!=Plugin_Changed)
			{
				return Plugin_Continue;
			}
			else if(action==Plugin_Changed)
			{
				distance=newDistance;
			}
		}
	}
    /*
       Rages
    */
	if(!strcmp(ability_name, "rage_new_weapon"))
	{
		Rage_New_Weapon(boss, ability_name);
	}
	else if(!strcmp(ability_name, "rage_overlay"))
	{
		Rage_Overlay(boss, ability_name);
	}
	else if(!strcmp(ability_name, "rage_uber"))
	{
		TF2_AddCondition(client, TFCond_Ubercharged, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 5.0));
		SetEntProp(client, Prop_Data, "m_takedamage", 0);
		CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 5.0), Timer_StopUber, boss, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(!strcmp(ability_name, "rage_stun"))
	{
		CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 10, 0.0), Timer_Rage_Stun, boss);
	}
	else if(!strcmp(ability_name, "rage_stunsg"))
	{
		Rage_StunBuilding(ability_name, boss);
	}
	else if(!strcmp(ability_name, "rage_instant_teleport"))
	{
		float position[3];
		bool otherTeamIsAlive;
	// Stun Duration
		Tstun=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 2.0);
	// Friendly Teleport
		//bool friendly=view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 2, 1));
	// Stun Flags
		char flagOverrideStr[12];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 3, flagOverrideStr, sizeof(flagOverrideStr));
		TflagOverride = ReadHexOrDecInt(flagOverrideStr);
		if(TflagOverride==0)
			TflagOverride=TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT;
	// Slowdown
		Tslowdown=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 4, 0.0);
	// Sound To Client
		bool sounds=view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 5, 1));
	// Particle Effect
		char particleEffect[48];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 6, particleEffect, sizeof(particleEffect));

		for(int target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target) && target!=client && !(FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM))
			{
				otherTeamIsAlive=true;
				break;
			}
		}

		if(!otherTeamIsAlive)
		{
			return Plugin_Continue;
		}

		int target, tries;
		do
		{
			tries++;
			target=GetRandomInt(1, MaxClients);
			if(tries==100)
			{
				return Plugin_Continue;
			}
		}
		while(!IsValidEntity(target) || target==client || (FF2_GetFF2flags(target) & FF2FLAG_ALLOWSPAWNINBOSSTEAM) || !IsPlayerAlive(target));

		if(strlen(particleEffect)>0)
		{
			CreateTimer(3.0, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(client, particleEffect)), TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(3.0, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(client, particleEffect, _, false)), TIMER_FLAG_NO_MAPCHANGE);
		}

		if(IsValidEntity(target))
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", position);
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 2.0);
			if(GetEntProp(target, Prop_Send, "m_bDucked"))
			{
				float temp[3]={24.0, 24.0, 62.0};  //Compiler won't accept directly putting it into SEPV -.-
				SetEntPropVector(client, Prop_Send, "m_vecMaxs", temp);
				SetEntProp(client, Prop_Send, "m_bDucked", 1);
				SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
				CreateTimer(0.2, Timer_StunBoss, boss, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
				if(sounds)
					TF2_StunPlayer(client, Tstun, Tslowdown, TflagOverride, target);
				else
					TF2_StunPlayer(client, Tstun, Tslowdown, TflagOverride, 0);
			}
			TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
		}
	}
	else if(!strcmp(ability_name, "rage_cloneattack"))
	{
		Rage_Clone(ability_name, boss);
	}
	else if(!strcmp(ability_name, "rage_tradespam"))
	{
		CreateTimer(0.0, Timer_Demopan_Rage, 1, TIMER_FLAG_NO_MAPCHANGE);
	}
	else if(!strcmp(ability_name, "rage_cbs_bowrage"))
	{
		Rage_Bow(boss);
	}
	else if(!strcmp(ability_name, "rage_explosive_dance"))
	{
		SetEntityMoveType(GetClientOfUserId(FF2_GetBossUserId(boss)), MOVETYPE_NONE);
		Handle data;
		CreateDataTimer(0.15, Timer_Prepare_Explosion_Rage, data);
		WritePackString(data, ability_name);
		WritePackCell(data, boss);
		ResetPack(data);
	}
	else if(!strcmp(ability_name, "rage_matrix_attack"))
	{
		Rage_Slowmo(boss, ability_name);
	}
    /*
       Specials
    */
	else if(!strcmp(ability_name, "special_democharge"))
	{
		if(status>0)
		{
			float charge=FF2_GetBossCharge(boss, 0);
			SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", 100.0);
			TF2_AddCondition(client, TFCond_Charging, 0.25);
			if(charge>10.0 && charge<90.0)
			{
				FF2_SetBossCharge(boss, 0, charge-0.4);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	int boss;
	for(int client; client<MaxClients; client++)
	{
		UberRageCount[client]=0.0;
		FF2Flags[client]=0;
		CloneOwnerIndex[client]=-1;
		#if defined _smac_included
		if(!HasSlowdown[client])
		#else
		if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE && !HasSlowdown)
		#endif
		{
			boss=FF2_GetBossIndex(client);
			if(boss>=0)
			{
				if(FF2_HasAbility(boss, this_plugin_name, "rage_matrix_attack"))
				{
					#if defined _smac_included
					HasSlowdown[client]=true;
					#else
					HasSlowdown=true;
					ServerCommand("smac_removecvar sv_cheats");
					ServerCommand("smac_removecvar host_timescale");
					#endif
				}
			}
		}
	}

	CreateTimer(0.30, Timer_GetBossTeam, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.41, Timer_Disable_Anims, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(9.31, Timer_Disable_Anims, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action Timer_GetBossTeam(Handle timer)
{
	BossTeam=FF2_GetBossTeam();
	return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(FF2Flags[client] & FLAG_ONSLOWMO)
		{
			if(SlowMoTimer)
			{
				KillTimer(SlowMoTimer);
			}
			Timer_StopSlowMo(INVALID_HANDLE, -1);
			return Plugin_Continue;
		}

		if(IsClientInGame(client) && CloneOwnerIndex[client]!=-1)  //FIXME: IsClientInGame() shouldn't be needed
		{
			CloneOwnerIndex[client]=-1;
			FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);
		}

		#if defined _smac_included
		if(HasSlowdown[client])
			HasSlowdown[client]=false;
		#else
		if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE && HasSlowdown)
		{
			HasSlowdown=false;
			ServerCommand("smac_addcvar sv_cheats replicated ban 0 0");
			ServerCommand("smac_addcvar host_timescale replicated ban 1.0 1.0");
		}
		#endif
	}
	return Plugin_Continue;
}

#if defined _smac_included
public Action SMAC_OnCheatDetected(int client, const char[] module, DetectionType type, Handle info)
{
	Debug("SMAC: Cheat detected!");
	if(type==Detection_CvarViolation)
	{
		Debug("SMAC: Cheat was a cvar violation!");
		char cvar[PLATFORM_MAX_PATH];
		KvGetString(info, "cvar", cvar, sizeof(cvar));
		Debug("Cvar was %s", cvar);
		if(StrEqual(cvar, "sv_cheats") || StrEqual(cvar, "host_timescale"))
		{
			if(HasSlowdown[client])
			{
				Debug("SMAC: Ignoring violation");
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}
#endif

public void OnClientDisconnect(int client)
{
	FF2Flags[client]=0;
	if(CloneOwnerIndex[client]!=-1)
	{
		CloneOwnerIndex[client]=-1;
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);
	}
}

public int OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client=GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	if(!client || !attacker || !IsClientInGame(client) || !IsClientInGame(attacker))
	{
		return;
	}

	int boss=FF2_GetBossIndex(attacker);
	if(boss>=0)
	{
		if(FF2_HasAbility(boss, this_plugin_name, OBJECTS))
		{
			char classname[PLATFORM_MAX_PATH], model[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS, 1, classname, sizeof(classname));
			FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS, 2, model, sizeof(model));
			int skin=FF2_GetAbilityArgument(boss, this_plugin_name, OBJECTS, 3);
			int count=FF2_GetAbilityArgument(boss, this_plugin_name, OBJECTS, 4, 14);
			float distance=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, OBJECTS, 5, 30.0);
			SpawnManyObjects(classname, client, model, skin, count, distance);
			return;
		}
		if(FF2_HasAbility(boss, this_plugin_name, "special_dissolve"))
		{
			CreateTimer(0.1, Timer_DissolveRagdoll, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
		}
		if(FF2_HasAbility(boss, this_plugin_name, "special_cbs_multimelee"))
		{
			if(GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon")==GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee))
			{
				TF2_RemoveWeaponSlot(attacker, TFWeaponSlot_Melee);
				char attributes[64];
				FF2_GetAbilityArgumentString(boss, this_plugin_name, "special_cbs_multimelee", 1, attributes, sizeof(attributes));
				if(strlen(attributes)==0)
					attributes="68 ; 2 ; 2 ; 3.1 ; 275 ; 1";
				int weapon;
				switch(GetRandomInt(0, 2))
				{
					case 0:
					{
						weapon=SpawnWeapon(attacker, "tf_weapon_club", 171, 101, 5, attributes);
					}
					case 1:
					{
						weapon=SpawnWeapon(attacker, "tf_weapon_club", 193, 101, 5, attributes);
					}
					case 2:
					{
						weapon=SpawnWeapon(attacker, "tf_weapon_club", 232, 101, 5, attributes);
					}
				}
				SetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon", weapon);
			}
		}
		if(FF2_HasAbility(boss, this_plugin_name, "special_dropprop"))
		{
			char model[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(boss, this_plugin_name, "special_dropprop", 1, model, sizeof(model));
			if(model[0]!='\0')  //Because you never know when someone is careless and doesn't specify a model...
			{
				if(!IsModelPrecached(model))  //Make sure the boss author precached the model (similar to above)
				{
					char bossName[64];
					FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
					if(!FileExists(model, true))
					{
						LogError("[FF2 Bosses] Model '%s' doesn't exist!  Please check %s's config", model, bossName);
						return;
					}
					else
					{
						PrecacheModel(model);
					}
				}

				if(FF2_GetAbilityArgument(boss, this_plugin_name, "special_dropprop", 3, 0))
				{
					CreateTimer(0.01, Timer_RemoveRagdoll, GetEventInt(event, "userid"), TIMER_FLAG_NO_MAPCHANGE);
				}

				int prop=CreateEntityByName("prop_physics_override");
				if(IsValidEntity(prop))
				{
					SetEntityModel(prop, model);
					SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
					SetEntProp(prop, Prop_Send, "m_CollisionGroup", 1);
					SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16);
					DispatchSpawn(prop);

					float position[3];
					GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
					position[2]+=20;
					TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);
					float duration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "special_dropprop", 2, 0.0);
					if(duration>0.5)
					{
						CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(prop), TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}

	boss=FF2_GetBossIndex(client);
	if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, OBJECTS_DEATH))
	{
		char classname[PLATFORM_MAX_PATH], model[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS_DEATH, 1, classname, sizeof(classname));
		FF2_GetAbilityArgumentString(boss, this_plugin_name, OBJECTS_DEATH, 2, model, sizeof(model));
		int skin=FF2_GetAbilityArgument(boss, this_plugin_name, OBJECTS_DEATH, 3);
		int count=FF2_GetAbilityArgument(boss, this_plugin_name, OBJECTS_DEATH, 4, 14);
		float distance=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, OBJECTS_DEATH, 5, 30.0);
		SpawnManyObjects(classname, client, model, skin, count, distance);
		return;
	}
	if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, "rage_cloneattack") && FF2_GetAbilityArgument(boss, this_plugin_name, "rage_cloneattack", 12, 1) && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(CloneOwnerIndex[target]==boss)
			{
				CloneOwnerIndex[target]=-1;
				FF2_SetFF2flags(target, FF2_GetFF2flags(target) & ~FF2FLAG_CLASSTIMERDISABLED);
				if(IsClientInGame(target) && GetClientTeam(target)==BossTeam)
				{
					ChangeClientTeam(target, (BossTeam==view_as<int>(TFTeam_Blue)) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)));
				}
			}
		}
	}

	if(CloneOwnerIndex[client]!=-1 && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))  //Switch clones back to the other team after they die
	{
		CloneOwnerIndex[client]=-1;
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_CLASSTIMERDISABLED);
		ChangeClientTeam(client, (BossTeam==view_as<int>(TFTeam_Blue)) ? (view_as<int>(TFTeam_Red)) : (view_as<int>(TFTeam_Blue)));
	}
}

/*	No Animations	*/

public Action Timer_Disable_Anims(Handle timer)
{
	int client;
	for(int boss; (client=GetClientOfUserId(FF2_GetBossUserId(boss)))>0; boss++)
	{
		if(FF2_HasAbility(boss, this_plugin_name, "special_noanims"))
		{
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
			SetEntProp(client, Prop_Send, "m_bCustomModelRotates", FF2_GetAbilityArgument(boss, this_plugin_name, "special_noanims", 1, 0));
		}
	}
	return Plugin_Continue;
}


/*	Easter  Abilities	*/

public void OnEntityCreated(int entity, const char[] classname)
{
	if(IsValidEntity(entity) && StrContains(classname, "tf_projectile")>=0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned);
	}
}

public void OnProjectileSpawned(int entity)
{
	int client=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client>0 && client<=MaxClients && IsClientInGame(client))
	{
		int boss=FF2_GetBossIndex(client);
		if(boss>=0 && FF2_HasAbility(boss, this_plugin_name, PROJECTILE))
		{
			char projectile[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(boss, this_plugin_name, PROJECTILE, 1, projectile, sizeof(projectile));

			char classname[PLATFORM_MAX_PATH];
			GetEntityClassname(entity, classname, sizeof(classname));
			if(StrEqual(classname, projectile, false))
			{
				char model[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(boss, this_plugin_name, PROJECTILE, 2, model, sizeof(model));
				if(IsModelPrecached(model))
				{
					SetEntityModel(entity, model);
				}
				else
				{
					char bossName[64];
					FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
					LogError("[FF2 Bosses] Model %s (used by boss %s for ability %s) isn't precached!", model, bossName, PROJECTILE);
				}
			}
		}
	}
}

int SpawnManyObjects(char[] classname, int client, char[] model, int skin=0, int amount=14, float distance=30.0)
{
	if(!client || !IsClientInGame(client))
	{
		return;
	}

	float position[3], velocity[3];
	float angle[]={90.0, 0.0, 0.0};
	GetClientAbsOrigin(client, position);
	position[2]+=distance;
	for(int i; i<amount; i++)
	{
		velocity[0]=GetRandomFloat(-400.0, 400.0);
		velocity[1]=GetRandomFloat(-400.0, 400.0);
		velocity[2]=GetRandomFloat(300.0, 500.0);
		position[0]+=GetRandomFloat(-5.0, 5.0);
		position[1]+=GetRandomFloat(-5.0, 5.0);

		int entity=CreateEntityByName(classname);
		if(!IsValidEntity(entity))
		{
			LogError("[FF2] Invalid entity while spawning objects for New Defaults-check your configs!");
			continue;
		}

		SetEntityModel(entity, model);
		DispatchKeyValue(entity, "OnPlayerTouch", "!self,Kill,,0,-1");
		SetEntProp(entity, Prop_Send, "m_nSkin", skin);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 6);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 152);
		SetEntProp(entity, Prop_Send, "m_triggerBloat", 24);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(entity, Prop_Send, "m_iTeamNum", 2);
		DispatchSpawn(entity);
		TeleportEntity(entity, position, angle, velocity);
		SetEntProp(entity, Prop_Data, "m_iHealth", 900);
		int offs=GetEntSendPropOffs(entity, "m_vecInitialVelocity", true);
		SetEntData(entity, offs-4, 1, _, true);
	}
}

public Action Timer_RemoveRagdoll(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	int ragdoll;
	if(client>0 && (ragdoll=GetEntPropEnt(client, Prop_Send, "m_hRagdoll"))>MaxClients)
	{
		AcceptEntityInput(ragdoll, "Kill");
	}
}


/*	Overlay		*/

void Rage_Overlay(int boss, const char[] ability_name)
{
	char overlay[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 1, overlay, PLATFORM_MAX_PATH);
	Format(overlay, PLATFORM_MAX_PATH, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target)!=BossTeam)
		{
			ClientCommand(target, overlay);
		}
	}

	CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 2, 6.0), Timer_Remove_Overlay, _, TIMER_FLAG_NO_MAPCHANGE);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
}

public Action Timer_Remove_Overlay(Handle timer)
{
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target)!=BossTeam)
		{
			ClientCommand(target, "r_screenoverlay off");
		}
	}
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);
	return Plugin_Continue;
}


/*	New Weapon	*/

int Rage_New_Weapon(int boss, const char[] ability_name)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return;
	}

	char classname[64], attributes[256];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 1, classname, sizeof(classname));
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 3, attributes, sizeof(attributes));

	int slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 4);
	TF2_RemoveWeaponSlot(client, slot);

	int index=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 2);
	int weapon=SpawnWeapon(client, classname, index, 101, 5, attributes);
	if(StrEqual(classname, "tf_weapon_builder") && index!=735)  //PDA, normal sapper
	{
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
	}
	else if(StrEqual(classname, "tf_weapon_sapper") || index==735)  //Sappers, normal sapper
	{
		SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
		SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
		SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
	}

	if(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 6))
	{
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}

	int ammo=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 5, 0);
	int clip=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 7, 0);
	if(ammo || clip)
	{
		FF2_SetAmmo(client, weapon, ammo, clip);
	}
}


/*	Stun	*/

public Action Timer_Rage_Stun(Handle timer, any boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	int victims=-1;
	bool solorage=false;
	char bossName[128];
	float bossPosition[3], targetPosition[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);
 // Initial Duration
	float duration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_stun", 1, 5.0);
 // Distance
	float distance=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_stun", 2, -1.0);
	if(distance<=0)
		distance=FF2_GetRageDist(boss, this_plugin_name, "rage_stun");
 // Stun Flags
	char flagOverrideStr[12];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, "rage_stun", 3, flagOverrideStr, sizeof(flagOverrideStr));
	int flagOverride = ReadHexOrDecInt(flagOverrideStr);
	if(flagOverride==0)
		flagOverride=TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT;
 // Slowdown
	float slowdown=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_stun", 4, 0.0);
 // Sound To Boss
	bool sounds=view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, "rage_stun", 5, 1));
 // Particle Effect
	char particleEffect[48];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, "rage_stun", 6, particleEffect, sizeof(particleEffect));
	if(strlen(particleEffect)==0)
		particleEffect=SPOOK;
 // Ignore
	int ignore=FF2_GetAbilityArgument(boss, this_plugin_name, "rage_stun", 7, 0);
 // Friendly Fire
	int friendly=FF2_GetAbilityArgument(boss, this_plugin_name, "rage_stun", 8, -1);
	if(friendly<0)
		friendly=GetConVarInt(FindConVar("mp_friendlyfire"));
 // Remove Parachute
	bool removeBaseJumperOnStun=view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, "rage_stun", 9, GetConVarInt(cvarBaseJumperStun)));
 // Max Duration
	float maxduration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_stun", 11, -1.0);
 // Add Duration
	float addduration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_stun", 12, 0.0);
	if(maxduration<=0)
	{
		maxduration=duration;
		addduration=0.0;
	}
 // Solo Rage Duration
	float soloduration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_stun", 13, -1.0);
	if(soloduration<=0)
	{
		soloduration=duration;
	}

	if((addduration!=0 || soloduration!=duration) && !Outdated)
	{
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target) && IsPlayerAlive(target) && ((friendly==1 || GetClientTeam(target)!=BossTeam) || target!=client))
			{
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
				if((!TF2_IsPlayerInCondition(target, TFCond_Ubercharged) || (ignore>0 && ignore!=2)) && (!TF2_IsPlayerInCondition(target, TFCond_MegaHeal) || ignore>1) && GetVectorDistance(bossPosition, targetPosition)<=distance)
				{
					victims++;
				}
			}
		}
	}
	if(victims>=0)
	{
		if(victims==0 && (duration!=soloduration || GetConVarBool(cvarSoloShame)))
		{
			solorage=true;	
			FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
			if(duration!=soloduration)
				duration=soloduration;
		}
		else if(victims>0 && duration<maxduration)
		{
			duration+=addduration*victims;
			if(duration>maxduration)
				duration=maxduration;
		}
	}
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && IsPlayerAlive(target) && ((friendly==0 || GetClientTeam(target)!=BossTeam) && target!=client))
		{
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
			if((!TF2_IsPlayerInCondition(target, TFCond_Ubercharged) || (ignore>0 && ignore!=2)) && (!TF2_IsPlayerInCondition(target, TFCond_MegaHeal) || ignore>1) && GetVectorDistance(bossPosition, targetPosition)<=distance)
			{
				if(removeBaseJumperOnStun)
				{
					TF2_RemoveCondition(target, TFCond_Parachute);
				}
				if(solorage)
				{
					CreateTimer(duration, Timer_SoloRageResult, target);
					CPrintToChatAll("{olive}[FF2]{default} %t", "Solo Rage", bossName);
				}
				TF2_StunPlayer(target, duration, slowdown, flagOverride, sounds ? client : 0);
				if(strlen(particleEffect)>1)
					CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(target, particleEffect, 75.0)), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

public Action Timer_SoloRageResult(Handle timer, any client)
{
	if(!IsClientInGame(client) || FF2_GetRoundState()!=1)
		return Plugin_Continue;

	if(IsPlayerAlive(client))
		CPrintToChatAll("{olive}[FF2]{default} %t", "Solo Rage Fail");
	else
		CPrintToChatAll("{olive}[FF2]{default} %t", "Solo Rage Win");

	return Plugin_Continue;
}

stock int ReadHexOrDecInt(char hexOrDecString[12])	// Credits to sarysa
{
	if(StrContains(hexOrDecString, "0x")==0)
	{
		int result=0;
		for(int i=2; i<10 && hexOrDecString[i]!=0; i++)
		{
			result=result<<4;
				
			if(hexOrDecString[i]>='0' && hexOrDecString[i]<='9')
				result+=hexOrDecString[i]-'0';
			else if(hexOrDecString[i]>='a' && hexOrDecString[i]<='f')
				result+=hexOrDecString[i]-'a'+10;
			else if(hexOrDecString[i]>='A' && hexOrDecString[i]<='F')
				result+=hexOrDecString[i]-'A'+10;
		}
		return result;
	}
	else
		return StringToInt(hexOrDecString);
}

stock int ReadHexOrDecString(int boss, const char[] ability_name, int args)
{
	static char hexOrDecString[12];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, args, hexOrDecString, sizeof(hexOrDecString));
	return ReadHexOrDecInt(hexOrDecString);
}


/*	Uber	*/

public Action Timer_StopUber(Handle timer, any boss)
{
	SetEntProp(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Data, "m_takedamage", 2);
	return Plugin_Continue;
}

public Action OnDeflect(Handle event, const char[] name, bool dontBroadcast)
{
	int boss=FF2_GetBossIndex(GetClientOfUserId(GetEventInt(event, "userid")));
	if(boss!=-1)
	{
		if(UberRageCount[boss]>11)
		{
			UberRageCount[boss]-=10;
		}
	}
	return Plugin_Continue;
}


/*	Building Stun	*/

void Rage_StunBuilding(const char[] ability_name, int boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	float bossPosition[3], sentryPosition[3];
	GetEntPropVector(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Send, "m_vecOrigin", bossPosition);

 // Duration
	float duration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 7.0);
 // Distance
	float distance=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 2, -1.0);
	if(distance<=0)
		distance=FF2_GetRageDist(boss, this_plugin_name, ability_name);
 // Building Health
 	bool destory=false;
	float health=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 3, 1.0);
	if(health<=0)
		destory=true;
 // Sentry Ammo
	float ammo=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 4, 1.0);
 // Sentry Rockets
	float rockets=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 5, 1.0);
 // Particle Effect
	char particleEffect[48];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 6, particleEffect, sizeof(particleEffect));
	if(strlen(particleEffect)==0)
		particleEffect=SPOOK;
 // Buildings
	int buildings=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 7, 1);
	// 1: Sentry
	// 2: Dispenser
	// 3: Teleporter
	// 4: Sentry + Dispenser
	// 5: Sentry + Teleporter
	// 6: Dispenser + Teleporter
	// 7: ALL
 // Friendly Fire
	int friendly=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 8, -1);
	if(friendly<0)
		friendly=GetConVarInt(FindConVar("mp_friendlyfire"));

	if(buildings>0 && buildings!=2 && buildings!=3 && buildings!=6)
	{
		int sentry;
		while((sentry=FindEntityByClassname(sentry, "obj_sentrygun"))!=-1)
		{
			if((((GetEntProp(sentry, Prop_Send, "m_nSkin") % 2)!=(GetClientTeam(client) % 2)) || friendly>0) && !GetEntProp(sentry, Prop_Send, "m_bCarried") && !GetEntProp(sentry, Prop_Send, "m_bPlacing"))
			{
				GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentryPosition);
				if(GetVectorDistance(bossPosition, sentryPosition)<=distance)
				{
					if(destory)
						SDKHooks_TakeDamage(sentry, client, client, 9001.0, DMG_GENERIC, -1);
					else
					{
						if(health!=1)
							SDKHooks_TakeDamage(sentry, client, client, GetEntProp(sentry, Prop_Send, "m_iMaxHealth")*health, DMG_GENERIC, -1);
						if(ammo>=0 && ammo<=1 && ammo!=1)
							SetEntProp(sentry, Prop_Send, "m_iAmmoShells", GetEntProp(sentry, Prop_Send, "m_iAmmoShells")*ammo);
						if(rockets>=0 && rockets<=1 && rockets!=1)
							SetEntProp(sentry, Prop_Send, "m_iAmmoRockets", GetEntProp(sentry, Prop_Send, "m_iAmmoRockets")*rockets);
						if(duration>0)
						{
							SetEntProp(sentry, Prop_Send, "m_bDisabled", 1);
							CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(sentry, particleEffect, 75.0)), TIMER_FLAG_NO_MAPCHANGE);
							CreateTimer(duration, Timer_EnableBuilding, EntIndexToEntRef(sentry), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}
	if(buildings>1 && buildings!=3 && buildings!=5)
	{
		int dispenser;
		while((dispenser=FindEntityByClassname(dispenser, "obj_dispenser"))!=-1)
		{
			if((((GetEntProp(dispenser, Prop_Send, "m_nSkin") % 2)!=(GetClientTeam(client) % 2)) || friendly>0) && !GetEntProp(dispenser, Prop_Send, "m_bCarried") && !GetEntProp(dispenser, Prop_Send, "m_bPlacing"))
			{
				GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", sentryPosition);
				if(GetVectorDistance(bossPosition, sentryPosition)<=distance)
				{
					if(destory)
						SDKHooks_TakeDamage(dispenser, client, client, 9001.0, DMG_GENERIC, -1);
					else
					{
						if(health!=1)
							SDKHooks_TakeDamage(dispenser, client, client, GetEntProp(dispenser, Prop_Send, "m_iMaxHealth")*health, DMG_GENERIC, -1);
						if(duration>0)
						{
							SetEntProp(dispenser, Prop_Send, "m_bDisabled", 1);
							CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(dispenser, particleEffect, 75.0)), TIMER_FLAG_NO_MAPCHANGE);
							CreateTimer(duration, Timer_EnableBuilding, EntIndexToEntRef(dispenser), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}
	if(buildings>2 && buildings!=4)
	{
		int teleporter;
		while((teleporter=FindEntityByClassname(teleporter, "obj_teleporter"))!=-1)
		{
			if((((GetEntProp(teleporter, Prop_Send, "m_nSkin") % 2)!=(GetClientTeam(client) % 2)) || friendly>0) && !GetEntProp(teleporter, Prop_Send, "m_bCarried") && !GetEntProp(teleporter, Prop_Send, "m_bPlacing"))
			{
				GetEntPropVector(teleporter, Prop_Send, "m_vecOrigin", sentryPosition);
				if(GetVectorDistance(bossPosition, sentryPosition)<=distance)
				{
					if(destory)
						SDKHooks_TakeDamage(teleporter, client, client, 9001.0, DMG_GENERIC, -1);
					else
					{
						if(health!=1)
							SDKHooks_TakeDamage(teleporter, client, client, GetEntProp(teleporter, Prop_Send, "m_iMaxHealth")*health, DMG_GENERIC, -1);
						if(duration>0)
						{
							SetEntProp(teleporter, Prop_Send, "m_bDisabled", 1);
							CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(teleporter, particleEffect, 75.0)), TIMER_FLAG_NO_MAPCHANGE);
							CreateTimer(duration, Timer_EnableBuilding, EntIndexToEntRef(teleporter), TIMER_FLAG_NO_MAPCHANGE);
						}
					}
				}
			}
		}
	}
}

public Action Timer_EnableBuilding(Handle timer, any sentryid)
{
	int sentry=EntRefToEntIndex(sentryid);
	if(FF2_GetRoundState()==1 && sentry>MaxClients)
	{
		SetEntProp(sentry, Prop_Send, "m_bDisabled", 0);
	}
	return Plugin_Continue;
}


/*	Instant Teleport	*/


public Action Timer_StunBoss(Handle timer, any boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!IsValidEntity(client))
	{
		return;
	}
	TF2_StunPlayer(client, Tstun, Tslowdown, TflagOverride, 0);
}


/*	Dissolve	*/

public Action Timer_DissolveRagdoll(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	int ragdoll=-1;
	if(client && IsClientInGame(client))
	{
		ragdoll=GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	}

	if(IsValidEntity(ragdoll))
	{
		DissolveRagdoll(ragdoll);
	}
}

int DissolveRagdoll(int ragdoll)
{
	int dissolver=CreateEntityByName("env_entity_dissolver");
	if(dissolver==-1)
	{
		return;
	}

	DispatchKeyValue(dissolver, "dissolvetype", "0");
	DispatchKeyValue(dissolver, "magnitude", "200");
	DispatchKeyValue(dissolver, "target", "!activator");

	AcceptEntityInput(dissolver, "Dissolve", ragdoll);
	AcceptEntityInput(dissolver, "Kill");
}


/*	Clone Attack	*/

void Rage_Clone(const char[] ability_name, int boss)
{
	Handle bossKV[8];
	char bossName[32];
	bool changeModel=view_as<bool>(FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 1));
	int weaponMode=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 2);
	char model[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 3, model, sizeof(model));
	int class=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 4);
	float ratio=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 5, 0.0);
	char classname[64]="tf_weapon_bottle";
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 6, classname, sizeof(classname));
	int index=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 7, 191);
	char attributes[64]="68 ; -1";
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 8, attributes, sizeof(attributes));
	int ammo=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 9, -1);
	int clip=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 10, -1);
	char healthformula[768];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 11, healthformula, sizeof(healthformula));

	float position[3], velocity[3];
	GetEntPropVector(GetClientOfUserId(FF2_GetBossUserId(boss)), Prop_Data, "m_vecOrigin", position);

	FF2_GetBossSpecial(boss, bossName, sizeof(bossName));

	int maxKV;
	for(maxKV=0; maxKV<8; maxKV++)
	{
		if(!(bossKV[maxKV]=FF2_GetSpecialKV(maxKV)))
		{
			break;
		}
	}

	int alive, dead;
	Handle players=CreateArray();
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target))
		{
			TFTeam team=view_as<TFTeam>(GetClientTeam(target));
			if(team>TFTeam_Spectator && team!=view_as<TFTeam>(BossTeam))
			{
				if(IsPlayerAlive(target))
				{
					alive++;
				}
				else if(FF2_GetBossIndex(target)==-1)  //Don't let dead bosses become clones
				{
					PushArrayCell(players, target);
					dead++;
				}
			}
		}
	}

	int health=ParseFormula(boss, healthformula, 0, alive);
	int totalMinions=(ratio ? RoundToCeil(alive*ratio) : MaxClients);  //If ratio is 0, use MaxClients instead
	int config=GetRandomInt(0, maxKV-1);
	int clone, temp;
	for(int i=1; i<=dead && i<=totalMinions; i++)
	{
		temp=GetRandomInt(0, GetArraySize(players)-1);
		clone=GetArrayCell(players, temp);
		RemoveFromArray(players, temp);

		FF2_SetFF2flags(clone, FF2_GetFF2flags(clone)|FF2FLAG_ALLOWSPAWNINBOSSTEAM|FF2FLAG_CLASSTIMERDISABLED);
		ChangeClientTeam(clone, BossTeam);
		TF2_RespawnPlayer(clone);
		CloneOwnerIndex[clone]=boss;
		TF2_SetPlayerClass(clone, (class ? (view_as<TFClassType>(class)) : (view_as<TFClassType>(KvGetNum(bossKV[config], "class", 0)))), _, false);

		if(changeModel)
		{
			if(model[0]=='\0')
			{
				KvGetString(bossKV[config], "model", model, sizeof(model));
			}
			SetVariantString(model);
			AcceptEntityInput(clone, "SetCustomModel");
			SetEntProp(clone, Prop_Send, "m_bUseClassAnimations", 1);
		}

		switch(weaponMode)
		{
			case 0:
			{
				TF2_RemoveAllWeapons(clone);
			}
			case 1:
			{
				int weapon;
				TF2_RemoveAllWeapons(clone);
				if(classname[0]=='\0')
				{
					classname="tf_weapon_bottle";
				}

				if(attributes[0]=='\0')
				{
					attributes="68 ; -1";
				}

				weapon=SpawnWeapon(clone, classname, index, 101, 0, attributes);
				if(StrEqual(classname, "tf_weapon_builder") && index!=735)  //PDA, normal sapper
				{
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
				}
				else if(StrEqual(classname, "tf_weapon_sapper") || index==735)  //Sappers, normal sapper
				{
					SetEntProp(weapon, Prop_Send, "m_iObjectType", 3);
					SetEntProp(weapon, Prop_Data, "m_iSubType", 3);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
					SetEntProp(weapon, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
				}

				if(IsValidEntity(weapon))
				{
					SetEntPropEnt(clone, Prop_Send, "m_hActiveWeapon", weapon);
					SetEntProp(weapon, Prop_Send, "m_iWorldModelIndex", -1);
				}

				FF2_SetAmmo(clone, weapon, ammo, clip);
			}
		}

		if(health)
		{
			SetEntProp(clone, Prop_Data, "m_iMaxHealth", health);
			SetEntProp(clone, Prop_Data, "m_iHealth", health);
			SetEntProp(clone, Prop_Send, "m_iHealth", health);
		}

		velocity[0]=GetRandomFloat(300.0, 500.0)*(GetRandomInt(0, 1) ? 1:-1);
		velocity[1]=GetRandomFloat(300.0, 500.0)*(GetRandomInt(0, 1) ? 1:-1);
		velocity[2]=GetRandomFloat(300.0, 500.0);
		TeleportEntity(clone, position, NULL_VECTOR, velocity);

		PrintHintText(clone, "%t", "seeldier_rage_message", bossName);

		SetEntProp(clone, Prop_Data, "m_takedamage", 0);
		SDKHook(clone, SDKHook_OnTakeDamage, SaveMinion);
		CreateTimer(4.0, Timer_Enable_Damage, GetClientUserId(clone), TIMER_FLAG_NO_MAPCHANGE);

		Handle data;
		CreateDataTimer(0.1, Timer_EquipModel, data, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(data, GetClientUserId(clone));
		WritePackString(data, model);
	}
	CloseHandle(players);

	int entity, owner;
	while((entity=FindEntityByClassname(entity, "tf_wearable"))!=-1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
		{
			TF2_RemoveWearable(owner, entity);
		}
	}

	while((entity=FindEntityByClassname(entity, "tf_wearable_razorback"))!=-1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
		{
			TF2_RemoveWearable(owner, entity);
		}
	}
	
	while((entity=FindEntityByClassname(entity, "tf_wearable_demoshield"))!=-1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
		{
			TF2_RemoveWearable(owner, entity);
		}
	}

	while((entity=FindEntityByClassname(entity, "tf_powerup_bottle"))!=-1)
	{
		if((owner=GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"))<=MaxClients && owner>0 && GetClientTeam(owner)==BossTeam)
		{
			TF2_RemoveWearable(owner, entity);
		}
	}
}

public Action Timer_EquipModel(Handle timer, any pack)
{
	ResetPack(pack);
	int client=GetClientOfUserId(ReadPackCell(pack));
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char model[PLATFORM_MAX_PATH];
		ReadPackString(pack, model, PLATFORM_MAX_PATH);
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

public Action Timer_Enable_Damage(Handle timer, any userid)
{
	int client=GetClientOfUserId(userid);
	if(client)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
		FF2_SetFF2flags(client, FF2_GetFF2flags(client) & ~FF2FLAG_ALLOWSPAWNINBOSSTEAM);
		SDKUnhook(client, SDKHook_OnTakeDamage, SaveMinion);
	}
	return Plugin_Continue;
}

public Action SaveMinion(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(attacker>MaxClients)
	{
		char edict[64];
		if(GetEntityClassname(attacker, edict, sizeof(edict)) && !strcmp(edict, "trigger_hurt", false))
		{
			int target;
			float position[3];
			bool otherTeamIsAlive;
			for(int clone=1; clone<=MaxClients; clone++)
			{
				if(IsValidEntity(clone) && IsClientInGame(clone) && IsPlayerAlive(clone) && GetClientTeam(clone)!=BossTeam)
				{
					otherTeamIsAlive=true;
					break;
				}
			}

			int tries;
			do
			{
				tries++;
				target=GetRandomInt(1, MaxClients);
				if(tries==100)
				{
					return Plugin_Continue;
				}
			}
			while(otherTeamIsAlive && (!IsValidEntity(target) || GetClientTeam(target)==BossTeam || !IsPlayerAlive(target)));

			GetEntPropVector(target, Prop_Data, "m_vecOrigin", position);
			TeleportEntity(client, position, NULL_VECTOR, NULL_VECTOR);
			TF2_StunPlayer(client, 2.0, 0.0, TF_STUNFLAGS_GHOSTSCARE|TF_STUNFLAG_NOSOUNDOREFFECT, client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

stock int Operate(Handle sumArray, int &bracket, float value, Handle _operator)
{
	float sum=GetArrayCell(sumArray, bracket);
	switch(GetArrayCell(_operator, bracket))
	{
		case Operator_Add:
		{
			SetArrayCell(sumArray, bracket, sum+value);
		}
		case Operator_Subtract:
		{
			SetArrayCell(sumArray, bracket, sum-value);
		}
		case Operator_Multiply:
		{
			SetArrayCell(sumArray, bracket, sum*value);
		}
		case Operator_Divide:
		{
			if(!value)
			{
				LogError("[FF2 Bosses] Detected a divide by 0 for rage_clone!");
				bracket=0;
				return;
			}
			SetArrayCell(sumArray, bracket, sum/value);
		}
		case Operator_Exponent:
		{
			SetArrayCell(sumArray, bracket, Pow(sum, value));
		}
		default:
		{
			SetArrayCell(sumArray, bracket, value);  //This means we're dealing with a constant
		}
	}
	SetArrayCell(_operator, bracket, Operator_None);
}

stock void OperateString(Handle sumArray, int &bracket, char[] value, int size, Handle _operator)
{
	if(!StrEqual(value, ""))  //Make sure 'value' isn't blank
	{
		Operate(sumArray, bracket, StringToFloat(value), _operator);
		strcopy(value, size, "");
	}
}

public int ParseFormula(int boss, const char[] key, int defaultValue, int playing)
{
	char formula[1024], bossName[64];
	FF2_GetBossSpecial(boss, bossName, sizeof(bossName));
	strcopy(formula, sizeof(formula), key);
	int size=1;
	int matchingBrackets;
	for(int i; i<=strlen(formula); i++)  //Resize the arrays once so we don't have to worry about it later on
	{
		if(formula[i]=='(')
		{
			if(!matchingBrackets)
			{
				size++;
			}
			else
			{
				matchingBrackets--;
			}
		}
		else if(formula[i]==')')
		{
			matchingBrackets++;
		}
	}

	Handle sumArray=CreateArray(_, size), _operator=CreateArray(_, size);
	int bracket;  //Each bracket denotes a separate sum (within parentheses).  At the end, they're all added together to achieve the actual sum
	SetArrayCell(sumArray, 0, 0.0);  //TODO:  See if these can be placed naturally in the loop
	SetArrayCell(_operator, bracket, Operator_None);

	char character[2], value[16];
	for(int i; i<=strlen(formula); i++)
	{
		character[0]=formula[i];  //Find out what the next char in the formula is
		switch(character[0])
		{
			case ' ', '\t':  //Ignore whitespace
			{
				continue;
			}
			case '(':
			{
				bracket++;  //We've just entered a new parentheses so increment the bracket value
				SetArrayCell(sumArray, bracket, 0.0);
				SetArrayCell(_operator, bracket, Operator_None);
			}
			case ')':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				if(GetArrayCell(_operator, bracket)!=Operator_None)  //Something like (5*)
				{
					LogError("[FF2 Bosses] %s's %s formula for rage_clone has an invalid operator at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				if(--bracket<0)  //Something like (5))
				{
					LogError("[FF2 Bosses] %s's %s formula for rage_clone has an unbalanced parentheses at character %i", bossName, key, i+1);
					CloseHandle(sumArray);
					CloseHandle(_operator);
					return defaultValue;
				}

				Operate(sumArray, bracket, GetArrayCell(sumArray, bracket+1), _operator);
			}
			case '\0':  //End of formula
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
			}
			case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.':
			{
				StrCat(value, sizeof(value), character);  //Constant?  Just add it to the current value
			}
			case 'n', 'x':  //n and x denote player variables
			{
				Operate(sumArray, bracket, float(playing), _operator);
			}
			case '+', '-', '*', '/', '^':
			{
				OperateString(sumArray, bracket, value, sizeof(value), _operator);
				switch(character[0])
				{
					case '+':
					{
						SetArrayCell(_operator, bracket, Operator_Add);
					}
					case '-':
					{
						SetArrayCell(_operator, bracket, Operator_Subtract);
					}
					case '*':
					{
						SetArrayCell(_operator, bracket, Operator_Multiply);
					}
					case '/':
					{
						SetArrayCell(_operator, bracket, Operator_Divide);
					}
					case '^':
					{
						SetArrayCell(_operator, bracket, Operator_Exponent);
					}
				}
			}
		}
	}

	int result=RoundFloat(GetArrayCell(sumArray, 0));
	CloseHandle(sumArray);
	CloseHandle(_operator);
	if(result<=0)
	{
		LogError("[FF2 Bosses] %s has an invalid %s formula for rage_clone, using default health!", bossName, key);
		return defaultValue;
	}
	return result;
}


/*	Trade Spam	*/

public Action Timer_Demopan_Rage(Handle timer, any count)  //TODO: Make this rage configurable
{
	if(count==13)  //Rage has finished-reset it in 6 seconds (trade_0 is 100% transparent apparently)
	{
		CreateTimer(6.0, Timer_Demopan_Rage, 0, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		char overlay[PLATFORM_MAX_PATH];
		Format(overlay, sizeof(overlay), "r_screenoverlay \"freak_fortress_2/demopan/trade_%i\"", count);

		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);  //Allow normal players to use r_screenoverlay
		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)!=BossTeam)
			{
				ClientCommand(client, overlay);
			}
		}
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & FCVAR_CHEAT);  //Reset the cheat permissions

		if(count)
		{
			EmitSoundToAll(SOUND_DEMOPAN_RAGE, _, _, _, _, _, _, _, _, _, false);
			CreateTimer(count==1 ? 1.0 : 0.5/float(count), Timer_Demopan_Rage, count+1, TIMER_FLAG_NO_MAPCHANGE);  //Give a longer delay between the first and second overlay for "smoothness"
		}
		else  //Stop the rage
		{
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}


/*	CBS Bow Rage	*/

void Rage_Bow(int boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	TF2_RemoveWeaponSlot(client, TFWeaponSlot_Primary);
	char attributes[64];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, "rage_cbs_bowrage", 1, attributes, sizeof(attributes));
	if(strlen(attributes)==0)
		attributes="6 ; 0.5 ; 37 ; 0.0 ; 280 ; 19";
	int weapon=SpawnWeapon(client, "tf_weapon_compound_bow", 1005, 101, 5, attributes);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	TFTeam team=(FF2_GetBossTeam()==view_as<int>(TFTeam_Blue) ? TFTeam_Red:TFTeam_Blue);

	int otherTeamAlivePlayers;
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsClientInGame(target) && view_as<TFTeam>(GetClientTeam(target))==team && IsPlayerAlive(target))
		{
			otherTeamAlivePlayers++;
		}
	}

	FF2_SetAmmo(client, weapon, ((otherTeamAlivePlayers>=CBS_MAX_ARROWS) ? CBS_MAX_ARROWS : otherTeamAlivePlayers)-1, 1);  //Put one arrow in the clip
}


/*	Explosive Dance	*/

public Action Timer_Prepare_Explosion_Rage(Handle timer, Handle data)
{
	int boss=ReadPackCell(data);
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));

	char ability_name[64];
	ReadPackString(data, ability_name, sizeof(ability_name));

	CreateTimer(0.13, Timer_Rage_Explosive_Dance, boss, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	float position[3];
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", position);

	char sound[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 1, sound, PLATFORM_MAX_PATH);
	if(strlen(sound))
	{
		EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
		EmitSoundToAll(sound, client, _, _, _, _, _, client, position);
		for(int target=1; target<=MaxClients; target++)
		{
			if(IsClientInGame(target) && target!=client)
			{
				EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
				EmitSoundToClient(target, sound, client, _, _, _, _, _, client, position);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Rage_Explosive_Dance(Handle timer, any boss)
{
	static int count;
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	count++;
	if(count<=35 && IsPlayerAlive(client))
	{
		SetEntityMoveType(boss, MOVETYPE_NONE);
		float bossPosition[3], explosionPosition[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);
		explosionPosition[2]=bossPosition[2];
		for(int i; i<5; i++)
		{
			int explosion=CreateEntityByName("env_explosion");
			DispatchKeyValueFloat(explosion, "DamageForce", 180.0);

			SetEntProp(explosion, Prop_Data, "m_iMagnitude", 280, 4);
			SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", 200, 4);
			SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);

			DispatchSpawn(explosion);

			explosionPosition[0]=bossPosition[0]+GetRandomInt(-350, 350);
			explosionPosition[1]=bossPosition[1]+GetRandomInt(-350, 350);
			if(!(GetEntityFlags(boss) & FL_ONGROUND))
			{
				explosionPosition[2]=bossPosition[2]+GetRandomInt(-150, 150);
			}
			else
			{
				explosionPosition[2]=bossPosition[2]+GetRandomInt(0,100);
			}
			TeleportEntity(explosion, explosionPosition, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode");
			AcceptEntityInput(explosion, "kill");
		}
	}
	else
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		count=0;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


/*	Matrix Attack	*/

void Rage_Slowmo(int boss, const char[] ability_name)
{
	FF2_SetFF2flags(boss, FF2_GetFF2flags(boss)|FF2FLAG_CHANGECVAR);
	SetConVarFloat(cvarTimeScale, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 2, 0.1));
	float duration=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 1.0)+1.0;
	SlowMoTimer=CreateTimer(duration, Timer_StopSlowMo, boss, TIMER_FLAG_NO_MAPCHANGE);
	FF2Flags[boss]=FF2Flags[boss]|FLAG_SLOWMOREADYCHANGE|FLAG_ONSLOWMO;
	UpdateClientCheatValue(1);

	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(client)
	{
		CreateTimer(duration, Timer_RemoveEntity, EntIndexToEntRef(AttachParticle(client, BossTeam==view_as<int>(TFTeam_Blue) ? "scout_dodge_blue" : "scout_dodge_red", 75.0)), TIMER_FLAG_NO_MAPCHANGE);
	}

	EmitSoundToAll(SOUND_SLOW_MO_START, _, _, _, _, _, _, _, _, _, false);
	EmitSoundToAll(SOUND_SLOW_MO_START, _, _, _, _, _, _, _, _, _, false);
}

public Action Timer_StopSlowMo(Handle timer, any boss)
{
	SlowMoTimer=INVALID_HANDLE;
	oldTarget=0;
	SetConVarFloat(cvarTimeScale, 1.0);
	UpdateClientCheatValue(0);
	if(boss!=-1)
	{
		FF2_SetFF2flags(boss, FF2_GetFF2flags(boss) & ~FF2FLAG_CHANGECVAR);
		FF2Flags[boss]&=~FLAG_ONSLOWMO;
	}
	EmitSoundToAll(SOUND_SLOW_MO_END, _, _, _, _, _, _, _, _, _, false);
	EmitSoundToAll(SOUND_SLOW_MO_END, _, _, _, _, _, _, _, _, _, false);
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float velocity[3], float angles[3], int &weapon)
{
	int boss=FF2_GetBossIndex(client);
	if(boss==-1 || !(FF2Flags[boss] & FLAG_ONSLOWMO))
	{
		return Plugin_Continue;
	}

	if(buttons & IN_ATTACK)
	{
		FF2Flags[boss]&=~FLAG_SLOWMOREADYCHANGE;
		CreateTimer(FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_matrix_attack", 3, 0.2), Timer_SlowMoChange, boss, TIMER_FLAG_NO_MAPCHANGE);

		float bossPosition[3], endPosition[3], eyeAngles[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);
		bossPosition[2]+=65;
		GetClientEyeAngles(client, eyeAngles);

		Handle trace=TR_TraceRayFilterEx(bossPosition, eyeAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf);
		TR_GetEndPosition(endPosition, trace);
		endPosition[2]+=100;
		SubtractVectors(endPosition, bossPosition, velocity);
		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, 2012.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		int target=TR_GetEntityIndex(trace);
		if(target && target<=MaxClients)
		{
			Handle data;
			CreateDataTimer(0.15, Timer_Rage_SlowMo_Attack, data);
			WritePackCell(data, GetClientUserId(client));
			WritePackCell(data, GetClientUserId(target));
			ResetPack(data);
		}
		CloseHandle(trace);
	}
	return Plugin_Continue;
}

public Action Timer_Rage_SlowMo_Attack(Handle timer, Handle data)
{
	int client=GetClientOfUserId(ReadPackCell(data));
	int target=GetClientOfUserId(ReadPackCell(data));
	if(client && target && IsClientInGame(client) && IsClientInGame(target))
	{
		float clientPosition[3], targetPosition[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPosition);
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", targetPosition);
		if(GetVectorDistance(clientPosition, targetPosition)<=1500 && target!=oldTarget)
		{
			SetEntProp(client, Prop_Send, "m_bDucked", 1);
			SetEntityFlags(client, GetEntityFlags(client)|FL_DUCKING);
			SDKHooks_TakeDamage(target, client, client, 900.0);
			TeleportEntity(client, targetPosition, NULL_VECTOR, NULL_VECTOR);
			oldTarget=target;
		}
	}
}

public bool TraceRayDontHitSelf(int entity, int mask)
{
	if(!entity || entity>MaxClients)
	{
		return true;
	}

	if(FF2_GetBossIndex(entity)==-1)
	{
		return true;
	}
	return false;
}

public Action Timer_SlowMoChange(Handle timer, any boss)
{
	FF2Flags[boss]|=FLAG_SLOWMOREADYCHANGE;
	return Plugin_Continue;
}

stock void UpdateClientCheatValue(int value)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			SendConVarValue(client, cvarCheats, value ? "1" : "0");
		}
	}
}


/*	Extras	*/

public Action Timer_RemoveEntity(Handle timer, any entid)
{
	int entity=EntRefToEntIndex(entid);
	if(IsValidEntity(entity) && entity>MaxClients)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

stock int AttachParticle(int entity, char[] particleType, float offset=0.0, bool attach=true)
{
	int particle=CreateEntityByName("info_particle_system");

	char targetName[128];
	float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2]+=offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int quality, char[] attribute)
{
	Handle weapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count=ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2=0;
		for(int i=0; i<count; i+=2)
		{
			int attrib=StringToInt(attributes[i]);
			if(!attrib)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if(weapon==INVALID_HANDLE)
	{
		return -1;
	}

	int entity=TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}
