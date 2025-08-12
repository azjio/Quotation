; AZJIO цитатник 24.08.2022

EnableExplicit

UseGIFImageDecoder()
; UseOGGSoundDecoder() 

#date$ = "2024.03.09"
#q$ = Chr(34)
#File = 0

;- Перечисления
#WindowPreview = 0

;- ● Enumeration
Enumeration
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
	#mINI
	#mExit
	#mEsc
EndEnumeration

XIncludeFile "ForQuotation.pb"


Structure iniGroups
	mode.i
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
Global strcopy$="xdotool key ctrl+c"
Global tmp$
Define *p
Define i
; Define isINI = 0
Global hFont;, hIcon
Global NewList iniGroups.iniGroups()

;- ini
Global PathConfig$ = GetPathPart(ProgramFilename())
Global ini$
If FileSize(PathConfig$ + "Quotation.ini") < 0
	PathConfig$ = GetHomeDirectory() + ".config/Quotation/"
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


Global ini_MaxSize.l = 500
Global ini_Preview = 1
Global ini_Clipboard = 0
; Global ini_Separator$ = "\n\n=== %d %t ====\n\n"
Global ini_Signal$
Global ini_ClrFnt = 0
Global ini_ClrBG = 0
Global ini_SelLst = 0
Global ini_width = 640
Global ini_height = 570
Global ini_top = 1
Global w, h
Global editor$ = "xdg-open"
Global fm$ = "xdg-open"
Global DelayCtrlC = 30

ExamineDesktops()

If FileSize(ini$) > 3 And OpenPreferences(ini$)
	If PreferenceGroup("set")
		strcopy$ = ReadPreferenceString("strcopy", strcopy$)
		editor$ = ReadPreferenceString("editor", editor$)
		fm$ = ReadPreferenceString("fm", fm$)
		ini_SelLst = ReadPreferenceInteger("SelLst", ini_SelLst)
		
		ini_width = ReadPreferenceInteger("width", ini_width)
		Limit(@ini_width, 150, DesktopWidth(0))
		ini_height = ReadPreferenceInteger("height", ini_height)
		Limit(@ini_height, 150, DesktopHeight(0))
		
		ini_top = ReadPreferenceInteger("top", ini_top)
		ini_MaxSize = ReadPreferenceInteger("MaxSize", ini_MaxSize)
		DelayCtrlC = ReadPreferenceInteger("DelayCtrlC", DelayCtrlC)
		ini_Preview = ReadPreferenceInteger("Preview", ini_Preview)
		If ini_Preview
			ini_ClrFnt = ColorValidate(ReadPreferenceString("ClrFnt", ""), ini_ClrFnt)
			ini_ClrBG = ColorValidate(ReadPreferenceString("ClrBG", ""), ini_ClrBG)
		EndIf
		ini_Clipboard = ReadPreferenceInteger("Clipboard", ini_Clipboard)
; 		ini_Separator$ = ReadPreferenceString("Separator", ini_Separator$)
		ini_Signal$ = ReadPreferenceString("Signal", "")
; 		ini_PathQuoteTxt$ = ReadPreferenceString("PathQuoteTxt", ini_PathQuoteTxt$)
; 		isINI = 1
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

