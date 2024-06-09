/* SubVersion Keywords
RegExMatch("$LastChangedRevision: 9 $"
         . "$LastChangedDate: 2007-06-18 22:14:16 +0200 (Mo, 18 Jun 2007) $"
         , "(?P<Num>\d+).*?(?P<Date>(?:\d+-?){3})", SVN_Rev)
*/
/* original by majkinetor
www.autohotkey.com/forum/topic17674.html
requires AHK 1.0.46.15
*/

/*
Script = MMenu Module
Version = 1.0
*/

/* =========================================================================
	MMenu													by Miodrag Milic
													 miodrag.milic@gmail.com	
	Interface
	---------
						   
	MMenu_Create	( [options] )
	MMenu_Destroy	( menu )

	MMenu_Add		( menu [,title, icon, position, options ])
	MMenu_Set		( menu, item, title [,icon, options] )
	MMenu_Remove	( menu, item )

	MMenu_Show		( menu, X, Y, OnClick [,OnSelect, OnInit, OnUninit ])
	MMenu_Hide		()
	MMenu_About		()
	
	MMenu_RemoveAll( menu )
  MMenu_Count		 ( menu )
	MMenu_GetPosition(pMenu, ByRef X, ByRef Y) {

	See documentation, in MMenu.htm for more details

============================================================================
*/
/*
  Plus
  MMenu_UpdateItems      by toralf
  
  MMenu_UpdateItems(String)     ;see below
*/

MMenu_RemoveAll( pMenu ) {
   loop, % MMenu_Count(pMenu)
      MMenu_Remove(pMenu, 1)

   return (MMenu_Count(pMenu)=0)
}

MMenu_Create( pOptions="" ) {
	local menu, hMenu

	;Menu info is kept in the MMenu_aMenu array
	;MMenu_aMenu[0] keeps the number of menus

	MMenu_aMenu[0]++
	menu := MMenu_aMenu[0]

	;Create the menu and associate its handle.
	hMenu := MMenu_API_CreatePopupMenu()
	if hMenu < 0		;convert to unsigned integer
		hMenu += 4294967296
	MMenu_aMenu[%menu%] := hMenu
	MMenu_aHandles[%hMenu%] := menu
	
	MMenu_parseMenuOptions( menu, pOptions )

	
	MMenu_setMaxHeight(menu)
	MMenu_setBackground(menu)
	
	return menu
}

MMenu_Count( pMenu ) {
	return MMenu_API_GetMenuItemCount( MMenu_aMenu[%pMenu%] )
}

;------------------------------------------------------------------------

MMenu_Destroy( pMenu ) {
	local hMenu := MMenu_aMenu[%pMenu%]
	MMenu_API_DestroyMenu( hMenu )

	MMenu_freeMenu( pMenu)
}

MMenu_GetPosition(pMenu, ByRef X, ByRef Y, pSelection=false) {
	local hMenu := MMenu_aMenu[%pMenu%]
	local res := 1
	local item

	item = 0
	if (pSelection) 
		loop, % MMenu_API_GetMenuItemCount(hMenu) 
			if MMenu_API_GetMenuState( hMenu, A_Index-1, 0x400) & 0x80     ;MF_HILITE= 0x80
			{
				item := A_Index-1
				break
			}

	MMenu_RECT_Set("MMenu_rect")
	res := DllCall("GetMenuItemRect", "uint", 0, "uint", hMenu, "uint", item, "uint", &MMenu_rect_c)
	MMenu_RECT_Get("MMenu_rect")
	
	X := MMenu_rect_left
	Y := MMenu_rect_top

	return %res%
}
 
;-----------------------------------------------------------------------------
; Add new menu item with specified attributes above pItem
; If pItem doesn't exist, or if it equals to 0, the new item will be appended 
;
; Returns false if pMenu is invalid or true if item is added.
MMenu_Add( pMenu, pTitle="", pIcon="", pItem=0, pOptions="" ) {
	local hMenu := MMenu_aMenu[%pMenu%]
	local idx, res
	static sID

	if (hMenu = "")
		return 0				;ERR_MENU

	sID++
	
	if (pIcon . pTitle . pOptions . pItem = 0)	;check for separator
		pOptions := "s"


	;set the item data
	MMenu_aItem[%sID%]_parent := pMenu
	MMenu_aItem[%sID%]_title  := pTitle


	;get item
	idx := MMenu_getItemIdx( pMenu, pItem )
	res := MMenu_API_InsertMenu(hMenu, idx, 0x0, sID, &pTitle)  ;MF_BYCOMMAND = 0x0

	;set icon
	MMenu_setItemIcon(pMenu, sID, pIcon)

	;set item options
	MMenu_setItemOptions( pMenu, sID, pOptions )
	
	MMenu_aItem[0] := sID
	return res
}

;------------------------------------------------------------------------

MMenu_Set( pMenu, pItem, pTitle="", pIcon="", pOptions="" ){
	local hMenu := MMenu_aMenu[%pMenu%]
	local idx := MMenu_getItemIdx( pMenu, pItem )
	local r	:= 1
	
	
	if !idx				;if invalid item
		return 0

	if (hMenu = "")
		return 0

	if (pTitle != "")
	{
		if (pTitle = " ")
			pTitle =

		r := MMenu_setItemTitle(pMenu, idx, pTitle)
	}

	if (pIcon != "") {
		if (pIcon = " ")
			pIcon = 
		r := MMenu_setItemIcon(pMenu, idx, pIcon) AND r

	}

	if (pOptions != "")
		r := MMenu_setItemOptions( pMenu, idx, pOptions ) AND r
	
	return r ? 1 : 0
}
;------------------------------------------------------------------------

MMenu_Get( pMenu, pItem){
	local hMenu := MMenu_aMenu[%pMenu%]
	local idx := MMenu_getItemIdx( pMenu, pItem )

	if !idx				;if invalid item
		return 0

	if (hMenu = "")
		return 0

  Return MMenu_aItem[%Idx%]_title
}

;- - - - - - - - - - - - - - - -

MMenu_setItemTitle(pMenu, pIdx, pTitle) {
	local hMenu := MMenu_aMenu[%pMenu%]

	MMenu_aItem[%pIdx%]_title := pTitle

	MMenu_mii_fMask := 0x40				;MIIM_STRING
	MMenu_mii_dwTypeData := &pTitle
	MMenu_mii_cch := StrLen(pTitle)
 
	MMenu_MENUITEMINFO_Set("MMenu_mii")
 	return, MMenu_API_SetMenuItemInfo(hMenu, pIdx, false, &MMenu_mii )
}

