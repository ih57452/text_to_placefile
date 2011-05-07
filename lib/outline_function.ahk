;~ by fasto ~ http://www.autohotkey.com/forum/viewtopic.php?p=318407#318407

Gdip_AddString(Path, sString,fontName, options,stringFormat=0x4000)
{
   nSize := DllCall("MultiByteToWideChar", "UInt", 0, "UInt", 0, "UInt", &sString, "Int", -1, "UInt", 0, "Int", 0)
   VarSetCapacity(wString, nSize*2)
   DllCall("MultiByteToWideChar", "UInt", 0, "UInt", 0, "UInt", &sString, "Int", -1, "UInt", &wString, "Int", nSize)

	hFamily := Gdip_FontFamilyCreate(fontName)
	RegExMatch(Options, "i)X([\-0-9]+)", xpos)
	RegExMatch(Options, "i)Y([\-0-9]+)", ypos)
	RegExMatch(Options, "i)W([0-9]+)", Width)
	RegExMatch(Options, "i)H([0-9]+)", Height)
	RegExMatch(Options, "i)R([0-9])", Rendering)	
		
	Style := 0, Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"
	Loop, Parse, Styles, |
	{
		If RegExMatch(Options, "i)\b" A_loopField)
		Style |= (A_LoopField != "StrikeOut") ? (A_Index-1) : 8
	}
	RegExMatch(Options, "i)S([0-9]+)", fontSize)
	Align := 0, Alignments := "Near|Left|Centre|Center|Far|Right"
	Loop, Parse, Alignments, |
	{
		If RegExMatch(Options, "i)\b" A_loopField)
		Align |= A_Index//2.1      ; 0|0|1|1|2|2
	}
	hFormat := Gdip_StringFormatCreate(stringFormat)
	Gdip_SetStringFormatAlign(hFormat, Align)	
	Gdip_SetTextRenderingHint(pGraphics, Rendering)
	CreateRectF(textbox, xpos1, ypos1, Width1, Height1)	
	iRet := DllCall("gdiplus\GdipAddPathString", "UInt", Path,  "UInt", &wString, "Int", -1, "Uint",hFamily, "Int", Style, "Float", fontSize1,"UInt", &textbox, "UInt", hFormat)
	Gdip_DeleteFontFamily(hFamily)
	Gdip_DeleteStringFormat(hFormat)
	return iRet 			
}

Gdip_DrawPath(pGraphics, pPen, Path)
{
	return DllCall("gdiplus\GdipDrawPath", "UInt", pGraphics, "UInt", pPen, "UInt", Path)
}

Gdip_SetLineJoin(pPen, linejoin=2) ;LineJoinMiter = 0,LineJoinBevel = 1,LineJoinRound = 2,LineJoinMiterClipped = 3
{
	return DllCall("gdiplus\GdipSetPenLineJoin", "Uint", pPen, "uInt", linejoin)
}
