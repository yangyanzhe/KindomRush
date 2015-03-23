TITLE main.asm      
.386      
.model flat,stdcall      
option casemap:none    

INCLUDELIB kernel32.lib
INCLUDELIB user32.lib
INCLUDELIB gdi32.lib
INCLUDELIB masm32.lib
INCLUDELIB comctl32.lib
INCLUDELIB winmm.lib
INCLUDELIB gdiplus.lib

INCLUDE masm32.inc
INCLUDE windows.inc
INCLUDE user32.inc
INCLUDE kernel32.inc
INCLUDE gdi32.inc
INCLUDE comctl32.inc
INCLUDE winmm.inc 
INCLUDE gdiplus.inc
        
INCLUDE kingdomRush.inc 
     
.code      
start:      
	INVOKE GetTickCount
	INVOKE nseed, eax

    INVOKE GetModuleHandle,0    ;��ȡӦ�ó���ģ����   
    mov hInstance,eax           ;����Ӧ�ó����� 

	INVOKE GetCommandLine
	mov CommandLine, eax
    
	INVOKE WinMain,hInstance,0,CommandLine,SW_SHOWDEFAULT      
    INVOKE ExitProcess,eax      ;�˳�����,������eax��ֵ   

;-------------------------------------------------------
WinMain PROC hInst:DWORD, 
			 hPrevInst:DWORD,
			 CmdLine:DWORD,
			 CmdShow:DWORD      
;
; Create the window and menu
; Receives: hInst(handler for current App), hPrevInst etc.
; Returns:  nothing
;--------------------------------------------------------
    LOCAL wndclass:WNDCLASSEX      
    LOCAL msg:MSG      
	LOCAL dwStyle:DWORD
	LOCAL scrWidth:DWORD
	LOCAL scrHeight:DWORD

	INVOKE GdiplusStartup, ADDR GdiPlusStartupToken, ADDR GdiInput, 0

	;��ʼ������
    mov wndclass.cbSize,sizeof WNDCLASSEX      
    mov wndclass.style,CS_HREDRAW or CS_VREDRAW or CS_BYTEALIGNWINDOW      
    mov wndclass.lpfnWndProc,OFFSET WndProc      
    mov wndclass.cbClsExtra,0      
    mov wndclass.cbWndExtra,0      
    mov eax,hInst      
    mov wndclass.hInstance,eax     

	INVOKE CreateSolidBrush,BgColor
	mov bgBrush, eax
    mov wndclass.hbrBackground, eax      
    mov wndclass.lpszMenuName,0      
    mov wndclass.lpszClassName,OFFSET ClassName      
    
	INVOKE LoadIcon, 0, IDI_APPLICATION
	mov wndclass.hIcon, eax
	mov wndclass.hIconSm, eax

    INVOKE LoadCursor,0,IDC_ARROW      
	mov wndclass.hCursor,eax            

	;������ˢ������
	INVOKE CreateSolidBrush,TextBgColor
	mov textBgBrush, eax
	
	INVOKE CreateFont, 80,
					0,
					0,
					0,
					FW_EXTRABOLD,
					FALSE,
					FALSE,
					FALSE,
					DEFAULT_CHARSET,
					OUT_TT_PRECIS,
					CLIP_DEFAULT_PRECIS,
					CLEARTYPE_QUALITY,
					DEFAULT_PITCH or FF_DONTCARE,
					OFFSET FontName
    mov titleFont, eax
	INVOKE CreateFont, 22,
                    0,
                    0,
                    0,
                    FW_EXTRABOLD,
                    FALSE,
                    FALSE,
                    FALSE,
                    DEFAULT_CHARSET,
                    OUT_TT_PRECIS,
                    CLIP_DEFAULT_PRECIS,
                    CLEARTYPE_QUALITY,
                    DEFAULT_PITCH or FF_DONTCARE,
                    OFFSET FontName
    mov textFont, eax

	;���㴰��λ�ã�ʹ����λ����Ļ����
	mov dwStyle, WS_OVERLAPPEDWINDOW
	mov eax, WS_SIZEBOX
	not eax
	and dwStyle, eax
	INVOKE GetSystemMetrics,SM_CXSCREEN
	mov scrWidth, eax
	INVOKE GetSystemMetrics,SM_CYSCREEN
	mov scrHeight, eax
	mov edx, 0
	mov ebx, 2
	mov eax, scrWidth
	sub eax, WndWidth
	div ebx
	mov WndOffX, eax
	mov eax, scrHeight
	sub eax, WndHeight
	div ebx
	mov WndOffY, eax

	;ע���û�����Ĵ�����
    INVOKE RegisterClassEx,ADDR wndclass        
	
	;��������
	INVOKE CreateWindowEx,WS_EX_OVERLAPPEDWINDOW, ADDR ClassName,      
                            ADDR WindowName,      
                            dwStyle,      
                            WndOffX,WndOffY,WndWidth,WndHeight,      
                            0,0,      
                            hInst,0           
	.IF eax == 0		
		call ErrorHandler
		jmp Exit_Program
	.ENDIF		  

	;���洰�ھ��
    mov   hWnd,eax                          

	;����ͼƬ
	INVOKE LoadBitmap, hInstance, 101
	mov BmpBackground, eax

	;��ʾ���ƴ���
	INVOKE ShowWindow,hWnd,SW_SHOWNORMAL   
    INVOKE UpdateWindow,hWnd

	;��ʼ����ĳ�����Ϣ����ѭ��     
