TITLE Windows Application

.386      
.model flat,stdcall      
option casemap:none

INCLUDE     windows.inc
INCLUDE     gdi32.inc
INCLUDE     user32.inc
INCLUDE		msimg32.inc
INCLUDE     kernel32.inc
INCLUDE		winmm.inc

INCLUDELIB  gdi32.lib
INCLUDELIB  kernel32.lib
INCLUDELIB  user32.lib
INCLUDELIB  msimg32.lib
INCLUDELIB  winmm.lib

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

MouseMoveProc_Prepared PROTO,
	hWnd: DWORD,
    cursorPosition: Coord

MouseMoveProc_Started PROTO,
	hWnd: DWORD,
	cursorPosition: Coord

LMouseProc_Prepared PROTO,
	hWnd: DWORD,
	cursorPosition: Coord

LMouseProc_Started PROTO,
	hWnd: DWORD,
	cursorPosition: Coord
	
PaintProc PROTO,
	hWnd: DWORD

PlayMp3File PROTO,
	hWin:DWORD,
	NameOfFile:DWORD

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
    LOCAL   cursorPosition: Coord
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

	  ;��������
	  .IF PlayFlag == 0
		mov     PlayFlag,1  
		INVOKE  PlayMp3File, hWnd, ADDR MusicFileName
	  .ENDIF
	
	  jmp       WinProcExit
    .ELSEIF eax == WM_MOUSEMOVE     ; ����ƶ��¼�
      mov  	    ebx, lParam
      movzx     edx, bx
      mov     	cursorPosition.x, edx
	  shr  	    ebx, 16
      movzx     edx, bx
	  mov     	cursorPosition.y, edx
      .IF wParam == MK_LBUTTON
        .IF Game.State == 0
          INVOKE 	MouseMoveProc_Prepared, hWnd, cursorPosition
        .ELSE
		  INVOKE 	MouseMoveProc_Started, hWnd, cursorPosition
        .ENDIF
      .ENDIF
      jmp       WinProcExit
    .ELSEIF eax == WM_LBUTTONDOWN   ; ������¼�
      mov  	    ebx, lParam
      movzx     edx, bx
      mov     	cursorPosition.x, edx
	  shr  	    ebx, 16
      movzx     edx, bx
	  mov     	cursorPosition.y, edx
	  .IF wParam == MK_LBUTTON
        .IF Game.State == 0
          INVOKE 	LMouseProc_Prepared, hWnd, cursorPosition
        .ELSE
		  INVOKE 	LMouseProc_Started, hWnd, cursorPosition
        .ENDIF
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
LoadTypeImages PROC,
    hInst: DWORD,
    typeNum: DWORD,
    typeHandler: DWORD,
    typeID: DWORD
;
; As the load procedure are repeatable, remove the repeatable code here
;---------------------------------------------------------
    LOCAL   bm: BITMAP

    mov     ecx, typeNum
    mov     ebx, typeHandler
    mov     edx, typeID
 LoadImages:
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
    loop    LoadImages

    ret
LoadTypeImages ENDP

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

    ; ���뿪ʼͼƬ�Ͱ�ť
    INVOKE  LoadTypeImages, hInst, instructionNum, OFFSET instructionHandler, IDB_INSTRUCTION
    INVOKE  LoadTypeImages, hInst, buttonNum, OFFSET buttonHandler, IDB_BUTTON

    ; �����ͼͼƬ
    INVOKE  LoadTypeImages, hInst, mapNum, OFFSET mapHandler, IDB_MAP

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
    INVOKE  LoadTypeImages, hInst, towerNum, OFFSET towerHandler, IDB_TOWER

    ; �������ı�־��ͼƬ
    INVOKE  LoadTypeImages, hInst, signNum, OFFSET signHandler, IDB_SIGN
	
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

	; �����ӵ�
    INVOKE  LoadTypeImages, hInst, bulletNum, OFFSET bulletHandler, IDB_BULLET

	; ���붯����ͼƬ
    INVOKE  LoadTypeImages, hInst, animateNum, OFFSET animateHandler, IDB_ANIMATE

	ret
