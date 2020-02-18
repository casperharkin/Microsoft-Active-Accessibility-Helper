#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


Extract_ACC_Funcs(A_MyDocuments . "\Autohotkey\Lib\ACC.ahk")
Menu Tray, Icon, C:\Windows\System32\SHELL32.dll,98

 
Global Selection, Options, Template, InputOutputControl, result, Path, title, TestText, Selection

Options := 	{"ControlSend":"ControlSend, ,@@@@,"
			,"ControlClick":"ControlClick,,"
			,"ControlFocus":"ControlFocus,,"
			,"ControlSetText":"ControlSetText,,@@@@,"
			,"ControlGetText":"ControlGetText,####,,"}

Gui, Font,, Verdana 
Gui Color, FFFFFF
GUI,Font, CWhite
Gui Add, Text, x0 y0 w430 h94   +0x4E +HWNDhGUIBG +BackgroundTrans,
DllCall("SendMessage", "Ptr", hGUIBG, "UInt", 0x172, "Ptr", 0, "Ptr", CreateDIB("0173C7", 1, 1))
Gui, Font, S12 +bold
Gui Add, Text, x9 y6 w400 h30 +Center +BackgroundTrans,Microsoft Active Accessibility Helper
Gui, Font, S6 +Norm 
Gui Add, Text, x11 y70 w35 h26 +Center +BackgroundTrans gCrossHair, DRAG CURSOR
Gui Add, Text, x17 y33 w25 h26 Border gCrossHair
Gui Add, Text, x17 y33 w25 h4 Border 
Gui Add, Text, x20 y48 w19 h1  Border 
Gui Add, Text, x29 y38 w1 h19 Border 

GUI,Font,
Gui, Font, S10
Gui Add, DropDownList, x62 y33 w200 vSelection gDropDownListSelection, ControlSend||ControlClick|ControlFocus|ControlSetText|ControlGetText
Gui Add, Edit, x62 y+5 w200 h22 hwndInputOutputControl  vTestText, Type Text to Send.
Gui Add, Button, x267 y33 w144 h57 gExecScript, Test Code
Gui Add, Edit,  x10 y100 w400 h120 +Multi +ReadOnly vEditControlDisplay, 
Gui Add, Edit, x10 y+5 w400 h128 +Multi vdisplayCode r6 -Wrap 
Gui, Show, Center w420, Microsoft Active Accessibility Helper
return

DropDownListSelection()
{
	Gui, submit, nohide
	If (Selection = "ControlClick") or (Selection = "ControlFocus") or (Selection = "ControlGetText")
		{
			GuiControl, disable, % InputOutputControl
			GuiControl, text, % InputOutputControl, % "N/A - " Selection
		}
	if (Selection = "ControlSend") or (Selection = "ControlSetText")
		{
			GuiControl, enable, % InputOutputControl
			GuiControl, -ReadOnly, % InputOutputControl
			GuiControl, text, % InputOutputControl, Type Text to Send
		}
	If (Selection = "ControlGetText")
		{
			GuiControl, enable, % InputOutputControl
			GuiControl, +ReadOnly, % InputOutputControl
			GuiControl, text, % InputOutputControl, Text Will Show Here
					ControlGetText, result,, ahk_id %ControlHwnd%
		SelectedCode := StrReplace(Options[Selection], "####", "result")
		GuiControl, text, % InputOutputControl, % result	

		}
		Template := Code(Path, title, TestText, Selection)
		GuiControl, text, displayCode, %Template%
}

~Lbutton Up::
if (CH = false) and (Lbutton_Pressed = true) 
	{ 
        GuiControl, Show, HBar
        GuiControl, Show, VBar
		CrossHair(CH:=true)
		Template := Code(Path, title, TestText, Selection)
		GuiControl,text, displayCode, %Template%
		Lbutton_Pressed := False
	}
Return	

CrossHair: 
gui, submit, nohide
GuiControl, Hide, HBar
GuiControl, Hide, VBar
CrossHair(CH:=false)
Lbutton_Pressed := True
	while, Lbutton_Pressed
		{
			MouseGetPos, , , id, control
			WinGetTitle, title, ahk_id %id%
			WinGetClass, class, ahk_id %id%
			oAcc := Acc_ObjectFromPoint(vChildID)
			Path := JEE_AccGetPath(oAcc, hWnd)
			GuiControl, text, EditControlDisplay, ID:________%id%`nClass:_____ %class%`nTitle:______ %title%`nControl:____%control%`nACCPath:__ %path%
		}
return

ExecScript:
ExecScript(Template,,A_AhkPath)
return

Code(Path, title, text, Selection) {
WinGet,hWnd,id, %title%
oAcc := Acc_Get("Object", path, 0, "ahk_id " hWnd)
ControlHwnd := Acc_WindowFromObject(oAcc)
SelectedCode := StrReplace(Options[Selection], "@@@@", text)

If (Selection = "ControlGetText") {
		ControlGetText, result,, ahk_id %ControlHwnd%
		SelectedCode := StrReplace(Options[Selection], "####", "result")
		GuiControl, text, % InputOutputControl, % result	
}

Template =
(
WinActivate ahk_exe %title%
WinGet, hWnd, id, %title%
oAcc := Acc_Get("Object", %path%, 0, "ahk_id " %hWnd%) 
ControlHwnd := Acc_WindowFromObject(oAcc)
ControlFocus, , ahk_id %ControlHwnd%
%SelectedCode% ahk_id %ControlHwnd%
)
return Template
}


GuiClose:
CrossHair(true)
ExitApp
return

