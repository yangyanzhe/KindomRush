TITLE core.asm      
    .386         
    option casemap:none 

INCLUDE struct.inc
INCLUDE Irvine32.inc
INCLUDE core.inc
INCLUDE data.inc
.data

MAP_WIDTH   =   700
MAP_HEIGHT  =   600
MAP_SIZE    =   MAP_WIDTH * MAP_HEIGHT
UP          =   0
LEFT        =   1
RIGHT       =   2
DOWN        =   3
MapFileName     db "data/map.data",0
Game            GameInfo <>
Game_Map        db MAP_SIZE dup(?)
fileHandle      HANDLE ?
DirectionX      dd 0, 1, 1, 0
DirectionY      dd 1, 0, 0, 1

.code
;==========================     Game      =============================
;----------------------------------------------------------------------     
LoadGameInfo PROC USES ecx ebx esi edi eax edx,
;
;������Ϸ��Ϣ
;----------------------------------------------------------------------
    INVOKE  LoadGameMap
    mov     Game.State, 0
    mov     Game.Player_Life, 20
    mov     Game.Player_Money, 220
    mov     Game.Start_Pos.x, 320
    mov     Game.Start_Pos.y, 0
    mov     Game.End_Pos.x, 699
    mov     Game.End_Pos.y, 400

;��ʼ��������
    mov     Game.Tower_Num, 2
    mov     ecx, 2
    mov     ebx, OFFSET Game.TowerArray
    mov     esi, 0
    mov     eax, OFFSET TOWERPOSITION
Initialize_Tower_Loop:  
    mov     (Tower PTR [ebx]).Tower_Type, 0     ;���ĳ�ʼ����Ϊ0���յأ�
    mov     (Tower PTR [ebx]).Range, 100        ;���Ĺ�����Χ
    mov     edi, [eax]                          ;����λ�ã�����TOWERPOSITION������
    mov     (Tower PTR [ebx]).Pos.x, edi
    mov     edi, [eax+4] 
    mov     (Tower PTR [ebx]).Pos.y, edi
    add     eax, 8
    add     ebx, TYPE Tower
    loop    Initialize_Tower_Loop

;��ʼ�������ִ���Ϣ
    mov     eax, ROUND_NUMBER
    mov     Game.Round_Num, eax
    mov     Game.Round, 0
    mov     ebx, OFFSET EACH_ROUND_ENEMY_NUMBER ;ebxָ��ÿ�ֹ�����������
    mov     edx, OFFSET EACH_ROUND_ENEMY_TYPE   ;edxָ��ÿ�ֹ�����������
    mov     esi, OFFSET Game.RoundArray         ;esiָ��ÿ���ִ�����  
    mov     ecx, eax
Initialize_Round_Loop:
    mov     (Round PTR [esi]).Trigger_Tick, 0   ;����ÿ�ִ���ʱ��
    mov     eax, [ebx]
    mov     (Round PTR [esi]).EnemyNumber, eax  ;����ÿ�ֹ�������
    mov     eax, esi
    add     eax, 8
    mov     edi, eax                            ;ediָ��ÿ�ֹ�������
    push    ecx
    mov     ecx, [ebx]
    ;��ʼ��ÿ�ֹ���
    Initialize_Round_Enemy_Loop:
        mov     eax, [edx]
        mov     (Enemy PTR [edi]).Enemy_Type, eax
        mov     eax, ENEMY_LIFE_0
        mov     (Enemy PTR [edi]).Current_Life, eax
        mov     eax, ENEMY_MONEY_0
        mov     (Enemy PTR [edi]).Money, eax
        add     edx, 4
        add     edi, TYPE Enemy
        loop    Initialize_Round_Enemy_Loop
    pop     ecx
    ;ָ���ƶ�
    add     esi, TYPE Round
    add     ebx, TYPE DWORD
    loop    Initialize_Round_Loop

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
    add     Game.Player_Money, eax
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
    mov     (Enemy PTR [esi]).Current_Dir, ecx
    ret
ActivateEnemy ENDP

;----------------------------------------------------------------------   
EnemyMove PROC USES edi esi ebx eax,
        pEnemy: PTR Enemy
        LOCAL p_x: DWORD,  
              p_y: DWORD,
              e_x: DWORD,
              e_y: DWORD,
              choosed_dir: DWORD