InitImages ENDP

;-----------------------------------------------------------------------
InitMapInfo PROC
;-----------------------------------------------------------------------
    ; ��ʼ��������
    mov     edx, OFFSET blankSet
    mov     eax, Level
    .WHILE eax > 0
      add   edx, TYPE PositionSet
      dec   eax
    .ENDW
    mov     ecx, (PositionSet PTR [edx]).number
    mov     Game.Tower_Num, ecx
    mov     ebx, edx
    add     ebx, TYPE DWORD
    mov     edx, OFFSET Game.TowerArray
InitTower:  
    mov     (Tower PTR [edx]).Tower_Type, 0     ;���ĳ�ʼ����Ϊ0���յأ�
    mov     (Tower PTR [edx]).Range, 80         ;���Ĺ�����Χ
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
    INVOKE UpdateTowers
    INVOKE UpdateBullets
    INVOKE UpdateAnimates
    INVOKE InvalidateRect, hWnd, NULL, FALSE
    ret
TimerProc ENDP

;-----------------------------------------------------------------------
MouseMoveProc_Prepared PROC,
	hWnd: DWORD,
	cursorPosition: Coord
;-----------------------------------------------------------------------

    ret
MouseMoveProc_Prepared ENDP

;-----------------------------------------------------------------------
MouseMoveProc_Started PROC,
	hWnd: DWORD,
	cursorPosition: Coord
;-----------------------------------------------------------------------

    ret
MouseMoveProc_Started ENDP

;-----------------------------------------------------------------------
LMouseProc_Prepared PROC,
	hWnd: DWORD,
	cursorPosition: Coord
;-----------------------------------------------------------------------

    ret
LMouseProc_Prepared ENDP

;-----------------------------------------------------------------------
LMouseProc_Started PROC,
	hWnd: DWORD,
	cursorPosition: Coord
;-----------------------------------------------------------------------
    LOCAL   oriX: DWORD         ; ����־��ԭ��
    LOCAL   oriY: DWORD         ; ����־��ԭ��
    ; INVOKE MessageBox, hWnd, NULL, NULL, MB_OK

    mov     eax, Game.IsClicked
    .IF eax == 1                ; Circle����
      mov   ebx, OFFSET Game.TowerArray
      mov   eax, Game.ClickedIndex
      .WHILE eax > 0
        add ebx, TYPE Tower
        dec eax
      .ENDW

      ; ����ԭ��λ��
      mov   eax, (Tower PTR [ebx]).Pos.x
      mov   oriX, eax
      mov   eax, (Tower PTR [ebx]).Pos.y
      mov   oriY, eax
      mov   edx, OFFSET towerHandler
      mov   eax, (Tower PTR [ebx]).Tower_Type
      .WHILE eax > 0
        add edx, TYPE BitmapInfo
        dec eax
      .ENDW
      mov   eax, (BitmapInfo PTR [edx]).bWidth
      shr   eax, 1
      add   oriX, eax
      mov   eax, (BitmapInfo PTR [edx]).bHeight
      shr   eax, 1
      sub   oriY, eax
      mov   eax, signHandler[0].bWidth
      shr   eax, 1
      sub   oriX, eax
	  mov   eax, signHandler[0].bHeight
      shr   eax, 1
      sub   oriY, eax

      mov   eax, (Tower PTR [ebx]).Tower_Type
      .IF eax == 0                  ; Blank Circle����
        mov ecx, blankSignNum
        dec ecx
        mov edx, OFFSET signHandler
        add edx, TYPE BitmapInfo
        mov esi, OFFSET signPosition
        add esi, TYPE Coord
        mov edi, 1

