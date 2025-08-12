;- TOP
; AZJIO цитатник 24.08.2022 - 2024.03.09

EnableExplicit

#date$ = "2024.03.09"
#q$ = Chr(34)

#GadgetHK = 0
#HK_ID = 1001
#File = 0

;- Перечисления
Enumeration
	#WindowSet
	#WindowPreview
EndEnumeration

;- ● Enumeration
Enumeration
	#Hotkey
	#Editor
	#btnApply
	#LBxGrps
	#btnOk
	#btnCancel
	#btnMenu
EndEnumeration

; Меню
Enumeration
	#Menu
	#Menu1
EndEnumeration

Enumeration
	#mAbout
	#mQFile
	#mQFolder
	#mHelp
	#mShow
	#mINI
	#mExit
	#mEsc
EndEnumeration

XIncludeFile "ForQuotation.pb"
XIncludeFile "SendKey.pbi"

;- ● Declare
Declare SizeHandler()
Declare _Exit()
Declare EvMenu(ev)
; Declare.s AssocExe(Ext$, *Act)

Structure iniGroups
	mode.i
	isExistPath.i
	wstr.i
	bom.i
	edit.i
	genname.i
	run.i
	name.s
	path.s
	folder.s
	ext.s
	separator.s
	title.s
	*p
EndStructure


;- ● Global / Define
Global tmp$, idx, *item
Define *p
Define WWE, i
Define isINI = 0
Define VirtKey
Define ModKey
Global hWnd_0, hWnd_1, hHotkey, hFont;, hIcon
Global NewList iniGroups.iniGroups()