;�ƶ�����
;Ѱ·�㷨�� ѡ��һ����ѡ������ԭ�ȵ��ƶ���������ƶ������ƶ�ʧ�ܣ���
;           ѡ�񣨶���������ԭ�ȷ���ͬ�����������ƶ������磬ԭ�������ߣ���ѡ����������ƶ���
;                       ѡ��ʽ�����ݵ�ǰ����յ����λ�á���ʧ�ܣ���
;           ѡ��������ѡ���루�����෴�ķ����ߡ���ʧ��, ��
;           ѡ���ģ���ѡ����ԭ�ȷ����෴�ķ����ƶ���
;require: �ض������ָ��
;----------------------------------------------------------------------
    mov     edi, pEnemy
    mov     ebx, OFFSET Game_Map
    mov     ecx, (Enemy PTR [edi]).Current_Pos.x
    cmp     ecx, 0
    je      GETY_Done
GETY:
    add     ebx, (MAP_WIDTH)
    loop    GETY
GETY_Done:
    mov     ecx, (Enemy PTR [edi]).Current_Pos.y
    cmp     ecx, 0
    je      STEP1
GETX:
    add     ebx, 1
    loop    GETX
STEP1:
    ;check if current direction is movable
    mov     ecx, (Enemy PTR [edi]).Current_Dir
    INVOKE  CheckMovable, ebx, ecx
    cmp     eax, 0
    je      STEP2
    mov     choosed_dir, ecx
    jmp     EnemyMove_Exit
STEP2:
    mov     eax, (Enemy PTR [edi]).Current_Pos.x
    mov     p_x, eax
    mov     eax, (Enemy PTR [edi]).Current_Pos.y
    mov     p_y, eax
    mov     eax, Game.End_Pos.x
    mov     e_x, eax
    mov     eax, Game.End_Pos.y
    mov     e_y, eax
    .IF ecx == 0 || ecx == 3
      mov     eax, e_x
      mov     edx, p_x
      .IF eax < edx
        mov     choosed_dir, 1
      .ELSE
        mov     choosed_dir, 2
      .ENDIF 
    .ELSE
      mov     eax, e_y
      mov     edx, p_y
      .IF eax < edx
        mov     choosed_dir, 0
      .ELSE
        mov     choosed_dir, 3
      .ENDIF
    .ENDIF
    mov edx, choosed_dir
    INVOKE  CheckMovable, ebx, edx
    cmp     eax, 0
    je      STEP3
    jmp     EnemyMove_Exit
STEP3:
    mov     eax, edx
    mov     edx, 3
    sub     edx, eax
    mov     choosed_dir, edx
    INVOKE  CheckMovable, ebx, edx
    cmp     eax, 0
    je      STEP4
    jmp     EnemyMove_Exit
STEP4:
    mov     eax, ecx
    mov     edx, 3
    sub     edx, eax
    mov     choosed_dir, edx
EnemyMove_Exit:    
    mov     eax, choosed_dir
    .IF eax == 0
      dec     (Enemy PTR [edi]).Current_Pos.y
    .ELSEIF eax == 1
      dec     (Enemy PTR [edi]).Current_Pos.x
    .ELSEIF eax == 2
      inc     (Enemy PTR [edi]).Current_Pos.y
    .ELSE
      inc     (Enemy PTR [edi]).Current_Pos.x
    .ENDIF
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

;----------------------------------------------------------------------     
CheckMovable PROC USES edi ebx ecx,
    pPoint: DWORD,
    Dir: DWORD
;�ж�ĳ���Ƿ�����ƶ�
;require: ��ǰ�����꣬���ƶ��ķ�λ
;----------------------------------------------------------------------
    mov     edi, pPoint   
    mov     ebx, Dir
    .IF ebx == 0
      sub   edi, MAP_WIDTH
    .ELSEIF ebx == 3
      add   edi, MAP_WIDTH
    .ELSEIF ebx == 1
      sub   edi, 1
    .ELSE
      add   edi, 1
    .ENDIF
    mov ecx, [edi]
    .IF ecx == 1
      mov   eax, 1
    .ELSE
      mov   eax, 0
    .ENDIF
    ret
CheckMovable ENDP

END
