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
#include "impl/logs.sp"

#include "impl/database_vars.sp"
#include "impl/convars_vars.sp"

#include "impl/huds.sp"
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
	url		=	"https://forums.alliedmods.net/forumdisplay.php?f=154"
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

	FF2Globals.Init();
	FF2PlayerInfo[0].Init();

	FF2Globals.PluginLateLoaded = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	LogMessage("Freak Fortress 2 "... PLUGIN_VERSION ..." Loading...");

	FF2LogsPaths.Init();
		
	FF2SavedAbility = new FF2SavedAbility_t();
	
	ConVars_CreateConvars();
	
	Events_HookGameEvents();
	
	OnPluginStart_TeleportToMultiMapSpawn();	// Setup adt_array

	ConVars_AddCommandHooks();
	
	ConVars_AddChangeHooks();
	ConVars_CreateCommands();
	
	FF2Globals.ReloadFF2 = false;
	FF2Globals.ReloadWeapons = false;
	FF2Globals.ReloadConfigs = false;

	AutoExecConfig(true, "FreakFortress2");

	DataBase_CreateCookies();
	
	FF2Huds.Init();

	char oldVersion[64];
	ConVars.Version.GetString(oldVersion, 64);
	if(strcmp(oldVersion, PLUGIN_VERSION, false))
		LogToFile(FF2LogsPaths.Errors, "[Config] Warning: Your config may be outdated. Back up tf/cfg/sourcemod/FreakFortress2.cfg and delete it, and this plugin will generate a new one that you can then modify to your original values.");

	LoadTranslations("freak_fortress_2.phrases");
	LoadTranslations("freak_fortress_2_prefs.phrases");
	LoadTranslations("freak_fortress_2_stats.phrases");
	LoadTranslations("freak_fortress_2_weaps.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	if(FF2Globals.PluginLateLoaded)
		OnMapStart();

	AddNormalSoundHook(HookSound);

	#if defined _steamtools_included
	FF2Globals.SteamTools = LibraryExists("SteamTools");
	#endif

	#if defined _SteamWorks_Included
	FF2Globals.SteamWorks = LibraryExists("SteamWorks");
	#endif

	#if defined _goomba_included
	FF2Globals.Goomba = LibraryExists("goomba");
	#endif

	#if defined _tf2attributes_included
	FF2Globals.TF2Attrib = LibraryExists("tf2attributes");
	#endif

	FF2Globals.Isx10 = LibraryExists("tf2x10");

	Handle gameData = LoadGameConfigFile("equipwearable");
	if(gameData == INVALID_HANDLE)
	{
		LogToFile(FF2LogsPaths.Errors, "[Gamedata] Failed to find equipwearable.txt");
		return;
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameData, SDKConf_Virtual, "CBasePlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	FF2ModsInfo.SDK_EquipWearable = EndPrepSDKCall();
	if(FF2ModsInfo.SDK_EquipWearable == null)
		LogToFile(FF2LogsPaths.Errors, "[Gamedata] Failed to create call: CBasePlayer::EquipWearable");

	delete gameData;
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "tf2x10", false))
	{
		FF2Globals.Isx10 = true;
	}
	#if defined _steamtools_included
	else if(StrEqual(name, "SteamTools", false))
	{
		FF2Globals.SteamTools = true;
	}
	#endif
	#if defined _SteamWorks_Included
	else if(StrEqual(name, "SteamWorks", false))
	{
		FF2Globals.SteamWorks = true;
	}
	#endif
	#if defined _tf2attributes_included
	else if(StrEqual(name, "FF2Globals.TF2Attrib", false))
	{
		FF2Globals.TF2Attrib = true;
	}
	#endif
	#if defined _goomba_included
	else if(StrEqual(name, "goomba", false))
	{
		FF2Globals.Goomba = true;
	}
	#endif
	#if !defined _smac_included
	else if(StrEqual(name, "smac", false))
	{
		FF2Globals.SMAC = true;
	}
	#endif
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "tf2x10", false))
	{
		FF2Globals.Isx10 = false;
	}
	#if defined _steamtools_included
	else if(StrEqual(name, "SteamTools", false))
	{
		FF2Globals.SteamTools = false;
	}
	#endif
	#if defined _SteamWorks_Included
	else if(StrEqual(name, "SteamWorks", false))
	{
		FF2Globals.SteamWorks = false;
	}
	#endif
	#if defined _tf2attributes_included
	else if(StrEqual(name, "FF2Globals.TF2Attrib", false))
	{
		FF2Globals.TF2Attrib = false;
	}
	#endif
	#if defined _goomba_included
	else if(StrEqual(name, "goomba", false))
	{
		FF2Globals.Goomba = false;
	}
	#endif
	#if !defined _smac_included
	else if(StrEqual(name, "smac", false))
	{
		FF2Globals.SMAC = false;
	}
	#endif
}

