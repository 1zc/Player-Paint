#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define MIN_PAINT_SPACING 1.0

public Plugin myinfo = 
{
	name = "Player Paint",
	author = "Infra",   // Credits to: SlidyBat (Paint Code), Zealain (GOKZ Client-Side Implementation), CabbageMcGravel (MomentumMod Textures)
	description = "Provides client-sided paint functionality for marking landmarks and visibility.", 
	version = "1.0.0", 
	url = "https://github.com/1zc"
};

char gC_PaintColors[][16] =
{
	{ "paint_red" },
	{ "paint_orange" },
	{ "paint_yellow" },
	{ "paint_white" },
	{ "paint_lightblue" },
	{ "paint_blue" },
	{ "paint_cyan" },
	{ "paint_green" },
	{ "paint_darkgreen" },
	{ "paint_purple" },
	{ "paint_lightpink" },
	{ "paint_pink" },
	{ "paint_brown" },
	{ "paint_black" }
};

char gC_PaintSizePostfix[][8] =
{
	{ "" },
	{ "_med" },
	{ "_large" }
};

/* GLOBALS */
Menu    g_hPaintMenu;
Menu    g_hPaintSizeMenu;
Menu 	g_hPaintOptionsMenu;
int     g_PlayerPaintColour[MAXPLAYERS + 1];
int     g_PlayerPaintSize[MAXPLAYERS + 1];
int		gI_Decals[sizeof(gC_PaintColors)][sizeof(gC_PaintSizePostfix)];
float 	gF_LastPaintPos[MAXPLAYERS + 1][3];
bool 	gB_IsPainting[MAXPLAYERS + 1];

/* COOKIES */
Handle	g_hPlayerPaintColour;
Handle	g_hPlayerPaintSize;