MessageLoop:      
    INVOKE GetMessage,ADDR msg,0,0,0        ;��ȡ��Ϣ      
    cmp eax,0      
    je Exit_Program      
    INVOKE TranslateMessage,ADDR msg        ;ת��������Ϣ   
    INVOKE DispatchMessage,ADDR msg         ;�ַ���Ϣ   
    jmp MessageLoop  
    
	;�ر�ʱ��
	INVOKE KillTimer, hWnd, 1
	INVOKE GdiplusShutdown, GdiPlusStartupToken

Exit_Program:
	INVOKE ExitProcess, 0  
	ret
WinMain ENDP

;----------------------------------------------------------------------   
WndProc PROC hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD      
;
;��Ϣ������
;----------------------------------------------------------------------
    LOCAL hPopMenu      ;һ���˵����
	LOCAL ps  :PAINTSTRUCT
	LOCAL pt  :POINT

    .IF uMsg == WM_CREATE      
		INVOKE CreateMenu   
		mov hMenu, eax   
		.IF eax
			INVOKE CreatePopupMenu      ;����һ���˵�   
			mov hPopMenu, eax           ;����һ���˵����   
			INVOKE AppendMenu, hPopMenu, NULL, MENU_NEWGAMEM, addr MenuFileNewM   ;��Ӷ����˵�
			INVOKE AppendMenu, hPopMenu, NULL, MENU_NEWGAMEH, addr MenuFileNewH   ;��Ӷ����˵�
			INVOKE AppendMenu, hPopMenu, NULL, MENU_SAVEGAME, addr MenuFileSave   ;��Ӷ����˵�
			INVOKE AppendMenu, hPopMenu, NULL, MENU_PLAYMUSIC, addr MenuFilePlay   ;��Ӷ����˵�
			INVOKE AppendMenu, hPopMenu, NULL, MENU_STOPMUSIC, addr MenuFileStop   ;��Ӷ����˵�
			INVOKE AppendMenu, hMenu, MF_POPUP, hPopMenu, addr MenuFile                ;���һ���˵�   
			INVOKE CreatePopupMenu      ;����һ���˵�   
			mov hPopMenu, eax           ;����һ���˵����   
			INVOKE AppendMenu, hPopMenu, NULL, MENU_ABOUTAUTHOR, addr MenuAboutAuthor   ;��Ӷ����˵�
			INVOKE AppendMenu, hPopMenu, NULL, MENU_HELPINFO, addr MenuAboutHelpInfo   ;��Ӷ����˵�
			INVOKE AppendMenu, hMenu, MF_POPUP, hPopMenu, addr MenuAbout                ;���һ���˵�   
		.ENDIF   
		INVOKE SetMenu, hWin, hMenu     ;���ò˵�
		jmp WndProcExit
	.ELSEIF uMsg == WM_CLOSE
		;������Ϸ���ȶԻ���
		INVOKE PostQuitMessage,0
		jmp WndProcExit
	.ELSEIF uMsg == WM_PAINT
		INVOKE BeginPaint, hWin, ADDR ps
		mov hDC, eax
		INVOKE PaintProc, hWin
		INVOKE EndPaint, hWin, ADDR ps
		jmp WndProcExit
    .ELSE
        INVOKE DefWindowProc,hWin,uMsg,wParam,lParam    ;����Ĭ����Ϣ������   
        jmp WndProcExit      
    .ENDIF      
    ;xor eax,eax

WndProcExit:      
    ret      
WndProc endp      

;------------------------------------------------------------------
ErrorHandler PROC
;
;��������ӡ��������Ϣ
;------------------------------------------------------------------
.data
pErrorMsg  DWORD ?		; ptr to error message
messageID  DWORD ?
.code
	INVOKE GetLastError	; Returns message ID in EAX
	mov messageID,eax

	; Get the corresponding message string.
	INVOKE FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
	  FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
	  ADDR pErrorMsg,NULL,NULL

	; Display the error message.
	INVOKE MessageBox, NULL, pErrorMsg, ADDR ErrorTitle, MB_ICONERROR+MB_OK

	; Free the error message string.
	INVOKE LocalFree, pErrorMsg
	ret
ErrorHandler ENDP

;-----------------------------------------------------------------------
PaintProc PROC hWin:DWORD
;
; Painting Function
;-----------------------------------------------------------------------

	LOCAL hOld: DWORD
	LOCAL xIndex: DWORD
	LOCAL yIndex: DWORD
	LOCAL textRect: RECT
	LOCAL movedis: DWORD
	LOCAL scale: DWORD  ;1~100

	mov movedis, 0

    INVOKE CreateCompatibleDC, hDC
    mov memDC, eax
	INVOKE CreateCompatibleDC, hDC
    mov imgDC, eax
	INVOKE CreateCompatibleBitmap, hDC, WndWidth, WndHeight
	mov hBitmap, eax
    INVOKE SelectObject, memDC, hBitmap
    mov hOld, eax
	INVOKE FillRect, memDC, ADDR rect, bgBrush
	
	;������
	INVOKE SelectObject, imgDC, BmpBackground
	INVOKE StretchBlt, memDC, ClientOffX, ClientOffY, ClientWidth, ClientHeight, imgDC,0, 0, BgBmpWidth, BgBmpHeight, SRCCOPY
	
	INVOKE BitBlt, hDC, 0, 0, WndWidth, WndHeight, memDC, 0, 0, SRCCOPY 
    INVOKE SelectObject,hDC,hOld
    INVOKE DeleteDC,memDC
	INVOKE DeleteDC,imgDC
	INVOKE DeleteObject, hBitmap
    ret
PaintProc ENDP

end start