public void OnConfigsExecuted()
{
	FF2GlobalsCvars.tf_arena_use_queue = GetConVarInt(FindConVar("tf_arena_use_queue"));
	FF2GlobalsCvars.mp_teams_unbalance_limit = GetConVarInt(FindConVar("mp_teams_unbalance_limit"));
	FF2GlobalsCvars.tf_arena_first_blood = GetConVarInt(FindConVar("tf_arena_first_blood"));
	FF2GlobalsCvars.mp_forcecamera = GetConVarInt(FindConVar("mp_forcecamera"));
	FF2GlobalsCvars.tf_dropped_weapon_lifetime = GetConVarInt(FindConVar("tf_dropped_weapon_lifetime"));
	GetConVarString(FindConVar("mp_humans_must_join_team"), FF2GlobalsCvars.mp_humans_must_join_team, sizeof(FF2GlobalsCvars.mp_humans_must_join_team));
	GetConVarString(FF2ModsInfo.cvarHostName=FindConVar("hostname"), FF2ModsInfo.OldHostName, sizeof(FF2ModsInfo.OldHostName));

	if(ConVars.Enabled.IntValue>1 || (Utils_IsFF2Map(FF2Globals.CurrentMap) && ConVars.Enabled.IntValue>0))
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
	FF2ModsInfo.cvarHostName.SetString(FF2ModsInfo.OldHostName);
	if(!FF2Globals.ReloadFF2 && Utils_CheckRoundState()==1)
	{
		Utils_ForceTeamWin(0);
		FPrintToChatAll("The plugin has been unexpectedly unloaded!");
	}
}