CheckSignClicked0:
        mov  eax, (Coord PTR [esi]).x
        add  eax, oriX
        cmp  cursorPosition.x, eax
        jb   CheckSignClicked1
        add  eax, (BitmapInfo PTR [edx]).bWidth
        cmp  cursorPosition.x, eax
        ja   CheckSignClicked1
        mov  eax, (Coord PTR [esi]).y
        add  eax, oriY
        cmp  cursorPosition.y, eax
        jb   CheckSignClicked1
        add  eax, (BitmapInfo PTR [edx]).bHeight
        cmp  cursorPosition.y, eax
        ja   CheckSignClicked1

        mov  (Tower PTR [ebx]).Tower_Type, edi
        jmp  CheckSignClicked2
CheckSignClicked1:
        add  edx, TYPE BitmapInfo
        add  esi, TYPE Coord
        inc  edi
        loop CheckSignClicked0

CheckSignClicked2:
        mov  Game.IsClicked, 0
        jmp  LMouseProcExit

      .ELSE                         ; Tower Circle����
        mov  ecx, towerSignNum
        dec  ecx
        mov  edx, OFFSET signHandler
        mov  eax, blankSignNum
        .WHILE eax > 0
          add edx, TYPE BitmapInfo
          dec eax
        .ENDW
        add  edx, TYPE BitmapInfo
        mov  esi, OFFSET signPosition
        add  esi, TYPE Coord

        mov  eax, (Coord PTR [esi]).x
        add  eax, oriX
        cmp  cursorPosition.x, eax
        jb   CheckSignClicked3
        add  eax, (BitmapInfo PTR [edx]).bWidth
        cmp  cursorPosition.x, eax
        ja   CheckSignClicked3
        mov  eax, (Coord PTR [esi]).y
        add  eax, oriY
        cmp  cursorPosition.y, eax
        jb   CheckSignClicked3
        add  eax, (BitmapInfo PTR [edx]).bHeight
        cmp  cursorPosition.y, eax
        ja   CheckSignClicked3

        add  (Tower PTR [ebx]).Tower_Type, 4
        jmp  CheckSignClicked4

CheckSignClicked3:
        add  edx, TYPE BitmapInfo
        add  esi, TYPE Coord

        mov  eax, (Coord PTR [esi]).x
        add  eax, oriX
        cmp  cursorPosition.x, eax
        jb   CheckSignClicked4
        add  eax, (BitmapInfo PTR [edx]).bWidth
        cmp  cursorPosition.x, eax
        ja   CheckSignClicked4
        mov  eax, (Coord PTR [esi]).y
        add  eax, oriY
        cmp  cursorPosition.y, eax
        jb   CheckSignClicked4
        add  eax, (BitmapInfo PTR [edx]).bHeight
        cmp  cursorPosition.y, eax
        ja   CheckSignClicked4

        mov  (Tower PTR [ebx]).Tower_Type, 0
CheckSignClicked4:
        mov  Game.IsClicked, 0
        jmp  LMouseProcExit
      .ENDIF
    .ELSE
      mov   ecx, Game.Tower_Num
      mov   ebx, OFFSET Game.TowerArray
      mov   esi, 0
CheckClicked:
      mov   edx, OFFSET towerHandler
      mov   eax, (Tower PTR [ebx]).Tower_Type
      .WHILE eax > 0
        add edx, TYPE BitmapInfo
        dec eax
      .ENDW
      ; �ж��Ƿ����ڿյ�/���ķ�Χ��
      mov   eax, (Tower PTR [ebx]).Pos.x
      cmp   cursorPosition.x, eax
      jb    CheckClicked0
      add   eax, (BitmapInfo PTR [edx]).bWidth
      cmp   cursorPosition.x, eax
      ja    CheckClicked0
      mov   eax, (Tower PTR [ebx]).Pos.y
      cmp   cursorPosition.y, eax
      ja    CheckClicked0
      sub   eax, (BitmapInfo PTR [edx]).bHeight
      cmp   cursorPosition.y, eax
      jb    CheckClicked0

      mov   Game.IsClicked, 1
      mov   Game.ClickedIndex, esi
      jmp   LMouseProcExit