;- - - - - - - - - - - - - - - -  
; Should set for picon="" too
;
MMenu_setItemIcon(pMenu, pIdx, pIcon) {
	local hMenu		:= MMenu_aMenu[%pMenu%]
	local iconSize	:= MMenu_aMenu[%pMenu%]_iconSize
	local sub		:= MMenu_aItem[%pIdx%]_submenu
	local hSub		:= MMenu_aMenu[%sub%]
	local res := 1

	;remove old icon
	;if (MMenu_aItem[%pIdx%]_separator)
	
	if (MMenu_aItem[%pIdx%]_hIcon != "")
		MMenu_destroyIcon( MMenu_aItem[%pIdx%]_hIcon )

	MMenu_aItem[%pIdx%]_icon := pIcon
	if pIcon is number
		 MMenu_aItem[%pIdx%]_hIcon := MMenu_mii_dwItemData := pIcon
	else MMenu_aItem[%pIdx%]_hIcon := MMenu_mii_dwItemData := MMenu_loadIcon(pIcon, iconSize) 



	if (MMenu_mii_dwItemData != 0)
		 MMenu_aMenu[%pMenu%]_hasIcons := true
	else res := 0


	MMenu_mii_fMask		:= 0x80 | 0x20	;MIIM_BITMAP | MIIM_DATA
	MMenu_mii_hbmpItem	:= -1
	MMenu_MENUITEMINFO_Set("MMenu_mii")
	res := MMenu_API_SetMenuItemInfo(hMenu, pIdx, false, &MMenu_mii) & res
	
	return res
}

;- - - - - - - - - - - - - - - -  

MMenu_setItemOptions(pMenu, pIdx, pOptions) {
	local hMenu := MMenu_aMenu[%pMenu%], sub

	;parse options
	MMenu_parseItemOptions(pIdx, pOptions, pMenu)

	;get previous item state
	MMenu_mii_fMask := 0x1	;MMenu_miiM_STATE
	MMenu_MENUITEMINFO_Set("MMenu_mii")
	MMenu_API_GetMenuItemInfo(hMenu, pIdx, false, &MMenu_mii )
	MMenu_MENUITEMINFO_Get("MMenu_mii")


;TYPE OPTIONS, only one at the time can be set
	if (MMenu_aItem[%pIdx%]_separator)
		 MMenu_mii_fType :=  0x800				;MFT_SEPARATOR

	else if (MMenu_aItem[%pIdx%]_break)
			MMenu_mii_fType := 	MMenu_aItem[%pIdx%]_break = 2 ? 0x20 : 0x40		;MFT_MENUBARBREAK :	MFT_MENUBREAK

		 else MMenu_mii_fType := 0	


;STATE OPTIONS, more can be set
	if (MMenu_aItem[%pIdx%]_grayed)
		 MMenu_mii_fState |= 0x3		;MFS_GRAYED
	else MMenu_mii_fState &= ~0x3

	if (MMenu_aItem[%pIdx%]_check)
		 MMenu_mii_fState |= 0x8		;MFS_CHECKED
	else MMenu_mii_fState &= ~0x8

	if (MMenu_aItem[%pIdx%]_default)
		 MMenu_mii_fState |= 0x1000	    ;MFS_DEFAULT
	else MMenu_mii_fState &= ~0x1000	


;SUBMENU OPTION
	sub  := MMenu_aItem[%pIdx%]_submenu
	if (sub != "") {
		 MMenu_mii_hSubmenu := MMenu_aMenu[%sub%]
		 MMenu_aMenu[%sub%]_parent := pMenu			;!!! if the user adds the same submenu into menu multiple times... who cares
	}
 	else MMenu_mii_hSubmenu := 0


	;set type options
	MMenu_mii_fMask := 0x100			;MIIM_FTYPE	
	MMenu_MENUITEMINFO_Set("MMenu_mii")
	MMenu_API_SetMenuItemInfo(hMenu, pIdx, false, &MMenu_mii )

	;set state options
	MMenu_mii_fMask := 0x1	;MIIM_STATE
	MMenu_MENUITEMINFO_Set("MMenu_mii")
 	MMenu_API_SetMenuItemInfo(hMenu, pIdx, false, &MMenu_mii )

	;set submenu options
	MMenu_mii_fMask := 0x4				;MIIM_SUBMENU = 0x4
	MMenu_MENUITEMINFO_Set("MMenu_mii")
 	MMenu_API_SetMenuItemInfo(hMenu, pIdx, false, &MMenu_mii )

	return 1
}


;------------------------------------------------------------------------
; return false on failure, true on succes
MMenu_Remove( pMenu, pItem=0 ) { 
	local hMenu := MMenu_aMenu[%pMenu%]
	local idx := MMenu_getItemIdx( pMenu, pItem )
	local res

 	res := MMenu_API_RemoveMenu(hMenu, idx, 0x0)		;MF_BYCOMMAND=0x0	
	MMenu_freeItem( idx )

	return res
}

;------------------------------------------------------------------------
; returns items internal id, or 0 on failure
;
MMenu_getItemIdx( pMenu, pItem ) {


	if InStr(pItem, A_Space, false, 0)	{
		StringTrimRight, pItem, pItem, 1
		return MMenu_findItemByTitle( pMenu, pItem)
	}

	if pItem is integer
		 return MMenu_findItemByPos( pMenu, pItem )
    else return MMenu_findItemByID( pMenu, pItem )
}

;------------------------------------------------------------------------
; return 0 on failure
MMenu_findItemByID( pMenu, pID ) {
	local res

	res := MMenu_aID[%pID%] 
	if res =
		return 0

	return res
}

;- - - - - - - - - - - - - - - -  
; return 0 on failure
MMenu_findItemByTitle( pMenu, pTitle ) {
	local hMenu := MMenu_aMenu[%pMenu%]
	local cnt := MMenu_API_GetMenuItemCount(hMenu)
	local buf

	if pTitle = 
		return 0

	VarSetCapacity(buf, 512)
	loop, %cnt%
	{
	  	 DllCall("GetMenuString", "uint", hMenu, "uint", A_Index-1, "str", buf, "uint", 512, "uint", 0x400) ;MF_BYPOSITION = 0x400
		 if (buf = pTitle)
			return MMenu_GetMenuItemID(hMenu, A_Index-1)
	}

	return 0
}

;- - - - - - - - - - - - - - - -  
; return 0 on failure
MMenu_findItemByPos( pMenu, pPos ) {
	local hMenu := MMenu_aMenu[%pMenu%]
	local cnt := MMenu_API_GetMenuItemCount(hMenu)
	local res

	if pPos <= 0
		return 0

	if pPos > cnt
		return 0

	res := MMenu_GetMenuItemID(hMenu, --pPos)
	if res = -1
		return 0
	
	return res

}

;this works for submenus too. Original OS function returns -1 for submenus.
MMenu_getMenuItemID(hMenu, pos){
	global

	MMenu_mii_fMask := 0x2				;MIIM_ID	
	MMenu_mii_wID := 0
	MMenu_MENUITEMINFO_Set("MMenu_mii")
	MMenu_API_GetMenuItemInfo(hMenu, pos, true, &MMenu_mii )
	MMenu_MENUITEMINFO_Get("MMenu_mii")

	return MMenu_mii_wID
}

