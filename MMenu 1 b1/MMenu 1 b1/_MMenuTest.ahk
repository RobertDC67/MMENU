#SingleInstance force
CoordMode, tooltip, screen

	main := MMenu_Create("O20")
	time  := MMenu_Create("S64 O50")
	sub2 := MMenu_Create("S92 O-8 Ca0")



	icn := "c:\windows\system32\shell32.dll:149"
	MMenu_Add( main, "Network", icn, 0, "c ivNet")
	MMenu_Add( main, "Configuration", "icons\gear.ico", 0, "ivConfig")
	MMenu_Add( main, "Time", "icons\home.ico", 0, "IvTools M" time )
	MMenu_Add( main, "Chat room", "icons\chat.ico", 0, "ivChat M" sub2 )
	MMenu_Add( main )
	MMenu_Add( main, "Exit" )

	MMenu_Add( sub2, "", "icons\home.ico", 0, "iItem1")
	MMenu_Add( sub2, "", "icons\chat.ico", 0, "iItem2")
	MMenu_Add( sub2, "", "icons\pen_red.ico", 0, "iItem3")
	MMenu_Add( sub2, "", "icons\gear.ico", 0, "iItem4")


	MMenu_Show( main, A_SCreenWidth/2-100, A_ScreenHeight/2-100, "OnMMenu", "SOnSelect IOnInit UOnUninit" )
	ExitApp
return

OnMMenu:
	msgbox Title:%M_Title%`nID:%M_ID%`nMenu:%M_Menu%`n
return


OnSelect:
	if StrLen(s) > 500
		s := ""
		
	s = %s%`n SELECT %M_SMENU% %M_STITLE% %M_SID%  
	ShowTooltip(s)
return


OnInit:
	IF (m_menu = main)
		RETURN
	
	s = %s%`n INIT: %M_Menu%

	ShowTooltip(s)
	if (M_Menu = time) and  !init
	{
		init := 1
		MMenu_Add( time, "time title 1", "icons\home.ico", 0, "IvMuhaha33 g d iv1")
		MMenu_Add( time, "time title 2", "icons\chat.ico", 0, "b| d iv2")
		MMenu_Add( time, "time title 3", "icons\pen_red.ico", 0, "d iv3")
		MMenu_Add( time, "time title 4", "icons\gear.ico", "v1", "iv4" )	
	}

	SetTimer, OnTimer, 1000
return


OnUninit:
	s = %s%`n UNINIT: %M_Menu%
	ShowTooltip(s)

	if (M_Menu=time)
		SetTimer, OnTimer, off
return

ShowTooltip(s) {
	global M_SMENU

	MMenu_GetPosition(M_SMENU, X, Y, 0)
	X-=200

	Tooltip %s%, %X%, %Y%
}

OnTimer:
	MMenu_Set( time, "v1", A_Min ":" A_Sec)
	MMenu_Set( time, "v2", A_Min ":" A_Sec)
	MMenu_Set( time, "v3", A_Min ":" A_Sec)
	MMenu_Set( time, "v4", A_TickCount)
return



#include includes
#include MMenu.ahk
#include structs.ahk