CheckClicked0:
      add   ebx, TYPE Tower
      add   esi, 1
      loop  CheckClicked
    .ENDIF

LMouseProcExit:
    INVOKE InvalidateRect, hWnd, NULL, FALSE
    ret
LMouseProc_Started ENDP

;-----------------------------------------------------------------------
PaintTowers PROC
;-----------------------------------------------------------------------
    ; �������пյ�
	INVOKE  SelectObject, imgDC, towerHandler[0].bHandler
    mov     ecx, Game.Tower_Num
    mov     ebx, OFFSET Game.TowerArray
DrawBlank:
	push    ecx
    mov     eax, (Tower PTR [ebx]).Pos.y
    sub     eax, towerHandler[0].bHeight
	INVOKE  TransparentBlt, 
            memDC, (Tower PTR [ebx]).Pos.x, eax,
            towerHandler[0].bWidth, towerHandler[0].bHeight,
            imgDC, 0, 0, 
            towerHandler[0].bWidth, towerHandler[0].bHeight,
            tcolor
	add     ebx, TYPE Tower
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

;---------------------------------------------------------
PaintSigns PROC uses eax esi ebx ecx
;	
;	Functions: ����ѡ�����ı�ʶ
;	Receives:  
;---------------------------------------------------------
	LOCAL   oriX: DWORD         ; ����־��ԭ��
    LOCAL   oriY: DWORD         ; ����־��ԭ��
    LOCAL   x: DWORD
    LOCAL   y: DWORD

    cmp     Game.IsClicked, 0
    je      PaintSignsExit

    mov     ebx, OFFSET Game.TowerArray
    mov     eax, Game.ClickedIndex
    .WHILE  eax > 0
      add   ebx, TYPE Tower
      dec   eax
    .ENDW

    ; ����ԭ��λ��
    mov     eax, (Tower PTR [ebx]).Pos.x
    mov     oriX, eax
    mov     eax, (Tower PTR [ebx]).Pos.y
    mov     oriY, eax
    mov     edx, OFFSET towerHandler
    mov     eax, (Tower PTR [ebx]).Tower_Type
    .WHILE  eax > 0
      add   edx, TYPE BitmapInfo
      dec   eax
    .ENDW
    mov     eax, (BitmapInfo PTR [edx]).bWidth
    shr     eax, 1
    add     oriX, eax
    mov     eax, (BitmapInfo PTR [edx]).bHeight
    shr     eax, 1
    sub     oriY, eax
    mov     eax, signHandler[0].bWidth
    shr     eax, 1
    sub     oriX, eax
	mov     eax, signHandler[0].bHeight
    shr     eax, 1
    sub     oriY, eax

	mov		eax, (Tower PTR [ebx]).Tower_Type
	.IF eax == 0
	  mov	ecx, blankSignNum
      mov   ebx, OFFSET signHandler
	  mov   edx, OFFSET signPosition
DrawBlankSigns:
      push  ecx
      push  edx
      mov   eax, oriX
      add   eax, (Coord PTR [edx]).x
      mov   x, eax
      mov   eax, oriY
      add   eax, (Coord PTR [edx]).y
      mov   y, eax
    INVOKE  SelectObject, imgDC, (BitmapInfo PTR [ebx]).bHandler
    INVOKE	TransparentBlt, 
			memDC, x, y,
            (BitmapInfo PTR [ebx]).bWidth, (BitmapInfo PTR [ebx]).bHeight, 
			imgDC, 0, 0,
            (BitmapInfo PTR [ebx]).bWidth, (BitmapInfo PTR [ebx]).bHeight, 
			tcolor
      pop   edx
      add   ebx, TYPE BitmapInfo
      add   edx, TYPE Coord
      pop   ecx
      loop  DrawBlankSigns
	.ELSE
	  mov	ecx, towerSignNum
      mov   ebx, OFFSET signHandler
      mov   eax, blankSignNum
      .WHILE eax > 0
        add ebx, TYPE signHandler
        dec eax
      .ENDW
	  mov   edx, OFFSET signPosition