;------------------------------------------------------------------------

MMenu_freeMenu( pMenu ){
	local hMenu := abs(MMenu_aMenu[%pMenu%])
	local sub

	loop,%MMenu_aItem[0]%
		if (MMenu_aItem[%A_Index%]_parent = pMenu)
		{
			sub := MMenu_aItem[%A_Index%]_submenu
			if ( sub != "")
				MMenu_freeMenu( sub )
			
			MMenu_freeItem( A_Index )
		}

	MMenu_aMenu[%pMenu%]			=
	MMenu_aMenu[%pMenu%]_iconSize	=
	MMenu_aMenu[%pMenu%]_textOffset =
	MMenu_aMenu[%pMenu%]_maxHeight	=
	MMenu_aMenu[%pMenu%]_hasIcons	=
	MMenu_aMenu[%pMenu%]_color		=
	MMenu_aMenu[%pMenu%]_text		=
	MMenu_aMenu[%pMenu%]_parent		=
	MMenu_aHandles[%hMenu%]			=
}

;- - - - - - - - - - - - - - - -  

MMenu_freeItem(pIdx){
	local id :=	MMenu_aItem[%pIdx%]_ID

	if (MMenu_aItem[%pIdx%]_hIcon != "")
		MMenu_destroyIcon( MMenu_aItem[%pIdx%]_hIcon )
	

	MMenu_aItem[%pIdx%]_hIcon	 =
	MMenu_aItem[%pIdx%]_title	 =
	MMenu_aItem[%pIdx%]_icon	 =
 	MMenu_aItem[%pIdx%]_ID		 =
	MMenu_aItem[%pIdx%]_iconSize =
	MMenu_aItem[%pIdx%]_parent	 =
	MMenu_aItem[%pIdx%]_submenu	 =
	MMenu_aItem[%pIdx%]_break	 = 

	MMenu_aID[%id%]	=
}

;------------------------------------------------------------------------
MMenu_Hide(){
	DllCall("EndMenu", "uint", MMenu_hParent)
}


MMenu_parseHandlers( pOptions  ){
	local c, token	

	MMenu_userInit	:= 	MMenu_userUninit := MMenu_userSelect := ""
	MMenu_userMiddle := MMenu_userRight := MMenu_userMenuChar := ""

	Loop, Parse, pOptions, %A_Space%
	{
		StringLeft c, A_LoopField, 1
		StringTrimLeft token, A_LoopField, 1

		if (c="S") {
			MMenu_userSelect := token
			continue
		}

		if (c="I") {
			MMenu_userInit	:= token
			continue
		}
		if (c="U") {
			MMenu_userUninit	:= token
			continue
		}
		if (c="M") {
			MMenu_userMiddle := token
			continue
		}
		if (c="R") {
			MMenu_userRight	:= token
		}

		if (c="C") {
			MMenu_userMenuChar := token
		}
	}

}


MMenu_Show( pMenu, pX, pY, pOnClick, pHandlers="") { 
	local hMenu := MMenu_aMenu[%pMenu%], itemID 

	MMenu_parseHandlers(pHandlers)
	
	if MMenu_hParent =
	{
		Gui 77:+LastFound +ToolWindow
		MMenu_hParent := WinExist()
	}
	Gui 77:Show, ;x0 y0 w100 h100 noactivate

	MMenu_MsgMonitor(true)
	itemID := MMenu_API_TrackPopupMenu( hMenu, 0x100, pX, pY, MMenu_hParent) ;TPM_RETURNCMD = 0x100
	MMenu_MsgMonitor(false)
	Gui 77:Hide

;	A_LastError=1401 -invalid menu handle

	;if menu is canceled, return
	if itemID = 0
		return


	MMenu_Title		:= MMenu_aItem[%itemID%]_title
	MMenu_ID		:= MMenu_aItem[%itemID%]_ID
	MMenu_Menu		:= MMenu_aItem[%itemID%]_parent

	GoSub %pOnClick%
}

;------------------------------------------------------------------------

MMenu_parseMenuOptions( pMenu, pOptions ){
	local c, token

	;defaults
	MMenu_aMenu[%pMenu%]_iconSize := 32
	MMenu_aMenu[%pMenu%]_textOffset := 5
	MMenu_aMenu[%pMenu%]_color := 0xFFFFFF
	MMenu_aMenu[%pMenu%]_text  := 0

	Loop, Parse, pOptions, %A_Space%
	{
		StringLeft c, A_LoopField, 1
		StringTrimLeft token, A_LoopField, 1

		;icon size
		if (c="S")	{
			MMenu_aMenu[%pMenu%]_iconSize := token
			continue
		}

		if (c="O")	{
			MMenu_aMenu[%pMenu%]_textOffset := token
			continue
		}

		if (c="H")	{
			if token < 100
				token := 100 

			MMenu_aMenu[%pMenu%]_maxHeight := token
			continue
		}

		if (c="C")	{
			MMenu_aMenu[%pMenu%]_color := "0x" token
			continue
		}

		if (c="T")	{
			MMenu_aMenu[%pMenu%]_text := "0x" token
			continue
		}
	}
}

;------------------------------------------------------------------------

MMenu_setMaxHeight( pMenu ) {
	local  hMenu := MMenu_aMenu[%pMenu%]

	MMenu_mi_fMask	:= 0x1		;MIM_MAXHEIGHT
	MMenu_mi_cyMax	:= MMenu_aMenu[%pMenu%]_maxHeight

	MMenu_MENUINFO_Set("MMenu_mi")
	MMenu_API_SetMenuInfo( hMenu, &MMenu_mi )
}

;- - - - - - - - - - - - - - - -  

MMenu_parseItemOptions( idx, pOptions, pMenu  )
{
	local c, token, bRemove	
	
	;default values
	MMenu_aItem[%idx%]_color := MMenu_aMenu[%pMenu%]_text 

    Loop, Parse, pOptions, %A_Space%, +
	{
		StringLeft c, A_LoopField, 1
		StringTrimLeft token, A_LoopField, 1

		if (c="-") {
			bRemove := true
			c := chr(*&token) 
		}

		if (c="I")	{
			MMenu_aItem[%idx%]_id := token
			MMenu_aID[%token%] := idx
			continue
		}

		if (c="S")	{
			MMenu_aItem[%idx%]_separator:= bRemove ?  "" : true
			continue
		}

		if (c="D")	{
			MMenu_aItem[%idx%]_default	:= bRemove ?  "" : true
			continue
		}

		if (c="B")	{
			MMenu_aItem[%idx%]_break	:= bRemove ?  "" : (token = "" ? 1 : 2)
			continue
		}

		if (c="G")	{
			MMenu_aItem[%idx%]_grayed	:= bRemove ?  false : true
			continue
		}

		if (c="M")	{
			MMenu_aItem[%idx%]_submenu	:= bRemove ?  "" : token
			continue
		}

		if (c="C")	{
			MMenu_aItem[%idx%]_check	:= bRemove ?  "" : true
			continue
		}

		if (c="T")	{
			MMenu_aItem[%idx%]_color	:= bRemove ?  MMenu_aMenu[%pMenu%]_text  : "0x" token
			continue
		}
	}
}

