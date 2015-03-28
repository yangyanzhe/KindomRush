TITLE core.asm      
    .386         
    option casemap:none 

INCLUDE struct.inc
INCLUDE Irvine32.inc
INCLUDE core.inc
.data

MAP_WIDTH   =   700
MAP_HEIGHT  =   600
MAP_SIZE    =   MAP_WIDTH * MAP_HEIGHT
UP          =   0
DOWN        =   1
LEFT        =   2
RIGHT       =   3
MapFileName     db "data/map.data",0
Game            GameInfo <>
Game_Map        db MAP_SIZE dup(?)
fileHandle      HANDLE ?

.code
;==========================     Game      =============================
;----------------------------------------------------------------------     
LoadGameInfo PROC USES ecx
;
;������Ϸ��Ϣ
;----------------------------------------------------------------------
    INVOKE  LoadGameMap
    mov     Game.Round_Num, 2
    mov     Game.Round, 0
    mov     Game.State, 0
    mov     Game.Player_Life, 20
    mov     Game.Player_Money, 220
    mov     Game.Start_Pos.x, 320
    mov     Game.Start_Pos.y, 0
    mov     Game.End_Pos.x, 699
    mov     Game.End_Pos.y, 400
    mov     Game.Tower_Num, 7
    mov     ecx, 7
    mov     ebx, OFFSET Game.TowerArray
    mov     esi, 0

;��ʼ��������
Initialize_Tower_Loop:  
    mov     (Tower PTR [ebx]).Tower_Type, 0     ;���ĳ�ʼ����Ϊ0���յأ�
    mov     (Tower PTR [ebx]).Range, 100
    add     ebx, TYPE Tower
    loop    Initialize_Tower_Loop

    ret
LoadGameInfo ENDP

;----------------------------------------------------------------------   
StartGame PROC
;
;��ʼ��Ϸ
;----------------------------------------------------------------------
    mov     Game.State, 1
    ret
StartGame ENDP

;----------------------------------------------------------------------     
ResetGame PROC      
;
;������Ϸ
;----------------------------------------------------------------------
    ret
ResetGame ENDP

;----------------------------------------------------------------------     
QuitGame PROC      
;
;�뿪��Ϸ
;----------------------------------------------------------------------
    ret
QuitGame ENDP

;----------------------------------------------------------------------     
PauseGame PROC      
;
;��ͣ��Ϸ
;----------------------------------------------------------------------
    mov     Game.State, 2
    ret
PauseGame ENDP

;==========================     Tower     =============================
;----------------------------------------------------------------------   
CreateTower PROC USES esi ebx ecx,
    _Type:DWORD, _TowerNumber:DWORD
;
;������
;----------------------------------------------------------------------
    mov     ebx, OFFSET Game.TowerArray
    mov     esi, _TowerNumber
    sub     esi, 1
    mov     ecx, esi
    cmp     ecx, 0
    je      create_tower
Loop_CreateTower:
    add     ebx, TYPE Tower
    loop    Loop_CreateTower

create_tower:
    mov     esi, _Type
    mov     (Tower PTR [ebx]).Tower_Type, esi
    mov     (Tower PTR [ebx]).Degree, 1
    ret
CreateTower ENDP

;----------------------------------------------------------------------   
SellTower PROC USES eax esi,
    pTower: PTR Tower
;����
;require: �ض�����ָ��
;----------------------------------------------------------------------
    mov     esi, pTower
    mov     eax, (Tower PTR [esi]).Sell_Cost
    sub     Game.Player_Money, eax
    ret
SellTower ENDP

;----------------------------------------------------------------------   
UpdateTower PROC USES esi,
    pTower: PTR Tower
;������
;require: �ض�����ָ��
;----------------------------------------------------------------------
    mov     esi, pTower
    inc     (Tower PTR [esi]).Degree
    ret
UpdateTower ENDP

;----------------------------------------------------------------------   
SearchAndAttack PROC USES eax ebx ecx esi edi edx,
    pTower: PTR Tower
;
;����������Ŀ��
; require: �ض�����ָ��
;----------------------------------------------------------------------
    mov     esi, pTower
    mov     ecx, Game.Enemy_Num

    mov     edi, OFFSET Game.pEnemyArray
Search_Enemy_Loop:
    mov     ebx, [edi]
    mov     edx, (Enemy PTR [ebx]).Current_Pos.x
    mov     eax, (Tower PTR [esi]).Pos.x
    .IF     eax < edx
        xchg  eax, edx
    .ENDIF
    sub     eax, edx
    mov     edx, (Tower PTR [esi]).Range
    .IF     eax > edx
        jmp   SearchEnemy_Continue
    .ENDIF

    mov     edx, (Enemy PTR [ebx]).Current_Pos.y
    mov     eax, (Tower PTR [esi]).Pos.y
    .IF     eax < edx
        xchg  eax, edx
    .ENDIF
    sub     eax, edx
    mov     edx, (Tower PTR [esi]).Range
    .IF     eax > edx
        jmp   SearchEnemy_Continue
    .ENDIF

    ; �ҵ���һ�����Խ��й����Ĺ���������˳�����
    mov     edx, (Tower PTR [esi]).Attack
    mov     eax, (Enemy PTR [ebx]).Current_Life
    .IF     eax < edx
        mov   (Enemy PTR [ebx]).Current_Life, 0
    .ELSE
        sub   (Enemy PTR [ebx]).Current_Life, edx
    .ENDIF
    jmp     SearchEnemy_Exit