If Not ListSize(iniGroups())
	If MessageRequester("Ошибка", "В ini-файле нет ни одной секции настроек для сохранения цитат." + #CRLF$ + #CRLF$ + "Открыть ini-файл?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
		RunProgram(ini$)
	EndIf
	End
EndIf

; кэшируем размеры окна
w = ini_width
h = ini_height

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



Procedure SizeHandler()
	w = WindowWidth(#WindowPreview)
	h = WindowHeight(#WindowPreview)
	ResizeGadget(#LBxGrps, w - 160, #PB_Ignore, #PB_Ignore, h - 43)
	ResizeGadget(#Editor, #PB_Ignore, #PB_Ignore, w - 170, h - 43)
	ResizeGadget(#btnOk, w - 110, h - 35, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnCancel, w - 220, h - 35, #PB_Ignore, #PB_Ignore)
	ResizeGadget(#btnMenu, w - 260, h - 35, #PB_Ignore, #PB_Ignore)
EndProcedure

	
Procedure _Re()
	Protected Selected_Text$, i, WWE, idx, name$, folder$, KeyCode, Separator$, ind$, Title$
	Protected *item
	; 	Static Change = 1
	
	ClearClipboard() ; если не будет выполнено захват выделенного в буфер, т оотчиста предостращает опадание старого буфера.
	
	If Not ini_Clipboard ; если strcopy$ не работает то отключаем его
		Delay(30)
		Execute(strcopy$)
		Delay(DelayCtrlC)
	EndIf
	Selected_Text$ = GetClipboardText()

	If Not Asc(Selected_Text$)
		ProcedureReturn
	EndIf
	
	If ini_Preview ; если показ то создаём GUI
		
		;-┌──GUI──┐
		If OpenWindow(#WindowPreview, 0, 0, w, h, "Предпросмотр",
			#PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget)

			gtk_window_set_icon_(WindowID(#WindowPreview), ImageID(0)) ; назначаем иконку в заголовке
			If ini_top
				StickyWindow(#WindowPreview , #True)
			EndIf
			
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
			
			
			If CreatePopupMenu(#Menu) ; Создаёт всплывающее меню
				MenuItem(#mHelp, "Справка" + #TAB$ + "F1")
				MenuItem(#mQFile, "Открыть файл с цитатами" + #TAB$ + "F2")
				MenuItem(#mQFolder, "Открыть рабочую папку")
				MenuItem(#mINI, "Открыть ini")
				MenuItem(#mAbout, "О программе")
				MenuBar()
				MenuItem(#mExit, "Выход")
			EndIf
			AddKeyboardShortcut(#WindowPreview, #PB_Shortcut_Escape, #mEsc)
			AddKeyboardShortcut(#WindowPreview, #PB_Shortcut_F1, #mHelp)
			AddKeyboardShortcut(#WindowPreview, #PB_Shortcut_F2, #mQFile)
			BindEvent(#PB_Event_SizeWindow, @SizeHandler())
		Else
			End
		EndIf


		SetGadgetText(#Editor , Selected_Text$)
		SetActiveWindow(#WindowPreview)
; 		SetForegroundWindow(WindowID(#WindowPreview))
		SetActiveGadget(#LBxGrps)
; 		SetWindowLongPtr_(GadgetID(#btnOk), #GWL_STYLE, GetWindowLongPtr_(GadgetID(#btnOk), #GWL_STYLE) | #BS_DEFPUSHBUTTON)
		SetGadgetState(#LBxGrps, ini_SelLst)
		
;-┌──Loop──┐
		Repeat
			WWE = WaitWindowEvent()
			Select EventWindow()
				Case #WindowPreview
					Select WWE
; 						Case #PB_Event_SizeWindow
; 							w = WindowWidth(#WindowPreview)
; 							h = WindowHeight(#WindowPreview)
; 							ResizeGadget(#LBxGrps, w - 160, #PB_Ignore, #PB_Ignore, h - 43)
; 							ResizeGadget(#Editor, #PB_Ignore, #PB_Ignore, w - 170, h - 43)
; 							ResizeGadget(#btnOk, w - 110, h - 35, #PB_Ignore, #PB_Ignore)
; 							ResizeGadget(#btnCancel, w - 220, h - 35, #PB_Ignore, #PB_Ignore)
; 							ResizeGadget(#btnMenu, w - 260, h - 35, #PB_Ignore, #PB_Ignore)
; 						Case #WM_KEYDOWN
; 							KeyCode = EventlParam() >> 16 & $FF
; 							Select KeyCode
; 								Case 28
; 									If GetActiveGadget() = #LBxGrps
; ; 										повтряются действия события #btnOk
; 										idx = GetGadgetState(#LBxGrps)
; ; 										Debug idx
; 										If idx <> -1
; 											*item = GetGadgetItemData(#LBxGrps, idx)
; 										EndIf
; 										If ini_Preview And iniGroups()\edit
; ; 											Debug "|" + Selected_Text$ + "|"
; 											Selected_Text$ = GetGadgetText(#Editor)
; ; 											Debug "|" + Selected_Text$ + "|"
; 										EndIf
; 										HideWindow(#WindowPreview, #True)
; 										SetGadgetText(#Editor , "")
; 										Break
; 									EndIf
; 							EndSelect
;- ├ Menu События
						Case #PB_Event_Menu        ; кликнут элемент всплывающего Меню
							Select EventMenu()	   ; получим кликнутый элемент Меню...
								Case #mEsc
									End
								Case #mINI
									RunProgram(editor$, ini$, "")
								Case #mQFolder
									idx = GetGadgetState(#LBxGrps)
									If idx > -1
										*item = GetGadgetItemData(#LBxGrps, idx)
										If *item
											ChangeCurrentElement(iniGroups(), *item)
											If Not Asc(iniGroups()\path)
												tmp$ = PathConfig$
											ElseIf Asc(iniGroups()\path) <> '/'
												tmp$ = PathConfig$ + iniGroups()\path ; если путь пуст то используем папку по умолчанию
											Else
												tmp$ = iniGroups()\path
											EndIf
											If FileSize(tmp$) > -1
												tmp$ = GetPathPart(tmp$)
											EndIf
											If FileSize(tmp$) = -2
												RunProgram(fm$, tmp$, "")
											Else
												RunProgram(fm$, PathConfig$, "")
											EndIf
										EndIf
									EndIf
								Case #mQFile
									idx = GetGadgetState(#LBxGrps)
									If idx > -1
										*item = GetGadgetItemData(#LBxGrps, idx)
										If *item
											ChangeCurrentElement(iniGroups(), *item)
											If Not Asc(iniGroups()\path)
												tmp$ = PathConfig$ + "Quotation.txt"
											ElseIf Asc(iniGroups()\path) <> '/'
												tmp$ = PathConfig$ + iniGroups()\path ; если путь пуст то используем папку по умолчанию
											Else
												tmp$ = iniGroups()\path
											EndIf
											If FileSize(tmp$) > 0
												RunProgram(editor$, tmp$, "")
											EndIf
										EndIf
									EndIf
								Case #mHelp
									tmp$ = "/usr/share/help/ru/quotation/quotation.htm"
									If FileSize(tmp$) > 0
										RunProgram("xdg-open", tmp$, GetPathPart(tmp$))
									EndIf
								Case #mExit
									End
								Case #mAbout
									MessageRequester("О программе", "Автор AZJIO (" + #date$ + ")")
							EndSelect
;- ├ Gadget События
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
										*item = GetGadgetItemData(#LBxGrps, idx)
; 										Debug *item
; 										Debug ListSize(iniGroups()) ; список глобальный но выдает бред, размер 94743837484327832
										If *item
											ChangeCurrentElement(iniGroups(), *item)
										EndIf
										If ini_SelLst <> idx
											If OpenPreferences(ini$)
												If PreferenceGroup("set")
													WritePreferenceInteger("SelLst", idx)
													ClosePreferences()
												EndIf
											EndIf
										EndIf
										
; 										при отмене не сохраняются размеры окна, сделать функцию выхода
										If w <> ini_width Or h <> ini_height
											If OpenPreferences(ini$)
												If PreferenceGroup("set")
													WritePreferenceInteger("width", w)
													WritePreferenceInteger("height", h)
													ClosePreferences()
												EndIf
											EndIf
										EndIf
										
									EndIf
									If iniGroups()\edit ; если разрешена правка, то копируем текст с окна
; 										Debug "|" + Selected_Text$ + "|"
										Selected_Text$ = GetGadgetText(#Editor)
; 										Debug "|" + Selected_Text$ + "|"
									EndIf
									Break
								Case #btnCancel
									End
							EndSelect
						Case #PB_Event_CloseWindow
								End
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
				If Not Asc(iniGroups()\path)
					iniGroups()\path = PathConfig$ + "Quotation.txt"
				ElseIf Asc(iniGroups()\path) <> '/'
					iniGroups()\path = PathConfig$ + iniGroups()\path ; если путь пуст то используем папку по умолчанию
				EndIf
				
				; 					создаём , если не существует
				If FileSize(iniGroups()\path) < 0
					ForceDirectories(GetPathPart(iniGroups()\path)) ; если абсолютный путь не существует, то создаём
					If CreateFile(#File, iniGroups()\path, iniGroups()\wstr) ; создаёт пустой файл
						If iniGroups()\bom									 ; добавлять ли метку BOM
							WriteStringFormat(#File , iniGroups()\wstr)
						EndIf
						CloseFile(#File)
					EndIf
				EndIf
				
				; 					предупреждаем, если нет доступа, или это папка или любая причина по которой не создан файл 
				If FileSize(iniGroups()\path) < 0
					MessageRequester("Ошибка", "Не удалось создать файл для цитат.")
					ProcedureReturn
				EndIf
				
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
				
				If OpenFile(#File, iniGroups()\path, iniGroups()\wstr)
					FileSeek(#File, Lof(#File))
					Separator$ = ReplaceString(iniGroups()\separator , "%d" , FormatDate("%yyyy.%mm.%dd", Date()))
					Separator$ = ReplaceString(Separator$ , "%t" , FormatDate("%hh.%ii.%ss", Date()))
					If iniGroups()\title
						Title$ = StringBetween2(Selected_Text$, iniGroups()\title, "_|_")
					EndIf
					If WriteString(#File, Separator$ + Title$ + Selected_Text$, iniGroups()\wstr) And IsSound
						PlaySound(#RingTone)
						Delay(IsSound)
					EndIf
					CloseFile(#File)
				Else
					MessageRequester("Ошибка", "Не удалось открыть файл для цитат.")
				EndIf
				
			Case 2
				; 					Debug "|" + iniGroups()\path + "|"
				; 					Debug Mid(iniGroups()\path, 2, 2)
				If Not Asc(iniGroups()\path)
					iniGroups()\path = PathConfig$ + "Quotation" ; если путь пуст то используем папку по умолчанию
				ElseIf Asc(iniGroups()\path) <> '/'
					iniGroups()\path = PathConfig$ + iniGroups()\path ; если путь пуст то используем папку по умолчанию
				EndIf
				If FileSize(iniGroups()\path) = -1
					ForceDirectories(iniGroups()\path) ; если путь не существует, то создаём
				EndIf
				If FileSize(iniGroups()\path) <> -2
					; MessageRequester("Ошибка", "Не удалось создать папку для цитат.")
					MessageRequester("", "Не удалось определить и создать путь:" + #CRLF$ + iniGroups()\path)
					ProcedureReturn
				EndIf
				
				If Right(iniGroups()\path, 1) <> #PS$
					iniGroups()\path + #PS$
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
							Delay(IsSound)
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
	
	
EndProcedure


DataSection
		IconTitle:
		IncludeBinary "icon.gif"
		IconTitleend:
EndDataSection

CatchImage(0, ?IconTitle)

_Re()
; IDE Options = PureBasic 6.12 LTS (Linux - x64)
; CursorPosition = 404
; FirstLine = 379
; Folding = -
; Optimizer
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = quotation
; CompileSourceDirectory
; Compiler = PureBasic 6.12 LTS - C Backend (Linux - x64)
; EnableBuildCount = 6
; IncludeVersionInfo
; VersionField0 = 0.1.0.%BUILDCOUNT
; VersionField2 = AZJIO
; VersionField3 = Quotation
; VersionField4 = 0.1
; VersionField6 = Quotation
; VersionField9 = AZJIO