;------------------------------------------------------------------------
MMenu_msgMonitor( on ){
	local WM_MENUSELECT		= 0x11F
	local WM_MEASUREITEM	= 0x2C
	local WM_DRAWITEM		= 0x2B
	local WM_ENTERMENULOOP	= 0x211
	local WM_INITMENUPOPUP	= 0x117
	local WM_UNINITMENUPOPUP= 0x125
	local WM_MENUSELECT		= 0x11F
	local WM_EXITMENULOOP	= 0x212
	local WM_MENUCOMMAND	= 0x126
	local WM_CONTEXTMENU	= 0x7b
	local WM_MBUTTONDOWN	= 0x207
	local WM_MENUCHAR		= 0x120



	static oldMeasure, oldDraw, oldrbutton, oldMButton, oldMenuChar

	if (on)	{
						OnMessage(WM_ENTERMENULOOP, "MMenu_OnEnterLoop")
		oldMeasure	:=  OnMessage(WM_MEASUREITEM,	"MMenu_OnMeasure")
		oldDraw		:=  OnMessage(WM_DRAWITEM,		"MMenu_OnDraw")
						
						OnMessage(WM_MENUSELECT,    "MMenu_OnSelect")
						OnMessage(WM_INITMENUPOPUP, "MMenu_OnInit")
						OnMessage(WM_UNINITMENUPOPUP,"MMenu_OnUninit")
		oldrbutton	:=	OnMessage(WM_CONTEXTMENU,	"MMenu_OnRButtonDown")
		oldMbutton	:=	OnMessage(WM_MBUTTONDOWN,	"MMenu_OnMButtonDown")
		oldMenuChar :=	OnMessage(WM_MENUCHAR,	"MMenu_OnMenuChar")
	}
	else {
		OnMessage(WM_ENTERMENULOOP)
		OnMessage(WM_MEASUREITEM,	oldMeasure)
		OnMessage(WM_DRAWITEM,		oldDraw)
		OnMessage(WM_INITMENUPOPUP)
		OnMessage(WM_MENUSELECT)
		OnMessage(WM_EXITMENULOOP)
		OnMessage(WM_UNINITMENUPOPUP)
		OnMessage(WM_CONTEXTMENU, oldrbutton)
		OnMessage(WM_MBUTTONDOWN, oldMbutton)
		OnMessage(WM_MENUCHAR,	oldMenuChar)
	}
}

;--------------------------------------------------------------------------------

MMenu_onEnterLoop(){
	return 1
}

;- - - - - - - - - - - - - - - -  
;MIM_BACKGROUND = 2
MMenu_setBackground(pmenu){
	local  hMenu := MMenu_aMenu[%pMenu%]
	
	MMenu_mi_fMask	 := 0x2		;MIM_MAXHEIGHT
	MMenu_mi_hbrBack := MMenu_API_CreateSolidBrush( MMenu_aMenu[%pMenu%]_color )

	MMenu_MENUINFO_Set("MMenu_mi")
	MMenu_API_SetMenuInfo( hMenu, &MMenu_mi )

}

MMenu_onDraw(wparam, lparam){
	local clr, mnu, obj

	MMenu_DRAWITEM_GetA("MMenu_di", lparam)
	if !MMenu_aItem[%MMenu_di_itemID%]_grayed
	{
		obj := MMenu_API_SelectObject( MMenu_di_hDC, MMenu_API_CreateSolidBrush( MMenu_aItem[%MMenu_di_itemID%]_color ) )
		MMenu_API_DeleteObject(obj)
		MMenu_API_SetTextColor(MMenu_di_hDC, MMenu_aItem[%MMenu_di_itemID%]_color)
	}
 	
	MMenu_API_DrawIconEx(MMenu_di_hDC, (MMenu_API_GetMenuCheckMarkDimensions() & 0xFFFF) + 4, MMenu_di_rcItem_Top, MMenu_di_itemData, 0, 0, 0, 0, 3) ;MMenu_di_NORMAL=3	  = MMenu_di_MASK | MMenu_di_IMAGE (1 | 2)
	return 1
}

;- - - - - - - - - - - - - - - -  

MMenu_onMeasure(wparam, lparam) {
	local iconSize, textOffset, menu
	local idx := MMenu_ExtractIntegerAtAddr(lparam, 8,  1)	;pointer to the MEASUREITEMSTRUCT is in lparam

	menu  := MMenu_aItem[%idx%]_parent
	iconSize := MMenu_aMenu[%menu%]_iconSize
	textOffset := MMenu_aMenu[%menu%]_textOffset


	if (MMenu_aItem[%idx%]_hIcon=0)
		if !MMenu_amenu[%menu%]_hasIcons         	;if item  has no icon at all menu has no icons at all, just return
				return 0
		else{
			MMenu_InsertIntegerAtAddr(iconsize + textOffset, lParam, 12)		;else put the width and offset only (without this, windows displays non icon titles bugy)
			return 1
		}

	MMenu_InsertIntegerAtAddr(iconSize + textOffset, lParam, 12)	
	MMenu_InsertIntegerAtAddr(iconSize, lParam, 16)

	return 1
}

;- - - - - - - - - - - - - - - -  

MMenu_onMenuChar(wparam, lparam){
	global

	if MMenu_userMenuChar =
		return 

	MMenu_CMENU := MMenu_aHandles[%lparam%]
	MMenu_CHAR  := wparam & 0xFFFF

	GoSub %MMenu_userMenuChar%
	return 3<<16
}

;- - - - - - - - - - - - - - - -  

MMenu_onInit(wparam, lparam){
	global

	if MMenu_userInit =
		return 

	if wparam < 0		;convert to unsigned integer
		wparam += 4294967296

	; try to fix the deactivation bug
	MMenu_Menu := MMenu_aHandles[%wparam%]

	GoSub %MMenu_userInit%
}

