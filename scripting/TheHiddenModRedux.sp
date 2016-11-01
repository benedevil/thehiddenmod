/* [TF2] The Hidden Mod Redux
*
* Originally created by Matheus28 - http://forums.alliedmods.net/showthread.php?t=143577
* Then modified and improved by atomic-penguin(Eric G. Wolfe) and Daniel Murray - https://forums.alliedmods.net/showthread.php?t=206742
* Redux by luki1412
*/
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <morecolors>
#undef REQUIRE_EXTENSIONS
#tryinclude <steamtools>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "The Hidden Mod Redux"
#define PLUGIN_VERSION "1.18b"

//int gvars
int g_iTheCurrentHidden = 0;
int g_iHiddenCurrentHp;
int g_iHiddenHpMax;
int g_iForceNextHidden = 0;
int g_iForceCommandHidden = 0;
int g_iDamageToHidden[MAXPLAYERS+1] = 0;
//bool gvars
bool g_bHiddenSticky;
bool g_bPlaying = false; 
bool g_bHiddenStarvation = false;
bool g_bActivated = false;
bool g_bTimerDie = false;
bool g_bTimerDieTick = false;
bool g_bLateLoad;
bool g_bJumped = false;
//float gvars
float g_fHiddenStamina;
float g_fHiddenInvisibility;
float g_fHiddenVisible;
float g_fHiddenBomb;
float g_fTickInterval;
//handles
Handle g_hTick;
ConVar g_hCV_hidden_version;
ConVar g_hCV_hidden_enabled;
ConVar g_hCV_hidden_taunts;
ConVar g_hCV_hidden_tauntdamage;
ConVar g_hCV_hidden_visible_damage; 
ConVar g_hCV_hidden_visible_jarate; 
ConVar g_hCV_hidden_visible_pounce;
ConVar g_hCV_hidden_visible_bomb;
ConVar g_hCV_hidden_allowpyro;
ConVar g_hCV_hidden_allowpyroweapons;
ConVar g_hCV_hidden_allowheavy;
ConVar g_hCV_hidden_allowheavyweapons;
ConVar g_hCV_hidden_allowengineer;
ConVar g_hCV_hidden_allowsentries;
ConVar g_hCV_hidden_allowdispenserupgrade;
ConVar g_hCV_hidden_allowteleporterupgrade;
ConVar g_hCV_hidden_allowrazorback;
ConVar g_hCV_hidden_hpperplayer;
ConVar g_hCV_hidden_hpperkill;
ConVar g_hCV_hidden_hpbase;
ConVar g_hCV_hidden_stamina;
ConVar g_hCV_hidden_starvationtime;
ConVar g_hCV_hidden_bombtime;
ConVar g_hCV_hidden_bombmagnitude;
ConVar g_hCV_hidden_bombthrowspeed;
ConVar g_hCV_hidden_bombdetonationdelay;
Handle g_hWeaponEquip;
Handle g_hGameConfig;
//cvar globals
int g_iCV_hidden_tauntdamage;
float g_fCV_hidden_stamina;
float g_fCV_hidden_starvationtime;
float g_fCV_hidden_bombtime;
float g_fCV_hidden_visible_damage; 
float g_fCV_hidden_visible_jarate; 
float g_fCV_hidden_visible_pounce;
float g_fCV_hidden_visible_bomb;
//bomb precache
char g_sBombModel[255] = "models/weapons/w_grenade.mdl";
//beacon
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
char g_sBlipSound[255] = "buttons/blip1.wav";
char g_sBeamSprite[255] = "sprites/laser.vmt";
char g_sHaloSprite[255] = "sprites/halo01.vmt";

#if defined _steamtools_included
bool g_bSteamTools = false;
#endif

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "luki1412",
	description = "The Hidden:Source-like mod for TF2",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	char Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if (!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) 
	{
		Format(error, err_max, "[%s] This plugin only works for TF2 or TF2 Beta.", PLUGIN_NAME);
		return APLRes_Failure;
	}

	g_bLateLoad = late;
	#if defined _steamtools_included
	MarkNativeAsOptional("Steam_SetGameDescription");
	#endif
	return APLRes_Success;
}