DrawTowerSigns:
      push  ecx
      push  edx
      mov   eax, oriX
      add   eax, (Coord PTR [edx]).x
      mov   x, eax
      mov   eax, oriY
      add   eax, (Coord PTR [edx]).y
      mov   y, eax
    INVOKE  SelectObject, imgDC, (BitmapInfo PTR [ebx]).bHandler
    INVOKE	TransparentBlt, 
			memDC, x, y,
            (BitmapInfo PTR [ebx]).bWidth, (BitmapInfo PTR [ebx]).bHeight, 
			imgDC, 0, 0,
            (BitmapInfo PTR [ebx]).bWidth, (BitmapInfo PTR [ebx]).bHeight, 
			tcolor
      pop   edx
      add   ebx, TYPE BitmapInfo
      add   edx, TYPE Coord
      pop   ecx
      loop  DrawTowerSigns
	.ENDIF

PaintSignsExit:
    ret
PaintSigns ENDP

;---------------------------------------------------
PaintBullets PROC uses eax ebx ecx edx
;
;---------------------------------------------------
	LOCAL   count:DWORD

	mov		ecx, Game.Bullet_Num
	cmp		ecx, 0
	je		DrawBulletExit

	mov     edx, OFFSET Game.BulletArray
	
DrawBullet:
	; get the image
	push	edx
    mov		count, ecx
    mov     ebx, OFFSET bulletHandler
	mov		eax, (Bullet PTR [edx]).Bullet_Type
	cmp		eax, 0			; �յ�
	je		L2

	cmp		eax, 3			; ħ����
	jne		L1

	mov		eax, 1			; ħ����
	mov		ecx, type BitmapInfo
	mul		ecx
	add		ebx, eax

L1:
	INVOKE  SelectObject, imgDC, (BitmapInfo PTR [ebx]).bHandler
	pop		edx
    push    edx
    INVOKE	TransparentBlt, 
			memDC, (Bullet PTR [edx]).Pos.x, (Bullet PTR [edx]).Pos.y,
            (BitmapInfo PTR [ebx]).bWidth, (BitmapInfo PTR [ebx]).bHeight, 
			imgDC, 0, 0,
            (BitmapInfo PTR [ebx]).bWidth, (BitmapInfo PTR [ebx]).bHeight, 
			tcolor
    pop     edx
	add		edx, TYPE Bullet
L2:
	mov		ecx, count
	loop	DrawBullet

DrawBulletExit:
	ret
PaintBullets ENDP

;--------------------------------------------------
UpdateWindmill PROC uses eax ebx
;
;--------------------------------------------------
	mov		ebx, OFFSET windmill

	mov		eax, (Animate PTR [ebx]).Gesture
	inc		eax
	.IF		eax > 7
		mov	 eax, 0
	.ENDIF
	mov		(Animate PTR [ebx]).Gesture, eax

	ret
UpdateWindmill ENDP

;---------------------------------------------------
DrawSingleAnimate PROC uses eax ecx edx 
; 
;	ebx-offset animate
;---------------------------------------------------
	Local	animateT:DWORD
	Local	gesture:DWORD

	mov		eax, 0

	; get the image
    mov     edx, OFFSET animateHandler
	push	edx
	
	mov		eax, (Animate PTR [ebx]).Animate_Type
	mov		animateT, eax
	mov		ecx, 8
	mul		ecx
	add		eax, (Animate PTR [ebx]).Gesture
	mov		ecx, (Animate PTR [ebx]).Gesture
	mov		gesture, ecx

	pushad
	.IF	gesture == 1
		.IF		animateT == 1			; ����ը������
			INVOKE	PlaySound, OFFSET BombFileName, 0, SND_ASYNC
		.ELSEIF	animateT == 2
			INVOKE  PlaySound, OFFSET AhFileName, 0, SND_ASYNC
		.ENDIF
	.ENDIF
	popad

	mov		ecx, type BitmapInfo
	mul		ecx

	pop		edx
	add		edx, eax

	push edx
	INVOKE  SelectObject, imgDC, (BitmapInfo PTR [edx]).bHandler
	pop edx
	INVOKE	TransparentBlt, 
			memDC, (Animate PTR [ebx]).Pos.x, (Animate PTR [ebx]).Pos.y,
			(BitmapInfo PTR [edx]).bWidth, (BitmapInfo PTR [edx]).bHeight, 
			imgDC, 0, 0,
            (BitmapInfo PTR [edx]).bWidth, (BitmapInfo PTR [edx]).bHeight, 
			tcolor

	ret
