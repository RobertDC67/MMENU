/*
--- functions ---

BitBlt                  ( hdcDest, nXDest, nYDest, nWidth, nHeight , hdcSrc, nXSrc, nYSrc, dwRop )
CreateCompatibleBitmap  ( hDC, nWidth, nHeight ) 
CreateCompatibleDC      ( hDC )
CreateSolidBrush		( crColor )
DrawIconEx              ( hDC, xLeft, yTop, hIcon, cxWidth, cyWidth, istepIfAniCur, hbrFlickerFreeDraw, diFlags )
DeleteObject			( hObject )
FillRect				( hDC, lpRec, hBr )
GetTextExtentPoint32    ( hDC, lpString, cbString, lpSize )
GetSysColor				( nIndex )
GetSysColorBrush		( nIndex )
SelectObject            ( hDC, hgdiobj )
SetBkColor				( hDC, crColor )
SetBKMode               ( hDC, iBkMode )
SetTextColor			( hDC, crColor )
TextOut                 ( hDC, nXStart, nYStart, lpString, cbString )

--- structs ---
RECT

--- custom ---
LoadIcon(pPath)
*/

API_DeleteObject( hObj ){
   return DllCall("DeleteObject", "uint", hObj)
}

API_BitBlt( hdcDest, nXDest, nYDest, nWidth, nHeight , hdcSrc, nXSrc, nYSrc, dwRop )
{
    return DllCall("BitBlt"
             , "uint",hdcDest,"int", nXDest, "int", nYDest, "int", nWidth, "int", nHeight
             , "uint",hdcSrc, "int", nXSrc, "int", nYSrc  , "uint", dwRop) 
}

;-------------------------------------------------------------------------------------------------

API_CreateCompatibleBitmap( hdc , nWidth, nHeight ) 
{
    return DllCall("CreateCompatibleBitmap", "uint",hdc, "int", nWidth, "int",nHeight)
}

;-------------------------------------------------------------------------------------------------

API_CreateCompatibleDC(hDC)
{
    return DllCall("CreateCompatibleDC", "uint", hDC)
}

;-------------------------------------------------------------------------------------------------

API_CreateSolidBrush(crColor)
{
	return DllCall("CreateSolidBrush", "uint", crColor)
}

;-------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------

API_FillRect(hDC, lpRec, hBr)
{
	return, DllCall("FillRect", "uint", hDC, "uint", lpRec, "uint", hBr)
}

;-------------------------------------------------------------------------------------------------

API_GetTextExtentPoint32(hDC, lpString, cbString, lpSize)
{
    return, DllCall("GetTextExtentPoint32A", "uint", hDC, "str", lpString, "int", cbString, "uint", lpSize)
}

;-------------------------------------------------------------------------------------------------

API_GetSysColor( nIndex )
{
	return DllCall("GetSysColor", "int", nIndex)
}

API_GetSysColorBrush( nIndex )
{
	return DllCall("GetSysColorBrush", "int", nIndex)
}

;-------------------------------------------------------------------------------------------------


;-------------------------------------------------------------------------------------------------

API_SelectObject( hDC, hgdiobj )
{
    return DllCall("SelectObject", "uint", hDC, "uint", hgdiobj)
}

;-------------------------------------------------------------------------------------------------

API_TextOut(hDC, nXStart, nYStart, lpString, cbString)
{
    return DllCall("TextOut"
            ,"uint", hDC
            ,"uint", nXStart
            ,"uint", nYStart
            ,"str",  lpString
            ,"uint", cbString)
}

;-------------------------------------------------------------------------------------------------

API_LoadIcon(pPath, pW=0, pH=0)
{

    return  DllCall( "LoadImage" 
                     , "uint", 0 
                     , "str", pPath
                     , "uint", 2                ; IMAGE_ICON
                     , "int", pW
                     , "int", pH
                     , "uint", 0x10 | 0x20)     ; LR_LOADFROMFILE | LR_TRANSPARENT
}



DRAWITEM_GetA(s, adr){
    global

	msgbox %s%
    %s%_itemID      := ExtractIntegerAtAddr(adr,8,  0)
    %s%_itemAction  := ExtractIntegerAtAddr(adr,12, 0)
    %s%_itemState   := ExtractIntegerAtAddr(adr,16, 0)
    %s%_hwndItem    := ExtractIntegerAtAddr(adr,20, 0)
    %s%_hDC         := ExtractIntegerAtAddr(adr,24, 0)

    %s%_rcItem_Left   := ExtractIntegerAtAddr(adr,28, 0)
    %s%_rcItem_Top    := ExtractIntegerAtAddr(adr,32, 0)
    %s%_rcItem_Right  := ExtractIntegerAtAddr(adr,36, 0)
    %s%_rcItem_Bottom := ExtractIntegerAtAddr(adr,40, 0)

	%s%_rcItem_Width  := %s%_rcItem_Right  - %s%_rcItem_Left
	%s%_rcItem_Height := %s%_rcItem_Bottom - %s%_rcItem_Top
}

/*
============================================================
			STRUCT
============================================================= 
*/

;typedef struct _RECT { 
;  LONG left; 
;  LONG top; 
;  LONG right; 
;  LONG bottom; 
;} RECT, *PRECT; 
RECT_Set(var)
{
	global

	VarSetCapacity(%var%_c, 16 , 0) 
	InsertInteger(%var%_left,   %var%_c, 0)	
	InsertInteger(%var%_top,    %var%_c, 4)	
	InsertInteger(%var%_right,  %var%_c, 8)	  
	InsertInteger(%var%_bottom, %var%_c, 12)	
}

RECT_Get(var)
{
	global

	%var%_left   := ExtractInteger(%var%_c, 0)	
	%var%_top	 := ExtractInteger(%var%_c, 4)	
	%var%_right	 := ExtractInteger(%var%_c, 8)	  
	%var%_bottom := ExtractInteger(%var%_c, 12)	
	%var%_width  := %var%_right - %var%_left
	%var%_height := %var%_bottom - %var%_top
}