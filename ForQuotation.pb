
#ASSOCSTR_EXECUTABLE = 2
#ASSOCF_VERIFY = $40

Procedure.s AssocExe(Ext$, *Act)
    Protected Size, OutRes.s
    AssocQueryString_(#ASSOCF_VERIFY, #ASSOCSTR_EXECUTABLE, @Ext$, *Act, 0, @Size)
    OutRes = Space(Size)
    If AssocQueryString_(#ASSOCF_VERIFY, #ASSOCSTR_EXECUTABLE, @Ext$, *Act, @OutRes, @Size)
        OutRes = ""
    EndIf
    ProcedureReturn OutRes
EndProcedure

Procedure IsHex(*c.Character)
	Protected flag = 1
	
	If *c\c = 0
		ProcedureReturn 0
	EndIf
	
	Repeat
		If Not ((*c\c >= '0' And *c\c <= '9') Or (*c\c >= 'a' And *c\c <= 'f') Or (*c\c >= 'A' And *c\c <= 'F'))
			flag = 0
			Break
		EndIf
		*c + SizeOf(Character)	
	Until Not *c\c
	
; 	Debug flag
	ProcedureReturn flag
EndProcedure

Procedure RGBtoBGR(c)
	ProcedureReturn RGB(Blue(c), Green(c), Red(c))
EndProcedure

; def если пустая строка или больше 6 или 5 или 4
; def в BGR, не RGB, то есть готовое для применения
; Color$ это RGB прочитанный из ini с последующим преобразованием в BGR
; при использовании ReadPreferenceString оставлять значение по умолчанию пустым, а def задавать сразу числом-переменной
Procedure ColorValidate(Color$, def = 0)
	Protected tmp$, tmp2$, i
; 	Debug Color$
	i = Len(Color$)
	If i <= 6 And IsHex(@Color$)
		Select i
			Case 6
; 				def = Val("$" + Color$)
; 				RGBtoBGR2(@def)
				def = RGBtoBGR(Val("$" + Color$))
			Case 1
				def = Val("$" + LSet(Color$, 6, Color$))
			Case 2
				def = Val("$" + Color$ + Color$ + Color$)
			Case 3
; 				сразу переворачиваем в BGR
				For i = 3 To 1 Step -1
					tmp$ = Mid(Color$, i, 1)
					tmp2$ + tmp$ + tmp$
				Next
				def = Val("$" + tmp2$)
		EndSelect
	EndIf
; 	Debug Hex(def)
	ProcedureReturn def
EndProcedure



Procedure SaveFile_Buff(File.s, *Buff, Size)
	Protected Result = #False
	Protected ID = CreateFile(#PB_Any, File)
	If ID
		If WriteData(ID, *Buff, Size) = Size
			Result = #True
		EndIf
		CloseFile(ID)
	EndIf
	ProcedureReturn Result
EndProcedure

Procedure.s GetKey(ini_HotkeyCode)
	Protected ModKey, Key$, sep$ = " + "
	ModKey = ini_HotkeyCode >> 8
	If ModKey & #HOTKEYF_CONTROL
		Key$ + sep$ + "Ctrl"
	EndIf
	If ModKey & #HOTKEYF_SHIFT
		Key$ + sep$ + "Shift"
	EndIf
	If ModKey & #HOTKEYF_ALT
		Key$ + sep$ + "Alt"
	EndIf
	Key$ + sep$ + Chr(ini_HotkeyCode & $FF)
	Key$ = Mid(Key$, Len(sep$) + 1)
	ProcedureReturn Key$
EndProcedure

Procedure GetModKey(MOD)
	Protected ModKey = 0
	If MOD & #HOTKEYF_SHIFT
		ModKey | #MOD_SHIFT
	EndIf
	If MOD & #HOTKEYF_CONTROL
		ModKey | #MOD_CONTROL
	EndIf
	If MOD & #HOTKEYF_ALT
		ModKey | #MOD_ALT
	EndIf
	ProcedureReturn ModKey
EndProcedure

;==================================================================
;
; Author:    ts-soft     
; Date:       March 5th, 2010
; Explain:
;     modified version from IBSoftware (CodeArchiv)
;     on vista and above check the Request for "User mode" or "Administrator mode" in compileroptions
;    (no virtualisation!)
;==================================================================
Procedure ForceDirectories(Dir.s)
	Static tmpDir.s, Init
	Protected result
	
	If Len(Dir) = 0
		ProcedureReturn #False
	Else
		If Not Init
			tmpDir = Dir
			Init   = #True
		EndIf
		If (Right(Dir, 1) = #PS$)
			Dir = Left(Dir, Len(Dir) - 1)
		EndIf
		If (Len(Dir) < 3) Or FileSize(Dir) = -2 Or GetPathPart(Dir) = Dir
			If FileSize(tmpDir) = -2
				result = #True
			EndIf
			tmpDir = ""
			Init = #False
			ProcedureReturn result
		EndIf
		ForceDirectories(GetPathPart(Dir))
		ProcedureReturn CreateDirectory(Dir)
	EndIf
EndProcedure



; Активировать окно
; https://www.purebasic.fr/english/viewtopic.php?t=7424
Procedure SetForegroundWindow(hWnd)
	Protected foregroundThreadID, ourThreadID
	If GetWindowLong_(hWnd, #GWL_STYLE) & #WS_MINIMIZE
		ShowWindow_(hWnd, #SW_SHOWNORMAL) ; #SW_MAXIMIZE
		UpdateWindow_(hWnd)
	EndIf
	foregroundThreadID = GetWindowThreadProcessId_(GetForegroundWindow_(), 0)
	ourThreadID = GetCurrentThreadId_()
	
	If (foregroundThreadID <> ourThreadID)
		AttachThreadInput_(foregroundThreadID, ourThreadID, #True);
	EndIf
	
	SetForegroundWindow_(hWnd)
	
	If (foregroundThreadID <> ourThreadID)
		AttachThreadInput_(foregroundThreadID, ourThreadID, #False)
	EndIf   
	
	InvalidateRect_(hWnd, #Null, #True)
EndProcedure


Procedure.s TrimChar(String$, TrimChar$ = #CRLF$ + #TAB$ + #FF$ + #VT$ + " ")
	Protected Len1, Len2, Blen, i, j
	Protected *memChar, *c.Character, *jc.Character
	
	Len1 = Len(TrimChar$)
	Len2 = Len(String$)
	Blen = StringByteLength(String$)
	
	If Not Asc(String$)
		ProcedureReturn ""
	EndIf
	
	; удаление слева
	*c.Character = @String$ + Blen - SizeOf(Character)
	*memChar = @TrimChar$
	
	For i = Len2 To 1 Step -1
		*jc.Character = *memChar
		
		For j = 1 To Len1
			If *c\c = *jc\c
				*c\c = 0
				Break
			EndIf
			*jc + SizeOf(Character)
		Next
		
		If *c\c
			Break
		EndIf
		*c - SizeOf(Character)
	Next
	
	; удаление справа
	*c.Character = @String$
	*memChar = @TrimChar$
	
	For i = 1 To Len2
		*jc.Character = *memChar
		
		For j = 1 To Len1
			If *c\c = *jc\c
				*c\c = 0
				Break
			EndIf
			*jc + SizeOf(Character)
		Next
		
		If *c\c
			String$ = PeekS(*c)
			Break
		EndIf
		*c + SizeOf(Character)
	Next
	
	ProcedureReturn String$
EndProcedure


Procedure.s StringBetween2(text$, StrForm$, delimiter$)
	Protected Pos1, Pos2, str1$, str2$, str3$
	StrForm$ = UnescapeString(StrForm$)
	str1$ = StringField(StrForm$, 1, delimiter$)
	str2$ = StringField(StrForm$, 2, delimiter$)
	str3$ = StringField(StrForm$, 3, delimiter$)
	str3$ = FormatDate(str3$, Date())
	If Not Asc(str2$)
		ProcedureReturn ""
	EndIf
	Pos1 = FindString(text$, str1$)
	If Pos1
		Pos1 + Len(str1$)
		Pos2 = FindString(text$, str2$, Pos1 + 1)
		If Pos2
			text$ = TrimChar(Mid(text$, Pos1, Pos2 - Pos1))
			If FindString(text$, #CR$) Or FindString(text$, #LF$)
				ProcedureReturn ""
			EndIf
			ProcedureReturn text$ + str3$
		EndIf
	EndIf
EndProcedure


Procedure Limit(*Value.integer, Min, Max)
  If *Value\i < Min
    *Value\i = Min
  ElseIf *Value\i > Max
    *Value\i = Max
  EndIf
EndProcedure

; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 258
; FirstLine = 225
; Folding = ---
; Optimizer
; EnableAsm
; EnableXP
; DPIAware