public void OnPluginStart()
{	
	LoadTranslations("player-paint.phrases");

	g_hPlayerPaintColour = RegClientCookie( "paint_playerpaintcolour", "paint_playerpaintcolour", CookieAccess_Protected );
	g_hPlayerPaintSize = RegClientCookie( "paint_playerpaintsize", "paint_playerpaintsize", CookieAccess_Protected );

	RegConsoleCmd("+paint", CommandPaintStart, "Starts painting.");
	RegConsoleCmd("-paint", CommandPaintEnd, "Stops painting.");
	RegConsoleCmd("sm_paint", CommandPaint, "Places a single paint mark.");
	RegConsoleCmd( "sm_paintcolor", CommandPaintColour);
	RegConsoleCmd( "sm_paintcolour", CommandPaintColour);
	RegConsoleCmd( "sm_paintsize", CommandPaintSize);
	RegConsoleCmd("sm_paintoptions", CommandPaintOptions);
	RegConsoleCmd("sm_clearpaint", CommandClearDecals, "Executes r_cleardecals on client side.");

	CreatePaintMenus();
	
	/* Late loading */
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnClientCookiesCached(int client)
{
	char sValue[64];

	
	GetClientCookie(client, g_hPlayerPaintColour, sValue, sizeof(sValue));
	g_PlayerPaintColour[client] = StringToInt(sValue);
	
	GetClientCookie(client, g_hPlayerPaintSize, sValue, sizeof(sValue));
	g_PlayerPaintSize[client] = StringToInt(sValue);
}

public void OnMapStart()
{
	char buffer[PLATFORM_MAX_PATH];
	
	AddFileToDownloadsTable("materials/decals/paint/paint_decal.vtf");
	for (int color = 0; color < sizeof(gC_PaintColors); color++)
	{
		for (int size = 0; size < sizeof(gC_PaintSizePostfix); size++)
		{
			Format(buffer, sizeof(buffer), "decals/paint/%s%s.vmt", gC_PaintColors[color], gC_PaintSizePostfix[size]);
			gI_Decals[color][size] = PrecachePaint(buffer);
		}
	}
	
	CreateTimer(0.1, Timer_Paint, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void Paint(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}

	float position[3];
	bool hit = GetPlayerEyeViewPoint(client, position);
	
	if (!hit || GetVectorDistance(position, gF_LastPaintPos[client], true) < MIN_PAINT_SPACING)
	{
		return;
	}
	
	TE_SetupWorldDecal(position, gI_Decals[g_PlayerPaintColour[client]][g_PlayerPaintSize[client]]);
	TE_SendToClient(client);
	 
	gF_LastPaintPos[client] = position;
}

public Action Timer_Paint(Handle timer)
{
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		if (gB_IsPainting[client])
		{
			Paint(client);
		}
	}
}

void CreatePaintMenus()
{
	/* COLOURS MENU */
	delete g_hPaintMenu;
	g_hPaintMenu = new Menu(PaintColourMenuHandle);
	
	g_hPaintMenu.SetTitle("Select Paint Colour:");
	int paintOptionNames = sizeof(gC_PaintColors);

	for(int i = 0; i < paintOptionNames; i++)
	{
		char colourDisplay[32];
		Format(colourDisplay, sizeof(colourDisplay), "%t", gC_PaintColors[i]);
		g_hPaintMenu.AddItem(gC_PaintColors[i], colourDisplay);
	}
	
	/* SIZE MENU */
	delete g_hPaintSizeMenu;
	g_hPaintSizeMenu = new Menu(PaintSizeMenuHandle);
	
	g_hPaintSizeMenu.SetTitle("Select Paint Size:");
	
	for (int i = 0; i < sizeof(gC_PaintSizePostfix); i++)
	{
		char sizeDisplay[32];
		Format(sizeDisplay, sizeof(sizeDisplay), "%t", gC_PaintSizePostfix[i]);
		g_hPaintSizeMenu.AddItem(gC_PaintSizePostfix[i], sizeDisplay);
	}

	/* MAIN OPTIONS MENU */
	delete g_hPaintOptionsMenu;
	g_hPaintOptionsMenu = new Menu(PaintOptionsMenuHandle);

	g_hPaintOptionsMenu.SetTitle("Paint Configuration:");
	g_hPaintOptionsMenu.AddItem("colour", "Select Paint Color");
	g_hPaintOptionsMenu.AddItem("size", "Select Paint Size");
}

public int PaintOptionsMenuHandle(Menu menu, MenuAction menuAction, int param1, int param2)
{
	if (menuAction == MenuAction_Select)
	{
		char selection[32];
		menu.GetItem(param2, selection, sizeof(selection));

		if (StrEqual(selection, "colour"))
		{
			g_hPaintMenu.Display(param1, 20);
		}

		else if (StrEqual(selection, "size"))
		{
			g_hPaintSizeMenu.Display(param1, 20);
		}
	}
}

public int PaintColourMenuHandle(Menu menu, MenuAction menuAction, int param1, int param2)
{
	if (menuAction == MenuAction_Select)
	{
		SetClientPaintColour(param1, param2);
	}
}

public int PaintSizeMenuHandle(Menu menu, MenuAction menuAction, int param1, int param2)
{
	if (menuAction == MenuAction_Select)
	{
		SetClientPaintSize(param1, param2);
	}
}

void SetClientPaintColour(int client, int paint)
{
	char sValue[64];
	g_PlayerPaintColour[client] = paint;
	IntToString(paint, sValue, sizeof(sValue));
	SetClientCookie(client, g_hPlayerPaintColour, sValue);
	
	CPrintToChat(client, "%t \x09Your paint colour has been set: \x04%t", "PREFIX", gC_PaintColors[paint]);
}

void SetClientPaintSize(int client, int size)
{
	char sValue[64];
	g_PlayerPaintSize[client] = size;
	IntToString(size, sValue, sizeof(sValue));
	SetClientCookie(client, g_hPlayerPaintSize, sValue);
	
	CPrintToChat(client, "%t \x09Your paint size has been set: \x04%t", "PREFIX", gC_PaintSizePostfix[size]);
}

void TE_SetupWorldDecal(const float origin[3], int index)
{    
    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin", origin);
    TE_WriteNum("m_nIndex", index);
}

int PrecachePaint(char[] filename)
{
	char path[PLATFORM_MAX_PATH];
	Format(path, sizeof(path), "materials/%s", filename);
	AddFileToDownloadsTable(path);
	
	return PrecacheDecal(filename, true);
}

bool GetPlayerEyeViewPoint(int client, float position[3])
{
	float angles[3];
	GetClientEyeAngles(client, angles);

	float origin[3];
	GetClientEyePosition(client, origin);

	Handle trace = TR_TraceRayFilterEx(origin, angles, MASK_PLAYERSOLID, RayType_Infinite, TraceEntityFilterPlayers);
	if (TR_DidHit(trace))
	{
		TR_GetEndPosition(position, trace);
		delete trace;
		return true;
	}
	delete trace;
	return false;
}

public bool TraceEntityFilterPlayers(int entity, int contentsMask)
{
	return (entity > MaxClients || !entity);
}

//
//
// 	Commands!
//
//

public Action CommandPaintStart(int client, int args)
{
	gB_IsPainting[client] = true;
	return Plugin_Handled;
}

public Action CommandPaintEnd(int client, int args)
{
	gB_IsPainting[client] = false;
	return Plugin_Handled;
}

public Action CommandPaint(int client, int args)
{
	if (CheckCommandAccess(client, "+paint", ADMFLAG_ROOT))
	{
		Paint(client);
	}

	return Plugin_Handled;
}

public Action CommandPaintColour(int client, int args)
{
	if (CheckCommandAccess(client, "+paint", ADMFLAG_ROOT))
	{
		g_hPaintMenu.Display(client, 20);
	}

	else
	{
		CPrintToChat(client, "%t %t", "PREFIX", "NoAccess");
	}
	
	return Plugin_Handled;
}

public Action CommandPaintSize(int client, int args)
{
	if (CheckCommandAccess(client, "+paint", ADMFLAG_ROOT))
	{
		g_hPaintSizeMenu.Display(client, 20);
	}

	else
	{
		CPrintToChat(client, "%t %t", "PREFIX", "NoAccess");
	}
	
	return Plugin_Handled;
}

public Action CommandPaintOptions(int client, int args)
{
	if (CheckCommandAccess(client, "+paint", ADMFLAG_ROOT))
	{
		g_hPaintOptionsMenu.Display(client, 20);
	}

	else 
	{
		CPrintToChat(client, "%t %t", "PREFIX", "NoAccess");
	}

	return Plugin_Handled;
}

public Action CommandClearDecals(int client, int args)
{
	CPrintToChat(client, "%t \x09Enter \x02r_cleardecals\x09 in your console to clear Paint decals.", "PREFIX");
	return Plugin_Handled;
}