;- - - - - - - - - - - - - - - -  
;wParam
;
;The low-order word specifies the menu item or submenu index. 
;If the selected item is a command item, this parameter contains the identifier of the menu item. 
;If the selected item opens a drop-down menu or submenu, this parameter contains the index of the 
;drop-down menu or submenu in the main menu, and the lParam parameter contains the handle to the 
;main (clicked) menu; use the GetSubMenu function to get the menu handle to the drop-down menu or submenu.
;
MMenu_onSelect(wparam, lparam){
	local idx  := wparam & 0xFFFF
	local menuFlag := wparam >> 16 
	local hSub, gg, menu, sub

	;lparam = 0 represents dummy message that is sent when user press ESC
	if (lparam = 0) or ( MMenu_userSelect = "")
		return 

; 	if lparam < 0		;convert to unsigned integer
; 		hMenu += 4294967296                                ;??? toralf: hMenu isn't global, commented lines, since thy didn't seem logical

	if menuFlag in 32912,144			;MF_POPUP and some number for submenus
	{
		hSub := MMenu_API_GetSubmenu( lparam, idx )
		if hSub < 0		;convert to unsigned integer
			hSub += 4294967296


		menu :=	MMenu_aHandles[%lparam%]	
		sub :=	MMenu_aHandles[%hSub%]
		loop, %MMenu_aItem[0]%
		{
			if (MMenu_aItem[%A_Index%]_parent = menu)
				if (MMenu_aItem[%A_Index%]_submenu = sub)
				{
					idx := A_Index
					break
				}
		}
	}		

	MMenu_SMENU	:= MMenu_aHandles[%lparam%]
	MMenu_SID	:= MMenu_aItem[%idx%]_id
	MMenu_STITLE := MMenu_aItem[%idx%]_title

	GoSub %MMenu_userSelect%
}

;- - - - - - - - - - - - - - - -  

MMenu_onUninit(wparam){
	global

	if MMenu_userUninit =
		return 

	if wparam < 0		;convert to unsigned integer
		wparam += 4294967296

	MMenu_Menu := MMenu_aHandles[%wparam%]
	GoSub %MMenu_userUninit%
}

;- - - - - - - - - - - - - - - -  

MMenu_onRButtonDown(wparam, lparam){
	global

	if MMenu_userRight =
		return 

	GoSub %MMenu_userRight%
}

;- - - - - - - - - - - - - - - -  

MMenu_OnMButtonDown(wparam, lparam){
	global


	if MMenu_userMiddle =
		return 

	GoSub %MMenu_userMiddle%
}

;--------------------------------------------------------------------------------

MMenu_About() {
	local msg
	    , version := "1.0 b1"

	msg .= "MMenu v" . version . " r"  RegExReplace("$LastChangedRevision: 9 $","\$LastChangedRevision: (\d+) \$", "$1")
	    .  "`nOpen source menu extension for AutoHotKey`n`n`n"
 	    .  "Created by:`t`t    Miodrag Milic`n"
	    .  "e-mail:`t`t miodrag.milic@gmail.com`n`n`n"
	    .  "code.r-moth.com   |  www.r-moth.com `n             r-moth.deviantart.com`n"
	return msg
}

MMenu_GetIcon( pPath, pNum=1 ) {
	return, DllCall("Shell32\ExtractIconA", "UInt", 0, "Str", pPath, "UInt", pNum)
}

;--------------------------------------------------------------------------------
;====================================================================================
; API_Draw.ahk
;=====================================================================================

MMenu_loadIcon(pPath, pSize=0)
{
	idx := InStr(pPath, ":", 0, 0)

	if idx >=4
	{
		resPath := SubStr( pPath, 1, idx-1)
		resIdx  := Substr( pPath, idx+1, 8)

		return MMenu_GetIcon( resPath, resIdx ) 
	}
	
;	h := DllCall("GetModuleHandle", "str", "c:\windows\system32\shell32.dll")
	return,  DllCall( "LoadImage" 
                     , "uint", 0 
                     , "str", pPath
                     , "uint", 2                ; IMAGE_ICON
                     , "int", pSize
                     , "int", pSize
                     , "uint", 0x10 | 0x20)     ; LR_LOADFROMFILE | LR_TRANSPARENT
}

;--------------------------------------------------------------------------------

MMenu_destroyIcon(hIcon) {
	return,	DllCall("DestroyIcon", "uint", hIcon)
}

;--------------------------------------------------------------------------------

MMenu_API_DrawIconEx( hDC, xLeft, yTop, hIcon, cxWidth, cyWidth, istepIfAniCur, hbrFlickerFreeDraw, diFlags)
{
    return DllCall("DrawIconEx"
            ,"uint", hDC
            ,"uint", xLeft
            ,"uint", yTop
            ,"uint", hIcon
            ,"int",  cxWidth
            ,"int",  cyWidth
            ,"uint", istepIfAniCur
            ,"uint", hbrFlickerFreeDraw
            ,"uint", diFlags )
}

;--------------------------------------------------------------------------------

MMenu_DRAWITEM_GetA(s, adr){
    global

    %s%_itemID      := MMenu_ExtractIntegerAtAddr(adr,8,  0)
	%s%_itemAction  := MMenu_ExtractIntegerAtAddr(adr,12, 0)
    %s%_itemState   := MMenu_ExtractIntegerAtAddr(adr,16, 0)
    %s%_hwndItem    := MMenu_ExtractIntegerAtAddr(adr,20, 0)
    %s%_hDC         := MMenu_ExtractIntegerAtAddr(adr,24, 0)

    %s%_rcItem_Left   := MMenu_ExtractIntegerAtAddr(adr,28, 0)
    %s%_rcItem_Top    := MMenu_ExtractIntegerAtAddr(adr,32, 0)
    %s%_rcItem_Right  := MMenu_ExtractIntegerAtAddr(adr,36, 0)
    %s%_rcItem_Bottom := MMenu_ExtractIntegerAtAddr(adr,40, 0)
	%s%_itemData	  := MMenu_ExtractIntegerAtAddr(adr,44, 0)
}


;-------------------------------------------------------------------------------------------------
MMenu_API_SetTextColor(hDC, crColor){
	return, DllCall("SetTextColor", "uint", hDC, "uint", crColor)
}


MMenu_API_CreateSolidBrush(crColor){
	return DllCall("CreateSolidBrush", "uint", crColor)
}

MMenu_API_SelectObject( hDC, hgdiobj ){
    return DllCall("SelectObject", "uint", hDC, "uint", hgdiobj)
}

MMenu_API_DeleteObject( hObj ){
   return DllCall("DeleteObject", "uint", hObj)
}


MMenu_RECT_Set(var)
{
	global

	VarSetCapacity(%var%_c, 16 , 0) 
	MMenu_InsertInteger(%var%_left,   %var%_c, 0)	
	MMenu_InsertInteger(%var%_top,    %var%_c, 4)	
	MMenu_InsertInteger(%var%_right,  %var%_c, 8)	  
	MMenu_InsertInteger(%var%_bottom, %var%_c, 12)	
}

MMenu_RECT_Get(var)
{
	global

	%var%_left   := MMenu_ExtractInteger(%var%_c, 0)	
	%var%_top	 := MMenu_ExtractInteger(%var%_c, 4)	
	%var%_right	 := MMenu_ExtractInteger(%var%_c, 8)	  
	%var%_bottom := MMenu_ExtractInteger(%var%_c, 12)	
	%var%_width  := %var%_right - %var%_left
	%var%_height := %var%_bottom - %var%_top
}

