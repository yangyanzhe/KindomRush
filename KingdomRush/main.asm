TITLE Windows Application                   (WinApp.asm)

.386      
.model flat,stdcall      
option casemap:none

INCLUDE     windows.inc
INCLUDE     gdi32.inc
INCLUDE     user32.inc
INCLUDE		msimg32.inc
INCLUDE     kernel32.inc

INCLUDELIB  gdi32.lib
INCLUDELIB  kernel32.lib
INCLUDELIB  user32.lib
INCLUDELIB  msimg32.lib

INCLUDE     core.inc
INCLUDE     main.inc

;==================== DATA =======================
.data
Level       dd 0

;=================== CODE =========================
InitImages PROTO,
    hInst:DWORD

InitMapInfo PROTO

TimerProc PROTO,
    hWnd: DWORD

LMouseProc PROTO,
	hWnd: DWORD,
	cursorPosition: POINTS
	
PaintProc PROTO,
    hWnd: DWORD

.code

;-----------------------------------------------------
WinMain PROC
;-----------------------------------------------------
    LOCAL   wndClass: WNDCLASSEX
    LOCAL   msg: MSG
    LOCAL   scrWidth: DWORD
    LOCAL   scrHeight: DWORD

    ; ��ȡ���
    INVOKE  GetModuleHandle, NULL
    mov     hInstance, eax
    mov     wndClass.hInstance, eax
    INVOKE  RtlZeroMemory, ADDR wndClass, SIZEOF wndClass

    ; ���س���Ĺ���ͼ��
    INVOKE  LoadIcon, hInstance, IDI_ICON
    mov     hIcon, eax
    mov     wndClass.hIcon, eax
    mov     wndClass.hIconSm, eax
    INVOKE  LoadCursor, hInstance, IDC_ARROW
    mov     wndClass.hCursor, eax

    ; ����ͼƬ
	INVOKE  InitImages, hInstance 

	; ��ʼ������
    mov     wndClass.cbSize, SIZEOF WNDCLASSEX
    mov     wndClass.hbrBackground, COLOR_WINDOW + 1
    mov     wndClass.lpfnWndProc, OFFSET WinProc
    mov     wndClass.lpszClassName, OFFSET classname
    mov     wndClass.style, CS_HREDRAW or CS_VREDRAW

    ; ע�ᴰ����
	INVOKE  RegisterClassEx, ADDR wndClass
    .IF eax == 0
      call  ErrorHandler
      jmp   Exit_Program
    .ENDIF

    ; �������ڣ�������Ļ���룩
    INVOKE  GetSystemMetrics, SM_CXSCREEN
	mov     scrWidth, eax
	INVOKE  GetSystemMetrics, SM_CYSCREEN
	mov     scrHeight, eax
    mov     ebx, 2
	mov     edx, 0
	mov     eax, scrWidth
	sub     eax, window_w
	div     ebx
	mov     window_x, eax
	mov     eax, scrHeight
	sub     eax, window_h
	div     ebx
	mov     window_y, eax

    INVOKE  CreateWindowEx, 
            0, 
            OFFSET classname,
            OFFSET windowname, 
            WS_OVERLAPPED or WS_SYSMENU or WS_MINIMIZEBOX ,
            window_x, 
            window_y, 
            window_w,
            window_h, 
            NULL, 
            NULL, 
            hInstance, 
            NULL
    mov     hMainWnd,eax

    .IF eax == 0
      call  ErrorHandler
      jmp   Exit_Program
    .ENDIF

    ; ���ƴ���
    INVOKE  ShowWindow, hMainWnd, SW_SHOW
    INVOKE  UpdateWindow, hMainWnd

    ; ��Ϣѭ��
Message_Loop:
    INVOKE  GetMessage, ADDR msg, NULL, NULL, NULL

    ; �˳�WM_QUIT
    .IF eax == 0
      jmp   Exit_Program
    .ENDIF

    INVOKE  TranslateMessage, ADDR msg
    INVOKE  DispatchMessage, ADDR msg
    jmp     Message_Loop

Exit_Program:
    ret
WinMain ENDP

;-----------------------------------------------------
WinProc PROC,
    hWnd: DWORD, 
    localMsg: DWORD, 
    wParam: DWORD, 
    lParam: DWORD
