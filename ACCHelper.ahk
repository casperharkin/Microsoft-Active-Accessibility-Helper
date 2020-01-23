#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.

Gui, Add, Text, x15 y13 w25 h26 Border gCrossHair 
Gui, Add, Text, x15 y13 w25 h4  Border
Gui, Add, Text, x18 y28 w19 h1 Border vHBar
Gui, Add, Text, x27 y18 w1 h19 Border vVBar
Gui, Font, S6
Gui, Add, Text, x11 y47 w35 h26 +Center, DRAG CURSOR
Gui, Font, S12
Gui Add, DropDownList, x62 y10 w200 vSelection gCSel, Send Text||Send Click
Gui Add, Edit, x62 y+5 w200 h22 hwndSelid  vTestText, Type Text to Send.
Gui, add, button, w400 gTest y10 x+15 w120 h55 , Test Code
Gui, Add, Edit, x10 y+10 w400 h120 ReadOnly vEditControlDisplay, 
Gui, Add, Edit, x10 y+10 w400 h120 vdisplayCode r6 Multi -Wrap 
Gui, Show, Center, Microsoft Active Accessibility Helper
return

CSel:
gui, submit, nohide
if (Selection = "Send Click") {
	GuiControl, disable, % Selid
	GuiControl, text, % Selid, Sending a Click.
}
else {
	GuiControl, enable,% Selid
	GuiControl, text, % Selid, Send Text
}
Return

~Lbutton Up::
Lbutton_Pressed := False
	if (CH = false) and (CheckSet = "Ac") 
	{ 
        GuiControl, Show, HBar
        GuiControl, Show, VBar
		CrossHair(CH:=true)
		Template := Code(Path, title, TestText, Selection)
		GuiControl,text, displayCode, %Template%
	}
Return	

Test:
ExecScript(Template,,A_AhkPath)
return

Code(Path, title, text, Selection)
{
global SelectionCMD
WinGet,hWnd,id, %title%
oAcc := Acc_Get("Object", path, 0, "ahk_id " hWnd)
ControlHwnd := Acc_WindowFromObject(oAcc)

if (Selection = "Send Text")
	SelectionCMD = ControlSetText, , %text%, ahk_id %ControlHwnd%

if (Selection = "Send Click")
	SelectionCMD = ControlClick, , ahk_id %ControlHwnd%

Template =
(
WinActivate ahk_exe %title%
WinGet, hWnd, id, %title%
oAcc := Acc_Get("Object", %path%, 0, "ahk_id " %hWnd%) 
ControlHwnd := Acc_WindowFromObject(oAcc)
ControlFocus, , ahk_id %ControlHwnd%
%SelectionCMD%

;========================================
;                Fucntions  
;========================================

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
)
Template .= FucntionsAdd
return Template
}

CrossHair: 
gui, submit, nohide
CheckSet := "Ac"
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
			GuiControl, text, EditControlDisplay, ID:________%id%`nClass:_____ %class%`nTitle:______ %title%`nControl:___  %control%`nACCPath:__ %path%
		}
return

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