SearchEnemy_Continue:
    mov     edi, TYPE DWORD
    loop    Search_Enemy_Loop
SearchEnemy_Exit:
    ret
SearchAndAttack ENDP

;==========================     Enemy     =============================
;----------------------------------------------------------------------   
ActivateEnemy PROC USES esi ecx ebx,
    pEnemy: PTR Enemy
;ʹ��������ͼ����ʼ�ƶ���
;require: �ض������ָ��
;----------------------------------------------------------------------
    ;���ض�����ָ����뵱ǰ��Ϸ����ָ�������
    mov     esi, OFFSET Game.pEnemyArray
    mov     ecx, Game.Enemy_Num
    dec     ecx
    mov     ebx, pEnemy
    mov     [esi + ecx * TYPE DWORD], ebx
    inc     Game.Enemy_Num

    ;��ʼ������ĳ�ʼ����ǰ���յ�λ��
    mov     esi, pEnemy
    mov     ecx, Game.Start_Pos.x
    mov     (Enemy PTR [esi]).Start_Pos.x, ecx
    mov     (Enemy PTR [esi]).Current_Pos.x, ecx
    mov     ecx, Game.Start_Pos.y
    mov     (Enemy PTR [esi]).Start_Pos.y, ecx
    mov     (Enemy PTR [esi]).Current_Pos.y, ecx
    mov     ecx, Game.End_Pos.x
    mov     (Enemy PTR [esi]).End_Pos.x, ecx
    mov     ecx, Game.End_Pos.y
    mov     (Enemy PTR [esi]).End_Pos.y, ecx
    ;��ʼ�����ﳯ������
    mov     ecx, DOWN
    mov     (Enemy PTR [esi]).Current_Dirt, ecx
    ret
ActivateEnemy ENDP

;----------------------------------------------------------------------   
EnemyMove PROC USES edi,
;�ƶ�����
;require: �ض������ָ��
;----------------------------------------------------------------------
    ret
EnemyMove ENDP

;----------------------------------------------------------------------   
EnemyCheckDie PROC USES eax ebx ecx edi edx,
;
;������й�������������ɾȥ�����Ĺ���
;----------------------------------------------------------------------
    mov     ebx, OFFSET Game.pEnemyArray
    mov     ecx, Game.Enemy_Num
    cmp     ecx, 0
    je      EnemyCheckDie_Exit
    mov     eax, 0
CheckAllDie:
    mov     edi, [ebx]
    mov     edx, (Enemy PTR [edi]).Current_Life
    .IF edx == 0
        INVOKE EnemyDie, eax
    .ENDIF
    add     ebx, TYPE DWORD
    loop    CheckAllDie
EnemyCheckDie_Exit:
    ret
EnemyCheckDie ENDP

;----------------------------------------------------------------------   
EnemyDie PROC USES ebx edi ecx eax,
    _EnemyNumber: DWORD
;
;����������������Ӷ�����ɾ��
;require:�����ڹ�������еı�ţ���0��ʼ��
;----------------------------------------------------------------------
    mov     ebx, OFFSET Game.pEnemyArray
    mov     edi, _EnemyNumber
    shl     edi, 2
    add     ebx, edi
    mov     edi, Game.Enemy_Num
    mov     ecx, _EnemyNumber
    sub     edi, ecx
    mov     ecx, edi
    sub     ecx, 1
EnemyQueueMoveForward:
    mov     edi, [ebx+4]
    mov     [ebx], edi
    add     ebx, 4
    loop    EnemyQueueMoveForward
    ret
EnemyDie ENDP

;=========================== player ==================================
;----------------------------------------------------------------------     
AddMoney PROC USES eax,
    money:DWORD
;
;������ҽ�Ǯ
;require: money
;----------------------------------------------------------------------
    mov     eax, money
    add     Game.Player_Money, eax
    ret
AddMoney ENDP

;----------------------------------------------------------------------     
SubMoney PROC USES eax,
    money:DWORD
;
;������ҽ�Ǯ
;require: money
;----------------------------------------------------------------------
    mov     eax, money
    cmp     Game.Player_Money, eax
    ja      subFully
    mov     Game.Player_Money, 0
    jmp     ret_submoney
subFully:
    sub     Game.Player_Money, eax
    jmp     ret_submoney
ret_submoney:
    ret
SubMoney ENDP

;=========================== private ==================================
;----------------------------------------------------------------------     
LoadGameMap PROC USES eax ecx edx
;������Ϸ��ͼ
;----------------------------------------------------------------------
    mov     edx, OFFSET MapFileName
    call    OpenInputFile
    mov     fileHandle, eax

    mov     edx, OFFSET Game_Map
    mov     ecx, MAP_SIZE
    call    ReadFromFile
    mov     Game_Map[eax], 0
    call    WriteDec
    call    Crlf
    ret
LoadGameMap ENDP

END