;-----------------------------------------------------
    LOCAL   cursorPosition: POINTS
	LOCAL	ps: PAINTSTRUCT

    mov      eax, localMsg

    .IF eax == WM_TIMER
      INVOKE    TimerProc, hWnd
      jmp    	WinProcExit
    .ELSEIF eax == WM_PAINT         ; ��ͼ
	  INVOKE    BeginPaint, hWnd, ADDR ps
	  mov       hDC, eax
	  INVOKE    PaintProc, hWnd
	  INVOKE    EndPaint, hWnd, ADDR ps
	  jmp       WinProcExit
    .ELSEIF eax == WM_LBUTTONDOWN   ; ����¼�
      mov  	    ebx, lParam
      mov  	    cursorPosition.x, bx
	  shr  	    ebx, 16
	  mov  	    cursorPosition.y, bx
	  .IF wParam == MK_LBUTTON
		INVOKE 	LMouseProc, hWnd, cursorPosition
	  .ENDIF
      jmp    	WinProcExit
    .ELSEIF eax == WM_CLOSE         ; �رմ����¼�
      INVOKE 	PostQuitMessage, 0
      jmp    	WinProcExit
    .ELSEIF eax == WM_CREATE        ; ���������¼�
      INVOKE 	SendMessage, hWnd, WM_SETICON, ICON_SMALL, hIcon
      INVOKE    InitMapInfo
      INVOKE    LoadGameInfo
      INVOKE    SetTimer, hWnd, TIMER_ID, TIMER_INTERVAL, NULL
      jmp    	WinProcExit
    .ELSE                           ; �����¼�
      INVOKE 	DefWindowProc, hWnd, localMsg, wParam, lParam
      jmp    	WinProcExit
    .ENDIF

WinProcExit:
    ret
WinProc ENDP

;---------------------------------------------------------
InitImages PROC,
    hInst:DWORD
;
; LoadImage of game. If more levels are designed, considering
; input the level number.
; Receives: handler
; Returns:  nothing
;---------------------------------------------------------
    LOCAL   bm: BITMAP

    ; �����ͼͼƬ
    mov     ecx, mapNum
    mov     ebx, OFFSET mapHandler
    mov     edx, IDB_MAP
LoadMap:
    push    ecx
    push    edx
	INVOKE  LoadBitmap, hInst, edx
    mov     (BitmapInfo PTR [ebx]).bHandler, eax
    INVOKE  GetObject, (BitmapInfo PTR [ebx]).bHandler, SIZEOF BITMAP, ADDR bm
    mov     eax, bm.bmWidth
    mov     (BitmapInfo PTR [ebx]).bWidth, eax
    mov     eax, bm.bmHeight
    mov     (BitmapInfo PTR [ebx]).bHeight, eax
    pop     edx
    pop     ecx
    add     ebx, TYPE BitmapInfo
    add     edx, 1
    loop    LoadMap

    ; ����յ�λ��
    mov     ecx, mapNum
    mov     ebx, OFFSET blankSet
    mov     edx, OFFSET blankIndex
    mov     esi, OFFSET blankPosition
LoadBlankPosition:
    push    ecx
    mov     eax, [edx + TYPE DWORD]
    sub     eax, [edx]
    mov     (PositionSet PTR [ebx]).number, eax

    mov     ecx, eax
    mov     edi, ebx
    add     edi, TYPE DWORD
LoadBlankPosition0:
    mov     eax, (Coord PTR [esi]).x
    mov     (Coord PTR [edi]).x, eax
    mov     eax, (Coord PTR [esi]).y
    mov     (Coord PTR [edi]).y, eax
    add     esi, TYPE Coord
    add     edi, TYPE Coord
    loop    LoadBlankPosition0

    add     ebx, TYPE PositionSet
    add     edx, TYPE DWORD
    pop     ecx
    loop    LoadBlankPosition

    ; ��������ͼƬ
    mov     ecx, towerNum
    mov     ebx, OFFSET towerHandler
    mov     edx, IDB_TOWER
LoadTower:
    push    ecx
    push    edx
    INVOKE  LoadBitmap, hInst, edx
    mov     (BitmapInfo PTR [ebx]).bHandler, eax
    INVOKE  GetObject, (BitmapInfo PTR [ebx]).bHandler, SIZEOF BITMAP, ADDR bm
    mov     eax, bm.bmWidth
    mov     (BitmapInfo PTR [ebx]).bWidth, eax
    mov     eax, bm.bmHeight
    mov     (BitmapInfo PTR [ebx]).bHeight, eax
    pop     edx
    pop     ecx
    add     ebx, TYPE BitmapInfo
    add     edx, 1
    loop    LoadTower

    ; �������ı�־��ͼƬ
    mov     ecx, signNum
    mov     ebx, OFFSET signHandler
    mov     edx, IDB_SIGN
LoadSign:
    push    ecx
    push    edx
    INVOKE  LoadBitmap, hInst, edx
    mov     (BitmapInfo PTR [ebx]).bHandler, eax
    INVOKE  GetObject, (BitmapInfo PTR [ebx]).bHandler, SIZEOF BITMAP, ADDR bm
    mov     eax, bm.bmWidth
    mov     (BitmapInfo PTR [ebx]).bWidth, eax
    mov     eax, bm.bmHeight
    mov     (BitmapInfo PTR [ebx]).bHeight, eax
    pop     edx
    pop     ecx
    add     ebx, TYPE BitmapInfo
    add     edx, 1
    loop    LoadSign
	
    ; �������ͼƬ
    mov     ecx, monsterNum
    mov     ebx, OFFSET monsterHandler
    mov     edx, IDB_MONSTER1
