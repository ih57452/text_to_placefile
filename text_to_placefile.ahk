;~     text_to_placefile - Easily write text onto a GRLevelX radar screen.
;~     Copyright (C) 2011 Bryan Perry <ih57452[AT]gmail.com>

;~     This program is free software: you can redistribute it and/or modify
;~     it under the terms of the GNU General Public License as published by
;~     the Free Software Foundation, either version 3 of the License, or
;~     (at your option) any later version.

;~     This program is distributed in the hope that it will be useful,
;~     but WITHOUT ANY WARRANTY; without even the implied warranty of
;~     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;~     GNU General Public License for more details.

;~     You should have received a copy of the GNU General Public License
;~     along with this program.  If not, see <http://www.gnu.org/licenses/>.

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
#Include .\lib\Dlg.ahk ;by majkinetor ~ http://www.autohotkey.com/forum/topic17230.html
#Include .\lib\Gdip.ahk ;by tic ~ http://www.autohotkey.com/forum/viewtopic.php?t=32238
CoordMode, Mouse, Screen
CoordMode, ToolTip, Screen
Menu, Tray, Tip, Text to Placefile`nClick the middle mouse button or press T to place text on the screen.
If (A_IsCompiled)
	Menu, Tray, NoStandard
Menu, Tray, Add, Help, help
Menu, Tray, Add
Menu, Tray, Add, Exit, ButtonExit
Menu, Tray, Default, Exit
IfNotExist, text_options.ini
{
	MsgBox, 8228, First Run, Would you like to view the instructions for this program?`nYou can view them later by clicking Help from the system tray icon.
	IfMsgBox, Yes
		Gosub, help
}

IniRead, font_num, text_options.ini, options, font_num, 1
IniRead, placefile_name, text_options.ini, options, placefile_name, text_placefile.txt
IniRead, icon_width, text_options.ini, options, icon_width, 300
IniRead, icon_height, text_options.ini, options, icon_height, 50
IniRead, refresh, text_options.ini, optioins, refresh, 2
IniRead, tooltip, text_options.ini, options, tooltip, 0
IniRead, tooltip_section, text_options.ini, options, tooltip_section, 1
IniRead, tooltip_offset_x, text_options.ini, options, tooltip_offset_x, 10
IniRead, tooltip_offset_y, text_options.ini, options, tooltip_offset_y, 20
Loop, 8
{
	IniRead, font%A_Index%_name, text_options.ini, font%A_Index%, font%A_Index%_name, Courier New
	IniRead, font%A_Index%_style, text_options.ini, font%A_Index%, font%A_Index%_style, Bold s14
	IniRead, font%A_Index%_color, text_options.ini, font%A_Index%, font%A_Index%_color, 0x000000
	font%A_Index% := font_line(A_Index)
}
Gosub, gui
If tooltip
	SetTimer, tooltip, 100

GroupAdd, GRX, ahk_class GRLevel3
GroupAdd, GRX, ahk_class GRLevel2
GroupAdd, GRX, ahk_class GR2Analyst
#IfWinActive, ahk_group GRX
~MButton::Goto, add_text
~t::Goto, add_text
#IfWinActive
Return

help:
Run, https://github.com/ih57452/text_to_placefile/wiki
Return

GuiClose:
GuiEscape:
ButtonCancel:
Gui, Hide
Return

ButtonExit:
Gdip_Shutdown(pToken)
ExitApp

add_text:
SetTimer, tooltip, Off
ToolTip
StatusBarGetText, road, 1
StatusBarGetText, range, 2
StatusBarGetText, value, 3
StatusBarGetText, altitude, 4
StatusBarGetText, coord, 5
ControlGetText, tooltip_text,,ahk_class tooltips_class32
MouseGetPos, mouse_x, mouse_y
road = %road%
range = %range%
value = %value%
altitude = %altitude%
coord = %coord%
StringReplace, tooltip_text, tooltip_text, `n, |, 1
IfInString, value, kts
	value := value . "|" . Round(SubStr(value, 1, -4) * 1.15077945) . " mph"
GuiControl,, text, |%road%||%range%|%value%|%altitude%|%coord%|%tooltip_text%
GuiControl,, placefile_name, %placefile_name%
Gui, Show,, Text to Placefile
If tooltip
	SetTimer, tooltip, 100
Return

add_text_to_placefile:
Gosub, save
If (!text)
	Return
IfNotExist, %placefile_name%
	Gosub, create_header
color := ((0x0 . SubStr(font%font_num%_color, 3, 2)) + 0) . " " . ((0x0 . SubStr(font%font_num%_color, 5, 2)) + 0) . " " . ((0x0 . SubStr(font%font_num%_color, 7, 2)) + 0)
FileAppend, Color: %color%`nText: %coord%`, %font_num%`, `"%text%`"`n, %placefile_name%
Return

add_icon_to_placefile:
Gosub, save
If (!text)
	Return
