void ConVars_CreateConvars()
{
    ConVars.Version = CreateConVar("ff2_version", PLUGIN_VERSION, "Freak Fortress 2 Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
    ConVars.Charset = CreateConVar("ff2_current", "0", "Freak Fortress 2 Current Boss Pack", FCVAR_SPONLY|FCVAR_DONTRECORD);
    ConVars.PointType = CreateConVar("ff2_point_type", "0", "0-Use ff2_point_alive, 1-Use ff2_point_time, 2-Use both", _, true, 0.0, true, 2.0);
    ConVars.PointDelay = CreateConVar("ff2_point_delay", "6", "Seconds to add to ff2_point_time per player");
    ConVars.PointTime = CreateConVar("ff2_point_time", "45", "Time before unlocking the control point");
    ConVars.AliveToEnable = CreateConVar("ff2_point_alive", "0.2", "The control point will only activate when there are this many people or less left alive, can be a ratio", _, true, 0.0, true, 34.0);
    ConVars.Announce = CreateConVar("ff2_announce", "120", "Amount of seconds to wait until FF2 info is displayed again.  0 to disable", _, true, 0.0);
    ConVars.AnnounceAds = CreateConVar("ff2_announce_ads", "1", "0-Disable mentioning authors/links, 1-Mention authors/links", _, true, 0.0, true, 1.0);
    ConVars.Enabled = CreateConVar("ff2_enabled", "1", "0-Force Disable, 1-Standby, 2-Force Enable", FCVAR_DONTRECORD, true, 0.0, true, 2.0);
    ConVars.Crits = CreateConVar("ff2_crits", "0", "Can the boss get random crits?", _, true, 0.0, true, 1.0);
    ConVars.ArenaRounds = CreateConVar("ff2_arena_rounds", "1", "Number of rounds to make arena before switching to FF2 (helps for slow-loading players)", _, true, 0.0);
    ConVars.CircuitStun = CreateConVar("ff2_circuit_stun", "0", "Amount of seconds the Short Circuit stuns the boss for.  0 to disable", _, true, 0.0);
    ConVars.CountdownPlayers = CreateConVar("ff2_countdown_players", "1", "Amount of players until the countdown timer starts, can be a ratio", _, true, 0.0, true, 34.0);
    ConVars.CountdownTime = CreateConVar("ff2_countdown", "120", "Amount of seconds until the round ends in a stalemate");
    ConVars.CountdownHealth = CreateConVar("ff2_countdown_health", "2000", "Amount of health the Boss has remaining until the countdown stops", _, true, 0.0);
    ConVars.CountdownResult = CreateConVar("ff2_countdown_result", "0", "0-Kill players when the countdown ends, 1-End the round in a stalemate", _, true, 0.0, true, 1.0);
    ConVars.SpecForceBoss = CreateConVar("ff2_spec_force_boss", "0", "0-Spectators are excluded from the queue system, 1-Spectators are counted in the queue system", _, true, 0.0, true, 1.0);
    ConVars.EnableEurekaEffect = CreateConVar("ff2_enable_eureka", "0", "0-Disable the Eureka Effect, 1-Enable the Eureka Effect", _, true, 0.0, true, 1.0);
    ConVars.ForceBossTeam = CreateConVar("ff2_force_team", "0", "0-Boss is always on Blu, 1-Boss is on a random team each round, 2-Boss is always on Red", _, true, 0.0, true, 3.0);
    ConVars.HealthBar = CreateConVar("ff2_health_bar", "1", "0-Disable the health bar, 1-Show the health bar without lives, 2-Show the health bar with lives", _, true, 0.0, true, 2.0);
    ConVars.LastPlayerGlow = CreateConVar("ff2_last_player_glow", "1", "How many players left before outlining everyone, can be a ratio", _, true, 0.0, true, 34.0);
    ConVars.BossTeleporter = CreateConVar("ff2_boss_teleporter", "0", "-1 to disallow all FF2Globals.Bosses from using teleporters, 0 to use TF2 logic, 1 to allow all FF2Globals.Bosses", _, true, -1.0, true, 1.0);
    ConVars.BossSuicide = CreateConVar("ff2_boss_suicide", "0", "Allow the boss to suicide after the round starts?", _, true, 0.0, true, 1.0);
    ConVars.PreroundBossDisconnect = CreateConVar("ff2_replace_disconnected_boss", "0", "If a boss disconnects before the round starts, use the next player in line instead? 0 - No, 1 - Yes", _, true, 0.0, true, 1.0);
    ConVars.Changelog = CreateConVar("ff2_changelog_url", CHANGELOG_URL, "FF2 Changelog URL. Normally you are not supposed to change this...", FCVAR_SPONLY|FCVAR_DONTRECORD);
    ConVars.CaberDetonations = CreateConVar("ff2_caber_detonations", "1", "Amount of times somebody can detonate the Ullapool Caber (0 = Infinite)", _, true, 0.0);
    ConVars.ShieldCrits = CreateConVar("ff2_shield_crits", "0", "0 to disable grenade launcher crits when equipping a shield, 1 for minicrits, 2 for crits", _, true, 0.0, true, 2.0);
    ConVars.GoombaDamage = CreateConVar("ff2_goomba_damage", "0.05", "How much the Goomba damage should be multipled by when FF2Globals.Goomba stomping the boss (requires Goomba Stomp)", _, true, 0.01, true, 1.0);
    ConVars.GoombaRebound = CreateConVar("ff2_goomba_jump", "300.0", "How high players should rebound after FF2Globals.Goomba stomping the boss (requires Goomba Stomp)", _, true, 0.0);
    ConVars.BossRTD = CreateConVar("ff2_boss_rtd", "0", "Can the boss use rtd? 0 to disallow boss, 1 to allow boss (requires RTD)", _, true, 0.0, true, 1.0);
    ConVars.DeadRingerHud = CreateConVar("ff2_deadringer_hud", "1", "Dead Ringer indicator? 0 to disable, 1 to enable", _, true, 0.0, true, 1.0);
    ConVars.Debug = CreateConVar("ff2_debug", "0", "0-Disable FF2 debug output, 1-Enable debugging (not recommended)", _, true, 0.0, true, 1.0);
    ConVars.Dmg2KStreak = CreateConVar("ff2_dmg_kstreak", "250", "Minimum damage to increase killstreak count", _, true, 0.0);
    ConVars.AirStrike = CreateConVar("ff2_dmg_airstrike", "250", "Minimum damage to increase head count for the Air-Strike", _, true, 0.0);
    ConVars.SniperDamage = CreateConVar("ff2_sniper_dmg", "2.0", "Sniper Rifle normal multiplier", _, true, 0.0);
    ConVars.SniperMiniDamage = CreateConVar("ff2_sniper_dmg_mini", "2.0", "Sniper Rifle mini-crit multiplier", _, true, 0.0);
    ConVars.BowDamage = CreateConVar("ff2_bow_dmg", "1.25", "Huntsman critical multiplier", _, true, 0.0);
    ConVars.BowDamageNon = CreateConVar("ff2_bow_dmg_non", "0.0", "If not zero Huntsman has no crit boost, Huntsman normal non-crit multiplier", _, true, 0.0);
    ConVars.BowDamageMini = CreateConVar("ff2_bow_dmg_mini", "0.0", "If not zero Huntsman is mini-crit boosted, Huntsman normal mini-crit multiplier", _, true, 0.0);
    ConVars.SniperClimbDamage = CreateConVar("ff2_sniper_climb_dmg", "15.0", "Damage taken during climb", _, true, 0.0);
    ConVars.SniperClimbDelay = CreateConVar("ff2_sniper_climb_delay", "1.56", "0-Disable Climbing, Delay between climbs", _, true, 0.0);
    ConVars.StrangeWep = CreateConVar("ff2_strangewep", "1", "0-Disable Boss Weapon Stranges, 1-Enable Boss Weapon Stranges", _, true, 0.0, true, 1.0);
    ConVars.QualityWep = CreateConVar("ff2_qualitywep", "5", "Default Boss Weapon Quality", _, true, 0.0, true, 15.0);
    ConVars.TripleWep = CreateConVar("ff2_triplewep", "1", "0-Disable Boss Extra Triple Damage, 1-Enable Boss Extra Triple Damage", _, true, 0.0, true, 1.0);
    ConVars.HardcodeWep = CreateConVar("ff2_hardcodewep", "1", "0-Only Use Config, 1-Use Alongside Hardcoded, 2-Only Use Hardcoded", _, true, 0.0, true, 2.0);
    ConVars.SelfKnockback = CreateConVar("ff2_selfknockback", "0", "0-Disallow boss self knockback, 1-Allow boss self knockback, 2-Allow boss taking self damage too", _, true, 0.0, true, 2.0);
    ConVars.FF2TogglePrefDelay = CreateConVar("ff2_boss_toggle_delay", "45.0", "Delay between joining the server and asking the player for their preference, if it is not set.");
    ConVars.NameChange = CreateConVar("ff2_name_change", "0", "0-Disable, 1-Add the current boss to the server name, 2-Add the current charset to the server name", _, true, 0.0, true, 2.0);
    ConVars.KeepBoss = CreateConVar("ff2_boss_keep", "1", "-1-Players can't choose the same boss twice, 0-Nothing, 1-Players keep their current boss selection", _, true, -1.0, true, 1.0);
    ConVars.SelectBoss = CreateConVar("ff2_boss_select", "1", "0-Disable, 1-Players can select FF2Globals.Bosses", _, true, 0.0, true, 1.0);
    ConVars.ToggleBoss = CreateConVar("ff2_boss_toggle", "1", "0-Disable, 1-Players can toggle being the boss", _, true, 0.0, true, 1.0);
    ConVars.ToggleBoss = CreateConVar("ff2_boss_companion", "1", "0-Disable, 1-Players can toggle being a companion", _, true, 0.0, true, 1.0);
    ConVars.PointsInterval = CreateConVar("ff2_points_interval", "600", "Every this damage gives a point", _, true, 1.0);
    ConVars.PointsDamage = CreateConVar("ff2_points_damage", "0", "Damage required to earn queue points", _, true, 0.0);
    ConVars.PointsMin = CreateConVar("ff2_points_queue", "10", "Minimum queue points earned", _, true, 0.0);
    ConVars.PointsExtra = CreateConVar("ff2_points_bonus", "10", "Maximum queue points earned", _, true, 0.0);
    ConVars.AdvancedMusic = CreateConVar("ff2_advanced_music", "1", "0-Use classic menu, 1-Use new menu", _, true, 0.0, true, 1.0);
    ConVars.SongInfo = CreateConVar("ff2_song_info", "0", "-1-Never show song and artist in chat, 0-Only if boss has song and artist, 1-Always show song and artist in chat", _, true, -1.0, true, 1.0);
    ConVars.DuoRandom = CreateConVar("ff2_companion_random", "0", "0-Next player in queue, 1-Random player is the companion", _, true, 0.0, true, 1.0);
    ConVars.DuoMin = CreateConVar("ff2_companion_min", "4", "Minimum players required to enable duos", _, true, 1.0, true, 34.0);
    ConVars.DuoRestore = CreateConVar("ff2_companion_restore", "0", "0-Disable, 1-Companions don't lose queue points", _, true, 0.0, true, 1.0);
    ConVars.LowStab = CreateConVar("ff2_low_stab", "1", "0-Disable, 1-Low-player count stabs, market, and caber do more damage", _, true, 0.0, true, 1.0);
    ConVars.GameText = CreateConVar("ff2_text_game", "0", "For game messages: 0-Use HUD texts, 1-Use game_text_tf entities, 2-Include boss intro and timer too", _, true, 0.0, true, 2.0);
    ConVars.Annotations = CreateConVar("ff2_text_msg", "0", "For backstabs and such: 0-Use hint texts, 1-Use annotations, 2-Use game_text_tf entities", _, true, 0.0, true, 2.0);
    ConVars.TellName = CreateConVar("ff2_text_names", "1", "For backstabs and such: 0-Don't show player/boss names, 1-Show player/boss names", _, true, 0.0, true, 1.0);
    ConVars.ShieldType = CreateConVar("ff2_shield_type", "1", "0-None, 1-Breaks on any hit, 2-Breaks if it'll kill, 3-Breaks if shield HP is depleted or melee hit, 4-Breaks if shield or player HP is depleted", _, true, 0.0, true, 4.0);
    ConVars.ShieldHealth = CreateConVar("ff2_shield_health", "500", "Maximum amount of health a Shield has if ff2_shield_type is 3 or 4", _, true, 0.0);
    ConVars.ShieldResist = CreateConVar("ff2_shield_resistance", "0.75", "Maximum amount (inverted) precentage of damage resistance a Shield has if ff2_shield_type is 3 or 4", _, true, 0.0, true, 1.0);
    ConVars.CountdownOvertime = CreateConVar("ff2_countdown_overtime", "0", "0-Disable, 1-Delay 'ff2_countdown_result' action until control point is no longer being captured", _, true, 0.0, true, 1.0);
    ConVars.BossLog = CreateConVar("ff2_boss_log", "0", "0-Disable, #-Players required to enable logging", _, true, 0.0, true, 34.0);
    ConVars.BossDesc = CreateConVar("ff2_boss_desc", "1", "0-Disable, 1-Show boss description before selecting a boss", _, true, 0.0, true, 1.0);
    ConVars.RPSPoints = CreateConVar("ff2_rps_points", "0", "0-Disable, #-Queue points awarded / removed upon RPS", _, true, 0.0);
    ConVars.RPSLimit = CreateConVar("ff2_rps_limit", "0", "0-Disable, #-Number of times the boss loses before being slayed", _, true, 0.0);
    ConVars.RPSDivide = CreateConVar("ff2_rps_divide", "0", "0-Disable, 1-Divide current boss health with ff2_rps_limit", _, true, 0.0, true, 1.0);
    ConVars.HealingHud = CreateConVar("ff2_hud_heal", "0", "0-Disable, 1-Show player's healing in damage HUD with they done healing, 2-Always show", _, true, 0.0, true, 2.0);
    ConVars.SteamTools = CreateConVar("ff2_steam_tools", "1", "0-Disable, 1-Show 'Freak Fortress 2' in game description (requires SteamTools or SteamWorks)", _, true, 0.0, true, 1.0);
    ConVars.Sappers = CreateConVar("ff2_sapper", "0", "0-Disable, 1-Can sap the boss, 2-Can sap minions, 3-Can sap both", _, true, 0.0, true, 3.0);
    ConVars.SapperCooldown = CreateConVar("ff2_sapper_cooldown", "500", "0-No Cooldown, #-Damage needed to be able to use again", _, true, 0.0);
    ConVars.SapperStart = CreateConVar("ff2_sapper_starting", "0", "#-Damage needed for first usage (Not used if ff2_sapper or ff2_sapper_cooldown is 0)", _, true, 0.0);
    ConVars.Theme = CreateConVar("ff2_theme", "0", "0-No Theme, #-Flags of Themes", _, true, 0.0);
    ConVars.SelfHealing = CreateConVar("ff2_healing", "0", "0-Block Boss Healing, 1-Allow Self-Healing, 2-Allow Non-Self Healing, 3-Allow All Healing", _, true, 0.0, true, 3.0);
    ConVars.BotRage = CreateConVar("ff2_bot_rage", "1", "0-Disable, 1-Bots can use rage when ready", _, true, 0.0, true, 1.0);
    ConVars.DamageToTele = CreateConVar("ff2_tts_damage", "250.0", "Minimum damage boss needs to take in order to be teleported to spawn", _, true, 1.0);
    ConVars.StatHud = CreateConVar("ff2_hud_stats", "-1", "-1-Disable, 0-Only by ff2_stats_bosses override, 1-Show only to client, 2-Show to anybody", _, true, -1.0, true, 2.0);
    ConVars.StatPlayers = CreateConVar("ff2_stats_players", "6", "0-Disable, #-Players required to use StatTrak", _, true, 0.0, true, 34.0);
    ConVars.StatWin2Lose = CreateConVar("ff2_stats_chat", "-1", "-1-Disable, 0-Only by ff2_stats_bosses override, 1-Show only to client if changed, 2-Show to everybody if changed, 3-Show only to client, 4-Show to everybody", _, true, -1.0, true, 4.0);
    ConVars.HealthHud = CreateConVar("ff2_hud_health", "0", "0-Disable, 1-Show boss's lives left, 2-Show boss's total health", _, true, 0.0, true, 2.0);
    ConVars.LookHud = CreateConVar("ff2_hud_aiming", "0.0", "-1-No Range Limit, 0-Disable, #-Show teammate's stats by looking at them within this range", _, true, -1.0);
    ConVars.SkipBoss = CreateConVar("ff2_boss_skip", "0", "0-Disable, 1-Add menu option to skip being a boss", _, true, 0.0, true, 1.0);
    ConVars.BossVsBoss = CreateConVar("ff2_boss_vs_boss", "0", "0-Always Boss vs Players, #-Chance of Boss vs Boss, 100-Always Boss vs Boss", _, true, 0.0, true, 100.0);
    ConVars.BvBLose = CreateConVar("ff2_boss_vs_boss_lose", "0", "0-Lose when all of a team die, 1-Lose when all of a team's FF2Globals.Bosses die, 2-Lose when all the team's mercs die", _, true, 0.0, true, 2.0);
    ConVars.BvBChaos = CreateConVar("ff2_boss_vs_boss_count", "1", "How many FF2Globals.Bosses per a team are assigned?", _, true, 1.0, true, 34.0);
    ConVars.BvBMerc = CreateConVar("ff2_boss_vs_boss_damage", "1.0", "How much to multiply non-boss damage against non-boss while each team as a boss alive", _, true, 0.0);
    ConVars.BvBStat = CreateConVar("ff2_boss_vs_boss_stats", "0", "Should Boss vs Boss mode count towards StatTrak?", _, true, 0.0, true, 1.0);
    ConVars.TimesTen = CreateConVar("ff2_times_ten", "5.0", "Amount to multiply boss's health and ragedamage when TF2x10 is enabled", _, true, 0.0);
    ConVars.ShuffleCharset = CreateConVar("ff2_bosspack_vote", "0", "0-Random option and show all packs, #-Random amount of packs to choose", _, true, 0.0, true, 64.0);
    ConVars.Broadcast = CreateConVar("ff2_broadcast", "0", "0-Block round end sounds, 1-Play round end sounds", _, true, 0.0, true, 1.0);
    ConVars.Market = CreateConVar("ff2_market_garden", "1.0", "0-Disable market gardens, #-Damage ratio of market gardens", _, true, 0.0);
    ConVars.Cloak = CreateConVar("ff2_cloak_damage", "1.0", "#-Extra damage multipler or maximum damage taken for cloak watches from FF2Globals.Bosses", _, true, 0.0);
    ConVars.Ringer = CreateConVar("ff2_deadringer_damage", "1.0", "#-Extra damage multipler or maximum damage taken for dead ringers from FF2Globals.Bosses", _, true, 0.0);
    ConVars.Kunai = CreateConVar("ff2_kunai_health", "200", "#-Overheal gained via Conniver's Kunai");
    ConVars.KunaiMax = CreateConVar("ff2_kunai_max", "600", "#-Maximum overheal gained via Conniver's Kunai", _, true, 1.0);
    ConVars.Disguise = CreateConVar("ff2_disguise", "1", "0-Disable, 1-Enable disguises showing player models (requires FF2Globals.TF2Attrib)", _, true, 0.0, true, 1.0);
    ConVars.Diamond = CreateConVar("ff2_diamondback", "2", "#-Amount of revenge crits gained upon backstabbing a boss", _, true, 0.0);
    ConVars.CloakStun = CreateConVar("ff2_cloak_stun", "2.0", "#-Amount in seconds before allowing to cloak after a backstab", _, true, 0.0);
    ConVars.Database = CreateConVar("ff2_stats_database", "0", "0-Only Client Preferences, 1-SQL over Client Preferences, 2-Only SQL | Table is ff2_stattrak", _, true, 0.0, true, 2.0);
    ConVars.ChargeAngle = CreateConVar("ff2_charge_angle", "30", "View angle requirement to activate charge abilities", _, true, 0.0, true, 360.0);
    ConVars.Attributes = CreateConVar("ff2_attributes", "2 ; 3.1 ; 275 ; 1", "Default attributes assigned to FF2Globals.Bosses without 'override' setting");
    ConVars.StartingUber = CreateConVar("ff2_uber_start", "40.0", "Starting Ubercharge precentage on round start", _, true, 0.0, true, 100.0);
    ConVars.DamageHud = CreateConVar("ff2_damage_tracker", "0", "Default Damage Tracker value for players", _, true, 0.0, true, 9.0);
    ConVars.Telefrag = CreateConVar("ff2_telefrag_damage", "5000.0", "Damage dealt upon a Telefrag", _, true, 0.0);
    ConVars.Health = CreateConVar("ff2_health_formula", "(((760.8+n)*(n-1))^1.0341)+2046", "Default boss health formula");
    ConVars.RageDamage = CreateConVar("ff2_rage_formula", "1900.0", "Default boss ragedamage formula");
    ConVars.Difficulty = CreateConVar("ff2_difficulty_random", "0.0", "0-Players can set their difficulty, #-Chance of difficulty", _, true, 0.0, true, 100.0);
    ConVars.EnableSandmanStun = CreateConVar("ff2_enable_sandmanstun", "0", "0-Disable the Sandman stun ability, 1-Enable the Sandman stun ability", _, true, 0.0, true, 1.0);
    ConVars.ShowBossBlocked = CreateConVar("ff2_boss_show_in_blocked_maps", "1.0", "0-Bosses will not appear in !ff2boss if their config blocked the map. 1-Bosses will appear in !ff2boss as a disabled option.", _, true, 0.0, true, 1.0);

    //The following are used in various subplugins
    CreateConVar("ff2_oldjump", "1", "Use old Saxton Hale jump equations", _, true, 0.0, true, 1.0);
    CreateConVar("ff2_base_jumper_stun", "0", "Whether or not the Base Jumper should be disabled when a player gets stunned", _, true, 0.0, true, 1.0);
    CreateConVar("ff2_solo_shame", "0", "Always insult the boss for solo raging", _, true, 0.0, true, 1.0);
}

void ConVars_AddChangeHooks()
{
    ConVars.Enabled.AddChangeHook(CvarChange);
    ConVars.Announce.AddChangeHook(CvarChange);
    ConVars.CircuitStun.AddChangeHook(CvarChange);
    ConVars.HealthBar.AddChangeHook(CvarChange);
    ConVars.LastPlayerGlow.AddChangeHook(CvarChange);
    ConVars.SpecForceBoss.AddChangeHook(CvarChange);
    ConVars.BossTeleporter.AddChangeHook(CvarChange);
    ConVars.ShieldCrits.AddChangeHook(CvarChange);
    ConVars.CaberDetonations.AddChangeHook(CvarChange);
    ConVars.GoombaDamage.AddChangeHook(CvarChange);
    ConVars.GoombaRebound.AddChangeHook(CvarChange);
    ConVars.BossRTD.AddChangeHook(CvarChange);
    ConVars.SniperDamage.AddChangeHook(CvarChange);
    ConVars.SniperMiniDamage.AddChangeHook(CvarChange);
    ConVars.BowDamage.AddChangeHook(CvarChange);
    ConVars.BowDamageNon.AddChangeHook(CvarChange);
    ConVars.BowDamageMini.AddChangeHook(CvarChange);
    ConVars.SniperClimbDamage.AddChangeHook(CvarChange);
    ConVars.SniperClimbDelay.AddChangeHook(CvarChange);
    ConVars.QualityWep.AddChangeHook(CvarChange);
    ConVars.PointsInterval.AddChangeHook(CvarChange);
    ConVars.PointsDamage.AddChangeHook(CvarChange);
    ConVars.PointsMin.AddChangeHook(CvarChange);
    ConVars.PointsExtra.AddChangeHook(CvarChange);
    ConVars.DuoMin.AddChangeHook(CvarChange);
    ConVars.Annotations.AddChangeHook(CvarChange);
    ConVars.TellName.AddChangeHook(CvarChange);
    ConVars.HealthHud.AddChangeHook(CvarChange);
    ConVars.Database.AddChangeHook(CvarChange);
    ConVars.ChargeAngle.AddChangeHook(CvarChange);
    ConVars.Attributes.AddChangeHook(CvarChange);
    ConVars.StartingUber.AddChangeHook(CvarChange);
    ConVars.Health.AddChangeHook(CvarChange);
    ConVars.RageDamage.AddChangeHook(CvarChange);
    (ConVars.Nextmap=FindConVar("sm_nextmap")).AddChangeHook(CvarChangeNextmap);
}

void ConVars_CreateCommands()
{
	RegConsoleCmd("ff2", FF2Panel, "Menu of FF2 commands");
	RegConsoleCmd("ff2_hp", Command_GetHPCmd, "View the boss's current HP");
	RegConsoleCmd("ff2hp", Command_GetHPCmd, "View the boss's current HP");
	RegConsoleCmd("ff2_next", QueuePanelCmd, "View the queue point list");
	RegConsoleCmd("ff2next", QueuePanelCmd, "View the queue point list");
	RegConsoleCmd("ff2_classinfo", Command_HelpPanelClass, "View class or boss info");
	RegConsoleCmd("ff2classinfo", Command_HelpPanelClass, "View class or boss info");
	RegConsoleCmd("ff2_infotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("ff2infotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("ff2_new", NewPanelCmd, "View FF2 changelog");
	RegConsoleCmd("ff2new", NewPanelCmd, "View FF2 changelog");
	RegConsoleCmd("ff2music", MusicTogglePanelCmd, "View the music menu");
	RegConsoleCmd("ff2_music", MusicTogglePanelCmd, "View the music menu");
	RegConsoleCmd("ff2voice", VoiceTogglePanelCmd, "Toggle hearing boss monologues");
	RegConsoleCmd("ff2_voice", VoiceTogglePanelCmd, "Toggle hearing boss monologues");
	RegConsoleCmd("ff2_resetpoints", ResetQueuePointsCmd, "Reset your queue points");
	RegConsoleCmd("ff2resetpoints", ResetQueuePointsCmd, "Reset your queue points");
	RegConsoleCmd("ff2_boss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("ff2boss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("ff2toggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("ff2_toggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("ff2companion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("ff2_companion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("ff2_skipsong", Command_SkipSong, "Skip the current song");
	RegConsoleCmd("ff2skipsong", Command_SkipSong, "Skip the current song");
	RegConsoleCmd("ff2_shufflesong", Command_ShuffleSong, "Play a random song");
	RegConsoleCmd("ff2shufflesong", Command_ShuffleSong, "Play a random song");
	RegConsoleCmd("ff2_tracklist", Command_Tracklist, "View list of songs");
	RegConsoleCmd("ff2tracklist", Command_Tracklist, "View list of songs");
	RegConsoleCmd("ff2_hud", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("ff2hud", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("ff2_dmg", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("ff2dmg", Command_HudMenu, "Toggle specific HUD settings");

	RegConsoleCmd("hale", FF2Panel, "Menu of FF2 commands");
	RegConsoleCmd("hale_hp", Command_GetHPCmd, "View the boss's current HP");
	RegConsoleCmd("halehp", Command_GetHPCmd, "View the boss's current HP");
	RegConsoleCmd("hale_next", QueuePanelCmd, "View the queue point list");
	RegConsoleCmd("halenext", QueuePanelCmd, "View the queue point list");
	RegConsoleCmd("hale_classinfo", Command_HelpPanelClass, "View class or boss info");
	RegConsoleCmd("haleclassinfo", Command_HelpPanelClass, "View class or boss info");
	RegConsoleCmd("hale_infotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("haleinfotoggle", HelpPanel3Cmd, "Toggle viewing class or boss info");
	RegConsoleCmd("hale_new", NewPanelCmd, "View FF2 changelog");
	RegConsoleCmd("halenew", NewPanelCmd, "View FF2 changelog");
	RegConsoleCmd("halemusic", MusicTogglePanelCmd, "View the music menu");
	RegConsoleCmd("hale_music", MusicTogglePanelCmd, "View the music menu");
	RegConsoleCmd("halevoice", VoiceTogglePanelCmd, "Toggle hearing boss monologues");
	RegConsoleCmd("hale_voice", VoiceTogglePanelCmd, "Toggle hearing boss monologues");
	RegConsoleCmd("hale_resetpoints", ResetQueuePointsCmd, "Reset your queue points");
	RegConsoleCmd("haleresetpoints", ResetQueuePointsCmd, "Reset your queue points");
	RegConsoleCmd("hale_boss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("haleboss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("haletoggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("hale_toggle", BossMenu, "Toggle being a FF2 boss");
	RegConsoleCmd("halecompanion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("hale_companion", CompanionMenu, "Toggle being a FF2 companion");
	RegConsoleCmd("hale_skipsong", Command_SkipSong, "Skip the current song");
	RegConsoleCmd("haleskipsong", Command_SkipSong, "Skip the current song");
	RegConsoleCmd("hale_shufflesong", Command_ShuffleSong, "Play a random song");
	RegConsoleCmd("haleshufflesong", Command_ShuffleSong, "Play a random song");
	RegConsoleCmd("hale_tracklist", Command_Tracklist, "View list of songs");
	RegConsoleCmd("haletracklist", Command_Tracklist, "View list of songs");
	RegConsoleCmd("hale_hud", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("halehud", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("hale_dmg", Command_HudMenu, "Toggle specific HUD settings");
	RegConsoleCmd("haledmg", Command_HudMenu, "Toggle specific HUD settings");

	RegConsoleCmd("sm_setboss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("sm_boss", Command_SetMyBoss, "View FF2 Boss Preferences");
	RegConsoleCmd("nextmap", Command_Nextmap);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	RegAdminCmd("ff2_loadcharset", Command_LoadCharset, ADMFLAG_RCON, "Usage: ff2_loadcharset <charset>.  Forces FF2 to switch to a given character set without changing maps");
	RegAdminCmd("ff2_reloadcharset", Command_ReloadCharset, ADMFLAG_RCON, "Forces FF2 to reload the current character set");
	RegAdminCmd("ff2_reload", Command_ReloadFF2, ADMFLAG_ROOT, "Reloads FF2 safely and quietly");
	RegAdminCmd("ff2_reloadweapons", Command_ReloadFF2Weapons, ADMFLAG_RCON, "Reloads FF2 weapon configuration safely and quietly");
	RegAdminCmd("ff2_reloadconfigs", Command_ReloadFF2Configs, ADMFLAG_RCON, "Reloads ALL FF2 configs safely and quietly");

	RegAdminCmd("ff2_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage: ff2_special <boss>.  Forces next round to use that boss");
	RegAdminCmd("ff2_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage: ff2_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("ff2_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("ff2_start_music", Command_StartMusic, ADMFLAG_CHEATS, "Start the Boss's music");
	RegAdminCmd("ff2_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently FF2Globals.TotalPlayers Boss music");
	RegAdminCmd("ff2_resetqueuepoints", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("ff2_resetq", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("ff2_charset", Command_Charset, ADMFLAG_CHEATS, "Usage: ff2_charset <charset>.  Forces FF2 to use a given character set");
	RegAdminCmd("ff2_reload_subplugins", Command_ReloadSubPlugins, ADMFLAG_RCON, "Reload FF2's subplugins.");
	RegAdminCmd("ff2_setrage", Command_SetRage, ADMFLAG_CHEATS, "Usage: ff2_setrage <target> <percent>. Sets the RAGE to a boss player");
	RegAdminCmd("ff2_addrage", Command_AddRage, ADMFLAG_CHEATS, "Usage: ff2_addrage <target> <percent>. Gives RAGE to a boss player");
	RegAdminCmd("ff2_setinfiniterage", Command_SetInfiniteRage, ADMFLAG_CHEATS, "Usage: ff2_infiniterage <target>. Gives infinite RAGE to a boss player");
	RegAdminCmd("ff2_setcharge", Command_SetCharge, ADMFLAG_CHEATS, "Usage: ff2_setcharge <target> <slot> <percent>. Sets a boss's charge");
	RegAdminCmd("ff2_addcharge", Command_AddCharge, ADMFLAG_CHEATS, "Usage: ff2_addcharge <target> <slot> <percent>. Adds a boss's charge");
	RegAdminCmd("ff2_makeboss", Command_MakeBoss, ADMFLAG_CHEATS, "Usage: ff2_makeboss <target> [team]. Makes a player a boss.");

	RegAdminCmd("hale_select", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage: hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_special", Command_SetNextBoss, ADMFLAG_CHEATS, "Usage: hale_select <boss>.  Forces next round to use that boss");
	RegAdminCmd("hale_addpoints", Command_Points, ADMFLAG_CHEATS, "Usage: hale_addpoints <target> <points>.  Adds queue points to any player");
	RegAdminCmd("hale_point_enable", Command_Point_Enable, ADMFLAG_CHEATS, "Enable the control point if ff2_point_type is 0");
	RegAdminCmd("hale_point_disable", Command_Point_Disable, ADMFLAG_CHEATS, "Disable the control point if ff2_point_type is 0");
	RegAdminCmd("hale_start_music", Command_StartMusic, ADMFLAG_CHEATS, "Start the Boss's music");
	RegAdminCmd("hale_stop_music", Command_StopMusic, ADMFLAG_CHEATS, "Stop any currently FF2Globals.TotalPlayers Boss music");
	RegAdminCmd("hale_resetqueuepoints", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("hale_resetq", ResetQueuePointsCmd, ADMFLAG_CHEATS, "Reset a player's queue points");
	RegAdminCmd("hale_setrage", Command_SetRage, ADMFLAG_CHEATS, "Usage: hale_setrage <target> <percent>. Sets the RAGE to a boss player");
	RegAdminCmd("hale_addrage", Command_AddRage, ADMFLAG_CHEATS, "Usage: hale_addrage <target> <percent>. Gives RAGE to a boss player");
	RegAdminCmd("hale_setinfiniterage", Command_SetInfiniteRage, ADMFLAG_CHEATS, "Usage: hale_infiniterage <target>. Gives infinite RAGE to a boss player");
	RegAdminCmd("hale_setcharge", Command_SetCharge, ADMFLAG_CHEATS, "Usage: hale_setcharge <target> <slot> <percent>. Sets a boss's charge");
	RegAdminCmd("hale_addcharge", Command_AddCharge, ADMFLAG_CHEATS, "Usage: hale_addcharge <target> <slot> <percent>. Adds a boss's charge");
	RegAdminCmd("hale_makeboss", Command_MakeBoss, ADMFLAG_CHEATS, "Usage: hale_makeboss <target> [team]. Makes a player a boss.");
	
	AddMultiTargetFilter("@hale", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!hale", BossTargetFilter, "all non-Boss players", false);
	AddMultiTargetFilter("@boss", BossTargetFilter, "all current Bosses", false);
	AddMultiTargetFilter("@!boss", BossTargetFilter, "all non-Boss players", false);
}

void ConVars_AddCommandHooks()
{
    AddCommandListener(OnCallForMedic, "voicemenu");	//Used to activate rages
    AddCommandListener(OnSuicide, "explode");		    //Used to stop boss from suiciding
    AddCommandListener(OnSuicide, "kill");			    //Used to stop boss from suiciding
    AddCommandListener(OnSuicide, "spectate");		    //Used to make sure players don't kill themselves and going to spec
    AddCommandListener(OnJoinTeam, "jointeam");		    //Used to make sure players join the right team
    AddCommandListener(OnJoinTeam, "autoteam");		    //Used to make sure players don't kill themselves and change team
    AddCommandListener(OnChangeClass, "joinclass");		//Used to make sure FF2Globals.Bosses don't change class
}

static void CvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == ConVars.Announce)
	{
		FF2GlobalsCvars.Announce = StringToFloat(newValue);
	}
	else if(convar == ConVars.ArenaRounds)
	{
		FF2GlobalsCvars.ArenaRounds = StringToInt(newValue);
	}
	else if(convar == ConVars.CircuitStun)
	{
		FF2GlobalsCvars.CircuitStun = StringToFloat(newValue);
	}
	else if(convar==ConVars.HealthBar || convar==ConVars.HealthHud)
	{
		UpdateHealthBar();
	}
	else if(convar == ConVars.LastPlayerGlow)
	{
		FF2GlobalsCvars.LastPlayerGlow = StringToFloat(newValue);
	}
	else if(convar == ConVars.SpecForceBoss)
	{
		FF2GlobalsCvars.SpecForceBoss = view_as<bool>(StringToInt(newValue));
	}
	else if(convar == ConVars.BossTeleporter)
	{
		FF2GlobalsCvars.BossTeleportation = StringToInt(newValue);
	}
	else if(convar == ConVars.ShieldCrits)
	{
		FF2GlobalsCvars.ShieldCrits = StringToInt(newValue);
	}
	else if(convar == ConVars.CaberDetonations)
	{
		FF2GlobalsCvars.AllowedDetonation = StringToInt(newValue);
	}
	else if(convar == ConVars.GoombaDamage)
	{
		FF2GlobalsCvars.GoombaDmg = StringToFloat(newValue);
	}
	else if(convar == ConVars.GoombaRebound)
	{
		FF2GlobalsCvars.ReboundPower = StringToFloat(newValue);
	}
	else if(convar == ConVars.SniperDamage)
	{
		FF2GlobalsCvars.SniperDmg = StringToFloat(newValue);
	}
	else if(convar == ConVars.SniperMiniDamage)
	{
		FF2GlobalsCvars.SniperMiniDmg = StringToFloat(newValue);
	}
	else if(convar == ConVars.BowDamage)
	{
		FF2GlobalsCvars.BowDmg = StringToFloat(newValue);
	}
	else if(convar == ConVars.BowDamageNon)
	{
		FF2GlobalsCvars.BowDmgNon = StringToFloat(newValue);
	}
	else if(convar == ConVars.BowDamageMini)
	{
		FF2GlobalsCvars.BowDmgMini = StringToFloat(newValue);
	}
	else if(convar == ConVars.SniperClimbDamage)
	{
		FF2GlobalsCvars.SniperClimpDmg = StringToFloat(newValue);
	}
	else if(convar == ConVars.SniperClimbDelay)
	{
		FF2GlobalsCvars.SniperClimpDelay = StringToFloat(newValue);
	}
	else if(convar == ConVars.QualityWep)
	{
		FF2GlobalsCvars.WeaponQuality = StringToInt(newValue);
	}
	else if(convar == ConVars.BossRTD)
	{
		FF2GlobalsCvars.CanBossRTD = view_as<bool>(StringToInt(newValue));
	}
	else if(convar == ConVars.PointsInterval)
	{
		FF2GlobalsCvars.PointsInterval = StringToInt(newValue);
		FF2GlobalsCvars.PointsInterval2 = StringToFloat(newValue);
	}
	else if(convar == ConVars.PointsDamage)
	{
		FF2GlobalsCvars.PointsDmg = StringToInt(newValue);
	}
	else if(convar == ConVars.PointsMin)
	{
		FF2GlobalsCvars.PointsMin = StringToInt(newValue);
	}
	else if(convar == ConVars.PointsExtra)
	{
		FF2GlobalsCvars.PointsExtra = StringToInt(newValue);
	}
	else if(convar == ConVars.DuoMin)
	{
		CheckDuoMin();
	}
	else if(convar == ConVars.Annotations)
	{
		FF2GlobalsCvars.Annotations = StringToInt(newValue);
	}
	else if(convar == ConVars.TellName)
	{
		FF2GlobalsCvars.TellName = view_as<bool>(StringToInt(newValue));
	}
	else if(convar == ConVars.ChargeAngle)
	{
		FF2GlobalsCvars.ChargeAngle = StringToFloat(newValue);
	}
	else if(convar == ConVars.Attributes)
	{
		strcopy(FF2GlobalsCvars.Attributes, sizeof(FF2GlobalsCvars.Attributes), newValue);
	}
	else if(convar == ConVars.StartingUber)
	{
		FF2GlobalsCvars.StartingUber = StringToFloat(newValue);
	}
	else if(convar == ConVars.Health)
	{
		strcopy(FF2GlobalsCvars.HealthFormula, sizeof(FF2GlobalsCvars.HealthFormula), newValue);
	}
	else if(convar == ConVars.RageDamage)
	{
		strcopy(FF2GlobalsCvars.RageDamage, sizeof(FF2GlobalsCvars.RageDamage), newValue);
	}
	else if(convar == ConVars.Database)
	{
		if(StringToInt(newValue))
		{
			if(!FF2Globals.Enabled_Database)
			{
				DataBase_SetupDatabase();
			}
			else if(FF2Globals.Enabled_Database == 1)
			{
				FF2Globals.Enabled_Database++;
			}
		}
		else if(FF2Globals.Enabled_Database == 2)
		{
			FF2Globals.Enabled_Database = 1;
		}
	}
	else if(convar == ConVars.Enabled)
	{
		switch(StringToInt(newValue))
		{
			case 0:
			{
				FF2ModsInfo.ChangeGamemode = FF2Globals.Enabled ? 2 : 0;
			}
			case 1:
			{
				if(Utils_IsFF2Map(FF2Globals.CurrentMap) && !FF2Globals.Enabled)
					FF2ModsInfo.ChangeGamemode = 1;
			}
			case 2:
			{
				FF2ModsInfo.ChangeGamemode = FF2Globals.Enabled ? 0 : 1;
			}
		}
	}
}

static void CvarChangeNextmap(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(Utils_IsFF2Map(newValue))
		CreateTimer(0.1, Timer_DisplayCharsetVote, _, TIMER_FLAG_NO_MAPCHANGE);
}