LoadMonster:
    push    ecx
	
	mov 	ecx, 5
LoadMonster0:
	push 	ecx
    push    edx
    INVOKE  LoadBitmap, hInst, edx
    mov     (BitmapInfo PTR [ebx]).bHandler, eax
    INVOKE  GetObject, (BitmapInfo PTR [ebx]).bHandler, SIZEOF BITMAP, ADDR bm
    mov     eax, bm.bmWidth
    mov     (BitmapInfo PTR [ebx]).bWidth, eax
    mov     eax, bm.bmHeight
    mov     (BitmapInfo PTR [ebx]).bHeight, eax
    pop     edx
	add 	ebx, TYPE BitmapInfo
	add 	edx, 1

    push    edx
    INVOKE  LoadBitmap, hInst, edx
    mov     (BitmapInfo PTR [ebx]).bHandler, eax
    INVOKE  GetObject, (BitmapInfo PTR [ebx]).bHandler, SIZEOF BITMAP, ADDR bm
    mov     eax, bm.bmWidth
    mov     (BitmapInfo PTR [ebx]).bWidth, eax
    mov     eax, bm.bmHeight
    mov     (BitmapInfo PTR [ebx]).bHeight, eax
    pop     edx
    pop     ecx
	add 	ebx, TYPE BitmapInfo
	add 	edx, 1
	loop 	LoadMonster0

    pop     ecx
    loop    LoadMonster

	ret
InitImages ENDP

;-----------------------------------------------------------------------
InitMapInfo PROC
;-----------------------------------------------------------------------
    ; ��ʼ��������
    mov     ecx, blankSet[0].number
    mov     Game.Tower_Num, ecx
    mov     ebx, OFFSET blankSet[0].position
    mov     edx, OFFSET Game.TowerArray
InitTower:  
    mov     (Tower PTR [edx]).Tower_Type, 1     ;���ĳ�ʼ����Ϊ0���յأ�
    mov     (Tower PTR [edx]).Range, 100        ;���Ĺ�����Χ
    mov     eax, (Coord PTR [ebx]).x
    mov     (Tower PTR [edx]).Pos.x, eax
    mov     eax, (Coord PTR [ebx]).y
    mov     (Tower PTR [edx]).Pos.y, eax
    add     ebx, TYPE Coord
    add     edx, TYPE Tower
    loop    InitTower

    ret
InitMapInfo ENDP

;-----------------------------------------------------------------------
TimerProc PROC,
    hWnd: DWORD
;-----------------------------------------------------------------------
    ; INVOKE MessageBox, hWnd, NULL, NULL, MB_OK
    INVOKE UpdateTimer
    INVOKE UpdateEnemies
    INVOKE InvalidateRect, hWnd, NULL, FALSE
    ret
TimerProc ENDP

;-----------------------------------------------------------------------
LMouseProc PROC,
	hWnd: DWORD,
	cursorPosition: POINTS
;-----------------------------------------------------------------------
    ; INVOKE MessageBox, hWnd, NULL, NULL, MB_OK
    ret
LMouseProc ENDP

;-----------------------------------------------------------------------
PaintTowers PROC
;-----------------------------------------------------------------------
    ; �������пյ�
	INVOKE  SelectObject, imgDC, towerHandler[0].bHandler
    mov     ecx, blankSet[0].number
    mov     ebx, OFFSET blankSet[0].position
DrawBlank:
	push    ecx
    mov     eax, (Coord PTR [ebx]).y
    sub     eax, towerHandler[0].bHeight
	INVOKE  TransparentBlt, 
            memDC, (Coord PTR [ebx]).x, eax,
            towerHandler[0].bWidth, towerHandler[0].bHeight,
            imgDC, 0, 0, 
            towerHandler[0].bWidth, towerHandler[0].bHeight,
            tcolor
	add     ebx, TYPE Coord
	pop     ecx
	loop    DrawBlank
	
	; �������ڵ���
    mov     ecx, Game.Tower_Num
    mov     ebx, OFFSET Game.TowerArray
    cmp     ecx, 0
    je      PaintTowersExit