public void OnPluginStart() 
{
	g_hCV_hidden_version = CreateConVar("sm_thehidden_version", PLUGIN_VERSION, "TF2 The Hidden Mod Redux version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCV_hidden_enabled = CreateConVar("sm_thehidden_enabled", "1", "Enables/disables the hidden mod redux.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_taunts = CreateConVar("sm_thehidden_allowtaunts", "1", "Enables/disables taunts.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_tauntdamage = CreateConVar("sm_thehidden_allowtauntdamage", "0", "Allow/disallow players to damage The Hidden while taunting.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowpyro = CreateConVar("sm_thehidden_allowpyro", "1", "Set whether pyros are allowed on team IRIS", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowpyroweapons = CreateConVar("sm_thehidden_allowpyroprimaries", "0", "Set whether pyros are allowed to use primary weapons", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowengineer = CreateConVar("sm_thehidden_allowengineer", "1", "Set whether engineers are allowed on team IRIS", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowsentries = CreateConVar("sm_thehidden_allowsentries", "0", "Set whether engineers are allowed to build sentries", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowdispenserupgrade = CreateConVar("sm_thehidden_allowdispenserupgrade", "0", "Set whether engineers are allowed to upgrade dispensers.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowteleporterupgrade = CreateConVar("sm_thehidden_allowteleporterupgrade", "1", "Set whether engineers are allowed to upgrade teleporters.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowheavy = CreateConVar("sm_thehidden_allowheavy", "1", "Set whether heavies are allowed on team IRIS", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowheavyweapons = CreateConVar("sm_thehidden_allowheavyprimaries", "0", "Set whether heavies are allowed to use primary weapons", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_allowrazorback = CreateConVar("sm_thehidden_allowrazorback", "0", "Allow/disallow razorbacks for snipers", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCV_hidden_visible_damage = CreateConVar("sm_thehidden_visibledamage", "0.5", "How much time the Hidden is visible for, after taking weapon damage.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_visible_jarate = CreateConVar("sm_thehidden_visiblejarate", "1.0", "How much time the Hidden is visible for, when splashed with jarate, mad milk, or bonked.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_visible_pounce = CreateConVar("sm_thehidden_visiblepounce", "0.25", "How much time the Hidden is visible for, when dashing.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_visible_bomb = CreateConVar("sm_thehidden_visiblebomb", "1.5", "How much time the Hidden is visible for, after throwing the the bomb.", FCVAR_NONE, true, 0.0, true, 5.0);
	g_hCV_hidden_hpbase = CreateConVar("sm_thehidden_hpbase", "300", "Amount of hp used for calculating the Hidden's starting/max hp.", FCVAR_NONE, true, 1.0, true, 10000.0);
	g_hCV_hidden_hpperplayer = CreateConVar("sm_thehidden_hpincreaseperplayer", "70", "This amount of hp, multiplied by the number of players, plus the base hp, equals The Hidden's hp.", FCVAR_NONE, true, 0.0, true, 1000.0);
	g_hCV_hidden_hpperkill = CreateConVar("sm_thehidden_hpincreaseperkill", "50", "Amount of hp the Hidden gets back after he kills a player. This value changes based on victim's class.", FCVAR_NONE, true, 0.0, true, 1000.0);
	g_hCV_hidden_bombmagnitude = CreateConVar("sm_thehidden_bombmagnitude", "100.0", "Magnitude of the bomb.", FCVAR_NONE, true, 1.0, true, 1000.0);
	g_hCV_hidden_bombthrowspeed = CreateConVar("sm_thehidden_bombthrowspeed", "2000.0", "The bomb throw speed.", FCVAR_NONE, true, 1.0, true, 10000.0);
	g_hCV_hidden_bombdetonationdelay = CreateConVar("sm_thehidden_bombdetonationdelay", "1.8", "Delay of the the bomb detonation.", FCVAR_NONE, true, 0.1, true, 100.0);
	g_hCV_hidden_stamina = CreateConVar("sm_thehidden_stamina", "5.0", "The Hidden's max stamina.", FCVAR_NONE, true, 1.0, true, 1000.0);
	g_hCV_hidden_starvationtime = CreateConVar("sm_thehidden_starvationtime", "100.0", "Time until the Hidden dies without killing.", FCVAR_NONE, true, 10.0, true, 1000.0);
	g_hCV_hidden_bombtime = CreateConVar("sm_thehidden_bombtime", "20.0", "The bomb cooldown.", FCVAR_NONE, true, 1.0, true, 1000.0);

	g_fTickInterval = GetTickInterval(); // 0.014999 default
	RegAdminCmd("sm_nexthidden", Cmd_NextHidden, ADMFLAG_CHEATS, "Forces a certain player to be the next Hidden, regardless of who wins the round");

	#if defined _steamtools_included
	g_bSteamTools = LibraryExists("SteamTools");
	#endif
	
	// Auto-create the config file
	AutoExecConfig(true, "The_Hidden_Mod_Redux");
	SetConVarString(g_hCV_hidden_version, PLUGIN_VERSION);
	LoadCvars();
	
	if (g_bLateLoad && GetConVarBool(g_hCV_hidden_enabled) && IsArenaMap()) 
	{
		OnConfigsExecuted();
		ActivatePlugin();
	} 

	HookConVarChange(g_hCV_hidden_enabled, cvhook_enabled);
	HookConVarChange(g_hCV_hidden_allowpyro, cvhook_allowpyro);
	HookConVarChange(g_hCV_hidden_allowengineer, cvhook_allowengineer);
	HookConVarChange(g_hCV_hidden_allowheavy, cvhook_allowheavy);
	
	g_hGameConfig = LoadGameConfigFile("the.hidden.mod.redux");
	
	if (!g_hGameConfig)
	{
		SetFailState("Can't find the.hidden.mod.redux.txt gamedata! Can't continue.", PLUGIN_NAME);
	}	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "WeaponEquip");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWeaponEquip = EndPrepSDKCall();

	if (!g_hWeaponEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving weapons. Try updating gamedata or restarting your server.", PLUGIN_NAME);
	}
}
//remove hidden's vision, everything else gets unloaded by sourcemod
public void OnPluginEnd() 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}
	
	if (g_iTheCurrentHidden && IsPlayerHereLoopCheck(g_iTheCurrentHidden) && IsPlayerAlive(g_iTheCurrentHidden))
	{
		RemoveHiddenPowers(g_iTheCurrentHidden);
		TF2_SetPlayerClass(g_iTheCurrentHidden, TFClass_Spy);
		CreateTimer(0.1, Timer_Respawn, g_iTheCurrentHidden, TIMER_FLAG_NO_MAPCHANGE);
	}

	DeactivatePlugin();	
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerHereLoopCheck(i))
		{
			SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
		}
	}
	
	CreateTimer(2.0, Timer_Win, _, TIMER_FLAG_NO_MAPCHANGE);
}
//if steamtools is running
#if defined _steamtools_included
public void OnLibraryAdded(const char[] name) 
{
	if (strcmp(name, "SteamTools", false) == 0) 
	{
		g_bSteamTools = true;
	}
	
}
#endif
//if steamtools isnt running anymore
#if defined _steamtools_included
public void OnLibraryRemoved(const char[] name) 
{
	if (strcmp(name, "SteamTools", false) == 0) 
	{
		g_bSteamTools = false;
	}
}
#endif
//change some tf2 cvars
public void OnConfigsExecuted() 
{
	SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
	SetConVarInt(FindConVar("tf_arena_override_team_size"), 32);
	SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
	SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
	SetConVarInt(FindConVar("mp_autoteambalance"), 0);
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
	SetConVarInt(FindConVar("tf_classlimit"), 0);
	SetConVarInt(FindConVar("tf_playergib"), 0);
}
//attempt to activate the plugin on mapstart, change game too
public void OnMapStart() 
{
	//precache sound and models
	PrecacheModel(g_sBombModel, true);
	PrecacheSound(g_sBlipSound, true);
	g_iHaloSprite = PrecacheModel(g_sHaloSprite, true);
	g_iBeamSprite = PrecacheModel(g_sBeamSprite, true);
	
	if (GetConVarBool(g_hCV_hidden_enabled) && IsArenaMap()) 
	{
		ActivatePlugin();
	} 
	else
	{
		LogMessage("[%s] This plugin isn't enabled or the current map isn't an arena map. Deactivating the plugin.", PLUGIN_NAME);
		DeactivatePlugin();
	}
}
//deactivate the plugin on mapend, change game back
public void OnMapEnd() 
{
	if (GetConVarBool(g_hCV_hidden_enabled)) 
	{
		DeactivatePlugin();
	}
}
// Hook when player takes damage for max damage calc
public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); 
}
//load these only when the game starts
void LoadCvars()
{
	g_fCV_hidden_stamina = GetConVarFloat(g_hCV_hidden_stamina);
	g_fCV_hidden_starvationtime = GetConVarFloat(g_hCV_hidden_starvationtime);
	g_fCV_hidden_bombtime = GetConVarFloat(g_hCV_hidden_bombtime);
	g_fCV_hidden_visible_damage = GetConVarFloat(g_hCV_hidden_visible_damage); 
	g_fCV_hidden_visible_jarate = GetConVarFloat(g_hCV_hidden_visible_jarate); 
	g_fCV_hidden_visible_pounce = GetConVarFloat(g_hCV_hidden_visible_pounce);
	g_fCV_hidden_visible_bomb = GetConVarFloat(g_hCV_hidden_visible_bomb);
	g_iCV_hidden_tauntdamage = GetConVarInt(g_hCV_hidden_tauntdamage);
}
//activate the mod
void ActivatePlugin() 
{
	if (g_bActivated)
	{
		return;
	}
	
	CreateTimer(30.0, Timer_Win, _, TIMER_FLAG_NO_MAPCHANGE);
	
	g_bActivated = true;
	g_bTimerDieTick = false;
	g_hTick = CreateTimer(0.2, Timer_Tick, _, TIMER_REPEAT);
	
	HookEvent("teamplay_round_win", teamplay_round_win, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", teamplay_round_start, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", arena_round_start, EventHookMode_PostNoCopy);

	HookEvent("player_spawn", player_spawn);
	HookEvent("player_hurt", player_hurt);
	HookEvent("player_death", player_death);
	HookEvent("player_upgradedobject", player_upgradedobject);

	AddCommandListener(Cmd_build, "build");
	AddCommandListener(Cmd_taunt, "taunt");
	AddCommandListener(Cmd_taunt, "+taunt");
	AddCommandListener(Cmd_join, "jointeam");
	AddCommandListener(Cmd_class, "joinclass");
	
	ConVar serverTags = FindConVar("sv_tags");
	
	if (serverTags != null) 
	{
		char tags[512];
		GetConVarString(serverTags, tags, sizeof(tags));
		
		if (StrContains(tags, "thehidden", false) == -1)
		{
			char newTags[512];
			Format(newTags, sizeof(newTags), "%s,%s", tags, "thehidden");
			SetConVarString(serverTags, newTags);
		}
	}
	
	#if defined _steamtools_included	
	if (g_bSteamTools)
	{
		SetGameDescription(); 
	}
	#endif
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsPlayerHereLoopCheck(i)) 
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		} 
	} 
}
//deactivate the mod
void DeactivatePlugin() 
{
	if (!g_bActivated)
	{
		return;
	}
	
	g_bActivated = false;
	g_bTimerDieTick = true;
	g_hTick = null;
	CreateTimer(1.0, Timer_EnableCps, _, TIMER_FLAG_NO_MAPCHANGE);
	
	UnhookEvent("teamplay_round_win", teamplay_round_win, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_round_start", teamplay_round_start, EventHookMode_PostNoCopy);
	UnhookEvent("arena_round_start", arena_round_start, EventHookMode_PostNoCopy);

	UnhookEvent("player_spawn", player_spawn);
	UnhookEvent("player_hurt", player_hurt);
	UnhookEvent("player_death", player_death);
	UnhookEvent("player_upgradedobject", player_upgradedobject);
	
	RemoveCommandListener(Cmd_build, "build");
	RemoveCommandListener(Cmd_join, "jointeam");
	RemoveCommandListener(Cmd_taunt, "taunt");
	RemoveCommandListener(Cmd_taunt, "+taunt");
	RemoveCommandListener(Cmd_class, "joinclass");	
	
	ConVar serverTags = FindConVar("sv_tags");
	
	if (serverTags != null) 
	{
		char tags[512];
		GetConVarString(serverTags, tags, sizeof(tags));
		
		if (StrContains(tags, "thehidden", false) != -1)
		{
			ReplaceString(tags, sizeof(tags), "thehidden", "", true);
			SetConVarString(serverTags, tags);
		}
	}
	
	#if defined _steamtools_included	
	if (g_bSteamTools)
	{
		SetGameDescription(); 
	}
	#endif
}
//block some buildings upgrades
public void player_upgradedobject(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(g_hCV_hidden_enabled))
	{
		return;
	}
	
	int objectid = GetEventInt(event,"index");
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	int obj = GetEntProp(objectid, Prop_Send, "m_iObjectType");
	
	if (GetConVarBool(g_hCV_hidden_allowdispenserupgrade) == false && obj == view_as<int>(TFObject_Dispenser)) 
	{
		SetEntProp(objectid, Prop_Send, "m_iUpgradeLevel", 0);
		SetEntPropFloat(objectid, Prop_Send, "m_flPercentageConstructed", 0.99 );
		SetEntProp(objectid, Prop_Send, "m_bBuilding", 1);
		CPrintToChat(client,"{mediumseagreen}[%s]{powderblue} You can't upgrade dispensers!", PLUGIN_NAME);
		return;
	}
	
	if (GetConVarBool(g_hCV_hidden_allowteleporterupgrade) == false && obj == view_as<int>(TFObject_Teleporter)) 
	{
		SetEntProp(objectid, Prop_Send, "m_iUpgradeLevel", 0);
		SetEntPropFloat(objectid, Prop_Send, "m_flPercentageConstructed", 0.99 );
		SetEntProp(objectid, Prop_Send, "m_bBuilding", 1);
		CPrintToChat(client,"{mediumseagreen}[%s]{powderblue} You can't upgrade teleporters!", PLUGIN_NAME);
		return;
	}
}
//a player pressed a button
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if (client == g_iTheCurrentHidden) 
	{
		if (g_bHiddenSticky) 
		{
			if (buttons & IN_JUMP > 0)
			{
				HiddenUnstick();
			}
		}
		
		if (buttons&IN_ATTACK) 
		{
			TF2_RemoveCondition(client, TFCond_Cloaked);
			AddHiddenVisible(0.75);
			
			if (IsFakeClient(client) && GetRandomInt(0,10) == 9)
			{
				HiddenBombTrigger();
			}
			
			return Plugin_Changed;
		}
		
		if (buttons&IN_ATTACK2) 
		{
			if (!IsFakeClient(client))
			{
				buttons&=~IN_ATTACK2;
				HiddenSuperJump();
				return Plugin_Changed;
			}
		}
		
		if (buttons&IN_RELOAD) 
		{
			HiddenBombTrigger();
		}
	}
	return Plugin_Continue;
}
//lets block sentries for engies
public Action Cmd_build(int client, char[] cmd, int args)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int building = StringToInt(arg1);
	
	if (!GetConVarBool(g_hCV_hidden_allowsentries) && building == view_as<int>(TFObject_Sentry)) 
	{
		CPrintToChat(client, "{mediumseagreen}[%s]{powderblue} You can't build sentries!", PLUGIN_NAME);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
//block taunts
public Action Cmd_taunt(int client, char[] cmd, int args)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if (!GetConVarBool(g_hCV_hidden_taunts)) 
	{
		CPrintToChat(client, "{mediumseagreen}[%s]{powderblue} Taunts are disabled!", PLUGIN_NAME);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
//team selection
public Action Cmd_join(int client, char[] cmd, int args)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}

	if (args > 1) 
	{
		return Plugin_Handled;
	}

	if (Client_TotalBlue() == 1)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		if (StrEqual(arg1, "spectator", true) || StrEqual(arg1, "red", true) || StrEqual(arg1, "spectate", true))
		{
			return Plugin_Continue;
		}
		else
		{
			if (StrEqual(arg1, "auto", true))
			{
				ChangeClientTeam(client, 2);
				ShowVGUIPanel(client, "class_red");
			}
			else
			{
				PrintCenterText(client, "You can't join that team! Switched to team IRIS.");
				ChangeClientTeam(client, 2);
				ShowVGUIPanel(client, "class_red");
			}	
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}
//class change
public Action Cmd_class(int client, char[] cmd, int args)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}

	if (args > 1 || !IsPlayerHere(client)) 
	{
		return Plugin_Handled;
	}

	int team = GetClientTeam(client);
	if (team < 3)
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
			
		if (StrEqual(arg1, "scout", true) || StrEqual(arg1, "soldier", true) || (StrEqual(arg1, "pyro", true) && GetConVarBool(g_hCV_hidden_allowpyro)) || (StrEqual(arg1, "heavyweapons", true) && GetConVarBool(g_hCV_hidden_allowheavy)) || (StrEqual(arg1, "engineer", true) && GetConVarBool(g_hCV_hidden_allowengineer)) || StrEqual(arg1, "demoman", true) || StrEqual(arg1, "medic", true) || StrEqual(arg1, "sniper", true))
		{
			return Plugin_Continue;
		}
		else
		{
			if (StrEqual(arg1, "random", true))
			{
				SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", PickAClass());
			}
			else
			{
				PrintCenterText(client, "You can't pick that class!");
				ShowVGUIPanel(client, team == 3 ? "class_blue" : "class_red");		
			}
			return Plugin_Handled;
		}
	}
	else
	{
		PrintCenterText(client, "You can't change class on this team!");
		return Plugin_Handled;
	}
}
//on take damage hook
public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}

	if (client == g_iTheCurrentHidden)
	{
		if (damagetype & DMG_FALL)
		{
			return Plugin_Handled;
		}
		
		if (g_iCV_hidden_tauntdamage == 0)
		{
			switch (damagecustom)
			{
				case TF_CUSTOM_TAUNT_HADOUKEN,TF_CUSTOM_TAUNT_HIGH_NOON,TF_CUSTOM_TAUNT_GRAND_SLAM,TF_CUSTOM_TAUNT_FENCING,TF_CUSTOM_TAUNT_ARROW_STAB,TF_CUSTOM_TAUNT_GRENADE,TF_CUSTOM_TAUNT_BARBARIAN_SWING,TF_CUSTOM_TAUNT_UBERSLICE,TF_CUSTOM_TAUNT_ENGINEER_SMASH,TF_CUSTOM_TAUNT_ENGINEER_ARM,TF_CUSTOM_TAUNT_ARMAGEDDON,TF_CUSTOM_TAUNT_ALLCLASS_GUITAR_RIFF,TF_CUSTOM_FLARE_PELLET:
				{
					return Plugin_Handled;
				}
			}
		}		
	}
	
	return Plugin_Continue;
}
//a player got hurt, only care about the hidden
public void player_hurt(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}

	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (victim != g_iTheCurrentHidden)
	{
		return;
	}

	int damage = GetEventInt(event, "damageamount");
	g_iHiddenCurrentHp -= damage;
	
	if (g_iHiddenCurrentHp < 0)
	{
		g_iHiddenCurrentHp = 0;
	}

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	
	
	if (attacker != g_iTheCurrentHidden)
	{
		if (damage > g_iHiddenCurrentHp) 
		{
			g_iDamageToHidden[attacker] += g_iHiddenCurrentHp;
		}
		else
		{
			g_iDamageToHidden[attacker] += damage;
		}
	}	
}
//a player spawned. lets check their classes and change/respawn if needed
public void player_spawn(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!GetConVarBool(g_hCV_hidden_enabled) || !IsPlayerHere(client) || !IsPlayerAlive(client)) 
	{
		return;
	}

	TFClassType class = view_as<TFClassType>(GetEventInt(event, "class"));
	
	if (client == g_iTheCurrentHidden) 
	{
		if (class != TFClass_Spy)
		{
			SetEntProp(client, Prop_Send, "m_lifeState", 2);
			ChangeClientTeam(client, 3);
			TF2_SetPlayerClass(client, TFClass_Spy, false, true);
			CreateTimer(0.1, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
		else
		{
			RequestFrame(GiveHiddenPowers, client);
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);
		}
		
		if (IsFakeClient(client))
		{
			g_bTimerDie = false;
			CreateTimer(1.0, Timer_Beacon, client, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT );
		}
		
		return;
	}
	else
	{
		if (!IsFakeClient(client))
		{
			if (class == TFClass_Unknown || class == TFClass_Spy || (class == TFClass_Engineer && !GetConVarBool(g_hCV_hidden_allowengineer)) || (class == TFClass_Pyro && !GetConVarBool(g_hCV_hidden_allowpyro)) || (class == TFClass_Heavy && !GetConVarBool(g_hCV_hidden_allowheavy))) 
			{
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				ChangeClientTeam(client, 2);
				TF2_SetPlayerClass(client, view_as<TFClassType>(PickAClass()), false, true);
				CreateTimer(0.1, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
				return;
			}
		}
		else
		{
			if (class != TFClass_Sniper) 
			{
				SetEntProp(client, Prop_Send, "m_lifeState", 2);
				ChangeClientTeam(client, 2);
				TF2_SetPlayerClass(client, TFClass_Sniper, false, true);
				CreateTimer(0.1, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
				return;	
			}
		}
		
		if ((!GetConVarBool(g_hCV_hidden_allowpyroweapons) && class == TFClass_Pyro) || (!GetConVarBool(g_hCV_hidden_allowheavyweapons) && class == TFClass_Heavy)) 
		{
			TF2_RemoveWeaponSlot(client, 0);
			EquipPlayerWeapon(client, GetPlayerWeaponSlot(client, 2));
		}
		
		if (class == TFClass_Sniper && !GetConVarBool(g_hCV_hidden_allowrazorback))
		{
			int i = MaxClients+1;
			int ent = 0;
			
			for (int n = 0; n <= MaxClients; n++) 
			{
				ent = FindEntityByClassname(i, "tf_wearable");
				
				if (IsValidEntity(ent)) 
				{
					if(GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex") == 57)
					{
						AcceptEntityInput(ent, "Kill");
					}
					
					i = ent;
				} 
				else 
				{
					break;
				}
			} 
		}
		
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
	}
}
//a player died
public void player_death(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}

	if (!g_bPlaying)
	{
		return;
	}	
	
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (victim != g_iTheCurrentHidden)
	{
		SetEntProp(victim, Prop_Send, "m_bGlowEnabled", 0);
		
		if (attacker == g_iTheCurrentHidden)
		{
			g_fHiddenInvisibility = g_fCV_hidden_starvationtime;
			int hpperkill = GetConVarInt(g_hCV_hidden_hpperkill);
			int customkill = GetEventInt(event, "customkill");
			int weaponi = GetEventInt(event, "weaponid");
			
			if (IsPlayerHere(g_iTheCurrentHidden) && IsPlayerAlive(g_iTheCurrentHidden))
			{
				if (customkill != TF_CUSTOM_BACKSTAB && weaponi == TF_WEAPON_KNIFE)
				{				
					TFClassType classv = TF2_GetPlayerClass(victim);
					
					switch (classv)
					{
						case TFClass_Scout, TFClass_Sniper, TFClass_Engineer:
						{
							g_iHiddenCurrentHp += hpperkill; 
							
							if (g_iHiddenCurrentHp > g_iHiddenHpMax) 
							{
								g_iHiddenCurrentHp = g_iHiddenHpMax;
							}			
						}
						case TFClass_Heavy, TFClass_Soldier:
						{
							g_iHiddenCurrentHp += hpperkill+20;
							
							if (g_iHiddenCurrentHp > g_iHiddenHpMax) 
							{
								g_iHiddenCurrentHp = g_iHiddenHpMax;
							}
						}
						default:
						{
							g_iHiddenCurrentHp += hpperkill+10;
							
							if (g_iHiddenCurrentHp > g_iHiddenHpMax) 
							{
								g_iHiddenCurrentHp = g_iHiddenHpMax;
							}
						}
					}
					
					CPrintToChatAll("{mediumseagreen}[%s] {crimson}The Hidden{powderblue} killed {crimson}%N{powderblue} and ate his body to restore some health!", PLUGIN_NAME, victim);
					RequestFrame(Dissolve, victim);
				}
				else
				{
					RequestFrame(GibRagdoll, victim);
					CPrintToChatAll("{mediumseagreen}[%s] {crimson}The Hidden{powderblue} killed {crimson}%N{powderblue}!", PLUGIN_NAME, victim);
				}
			}
			
			if (GetAliveEnemiesCount() <= 1)
			{
				g_iForceNextHidden = 0;
				CPrintToChatAll("{mediumseagreen}[%s] {crimson}The Hidden{powderblue} killed the entire team {crimson}IRIS{powderblue}! The next {crimson}Hidden{powderblue} will be chosen randomly!", PLUGIN_NAME);
			}
		}
	}
	else
	{
		g_iHiddenCurrentHp = 0;
		RemoveHiddenPowers(victim);
		
		if (attacker != g_iTheCurrentHidden && attacker != 0 && !g_bHiddenStarvation) 
		{
			int top = 0;
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (g_iDamageToHidden[i] >= g_iDamageToHidden[top])
				{
					top = i;
				}
			}

			CPrintToChatAll("{mediumseagreen}[%s] {powderblue}Team {crimson}IRIS{powderblue} killed {crimson}the Hidden{powderblue}!", PLUGIN_NAME);
			
			if (top > 0 && g_iDamageToHidden[top] > 0)
			{
				g_iForceNextHidden = GetClientUserId(top);
				CPrintToChatAll("{mediumseagreen}[%s] {crimson}%N{powderblue} dealt most damage to {crimson}the Hidden{powderblue} and will become the next {crimson}Hidden{powderblue}!", PLUGIN_NAME, top);
			}
			else
			{
				g_iForceNextHidden = 0;
				CPrintToChatAll("{mediumseagreen}[%s] {powderblue}The next {crimson}Hidden{powderblue} will be chosen randomly!", PLUGIN_NAME);
			}
		}
		else
		{
			g_iForceNextHidden = 0;
			
			if (g_bHiddenStarvation)
			{
				CPrintToChatAll("{mediumseagreen}[%s]{powderblue} {crimson}The Hidden{powderblue} starved to death. The next {crimson}Hidden{powderblue} will be chosen randomly!", PLUGIN_NAME);
			}
			else
			{
				CPrintToChatAll("{mediumseagreen}[%s]{powderblue} {crimson}The Hidden{powderblue} committed suicide. The next {crimson}Hidden{powderblue} will be chosen randomly!", PLUGIN_NAME);
			}
		} 
	}
	
	return;
}
//spawn another ragdoll
public void GibRagdoll(int client)
{
	int oldragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if (oldragdoll != -1)
	{
		float RagOrigin[3], RagForce[3], RagVel[3];
		GetEntPropVector(oldragdoll, Prop_Send, "m_vecRagdollOrigin", RagOrigin);
		GetEntPropVector(oldragdoll, Prop_Send, "m_vecForce", RagForce);
		GetEntPropVector(oldragdoll, Prop_Send, "m_vecRagdollVelocity", RagVel);
		AcceptEntityInput(oldragdoll, "Kill");
		
		int newragdoll = CreateEntityByName("tf_ragdoll");
		
		if (newragdoll != -1)
		{
			SetEntPropVector(newragdoll, Prop_Send, "m_vecRagdollOrigin", RagOrigin);
			SetEntPropVector(newragdoll, Prop_Send, "m_vecForce", RagForce);
			SetEntPropVector(newragdoll, Prop_Send, "m_vecRagdollVelocity", RagVel);
			SetEntProp(newragdoll, Prop_Send, "m_iPlayerIndex", client);
			SetEntProp(newragdoll, Prop_Send, "m_bGib", 1);
			DispatchSpawn(newragdoll);
		}
	}
}
//the game frame, less = better
public void OnGameFrame()
{	
	if (g_iTheCurrentHidden == 0) 
	{
		return;
	}

	if (IsPlayerHere(g_iTheCurrentHidden) && IsPlayerAlive(g_iTheCurrentHidden))
	{
		if (GetClientHealth(g_iTheCurrentHidden) > 0) 
		{
			if (g_iHiddenCurrentHp > g_iHiddenHpMax) 
			{
				SetEntityHealth(g_iTheCurrentHidden, g_iHiddenHpMax);
			} 
			else 
			{
				SetEntityHealth(g_iTheCurrentHidden, g_iHiddenCurrentHp);
			}
		}
		else
		{
			g_iHiddenCurrentHp = 0;
		}
		
		SetEntPropFloat(g_iTheCurrentHidden, Prop_Send, "m_flMaxspeed", 400.0);
		
		if (g_fHiddenInvisibility > 0.0) 
		{
			g_fHiddenInvisibility -= g_fTickInterval;
			
			if (g_fHiddenInvisibility < 0.0) 
			{
				g_fHiddenInvisibility = 0.0;
				g_bHiddenStarvation = true;
				Client_TakeDamage(g_iTheCurrentHidden, 0, 99999, DMG_CRUSH, "");
				return;
			}
		}
		
		if (g_fHiddenBomb > 0.0) 
		{
			g_fHiddenBomb -= g_fTickInterval;
			
			if (g_fHiddenBomb < 0.0) 
			{
				g_fHiddenBomb = 0.0;
			}
		}
		
		if (!g_bHiddenSticky) 
		{
			HiddenUnstick();
			
			if (g_fHiddenStamina < g_fCV_hidden_stamina) 
			{
				g_fHiddenStamina += g_fTickInterval/4;
				
				if (g_fHiddenStamina > g_fCV_hidden_stamina) 
				{
					g_fHiddenStamina = g_fCV_hidden_stamina;
				}
			}
		} 
		else
		{
			g_fHiddenStamina -= g_fTickInterval/2;
			
			if (g_fHiddenStamina <= 0.0) 
			{
				g_fHiddenStamina = 0.0;
				g_bHiddenSticky = false;
				HiddenUnstick();
			} 
			else if (GetEntityMoveType(g_iTheCurrentHidden) == MOVETYPE_WALK) 
			{
				SetEntityMoveType(g_iTheCurrentHidden, MOVETYPE_NONE);
			}
		}
		
		if (g_fHiddenVisible > 0.0) 
		{
			g_fHiddenVisible -= g_fTickInterval;
			
			if (g_fHiddenVisible < 0.0) 
			{
				g_fHiddenVisible = 0.0;
			}
		}
		
		if (g_fHiddenInvisibility > 0.0) 
		{
			if (g_fHiddenVisible <= 0.0) 
			{
				if (!TF2_IsPlayerInCondition(g_iTheCurrentHidden, TFCond_Cloaked)) 
				{
					TF2_AddCondition(g_iTheCurrentHidden, TFCond_Cloaked, -1.0);
				}
			} 
			else 
			{
				TF2_RemoveCondition(g_iTheCurrentHidden, TFCond_Cloaked);
			}
		} 
		else 
		{
			TF2_RemoveCondition(g_iTheCurrentHidden, TFCond_Cloaked);
		}
	} 	
}
//conditions
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (client != g_iTheCurrentHidden)
	{
		return;
	}
	
	switch (condition)
	{
		case TFCond_OnFire:
		{
			AddHiddenVisible(g_fCV_hidden_visible_damage);
			TF2_RemoveCondition(client, condition);
			GiveHiddenVision(client);			
		}
		case TFCond_Ubercharged:
		{
			TF2_RemoveCondition(client, condition);
			GiveHiddenVision(client);		
		}
		case TFCond_Jarated:
		{
			AddHiddenVisible(g_fCV_hidden_visible_jarate);
			TF2_RemoveCondition(client, condition);
			GiveHiddenVision(client);
		}
		case TFCond_Milked, TFCond_Bonked:
		{
			AddHiddenVisible(g_fCV_hidden_visible_jarate);
			TF2_RemoveCondition(client, condition);	
		}
		case TFCond_Bleeding:
		{
			AddHiddenVisible(g_fCV_hidden_visible_damage);
			TF2_RemoveCondition(client, condition);
			GiveHiddenVision(client);
		}
		case TFCond_DeadRingered, TFCond_Kritzkrieged, TFCond_MarkedForDeath, TFCond_CritOnFirstBlood:
		{
			TF2_RemoveCondition(client, condition);
		}
		case TFCond_Disguising, TFCond_Disguised:
		{
			if (!IsFakeClient(client))
			{
				TF2_RemoveCondition(client, condition);
			}
		}
	}
}
//someone won, reset the hidden
public void teamplay_round_win(Handle event, const char[] name, bool dontBroadcast) 
{
	g_bPlaying = true;
	g_bTimerDie = true;
	CreateTimer(0.1, Timer_ResetHidden, _, TIMER_FLAG_NO_MAPCHANGE);
}
//round start - players cant move but they can change classes
public void teamplay_round_start(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!CanPlay()) 
	{
		CPrintToChatAll("{mediumseagreen}[%s]{powderblue} Not enough players to start a new game.", PLUGIN_NAME);
		return;
	}

	LoadCvars();	
	g_bPlaying = false;
	NewGame();
}
//arena start - players can move, cant change classes
public void arena_round_start(Handle event, const char[] name, bool dontBroadcast) 
{
	Client_RespawnAll(true, false);
	g_bPlaying = true;
	g_bHiddenStarvation = false;
}
//a beacon for the hidden bot
public Action Timer_Beacon(Handle timer, any client)
{
	if (!IsPlayerHereLoopCheck(client) || !IsPlayerAlive(client) || g_bTimerDie == true)
	{
		return Plugin_Stop;
	}
	
	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	
	if (g_iBeamSprite > -1 && g_iHaloSprite > -1)
	{
		int Color[4] = {0, 0, 255, 255};
		TE_SetupBeamRingPoint(vec, 10.0, 400.0, g_iBeamSprite, g_iHaloSprite, 0, 15, 0.5, 5.0, 0.0, Color, 10, 0);
		TE_SendToAll();
	}
	
	if (g_sBlipSound[0])
	{
		GetClientEyePosition(client, vec);
		EmitAmbientSound(g_sBlipSound, vec, client, SNDLEVEL_RAIDSIREN);	
	}
	
	return Plugin_Continue;
}
//disable control points
public Action Timer_DisableCps(Handle timer) 
{
	int i = MaxClients+1;
	int TA = 0;
	
	while ((TA = FindEntityByClassname(i, "trigger_capture_area")) > -1) 
	{
		if (TA>MaxClients && IsValidEntity(TA)) 
		{
			AcceptEntityInput(TA, "Disable");
			i = TA;
		} 
		else 
		{
			break;
		}
	} 
	
	TA = 0;
	i = MaxClients+1;
	while ((TA = FindEntityByClassname(i, "team_control_point")) > -1) 
	{	
		if (TA>MaxClients && IsValidEntity(TA)) 
		{
			SetVariantInt(0);
			AcceptEntityInput(TA, "SetLocked");
			SetVariantFloat(0.10);
			AcceptEntityInput(TA, "SetUnlockTime");
			i = TA;
		} 
		else 
		{
			break;
		}
	} 
}
//enable control points
public Action Timer_EnableCps(Handle timer) 
{
	int i = MaxClients+1;
	int TA = 0;
	
	while ((TA = FindEntityByClassname(i, "trigger_capture_area")) > -1) 
	{
		if (TA>MaxClients && IsValidEntity(TA)) 
		{
			AcceptEntityInput(TA, "Enable");
			i = TA;
		} 
		else 
		{
			break;
		}
	}  
}
//timer callback for new game
public void NewGame() 
{
	if (g_iTheCurrentHidden != 0) 
	{
		return;
	}
	
	CreateTimer(1.0, Timer_DisableCps, _, TIMER_FLAG_NO_MAPCHANGE);
	SelectHidden();

	for (int n = 0; n <= MaxClients; n++) 
	{
		g_iDamageToHidden[n] = 0;
	}
	
	Client_RespawnAll(false, false);	
	
	if (g_hTick == null)
	{
		g_hTick = CreateTimer(0.1, Timer_Tick, _, TIMER_REPEAT);
	}
}
//timer callback for resetting the hidden
public Action Timer_ResetHidden(Handle timer) 
{
	ResetHidden();
}
//timer callback for respawn
public Action Timer_Respawn(Handle timer, any data) 
{
	TF2_RespawnPlayer(data);
}
//notify the hidden that he has help in chat
public Action NotifyHidden(Handle timer, any client) 
{
	if (IsPlayerHere(client)) 
	{     
		PrintHintText(g_iTheCurrentHidden, "READ THE CHAT FOR HELP");
	}
}
//jump check
public Action Timer_Jumped(Handle timer, any data)
{
	g_bJumped = false;
}
//force round restart
public Action Timer_Win(Handle timer, any data) 
{
	CPrintToChatAll("{mediumseagreen}[%s]{powderblue} Killing all bots in the first round.", PLUGIN_NAME);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerHereLoopCheck(i) && IsFakeClient(i) && IsPlayerAlive(i))
		{
			Client_TakeDamage(i, i, 99999, DMG_CRUSH, "");
		}
	}
}
//ragdol dissolve timer
public void Dissolve(int client) 
{
	if (!IsPlayerHere(client)) 
	{
		return;
	}
	
	int ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	if (ragdoll < 0) 
	{
		return;
	}
	
	char dname[32];
	char dtype[32];
	Format(dname, sizeof(dname), "dis_%d", client);
	Format(dtype, sizeof(dtype), "%d", 3);
	int ent = CreateEntityByName("env_entity_dissolver");
	
	if (IsValidEntity(ent)) 
	{
		DispatchKeyValue(ragdoll, "targetname", dname);
		DispatchKeyValue(ent, "dissolvetype", dtype);
		DispatchKeyValue(ent, "target", dname);
		DispatchKeyValue(ent, "magnitude", "10");
		AcceptEntityInput(ent, "Dissolve", ragdoll, ragdoll);
		AcceptEntityInput(ent, "Kill");
	}
}
//hud timer
public Action Timer_Tick(Handle timer) 
{
	if (g_bTimerDieTick == true)
	{
		return Plugin_Stop;
	}
	
	ShowHiddenHP(0.4);
	return Plugin_Continue;
}
//force next hidden?
public Action Cmd_NextHidden(int client, int args) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return Plugin_Continue;
	}
	
	if (args != 1) 
	{
		if (GetCmdReplySource() == SM_REPLY_TO_CHAT) 
		{
			CReplyToCommand(client, "{mediumseagreen}[%s]{powderblue} Usage: {crimson}/nexthidden{powderblue} <player>", PLUGIN_NAME);
		} 
		else 
		{
			ReplyToCommand(client, "[%s] Usage: sm_nexthidden <player>", PLUGIN_NAME);
		}
		return Plugin_Handled;
	}
	
	char tmp[128];
	GetCmdArg(1, tmp, sizeof(tmp));
	int target = FindTarget(client, tmp, false, false);
	
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	if (GetClientTeam(target) <= 1)
	{
		if (GetCmdReplySource() == SM_REPLY_TO_CHAT) 
		{
			CReplyToCommand(client, "{mediumseagreen}[%s]{powderblue} The player you selected isn't on RED or BLU.", PLUGIN_NAME);
		} 
		else 
		{
			ReplyToCommand(client, "[%s] The player you selected isn't on RED or BLU.", PLUGIN_NAME);
		}
		
		return Plugin_Handled;	
	}
	
	g_iForceCommandHidden = GetClientUserId(target);
	CPrintToChat(client, "{mediumseagreen}[%s]{powderblue} The next {crimson}Hidden{powderblue} will be {crimson}%N{powderblue}, regardless of who wins the round.", PLUGIN_NAME, target);
	return Plugin_Handled;
}
//pause the invisibility
void AddHiddenVisible(float value) 
{
	if (g_fHiddenVisible < value) 
	{
		g_fHiddenVisible = value;
	}
}
//is this an arena map?
bool IsArenaMap() 
{
	char curMap[32];
	GetCurrentMap(curMap, sizeof(curMap));
	return strncmp("arena_", curMap, 6, false) == 0;
}
//remove the hidden powers on disconnect
public void OnClientDisconnect(int client) 
{
	g_iDamageToHidden[client] = 0;
	
	if (client == g_iTheCurrentHidden) 
	{
		ResetHidden();
	}
}
//is there enough players? can we play?
bool CanPlay() 
{
	int numClients = Client_Total();
	// Requires 2 or more players, including bots in the server.
	if (numClients >= 2) 
	{
		return true;
	} 
	else 
	{
		return false;
	}
}
//number of players
int Client_Total()
{
	int numClients = 0;
	
	for (int client = 1; client <= MaxClients; client++) {
		
		if (!IsClientConnected(client) || !IsClientInGame(client) || IsClientReplay(client) || IsClientSourceTV(client) || GetClientTeam(client) <= 1 ) 
		{
			continue;
		}
		
		numClients++;
	}
	
	return numClients;
}
//players on blue
int Client_TotalBlue()
{
	int numClients = 0;
	
	for (int client = 1; client <= MaxClients; client++) {
		
		if (!IsClientConnected(client) || !IsClientInGame(client) || IsClientReplay(client) || IsClientSourceTV(client) || GetClientTeam(client) != 3 ) 
		{
			continue;
		}
		
		numClients++;
	}
	
	return numClients;
}
//get a random player
int Client_GetRandom()
{
	int[] clients = new int[MaxClients];
	int num = Client_Get(clients);

	if (num == 0) 
	{
		return -1;
	}
	else if (num == 1) 
	{
		return clients[0];
	}

	int random = GetRandomInt(0, num-1);
	return clients[random];
}
//clients count
int Client_Get(int[] clients)
{
	int x = 0;
	
	for (int client = 1; client <= MaxClients; client++) 
	{
		if (IsPlayerHereLoopCheck(client) && GetClientTeam(client) >= 2) 
		{
			clients[x++] = client;
		}
	}

	return x;
}
//how many enemies left?
int GetAliveEnemiesCount() 
{
	int clients = 0;
	
	for ( int i = 1; i <= MaxClients; i++ ) 
	{
		if ( IsPlayerHereLoopCheck(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 && !IsClientSourceTV(i) && !IsClientReplay(i) ) 
		{
			clients += 1;
		}
	}
	return clients;
}
//select the hidden
void SelectHidden() 
{
	g_iTheCurrentHidden = 0;
	g_iHiddenHpMax = GetConVarInt(g_hCV_hidden_hpbase)+((Client_Total()-1)*GetConVarInt(g_hCV_hidden_hpperplayer));
	g_iHiddenCurrentHp = g_iHiddenHpMax;
	g_fHiddenVisible = 0.0;
	g_fHiddenStamina = g_fCV_hidden_stamina;
	g_bHiddenSticky = false;
	g_fHiddenInvisibility = g_fCV_hidden_starvationtime;
	g_fHiddenBomb = 0.0;
	int forcedcommand = GetClientOfUserId(g_iForceCommandHidden);
	
	if (IsPlayerHere(forcedcommand) && GetClientTeam(forcedcommand) > 1 )
	{
		g_iTheCurrentHidden = forcedcommand;
		g_iForceCommandHidden = 0;
		g_iForceNextHidden = 0;
		CPrintToChatAll("{mediumseagreen}[%s]{powderblue} An admin forced {crimson}%N{powderblue} to be the next {crimson}Hidden{powderblue}.", PLUGIN_NAME, forcedcommand);
	}
	else
	{
		int forced = GetClientOfUserId(g_iForceNextHidden);
		
		if (IsPlayerHere(forced) && GetClientTeam(forced) > 1 ) 
		{
			g_iTheCurrentHidden = forced;
			g_iForceNextHidden = 0;
		} 
		else 
		{
			g_iTheCurrentHidden = Client_GetRandom();
			g_iForceNextHidden = 0;
		}
	}
	
	CPrintToChat(g_iTheCurrentHidden, "{mediumseagreen}[%s]{powderblue} To dash, aim up and press the {crimson}attack2{powderblue} button. You will stick to the walls, if you dash to them while holding the button.", PLUGIN_NAME);
	CPrintToChat(g_iTheCurrentHidden, "{mediumseagreen}[%s]{powderblue} You can press {crimson}jump{powderblue} or dash again to stop pouncing. Aim and press the {crimson}reload{powderblue} button to throw your cluster bomb.", PLUGIN_NAME);
	CPrintToChat(g_iTheCurrentHidden, "{mediumseagreen}[%s]{powderblue} Your own bombs can't hurt you. Every kill restores you some health and decreases your hunger. You take no fall damage. You still have your sapper.", PLUGIN_NAME);
	CreateTimer(3.0, NotifyHidden, g_iTheCurrentHidden, TIMER_FLAG_NO_MAPCHANGE );
}
//superjump
void HiddenSuperJump() 
{
	if (g_iTheCurrentHidden == 0 || HiddenStick() != -1 || g_fHiddenStamina < 1.0) 
	{
		return;
	}
	
	if (!(GetEntityFlags(g_iTheCurrentHidden) & FL_ONGROUND) || g_bJumped)
	{
		return;
	}
	
	float ang[3];
	float vel[3];
	GetClientEyeAngles(g_iTheCurrentHidden, ang);
	GetEntPropVector(g_iTheCurrentHidden, Prop_Data, "m_vecAbsVelocity", vel);
	
	float tmp[3];
	GetAngleVectors(ang, tmp, NULL_VECTOR, NULL_VECTOR);
	
	vel[0] += tmp[0]*700.0;
	vel[1] += tmp[1]*700.0;
	vel[2] += tmp[2]*1400.0;
	
	TeleportEntity(g_iTheCurrentHidden, NULL_VECTOR, NULL_VECTOR, vel);
	AddHiddenVisible(g_fCV_hidden_visible_pounce);
	g_fHiddenStamina -= 1.25;
	g_bJumped = true;
	CreateTimer(1.0, Timer_Jumped, _, TIMER_FLAG_NO_MAPCHANGE);
	return;
}
//stick to the walls
int HiddenStick() 
{
	if (g_iTheCurrentHidden == 0) 
	{
		return 0;
	}	

	if ((GetEntityFlags(g_iTheCurrentHidden) & FL_ONGROUND))
	{
		return 0;
	}
	
	float pos[3];
	float ang[3];
	
	GetClientEyeAngles(g_iTheCurrentHidden, ang);
	GetClientEyePosition(g_iTheCurrentHidden, pos);
	
	Handle ray = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, TraceRay_HitWorld);
	
	if (TR_DidHit(ray)) 
	{
		float pos2[3];
		TR_GetEndPosition(pos2, ray);
		if (GetVectorDistance(pos, pos2)<64.0) 
		{
			if (g_bHiddenSticky) 
			{
				CloseHandle(ray);
				return 0;
			}
			
			g_bHiddenSticky=true;
			SetEntityMoveType(g_iTheCurrentHidden, MOVETYPE_NONE);
			
			CloseHandle(ray);
			return 1;
		} 
		else 
		{
			CloseHandle(ray);
			return -1;
		}
	} 
	else 
	{
		CloseHandle(ray);
		return -1;
	}
}
//unstick the person
void HiddenUnstick() 
{
	g_bHiddenSticky=false;
	if (GetEntityMoveType(g_iTheCurrentHidden) == MOVETYPE_NONE) 
	{
		SetEntityMoveType(g_iTheCurrentHidden, MOVETYPE_WALK);
		float vel[3] = 0.0;
		TeleportEntity(g_iTheCurrentHidden, NULL_VECTOR, NULL_VECTOR, vel);
	}
}
//give vision
void GiveHiddenVision(int i) 
{
	OverlayCommand(i, "effects/combine_binocoverlay");
}
//remove it
void RemoveHiddenVision(int i) 
{
	OverlayCommand(i, "\"\"");
}
//hud stuff
void ShowHiddenHP(float duration) 
{
	if (g_iTheCurrentHidden == 0)
	{
		return;
	}
	
	int perc = RoundToCeil(float(g_iHiddenCurrentHp)/float(g_iHiddenHpMax)*100.0);
	int ponc = RoundToCeil(g_fHiddenStamina/g_fCV_hidden_stamina*100.0);
	int cbomb = RoundToCeil(100.0-g_fHiddenBomb/g_fCV_hidden_bombtime*100.0);
	float starv = g_fHiddenInvisibility/g_fCV_hidden_starvationtime*100.0; 
	int hung = RoundToCeil(100.0-starv);

	if (perc > 25.0) 
	{
		SetHudTextParams(-1.0, 0.1, duration, 10, 255, 10, 255, 1, 0.0, 0.0, 0.0);
	} 
	else 
	{
		SetHudTextParams(-1.0, 0.1, duration, 255, 10, 10, 255, 1, 0.0, 0.0, 0.0);
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerHereLoopCheck(i) && !IsFakeClient(i) && GetClientTeam(i) > 0 && perc != 0.0)
		{
			if(i != g_iTheCurrentHidden)
			{
				ShowHudText(i, 0, "The Hidden's Health: %.0i%%", perc);
			}
			else
			{
				ShowHudText(g_iTheCurrentHidden, 0, "Your Health: %.0i%%", perc);
			
				SetHudTextParams(-1.0, 0.125, duration, 10, 255, 127, 255, 1, 0.0, 0.0, 0.0);
				ShowHudText(g_iTheCurrentHidden, 1, "Stamina: %.0i%%", ponc);
				
				SetHudTextParams(-1.0, 0.150, duration, 10, 127, 255, 255, 1, 0.0, 0.0, 0.0);
				ShowHudText(g_iTheCurrentHidden, 2, "Cluster Bomb: %.0i%%", cbomb);
				
				SetHudTextParams(-1.0, 0.175, duration, 127, 10, 255, 255, 1, 0.0, 0.0, 0.0);
				ShowHudText(g_iTheCurrentHidden, 3, "Hunger: %.0i%%", hung);
				
				SetEntPropFloat(g_iTheCurrentHidden, Prop_Send, "m_flCloakMeter", starv);
			}
		}
	} 
}
//give hidden powers
void GiveHiddenPowers(int i) 
{
	if (!i) 
	{
		return;
	}
	
	TF2_RemoveWeaponSlot(i, 0); // Revolver
	//TF2_RemoveWeaponSlot(i, 1); // Sapper	
	TF2_RemoveWeaponSlot(i, 2); // Knife
	TF2_RemoveWeaponSlot(i, 3); // Disguise Kit
	
	if(!IsFakeClient(i))
	{
		Client_SetHideHud(i, ( 1<<3 ));
		GiveHiddenVision(i);
	}

	TF2_RemoveWeaponSlot(i, 4); // Invisibility Watch

	CreateNamedItem(i, 4, "tf_weapon_knife", 1, 0);
	//CreateNamedItem(i, 1080, "tf_weapon_sapper", 99, 5);
	
	SetEntProp(i, Prop_Data, "m_iMaxHealth", g_iHiddenHpMax);
}
//remove hidden's powers
void RemoveHiddenPowers(int i) 
{
	RemoveHiddenVision(i);
	TF2_RemoveCondition(i, TFCond_Cloaked);
	SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 320.0);
	Client_SetHideHud(i, 0);
}
//hide hidden's hud
void Client_SetHideHud(int client, int flags)
{
	SetEntProp(client, Prop_Send, "m_iHideHUD", flags);
}
//reset the hidden
void ResetHidden() 
{
	if (IsPlayerHere(g_iTheCurrentHidden)) 
	{
		RemoveHiddenPowers(g_iTheCurrentHidden);
	}
	g_iTheCurrentHidden = 0;
}
//set the overlay
void OverlayCommand(int client, char[] overlay) 
{    
	if (IsPlayerHere(client)) 
	{
		SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT));
		ClientCommand(client, "r_screenoverlay %s", overlay);
	}
}
//respawn everyone according to the plan
void Client_RespawnAll(bool Notify, bool Desired) 
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsPlayerHereLoopCheck(i))
		{
			switch (GetClientTeam(i))
			{
				case 0,1:
				{
					continue;
				}
				case 2:
				{
					if (i == g_iTheCurrentHidden)
					{
						if (Desired)
						{
							SetEntProp(i, Prop_Send, "m_lifeState", 2);
							ChangeClientTeam(i, 3);
							SetEntProp(i, Prop_Send, "m_iDesiredPlayerClass", 8);
						}
						else
						{
							SetEntProp(i, Prop_Send, "m_lifeState", 2);
							ChangeClientTeam(i, 3);
							TF2_SetPlayerClass(i, TFClass_Spy);
							CreateTimer(0.1, Timer_Respawn, i, TIMER_FLAG_NO_MAPCHANGE);
						}
						
						if (Notify)
						{
							CPrintToChat(i, "{mediumseagreen}[%s]{powderblue} You can't be on this team.", PLUGIN_NAME);
						}
					}
				}
				case 3:
				{
					if (i != g_iTheCurrentHidden)
					{
						if (Desired)
						{
							SetEntProp(i, Prop_Send, "m_lifeState", 2);
							ChangeClientTeam(i, 2);
							
							if (IsFakeClient(i))
							{
								SetEntProp(i, Prop_Send, "m_iDesiredPlayerClass", 2);
							}
							else
							{
								SetEntProp(i, Prop_Send, "m_iDesiredPlayerClass", PickAClass());
							}							
						}
						else
						{
							SetEntProp(i, Prop_Send, "m_lifeState", 2);
							ChangeClientTeam(i, 2);
							
							if (IsFakeClient(i))
							{
								TF2_SetPlayerClass(i, TFClass_Sniper);
							}
							else
							{
								TF2_SetPlayerClass(i, view_as<TFClassType>(PickAClass()));
							}
							 
							CreateTimer(0.1, Timer_Respawn, i, TIMER_FLAG_NO_MAPCHANGE);
						}
						
						if (Notify)
						{
							CPrintToChat(i, "{mediumseagreen}[%s]{powderblue} You can't be on this team.", PLUGIN_NAME);
						}
					}
				}
			}
		}
	}
}
//shoot the bomb if ready
bool HiddenBombTrigger() 
{
	if (g_iTheCurrentHidden == 0) 
	{
		return false;
	}
	
	if (g_fHiddenBomb > 0.0)
	{
		return false;
	}
	
	g_fHiddenBomb = g_fCV_hidden_bombtime;
	Command_ClusterBomb(g_iTheCurrentHidden);	
	AddHiddenVisible(g_fCV_hidden_visible_bomb);

	return true;
}
//enable or disable the plugin - cvar changed
public void cvhook_enabled(Handle cvar, const char[] oldVal, const char[] newVal) 
{
	if (GetConVarBool(g_hCV_hidden_enabled) && IsArenaMap()) 
	{
		ActivatePlugin();
	} 
	else 
	{
		DeactivatePlugin();
	}
}
//hook convar change for pyro
public void cvhook_allowpyro(Handle cvar, const char[] oldVal, const char[] newVal) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}
	
	if (GetConVarBool(cvar)) 
	{
		CPrintToChatAll("{mediumseagreen}[%s]{powderblue} Class: {crimson}Pyro{powderblue} is now allowed on the team {crimson}IRIS{powderblue}!", PLUGIN_NAME);
	} 
	else 
	{
		CPrintToChatAll("{mediumseagreen}[%s]{powderblue} Class: {crimson}Pyro{powderblue} is no longer allowed on the team {crimson}IRIS{powderblue}!", PLUGIN_NAME);
	}
}
//hook convar change for engie
public void cvhook_allowengineer(Handle cvar, const char[] oldVal, const char[] newVal) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}
	
	if (GetConVarBool(cvar)) 
	{
		CPrintToChatAll("{mediumseagreen}[%s]{powderblue} Class: {crimson}Engineer{powderblue} is now allowed on the team {crimson}IRIS{powderblue}!", PLUGIN_NAME);
	} 
	else 
	{
		CPrintToChatAll("{mediumseagreen}[%s]{powderblue} Class: {crimson}Engineer{powderblue} is no longer allowed on the team {crimson}IRIS{powderblue}!", PLUGIN_NAME);
	}
}
//hook convar change for heavy
public void cvhook_allowheavy(Handle cvar, const char[] oldVal, const char[] newVal) 
{
	if (!GetConVarBool(g_hCV_hidden_enabled)) 
	{
		return;
	}
	
	if (GetConVarBool(cvar)) 
	{
		CPrintToChatAll("{mediumseagreen}[%s]{powderblue} Class: {crimson}Heavy{powderblue} is now allowed on the team {crimson}IRIS{powderblue}!", PLUGIN_NAME);
	} 
	else 
	{
		CPrintToChatAll("{mediumseagreen}[%s]{powderblue} Class: {crimson}Heavy{powderblue} is no longer allowed on the team {crimson}IRIS{powderblue}!", PLUGIN_NAME);
	}
}
//bomb and bomblets
public Action Command_ClusterBomb(int client)
{
	if (IsPlayerHere(client))
	{
		if (IsPlayerAlive(client))
		{
			if (GetMaxEntities() - GetEntityCount() < 200)
			{
				CPrintToChat(client, "{mediumseagreen}[%s]{powderblue} There are too many entities on the map, can't spawn the bomb.", PLUGIN_NAME);
				return Plugin_Handled;
			}
			
			float pos[3];
			float ePos[3];
			float angs[3];
			float vecs[3];			
			GetClientEyePosition(client, pos);
			GetClientEyeAngles(client, angs);
			GetAngleVectors(angs, vecs, NULL_VECTOR, NULL_VECTOR);
			Handle trace = TR_TraceRayFilterEx(pos, angs, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

			if (TR_DidHit(trace))
			{
				TR_GetEndPosition(ePos, trace);
				
				if (GetVectorDistance(ePos, pos, false) < 45.0)
				{
					CPrintToChat(client, "{mediumseagreen}[%s]{powderblue} You are too close to a wall or something like that.", PLUGIN_NAME);
					return Plugin_Handled;
				}
			}
			
			CloseHandle(trace);			
			pos[0] += vecs[0] * 32.0;
			pos[1] += vecs[1] * 32.0;
			ScaleVector(vecs, GetConVarFloat(g_hCV_hidden_bombthrowspeed));
			int ent = CreateEntityByName("prop_physics_override");
			
			if (IsValidEntity(ent))
			{					
				DispatchKeyValue(ent, "model", g_sBombModel);						
				SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
				SetEntProp(ent, Prop_Send, "m_CollisionGroup", 1);
				SetEntProp(ent, Prop_Send, "m_usSolidFlags", 12);
				SetEntProp(ent, Prop_Send, "m_nSolidType", 6);
				SetEntProp(ent, Prop_Send, "m_iTeamNum", 3);
				SetEntProp(ent, Prop_Send, "m_nSkin", 1);
				SetEntPropFloat(ent, Prop_Send, "m_flModelScale", 1.5);
				DispatchSpawn(ent);
				TeleportEntity(ent, pos, NULL_VECTOR, vecs);
				CreateTimer(GetConVarFloat(g_hCV_hidden_bombdetonationdelay), Explode, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}

	return Plugin_Handled;
}
public Action Explode(Handle timer, any enty)
{
	int ent = EntRefToEntIndex(enty);
	if (IsValidEntity(ent))
	{
		float pos[3];
		GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
		pos[2] += 32.0;
		int client = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		int team = GetEntProp(client, Prop_Send, "m_iTeamNum");
		AcceptEntityInput(ent, "Kill");
		int explosion = CreateEntityByName("env_explosion");
		
		if (IsValidEntity(explosion))
		{
			int tMag = GetConVarInt(g_hCV_hidden_bombmagnitude);
			SetEntProp(explosion, Prop_Data, "m_iMagnitude", tMag);
			DispatchKeyValue(explosion, "spawnflags", "0");
			SetEntProp(explosion, Prop_Send, "m_iTeamNum", team);
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", client);
			//SetEntPropEnt(explosion, Prop_Data, "m_hEntityIgnore", client);
			
			int explosion2 = CreateEntityByName("env_physexplosion");
			
			if (IsValidEntity(explosion2))
			{
				char sMag[4];
				IntToString(tMag, sMag, 4);
				SetEntPropString(explosion2, Prop_Data, "m_damage", sMag);
				SetEntProp(explosion2, Prop_Send, "m_iTeamNum", team);
				SetEntPropEnt(explosion2, Prop_Send, "m_hOwnerEntity", client);			
			}
			
			DispatchSpawn(explosion);
			DispatchSpawn(explosion2);
			ActivateEntity(explosion);
			ActivateEntity(explosion2);
			
			TeleportEntity(explosion, pos, NULL_VECTOR, NULL_VECTOR);	
			TeleportEntity(explosion2, pos, NULL_VECTOR, NULL_VECTOR);				
			AcceptEntityInput(explosion, "Explode");
			AcceptEntityInput(explosion2, "Explode");
			AcceptEntityInput(explosion, "Kill");
			AcceptEntityInput(explosion2, "Kill");
		}		
	}
}

bool TraceEntityFilterPlayer(int entity, int mask)
{
	if (mask == -15)
	{
		LogToGame("WutFace");		
	}
	
	return entity > MaxClients || !entity;
}

bool TraceRay_HitWorld(int entityhit, int mask) 
{
	if (mask == -15)
	{
		LogToGame("WutFace");
	}
	
	return entityhit == 0;
}
//creating a weapon
bool CreateNamedItem(int client, int itemindex, char[] classname, int level, int quality)
{
	int weapon=CreateEntityByName(classname);
	if (!IsValidEntity(weapon))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(weapon, entclass, sizeof(entclass));	
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_bInitialized"), 1);	
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(weapon, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);	
	
	if (StrEqual(classname, "tf_weapon_builder", true) || StrEqual(classname, "tf_weapon_sapper", true))
	{
		SetEntProp( weapon, Prop_Send, "m_iObjectType", 3 );
	}
	
	DispatchSpawn(weapon);
	SDKCall(g_hWeaponEquip, client, weapon);
	return true;
} 
//a check used for non-loops
bool IsPlayerHere(int client)
{
	return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}
//a check used for loops
bool IsPlayerHereLoopCheck(int client)
{
	return (IsClientConnected(client) && IsClientInGame(client));
}
//changing the game in server browser
#if defined _steamtools_included
void SetGameDescription() 
{
	char gameDesc[64];
	if (GetConVarBool(g_hCV_hidden_enabled)) 
	{
		Format(gameDesc, sizeof(gameDesc), "%s", PLUGIN_NAME);
	} 
	else 
	{
		gameDesc = "Team Fortress";
	}
	Steam_SetGameDescription(gameDesc);
}
#endif
//a better way to kill players
void Client_TakeDamage(int victim, int attacker, int damage, int dmg_type = DMG_GENERIC, const char[] weapon) 
{ 
  if (IsPlayerHere(victim)) 
  { 
    char sDamage[16]; 
    char sDamageType[32]; 
    IntToString(damage, sDamage, sizeof(sDamage)); 
    IntToString(dmg_type, sDamageType, sizeof(sDamageType)); 
    int index = CreateEntityByName("point_hurt");

    if (IsValidEntity(index)) 
    { 
      DispatchKeyValue(victim,"targetname","cod_hurtme"); 
      DispatchKeyValue(index,"DamageTarget","cod_hurtme"); 
      DispatchKeyValue(index,"Damage", sDamage); 
      DispatchKeyValue(index,"DamageType",sDamageType); 
      DispatchKeyValue(index,"classname",weapon); 
      DispatchSpawn(index); 
      AcceptEntityInput(index,"Hurt", attacker); 
      DispatchKeyValue(index,"classname","point_hurt"); 
      DispatchKeyValue(victim,"targetname","cod_donthurtme"); 
      RemoveEdict(index); 
    } 
  } 
}
//pick a class
int PickAClass()
{
	int x = 0;
	int classes[9];
	bool test3 = GetConVarBool(g_hCV_hidden_allowengineer);
	bool test2 = GetConVarBool(g_hCV_hidden_allowpyro);	
	bool test = GetConVarBool(g_hCV_hidden_allowheavy);

	for (int i = 1; i <= 9; i++)
	{
		if (i <= 5)
		{
			classes[x] = i;
			x++;
		}
		else
		{
			if (test && i == 6)
			{
				classes[x] = i;
				x++;
				continue;
			}
			
			if (test2 && i == 7)
			{
				classes[x] = i;
				x++;
				continue;
			}
			
			if (test3 && i == 9)
			{
				classes[x] = i;
				x++;
				continue;
			}
		}
	}

	x--;
	return classes[GetRandomInt(0,x)];	
}