MMenu_ExtractInteger(ByRef pSource, pOffset = 0, pIsSigned = false, pSize = 4)
; pSource is a string (buffer) whose memory area contains a raw/binary integer at pOffset.
; The caller should pass true for pSigned to interpret the result as signed vs. unsigned.
; pSize is the size of PSource's integer in bytes (e.g. 4 bytes for a DWORD or Int).
; pSource must be ByRef to avoid corruption during the formal-to-actual copying process
; (since pSource might contain valid data beyond its first binary zero).
{
    Loop %pSize%  ; Build the integer by adding up its bytes.
        result += *(&pSource + pOffset + A_Index-1) << 8*(A_Index-1)
    if (!pIsSigned OR pSize > 4 OR result < 0x80000000)
        return result  ; Signed vs. unsigned doesn't matter in these cases.
    ; Otherwise, convert the value (now known to be 32-bit) to its signed counterpart:
    return -(0xFFFFFFFF - result + 1)
}

MMenu_InsertInteger(pInteger, ByRef pDest, pOffset = 0, pSize = 4)
; The caller must ensure that pDest has sufficient capacity.  To preserve any existing contents in pDest,
; only pSize number of bytes starting at pOffset are altered in it.
{
    Loop %pSize%  ; Copy each byte in the integer into the structure as raw binary data.
        DllCall("RtlFillMemory", "UInt", &pDest + pOffset + A_Index-1, "UInt", 1, "UChar", pInteger >> 8*(A_Index-1) & 0xFF)
}


MMenu_ExtractIntegerAtAddr(pSourceAddr, pOffset = 0, pIsSigned = False, pSize = 4) 
{ 
   Loop, %pSize% 
   { 
      iResult += *(pSourceAddr + pOffset + A_Index - 1) << 8 * (A_Index - 1) 
   } 
   If (pIsSigned && pSize <= 4 && iResult >= 0x80000000) 
   { 
      iResult -= 0x100000000 
   } 
   Return iResult 
}

MMenu_InsertIntegerAtAddr(pInteger, ByRef pDest, pOffset = 0, pSize = 4)
{
	Loop %pSize%  ; Copy each byte in the integer into the structure as raw binary data.
		DllCall("RtlFillMemory", "UInt", pDest + pOffset + A_Index-1, "UInt", 1, "UChar", pInteger >> 8*(A_Index-1) & 0xFF)
}

/*
	-- FUN --
	CreatePopupMenu			() 
	DeleteMenu				( hMenu, uPos, uFlags ) 
	DestroyMenu				( hMenu ) 
	GetMenuCheckMarkDimensions()
	GetMenuItemCount		( hMenu ) 
	GetMenuItemID			( hMenu, nPos )
	GetMenuItemInfo			( hMenu, uItem, fByPosition, lpmii )
	GetMenuState			( hMenu, uId, uFlags )
	GetMenuString			( hMenu, uIDItem, lpString, nMaxCount, uFlag )
	GetSubmenu				( hMenu, nPos) 
	SetMenuItemInfo			( hMenu, uItem, fByPosition, lpmii )
	SetMenuInfo				( hMenu, sMENUINFO )
	TrackPopupMenu			( hMenu, uFlags, X, Y, hWnd ) 
	InsertMenu				( hMenu, uPos, uFlags, uID, pData)
	IsMenu					( hMenu )
	RemoveMenu				( hMenu, uPosition, uFlags )


	-- STRUCTS --
	MENUINFO
	MENUITEMINFO
	SIZE
*/

MMenu_API_GetMenuCheckMarkDimensions() {
	return DllCall("GetMenuCheckMarkDimensions")
}

MMenu_API_GetMenuState( hMenu, uId, uFlags ) {
	return DllCall("GetMenuState", "uint", hMenu, "uint", uID, "uint", uFlags)
}

; API_GetMenuString( hMenu, uIDItem, lpString, nMaxCount, uFlag ){
; 	return DllCall("GetMenuString", "uint", hMenu, "uint", uIDItem, "str", lpString, "uint", nMaxCount, "uint", uFlag)
; }
;  
; API_IsMenu( hMenu ) {
; 	return DllCall("IsMenu", "uint", hMenu)
; }

MMenu_API_GetSubmenu(hMenu, nPos) {
	return DllCall("GetSubMenu", "uint", hMenu, "int", nPos)
}

MMenu_API_RemoveMenu( hMenu, uPosition, uFlags ) {
	return DllCall("RemoveMenu", "uint", hMenu, "uint", uPosition, "uint", uFlags)
}

; API_GetMenuItemID( hMenu, nPos ) {
; 	return DllCall("GetMenuItemID", "uint", hMenu, "int", nPos)
; }

;----------------------------------------------------------

MMenu_API_InsertMenu( hMenu, uPos, uFlags, uID, pData)
{ 
   return DllCall("InsertMenu" 
					,"uint", hMenu
					,"uint", uPos
				    ,"uint", uFlags
			        ,"uint", uID
		            ,"uint", pData) 
}

;----------------------------------------------------------

MMenu_API_GetMenuItemCount( hMenu ) 
{ 
	return DllCall("GetMenuItemCount", "uint", hMenu) 
} 

;----------------------------------------------------------

MMenu_API_CreatePopupMenu() 
{ 
	return DllCall("CreatePopupMenu") 
} 

;----------------------------------------------------------

MMenu_API_DestroyMenu( hMenu ) 
{ 
	return  DllCall("DestroyMenu", "uint", hMenu) 
} 


;----------------------------------------------------------

MMenu_API_TrackPopupMenu( hMenu, uFlags, X, Y, hWnd ) 
{ 
   global 

	return DllCall("TrackPopupMenu" 
               , "uint", hMenu 
               , "uint", uFlags
               , "int", X 
               , "int", Y 
               , "uint", 0 
               , "uint", hWnd
               , "uint", 0) 
} 

;----------------------------------------------------------

MMenu_API_SetMenuInfo(hMenu, sMENUINFO)
{
	return DllCall("SetMenuInfo", "uint", hMenu, "uint", sMENUINFO) 
}

;----------------------------------------------------------

; API_DeleteMenu( hMenu, uPos, uFlags) 
; { 
;    DllCall("DeleteMenu" 
;          ,"uint", hMenu 
;          ,"uint", uPos
;          ,"uint", uFlags) 
; } 

;-------------------------------------------------------------------------------------------------

MMenu_API_SetMenuItemInfo( hMenu, uItem, fByPosition, lpmii)
{
	return, DllCall("SetMenuItemInfo", "uint", hMenu, "uint", uItem, "uint", fByPosition, "uint", lpmii)
}

;-------------------------------------------------------------------------------------------------

MMenu_API_GetMenuItemInfo( hMenu, uItem, fByPosition, lpmii)
{
	return, DllCall("GetMenuItemInfo", "uint", hMenu, "uint", uItem, "uint", fByPosition, "uint", lpmii)
}



/*
=================================================================================================
				
							STRUCTS

==================================================================================================
*/

