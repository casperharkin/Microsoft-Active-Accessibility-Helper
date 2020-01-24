#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
;SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

BMPLogoIcon := LogoIcon()
Menu Tray, Icon, HBITMAP:*%BMPLogoIcon%
SetTimer,StatusBarUpdate, 1000
Global Selection, Options, Template, InputOutputControl, result

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
		}
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

FunctionsSection = 
(


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
Template .= FunctionsSection
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

LogoIcon()
{

LogoIcon:="iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAC4jAAAuIwF4pT92AAAgAElEQVR4Xu19CXiU1dn2SUJYQkIg"
LogoIcon.="BBJCIIAsAgEBi1rApUrVarFaC/opAq6f2w/FtlyyiYpFa+lXXFCqQqEqUrAFBUS0Kn6oLLInxKBhC0u22bLAzCQzw//cmTN+4Z3zzkzCzGRm8tzXdV8iJO/7nPPcz9ne"
LogoIcon.="c54jBCNW0IbYmdibeBVxCnE+8W3iRuIW4rfE74jFRBPRLmmSf/ed/Jkt8nfels+YIp/ZW74D72IwGM2EOGJ7Yh/ir4jziP8Q7sAtIlYQzxCdxHMXSKd8VoV89hb5LrwT"
LogoIcon.="74YNsAU2MRiMEKEtMYd4E/Ep4gfEI8IdnP6COFTEu2EDbIFNsA02wlYGg3GBaEXsRZxEXEn8gVhNdAn/wRluwibYBhthK2zuJdxlYDAYAQJD6XTh7k1fFe55Oebp/gIw"
LogoIcon.="0gibYTvKgLKgTDxNYDB0kEi8RLiH0tuIVcJ/kPkieuTaxMREa4cOHWrT09MdmZmZzu7du1t79uxp6du3b8WgQYNKQPwZf4d/w8/gZ/E7+F08Q1z4iANlQZlQNpQRZWUw"
LogoIcon.="GITWxJHEl4jHRdOCra5du3b2jIwMe79+/SquvfbasocffvjMs88+a1q2bFnJpk2bzFu3brXu2rXLuW/fPseBAwdqDx48aCssLLSC+DP+Dv+Gn8HP4neWLl1aimfgWXgm"
LogoIcon.="no134F14ZwB2aemSZURZUWaUncFokcBC2Rji34inROMC39GmTRs79djVY8eOrXjyySct7733XsWOHTvsBQUF9qNHj9pKS0sd5eXl58rKys7Rn89jSUmJktqfw+/iGXgW"
LogoIcon.="noln4x14F96Jd8MG2AKbArC7YUNwSpZ9jOBFQ0YLAoa/VxJXEMuE/2CpZ1xcnKNTp05nx4wZY/jd735X+fbbb1fs3r3bRoFpp0B1eQLdE8ynT58OKhs2EngX3ol3wwbY"
LogoIcon.="AptgG2yErf7K04Blsi6uFDw1YMQ4sJHmeeJp4T8wQGdSUpJt2LBhphkzZpg2b95cefjwYQS8s2HA+wveUFHTIDhhG2yErbAZtovA9yKgThYI95cDBiOmkEy8h7hLBBAQ"
LogoIcon.="CQkJdb1797bcf//9pn/+858mmqdjSO9s7oD3xwbTCCdshu0oA8qCMvkrt6wb1NFEWWcMRlQjgXg5cRWxRvgJgFatWtXm5uZannvuOSMNrc9QUDnQu0Zy0OsRNsN2+rMD"
LogoIcon.="ZUGZUDaU0V89yLrCXoLLiPGCwYhCdCD+TrhXvX0KPjEx0T58+HDzn//8Z2NeXp6VelAXelJ/QRYtlKMCF8qGMqKsKLO/eiEeI06XdclgRA36CffCFr6j6wqchsW1I0eO"
LogoIcon.="NL/yyivGgoICDPNd0djbB0o5RXChrCgzyo468FVHxLPE5cS+gsGIcGDIfyNxp/D9Wc+ZnZ1dNW/ePAMFgxUr6rEc+FrK6QEaAivqAHUhfK+NoC53EG+QdcxgRBwwTP09"
LogoIcon.="sUT4EHJSUpJ1woQJhi+++KKKAsHZkgJfS/lp0Ym6QJ2gboTvhhNfCn4neErAiDBkE5cJH0P+uLi4Osx9//73v5uOHTtWG0tz/Asl6gJ1grpBHaGu9OpR1vEyWecMRrMD"
LogoIcon.="830ch9XtufA9/KGHHqrYv3//2ZY23A+UnmkB6gh1JfcQ6I6kZJ338/IGgxFGDCd+IXwIlea3la+++qqpuLiYe/0AiDpCXb3yyium7t27VwrfU4IvpA8YjLADW1exaUUp"
LogoIcon.="Tgxjr7zySjN2xsX66n6w6fla8PHHH1vGjBnjb0qwS/qCwQgLcKYd59sLhY4o27VrVz/kz8/Pt3Kv33Si7rB34MEHH6yQJxD1GoFC6RPON8AIOfCZD2mwlGJMTU21Ytfb"
LogoIcon.="8ePHecgfBKIOUZfPPvusoUOHDr72VRyRvmEwQobRxAKhI8L09PQamruaT5065eAhf/CIujx58mTdyy+/bO7cubOvLdUF0kcMRtCBTDbY4KMSnqtbt26VK1assLT0b/uh"
LogoIcon.="oqxT5/Llyy2oa6G/OLhT+orBCBqwDfVzoRP8ffr0Mf/rX/8yY+HKn5CZF0bUMeoadS70G4HPBW8dZgQJ3YnrhM6ws3fv3uYNGzZw8IeRqGvUOepezy/SZ90V/mQwAgbO"
LogoIcon.="pCNtlbKnwVB0zZo1HPzNQNQ56l5OB5QjM+k7zivAaBJwDv3/CfdpNC+BYTFq2bJlHPzNSNQ9fOBjYRC+e1xwTgFGE3CtcN+X5yWslJQU66JFi0wkQqc/kTJDTid8AZ+o"
LogoIcon.="fCV9+DOlhxkMHSB331ahEBQy4D799NMGfJbi1f7mp+cTIXwisxOrGoH/FZxrkBEgfM37HZMnT644duyYnYM/cghfwCfwjVCnJ4cvXxfuS0wZDF1gK+kjQn3hpuuyyy4z"
LogoIcon.="79u37yzv8Is8wifwDXwk1I03fPqQyukMhgdDhM4e/8zMzOr169dbOPgjl/ANfARfqXwo3DsFBys9z2jxwO00S4RCODS3tCGZJXb5+RMhs3kJH8FX8JnKl8TXiG2UCmC0"
LogoIcon.="aNxCVG0scUycOJHn/VFCz3oAfCbU6wEm4jilAhgtFplCJ7HHgAEDLDt37qzhoX/0EL6Cz+A7lU+Fe6twhlIJjBYHLPzNEIrbbhMTE22LFi0y8maf6CN8Bt/Bh1q/Sl/P"
LogoIcon.="EJw/gCHcJ8d+EN4icd1www3GoqIiHvpHIeEz+A4+FOqvAj8IPjXY4oEc838WimEizvZv2LCBV/2jmPAdfAhfqnwsfc/3DLRg4LPfYeEtDMe0adMMSOzhT2TMyCZ8CF8K"
LogoIcon.="9YLgYakBRgsEDog8JxQ9Q//+/S240JJ7/+gnfAhfwqcqX0sN8GGhFoiLiYeERhDIQDt37lwDCafZvvnLG3POo7/fiTRGUhngS/hUJ7vwIakFRgsCVn+fEorFoYsuuqjy"
LogoIcon.="22+/DftnP3kxBoasdYcPH7YePHjQlpeXV3vo0CHr8ePHcXGoEzY1ZyD5o0znXR9wsBm2owwoC8qEsjXHdeewCT6Fb7X+lhp4SvAXgRaFPsR84S0Gx4wZMwzh3PEne0dn"
LogoIcon.="fn6+bdmyZcbJkyebR40aVdKvX7+KnJwc85AhQ0puvPHG8lmzZpk+++yzqki9VqxUXu8FG2ErbIbtKAPKgjJNmTIFV6MZUdZw507E++BboV4LyJeaYLQQPCwU3/179uxZ"
LogoIcon.="tW3btupwBRje8/3339sWLFhgGDhwoFkeZ1VmH8LwNS0t7cwtt9xi2LRpUyX9flgDSI/SBidsgm2w0cdFHi6UEWVFmVH2cNY1fAsfK+yqk5pgtADgSCjulfPq/bFaTGIJ"
LogoIcon.="y8o/Nqps3rzZct1115kSExN9XXrhFURdu3atnj17tgHfucMVQDplqP/WDltgk/B9jdd5RJlRdtRBGDda+foiAE3wceEWgJHEMqERAL4V45rqcAQUBL9u3Tp/mW19MiEh"
LogoIcon.="Aeffy6kXbZaNSngn3g0bYIs/e3VYn1EZdRGORgC+JR9Xk69Vx72hCWiDEeOYLRRivOmmm+pv8wl1MEGEH374oQVzY9HE4PcwPj6+PgAPHz4c1kbAs8vunnvuqYAN/uz0"
LogoIcon.="QxfqAnUS6sZXHhSqJV+bdGyBNhgxjDThTg91nuPRg7388stGrFD7E9GFEALfu3fvmREjRvgKfifZU9u6desami9jL7ud5tS1Oj97rlWrVnZcmxXOhUuiEym4fPX8sBm2"
LogoIcon.="owwoC8qEsun8vAt1groJdSMAH7/00ktGaY/WDmgDGmHEKK4nen0Koh6ocvfu3SHP9FNcXFz3wAMP6KatIlGe7dKli2nAgAGVQ4cOrbvkkktqc3NzbWSfMTk5GRtZlItr"
LogoIcon.="GRkZ1Rs3bqwMtf2gZ3st3qmyBTbC1l69ehlhO8qAsqBMKBvKKHTSraFuUEf+bLgQwv5du3ad1VkMhDagEUYMAt95XxTeTnfSMNqIb9T+xHMhRM+DPPYpKSmqNONYHbf0"
LogoIcon.="7dvXfOmll9b95Cc/OUf//ZH0/y4KpLNdu3Ytp55V1eu6brzxRsORI0dCOoXBs/EOvEsoghi2wUbYCps1ZcB/61BGlFX1+6ib999/3xzqkRh8TdMXvVEYNMJ7AmIQnYhf"
LogoIcon.="Co3DcZX3ypUrTaEWHXq222+/XXkyjYbKVf379zdrg0bL4cOH26kXLReKkUD79u2tFDyWUJYDz8Y78C7t+2ETbIONvsqAMqKsKLPiGa7f/OY3xlCPAlCOd955x9y2bVtV"
LogoIcon.="Y/ql1AojxoCjn6VC4/B+/fp5Nqb4FU5TiWHnxx9/bOnUqZPXqTT0mjQcNVJw+Ax+D9G70hBblbnINX78eEMogwfPxjuEohGDTbDNn/2SLpRZNZpJS0urkZ8G/drTVMLX"
LogoIcon.="eXl5NoxGFPVYKviYcEziXqLXws+dd95pPnnyZK0/0VwIqcdxzZo1SzmHp2GvadiwYdYAgsbTg2K7slG1+p6VlVXz7bffWkMRPHI7rRXv0L4XtsAm7dTFF1FmlF37LNTR"
LogoIcon.="nDlzQjqSAU+cOFE3YcIE1QGhWqkVRgwBZ74XC29n21944QVDKMWG3ubo0aP2n//85xWK99diga8xgSODx0Y9rlfwtG7d2rZ8+fLyUJQHz1y2bFkF3qF9L2yBTf7s1jZk"
LogoIcon.="KLtQNMrXX3+9IdQ5GFGe559/HnWomgYsFpwnIKbQmbhdaBzdsWNH2yeffBLS1XM8e8+ePbbs7GyvVXOaB9cMGTIk0GFzw+BxUU+M4at2ROGYPn16ZSg21eCAz7Rp07BK"
LogoIcon.="rv2UVwdb/K1fqIiyow609YK6Qp2F2i801ahMTU1VNQDbpWYYMQLs8PLqgQcNGmT47rvvQtrTQGgbN240dejQwUtoNAQuGz58eKN6TtkAnKP5azkNvb1643HjxuFTms2f"
LogoIcon.="XY0h6gen+2666aZy7ftgAw77NHYUA6LsqAPtM1FXqLNQNgAoU0FBAc4lGLXvl1rhXYExhPuFd2/pmjRpkiUcn/9WrFhRQkNnr5Xzrl27nqFAcPgLFBVzc3Pt1Ht67Se4"
LogoIcon.="/PLLTxcVFVmD2ajJnX/Wyy677LT2fbCBevJaf/bq0IE60D4TdYU6C8VUpiHhe2hA+36plfsFI2agyvxjf/HFFyvKy8v9CuVCCBEvWrSoJC4uTtsAOGnobG9KzwkOHTrU"
LogoIcon.="QYHiFTwXX3xxGY1qgvpVA8/CMwcMGODVW2OXHzb6+LNXRZQddSA00wrUFeos1A0AfA8NCPU6wHOCERNoTfyH0Dg4KSnJtmbNmpAsmDUknk8iQ+Boh+uO7t271zS1AcAO"
LogoIcon.="O7mh5rxyXXTRRRVIwBHsBgDPxLO174MNsMWfvXoNAOpAeO+MtKHOwuEbaABa0JZLaqa1YEQ9lBuAMjIy7Nu3bw/5cVqIbMmSJSUJCQnaEYCrW7dutU1ZPAOp13VS7+u1"
LogoIcon.="gk5/X4JMPMFuAPBMJPjQvo9ssMMWf/bqNAD1dSA0+wpQV6izUDcA8D00AC1oyyV4Q1DMoIdQZP7t27evgXq1kC4AghDx6tWry7DjUGtDWlqaacSIEU3qPQcOHFjVqlUr"
LogoIcon.="r30F11xzTcmRI0eC3gDgmVdeeaVXAwAbBg0aVO3PXhVRdtSB9pmoK9RZqBsAObKxQwtaG6RmeghG1OMyopeDKVBKSdRBHSqriF5my5YtNZ07d/bqZUjohmHDhvncOqsi"
LogoIcon.="hs69evXCcNyrUZk4cWJIFjaxWQqbprTvgw2wpSlTGZQddaB9JuoKdRbq0Zls2GzQgqJcBqkdRpRjAtHrAM6DDz5YQwIIefYf+bnJhk+OWhtoqGu7+OKLK5sQPHXp6emq"
LogoIcon.="wyz2P/7xjyE51oxnzp8/H721dtrhgi2wKQC7fyTKjLKjDrT1MnjwYEOwFzL1CA1AC1obpGYmCEbU47fC27m18+bNs4T6C4CHDT43aQPWQfNPnANo1KfA3NzcGpp7ex2m"
LogoIcon.="waaWTZs2hWQfPZ750UcfWVT7GWALbPJnt4b1ZRfeC4CuKVOmWOidQR/FqAgNQAtCsSNRaocR5ZgrNI4N12cmD/GeV1991ahKoEHBU0mjg6pGjAIc3bp1U+YUGDp0qClU"
LogoIcon.="G5vkp0As+Kn279fbdGmADRnKijKj7NpnIcHJa6+9FpJRjIo+PtOek9phRDmeF94is7755punwyUyBM/+/fvPDhw4ULXpxJmWlmYIZEeg5ygt2a8asuJCE9xkHLLMQKXu"
LogoIcon.="CzbQa3stPsKmQI40gygryiwUGYKoYbAcOHDgbCgaMRWhAWgBmlDU6fOCEdVAYoeXhMaxbdq0sb777rul4WoAQATP7NmzlcGDY7E0HK4/S683EkBgoQFp27atMpEFshrt"
LogoIcon.="2LEjpAtneDbegXdp3w+bYBts1GsEUDaUEWXVSWwS8kZMS2gAWoAmFPa8JDg5SFSjFfENoXFscnKyfd26dRWhDBYt5XHaGp1RQH0jgF5x8ODB1ZfKrECSLpy06927t0kv"
LogoIcon.="k058fHztzJkzK06HJ6W548knn0QyUNWcuT6zEdlqhs2w3VMOlAllQxl1gh+fNi27du0KaSOmJd4FLUATCpvekBpiRCnaEN8RGsd27Nix9tNPPw3pKUAdsbmWLl1q0smo"
LogoIcon.="AzoTExORtroyOzvb3LNnz/KsrKxqHLf1kX3XdfXVV5sKCgqC+u1fj/KrhvWqq67CWoAysSlshc2wHWVAWVAmlE3oJAZFnaBuQnGS0RehAWgBmlDYBe1AQ4woRRLx30Lj"
LogoIcon.="2C5duji/+eabkO8C1BLBg6w6jzzySIVeLyiJwIIg8YlMlUD0R3bv3r0Sq/PhLIs84WihAFdNBRrSIcvgtduvIVEXqBPUTTgaMW1ZoAVoQmEbtAMNMaIUKcRNQuPYbt26"
LogoIcon.="OXbv3u0KZ9B4KLfV2idOnFh+oTn1qRyVNH+10DPD2mvKcrjeeecdC2zwZ6cvog5QF6iTcAc/CA1AC9CEwj5oBxpiRClSiZ8KjWOp56rdu3evszkaAI/ocKvOfffdV962"
LogoIcon.="bVvVQRR/dPbp08eyatWqsNyo46Mcrvfeew83HGFtQi/nvy5RdtQB6qI5fQEtQBMKG6EdaIgRpYjIBgAscacKq33ttddwD4DFx4WaDelKSkqy3nHHHYatW7dWN0fPryiH"
LogoIcon.="C7bAJtgmArjtCGVFmVF21EFz9PwecgMQ24jYBgCE8NGL4uvAvHnzTCNHjjSmpKTYaFiMQIIg6+fQyMOHBTUKMiMNu02RdkU4bIFNsA02wlaZO9CzhlGLMnXo0AFJRYwo"
LogoIcon.="K8qMsjdn8Hts5wYgdhHRDYCHsAPBgHkwUmG9+uqrJU8//bR55syZZ1544YXy5cuXl27fvv0MMtniu3VzB42KsAm2wUbYCpthO8qAsqBMVDazHO43y/qLitwAxDaiogHw"
LogoIcon.="UI4I6gMJe9Q9xP9Hmq2+6KsMkdZ4cQMQ24iqBoAZfnIDENvgBoDpk9wAxDa4AWD6JDcAsY2obAAwT45F+it3c5AbgNhG1DQACJCysjJXcXGx/ejRo9ZYJMqGMkZSY8AN"
LogoIcon.="QGwjKhoABER+fr51/vz5lltvvdVw7bXXlsYiUTaUEWWNlEaAG4DYRsQ3AAiEoqKiuttuu03vospYox1lRZkjoRHgBiC2EfENAGxYu3at0ccR4ZgjyooyR0r9cwMQu4j4"
LogoIcon.="BqDMfe12aWJiYotpAFBWlDmcGZn0yA1AbCPiGwDYsGPHjjM5OTmqPH8xSZQVZY6U+ucGIHYR8Q2ApHPevHmGhIQElQjrGR8fX9eqVata/EwkEzbCVr1y4GdQVpQ5gHoJ"
LogoIcon.="ObkBiG1ERQOAxbDCwkIbUnsJ9XFaV7t27cr79u1biqy5yJ0XiYRtsBG26pUDZURZI2EBEOQGILYRFQ0ACFs++OADS5cuXfSmAo7U1FRzbm5utSfZpr/02+GiJ3kpbION"
LogoIcon.="QieNGcqGMkZavXMDELuImgZA0rlw4UJTcnKyXpYgJ/WuZuplcRVXQJdwhIkO2ATbhE5mIJQJZTsdIUN/D7kBiG1EVQOAYTHO08+ePbuiTZs2ulmAaR59NjMzs2LIkCFn"
LogoIcon.="KPj8XsQRQrpgA2yBTUInGxDKgjKhbJEy9PeQG4DYhl4DYI/EBgBEgBw7dsz+2GOPleOaLK3tDeigHteSk5NjvOSSS6yB3MgTLOJdeCfeDRuEj8zFKAPKgjJFWvCDDRoA"
LogoIcon.="VV1zAxDl6Ej8XHg3AFZyuiMSGwAQgXL48GH7jBkzKlJSUnzuD4iLi6tNSkoy9+jRw0i9MS7orAvF+oDncg+8A+/CO/FuX7bBdpQBZYnE4AdlA+CAJhRl+FxqiBGl6ET8"
LogoIcon.="Smgcm52dXb1///6IG442JGw7efJk3eLFi800xMZNwD6TbSLRJi7bTE9PN/Xp08c4dOhQ64gRI+xNXTD0LOzhGXgWPdOAZ+MdASQwdcFm2I4yRHo9QwvQhKIcX0kNMaIU"
LogoIcon.="nYk7hcaxPXv2xAWUzZqNNhDKY7QurJxTUJp8fV9vQBcu2qB5N267qaCereqiiy7C58NqCuQ6XNk1fPhwNA71DYSkFX+Hf8PP4GfxO/S7lampqRUy6DFE9pvxFzbCVtgM"
LogoIcon.="26OhjqEFaEJRnp1SQ4woRRfiXqFxbK9evUx5eXkROyzVkoapLtyYS8NpQ0ZGhu71Wjp0UPDaaC6OEUINzdlLaWh+mgK7NC0trQLEn/F3+Df8DH4WvyP83EqkoQu2wUbY"
LogoIcon.="WtqM9xU0htAAtABNKMoE7UBDjChFJrFQaBxLvVvFwYMHI2YzSiCUtjo3b95c+atf/cpzeMhvjxwGumAL2WT65JNPqmBjtNUrtABNKMoG7UBDjChFT2Kx0Dh28ODBpYWF"
LogoIcon.="hRFzJr0xxKLV0aNHa1evXm2eMGGCkeblNdRbN6anDgrxTrwbNqxZs8YCmyJ1UdUX5S5MKzShKCe0Aw0xohSDiF6Ovfzyy08XFRVFZQMAlpT8Xw7+zz77rGrq1KmGAQMG"
LogoIcon.="mJOSkho7bG8sHXgH3oV34t2RfFdBIJT5GKzQhKK80A40xIhSXE40CI1jr7/++rJjx45F1RRAj7LXdeTn59uoJzZOnz7d/JOf/MRAc3vM+zFNCGThUI84gGTDs0aOHGnA"
LogoIcon.="s/EOvAvvjMYeX0u578IGTSjKb5AaYkQpxhK9VnfvuOMOfJ6q9SeOaKJnVEBB6cTtO1988UX1G2+8UTJnzpyqu+66q/LSSy8tzcnJMXfv3t2akZHhpKCuS0lJsYP4M/4O"
LogoIcon.="/4afwc/id/C79IzSLVu2VMsbfZzR3NvrEVqAJrQ6kdoZq6MtRhTg18QzQuPYRx55xAYx+xNGtBIBit7ZczvPqVOnaimArXl5efVboHfu3OlAA7F+/XoDiD/j7/Bv+Bn8"
LogoIcon.="LH4nkm/0CSahBWhCqxOpnV/raIsRBZgsvPPsOWfMmGGHuP0JI5Yo9xTUB7Mven7O3/NiidACNCG8P6/apYYYUYrHhfenstqnnnrK0tIaAKY+oQVoQrhvZG6oFZfUECNK"
LogoIcon.="MVN4D+tsf/rTn8oiIR8dMzIILUATwn2duVYvM3W0xYgCLBAah+Ke+sWLF5/mBoDpIbQATUAbWr1IDTGiEPHEV4TGoa1bt7a+/fbbJdwAMD2EFqAJaEOrF6mheB2NMSIY"
LogoIcon.="bYhvC41Dk5OT7R988IEhFr5hM4NDmY7NAG1o9SI11EZHY4wIRgrxY6FxaHp6umPr1q1WbgCYHkIL0AS0odWL1FCKjsYYEQyc4totNA7Nzs4+s2/fvog+o84ML6EFaALa"
LogoIcon.="0OpFaohPBEYhcIjjuNA4dMCAAWUFBQUxsQ2YGRxCC9AEtKHVi9QQHwiKQgwnIj/9eQ4dPXp0yeHDh6P2IBAz+IQWoAloQ6sXqaHhOhpjRDCuJ1YKjUPHjx9virVzAMwL"
LogoIcon.="JzQBbWj1IjV0g47GGBGMicJ7Y4dr2rRptrKysqjIVsMMH6EJaEN47xy1SS0xogxPCO/WHPfSmXkbMFNLaALaEN7bgc9JLTGiDH8RGkfGxcVZX375Zd4ExPQiNAFtQCNa"
LogoIcon.="3UgtMaII7YirhcaR7du3t69du5Y3ATG9CE1AG9CIVjdSS+10tMaIQCCV83ahcWRmZqZ9586ddm4AmFpCE9AGNKLVjdQSpwePIvQSij0A/fr1QzbgqEkHzgwfZXZgOzSi"
LogoIcon.="1Y3UUi+l0hgRiZ8SjULjyKuvvrr0yJEjvAeA6UVoAtqARrS6kVr6qY7WGBGIO4heizn3339/DTna4U8MzJZJaAMa0epGaukOHa0xIhC/F95OrJs7d24lfwJk6hHagEaE"
LogoIcon.="OpPy73W0xogwxBFfEhoHJiQkWF977TX+BMjUJbQBjUArWv1ITcXpaI4RQUgmrhcaB3bo0KF248aNZv4CwNQjtAGNQCta/UhNJetojhFByCJ+JzQO7N69e82ePXui8voq"
LogoIcon.="ZngIbUAj0IpWP1JTWTqaY0QQLhOK24BGjhxZ+sMPP/AXAKYuoQ1oBFrR6kdq6jIdzTEiCPcIRXbXe++9FzfX1vkTAbPFsw5a0epHauoeHc0xIgjPCm/n1c6fP9/EXwCY"
LogoIcon.="/giNQCtCfSjoWR3NMSIEbYnvCY3j2rZta1u5cmU5fwFg+iM0Aq1AM1odSW211dEeIwKgzAOYkZFh27Fjh40XAJn+CI1AK9CMVkeC8wNGPAYL953u5zkuNze3rLCwkPMA"
LogoIcon.="Mv0SGoFWoBmtjqS2ButojxEBUN4GPH78ePOJEyc4DRgzIEIr0IxWR4JvC454PC28nVY3e/bsKl4AZAZKaAWaEeotwU8rlcdodrQnrhMah2Ex55133qngBUBmoIRWoBmd"
LogoIcon.="hcB1UmuMCEMOsUhoHJaVlVWza9cuXgBkBkxoBZqBdrR6khrL0dEgoxnxC6LXBo6rr766/MiRI7wAyAyYMjeADdrR6klq7Bc6GmQ0I2YJb2c5pk+fXkktOqcBZzaK0Ay0"
LogoIcon.="Aw0pdDVLR4OMZoIyCWhiYqJt2bJlvAGI2WhCM9AONKTVleAkoRGH7kJxAjAzM/Ps9u3b+SZgZqMJzUA70JBWV1Jr3XW0yGgGXEe0CI2jrrjiivKioiKe/zMbTWgG2oGG"
LogoIcon.="tLqSWrtOR4uMZsAfhLeTnI8//ngVteROf85mMlWEdqAhaEmhrz/oaJERZiQR/y00DmrVqpVtyZIlPP9nNpnQDjQELWn1JTWXpKNJRhjRn3hMaByUkZFxZtu2bWd4/s9s"
LogoIcon.="KqEdaAha0upLaq6/UpGMsEfVZywAABckSURBVEKZAGTs2LGGo0eP8iUgzCYT2oGGoCWtvgTfGhwRaEVcIrydg1uATTz8Z14ooSFoSagThCyRGmQ0E7oR9wuNY1JTU20f"
LogoIcon.="ffSRhYf/zAslNAQtQVNanUntddPRJiMMuJlYLTSOueSSSwyFhYU8/GdeMGV+ADs0pdWZcG8LvklHm4wQI574V+HtFOejjz5qJsfx5z9mUAgtQVNC/Tnwf6QWGWEGhl57"
LogoIcon.="hcYh7dq1s61atYrn/8ygEVqCpqAtrd6kBnka0Ay4leh1XDM3N9dUUFDAu/+YQSO0BE1BW1q9SQ3+SkejjBAhgbhYeDvDMXXqVBMP/5nBJjQFbQn16cBXpSYZYUIO8aDQ"
LogoIcon.="OCI5Odm2du1aMw//mcEmNAVtQWNa3Ukt5uholRECTCHahcYRI0aMMB46dIiH/8ygE5qCtqAxre6kFqcolcoIOpS5/4h1Tz75pImTfzBDRWgLGhPqZKGcKzBMGE2sEBoH"
LogoIcon.="pKen13z++edVvPmHGSpCW9AYtKbVn9TkaB3NMoKEOOKfhHflu2699VZjcXFxLQ//maEitAWNQWvQnEKHf5IaZYQIvYh5QlPxbdq0QeovIy/+MUNNmSrMCM1pdSi12Uup"
LogoIcon.="XEZQMFUo5l9Dhw41Hzx4kBf/mCEnNAatQXNaHUptTtXRLuMCkUncJhSVPnv2bCNn/mGGi9AaNCfUi4HbpFYZQca9QnHuv0ePHlXbtm2r5sU/ZrgIrX3zzTfV0J5Wj1Kj"
LogoIcon.="9+pomNFEpBE/E96V7XjssccM5BSHP6cxmUGm49FHH8UJQdXOwM+kZhlBwt1Er/TMXbt2reZPf8zmIDT32WefVXXp0sXrOLrU6t06WmY0EhnEL4V3JTsnTZpkOHnyJPf+"
LogoIcon.="zGYhaa9u4sSJGAWojglDs12VimY0Co8Kxbbfzp0712zatKmSe39mcxGfBDdu3FjZqVMn1cYgaPZhHU0zAkQOcbdQzP3vu+8+7v2Zzc4TJ044Jk+erDcK+JbYU6lshl8g"
LogoIcon.="y8pTQrHIkpWVVbVlyxae+zObnZ7twZmZmaq1AGh3tuCMQU3CT4nFQlGp06dP55V/ZiQReSj0vggcI16hEjhDH6nE94V3ZZ7r27dv5c6dO2u492dGCuVFotV9+vSpVGmW"
LogoIcon.="uIbYQal0hhIPEa1CU5GtWrWyv/jii0Y+8suMNCJj0AsvvGCERrW6lVp+SEfrDA2GCcVV30TX2LFjjT/88APv+WdGHKHJ77//3nbdddchX4DqpGCB1DbDB9KJa4ViGIUz"
LogoIcon.="2OvXr+fLPpgRS2jzww8/tOATtUrDwn2haGel8hn1Vyw9LRQHLOLi4uqw8Hfq1Cle+GNGNKFRaBWa1epYavspwdeJKXG7UGT6IbpGjRplysvLO8tDf2akExqFVqFZoZ4K"
LogoIcon.="lBNvU0ZAC8YYYqFQDJvwfXXDhg089GdGDaFVaFZnbwCINa5RykhogRhM3C4UFZWYmGhfsGCBkfP8M6ON0Cy0Cw2rtC3ceQMGKSOiBQHbJDcKdQU5JkyYYDhy5Ahf8smM"
LogoIcon.="OkKz0C40LNQbhM5J7bfYrcK9hHvFXzVPco0ePdq8d+/eszz0Z0YroV1oGFrW07mMgV5e0RHjuIi4Qagr5Vy/fv0sn3/+OZ/0Y0Y9oeEvvviisn///r4agQ0yJloEhhA/"
LogoIcon.="Eeoh0bmMjIzq1atXW3i3HzNWCC2vWbPGnJmZqUoh5uEnMjZiFjgR9QuhuNLbw86dO5954403LDR/4uBnxhSh6bfeesusc6mIh3tljMTc6cFk4uPE00I/+GuWLFliocri"
LogoIcon.="FX9mTBJfBv72t7+ZfewUPCdj5HEZM1EP3JKCYc1y4b5HXTf4X3/9dQ5+Zkugkzo6f41AjYyZISKKbxrqRHxE6GzwkXRlZWVVLl261Hyag5/ZcuiE5qF9obMQLlkoY6iT"
LogoIcon.="iCJ0JE4gfiwUmXwb0DVkyBDzhx9+aOYFP2ZLIzQP7SMGhO9G4KyMpfEytiISCcQs4l3ETcLHcB+Mj4+vHTt2rPnrr7+u5uBntlRC+4gBxAJiwlfMyJj6iPhfMtYSRDMD"
LogoIcon.="J5pwtPEq4gvEfUKRxENDV8eOHc888cQTFd99952Nv/MzWzoRA4gFxARiQ/geDXhGBHtlzF0lYzDkpwsThTulUTfiCOJ9xMXCvYdf79TTecTxyGHDhplXrVplxpFJ3t7L"
LogoIcon.="ZLqJWEBMIDYQIzpHib06Uxl722Us3idjs5uMVcRso5FN/JVw5zN/gjiHuIC4lPipcC9K4Miu3gEHFZ3Y3DNt2jTD3r17z/CQn8lUE7GBGEGsIGaEOtW4Hu0yNgtlrCJm"
LogoIcon.="EbuIYcQyYhqxjRhXAq3H/xIxDNE7vNAYulJSUs7iMMSnn35aRQV08JCfyfRNGSMOxAxiBzEkAhhhB0DENGIbMY5YPw9tiMsCeIhf0vDFgd1Od9xxh/H99983Hz9+vJYD"
LogoIcon.="n8lsHBEziB3EEGIJMYXY8hd/ARKxjpj/EVhI2BnAL+rR2bZtW9uAAQMsGL7gooQTJ07U4eoknuszmU0jYgcxhFhCTCG2EGOINdG46YGWiPXzchPiKuOvA/hFD13x8fH2"
LogoIcon.="Dh062AcOHGj+7//+b/O7775rzM/PR8ZeHuozmUEmYgqxhRhDrCHmEHuIQcSiaNw04Wuhub4c+47XqwI9ISHBnpycbO/atWtdTk6O5fLLLy996KGHqhcuXFjx0UcfWQ4e"
LogoIcon.="PGgnAx3c2zOZoadnVEB/diD2EIOIRcQkYhMxilhFzCJ2dRqG9UJz1gDfEd/Q/iDNOeyTJk06tn79esP27dvteXl5tUVFRfW9fHl5uadV8ms0k8kMPhF7iEHEImISsYkY"
LogoIcon.="RawiZhG7iGFFA/CGUOwdmKn4QcfMmTOrDAaDyxPsHPBMZmTSE5+IVcQsYleov+jN1AY/gL3GXnv3b7jhhopjx47xbTxMZpQQsYqYRewqgv+sjHUvXEw8of2FHj16VO7e"
LogoIcon.="vZtz8zGZUULE6p49e85S7FoUDcAJGetewPZBr1RduOxw8eLFRrnwwGQyI5yIVcSszkWlnwgfNxU/p/iFc+PGjTNiUwJPA5jMyCZiFLF68803G1WxLGNcF9cSzdpfwi6k"
LogoIcon.="LVu2VPE0gMmMbMosxFU6uQdxeOhnOrFfDyQc+Ex4/2LdH/7whwq+oYfJjGwiRnG0WCgu2SX+RwSQVOQPQrF5IDs7u4pHAUxm5BKxiS3DWVlZqvTj2Dr8hE7Mn4eBxENC"
LogoIcon.="8YC77rrLUFxcXMdrAUxmZNEz97/zzjtxFZnqnACOCQ9QRrwGyEn+jFCMApKTk8+uXLnSzF8EmMzIImLy3XffNbdv316VhxOxPE80IsMwWgpcYax90LkrrrjClJeXZ+Wp"
LogoIcon.="AJMZGUQsIiYRm6qYJRaIAHt/D9BSzBKKbYRIVzR58uSKo0eP8q29TGYzEzGIWERM6qQSc8hYDrj39yCTuFkoWpTWrVvbZ82aVXHixAneG8BkNhMRe4hBxCJiUhWrMoYz"
LogoIcon.="lREeAEYTjwnFg5OSkmyzZ8+u4A1CTGb46Vn0QwwiFlUxKmN3tCKuAwaGDVOFTrrvdu3a2adOnVp+6NAhTvHNZIaJiDXEHGIPMaiKTRmzU0UThv5apBBfFzqJQhMSEmqv"
LogoIcon.="v/56E3YfIaspjwaYzNBQHvV1IdYQc4g9VUzKWH1dxm5Q0EW4EwnqJSV09erVq3LhwoXGwsJCW1lZGTcETGaQKLMAuRBbiDHEmtBPAeaQsdrFK4ovEF2JK4SPZISJiYl2"
LogoIcon.="fIpYunSp6YcffqhvCJora5AnOUJDwhZfbPiz/p7PjC42VQfNpQePnYih77//3vbWW2+ZEFuIMb34k7G5QsZqSIDVxH8Qfd1j5qJ5ie2nP/2pcf78+cavvvqquri4uLZh"
LogoIcon.="CrFgVKjWmdgIAcr3OI8fP26jirPm5+fb9+/fX7dv3766vXv3Ovbs2ePavXu369tvv3Vu27bNvnXr1rPffPONHf+Wl5dnp1bWimQKeAae5cl1GAybmeGhx18N9QCfwrfw"
LogoIcon.="MXwNn8P30AC0AE2QNpz4N2gFmoF2oCFoqaEeQG1j4c8mf2yoZ7wHMYPYQQxR4BtlJmBfiT9rZWw2ecU/UCCdMHYK6h03/JHx8fF1uOHklltuMT3zzDPmdevWmQ4cOGA/"
LogoIcon.="evToj3kFtRWqpeffGzqTKsdOI4z64N61a1fd5s2bK1esWFFCw6PS2bNnVz/88MPWm2++uWLEiBElffr0MfTo0aMqOzu7Jisry0qs69atmyszM9PVtWtXZ3p6uqNLly5O"
LogoIcon.="+nsbDa1MgwcPLqX5Vfljjz12dsGCBYY1a9YYSBB2EoG9OUc0TN9s2GPCV+Qz2+rVqw1//OMfDfAlfArfwsfwNXwO30MD0AI0QX9fC41AK9AMtAMNQUvQFLQFjUFr0By0"
LogoIcon.="Bw1Ci6RJr0YiEF178vkhJhAbiBHECmIGsYMY8hdnMhafEZpU36FEa+KvifuFf+N+bKGQqbR3796Wn/3sZ6UPPPBAzZw5cypfeeWV0+++++7pf//732WbNm0ybdmypYZa"
LogoIcon.="Put//vOfqvXr1xvJiWWo8EWLFpXOnTu36tFHH7WOGzeu4tJLL0VwG8lxtR07dqxt3bq1NS4uDq1kIBUWCNHa2pOSkuw5OTmVv/jFLwzUGpu//PLLanx+4SzIkUFPTw+f"
LogoIcon.="wDfwEXzVs2fPSvhOuK/MakzKbF+sg8agNWgO2oMGoUVoEtokjVb+9a9/Pb18+fJTpN1S0nAFabkSmoa2oXFoHZqH9hEDiAXEBGIDMSJ8j7C1RAwiFhGTYccg4qvEMuHf"
LogoIcon.="UGWFUgtnbdOmjRXfMpHjPC0trQ4tc6dOnepSUlLsmE7I4MZnjWAFd5OInVbUc9Qg2cKyZct+XOfghiD8lIHvgg/gC/gEvgnwYs1QshZapbm6lbRrRUCjsYCmoW1oHFqH"
LogoIcon.="5qF90XRNI+YQe4jBZgWuGLqa+E+iKgdZLNKFOdmYMWOMS5cuNWIrJoZ1/kTLDA5R16hz1D18EMD8OJaIGEOsXS3E+dd7NTdw0cBNxLeIR0XTW7ZoIhY8rbfffnsFDT8r"
LogoIcon.="qVfi0UAIKRfKXKhr1DnqXrSMwEcsHRXu2EKMnXepR6QBcxHkFJhO/Fi4s5AqdxKGiKgspEPCwshJYr5w36G+lfiFcCdF/Ij4AfF9SWRBypM/j/PU1aJxDZiT5pyW119/"
LogoIcon.="3Yh73LgRCD5Rp6hb1DHqWjTubrw66VOD9DF8DZ97/A8tQBPQBjQCrUAz+fLnoaUa0ThNXCgRM4gdxBBiCTHVLPP8pgJbELETCSmI/4v4F+Gu9CLhvsccVxU3xomg54pj"
LogoIcon.="HHs8LdxHlr8kria+QpxLfEi470G/gngRMUO4V0c7CXc6JGREhV3tiUmSqcL97bQP8TLiL4kPCLfNnxNLRABXpqekpFifeOKJcpqX8pQgiERdok5Rt6hjf36QviqRvvuL"
LogoIcon.="9OUvpW/hY/gaPvf4H1qAJqANaARagWagHWgIWoKmoC1oDFqD5qA9aBBahCbPiAB0oqFT/h5iArGBGIHNiBnEDuy64O28kYAE4a707sRLibcJ917lZ4kLia8J9yYGVCzm"
LogoIcon.="OPim+aZwL3Tg358iPizcK55jiP2F+5snHNZOuBOZBBt4JmweRvy9cAsKPYmuQ3Ef28SJEysOHTrEjUAQiDosLCy033333RXyrjtfwVQtffR76bNUETpdQHPQHjQILUKT"
LogoIcon.="0CY0Cq1Cs9AuNAwtQ9PQNjT+mvx3aB8xgFhATCA2YHOCaIFAoTHEaSeJP+P+slA4sClAK4ye4XbiRuFutZVCjIuLq50wYUIFtm7ydKDpRPB/9913tvHjxxtQp3r1LX2x"
LogoIcon.="Ufqmk4icHhPahYa1um6RAR5LQMv/oHBnWtFtBO6///7yY8eO8XHpJhB1hpX+e++9t9xP8BdIX/jNdstgBBtDhbvnUa5Et2nTxv7cc88ZSdCcTr2RPHXqlOOZZ54x+Eh0"
LogoIcon.="4ZJ1P1ThFwYjbOhBXCl0Fn/S0tLO/OMf/7DQcNblT/RMN1FXK1asMHfq1ElvmuWQdd5D4Q8GI+zA0Uss7Cgzs2CL56efflrJi4L+iTr65JNPLL169dLbVGaTdR30464M"
LogoIcon.="xoUAq7eLhHok4Bo9erQFmVt5PUCfqBvU0ahRo3A9nWpa5ZB1nKqofwaj2YHvy2uFoufCHvXp06cbaW7L6wE6xLyf6sjgYz//WhHCs+4MRjCQS9wjFALu3LnzmbVr11p4"
LogoIcon.="KuBN1AnqJi0tTXWp5TlZp7nKGmcwIgzYr31KKKYCV155pRnftnkq8H9EXVCdWKlusJtONfQ/JeuUwYgKYAMIdqN5fcJCIse5c+caSvim5R+JupgzZ44hPj5e9b3fLusy"
LogoIcon.="UjaEMRgBAXvJ8Z3aazibmZlZ/fHHH/NXgdPuoT/qAnWiqitZh2HLdMNgBBPXCPdBEa+pANI6I9ljS54KoOyoA9SFUA/9T8s6ZDCiEtgHPl8oTj3iYAt2urXkqQDK/vTT"
LogoIcon.="Txt0Dvk4Zd21UtYsgxElwG61r4XOVGDTpk2WlnjdOsq8ceNGCxJfqupG1hnv9GPEBHCWXJVF2TVmzBjzvn37zrak9QCUde/evWdHjx6tt+HHJOuMwYgJ4Agokjwod7fd"
LogoIcon.="fvvtBpoLt4jr1hH8uNfutttuQ4Oo3DVJ/B8RZdlvGAx/6EXcJhTDXXz+evjhh8tx/DWWGwHPEd8HH3ywXOeTH7iD2FtVgQxGtANpqUqFQvg49vrYY4+VHz58OCYzCaFM"
LogoIcon.="RUVFdmroynxcb4VU1zz0Z8QskAnmt0InmxBWwydNmlSOFFix1Ah4Mvvcfffd5T7Sep0l/k5wthxGjANJKPVODdZnEho3bpxx27Zt1bGQQwBl+Prrr6tuuukmo4/MPvjk"
LogoIcon.="t1hEeLprBiNYQLbZ94R+TnvnoEGDzCtXrjTjhFw0jgZgM2x/++23zQMGDMBqv14GaNQBUnN386olBiOGkUVcJfQbARcy4vz2t7814JMZetJoWCCUl3TiBuYzjz/+uCE1"
LogoIcon.="NfWsrzIK9xHfnl61w2C0AKARwEhAN5c8zsbn5uaaX3/9dVNRUZEtUi8l9dzVh629L7/8smngwIEWst1XjnwE/zpijletMBgtCJgO4KIJ3TTjIO6/u+aaa4x///vff7yU"
LogoIcon.="NBKmBvKq6/rAf/PNN01jxowxIRmqr7IId1qvZcRswWAw6he/cOQVt8P4Cpz6S0mvuuoq08KFC43bt28/g+uywj0q8FzJXVxcXPv111/XLFiwwDhq1CgEfiCXdCLXH+6y"
LogoIcon.="5zTeDEYDJAr3N/Bvhf8gqs8rkJWVVT1hwgTjW2+9ZTxw4ICVgtNRXl5e3ysHq0GQF3LWPxPPPnXqVB3WJHBHH3bzYS+/j009WuKuvbuJbQWDwVACd9Hhk1il8B9Q9aMC"
LogoIcon.="bCLq16+fZcqUKZU0MjBs3ry58uDBg3YaHdQiaNFbg56GwRflkL6e9Luu48eP2/Py8uwbNmwwP//888a7777bgizHcjOP34ZKEtObdwSn9GIwAgL2CuC+OFwUqUw1rkMX"
LogoIcon.="9cb21NRUNAjGX//616ZZs2ZVL1q0qHT16tXlNFy37t+/vy4/P99eUFBgO3TokBXEn/F3+LevvvrKumrVqjJqSMpmzJhx5pe//KWhT58+5pSUFHtcXFxjgh7EIiBGNFOE"
LogoIcon.="+5JLBoPRCCD3/aPEnaJxDUFD1lHgWtu1a2fr0qVLXXZ2dg314Mb+/fuXDRkypATEn/F3+Lf09PQ6rDPQ7+B9jb3p9sd3CvetubhJN0cwGIwmAxddYpPMPcT1wn1U1l8A"
LogoIcon.="Nhcx1N9KnCbcUxne1stgBBEYRl9HXEI8Sgx08S2UxCihXLh3840npovIuZ2XwYhJ4Kz8IOIDwv09HavrVaJx8/MLoVW4G6B/CfcBnsuJ7QWDwQg70Bh0J95IfJb4gXA3"
LogoIcon.="CDhai0s29PbgB0oEu4FYRPwP8SXincS+wr1YyWAwIgQYemOagAbhCuJk4gLh/gS3mbibWCzcm3GwR98hiSDHZ0dk4T1A/Jy4WrhPLWIREtMOJOnoJDhJZ0zh/wPtwzf2"
LogoIcon.="bged+AAAAABJRU5ErkJggg=="

; GDI+ Startup
hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll") ; Load module
VarSetCapacity(GdiplusStartupInput, (A_PtrSize = 8 ? 24 : 16), 0) ; GdiplusStartupInput structure
NumPut(1, GdiplusStartupInput, 0, "UInt") ; GdiplusVersion
VarSetCapacity(pToken, 0) ;Make var big enough to fit contents
DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", pToken, "Ptr", &GdiplusStartupInput, "Ptr", 0) ; Initialize GDI+

BMPLogo := GdipCreateFromBase(LogoIcon) ;Turn the raw data into an image. 

; Free GDI+ module from memory
DllCall("Kernel32.dll\FreeLibrary", "Ptr", hGdip)
Return BMPLogo
}
StatusBarUpdate:
FormatTime, TimeString, 20050423220133, dddd MMMM d, yyyy hh:mm:ss tt
SB_SetText(TimeString,2)
return
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