void EnableFF2()
{
	FF2Globals.Enabled = true;
	FF2Globals.Enabled2 = true;
	FF2Globals.Enabled3 = false;

	//Cache cvars
	SetConVarString(FindConVar("ff2_version"), PLUGIN_VERSION);
	FF2GlobalsCvars.Announce = ConVars.Announce.FloatValue;
	FF2GlobalsCvars.PointType = ConVars.PointType.IntValue;
	FF2GlobalsCvars.PointDelay = ConVars.PointDelay.IntValue;
	FF2GlobalsCvars.GoombaDmg = ConVars.GoombaDamage.FloatValue;
	FF2GlobalsCvars.ReboundPower = ConVars.GoombaRebound.FloatValue;
	FF2GlobalsCvars.SniperDmg = ConVars.SniperDamage.FloatValue;
	FF2GlobalsCvars.SniperMiniDmg = ConVars.SniperMiniDamage.FloatValue;
	FF2GlobalsCvars.BowDmg = ConVars.BowDamage.FloatValue;
	FF2GlobalsCvars.BowDmgNon = ConVars.BowDamageNon.FloatValue;
	FF2GlobalsCvars.BowDmgMini = ConVars.BowDamageMini.FloatValue;
	FF2GlobalsCvars.SniperClimpDmg = ConVars.SniperClimbDamage.FloatValue;
	FF2GlobalsCvars.SniperClimpDelay = ConVars.SniperClimbDelay.FloatValue;
	FF2GlobalsCvars.WeaponQuality = ConVars.QualityWep.IntValue;
	FF2GlobalsCvars.CanBossRTD = ConVars.BossRTD.BoolValue;
	FF2GlobalsCvars.AliveToEnable = ConVars.AliveToEnable.FloatValue;
	FF2GlobalsCvars.PointsInterval = ConVars.PointsInterval.IntValue;
	FF2GlobalsCvars.PointsInterval2 = ConVars.PointsInterval.FloatValue;
	FF2GlobalsCvars.PointsDmg = ConVars.PointsDamage.IntValue;
	FF2GlobalsCvars.PointsMin = ConVars.PointsMin.IntValue;
	FF2GlobalsCvars.PointsExtra = ConVars.PointsExtra.IntValue;
	FF2GlobalsCvars.ArenaRounds = ConVars.ArenaRounds.IntValue;
	FF2GlobalsCvars.CircuitStun = ConVars.CircuitStun.FloatValue;
	FF2GlobalsCvars.CountdownHealth = ConVars.CountdownHealth.IntValue;
	FF2GlobalsCvars.CountdownPlayers = ConVars.CountdownPlayers.FloatValue;
	FF2GlobalsCvars.CountdownTime = ConVars.CountdownTime.IntValue;
	FF2GlobalsCvars.CountdownOvertime = ConVars.CountdownOvertime.BoolValue;
	FF2GlobalsCvars.LastPlayerGlow = ConVars.LastPlayerGlow.FloatValue;
	FF2GlobalsCvars.BossTeleportation = ConVars.BossTeleporter.IntValue;
	FF2GlobalsCvars.ShieldCrits = ConVars.ShieldCrits.IntValue;
	FF2GlobalsCvars.AllowedDetonation = ConVars.CaberDetonations.IntValue;
	FF2GlobalsCvars.Annotations = ConVars.Annotations.IntValue;
	FF2GlobalsCvars.TellName = ConVars.TellName.BoolValue;

	//Set some Valve cvars to what we want them to be
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_forcecamera"), 0);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
	SetConVarString(FindConVar("mp_humans_must_join_team"), "any");

	ConVars.Tags = FindConVar("sv_tags");
	Utils_AddServerTag("ff2");
	Utils_AddServerTag("hale");
	Utils_AddServerTag("vsh");

	float time = FF2GlobalsCvars.Announce;
	if(time > 1.0)
		CreateTimer(time, Timer_Announce, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	CacheWeapons();
	CacheDifficulty();
	Utils_CheckToChangeMapDoors();
	Utils_CheckToTeleportToSpawn();
	Utils_MapHasMusic(true);
	FindCharacters();
	FF2CharSetInfo.CurrentCharSet[0] = 0;

	#if !defined _smac_included
	if(FF2Globals.SMAC && FindPluginByFile("smac_cvars.smx")!=INVALID_HANDLE)
	{
		ServerCommand("smac_removecvar sv_cheats");
		ServerCommand("smac_removecvar host_timescale");
	}
	#endif

	FF2Globals.IsMedival = FindEntityByClassname(-1, "tf_logic_medieval")!=-1 || GetConVarBool(FindConVar("tf_medieval"));
	FindHealthBar();

	FF2ModsInfo.ChangeGamemode = 0;

	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client))
			OnClientPostAdminCheck(client);
	}

	FF2Globals.ChangedDescription = true;
	if(ConVars.SteamTools.BoolValue)
	{
		char gameDesc[64];
		if(FF2Globals.Isx10)
		{
			FormatEx(gameDesc, sizeof(gameDesc), "Freak Fortress 2 x10 (%s)", PLUGIN_VERSION);
		}
		else
		{
			FormatEx(gameDesc, sizeof(gameDesc), "Freak Fortress 2 (%s)", PLUGIN_VERSION);
		}

		#if defined _SteamWorks_Included
		if(FF2Globals.SteamWorks)
		{
			SteamWorks_SetGameDescription(gameDesc);
			return;
		}
		#endif

		#if defined _steamtools_included
		if(FF2Globals.SteamTools)
		{
			Steam_SetGameDescription(gameDesc);
		}
		#endif
	}
}