;typedef struct tagSIZE { 
;  LONG cx; 
;  LONG cy; 
;} SIZE, *PSIZE;
; SIZE_Get(var)
; {
; 	global
; 	%var%_cx := MMenu_ExtractInteger(%var%_c,0)
; 	%var%_cy := MMenu_ExtractInteger(%var%_c,4)
; }
; 
; SIZE_Set(var)
; {
; 	global
; 
; 	VarSetCapacity(%var%_c, 4, 0)
; 	MMenu_InsertInteger(%var%_cx, %var%_c, 0)
; 	MMenu_InsertInteger(%var%_cy, %var%_c, 4)
; }


;-------------------------------------------------------------------------------------------------
;typedef struct tagMENUITEMINFO {
;  UINT    cbSize; 
;  UINT    fMask; 
;  UINT    fType; 
;  UINT    fState; 
;  UINT    wID; 
;  HMENU   hSubMenu; 
;  HBITMAP hbmpChecked; 
;  HBITMAP hbmpUnchecked; 
;  ULONG_PTR dwItemData; 
;  LPTSTR  dwTypeData; 
;  UINT    cch; 
;  HBITMAP hbmpItem;
;} MENUITEMINFO, *LPMENUITEMINFO; 
MMenu_MENUITEMINFO_Get(var)
{
	global
	%var%_fMask			:= MMenu_ExtractInteger(%var%,4)
	%var%_fType			:= MMenu_ExtractInteger(%var%,8)
	%var%_fState		:= MMenu_ExtractInteger(%var%,12) 
	%var%_wID			:= MMenu_ExtractInteger(%var%,16) 
	%var%_hSubMenu		:= MMenu_ExtractInteger(%var%,20) 
	%var%_dwItemData	:= MMenu_ExtractInteger(%var%,32) 
	%var%_dwTypeData	:= MMenu_ExtractInteger(%var%,36) 
	%var%_hbmpItem		:= MMenu_ExtractInteger(%var%,44) 
}

MMenu_MENUITEMINFO_Set(var)
{
	global
	VarSetCapacity(%var%, 48, 0)
	MMenu_InsertInteger(48,				%var%,0)
	MMenu_InsertInteger(%var%_fMask,		%var%,4) 
	MMenu_InsertInteger(%var%_fType,		%var%,8) 
	MMenu_InsertInteger(%var%_fState,		%var%,12) 
	MMenu_InsertInteger(%var%_wID,		%var%,16) 
	MMenu_InsertInteger(%var%_hSubMenu,	%var%,20) 
	MMenu_InsertInteger(%var%_dwItemData,	%var%,32) 
	MMenu_InsertInteger(%var%_dwTypeData,	%var%,36) 
	MMenu_InsertInteger(%var%_cch,		%var%,40) 
	MMenu_InsertInteger(%var%_hbmpItem,	%var%,44) 

}

;----------------------------------------------------------
;typedef struct MENUINFO {
;  DWORD   cbSize;				0
;  DWORD   fMask;				4
;  DWORD   dwStyle;				8
;  UINT    cyMax;				12
;  HBRUSH  hbrBack;				16
;  DWORD   dwContextHelpID;		20
;  ULONG_PTR  dwMenuData;		24
;
MMenu_MENUINFO_Set(var)
{
	global 
	
	VarSetCapacity(%var%, 28, 0) 
	MMenu_InsertInteger(28,				%var%, 0)
	MMenu_InsertInteger(%var%_fMask,		%var%, 4)
	MMenu_InsertInteger(%var%_dwStyle,	%var%, 8)
	MMenu_InsertInteger(%var%_cyMax,		%var%, 12)
	MMenu_InsertInteger(%var%_hbrBack,	%var%, 16)
	MMenu_InsertInteger(%var%_dwMenuData,	%var%, 24)
}

; MENUINFO_Get(var)
; {
; 	global 
; 
; 	%var%_fMask		 := MMenu_ExtractInteger(%var%, 4)
; 	%var%_dwStyle	 := MMenu_ExtractInteger(%var%, 8)
; 	%var%_cyMax		 := MMenu_ExtractInteger(%var%, 12)
; 	%var%_hbrBack	 := MMenu_ExtractInteger(%var%, 16)
; 	%var%_dwMenuData := MMenu_ExtractInteger(%var%, 24)
; }


; update menu items with info on paths
; item menu names must have a common name (ID) and end with "Info/Path/Folder/Keys/Files/Values/LastMod/Size"
; to start the gathering of data specify a string with the data to collect
; to stop the gathering, specify "S[top]" as the parameter
;
; the string with the data to collect is a list of root folders or keys for which data should be put into menu
; needed data for each root folder/key are: "type | path | menu # | menu item names"
;       type                either F[older] or R[egistry]
;       path                the root path (folder or key) from which the search starts
;       menu #              menu number the fields are in
;       menu item names     the common beginning of the menu item IDs
;                             - their individual ID ends with:
;                                   Info
;                                   Path
;                                   Folder Or Keys
;                                   Files  Or Values
;                                   LastMod
;                                   Size   (not available for registry paths)
; Nothing happens in the case that idividual items do not exist in the menu. Thus you can leave some fields out.
; you need to have permission to read the folders or keys to get the data
; as a limited user you might not be able to get the last modified date for registry keys even though that you can read them
MMenu_UpdateItems(String){
    global MMenu_UpdateItems_Stop
    If (InStr(String,"s")=1) {            ;check if the search should be stopped
        MMenu_UpdateItems_Stop := True        ;set status var
        Return
      }
    MMenu_UpdateItems_Stop := False       ;set status var
    
    ;set the list of root folders for which data should be put into menu
    MMenu_UpdateItems_NextFolder(String)
    
    ;start extra thread to gather data for root folders and fill it into menu while it is shown
    SetTimer, MMenu_UpdateItems, On
  }

;get the number of folders and files/keys and values for a given path and put into menu
MMenu_UpdateItems:
  SetTimer, MMenu_UpdateItems, Off         ;stop timer, it will restart itself when needed

  If MMenu_UpdateItems_Stop                ;stop depending on status var, e.g. when menu closed
      Return 

  If ! MMenu_UpdateItems {                 ;if there is currently no root folder that needs to be looked at
      If ! MMenu_UpdateItems := MMenu_UpdateItems_NextFolder()   ;get next root folder with data
          Return                                                      ;when there is no root folder left stop the gathering of data
      StringSplit, MMenu_UpdateItems, MMenu_UpdateItems, |       ;split root folder/key data into components
      MMenu_UpdateItems_Type := MMenu_UpdateItems1               ;root path type
      MMenu_UpdateItems      := MMenu_UpdateItems2               ;root path
      MMenu_UpdateItems_Menu := MMenu_UpdateItems3               ;menu number
      MMenu_UpdateItems_Name := MMenu_UpdateItems4               ;menu item names
      ;fill menu with root path
      MMenu_Set(MMenu_UpdateItems_Menu, MMenu_UpdateItems_Name "Path", MMenu_UpdateItems)                    
      ;inform user by changing the menu title
      MMenu_Set(MMenu_UpdateItems_Menu, MMenu_UpdateItems_Name "Info", "Please wait!")
; FileAppend, %MMenu_UpdateItems%`n, Filename.txt
      ;reset data and gather from root path
      If (InStr(MMenu_UpdateItems_Type,"f")=1)
          MMenu_UpdateItems := MMenu_UpdateItems_Folder(MMenu_UpdateItems "`n",MMenu_UpdateItems_Menu,MMenu_UpdateItems_Name,"Reset")
      Else
          MMenu_UpdateItems := MMenu_UpdateItems_Registry(MMenu_UpdateItems "`n",MMenu_UpdateItems_Menu,MMenu_UpdateItems_Name,"Reset")
  }Else
      ;gather data for folders in paths
      If (InStr(MMenu_UpdateItems_Type,"f")=1)
          MMenu_UpdateItems := MMenu_UpdateItems_Folder(MMenu_UpdateItems,MMenu_UpdateItems_Menu,MMenu_UpdateItems_Name)
      Else
          MMenu_UpdateItems := MMenu_UpdateItems_Registry(MMenu_UpdateItems,MMenu_UpdateItems_Menu,MMenu_UpdateItems_Name)

; FileAppend, %MMenu_UpdateItems%`n, Filename.txt

  If MMenu_UpdateItems                   ;if there are still folders to be looked at
      SetTimer, MMenu_UpdateItems, 250      ;start itself in an extra thread to look for these folders
  Else{                                  ;otherwise
      MMenu_Set(MMenu_UpdateItems_Menu, MMenu_UpdateItems_Name "Info", "Details:")  ;inform user by changing the menu title
      SetTimer, MMenu_UpdateItems, On                  ;start itself again for next root folder
    }
Return

;get the number of folders and files for a given path
; it stops working after a while to let a menu update
; optimized for speed and responsiveness of the menu
MMenu_UpdateItems_Folder(FolderList,menu,name,Reset = 0){
    Static NumFolder,NumFiles,Size,LastModTime,LastFolder

    SetBatchLines, -1        ;speed!

    If Reset {               ;reset, e.g. a new folder path gets searched
        LastModTime = 0
        NumFolder   = 0
        NumFiles    = 0
        Size        = 0
        LastFolder  =
      }
  
    Loop, Parse, FolderList, `n    ;go through list of folders
      {
        If (A_Index > 75)          ;after 75 folders got searched, stop (will be resumed from here with next call)
            Break
        If A_LoopField is space    ;don't search pure `n
            Continue
        DoneFolder .= A_LoopField "`n"     ;remember folders that have been searched
        If (LastFolder = A_LoopField)      ;never scan a folder twice (can happen when there was an error during reading the first time)
            Continue
        LastFolder = %A_LoopField%
        Loop, %A_LoopField%\*, 1, 0        ;get subfolders and files in that folder
          {
            If InStr(A_LoopFileAttrib, "D") {     ;count folders and remember their subfolders to be searched
                NumFolder++
                FolderList .= A_LoopFileLongPath "`n" 
            }Else{                                ;count files, add file size and get latest mod time
                NumFiles++
                Size += A_LoopFileSize
              }
            LastModTime := LastModTime > A_LoopFileTimeModified ? LastModTime : A_LoopFileTimeModified
          }
      }
    StringReplace, FolderList, FolderList, %DoneFolder%     ;remove already searched folders from list
    MMenu_Set(menu, name "Folder",  NumFolder)              ;set until-now gathered data into menu fields
    MMenu_Set(menu, name "Files",   NumFiles)
    MMenu_Set(menu, name "Size",    MMenu_UpdateItems_HumanReadableSize(Size))
    MMenu_Set(menu, name "LastMod", MMenu_UpdateItems_HumanReadableDate(LastModTime))
    Return FolderList                                       ;return still to be searched list of folders
  }
