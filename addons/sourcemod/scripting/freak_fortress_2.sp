/*
                << Freak Fortress 2 >>
                    < Unofficial >

     Original Author of VSH and FF2, Rainbolt Dash
        Programmer, modeller, mapper, painter
             Author of Demoman The Pirate
         One of two creators of Floral Defence

      And notoriously famous for creating plugins
      with terrible code and then abandoning them.

      Updated by Otokiru, Powerlord, and RavensBro
       after Rainbolt Dash got sucked into DOTA2

     Updated again by Wliu, Chris, Lawd, and Carge
              after Powerlord quit FF2

           Old Versus Saxton Hale Thread:
  http://forums.alliedmods.net/showthread.php?t=146884
             Old Freak Fortress Thread:
  http://forums.alliedmods.net/showthread.php?t=182108
           New Versus Saxton Hale Thread:
  http://forums.alliedmods.net/showthread.php?t=244209
             New Freak Fortress Thread:
  http://forums.alliedmods.net/showthread.php?t=229013

    Freak Fortress and Versus Saxton Hale Subforum:
  http://forums.alliedmods.net/forumdisplay.php?f=154




 I'm not sure how long FF2 (or TF2 in general) is going to
last, but I would hate to see this plugin go, it's one of
my all time favorite gamemodes. I just love the concept of
one vs all gameplay. Sure it may have balance issues and
other broken things, but I'll still love this gamemode
either way. So I'm giving it one hella of a booster, one
last time or to encourage others to do the same.

					-Batfoxkid

          Unofficial Freak Fortress Thread:
  http://forums.alliedmods.net/showthread.php?t=313008
*/
#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <morecolors>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#tryinclude <SteamWorks>
#define REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#tryinclude <cw3>
#tryinclude <smac>
#tryinclude <goomba>
#tryinclude <tf2attributes>
#define REQUIRE_PLUGIN

#pragma newdecls required

#include "impl/consts.sp"
#include "impl/vars.sp"

#include "impl/convars_vars.sp"
#include "impl/commands.sp"
#include "impl/panels.sp"

#include "impl/healthbar.sp"
#include "impl/convars.sp"
#include "impl/database.sp"

#include "impl/natives.sp"
#include "impl/forwards.sp"
#include "impl/events.sp"

#include "impl/vsh_hooks.sp"
#include "impl/timers.sp"
#include "impl/hooks.sp"

#include "impl/character.sp"
#include "impl/character_args.sp"
#include "impl/music.sp"

#include "impl/formula_parser.sp"
#include "impl/utils.sp"