DrawSingleAnimate ENDP

;---------------------------------------------------
PaintAnimates PROC uses eax ebx ecx edx 
;
;---------------------------------------------------
	mov		eax, 0
	mov		ebx, 0

	mov		ecx, Game.Animate_Num
	cmp		ecx, 0
	je		PaintAnimatesExit

	; get the struct-Animate
	mov     ebx, OFFSET Game.AnimateArray
L1:
	push	ecx
	INVOKE	DrawSingleAnimate
	add		ebx, TYPE Animate
	pop		ecx
	loop	L1

PaintAnimatesExit:
	ret
PaintAnimates ENDP

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

    ; �ж��Ƿ��ڵȴ�ҳ��
    cmp     Game.State, 0
    jne     AlreadyStarted

    ; ��Ϸ��δ��ʼ
    ; Startҳ��
    mov     eax, Game.ClickedIndex
    mov     ebx, OFFSET instructionHandler
    .WHILE eax > 0
      add   ebx, TYPE BitmapInfo
      dec   eax
    .ENDW
    INVOKE 	SelectObject, imgDC, (BitmapInfo PTR [ebx]).bHandler
	INVOKE 	StretchBlt, 
			memDC, 0, 0, window_w, window_h, 
			imgDC, 0, 0, (BitmapInfo PTR [ebx]).bWidth, (BitmapInfo PTR [ebx]).bHeight, 
			SRCCOPY

    jmp     PaintProcExit

    ; ��Ϸ�Ѿ���ʼ
AlreadyStarted:
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
	INVOKE  PaintBullets

	; ������
	mov     ebx, OFFSET windmill
	INVOKE	DrawSingleAnimate
	INVOKE  UpdateWindmill
	INVOKE	PaintAnimates

	; ��������ʾԲȦ
	INVOKE	PaintSigns

PaintProcExit:
	INVOKE 	BitBlt, hDC, 0, 0, window_w, window_h, memDC, 0, 0, SRCCOPY
    INVOKE 	DeleteObject, hBitmap
    INVOKE 	DeleteDC, memDC
	INVOKE 	DeleteDC, imgDC
    INVOKE 	ReleaseDC, hWnd, hDC

	ret
PaintProc ENDP

;----------------------------------------------------------------------
PlayMp3File PROC hWin:DWORD, NameOfFile:DWORD
;
; �������ֺ���
;----------------------------------------------------------------------
	LOCAL   mciOpenParms:MCI_OPEN_PARMS, mciPlayParms:MCI_PLAY_PARMS

	mov     eax, hWin        
	mov     mciPlayParms.dwCallback,eax
	mov     eax, OFFSET Mp3Device
	mov     mciOpenParms.lpstrDeviceType, eax
	mov     eax, NameOfFile
	mov     mciOpenParms.lpstrElementName, eax
	INVOKE  mciSendCommand, 0, MCI_OPEN,MCI_OPEN_TYPE or MCI_OPEN_ELEMENT, ADDR mciOpenParms
	mov     eax, mciOpenParms.wDeviceID
	mov     Mp3DeviceID, eax
	INVOKE  mciSendCommand, Mp3DeviceID, MCI_PLAY, MCI_NOTIFY, ADDR mciPlayParms
	
	ret
PlayMp3File ENDP

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