MMenu_UpdateItems_Registry(KeyList,menu,name,Reset = 0){
    Static NumKeys,NumValues,LastModTime,Lastkey

    SetBatchLines, -1        ;speed!

    If Reset {               ;reset, e.g. a new registry path gets searched
        LastModTime = 0
        NumKeys     = 0
        NumValues   = 0
        Lastkey     =
      }

    Loop, Parse, KeyList, `n    ;go through list of keys
      {
        If (A_Index > 75)          ;after 75 keys got searched, stop (will be resumed from here with next call)
            Break
        If A_LoopField is space    ;don't search pure `n
            Continue
        DoneKeys .= A_LoopField "`n"     ;remember keys that have been searched
        If (Lastkey = A_LoopField)      ;never scan a key twice (can happen when there was an error during reading the first time)
            Continue
        Lastkey = %A_LoopField%
        StringLeft, RootKey, A_LoopField, InStr(A_LoopField,"\") - 1    ;get root key and key
        StringTrimLeft, Key, A_LoopField, InStr(A_LoopField,"\")
        Loop, %RootKey%, %Key%, 1, 0            ;get subkeys and values in that key
          {
            If InStr(A_LoopRegType, "Key") {    ;count subkeys and remember their full key path to be searched
                NumKeys++
                KeyList .=  A_LoopRegKey "\" A_LoopRegSubKey "\" A_LoopRegName "`n"
                LastModTime := LastModTime > A_LoopRegTimeModified ? LastModTime : A_LoopRegTimeModified
            }Else{                              ;count values and get latest mod time
                NumValues++
              }
          }
      }
    StringReplace, KeyList, KeyList, %DoneKeys%     ;remove already searched keys from list
    MMenu_Set(menu, name "Keys",    NumKeys)          ;set until-now gathered data into menu fields
    MMenu_Set(menu, name "Values",  NumValues)
    MMenu_Set(menu, name "LastMod", MMenu_UpdateItems_HumanReadableDate(LastModTime))
    Return KeyList                                  ;return still to be searched list of keys
  }

;convert file size in bytes into Gb/Mb/Kb and concatenate unit
MMenu_UpdateItems_HumanReadableSize(Size){
    If (Size > 1024 * 1024 * 1024)
        Size := Round(Size / (1024 * 1024 * 1024),2) " Gb"
    Else If (Size > 1024 * 1024)
        Size := Round(Size / (1024 * 1024),2) " Mb"
    Else If (Size > 1024)
        Size := Round(Size / 1024,2) " Kb"
    Else
        Size .= " b"
    Return Size
  }

;convert a date string into a shortdate
MMenu_UpdateItems_HumanReadableDate(Date){
    FormatTime, Date, %Date%, ShortDate
    Return Date
  }

;Return the next topmost item in a `n separated list and remove it from the list
;specify SetAsNewList to set a new list
MMenu_UpdateItems_NextFolder(SetAsNewList = ""){
    Static List
    If SetAsNewList {
        List = %SetAsNewList%
        Return
      }
    StringSplit, Item, List, `n 
    List := RegExReplace(List,"\Q" Item1 "\E\n?", "", "", 1, 1)
    Return Item1
  }