DrawTowers:
    push    ecx
    mov     eax, (Tower PTR [ebx]).Tower_Type
    cmp     eax, 0
    je      DrawTowers0
    mov     edx, OFFSET towerHandler
    .WHILE  eax > 0
      add   edx, TYPE BitmapInfo
      dec   eax
    .ENDW
    push    edx
    INVOKE  SelectObject, imgDC, (BitmapInfo PTR [edx]).bHandler
    pop     edx
    mov     eax, (Tower PTR [ebx]).Pos.y
    sub     eax, (BitmapInfo PTR [edx]).bHeight
	INVOKE  TransparentBlt, 
            memDC, (Tower PTR [ebx]).Pos.x, eax,
            (BitmapInfo PTR [edx]).bWidth, (BitmapInfo PTR [edx]).bHeight,
            imgDC, 0, 0, 
            (BitmapInfo PTR [edx]).bWidth, (BitmapInfo PTR [edx]).bHeight,
            tcolor
DrawTowers0:
	add     ebx, TYPE Tower        
    pop     ecx
    loop    DrawTowers

PaintTowersExit:
    ret
PaintTowers ENDP

;---------------------------------------------------------
PaintMonsters PROC
;
; LoadImage of game. If more levels are designed, considering
; input the level number.
; Receives: handler
; Returns:  nothing
;---------------------------------------------------------
	mov     eax, OFFSET Game.pEnemyArray
    mov     esi, eax
    mov     ecx, Game.Enemy_Num
    cmp     ecx, 0
    je      PaintMonstersExit

DrawMonsters:
    push    ecx
    mov     edx, OFFSET monsterHandler
    mov     ebx, [esi]
    mov     eax, (Enemy PTR [ebx]).Enemy_Type
    .WHILE  eax > 0
      add   edx, TYPE MonsterBitmapInfo
      dec   eax
    .ENDW
    mov     eax, (Enemy PTR [ebx]).Current_Dir
    .WHILE  eax > 0
      add   edx, TYPE BitmapInfo
      add   edx, TYPE BitmapInfo
      dec   eax
    .ENDW
    mov     eax, (Enemy PTR [ebx]).Gesture
    .IF     eax > 0
      add   edx, TYPE BitmapInfo
    .ENDIF
    push    edx
    INVOKE  SelectObject, imgDC, (BitmapInfo PTR [edx]).bHandler
    pop     edx
	INVOKE	TransparentBlt, 
			memDC, (Enemy PTR [ebx]).Current_Pos.x, (Enemy PTR [ebx]).Current_Pos.y,
            (BitmapInfo PTR [edx]).bWidth, (BitmapInfo PTR [edx]).bHeight, 
			imgDC, 0, 0,
            (BitmapInfo PTR [edx]).bWidth, (BitmapInfo PTR [edx]).bHeight, 
			tcolor
    add     esi, TYPE DWORD
    pop     ecx
    loop    DrawMonsters
	
PaintMonstersExit:
    ret
PaintMonsters ENDP

;-----------------------------------------------------------------------
PaintProc PROC,
	hWnd:DWORD
;
; Painting  Function
; Receives: Windows handler
; Returns:  nothing
;-----------------------------------------------------------------------
	LOCAL 	hBitmap: DWORD
	LOCAL 	hOld: DWORD

    INVOKE 	CreateCompatibleDC, hDC
    mov 	memDC, eax
	INVOKE 	CreateCompatibleDC, hDC
    mov 	imgDC, eax

	INVOKE 	CreateCompatibleBitmap, hDC, window_w, window_h
	mov 	hBitmap, eax
    INVOKE 	SelectObject, memDC, hBitmap
    mov 	hOld, eax

	; ����ͼ
	INVOKE 	SelectObject, imgDC, mapHandler[0].bHandler
	INVOKE 	StretchBlt, 
			memDC, 0, 0, window_w, window_h, 
			imgDC, 0, 0, mapHandler[0].bWidth, mapHandler[0].bHeight, 
			SRCCOPY

	; ���յأ���
    INVOKE  PaintTowers

	; ����

	; ��С��
	INVOKE 	PaintMonsters

	; ���ӵ�

	
	INVOKE 	BitBlt, hDC, 0, 0, window_w, window_h, memDC, 0, 0, SRCCOPY 
    INVOKE 	DeleteDC, memDC
	INVOKE 	DeleteDC, imgDC
	INVOKE 	DeleteObject, hBitmap

	ret
PaintProc ENDP

;---------------------------------------------------
ErrorHandler PROC
; Display the appropriate system error message.
;---------------------------------------------------
.data

pErrorMsg   dd ?      ; ptr to error message
messageID   dd ?
ErrorTitle  db "Error", 0

.code

    INVOKE  GetLastError ; Returns message ID in EAX
    mov     messageID, eax

    ; Get the corresponding message string.
    INVOKE  FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
            FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
            ADDR pErrorMsg,NULL,NULL

    ; Display the error message.
    INVOKE  MessageBox,NULL, pErrorMsg, ADDR ErrorTitle,
            MB_ICONERROR+MB_OK

    ; Free the error message string.
    INVOKE  LocalFree, pErrorMsg
    ret
ErrorHandler ENDP

start:
    INVOKE  WinMain
    INVOKE  ExitProcess, NULL

END start