If !pToken
{
	If !pToken := Gdip_Startup()
	{
		MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
		Return
	}
	OnExit, ButtonExit
}
max_size := Round(Sqrt(icon_width**2 + icon_height**2))
StringReplace, text, text, |, `n, 1
IfNotExist, %placefile_name%
	Gosub, create_header
new_icon := Gdip_CreateBitmap(icon_width, icon_height)
G := Gdip_GraphicsFromImage(new_icon)
Gdip_TextToGraphics(G, text, "Center r4 cff" . SubStr(font%font_num%_color, 3) . " " . font%font_num%_style, font%font_num%_name, icon_width, icon_height)
Gdip_DeleteGraphics(G)
Gui, 2: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
Gui, 2: Show
hwnd2 := WinExist()
escaped := 0
SetTimer, find_angle, 100
KeyWait, LButton, D
SetTimer, find_angle, Off
Gui, 2: Destroy
IfExist, text_icon.png
{
	old_icon := Gdip_CreateBitmapFromFile("text_icon.png")
	old_icon_height := Gdip_GetImageHeight(old_icon)
	text_icon := Gdip_CreateBitmap(icon_width, old_icon_height + icon_height)
	G := Gdip_GraphicsFromImage(text_icon)
	Gdip_DrawImage(G, old_icon, 0, 0, icon_width, old_icon_height, 0, 0, icon_width, old_icon_height)
	Gdip_DrawImage(G, new_icon, 0, old_icon_height, icon_width, icon_height, 0, 0, icon_width, icon_height)
	Gdip_DeleteGraphics(G)
	Gdip_DisposeImage(old_icon)
}
Else
{
	text_icon := new_icon
	old_icon_height := 0
}
Gdip_SaveBitmapToFile(text_icon, "text_icon.png")
Gdip_DisposeImage(new_icon)
Gdip_DisposeImage(text_icon)
FileAppend, % "Icon: " . coord . ", " . angle . ", 1, " . ((old_icon_height + icon_height) // icon_height) . "`n", %placefile_name%
Return

find_angle:
MouseGetPos, x, y
x := x - mouse_x
y := y - mouse_y
If (x > 0) And (y >= 0)
	angle := Round(deg(ATan(y / x)))
Else If (x > 0) And (y < 0)
	angle := Round(deg(ATan(y / x) + 2 * pi()))
Else If (x < 0)
	angle := Round(deg(ATan(y / x) + pi()))
Else If (x = 0) And (y > 0)
	angle := Round(deg(pi() / 2))
Else If (x = 0) And (y < 0)
	angle := Round(deg((3 * pi()) / 2))
Else
	angle := 0