public Plugin myinfo =
{
	name		=	"Freak Fortress 2",
	author		=	"Many many people",
	description	=	"RUUUUNN!! COWAAAARRDSS!",
	version		=	PLUGIN_VERSION,
	url		=	"https://forums.alliedmods.net/forumdisplay.php?f=154",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char plugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myself, plugin, sizeof(plugin));
	if(!StrContains(plugin, "freaks/"))  //Prevent plugins/freaks/freak_fortress_2 from loading if it exists -.-
	{
		strcopy(error, err_max, "There is a duplicate copy of Freak Fortress 2 inside the /plugins/freaks folder.  Please remove it");
		return APLRes_Failure;
	}

	Natives_Create();
	Forwards_Create();
	
	RegPluginLibrary("freak_fortress_2");

	AskPluginLoad_VSH();
	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif

	#if defined _SteamWorks_Included
	MarkNativeAsOptional("SteamWorks_SetGameDescription");
	#endif

	#if defined _tf2attributes_included
	MarkNativeAsOptional("TF2Attrib_SetByDefIndex");
	MarkNativeAsOptional("TF2Attrib_RemoveByDefIndex");
	#endif

	LateLoaded = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LogMessage("Freak Fortress 2 "... PLUGIN_VERSION ..." Loading...");

	// Logs
	BuildPath(Path_SM, pLog, sizeof(pLog), BossLogPath);
	if(!DirExists(pLog))
	{
		CreateDirectory(pLog, 511);
		if(!DirExists(pLog))
			LogError("Failed to create directory at %s", pLog);
	}

	BuildPath(Path_SM, eLog, sizeof(eLog), "%s/%s", LogPath, ErrorLog);
	if(!FileExists(eLog))
		OpenFile(eLog, "a+");
		
	_FF2Save = new FF2Save();
	
	ConVars_CreateConvars();
	
	Events_HookGameEvents();
	
	OnPluginStart_TeleportToMultiMapSpawn();	// Setup adt_array

	ConVars_AddCommandHooks();
	
	ConVars_AddChangeHooks();
	ConVars_CreateCommands();
	
	ReloadFF2 = false;
	ReloadWeapons = false;
	ReloadConfigs = false;

	AutoExecConfig(true, "FreakFortress2");

	DataBase_CreateCookies();
	
	jumpHUD = CreateHudSynchronizer();
	rageHUD = CreateHudSynchronizer();
	livesHUD = CreateHudSynchronizer();
	abilitiesHUD = CreateHudSynchronizer();
	timeleftHUD = CreateHudSynchronizer();
	infoHUD = CreateHudSynchronizer();
	statHUD = CreateHudSynchronizer();
	healthHUD = CreateHudSynchronizer();
	rivalHUD = CreateHudSynchronizer();

	char oldVersion[64];
	cvarVersion.GetString(oldVersion, 64);
	if(strcmp(oldVersion, PLUGIN_VERSION, false))
		LogToFile(eLog, "[Config] Warning: Your config may be outdated. Back up tf/cfg/sourcemod/FreakFortress2.cfg and delete it, and this plugin will generate a new one that you can then modify to your original values.");

	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("freak_fortress_2_prefs.phrases");
	LoadTranslations("freak_fortress_2_stats.phrases");
	LoadTranslations("freak_fortress_2_weaps.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	if(LateLoaded)
		OnMapStart();

	AddNormalSoundHook(HookSound);

	#if defined _steamtools_included
	steamtools = LibraryExists("SteamTools");
	#endif

	#if defined _SteamWorks_Included
	steamworks = LibraryExists("SteamWorks");
	#endif

	#if defined _goomba_included
	goomba = LibraryExists("goomba");
	#endif

	#if defined _tf2attributes_included
	tf2attributes = LibraryExists("tf2attributes");
	#endif

	TimesTen = LibraryExists("tf2x10");

	Handle gameData = LoadGameConfigFile("equipwearable");
	if(gameData == INVALID_HANDLE)
	{
		LogToFile(eLog, "[Gamedata] Failed to find equipwearable.txt");
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	SDKEquipWearable = EndPrepSDKCall();
	if(SDKEquipWearable == null)
		LogToFile(eLog, "[Gamedata] Failed to create call: CBasePlayer::EquipWearable");

	delete gameData;
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "tf2x10", false))
	{
		TimesTen = true;
	}
	#if defined _steamtools_included
	else if(StrEqual(name, "SteamTools", false))
	{
		steamtools = true;
	}
	#endif
	#if defined _SteamWorks_Included
	else if(StrEqual(name, "SteamWorks", false))
	{
		steamworks = true;
	}
	#endif
	#if defined _tf2attributes_included
	else if(StrEqual(name, "tf2attributes", false))
	{
		tf2attributes = true;
	}
	#endif
	#if defined _goomba_included
	else if(StrEqual(name, "goomba", false))
	{
		goomba = true;
	}
	#endif
	#if !defined _smac_included
	else if(StrEqual(name, "smac", false))
	{
		smac = true;
	}
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "tf2x10", false))
	{
		TimesTen = false;
	}
	#if defined _steamtools_included
	else if(StrEqual(name, "SteamTools", false))
	{
		steamtools = false;
	}
	#endif
	#if defined _SteamWorks_Included
	else if(StrEqual(name, "SteamWorks", false))
	{
		steamworks = false;
	}
	#endif
	#if defined _tf2attributes_included
	else if(StrEqual(name, "tf2attributes", false))
	{
		tf2attributes = false;
	}
	#endif
	#if defined _goomba_included
	else if(StrEqual(name, "goomba", false))
	{
		goomba = false;
	}
	#endif
	#if !defined _smac_included
	else if(StrEqual(name, "smac", false))
	{
		smac = false;
	}
	#endif
}