;- ini
Global PathConfig$ = GetPathPart(ProgramFilename())
Global ini$
If FileSize(PathConfig$ + "Quotation.ini") < 0 And MessageRequester("Портативная?", "Создать конфиг и рабочую папку рядом с исполняемым файлом?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_No
	PathConfig$ = GetHomeDirectory() + "AppData\Roaming\Quotation\"
EndIf
ini$ = PathConfig$ + "Quotation.ini"


If FileSize(ini$) < 8 And (FileSize(GetPathPart(ini$)) = -2 Or CreateDirectory(GetPathPart(ini$)))
	SaveFile_Buff(ini$, ?ini, ?iniend - ?ini)
EndIf

DataSection
	ini:
	IncludeBinary "sample.ini"
	iniend:
EndDataSection


Global ini_HotkeyCode.l = 586
Global ini_MaxSize.l = 500
Global ini_Preview = 1
Global ini_Clipboard = 0
; Global ini_Separator$ = "\n\n=== %d %t ====\n\n"
Global ini_Signal$
Define ini_ClrFnt = 0
Define ini_ClrBG = 0
Global ini_SelLst = 0
Global ini_width = 640
Global ini_height = 570
Global ini_top = 1
Global w, h
Global editor$
; Global editor$ = "notepad.exe"
Global fm$ = "explorer.exe"


		ExamineDesktops()

If FileSize(ini$) > 3 And OpenPreferences(ini$)
	If PreferenceGroup("set")
		ini_HotkeyCode = ReadPreferenceLong("HotkeyCode", ini_HotkeyCode)
		editor$ = ReadPreferenceString("editor", editor$)
		fm$ = ReadPreferenceString("fm", fm$)
		ini_SelLst = ReadPreferenceInteger("SelLst", ini_SelLst)
		
		ini_width = ReadPreferenceInteger("width", ini_width)
		Limit(@ini_width, 150, DesktopWidth(0))
		ini_height = ReadPreferenceInteger("height", ini_height)
		Limit(@ini_height, 150, DesktopHeight(0))
		
		ini_top = ReadPreferenceInteger("top", ini_top)
		ini_MaxSize = ReadPreferenceInteger("MaxSize", ini_MaxSize)
		ini_Preview = ReadPreferenceInteger("Preview", ini_Preview)
		If ini_Preview
			ini_ClrFnt = ColorValidate(ReadPreferenceString("ClrFnt", ""), ini_ClrFnt)
			ini_ClrBG = ColorValidate(ReadPreferenceString("ClrBG", ""), ini_ClrBG)
		EndIf
		ini_Clipboard = ReadPreferenceInteger("Clipboard", ini_Clipboard)
; 		ini_Separator$ = ReadPreferenceString("Separator", ini_Separator$)
		ini_Signal$ = ReadPreferenceString("Signal", "")
; 		ini_PathQuoteTxt$ = ReadPreferenceString("PathQuoteTxt", ini_PathQuoteTxt$)
		isINI = 1
	EndIf
	ExaminePreferenceGroups()
	While NextPreferenceGroup()
		If PreferenceGroupName() = "set"
			Continue
		EndIf
		*p = AddElement(iniGroups())
		If *p
			iniGroups()\p = *p
			iniGroups()\name = PreferenceGroupName()
			iniGroups()\mode = ReadPreferenceInteger("mode", 1)
			iniGroups()\path = ReadPreferenceString("path", "")
			iniGroups()\edit = ReadPreferenceInteger("edit", 0)
			iniGroups()\bom = ReadPreferenceInteger("bom", 1)
			iniGroups()\title = ReadPreferenceString("TitleBtwn", "")
			iniGroups()\run = ReadPreferenceInteger("run", 0)
			Select ReadPreferenceInteger("wstr", 0)
				Case 0
					iniGroups()\wstr = #PB_UTF8
				Case 1
					iniGroups()\wstr = #PB_Ascii
				Case 2
					iniGroups()\wstr = #PB_Unicode
			EndSelect
			If iniGroups()\mode = 2
				iniGroups()\folder = ReadPreferenceString("folder", "")
				iniGroups()\ext = ReadPreferenceString("ext", "")
				If Asc(iniGroups()\ext)
					iniGroups()\ext =  "." + iniGroups()\ext
				EndIf
				iniGroups()\genname = ReadPreferenceInteger("genname", 0)
			Else
				iniGroups()\separator = UnescapeString(ReadPreferenceString("separator", "\n\n=== %d %t ====\n\n"))
			EndIf
		EndIf
	Wend
	ClosePreferences()
EndIf

; кэшируем размеры окна
w = ini_width
h = ini_height

If Not ListSize(iniGroups())
	If MessageRequester("Ошибка", "В ini-файле нет ни одной секции настроек для сохранения цитат." + #CRLF$ + #CRLF$ + "Открыть ini-файл?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
		RunProgram(ini$)
	EndIf
	End
EndIf

;- InitSound
Global IsSound = 0
#RingTone = 0
If Asc(ini_Signal$) And FileSize(ini_Signal$) > 0 And InitSound()
	If LoadSound(#RingTone, ini_Signal$)
		IsSound = SoundLength(#RingTone, #PB_Sound_Millisecond)
		If IsSound > 3000
			IsSound = 3000
		EndIf
	EndIf
EndIf

If Not Asc(editor$)
	editor$ = AssocExe(".txt", 0)
	If Not Asc(editor$)
		editor$ = "notepad.exe"
	EndIf
EndIf


Global g_Key.INPUT
g_Key\type = #INPUT_KEYBOARD

Procedure ReleaseKey()
	While GetAsyncKeyState_(#VK_SHIFT)
		g_Key\ki\wVk = #VK_SHIFT
		g_Key\ki\dwFlags = #KEYEVENTF_KEYUP
		SendInput_( 1, @g_Key, SizeOf(INPUT))
		Delay(10)
	Wend
	While GetAsyncKeyState_(#VK_CONTROL)
		g_Key\ki\wVk = #VK_CONTROL
		g_Key\ki\dwFlags = #KEYEVENTF_KEYUP
		SendInput_( 1, @g_Key, SizeOf(INPUT))
		Delay(10)
	Wend
	While GetAsyncKeyState_(#VK_MENU)
		g_Key\ki\wVk = #VK_MENU
		g_Key\ki\dwFlags = #KEYEVENTF_KEYUP
		SendInput_( 1, @g_Key, SizeOf(INPUT))
		Delay(10)
	Wend
EndProcedure



	
Procedure _Re()
	Protected Selected_Text$, i, WWE, name$, folder$, KeyCode, w, h, Separator$, ind$, Title$
; 	Static Change = 1
	ReleaseKey()
	If Not ini_Clipboard
		SendKey(#VK_INSERT, #MOD_LCONTROL)
		Delay(10)
	EndIf
	Selected_Text$ = GetClipboardText()

	If Not Asc(Selected_Text$)
		ProcedureReturn
	EndIf
	
	If ini_Preview
		SetGadgetText(#Editor , Selected_Text$)
		HideWindow(#WindowSet, #True)
		HideWindow(#WindowPreview, #False)
		SetActiveWindow(#WindowPreview)
; 		SetForegroundWindow(WindowID(#WindowPreview))
		SetActiveGadget(#LBxGrps)
; 		SetWindowLongPtr_(GadgetID(#btnOk), #GWL_STYLE, GetWindowLongPtr_(GadgetID(#btnOk), #GWL_STYLE) | #BS_DEFPUSHBUTTON)
		SetGadgetState(#LBxGrps, ini_SelLst)
		
;-┌──Loop Preview──┐
		Repeat
			WWE = WaitWindowEvent()
				Select WWE
					Case #WM_QUERYENDSESSION ; выход из ОС, пришёл запрос завершения сессии
						_Exit()
;- ├ События трея
					Case #PB_Event_SysTray
						Select EventType()
							Case #PB_EventType_RightClick, #PB_EventType_LeftClick
								HideWindow(#WindowPreview, #True)
								Break
						EndSelect
				EndSelect
			Select EventWindow()
				Case #WindowSet
					Select WWE
						Case #PB_Event_CloseWindow
							HideWindow(#WindowSet, #True)
					EndSelect
				Case #WindowPreview
					Select WWE
						Case #WM_KEYDOWN
							KeyCode = EventlParam() >> 16 & $FF
							Select KeyCode
								Case 28
; 									при нажатии Enter проверяем активное окно. Если редактор то осуществляется перенос иначе нажатие OK
									If GetActiveGadget() = #LBxGrps
; 										повтряются действия события #btnOk
										idx = GetGadgetState(#LBxGrps)
; 										Debug idx
										If idx > -1
											ini_SelLst = idx
											*item = GetGadgetItemData(#LBxGrps, idx)
										EndIf
										If ini_Preview And iniGroups()\edit
; 											Debug "|" + Selected_Text$ + "|"
											Selected_Text$ = GetGadgetText(#Editor)
; 											Debug "|" + Selected_Text$ + "|"
										EndIf
										HideWindow(#WindowPreview, #True)
										SetGadgetText(#Editor , "")
										Break
									EndIf
							EndSelect
;- ├ Menu События
						Case #PB_Event_Menu        ; кликнут элемент всплывающего Меню
							EvMenu(EventMenu())
						Case #PB_Event_Gadget
							Select EventGadget()
; 								Case #Editor
; 									If Change And  EventType() = #PB_EventType_Change
; 										Change = 0
; 										For i = 0 To CountGadgetItems(#LBxGrps) - 1
; 											*item = GetGadgetItemData(#LBxGrps, i)
; 											ChangeCurrentElement(iniGroups() , *item)
; 											If iniGroups()\edit
; 												SetGadgetItemColor(#LBxGrps , i , #PB_Gadget_FrontColor , $00FF00) ; только ListIconGadget
; 											EndIf
; 										Next
; 										*item = 0
; 									EndIf
								Case #btnMenu
									DisplayPopupMenu(#Menu, WindowID(#WindowPreview))  ; покажем всплывающее Меню
								Case #btnOk
									idx = GetGadgetState(#LBxGrps)
; 									Debug idx
									If idx > -1
										ini_SelLst = idx
										*item = GetGadgetItemData(#LBxGrps, idx)
										If *item
											ChangeCurrentElement(iniGroups(), *item) ; для iniGroups()\edit нужно задать текущий
										EndIf
									EndIf
									If ini_Preview And iniGroups()\edit
; 										Debug "|" + Selected_Text$ + "|"
										Selected_Text$ = GetGadgetText(#Editor)
; 										Debug "|" + Selected_Text$ + "|"
									EndIf
									HideWindow(#WindowPreview, #True)
									SetGadgetText(#Editor , "")
									Break
								Case #btnCancel
									HideWindow(#WindowPreview, #True)
									SetGadgetText(#Editor , "")
									ProcedureReturn
							EndSelect
						Case #PB_Event_CloseWindow
							HideWindow(#WindowPreview, #True)
							SetGadgetText(#Editor , "")
							ProcedureReturn
					EndSelect
			EndSelect
		ForEver
;-└──Loop──┘
	Else
		*item = SelectElement(iniGroups(), 0)
	EndIf
	
	If *item
		ChangeCurrentElement(iniGroups() , *item)
; 		Debug iniGroups()\name
		Select iniGroups()\mode
			Case 1
				If Not iniGroups()\isExistPath
					If iniGroups()\isExistPath = -1
						MessageRequester("Ошибка", "Не удалось создать файл для цитат.")
						ProcedureReturn
					EndIf
					If Not Asc(iniGroups()\path)
						iniGroups()\path = PathConfig$ + GetFilePart(ProgramFilename(), #PB_FileSystem_NoExtension) + ".txt"
					ElseIf Mid(iniGroups()\path, 2, 2) <> ":\" 
						iniGroups()\path = PathConfig$ + iniGroups()\path ; если путь пуст то используем папку по умолчанию
					EndIf
						
; 					создаём , если не существует
					If FileSize(iniGroups()\path) < 0
						ForceDirectories(GetPathPart(iniGroups()\path)) ; если абсолютный путь не существует, то создаём
						If CreateFile(#File, iniGroups()\path, iniGroups()\wstr) ; создаёт пустой файл
							If iniGroups()\bom ; добавлять ли метку BOM
								WriteStringFormat(#File , iniGroups()\wstr)
							EndIf
							CloseFile(#File)
						EndIf
					EndIf
					
; 					предупреждаем, если нет доступа, или это папка или любая причина по которой не создан файл 
					If FileSize(iniGroups()\path) < 0
						MessageRequester("Ошибка", "Не удалось создать файл для цитат.")
						iniGroups()\isExistPath = -1
						ProcedureReturn
					EndIf
					iniGroups()\isExistPath = 0
					
; 					Бэкапируем если размер файла превышен
					If FileSize(iniGroups()\path) > (ini_MaxSize * 1024)
						If RenameFile(iniGroups()\path , ReplaceString(iniGroups()\path, ".txt", "", #PB_String_NoCase, Len(iniGroups()\path) - 3, 1) + FormatDate(" %yyyy.%mm.%dd %hh.%ii.%ss", Date()) + ".txt")
							If CreateFile(#File, iniGroups()\path, iniGroups()\wstr) ; создаёт пустой файл
								If iniGroups()\bom ; добавлять ли метку BOM
									WriteStringFormat(#File , iniGroups()\wstr)
								EndIf
								CloseFile(#File)
							EndIf
						EndIf
					EndIf
				EndIf
				
				If OpenFile(#File, iniGroups()\path, iniGroups()\wstr)
					FileSeek(#File, Lof(#File))
					Separator$ = ReplaceString(iniGroups()\separator , "%d" , FormatDate("%yyyy.%mm.%dd", Date()))
					Separator$ = ReplaceString(Separator$ , "%t" , FormatDate("%hh.%ii.%ss", Date()))
					If iniGroups()\title
						Title$ = StringBetween2(Selected_Text$, iniGroups()\title, "_|_")
					EndIf
					If WriteString(#File, Separator$ + Title$ + Selected_Text$, iniGroups()\wstr) And IsSound
						PlaySound(#RingTone)
						;Delay(IsSound)
					EndIf
					CloseFile(#File)
				Else
					MessageRequester("Ошибка", "Не удалось открыть файл для цитат.")
				EndIf
				
			Case 2
				If Not iniGroups()\isExistPath
					If iniGroups()\isExistPath = -1
						MessageRequester("Ошибка", "Не удалось создать папку для цитат.")
						ProcedureReturn
					EndIf
; 					Debug "|" + iniGroups()\path + "|"
; 					Debug Mid(iniGroups()\path, 2, 2)
					If Not Asc(iniGroups()\path)
						iniGroups()\path = PathConfig$ + GetFilePart(ProgramFilename(), #PB_FileSystem_NoExtension)  ; если путь пуст то используем папку по умолчанию
					ElseIf Mid(iniGroups()\path, 2, 2) <> ":\"
						iniGroups()\path = PathConfig$ + iniGroups()\path ; если путь пуст то используем папку по умолчанию
					EndIf
					If FileSize(iniGroups()\path) = -1
						ForceDirectories(iniGroups()\path) ; если путь не существует, то создаём
					EndIf
					If FileSize(iniGroups()\path) = -2
						iniGroups()\isExistPath = 0
					Else
; 						MessageRequester("Ошибка", "Не удалось создать папку для цитат.")
						MessageRequester("", "Не удалось определить и создать путь:" + #CRLF$ + iniGroups()\path)
						iniGroups()\isExistPath = -1
						ProcedureReturn
					EndIf
					
					If Right(iniGroups()\path, 1) <> "\"
						iniGroups()\path + "\"
					EndIf
; 					If FileSize(iniGroups()\path) = -2
; 						iniGroups()\isExistPath = 0
; 					Else
; 						MessageRequester("", "Не удалось определить и создать путь:" + #CRLF$ + iniGroups()\path)
; 						ProcedureReturn
; 					EndIf
				EndIf
				folder$ = FormatDate(iniGroups()\folder, Date())
				If Not CheckFilename(folder$)
					MessageRequester("Ошибка имени папки", "Задайте правильно маску папки: " + iniGroups()\folder + #CRLF$ + folder$)
					ProcedureReturn
				EndIf
				If Right(folder$, 1) <> #PS$
					folder$ + #PS$
				EndIf
				If FileSize(iniGroups()\path + folder$) <> -2 And Not CreateDirectory(iniGroups()\path + folder$)
					MessageRequester("Ошибка создания папки", "Не удалось создать папку: " + #CRLF$ + iniGroups()\path + folder$)
					iniGroups()\isExistPath = -1
					ProcedureReturn
				EndIf
				
				
				Select iniGroups()\genname
					Case 1
						name$ =  FormatDate("%yyyy.%mm.%dd %hh.%ii.%ss", Date()) 
					Case 2
						i = 0
						Repeat
							i + 1
							name$ = Str(i)
							Debug name$
						Until FileSize(iniGroups()\path + folder$ + name$ + iniGroups()\ext) = -1
						Debug name$
					Default
						Repeat
							name$ = InputRequester("Задайте имя файла", "Пустое - Отмена", "")
							If Not Asc(name$)
								ProcedureReturn
							EndIf
; 							Цикл исключения дубликата файла, чтобы не перезаписать существующий а добавить с индексом
							i = 0
							ind$ = ""
							While FileSize(iniGroups()\path + folder$ + name$ + ind$ + iniGroups()\ext) >= 0
								i + 1
								ind$ = "_" + Str(i)
							Wend
							name$ + ind$
						Until CheckFilename(name$)
				EndSelect
; 				If iniGroups()\genname
; 					name$ =  FormatDate("%yyyy.%mm.%dd %hh.%ii.%ss", Date()) 
; 				Else
; 					Repeat
; 						name$ = InputRequester("Задайте имя файла", "", "")
; 					Until CheckFilename(name$)
; 				EndIf
; 				Debug iniGroups()\ext
				If Asc(iniGroups()\ext) And CheckFilename(iniGroups()\ext)
; 					Debug iniGroups()\ext
					name$ + iniGroups()\ext
; 					Debug name$
				EndIf
				If Asc(name$)
					tmp$ = iniGroups()\path + folder$ + name$
					If CreateFile(#File, tmp$, iniGroups()\wstr) ; создаёт пустой файл
						If iniGroups()\bom ; добавлять ли метку BOM
							WriteStringFormat(#File , iniGroups()\wstr)
						EndIf
						If WriteString(#File, Selected_Text$, iniGroups()\wstr) And IsSound
							PlaySound(#RingTone)
							;Delay(IsSound)
						EndIf
						CloseFile(#File)
						If iniGroups()\run And FileSize(tmp$) > 0
							RunProgram(editor$, tmp$, GetPathPart(tmp$))
						EndIf
					Else
						MessageRequester("Ошибка", "Не удалось создать файл для цитат.")
					EndIf
				EndIf

		EndSelect
	EndIf
	
	SetGadgetText(#Editor , "")
EndProcedure


		;-┌──GUI──┐
hWnd_0 = OpenWindow(#WindowSet, 0, 0, 240, 75, "Hotkey", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_Invisible)

If hWnd_0
	If ini_top
		StickyWindow(#WindowSet, #True)
	EndIf
	; 	ShortcutGadget(#GadgetHK, 10, 10, 200, 25, #PB_Shortcut_Alt | #PB_Shortcut_J)
; 	hHotkey = CreateWindowEx_(0, #HOTKEY_CLASS, 0, #WS_CHILD | #WS_VISIBLE | #WS_TABSTOP, 10, 10, 200, 25, hWnd_0, 0, 0, 0)
; 	SendMessage_(hHotkey, #HKM_SETHOTKEY, #PB_Shortcut_J | (#HOTKEYF_CONTROL << 8), 0)
; 	SendMessage_(hHotkey, #HKM_SETHOTKEY, ini_HotkeyCode, 0)
	hHotkey = ShortcutGadget(#Hotkey, 10, 10, 220, 25, ini_HotkeyCode)
; 	hFont = LoadFont(0, "Arial", 11)
; 	If hFont
; 		SendMessage_(hHotkey, #WM_SETFONT, hFont, #True)
; 	EndIf
	ButtonGadget(#btnApply, 130, 40, 100, 28, "Применить")


;- ├ Menu создание
	If CreatePopupMenu(#Menu) ; Создаёт всплывающее меню
		MenuItem(#mShow, "Показать настройки")
		MenuItem(#mHelp, "Справка")
		MenuItem(#mQFile, "Открыть файл с цитатами")
		MenuItem(#mQFolder, "Открыть рабочую папку")
		MenuItem(#mINI, "Открыть ini")
		MenuItem(#mAbout, "О программе")
		MenuBar()
		MenuItem(#mExit, "Выход")
	EndIf
	#SysTrayIcon = 0
; If ExtractIconEx_("'Shell32.dll", 0, 0, @hIcon, 138)
; EndIf
	AddSysTrayIcon(#SysTrayIcon, hWnd_0, GetClassLongPtr_(hWnd_0, #GCL_HICON))
Else
	End
EndIf


		;-┌──GUI──┐
hWnd_1 = OpenWindow(#WindowPreview, 0, 0, ini_width, ini_height, "Предпросмотр", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_Invisible)

If hWnd_1
	If ini_top
		StickyWindow(#WindowPreview , #True)
	EndIf
	SetActiveWindow(#WindowPreview)
	
	EditorGadget(#Editor, 5, 5, w - 170, h - 43, #PB_Editor_WordWrap)
	If ini_ClrBG
		SetGadgetColor(#Editor , #PB_Gadget_BackColor, $3f3f3f)
	EndIf
	If ini_ClrFnt
		SetGadgetColor(#Editor , #PB_Gadget_FrontColor, $aaaaaa)
	EndIf

	ListViewGadget(#LBxGrps , w - 160, 5, 150, h - 43)
	If ini_ClrBG
		SetGadgetColor(#LBxGrps , #PB_Gadget_BackColor, $3f3f3f)
	EndIf
	If ini_ClrFnt
		SetGadgetColor(#LBxGrps , #PB_Gadget_FrontColor, $aaaaaa)
	EndIf

	i = 0
	ForEach iniGroups()
		AddGadgetItem(#LBxGrps, i, iniGroups()\name)
		SetGadgetItemData(#LBxGrps, i, iniGroups()\p)
		i + 1
	Next
	ButtonGadget(#btnOk, w - 110, h - 35, 100, 30, "OK", #PB_Button_Default)
	ButtonGadget(#btnCancel, w - 220, h - 35, 100, 30, "Отмена")
	ButtonGadget(#btnMenu, w - 260, h - 35, 30, 30, Chr($2630)) ; ☰ (меню)
	
	If CreatePopupMenu(#Menu1) ; Создаёт всплывающее меню
		MenuItem(#mEsc, "Esc" + #TAB$ + "Esc")
	EndIf
	AddKeyboardShortcut(#WindowPreview, #PB_Shortcut_Escape, #mEsc)
	AddKeyboardShortcut(#WindowPreview, #PB_Shortcut_F1, #mHelp)
	AddKeyboardShortcut(#WindowPreview, #PB_Shortcut_F2, #mQFile)
	BindEvent(#PB_Event_SizeWindow, @SizeHandler())
Else
	End
EndIf


; регистрация горячей клавиши
If ini_HotkeyCode
; 	Debug ini_HotkeyCode
	VirtKey = ini_HotkeyCode & $FF ; LoWord
	ModKey = GetModKey(ini_HotkeyCode >> 8)
; 	Debug GetKey(ini_HotkeyCode)
	; Debug SendMessage_(GadgetID(#GadgetHK), #HKM_GETHOTKEY, 0, 0)
	; If MAKELONG(loword, hiword)
	UnregisterHotKey_(hWnd_0, #HK_ID) ; переназначение работает без отмены регистрации
	If Not RegisterHotKey_(hWnd_0, #HK_ID, ModKey, VirtKey)
		MessageRequester("Ошибка", "Не удалось зарегистрировать горячую клавишу")
	EndIf
Else
EndIf



;-┌──Loop Tray──┐
Repeat
	WWE = WaitWindowEvent()
	If WWE = #WM_QUERYENDSESSION ; выход из ОС, пришёл запрос завершения сессии
		_Exit()
	EndIf
	Select EventWindow()
		Case #WindowSet
			Select WWE
;- ├ События Настройки хоткея
				Case #PB_Event_Gadget
					Select EventGadget()
						Case #btnApply
							; 						ini_HotkeyCode = GetGadgetState(#GadgetHK)
							ini_HotkeyCode = SendMessage_(hHotkey, #HKM_GETHOTKEY, 0, 0)
							If Not ini_HotkeyCode
								Debug "Отмена горячей клавиши (Backspace)"
								UnregisterHotKey_(hWnd_0, #HK_ID)
							EndIf
							Debug ini_HotkeyCode
							
							If isINI And OpenPreferences(ini$, #PB_Preference_GroupSeparator)
								If PreferenceGroup("set")
									WritePreferenceLong("HotkeyCode", ini_HotkeyCode)
								EndIf
								ClosePreferences()
							EndIf
							
							VirtKey = ini_HotkeyCode & $FF ; LoWord
							ModKey = GetModKey(ini_HotkeyCode >> 8)
							Debug GetKey(ini_HotkeyCode)
							; Debug SendMessage_(GadgetID(#GadgetHK), #HKM_GETHOTKEY, 0, 0)
							; If MAKELONG(loword, hiword)
							UnregisterHotKey_(hWnd_0, #HK_ID) ; переназначение работает без отмены регистрации
							If Not RegisterHotKey_(hWnd_0, #HK_ID, ModKey, VirtKey)
								Debug "Не удалось зарегистрировать горячую клавишу"
							EndIf
							HideWindow(#WindowSet, #True)
					EndSelect
;- ├ События трея
				Case #PB_Event_SysTray
					Select EventType()
						Case #PB_EventType_RightClick, #PB_EventType_LeftClick
							DisplayPopupMenu(#Menu, WindowID(#WindowSet))  ; показывает всплывающее Меню
		; 							SetWindowState(#WindowSet, #PB_Window_Normal)
		; 							SetActiveWindow(#WindowSet)
		; 							HideWindow(#WindowSet, #False)
					EndSelect
				Case #PB_Event_CloseWindow
					HideWindow(#WindowSet, #True)
			EndSelect
; 		Case #WindowPreview
; 			Select WWE
; ;- ├ События Предпросмотра
; 				Case #PB_Event_Gadget
; 					Select EventGadget()
; 						Case #btnApply
; 					EndSelect
; 				Case #PB_Event_CloseWindow
; 					HideWindow(#WindowPreview, #True)
; 			EndSelect
	EndSelect
	
	Select WWE
;- ├ События меню
		Case #PB_Event_Menu        ; кликнут элемент всплывающего Меню
			EvMenu(EventMenu())

;- ├ События хоткея
		Case #WM_HOTKEY
			Select EventwParam()
				Case #HK_ID
					_Re()
; 					Debug "Перехвачена горячая клавиша 1"
			EndSelect
	EndSelect
ForEver
;-└──Loop──┘


Procedure EvMenu(ev)
			Select ev    ; получим кликнутый элемент Меню...
				Case #mINI
					RunProgram(ini$)
				Case #mQFolder
					idx = GetGadgetState(#LBxGrps)
					If idx > -1
						*item = GetGadgetItemData(#LBxGrps, idx)
						If *item
							ChangeCurrentElement(iniGroups(), *item)
							If Not Asc(iniGroups()\path) ; если путь пуст то используем папку по умолчанию
								tmp$ = PathConfig$
							ElseIf Mid(iniGroups()\path, 2, 2) <> ":\" ; относительный путь
								tmp$ = PathConfig$ + iniGroups()\path
							Else
								tmp$ = iniGroups()\path ; абсолютный путь
							EndIf
							If FileSize(tmp$) > -1 ; если файл, то обрезаем
								tmp$ = GetPathPart(tmp$)
							EndIf
							If FileSize(tmp$) = -2 ; если папка то открываем
								RunProgram(fm$, tmp$, "")
							Else
								RunProgram(fm$, PathConfig$, "") ; иначе папка конфига
							EndIf
						EndIf
					EndIf
				Case #mQFile
					idx = GetGadgetState(#LBxGrps)
					If idx > -1
						*item = GetGadgetItemData(#LBxGrps, idx)
						If *item
							ChangeCurrentElement(iniGroups(), *item)
							If Not Asc(iniGroups()\path) ; если путь пуст то используем файл по умолчанию
								tmp$ = PathConfig$ + "Quotation.txt"
							ElseIf Mid(iniGroups()\path, 2, 2) <> ":\" ; относительный путь
								tmp$ = PathConfig$ + iniGroups()\path
							Else
								tmp$ = iniGroups()\path ; абсолютный путь
							EndIf
							If FileSize(tmp$) > 0 ; если файл то открываем
								RunProgram(editor$, tmp$, "")
							EndIf
						EndIf
					EndIf
				Case #mHelp
					tmp$ = GetPathPart(ProgramFilename()) + "Quotation.chm"
					If FileSize(tmp$) > 0
						RunProgram(tmp$)
					EndIf
				Case #mExit
					_Exit()
				Case #mShow
; 					SetWindowState(#WindowSet, #PB_Window_Normal)
					HideWindow(#WindowSet, #False)
				Case #mAbout
					MessageRequester("О программе", "Автор AZJIO (" + #date$ + ")")
				Case #mEsc
					HideWindow(#WindowPreview, #True)
					SetGadgetText(#Editor , "")
					ProcedureReturn
			EndSelect
EndProcedure

Procedure _Exit()
	If ini_Preview
		idx = GetGadgetState(#LBxGrps)
		If idx > -1
			If ini_SelLst <> idx
				If OpenPreferences(ini$)
					If PreferenceGroup("set")
						WritePreferenceInteger("SelLst", idx)
						ClosePreferences()
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	; 	Если изменены размеры окна, то сохраняем
; 	Debug w
; 	Debug ini_width
; 	Debug h
; 	Debug ini_height
	If w <> ini_width Or h <> ini_height
		If OpenPreferences(ini$)
			If PreferenceGroup("set")
				WritePreferenceInteger("width", w)
				WritePreferenceInteger("height", h)
				ClosePreferences()
			EndIf
		EndIf
	EndIf
; 	DestroyWindow_(hHotkey)
	UnregisterHotKey_(hWnd_0, #HK_ID)
	CloseWindow(#WindowSet)
	RemoveSysTrayIcon(#SysTrayIcon)
; 	If IsSound ; звуки удаляются автоматически
; 		FreeSound(#RingTone) 
; 	EndIf
	End
EndProcedure

Procedure SizeHandler()
	w = WindowWidth(#WindowPreview)
	h = WindowHeight(#WindowPreview)
	ResizeGadget(#LBxGrps, w - 160, #PB_Ignore, #PB_Ignore, h - 43)
	ResizeGadget(#Editor, #PB_Ignore, #PB_Ignore, w - 170, h - 43)
	ResizeGadget(#btnOk, w - 110, h - 35, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnCancel, w - 220, h - 35, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnMenu, w - 260, h - 35, #PB_Ignore, #PB_Ignore)
EndProcedure

; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 5
; Folding = -
; Optimizer
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = Quotation.exe
; CompileSourceDirectory
; Compiler = PureBasic 6.04 LTS - C Backend (Windows - x64)
; EnableBuildCount = 0
; IncludeVersionInfo
; VersionField0 = 0.5.3.%BUILDCOUNT
; VersionField2 = AZJIO
; VersionField3 = Quotation
; VersionField4 = 0.5.3
; VersionField6 = Quotation
; VersionField9 = AZJIO