CrossHair(OnOff=1) {  ; Change Cursor to Cross-Hair
    ; INIT = "I","Init"; OFF = 0,"Off"; TOGGLE = -1,"T","Toggle"; ON = others
	static AndMask, XorMask, $, h_cursor, IDC_CROSS := 32515
        ,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13 ; system cursors
        , b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13   ; blank cursors
        , h1,h2,h3,h4,h5,h6,h7,h8,h9,h10,h11,h12,h13   ; handles of default cursors
    if (OnOff = "Init" or OnOff = "I" or $ = "") {      ; init when requested or at first call
        $ := "h"                                          ; active default cursors
        , VarSetCapacity( h_cursor,4444, 1 )
        , VarSetCapacity( AndMask, 32*4, 0xFF )
        , VarSetCapacity( XorMask, 32*4, 0 )
        , system_cursors := "32512,32513,32514,32515,32516,32642,32643,32644,32645,32646,32648,32649,32650"
        StringSplit c, system_cursors, `,
        Loop, %c0%
            h_cursor   := DllCall( "LoadCursor", "uint",0, "uint",c%A_Index% )
            , h%A_Index% := DllCall( "CopyImage",  "uint",h_cursor, "uint",2, "int",0, "int",0, "uint",0 )
            , b%A_Index% := DllCall("LoadCursor", "Uint", "", "Int", IDC_CROSS, "Uint")
    }
    $ := (OnOff = 0 || OnOff = "Off" || $ = "h" && (OnOff < 0 || OnOff = "Toggle" || OnOff = "T")) ? "b" : "h"

    Loop, %c0%
        h_cursor := DllCall( "CopyImage", "uint",%$%%A_Index%, "uint",2, "int",0, "int",0, "uint",0 )
        , DllCall( "SetSystemCursor", "uint",h_cursor, "uint",c%A_Index% )
; http://www.autohotkey.com/docs/commands/DllCall.htm
; http://www.autohotkey.com/forum/topic4570.html#75609
}

JEE_AccGetPath(oAcc, hWnd:="")
{ ;https://www.autohotkey.com/boards/viewtopic.php?t=56470
	local
	if (hWnd = "")
		hWnd := Acc_WindowFromObject(oAcc)
		, hWnd := DllCall("user32\GetParent", Ptr,hWnd, Ptr)
	vAccPath := ""
	vIsMatch := 0
	if (hWnd = -1) ;get all possible ancestors
		Loop
		{
			vIndex := JEE_AccGetEnumIndex(oAcc)
			if !vIndex
				break
			vAccPath := vIndex (A_Index=1?"":".") vAccPath
			oAcc := oAcc.accParent
		}
	else
		Loop
		{
			vIndex := JEE_AccGetEnumIndex(oAcc)
			hWnd2 := Acc_WindowFromObject(oAcc)
			if !vIsMatch && (hWnd = hWnd2)
				vIsMatch := 1
			if vIsMatch && !(hWnd = hWnd2)
				break
			vAccPath := vIndex (A_Index=1?"":".") vAccPath
			oAcc := oAcc.accParent
			if (A_Index > 5)
				break
		}
	if vIsMatch
		return SubStr(vAccPath, InStr(vAccPath, ".")+1)
	return vAccPath
}

JEE_AccGetEnumIndex(oAcc, vChildID:=0)
{
	local
	vOutput := ""
	vAccState := oAcc.accState(0)
	if !vChildID
	{
		Acc_Location(oAcc, 0, vChildPos)
		for _, oChild in Acc_Children(Acc_Parent(oAcc))
		{
			if !(vAccState = oChild.accState(0))
				continue
			Acc_Location(oChild, 0, vPos)
			if IsObject(oChild) && (vPos = vChildPos)
				vOutput .= A_Index "or"
		}
	}
	else
	{
		Acc_Location(oAcc, vChildID, vChildPos)
		for _, oChild in Acc_Children(oAcc)
		{
			if !(vAccState = oChild.accState(0))
				continue
			Acc_Location(oAcc, oChild, vPos)
			if !IsObject(oChild) && (vPos = vChildPos)
				vOutput .= A_Index "or"
		}
	}
	return SubStr(vOutput, 1, -2)
}

ExecScript(Script, Params="", AhkPath="")
{ ;https://github.com/G33kDude/CodeQuickTester
    static Shell := ComObjCreate("WScript.Shell")
    Name := "\\.\pipe\AHK_CQT_" A_TickCount
    Pipe := []
    Loop, 3
    {
        Pipe[A_Index] := DllCall("CreateNamedPipe"
        , "Str", Name
        , "UInt", 2, "UInt", 0
        , "UInt", 255, "UInt", 0
        , "UInt", 0, "UPtr", 0
        , "UPtr", 0, "UPtr")
    }
    if !FileExist(AhkPath)
        throw Exception("AutoHotkey runtime not found: " AhkPath)
    if (A_IsCompiled && AhkPath == A_ScriptFullPath)
        AhkPath .= " /E"
    if FileExist(Name)
    {
        Exec := Shell.Exec(AhkPath " /CP65001 " Name " " Params)
        DllCall("ConnectNamedPipe", "UPtr", Pipe[2], "UPtr", 0)
        DllCall("ConnectNamedPipe", "UPtr", Pipe[3], "UPtr", 0)
        FileOpen(Pipe[3], "h", "UTF-8").Write(Script)
    }
    else ; Running under WINE with improperly implemented pipes
    {
        FileOpen(Name := "AHK_CQT_TMP.ahk", "w").Write(Script)
        Exec := Shell.Exec(AhkPath " /CP65001 " Name " " Params)
    }
    Loop, 3
        DllCall("CloseHandle", "UPtr", Pipe[A_Index])
    return Exec
}


CreateDIB(Input, W, H, ResizeW := 0, ResizeH := 0, Gradient := 1 ) {
	WB := Ceil((W * 3) / 2) * 2, VarSetCapacity(BMBITS, (WB * H) + 1, 0), P := &BMBITS
	Loop, Parse, Input, |
	{
		P := Numput("0x" . A_LoopField, P + 0, 0, "UInt") - (W & 1 && Mod(A_Index * 3, W * 3) = 0 ? 0 : 1)
	}
	hBM := DllCall("CreateBitmap", "Int", W, "Int", H, "UInt", 1, "UInt", 24, "Ptr", 0, "Ptr")
	hBM := DllCall("CopyImage", "Ptr", hBM, "UInt", 0, "Int", 0, "Int", 0, "UInt", 0x2008, "Ptr")
	DllCall("SetBitmapBits", "Ptr", hBM, "UInt", WB * H, "Ptr", &BMBITS)
	If (Gradient != 1) {
		hBM := DllCall("CopyImage", "Ptr", hBM, "UInt", 0, "Int", 0, "Int", 0, "UInt", 0x0008, "Ptr")
	}
	return DllCall("CopyImage", "Ptr", hBM, "Int", 0, "Int", ResizeW, "Int", ResizeH, "Int", 0x200C, "UPtr")
}

GdipCreateFromBase(B64, IsIcon := 0) 
{
	VarSetCapacity(B64Len, 0)
	DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", StrLen(B64), "UInt", 0x01, "Ptr", 0, "UIntP", B64Len, "Ptr", 0, "Ptr", 0)
	VarSetCapacity(B64Dec, B64Len, 0) ; pbBinary size
	DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", StrLen(B64), "UInt", 0x01, "Ptr", &B64Dec, "UIntP", B64Len, "Ptr", 0, "Ptr", 0)
	pStream := DllCall("Shlwapi.dll\SHCreateMemStream", "Ptr", &B64Dec, "UInt", B64Len, "UPtr")
	VarSetCapacity(pBitmap, 0)
	DllCall("Gdiplus.dll\GdipCreateBitmapFromStreamICM", "Ptr", pStream, "PtrP", pBitmap)
	VarSetCapacity(hBitmap, 0)
	DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "UInt", pBitmap, "UInt*", hBitmap, "Int", 0XFFFFFFFF)

	If (IsIcon) 
		DllCall("Gdiplus.dll\GdipCreateHICONFromBitmap", "Ptr", pBitmap, "PtrP", hIcon, "UInt", 0)
	
	ObjRelease(pStream)
	return (IsIcon ? hIcon : hBitmap)
}

ACC_Funcs_Get(_What)
{
	Static Size = 7850, Name = "Acc.ahk", Extension = "ahk", Directory = "C:\Users\babb\Documents\Autohotkey\Lib"
	, Options = "Size,Name,Extension,Directory"
	;This function returns the size(in bytes), name, filename, extension or directory of the file stored depending on what you ask for.
	If (InStr("," Options ",", "," _What ","))
		Return %_What%
}

Extract_ACC_Funcs(_Filename, _DumpData = 0)
{
	;This function "extracts" the file to the location+name you pass to it.
	Static HasData = 1, Out_Data, Ptr
	Static 1
	1 := "OyBodHRwOi8vd3d3LmF1dG9ob3RrZXkuY29tL2JvYXJkL3RvcGljLzc3MzAzLWFjYy1saWJyYXJ5LWFoay1sLXVwZGF0ZWQtMDkyNzIwMTIvDQo7IGh0dHBzOi8vZGwuZHJvcGJveC5jb20vdS80NzU3MzQ3My9XZWIlMjBTZXJ2ZXIvQUhLX0wvQWNjLmFoaw0KOy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQ0KOyBBY2MuYWhrIFN0YW5kYXJkIExpYnJhcnkNCjsgYnkgU2Vhbg0KOyBVcGRhdGVkIGJ5IGpldGhyb3c6DQo7IAlNb2RpZmllZCBDb21PYmpFbndyYXAgcGFyYW1zIGZyb20gKDkscGFjYykgLS0+ICg5LHBhY2MsMSkNCjsgCUNoYW5nZWQgQ29tT2JqVW53cmFwIHRvIENvbU9ialZhbHVlIGluIG9yZGVyIHRvIGF2b2lkIEFkZFJlZiAodGhhbmtzIGZpbmNzKQ0KOyAJQWRkZWQgQWNjX0dldFJvbGVUZXh0ICYgQWNjX0dldFN0YXRlVGV4dA0KOyAJQWRkZWQgYWRkaXRpb25hbCBmdW5jdGlvbnMgLSBjb21tZW50ZWQgYmVsb3cNCjsgCVJlbW92ZWQgb3JpZ2luYWwgQWNjX0NoaWxkcmVuIGZ1bmN0aW9uDQo7IGxhc3QgdXBkYXRlZCAyLzI1LzIwMTANCjstLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0NCg0KQWNjX0luaXQoKQ0Kew0KCVN0YXRpYwloDQoJSWYgTm90CWgNCgkJaDo9RGxsQ2FsbCgiTG9hZExpYnJhcnkiLCJTdHIiLCJvbGVhY2MiLCJQdHIiKQ0KfQ0KQWNjX09iamVjdEZyb21FdmVudChCeVJlZiBfaWRDaGlsZF8sIGhXbmQsIGlkT2JqZWN0LCBpZENoaWxkKQ0Kew0KCUFjY19Jbml0KCkNCglJZglEbGxDYWxsKCJvbGVhY2NcQWNjZXNzaWJsZU9iamVjdEZyb21FdmVudCIsICJQdHIiLCBoV25kLCAiVUludCIsIGlkT2JqZWN0LCAiVUludCIsIGlkQ2hpbGQsICJQdHIqIiwgcGFjYywgIlB0ciIsIFZhclNldENhcGFjaXR5KHZhckNoaWxkLDgrMipBX1B0clNpemUsMCkqMCsmdmFyQ2hpbGQpPTANCglSZXR1cm4JQ29tT2JqRW53cmFwKDkscGFjYywxKSwgX2lkQ2hpbGRfOj1OdW1HZXQodmFyQ2hpbGQsOCwiVUludCIpDQp9DQoNCkFjY19PYmplY3RGcm9tUG9pbnQoQnlSZWYgX2lkQ2hpbGRfID0gIiIsIHggPSAiIiwgeSA9ICIiKQ0Kew0KCUFjY19Jbml0KCkNCglJZglEbGxDYWxsKCJvbGVhY2NcQWNjZXNzaWJsZU9iamVjdEZyb21Qb2ludCIsICJJbnQ2NCIsIHg9PSIifHx5PT0iIj8wKkRsbENhbGwoIkdldEN1cnNvclBvcyIsIkludDY0KiIscHQpK3B0OngmMHhGRkZGRkZGRnx5PDwzMiwgIlB0cioiLCBwYWNjLCAiUHRyIiwgVmFyU2V0Q2FwYWNpdHkodmFyQ2hpbGQsOCsyKkFfUHRyU2l6ZSwwKSowKyZ2YXJDaGlsZCk9MA0KCVJldHVybglDb21PYmpFbndyYXAoOSxwYWNjLDEpLCBfaWRDaGlsZF86PU51bUdldCh2YXJDaGlsZCw4LCJVSW50IikNCn0NCg0KQWNjX09iamVjdEZyb21XaW5kb3coaFduZCwgaWRPYmplY3QgPSAtNCkNCnsNCglBY2NfSW5pdCgpDQoJSWYJRGxsQ2FsbCgib2xlYWNjXEFjY2Vzc2libGVPYmplY3RGcm9tV2luZG93IiwgIlB0ciIsIGhXbmQsICJVSW50IiwgaWRPYmplY3QmPTB4RkZGRkZGRkYsICJQdHIiLCAtVmFyU2V0Q2FwYWNpdHkoSUlELDE2KStOdW1QdXQoaWRPYmplY3Q9PTB4RkZGRkZGRjA/MHg0NjAwMDAwMDAwMDAwMEMwOjB4NzE5QjM4MDBBQTAwMEM4MSxOdW1QdXQoaWRPYmplY3Q9PTB4RkZGRkZGRjA/MHgwMDAwMDAwMDAwMDIwNDAwOjB4MTFDRjNDM0Q2MTg3MzZFMCxJSUQsIkludDY0IiksIkludDY0IiksICJQdHIqIiwgcGFjYyk9MA0KCVJldHVybglDb21PYmpFbndyYXAoOSxwYWNjLDEpDQp9DQoNCkFjY19XaW5kb3dGcm9tT2JqZWN0KHBhY2MpDQp7DQoJSWYJRGxsQ2FsbCgib2xlYWNjXFdpbmRvd0Zyb21BY2Nlc3NpYmxlT2JqZWN0IiwgIlB0ciIsIElzT2JqZWN0KHBhY2MpP0NvbU9ialZhbHVlKHBhY2MpOnBhY2MsICJQdHIqIiwgaFduZCk9MA0KCVJldHVybgloV25kDQp9DQoNCkFjY19HZXRSb2xlVGV4dChuUm9sZSkNCnsNCgluU2l6ZSA6PSBEbGxDYWxsKCJvbGVhY2NcR2V0Um9sZVRleHQiLCAiVWludCIsIG5Sb2xlLCAiUHRyIiwgMCwgIlVpbnQiLCAwKQ0KCVZhclNldENhcGFjaXR5KHNSb2xlLCAoQV9Jc1VuaWNvZGU/MjoxKSpuU2l6ZSkNCglEbGxDYWxsKCJvbGVhY2NcR2V0Um9sZVRleHQiLCAiVWludCIsIG5Sb2xlLCAic3RyIiwgc1JvbGUsICJVaW50IiwgblNpemUrMSkNCglSZXR1cm4Jc1JvbGUNCn0NCg0KQWNjX0dldFN0YXRlVGV4dChuU3RhdGUpDQp7DQoJblNpemUgOj0gRGxsQ2FsbCgib2xlYWNjXEdldFN0YXRlVGV4dCIsICJVaW50IiwgblN0YXRlLCAiUHRyIiwgMCwgIlVpbnQiLCAwKQ0KCVZhclNldENhcGFjaXR5KHNTdGF0ZSwgKEFfSXNVbmljb2RlPzI6MSkqblNpemUpDQoJRGxsQ2FsbCgib2xlYWNjXEdldFN0YXRlVGV4dCIsICJVaW50IiwgblN0YXRlLCAic3RyIiwgc1N0YXRlLCAiVWludCIsIG5TaXplKzEpDQoJUmV0dXJuCXNTdGF0ZQ0KfQ0KDQpBY2NfU2V0V2luRXZlbnRIb29rKGV2ZW50TWluLCBldmVudE1heCwgcENhbGxiYWNrKQ0Kew0KCVJldHVybglEbGxDYWxsKCJTZXRXaW5FdmVudEhvb2siLCAiVWludCIsIGV2ZW50TWluLCAiVWludCIsIGV2ZW50TWF4LCAiVWludCIsIDAsICJQdHIiLCBwQ2FsbGJhY2ssICJVaW50IiwgMCwgIlVpbnQiLCAwLCAiVWludCIsIDApDQp9DQoNCkFjY19Vbmhvb2tXaW5FdmVudChoSG9vaykNCnsNCglSZXR1cm4JRGxsQ2FsbCgiVW5ob29rV2luRXZlbnQiLCAiUHRyIiwgaEhvb2spDQp9DQovKglXaW4gRXZlbnRzOg0KDQoJcENhbGxiYWNrIDo9IFJlZ2lzdGVyQ2FsbGJhY2soIldpbkV2ZW50UHJvYyIpDQoJV2luRXZlbnRQcm9jKGhIb29rLCBldmVudCwgaFduZCwgaWRPYmplY3QsIGlkQ2hpbGQsIGV2ZW50VGhyZWFkLCBldmVudFRpbWUpDQoJew0KCQlDcml0aWNhbA0KCQlBY2MgOj0gQWNjX09iamVjdEZyb21FdmVudChfaWRDaGlsZF8sIGhXbmQsIGlkT2JqZWN0LCBpZENoaWxkKQ0KCQk7IENvZGUgSGVyZToNCg0KCX0NCiovDQoNCjsgV3JpdHRlbiBieSBqZXRocm93DQpBY2NfUm9sZShBY2MsIENoaWxkSWQ9MCkgew0KCXRyeSByZXR1cm4gQ29tT2JqVHlwZShBY2MsIk5hbWUiKT0iSUFjY2Vzc2libGUiP0FjY19HZXRSb2xlVGV4dChBY2MuYWNjUm9sZShDaGlsZElkKSk6ImludmFsaWQgb2JqZWN0Ig0KfQ0KQWNjX1N0YXRlKEFjYywgQ2hpbGRJZD0wKSB7DQoJdHJ5IHJldHVybiBDb21PYmpUeXBlKEFjYywiTmFtZSIpPSJJQWNjZXNzaWJsZSI/QWNjX0dldFN0YXRlVGV4dChBY2MuYWNjU3RhdGUoQ2hpbGRJZCkpOiJpbnZhbGlkIG9iamVjdCINCn0NCkFjY19Mb2NhdGlvbihBY2MsIENoaWxkSWQ9MCwgYnlyZWYgUG9zaXRpb249IiIpIHsgOyBhZGFwdGVkIGZyb20gU2VhbidzIGNvZGUNCgl0cnkgQWNjLmFjY0xvY2F0aW9uKENvbU9iaigweDQwMDMsJng6PTApLCBDb21PYmooMHg0MDAzLCZ5Oj0wKSwgQ29tT2JqKDB4NDAwMywmdzo9MCksIENvbU9iaigweDQwMDMsJmg6PTApLCBDaGlsZElkKQ0KCWNhdGNoDQoJCXJldHVybg0KCVBvc2l0aW9uIDo9ICJ4IiBOdW1HZXQoeCwwLCJpbnQiKSAiIHkiIE51bUdldCh5LDAsImludCIpICIgdyIgTnVtR2V0KHcsMCwiaW50IikgIiBoIiBOdW1HZXQoaCwwLCJpbnQiKQ0KCXJldHVybgl7eDpOdW1HZXQoeCwwLCJpbnQiKSwgeTpOdW1HZXQoeSwwLCJpbnQiKSwgdzpOdW1HZXQodywwLCJpbnQiKSwgaDpOdW1HZXQoaCwwLCJpbnQiKX0NCn0NCkFjY19QYXJlbnQoQWNjKSB7IA0KCXRyeSBwYXJlbnQ6PUFjYy5hY2NQYXJlbnQNCglyZXR1cm4gcGFyZW50P0FjY19RdWVyeShwYXJlbnQpOg0KfQ0KQWNjX0NoaWxkKEFjYywgQ2hpbGRJZD0wKSB7DQoJdHJ5IGNoaWxkOj1BY2MuYWNjQ2hpbGQoQ2hpbGRJZCkNCglyZXR1cm4gY2hpbGQ/QWNjX1F1ZXJ5KGNoaWxkKToNCn0NCkFjY19RdWVyeShBY2MpIHsgOyB0aGFua3MgTGV4aWtvcyAtIHd3dy5hdXRvaG90a2V5LmNvbS9mb3J1bS92aWV3dG9waWMucGhwP3Q9ODE3MzEmcD01MDk1MzAjNTA5NTMwDQoJdHJ5IHJldHVybiBDb21PYmooOSwgQ29tT2JqUXVlcnkoQWNjLCJ7NjE4NzM2ZTAtM2MzZC0xMWNmLTgxMGMtMDBhYTAwMzg5YjcxfSIpLCAxKQ0KfQ0KQWNjX0Vycm9yKHA9IiIpIHsNCglzdGF0aWMgc2V0dGluZzo9MA0KCXJldHVybiBwPSIiP3NldHRpbmc6c2V0dGluZzo9cA0KfQ0KQWNjX0NoaWxkcmVuKEFjYykgew0KCWlmIENvbU9ialR5cGUoQWNjLCJOYW1lIikgIT0gIklBY2Nlc3NpYmxlIg0KCQlFcnJvckxldmVsIDo9ICJJbnZhbGlkIElBY2Nlc3NpYmxlIE9iamVjdCINCgllbHNlIHsNCgkJQWNjX0luaXQoKSwgY0NoaWxkcmVuOj1BY2MuYWNjQ2hpbGRDb3VudCwgQ2hpbGRyZW46PVtdDQoJCWlmIERsbENhbGwoIm9sZWFjY1xBY2Nlc3NpYmxlQ2hpbGRyZW4iLCAiUHRyIixDb21PYmpWYWx1ZShBY2MpLCAiSW50IiwwLCAiSW50IixjQ2hpbGRyZW4sICJQdHIiLFZhclNldENhcGFjaXR5KHZhckNoaWxkcmVuLGNDaGlsZHJlbiooOCsyKkFfUHRyU2l6ZSksMCkqMCsmdmFyQ2hpbGRyZW4sICJJbnQqIixjQ2hpbGRyZW4pPTAgew0KCQkJTG9vcCAlY0NoaWxkcmVuJQ0KCQkJCWk6PShBX0luZGV4LTEpKihBX1B0clNpemUqMis4KSs4LCBjaGlsZDo9TnVtR2V0KHZhckNoaWxkcmVuLGkpLCBDaGlsZHJlbi5JbnNlcnQoTnVtR2V0KHZhckNoaWxkcmVuLGktOCk9OT9BY2NfUXVlcnkoY2hpbGQpOmNoaWxkKSwgTnVtR2V0KHZhckNoaWxkcmVuLGktOCk9OT9PYmpSZWxlYXNlKGNoaWxkKToNCgkJCXJldHVybiBDaGlsZHJlbi5NYXhJbmRleCgpP0NoaWxkcmVuOg0KCQl9IGVsc2UNCgkJCUVycm9yTGV2ZWwgOj0gIkFjY2Vzc2libGVDaGlsZHJlbiBEbGxDYWxsIEZhaWxlZCINCgl9DQoJaWYgQWNjX0Vycm9yKCkNCgkJdGhyb3cgRXhjZXB0aW9uKEVycm9yTGV2ZWwsLTEpDQp9DQpBY2NfQ2hpbGRyZW5CeVJvbGUoQWNjLCBSb2xlKSB7DQoJaWYgQ29tT2JqVHlwZShBY2MsIk5hbWUiKSE9IklBY2Nlc3NpYmxlIg0KCQlFcnJvckxldmVsIDo9ICJJbnZhbGlkIElBY2Nlc3NpYmxlIE9iamVjdCINCgllbHNlIHsNCgkJQWNjX0luaXQoKSwgY0NoaWxkcmVuOj1BY2MuYWNjQ2hpbGRDb3VudCwgQ2hpbGRyZW46PVtdDQoJCWlmIERsbENhbGwoIm9sZWFjY1xBY2Nlc3NpYmxlQ2hpbGRyZW4iLCAiUHRyIixDb21PYmpWYWx1ZShBY2MpLCAiSW50IiwwLCAiSW50IixjQ2hpbGRyZW4sICJQdHIiLFZhclNldENhcGFjaXR5KHZhckNoaWxkcmVuLGNDaGlsZHJlbiooOCsyKkFfUHRyU2l6ZSksMCkqMCsmdmFyQ2hpbGRyZW4sICJJbnQqIixjQ2hpbGRyZW4pPTAgew0KCQkJTG9vcCAlY0NoaWxkcmVuJSB7DQoJCQkJaTo9KEFfSW5kZXgtMSkqKEFfUHRyU2l6ZSoyKzgpKzgsIGNoaWxkOj1OdW1HZXQodmFyQ2hpbGRyZW4saSkNCgkJCQlpZiBOdW1HZXQodmFyQ2hpbGRyZW4saS04KT05DQoJCQkJCUFjY0NoaWxkOj1BY2NfUXVlcnkoY2hpbGQpLCBPYmpSZWxlYXNlKGNoaWxkKSwgQWNjX1JvbGUoQWNjQ2hpbGQpPVJvbGU/Q2hpbGRyZW4uSW5zZXJ0KEFjY0NoaWxkKToNCgkJCQllbHNlDQoJCQkJCUFjY19Sb2xlKEFjYywgY2hpbGQpPVJvbGU/Q2hpbGRyZW4uSW5zZXJ0KGNoaWxkKToNCgkJCX0NCgkJCXJldHVybiBDaGlsZHJlbi5NYXhJbmRleCgpP0NoaWxkcmVuOiwgRXJyb3JMZXZlbDo9MA0KCQl9IGVsc2UNCgkJCUVycm9yTGV2ZWwgOj0gIkFjY2Vzc2libGVDaGlsZHJlbiBEbGxDYWxsIEZhaWxlZCINCgl9DQoJaWYgQWNjX0Vycm9yKCkNCgkJdGhyb3cgRXhjZXB0aW9uKEVycm9yTGV2ZWwsLTEpDQp9DQpBY2NfR2V0KENtZCwgQ2hpbGRQYXRoPSIiLCBDaGlsZElEPTAsIFdpblRpdGxlPSIiLCBXaW5UZXh0PSIiLCBFeGNsdWRlVGl0bGU9IiIsIEV4Y2x1ZGVUZXh0PSIiKSB7DQoJc3RhdGljIHByb3BlcnRpZXMgOj0ge0FjdGlvbjoiRGVmYXVsdEFjdGlvbiIsIERvQWN0aW9uOiJEb0RlZmF1bHRBY3Rpb24iLCBLZXlib2FyZDoiS2V5Ym9hcmRTaG9ydGN1dCJ9DQoJQWNjT2JqIDo9ICAgSXNPYmplY3QoV2luVGl0bGUpPyBXaW5UaXRsZQ0KCQkJOiAgIEFjY19PYmplY3RGcm9tV2luZG93KCBXaW5FeGlzdChXaW5UaXRsZSwgV2luVGV4dCwgRXhjbHVkZVRpdGxlLCBFeGNsdWRlVGV4dCksIDAgKQ0KCWlmIENvbU9ialR5cGUoQWNjT2JqLCAiTmFtZSIpICE9ICJJQWNjZXNzaWJsZSINCgkJRXJyb3JMZXZlbCA6PSAiQ291bGQgbm90IGFjY2VzcyBhbiBJQWNjZXNzaWJsZSBPYmplY3QiDQoJZWxzZSB7DQoJCVN0cmluZ1JlcGxhY2UsIENoaWxkUGF0aCwgQ2hpbGRQYXRoLCBfLCAlQV9TcGFjZSUsIEFsbA0KCQlBY2NFcnJvcjo9QWNjX0Vycm9yKCksIEFjY19FcnJvcih0cnVlKQ0KCQlMb29wIFBhcnNlLCBDaGlsZFBhdGgsIC4sICVBX1NwYWNlJQ0KCQkJdHJ5IHsNCgkJCQlpZiBBX0xvb3BGaWVsZCBpcyBkaWdpdA0KCQkJCQlDaGlsZHJlbjo9QWNjX0NoaWxkcmVuKEFjY09iaiksIG0yOj1BX0xvb3BGaWVsZCA7IG1pbWljICJtMiIgb3V0cHV0IGluIGVsc2Utc3RhdGVtZW50DQoJCQkJZWxzZQ0KCQkJCQlSZWdFeE1hdGNoKEFfTG9vcEZpZWxkLCAiKFxEKikoXGQqKSIsIG0pLCBDaGlsZHJlbjo9QWNjX0NoaWxkcmVuQnlSb2xlKEFjY09iaiwgbTEpLCBtMjo9KG0yP20yOjEpDQoJCQkJaWYgTm90IENoaWxkcmVuLkhhc0tleShtMikNCgkJCQkJdGhyb3cNCgkJCQlBY2NPYmogOj0gQ2hpbGRyZW5bbTJdDQoJCQl9IGNhdGNoIHsNCgkJCQlFcnJvckxldmVsOj0iQ2Fubm90IGFjY2VzcyBDaGlsZFBhdGggSXRlbSAjIiBBX0luZGV4ICIgLT4gIiBBX0xvb3BGaWVsZCwgQWNjX0Vycm9yKEFjY0Vycm9yKQ0KCQkJCWlmIEFjY19FcnJvcigpDQoJCQkJCXRocm93IEV4Y2VwdGlvbigiQ2Fubm90IGFjY2VzcyBDaGlsZFBhdGggSXRlbSIsIC0xLCAiSXRlbSAjIiBBX0luZGV4ICIgLT4gIiBBX0xvb3BGaWVsZCkNCgkJCQlyZXR1cm4NCgkJCX0NCgkJQWNjX0Vycm9yKEFjY0Vycm9yKQ0KCQlTdHJpbmdSZXBsYWNlLCBDbWQsIENtZCwgJUFfU3BhY2UlLCAsIEFsbA0KCQlwcm9wZXJ0aWVzLkhhc0tleShDbWQpPyBDbWQ6PXByb3BlcnRpZXNbQ21kXToNCgkJdHJ5IHsNCgkJCWlmIChDbWQgPSAiTG9jYXRpb24iKQ0KCQkJCUFjY09iai5hY2NMb2NhdGlvbihDb21PYmooMHg0MDAzLCZ4Oj0wKSwgQ29tT2JqKDB4NDAwMywmeTo9MCksIENvbU9iaigweDQwMDMsJnc6PTApLCBDb21PYmooMHg0MDAzLCZoOj0wKSwgQ2hpbGRJZCkNCgkJCSAgLCByZXRfdmFsIDo9ICJ4IiBOdW1HZXQoeCwwLCJpbnQiKSAiIHkiIE51bUdldCh5LDAsImludCIpICIgdyIgTnVtR2V0KHcsMCwiaW50IikgIiBoIiBOdW1HZXQoaCwwLCJpbnQiKQ0KCQkJZWxzZSBpZiAoQ21kID0gIk9iamVjdCIpDQoJCQkJcmV0X3ZhbCA6PSBBY2NPYmoNCgkJCWVsc2UgaWYgQ21kIGluIFJvbGUsU3RhdGUNCgkJCQlyZXRfdmFsIDo9IEFjY18lQ21kJShBY2NPYmosIENoaWxkSUQrMCkNCgkJCWVsc2UgaWYgQ21kIGluIENoaWxkQ291bnQsU2VsZWN0aW9uLEZvY3VzDQoJCQkJcmV0X3ZhbCA6PSBBY2NPYmpbImFjYyIgQ21kXQ0KCQkJZWxzZQ0KCQkJCXJldF92YWwgOj0gQWNjT2JqWyJhY2MiIENtZF0oQ2hpbGRJRCswKQ0KCQl9IGNhdGNoIHsNCgkJCUVycm9yTGV2ZWwgOj0gIiIiIiBDbWQgIiIiIENtZCBOb3QgSW1wbGVtZW50ZWQiDQoJCQlpZiBBY2NfRXJyb3IoKQ0KCQkJCXRocm93IEV4Y2VwdGlvbigiQ21kIE5vdCBJbXBsZW1lbnRlZCIsIC0xLCBDbWQpDQoJCQlyZXR1cm4NCgkJfQ0KCQlyZXR1cm4gcmV0X3ZhbCwgRXJyb3JMZXZlbDo9MA0KCX0NCglpZiBBY2NfRXJyb3IoKQ0KCQl0aHJvdyBFeGNlcHRpb24oRXJyb3JMZXZlbCwtMSkNCn0="
	
	If (!HasData)
		Return -1
	
	If (!Out_Data){
		Ptr := A_IsUnicode ? "Ptr" : "UInt"
		, VarSetCapacity(TD, 10755 * (A_IsUnicode ? 2 : 1))
		
		Loop, 1
			TD .= %A_Index%, %A_Index% := ""
		
		VarSetCapacity(Out_Data, Bytes := 7850, 0)
		, DllCall("Crypt32.dll\CryptStringToBinary" (A_IsUnicode ? "W" : "A"), Ptr, &TD, "UInt", 0, "UInt", 1, Ptr, &Out_Data, A_IsUnicode ? "UIntP" : "UInt*", Bytes, "Int", 0, "Int", 0, "CDECL Int")
		, TD := ""
	}
	
	IfExist, %_Filename%
		FileDelete, %_Filename%
	
	h := DllCall("CreateFile", Ptr, &_Filename, "Uint", 0x40000000, "Uint", 0, "UInt", 0, "UInt", 4, "Uint", 0, "UInt", 0)
	, DllCall("WriteFile", Ptr, h, Ptr, &Out_Data, "UInt", 7850, "UInt", 0, "UInt", 0)
	, DllCall("CloseHandle", Ptr, h)
	
	If (_DumpData)
		VarSetCapacity(Out_Data, 7850, 0)
		, VarSetCapacity(Out_Data, 0)
		, HasData := 0
}

; http://www.autohotkey.com/board/topic/77303-acc-library-ahk-l-updated-09272012/
; https://dl.dropbox.com/u/47573473/Web%20Server/AHK_L/Acc.ahk
;------------------------------------------------------------------------------
; Acc.ahk Standard Library
; by Sean
; Updated by jethrow:
; 	Modified ComObjEnwrap params from (9,pacc) --> (9,pacc,1)
; 	Changed ComObjUnwrap to ComObjValue in order to avoid AddRef (thanks fincs)
; 	Added Acc_GetRoleText & Acc_GetStateText
; 	Added additional functions - commented below
; 	Removed original Acc_Children function
; last updated 2/25/2010
;------------------------------------------------------------------------------

Acc_Init()
{
	Static	h
	If Not	h
		h:=DllCall("LoadLibrary","Str","oleacc","Ptr")
}
Acc_ObjectFromEvent(ByRef _idChild_, hWnd, idObject, idChild)
{
	Acc_Init()
	If	DllCall("oleacc\AccessibleObjectFromEvent", "Ptr", hWnd, "UInt", idObject, "UInt", idChild, "Ptr*", pacc, "Ptr", VarSetCapacity(varChild,8+2*A_PtrSize,0)*0+&varChild)=0
	Return	ComObjEnwrap(9,pacc,1), _idChild_:=NumGet(varChild,8,"UInt")
}

Acc_ObjectFromPoint(ByRef _idChild_ = "", x = "", y = "")
{
	Acc_Init()
	If	DllCall("oleacc\AccessibleObjectFromPoint", "Int64", x==""||y==""?0*DllCall("GetCursorPos","Int64*",pt)+pt:x&0xFFFFFFFF|y<<32, "Ptr*", pacc, "Ptr", VarSetCapacity(varChild,8+2*A_PtrSize,0)*0+&varChild)=0
	Return	ComObjEnwrap(9,pacc,1), _idChild_:=NumGet(varChild,8,"UInt")
}

Acc_ObjectFromWindow(hWnd, idObject = -4)
{
	Acc_Init()
	If	DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", hWnd, "UInt", idObject&=0xFFFFFFFF, "Ptr", -VarSetCapacity(IID,16)+NumPut(idObject==0xFFFFFFF0?0x46000000000000C0:0x719B3800AA000C81,NumPut(idObject==0xFFFFFFF0?0x0000000000020400:0x11CF3C3D618736E0,IID,"Int64"),"Int64"), "Ptr*", pacc)=0
	Return	ComObjEnwrap(9,pacc,1)
}

Acc_WindowFromObject(pacc)
{
	If	DllCall("oleacc\WindowFromAccessibleObject", "Ptr", IsObject(pacc)?ComObjValue(pacc):pacc, "Ptr*", hWnd)=0
	Return	hWnd
}

Acc_GetRoleText(nRole)
{
	nSize := DllCall("oleacc\GetRoleText", "Uint", nRole, "Ptr", 0, "Uint", 0)
	VarSetCapacity(sRole, (A_IsUnicode?2:1)*nSize)
	DllCall("oleacc\GetRoleText", "Uint", nRole, "str", sRole, "Uint", nSize+1)
	Return	sRole
}

Acc_GetStateText(nState)
{
	nSize := DllCall("oleacc\GetStateText", "Uint", nState, "Ptr", 0, "Uint", 0)
	VarSetCapacity(sState, (A_IsUnicode?2:1)*nSize)
	DllCall("oleacc\GetStateText", "Uint", nState, "str", sState, "Uint", nSize+1)
	Return	sState
}

Acc_SetWinEventHook(eventMin, eventMax, pCallback)
{
	Return	DllCall("SetWinEventHook", "Uint", eventMin, "Uint", eventMax, "Uint", 0, "Ptr", pCallback, "Uint", 0, "Uint", 0, "Uint", 0)
}

Acc_UnhookWinEvent(hHook)
{
	Return	DllCall("UnhookWinEvent", "Ptr", hHook)
}
/*	Win Events:

	pCallback := RegisterCallback("WinEventProc")
	WinEventProc(hHook, event, hWnd, idObject, idChild, eventThread, eventTime)
	{
		Critical
		Acc := Acc_ObjectFromEvent(_idChild_, hWnd, idObject, idChild)
		; Code Here:

	}
*/

; Written by jethrow
Acc_Role(Acc, ChildId=0) {
	try return ComObjType(Acc,"Name")="IAccessible"?Acc_GetRoleText(Acc.accRole(ChildId)):"invalid object"
}
Acc_State(Acc, ChildId=0) {
	try return ComObjType(Acc,"Name")="IAccessible"?Acc_GetStateText(Acc.accState(ChildId)):"invalid object"
}
Acc_Location(Acc, ChildId=0, byref Position="") { ; adapted from Sean's code
	try Acc.accLocation(ComObj(0x4003,&x:=0), ComObj(0x4003,&y:=0), ComObj(0x4003,&w:=0), ComObj(0x4003,&h:=0), ChildId)
	catch
		return
	Position := "x" NumGet(x,0,"int") " y" NumGet(y,0,"int") " w" NumGet(w,0,"int") " h" NumGet(h,0,"int")
	return	{x:NumGet(x,0,"int"), y:NumGet(y,0,"int"), w:NumGet(w,0,"int"), h:NumGet(h,0,"int")}
}
Acc_Parent(Acc) { 
	try parent:=Acc.accParent
	return parent?Acc_Query(parent):
}
Acc_Child(Acc, ChildId=0) {
	try child:=Acc.accChild(ChildId)
	return child?Acc_Query(child):
}
Acc_Query(Acc) { ; thanks Lexikos - www.autohotkey.com/forum/viewtopic.php?t=81731&p=509530#509530
	try return ComObj(9, ComObjQuery(Acc,"{618736e0-3c3d-11cf-810c-00aa00389b71}"), 1)
}
Acc_Error(p="") {
	static setting:=0
	return p=""?setting:setting:=p
}
Acc_Children(Acc) {
	if ComObjType(Acc,"Name") != "IAccessible"
		ErrorLevel := "Invalid IAccessible Object"
	else {
		Acc_Init(), cChildren:=Acc.accChildCount, Children:=[]
		if DllCall("oleacc\AccessibleChildren", "Ptr",ComObjValue(Acc), "Int",0, "Int",cChildren, "Ptr",VarSetCapacity(varChildren,cChildren*(8+2*A_PtrSize),0)*0+&varChildren, "Int*",cChildren)=0 {
			Loop %cChildren%
				i:=(A_Index-1)*(A_PtrSize*2+8)+8, child:=NumGet(varChildren,i), Children.Insert(NumGet(varChildren,i-8)=9?Acc_Query(child):child), NumGet(varChildren,i-8)=9?ObjRelease(child):
			return Children.MaxIndex()?Children:
		} else
			ErrorLevel := "AccessibleChildren DllCall Failed"
	}
	if Acc_Error()
		throw Exception(ErrorLevel,-1)
}
Acc_ChildrenByRole(Acc, Role) {
	if ComObjType(Acc,"Name")!="IAccessible"
		ErrorLevel := "Invalid IAccessible Object"
	else {
		Acc_Init(), cChildren:=Acc.accChildCount, Children:=[]
		if DllCall("oleacc\AccessibleChildren", "Ptr",ComObjValue(Acc), "Int",0, "Int",cChildren, "Ptr",VarSetCapacity(varChildren,cChildren*(8+2*A_PtrSize),0)*0+&varChildren, "Int*",cChildren)=0 {
			Loop %cChildren% {
				i:=(A_Index-1)*(A_PtrSize*2+8)+8, child:=NumGet(varChildren,i)
				if NumGet(varChildren,i-8)=9
					AccChild:=Acc_Query(child), ObjRelease(child), Acc_Role(AccChild)=Role?Children.Insert(AccChild):
				else
					Acc_Role(Acc, child)=Role?Children.Insert(child):
			}
			return Children.MaxIndex()?Children:, ErrorLevel:=0
		} else
			ErrorLevel := "AccessibleChildren DllCall Failed"
	}
	if Acc_Error()
		throw Exception(ErrorLevel,-1)
}
Acc_Get(Cmd, ChildPath="", ChildID=0, WinTitle="", WinText="", ExcludeTitle="", ExcludeText="") {
	static properties := {Action:"DefaultAction", DoAction:"DoDefaultAction", Keyboard:"KeyboardShortcut"}
	AccObj :=   IsObject(WinTitle)? WinTitle
			:   Acc_ObjectFromWindow( WinExist(WinTitle, WinText, ExcludeTitle, ExcludeText), 0 )
	if ComObjType(AccObj, "Name") != "IAccessible"
		ErrorLevel := "Could not access an IAccessible Object"
	else {
		StringReplace, ChildPath, ChildPath, _, %A_Space%, All
		AccError:=Acc_Error(), Acc_Error(true)
		Loop Parse, ChildPath, ., %A_Space%
			try {
				if A_LoopField is digit
					Children:=Acc_Children(AccObj), m2:=A_LoopField ; mimic "m2" output in else-statement
				else
					RegExMatch(A_LoopField, "(\D*)(\d*)", m), Children:=Acc_ChildrenByRole(AccObj, m1), m2:=(m2?m2:1)
				if Not Children.HasKey(m2)
					throw
				AccObj := Children[m2]
			} catch {
				ErrorLevel:="Cannot access ChildPath Item #" A_Index " -> " A_LoopField, Acc_Error(AccError)
				if Acc_Error()
					throw Exception("Cannot access ChildPath Item", -1, "Item #" A_Index " -> " A_LoopField)
				return
			}
		Acc_Error(AccError)
		StringReplace, Cmd, Cmd, %A_Space%, , All
		properties.HasKey(Cmd)? Cmd:=properties[Cmd]:
		try {
			if (Cmd = "Location")
				AccObj.accLocation(ComObj(0x4003,&x:=0), ComObj(0x4003,&y:=0), ComObj(0x4003,&w:=0), ComObj(0x4003,&h:=0), ChildId)
			  , ret_val := "x" NumGet(x,0,"int") " y" NumGet(y,0,"int") " w" NumGet(w,0,"int") " h" NumGet(h,0,"int")
			else if (Cmd = "Object")
				ret_val := AccObj
			else if Cmd in Role,State
				ret_val := Acc_%Cmd%(AccObj, ChildID+0)
			else if Cmd in ChildCount,Selection,Focus
				ret_val := AccObj["acc" Cmd]
			else
				ret_val := AccObj["acc" Cmd](ChildID+0)
		} catch {
			ErrorLevel := """" Cmd """ Cmd Not Implemented"
			if Acc_Error()
				throw Exception("Cmd Not Implemented", -1, Cmd)
			return
		}
		return ret_val, ErrorLevel:=0
	}
	if Acc_Error()
		throw Exception(ErrorLevel,-1)
}