public void OnConfigsExecuted()
{
	tf_arena_use_queue = GetConVarInt(FindConVar("tf_arena_use_queue"));
	mp_teams_unbalance_limit = GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
	tf_arena_first_blood = GetConVarInt(FindConVar("tf_arena_first_blood"));
	mp_forcecamera = GetConVarInt(FindConVar("mp_forcecamera"));
	tf_dropped_weapon_lifetime = GetConVarInt(FindConVar("tf_dropped_weapon_lifetime"));
	GetConVarString(FindConVar("mp_humans_must_join_team"), mp_humans_must_join_team, sizeof(mp_humans_must_join_team));
	GetConVarString(hostName=FindConVar("hostname"), oldName, sizeof(oldName));

	if(cvarEnabled.IntValue>1 || (Utils_IsFF2Map(currentmap) && cvarEnabled.IntValue>0))
	{
		EnableFF2();
	}
	else
	{
		DisableFF2();
		CacheDifficulty();
		FindCharacters();
	}
}

public void OnPluginEnd()
{
	OnMapEnd();
	hostName.SetString(oldName);
	if(!ReloadFF2 && Utils_CheckRoundState()==1)
	{
		Utils_ForceTeamWin(0);
		FPrintToChatAll("The plugin has been unexpectedly unloaded!");
	}
}

void EnableFF2()
{
	Enabled = true;
	Enabled2 = true;
	Enabled3 = false;

	//Cache cvars
	SetConVarString(FindConVar("ff2_version"), PLUGIN_VERSION);
	Announce = cvarAnnounce.FloatValue;
	PointType = cvarPointType.IntValue;
	PointDelay = cvarPointDelay.IntValue;
	GoombaDamage = cvarGoombaDamage.FloatValue;
	reboundPower = cvarGoombaRebound.FloatValue;
	SniperDamage = cvarSniperDamage.FloatValue;
	SniperMiniDamage = cvarSniperMiniDamage.FloatValue;
	BowDamage = cvarBowDamage.FloatValue;
	BowDamageNon = cvarBowDamageNon.FloatValue;
	BowDamageMini = cvarBowDamageMini.FloatValue;
	SniperClimbDamage = cvarSniperClimbDamage.FloatValue;
	SniperClimbDelay = cvarSniperClimbDelay.FloatValue;
	QualityWep = cvarQualityWep.IntValue;
	canBossRTD = cvarBossRTD.BoolValue;
	AliveToEnable = cvarAliveToEnable.FloatValue;
	PointsInterval = cvarPointsInterval.IntValue;
	PointsInterval2 = cvarPointsInterval.FloatValue;
	PointsDamage = cvarPointsDamage.IntValue;
	PointsMin = cvarPointsMin.IntValue;
	PointsExtra = cvarPointsExtra.IntValue;
	arenaRounds = cvarArenaRounds.IntValue;
	circuitStun = cvarCircuitStun.FloatValue;
	countdownHealth = cvarCountdownHealth.IntValue;
	countdownPlayers = cvarCountdownPlayers.FloatValue;
	countdownTime = cvarCountdownTime.IntValue;
	countdownOvertime = cvarCountdownOvertime.BoolValue;
	lastPlayerGlow = cvarLastPlayerGlow.FloatValue;
	bossTeleportation = cvarBossTeleporter.IntValue;
	shieldCrits = cvarShieldCrits.IntValue;
	allowedDetonations = cvarCaberDetonations.IntValue;
	Annotations = cvarAnnotations.IntValue;
	TellName = cvarTellName.BoolValue;

	//Set some Valve cvars to what we want them to be
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
	SetConVarString(FindConVar("mp_humans_must_join_team"), "any");

	cvarTags = FindConVar("sv_tags");
	Utils_AddServerTag("ff2");
	Utils_AddServerTag("hale");
	Utils_AddServerTag("vsh");

	float time = Announce;
	if(time > 1.0)
		CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	CacheWeapons();
	CacheDifficulty();
	Utils_CheckToChangeMapDoors();
	Utils_CheckToTeleportToSpawn();
	Utils_MapHasMusic(true);
	FindCharacters();
	FF2CharSetString[0] = 0;

	#if !defined _smac_included
	if(smac && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
	{
		ServerCommand("smac_removecvar sv_cheats");
		ServerCommand("smac_removecvar host_timescale");
	}
	#endif

	bMedieval = FindEntityByClassname(-1, "tf_logic_medieval")!=-1 || GetConVarBool(FindConVar("tf_medieval"));
	FindHealthBar();

	changeGamemode = 0;

	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client))
			OnClientPostAdminCheck(client);
	}

	EnabledDesc = true;
	if(cvarSteamTools.BoolValue)
	{
		char gameDesc[64];
		if(TimesTen)
		{
			FormatEx(gameDesc, sizeof(gameDesc), "Freak Fortress 2 x10 (%s)", PLUGIN_VERSION);
		}
		else
		{
			FormatEx(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
		}

		#if defined _SteamWorks_Included
		if(steamworks)
		{
			SteamWorks_SetGameDescription(gameDesc);
			return;
		}
		#endif

		#if defined _steamtools_included
		if(steamtools)
		{
			Steam_SetGameDescription(gameDesc);
		}
		#endif
	}
}