Gdip_GetRotatedDimensions(icon_width, icon_height * 2, angle, rotated_width, rotated_height)
hbm := CreateDIBSection(rotated_width, rotated_height)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
Gdip_SetInterpolationMode(G, 7)
Gdip_GetRotatedTranslation(icon_width, icon_height * 2, angle, xt, yt)
Gdip_TranslateWorldTransform(G, xt, yt)
Gdip_RotateWorldTransform(G, angle)
Gdip_DrawImage(G, new_icon, 0, icon_height, icon_width, icon_height, 0, 0, icon_width, icon_height)
Gdip_ResetWorldTransform(G)
UpdateLayeredWindow(hwnd2, hdc, mouse_x - (rotated_width // 2), mouse_y - (rotated_height // 2), rotated_width, rotated_height)
SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc), Gdip_DeleteGraphics(G)
Return

clear_placefile:
FileDelete, text_icon.png
FileDelete, %placefile_name%
Gosub, create_header
Return

create_header:
header = RefreshSeconds: %refresh%`n
Loop, 8
	header .= font%A_Index% . "`n"
header .= "IconFile: 1, " . icon_width . ", " . icon_height . ", " . (icon_width // 2) . ", 0, text_icon.png`n" 
FileAppend, %header%, %placefile_name%
Return

change_font:
n := SubStr(A_GuiControl, 0)
If Dlg_Font(font%n%_name, font%n%_style, font%n%_color)
{
	font%n% := font_line(n)
	Loop, Read, %placefile_name%, %placefile_name%.tmp
	{
		If (SubStr(A_LoopReadLine, 1, 7) = "Font: " . n)
		{
			FileAppend, % font%n% . "`n"
			Continue
		}
		FileAppend, %A_LoopReadLine%`n
	}
	FileCopy,%placefile_name%.tmp, %placefile_name%, 1
	FileDelete, %placefile_name%.tmp
	StringReplace, font%n%_style, font%n%_style, bold, Bold
	StringReplace, font%n%_style, font%n%_style, italic, Italic
	StringReplace, font%n%_style, font%n%_style, underline, Underline
	StringReplace, font%n%_style, font%n%_style, strikeout, Strikeout
	Gosub, save
	Gui, Destroy
	Gosub, gui
	Gui, Show,, Text to Placefile
}
Return

save:
Gui, Submit
Loop, 8
{
	If (f%A_Index%)
		font_num := A_Index
	IniWrite, % font%A_Index%_name, text_options.ini, font%A_Index%, font%A_Index%_name
	IniWrite, % font%A_Index%_style, text_options.ini, font%A_Index%, font%A_Index%_style
	IniWrite, % font%A_Index%_color, text_options.ini, font%A_Index%, font%A_Index%_color
}
IniWrite, %font_num%, text_options.ini, options, font_num
IniWrite, %placefile_name%, text_options.ini, options, placefile_name
IniWrite, %icon_width%, text_options.ini, options, icon_width
IniWrite, %icon_height%, text_options.ini, options, icon_height
IniWrite, %refresh%, text_options.ini, options, refresh
Return

change_tooltip:
Gui, Submit, NoHide
IniWrite, %tooltip%, text_options.ini, options, tooltip
IniWrite, %tooltip_section%, text_options.ini, options, tooltip_section
IniWrite, %tooltip_offset_x%, text_options.ini, options, tooltip_offset_x
IniWrite, %tooltip_offset_y%, text_options.ini, options, tooltip_offset_y
If tooltip
	SetTimer, tooltip, 100
Else
	SetTimer, tooltip, Off
Return

tooltip:
IfWinNotActive, ahk_group GRX
{
	ToolTip
	Return
}
MouseGetPos, tooltip_x, tooltip_y,, control
If (!InStr(control, "Direct3D Window Class"))
{
	ToolTip
	Return
}
StatusBarGetText, tooltip_text, %tooltip_section%
tooltip_text = %tooltip_text%
ToolTip, %tooltip_text%, % tooltip_x + tooltip_offset_x, % tooltip_y - tooltip_offset_y
Return

gui:
Gui, Add, ComboBox, x12 y12 w370 h20 r15 vtext, %road%||%range%|%value%|%altitude%|%coord%|%tooltip_text%
Gui, Add, Button, x112 y42 w70 h30 gchange_font, Change Font1
Gui, Add, Button, x112 y72 w70 h30 gchange_font, Change Font2
Gui, Add, Button, x112 y102 w70 h30 gchange_font, Change Font3
Gui, Add, Button, x112 y132 w70 h30 gchange_font, Change Font4
Gui, Add, Button, x312 y42 w70 h30 gchange_font, Change Font5
Gui, Add, Button, x312 y72 w70 h30 gchange_font, Change Font6
Gui, Add, Button, x312 y102 w70 h30 gchange_font, Change Font7
Gui, Add, Button, x312 y132 w70 h30 gchange_font, Change Font8
Gui, Add, Text, x12 y172 w80 h20 , Placefile name:
Gui, Add, Edit, x92 y172 w200 h20 vplacefile_name, %placefile_name%
Gui, Add, Button, x292 y172 w90 h20 gclear_placefile, Clear Placefile
Gui, Add, CheckBox, x12 y195 w90 h20 Checked%tooltip% gchange_tooltip vtooltip, Enable Tooltip:
Gui, Add, DropDownList, x110 y195 w170 h20 r5 AltSubmit gchange_tooltip vtooltip_section, Road Names/Shapefile Text|Azimuth and Range|Product Value|Tilt Height|Lat and Lon
Gui, Add, Button, x12 y222 w100 h30 Default gadd_icon_to_placefile, Add Rotatable Text
Gui, Add, Button, x122 y222 w100 h30 gadd_text_to_placefile , Add Plain Text
Gui, Add, Button, x232 y222 w70 h30 , Cancel
Gui, Add, Button, x312 y222 w70 h30 , Exit
Gui, Font, % "norm " . font1_style . " c" . font1_color, % font1_name
Gui, Add, Radio, x12 y42 w100 h30 vf1, Font1
Gui, Font, % "norm " . font2_style . " c" . font2_color, % font2_name
Gui, Add, Radio, x12 y72 w100 h30 vf2, Font2
Gui, Font, % "norm " . font3_style . " c" . font3_color, % font3_name
Gui, Add, Radio, x12 y102 w100 h30 vf3, Font3
Gui, Font, % "norm " . font4_style . " c" . font4_color, % font4_name
Gui, Add, Radio, x12 y132 w100 h30 vf4, Font4
Gui, Font, % "norm " . font5_style . " c" . font5_color, % font5_name
Gui, Add, Radio, x212 y42 w100 h30 vf5, Font5
Gui, Font, % "norm " . font6_style . " c" . font6_color, % font6_name
Gui, Add, Radio, x212 y72 w100 h30 vf6, Font6
Gui, Font, % "norm " . font7_style . " c" . font7_color, % font7_name
Gui, Add, Radio, x212 y102 w100 h30 vf7, Font7
Gui, Font, % "norm " . font8_style . " c" . font8_color, % font8_name
Gui, Add, Radio, x212 y132 w100 h30 vf8, Font8
Gui, Font
Gui, +AlwaysOnTop
; Generated using SmartGUI Creator 4.0
GuiControl,, f%font_num%, 1
GuiControl, Choose, tooltip_section, %tooltip_section%
Return

font_line(n) {
	local flags = 0, size
	IfInString, font%n%_style, Bold
		flags += 1
	IfInString, font%n%_style, Italic
		flags += 2
	RegExMatch(font%n%_style, "\d+", size)
	Return, "Font: " . n . ", " . size . ", " . flags . ", """ . font%n%_name . """"
}

pi() {
	Return, 4 * ATan(1)
}

deg(rad) {
	Return, rad * (180 / pi())
}