void DisableFF2()
{
	FF2Globals.Enabled = false;
	FF2Globals.Enabled2 = false;
	FF2Globals.Enabled3 = false;

	DisableSubPlugins();

	SetConVarInt(FindConVar("tf_arena_use_queue"), FF2GlobalsCvars.tf_arena_use_queue);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), FF2GlobalsCvars.mp_teams_unbalance_limit);
	SetConVarInt(FindConVar("tf_arena_first_blood"), FF2GlobalsCvars.tf_arena_first_blood);
	SetConVarInt(FindConVar("mp_forcecamera"), FF2GlobalsCvars.mp_forcecamera);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), FF2GlobalsCvars.tf_dropped_weapon_lifetime);
	SetConVarString(FindConVar("mp_humans_must_join_team"), FF2GlobalsCvars.mp_humans_must_join_team);
	FF2ModsInfo.cvarHostName.SetString(FF2ModsInfo.OldHostName);

	Utils_RemoveServerTag("ff2");
	Utils_RemoveServerTag("hale");
	Utils_RemoveServerTag("vsh");

	if(FF2Globals.DoorCheckTimer != INVALID_HANDLE)
	{
		KillTimer(FF2Globals.DoorCheckTimer);
		FF2Globals.DoorCheckTimer = INVALID_HANDLE;
	}

	for(int client=1; client<=MaxClients; client++)
	{
		if(Utils_IsValidClient(client))
			DataBase_SaveClientPreferences(client);

		if(FF2PlayerInfo[client].MusicTimer != null)
		{
			delete FF2PlayerInfo[client].MusicTimer;
		}
	}

	#if !defined _smac_included
	if(FF2Globals.SMAC && FindPluginByFile("smac_cvars.smx") != INVALID_HANDLE)
	{
		ServerCommand("smac_addcvar sv_cheats replicated ban 0 0");
		ServerCommand("smac_addcvar host_timescale replicated ban 1.0 1.0");
	}
	#endif

	FF2ModsInfo.ChangeGamemode = 0;

	if(FF2Globals.ChangedDescription && ConVars.SteamTools.BoolValue)
	{
		#if defined _SteamWorks_Included
		if(FF2Globals.SteamWorks)
		{
			SteamWorks_SetGameDescription("Team Fortress");
			FF2Globals.ChangedDescription = false;
			return;
		}
		#endif

		#if defined _steamtools_included
		if(FF2Globals.SteamTools)
			Steam_SetGameDescription("Team Fortress");
		#endif
	}
	FF2Globals.ChangedDescription = false;
}

void CheckArena()
{
	float PointTotal = float(FF2GlobalsCvars.PointTime+FF2GlobalsCvars.PointDelay*(FF2Globals.TotalPlayers-1));
	if(!FF2GlobalsCvars.PointType || PointTotal<0)
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
	int client = FF2BossInfo[boss].Boss;
	if((!boss || boss==MAXBOSSES) && (IgnoreValid[client] || Utils_CheckValidBoss(client, xIncoming[client], !FF2GlobalsCvars.DuoMin)) && ConVars.SelectBoss.BoolValue && CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		if(preset)
		{
			FPrintToChat(client, "%t", "boss_selection_overridden");
		}
		else
		{
			strcopy(SpecialName, sizeof(xIncoming[]), xIncoming[client]);
			if(ConVars.KeepBoss.IntValue<1 || !ConVars.SelectBoss.BoolValue || IsFakeClient(client))
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
			if(i >= ConVars.DuoMin.IntValue)
			{
				FF2GlobalsCvars.DuoMin = true;
				return;
			}
		}
	}
	FF2GlobalsCvars.DuoMin = false;
}

#include <freak_fortress_2_vsh_feedback>