void DisableFF2()
{
	Enabled = false;
	Enabled2 = false;
	Enabled3 = false;

	DisableSubPlugins();

	SetConVarInt(FindConVar("tf_arena_use_queue"), tf_arena_use_queue);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), mp_teams_unbalance_limit);
	SetConVarInt(FindConVar("tf_arena_first_blood"), tf_arena_first_blood);
	SetConVarInt(FindConVar("mp_forcecamera"), mp_forcecamera);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), tf_dropped_weapon_lifetime);
	SetConVarString(FindConVar("mp_humans_must_join_team"), mp_humans_must_join_team);
	hostName.SetString(oldName);

	Utils_RemoveServerTag("ff2");
	Utils_RemoveServerTag("hale");
	Utils_RemoveServerTag("vsh");

	if(doorCheckTimer != INVALID_HANDLE)
	{
		KillTimer(doorCheckTimer);
		doorCheckTimer = INVALID_HANDLE;
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client))
			DataBase_SaveClientPreferences(client);

		if(MusicTimer[client] != null)
		{
			delete MusicTimer[client];
		}
	}

	#if !defined _smac_included
	if(smac && FindPluginByFile("smac_cvars.smx") != INVALID_HANDLE)
	{
		ServerCommand("smac_addcvar sv_cheats replicated ban 0 0");
		ServerCommand("smac_addcvar host_timescale replicated ban 1.0 1.0");
	}
	#endif

	changeGamemode = 0;

	if(EnabledDesc && cvarSteamTools.BoolValue)
	{
		#if defined _SteamWorks_Included
		if(steamworks)
		{
			SteamWorks_SetGameDescription("Team Fortress");
			EnabledDesc = false;
			return;
		}
		#endif

		#if defined _steamtools_included
		if(steamtools)
			Steam_SetGameDescription("Team Fortress");
		#endif
	}
	EnabledDesc = false;
}

void CheckArena()
{
	float PointTotal = float(PointTime+PointDelay*(playing-1));
	if(!PointType || PointTotal<0)
	{
		Utils_SetArenaCapEnableTime(0.0);
		Utils_SetControlPoint(false);
	}
	else
	{
		Utils_SetArenaCapEnableTime(PointTotal);
	}
}

public Action FF2_OnSpecialSelected(int boss, int &SpecialNum, char[] SpecialName, bool preset)
{
	int client = Boss[boss];
	if((!boss || boss==MAXBOSSES) && (IgnoreValid[client] || Utils_CheckValidBoss(client, xIncoming[client], !DuoMin)) && cvarSelectBoss.BoolValue && CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		if(preset)
		{
			FPrintToChat(client, "%t", "boss_selection_overridden");
		}
		else
		{
			strcopy(SpecialName, sizeof(xIncoming[]), xIncoming[client]);
			if(cvarKeepBoss.IntValue<1 || !cvarSelectBoss.BoolValue || IsFakeClient(client))
			{
				xIncoming[client][0] = 0;
				CanBossVs[client] = 0;
				CanBossTeam[client] = 0;
				IgnoreValid[client] = false;
				DataBase_SaveKeepBossCookie(client);
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}


/*
    TeleportToMultiMapSpawn()
    [X][2]
       [0] = RED spawnpoint entref
       [1] = BLU spawnpoint entref
*/
static ArrayList s_hSpawnArray = null;

static void OnPluginStart_TeleportToMultiMapSpawn()
{
	s_hSpawnArray = new ArrayList(2);
}

void teamplay_round_start_TeleportToMultiMapSpawn()
{
	s_hSpawnArray.Clear();
	int iInt=0, iEnt=MaxClients+1;
	int iSkip[MAXTF2PLAYERS]={0,...};
	while((iEnt = Utils_FindEntityByClassname2(iEnt, "info_player_teamspawn")) != -1)
	{
		TFTeam iTeam = Utils_GetEntityTeamNum(iEnt);
		int iClient = Utils_GetClosestPlayerTo(iEnt, iTeam);
		if(iClient)
		{
			bool bSkip = false;
			for(int i = 0; i<=MaxClients; i++)
			{
				if(iSkip[i] == iClient)
				{
					bSkip = true;
					break;
				}
			}
			if(bSkip)
				continue;

			iSkip[iInt++] = iClient;
			int iIndex = s_hSpawnArray.Push(EntIndexToEntRef(iEnt));
			s_hSpawnArray.Set(iIndex, iTeam, 1);	// Opposite team becomes an invalid ent
		}
	}
}

/*
    Teleports a client to spawn, but only if it's a spawn that someone spawned in at the start of the round.
    Useful for multi-stage maps like vsh_megaman
*/
int TeleportToMultiMapSpawn(int iClient, TFTeam iTeam=TFTeam_Unassigned)
{
	int iSpawn, iIndex;
	TFTeam iTeleTeam;
	if(iTeam <= TFTeam_Spectator)
	{
		iSpawn = EntRefToEntIndex(GetRandBlockCellEx(s_hSpawnArray));
	}
	else
	{
		do
			iTeleTeam = view_as<TFTeam>(Utils_GetRandBlockCell(s_hSpawnArray, iIndex, 1));
		while (iTeleTeam != iTeam);
		iSpawn = EntRefToEntIndex(GetArrayCell(s_hSpawnArray, iIndex, 0));
	}
	Utils_TeleMeToYou(iClient, iSpawn);
	return iSpawn;
}


void CheckDuoMin()
{
	int i;
	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client) && GetClientTeam(client)>view_as<int>(TFTeam_Spectator))
		{
			i++;
			if(i >= cvarDuoMin.IntValue)
			{
				DuoMin = true;
				return;
			}
		}
	}
	DuoMin = false;
}

#include <freak_fortress_2_vsh_feedback>
