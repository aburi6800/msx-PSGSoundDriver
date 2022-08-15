SECTION code_user
PUBLIC _main

; --------------------------------------------------
; ドライバを使用するプログラムで必要
; --------------------------------------------------
EXTERN SOUNDDRV_INIT
EXTERN SOUNDDRV_EXEC
EXTERN SOUNDDRV_BGMPLAY
EXTERN SOUNDDRV_SFXPLAY
EXTERN SOUNDDRV_STOP
EXTERN SOUNDDRV_PAUSE
EXTERN SOUNDDRV_RESUME
EXTERN SOUNDDRV_STATE
; --------------------------------------------------
; ここまで
; --------------------------------------------------


_main:
; ====================================================================================================
; テストアプリケーション
; ====================================================================================================
TESTAPP:
    CALL INIT
    CALL MAINLOOP
    JP TESTAPP


; ====================================================================================================
; 初期処理
; ====================================================================================================
INIT:
    ; ■画面初期化
    CALL SCREEN_INIT

    ; ■フォントパターン定義
    CALL SET_FONT_PATTERN

    ; ■文字列表示
    LD DE,STRDATA1
    CALL PRTFIXSTR
    LD DE,STRDATA2
    CALL PRTFIXSTR
    LD DE,STRDATA3
    CALL PRTFIXSTR
    LD DE,STRDATA4
    CALL PRTFIXSTR
    LD DE,STRDATA5
    CALL PRTFIXSTR
    LD DE,STRDATA6
    CALL PRTFIXSTR
    LD DE,STRDATA7
    CALL PRTFIXSTR
    LD DE,STRDATA8
    CALL PRTFIXSTR
    LD DE,STRDATA9
    CALL PRTFIXSTR
    LD DE,STRDATA10
    CALL PRTFIXSTR
    LD DE,STRDATA11
    CALL PRTFIXSTR
    LD DE,STRDATA12
    CALL PRTFIXSTR
    LD DE,STRDATA13
    CALL PRTFIXSTR

    ; --------------------------------------------------
    ; ドライバを使用するプログラムで必要
    ; --------------------------------------------------
    ; ■ドライバ初期化
    ;   利用するアプリケーションで行う処理
    ;   H.TIMIフックのバックアップと書き換えも行われる
    CALL SOUNDDRV_INIT
    ; --------------------------------------------------
    ; ここまで
    ; --------------------------------------------------


; ====================================================================================================
; メイン
; ====================================================================================================
MAINLOOP:
    CALL GET_KEYMATRIX              ; キーマトリクス取得

    LD A,(KEYBUFF+21)               ; F1キーの入力を取得
    OR A
    JR Z,MAINLOOP_L0                ; 未入力(=キーバッファの値がゼロ)なら次の処理へ

    ; F1キーが押されていたらここに入る
    LD A,(SOUNDDRV_STATE)           ; サウンドドライバーの状態が一時停止中か？
    CP 2
    JR C,MAINLOOP_L                 ; 2未満(=一時停止していない)なら一時停止する

    CALL SOUNDDRV_RESUME    
	JR MAINLOOP

MAINLOOP_L:
    CALL SOUNDDRV_PAUSE    
    LD HL,_SFX_PAUSE
    CALL SOUNDDRV_SFXPLAY

	JR MAINLOOP

MAINLOOP_L0:
    LD A,(SOUNDDRV_STATE)           ; サウンドドライバーの状態が一時停止中か？
    AND 2
    JR NZ,MAINLOOP

    LD B,10                         ; 0〜9のキーの入力をチェック
    LD DE,KEYBUFF                   ; キーバッファの先頭アドレス

MAINLOOP_L1:
    LD A,(DE)                       ; A <- キーバッファの値
    OR A
    JR Z,MAINLOOP_L4                ; キーバッファの値がゼロ(=OFF)なら次の処理へ

MAINLOOP_L2:
    LD A,B                          ; A < B(ループカウンタ)
    DEC A                           ; Bは1〜10なので、-1する

    LD C,A                          ; C <- A (計算用に値をコピー)
    ADD A,A                         ; A <- A*2+C = A*3
    ADD A,C

    LD HL,MAINLOOP_L3

    PUSH DE
    LD D,0                          ; DE <- A
    LD E,A
    ADD HL,DE                       ; Noに対応するJPのアドレスを求める
    POP DE
    JP (HL)

MAINLOOP_L3:
    JP PLAY9
    JP PLAY8
    JP PLAY7
    JP PLAY6
    JP PLAY5
    JP PLAY4
    JP PLAY3
    JP PLAY2
    JP PLAY1
    JP PLAY0

MAINLOOP_L4:
    INC DE
    DJNZ MAINLOOP_L1

	JR MAINLOOP


PLAY0:
    LD HL,$0000
    CALL WRTCUR

    ; --------------------------------------------------
    ; 演奏を止めるときは、SOUNDDRV_STOPをCALLする
    ; --------------------------------------------------
    CALL SOUNDDRV_STOP

    JP MAINLOOP_L4

PLAY1:
    LD HL,32*7+2
    CALL WRTCUR

    ; --------------------------------------------------
    ; BGMの演奏を開始するときは、HLにデータの先頭アドレスを設定し
    ; SOUNDDRV_BGMPLAYをCALLする
    ; --------------------------------------------------
    LD HL,_00
    CALL SOUNDDRV_BGMPLAY

    JP MAINLOOP_L4

PLAY2:
    LD HL,32*8+2
    CALL WRTCUR

    LD HL,_01
    CALL SOUNDDRV_BGMPLAY
    JP MAINLOOP_L4

PLAY3:
    LD HL,32*9+2
    CALL WRTCUR

    LD HL,_02
    CALL SOUNDDRV_BGMPLAY
    JP MAINLOOP_L4

PLAY4:
    LD HL,32*10+2
    CALL WRTCUR

    LD HL,_03
    CALL SOUNDDRV_BGMPLAY
    JP MAINLOOP_L4

PLAY5:
    LD HL,32*11+2
    CALL WRTCUR

    LD HL,_04
    CALL SOUNDDRV_BGMPLAY
    JP MAINLOOP_L4

PLAY6:
    LD HL,32*12+2
    CALL WRTCUR

    LD HL,_05
    CALL SOUNDDRV_BGMPLAY
    JP MAINLOOP_L4

PLAY7:
    LD HL,32*13+2
    CALL WRTCUR

    LD HL,_06
    CALL SOUNDDRV_BGMPLAY
    JP MAINLOOP_L4

PLAY8:
    LD HL,32*14+2
    CALL WRTCUR

    LD HL,_07
    CALL SOUNDDRV_BGMPLAY
    JP MAINLOOP_L4

PLAY9:
    LD HL,32*15+2
    CALL WRTCUR

    ; --------------------------------------------------
    ; SFXの演奏を開始するときは、HLにデータの先頭アドレスを設定し
    ; SOUNDDRV_SFXPLAYをCALLする
    ; --------------------------------------------------
    LD HL,SFX_03
    CALL SOUNDDRV_SFXPLAY

    JP MAINLOOP_L4

WRTCUR:
    PUSH BC
    PUSH DE
    PUSH HL

    LD DE,CURDATA0
    LD HL,32*7+2
    CALL PRTSTR
    LD DE,CURDATA0
    LD HL,32*8+2
    CALL PRTSTR
    LD DE,CURDATA0
    LD HL,32*9+2
    CALL PRTSTR
    LD DE,CURDATA0
    LD HL,32*10+2
    CALL PRTSTR
    LD DE,CURDATA0
    LD HL,32*11+2
    CALL PRTSTR
    LD DE,CURDATA0
    LD HL,32*12+2
    CALL PRTSTR
    LD DE,CURDATA0
    LD HL,32*13+2
    CALL PRTSTR
    LD DE,CURDATA0
    LD HL,32*14+2
    CALL PRTSTR
    LD DE,CURDATA0
    LD HL,32*15+2
    CALL PRTSTR

    POP HL
    LD A,H
    OR L
    JR Z,WRTCUR_EXIT

    LD DE,CURDATA1
    CALL PRTSTR

WRTCUR_EXIT:
    POP DE
    POP BC
    RET


; ====================================================================================================
; キーマトリクス取得処理
; ====================================================================================================
GET_KEYMATRIX:

    LD HL,KEYBUFF                   ; HL <- キーバッファアドレス
    LD DE,KEYBUFF_SV                ; HL <- キー入力バッファSVの先頭アドレス

    LD A,0                          ; キーマトリクスの0行目をスキャン対象
    CALL SNSMAT                     ; BIOS キーマトリクススキャン
    CALL GET_KEYMATRIX_SUB          ; 入力キーの情報をバッファに設定

    LD A,1                          ; キーマトリクスの1行目をスキャン対象
    CALL SNSMAT                     ; BIOS キーマトリクススキャン
    CALL GET_KEYMATRIX_SUB          ; 入力キーの情報をバッファに設定

    LD A,6                          ; キーマトリクスの6行目をスキャン対象
    CALL SNSMAT                     ; BIOS キーマトリクススキャン
    CALL GET_KEYMATRIX_SUB          ; 入力キーの情報をバッファに設定

    RET


GET_KEYMATRIX_SUB:
    ; ■以下前提
    ;   - Aレジスタにスキャン結果のデータが入っている
    ;   - HLレジスタにキーバッファのアドレスが設定されている
    ;   - DEレジスタにキー入力バッファSVのアドレスが設定されている
    LD B,8                          ; 0〜7ビットをスキャンするためのループ回数
    LD C,A                          ; C <- A (値を退避)

GET_KEYMATRIX_SUB_L1:
    LD A,C                          ; A <- C (退避した値をAレジスタに戻す)
    AND %00000001                   ; 下位1ビットを判定
    JR NZ,GET_KEYMATRIX_SUB_L2      ; ビットが立っている=キーが押されていないならL2へ

    ; ■キーが押されているときの処理
    ;   キー入力バッファSVの値を読み、OFFの時だけキー入力バッファをONにする
    ;   キー入力バッファSVがONの時は押しっぱなしなので、キー入力バッファをOFFにする
    LD A,(DE)                       ; A <- キー入力バッファSV
    OR A
    JR Z,GET_KEYMATRIX_SUB_L12      ; キー入力バッファSVがOFFの時はL12へ

    LD (HL),KEY_OFF                 ; キー入力バッファにOFFを設定
                                    ; キー入力バッファSVはそのままで良いので何もしない
    JR GET_KEYMATRIX_SUB_L3

GET_KEYMATRIX_SUB_L12:
    LD (HL),KEY_ON                  ; キー入力バッファにONを設定
    LD A,KEY_ON
    LD (DE),A                       ; キー入力バッファSVにONを設定
    JR GET_KEYMATRIX_SUB_L3

GET_KEYMATRIX_SUB_L2:
    ; ■キーが押されていないときの処理
    LD (HL),KEY_OFF                 ; キーバッファワークにキーオフを設定
    LD A,KEY_OFF
    LD (DE),A                       ; キー入力バッファSVにOFFを設定

GET_KEYMATRIX_SUB_L3:
    INC HL                          ; キーバッファワークのアドレスを+1
    INC DE                          ; キー入力バッファSVのアドレスを+1
    SRL C                           ; Cレジスタの値を右シフト

    DJNZ GET_KEYMATRIX_SUB_L1

    RET


; ====================================================================================================
; 画面初期化
; ====================================================================================================
SCREEN_INIT:
    ; ■COLOR 15,1,1
    LD A,15                         ; Aレジスタに文字色をロード 
    LD (FORCLR),A                   ; Aレジスタの値をワークエリアに格納
    LD A,1                          ; Aレジスタに全景色をロード
    LD (BAKCLR),A                   ; Aレジスタの値をワークエリアに格納
;    LD A,1                         ; Aレジスタに背景色をロード
    LD (BDRCLR),A                   ; Aレジスタの値をワークエリアに格納

    ; ■SCREEN 1,2,0
    LD A,(REG1SAV)                  ; AレジスタにVDPコントロールレジスタ1の値をロード
    OR 2                            ; ビット2を立てる(=スプライトモードを16x16に設定)
    LD (REG1SAV),A                  ; Aレジスタの値をVDPコントロールレジスタ1のワークエリアに格納
    LD A,1                          ; Aレジスタにスクリーンモードの値を設定
    CALL CHGMOD                     ; BIOS スクリーンモード変更
    LD A,0                          ; Aレジスタにキークリックスイッチの値(0=OFF)をロード
    LD (CLIKSW),A                   ; Aレジスタの値をワークエリアに格納

    ; ■WIDTH 32
    LD A,32                         ; AレジスタにWIDTHの値を設定
    LD (LINL32),A                   ; Aレジスタの値をワークエリアに格納

    ; ■KEY OFF
    CALL ERAFNC                     ; BIOS ファンクションキー非表示

    RET


; ====================================================================================================
; フォントパターン定義
; ====================================================================================================
SET_FONT_PATTERN:
	LD HL,FONT_PTN_DATA			    ; HLレジスタに転送元データの先頭アドレスを設定
    LD DE,PTN_GEN_ADDR+32*8         ; DEレジスタに転送先アドレスを設定
	LD BC,8*64					    ; BCレジスタにデータサイズを指定
    CALL LDIRVM					    ; BIOS VRAMブロック転送

    RET


; ====================================================================================================
; 文字列固定位置表示サブルーチン
; IN  : DE = 表示文字データの開始アドレス
; HLレジスタを破壊します
; ====================================================================================================
PRTFIXSTR:
    LD A,(DE)                       ; DE <- HLアドレスの示す表示位置データ
    LD L,A
    INC DE
    LD A,(DE)
    LD H,A
    INC DE                          ; DE <- 文字列データの先頭アドレス


; ====================================================================================================
; 文字列表示サブルーチン
; IN  : HL = 表示位置（y*32+x）
;       DE = 表示文字データの開始アドレス
; BCレジスタを破壊します
; ====================================================================================================
PRTSTR:
    LD BC,PTN_NAME_ADDR             ; BC <- パターンネームテーブルの先頭アドレス
    ADD HL,BC                       ; HL=HL+BC

PRTSTR_L1:
	LD A,(DE)				        ; AレジスタにDEレジスタの示すアドレスのデータを取得
	OR 0					        ; 0かどうか
    JR Z,PRTSTR_END			        ; 0の場合はPRTENDへ

	CALL WRTVRM				        ; BIOS WRTVRM呼び出し
	    					        ; - HL : 書き込み先のVRAMアドレス
    	                            ; - A  : 書き込むデータ

	INC HL					        ; HL=HL+1
    INC DE					        ; DE=DE+1
    JR PRTSTR_L1

PRTSTR_END:
	RET


; ====================================================================================================
; 定数エリア
; romに格納される
; ====================================================================================================
SECTION rodata_user

; ■BIOSアドレス定義
INCLUDE "include/msxbios.inc"

; ■システムワークエリアアドレス定義
INCLUDE "include/msxsyswk.inc"

; ■VRAMワークエリアアドレス定義
INCLUDE "include/msxvrmwk.inc"

; ■キースキャン用定数
KEY_ON:                 EQU $01     ; キーオン
KEY_OFF:                EQU $00     ; キーオフ

; ■フォントパターン
INCLUDE "sample_res/font.asm"

; ■表示文字列データ
; dw : 表示先のVRAMアドレスのオフセット値(下位/上位)    
; db : 表示文字列、最後に0を設定すること
STRDATA1:
    DW 32*3+6
	DB "MSX PSG DRIVER TEST",0
STRDATA2:
    DW 32*4+6
	DB "-------------------",0
STRDATA3:
    DW 32*7+3
	DB "[1] BGM00",0
STRDATA4:
    DW 32*8+3
	DB "[2] BGM01(NO LOOP)",0
STRDATA5:
    DW 32*9+3
	DB "[3] BGM02",0
STRDATA6:
    DW 32*10+3
	DB "[4] BGM03",0
STRDATA7:
    DW 32*11+3
	DB "[5] BGM04",0
STRDATA8:
    DW 32*12+3
	DB "[6] BGM05",0
STRDATA9:
    DW 32*13+3
	DB "[7] BGM06(NO LOOP)",0
STRDATA10:
    DW 32*14+3
	DB "[8] BGM07(NO LOOP)",0
STRDATA11:
    DW 32*15+3
	DB "[9] SFX01",0
STRDATA12:
    DW 32*17+3
	DB "[0] STOP",0
STRDATA13:
    DW 32*19+3
	DB "[F1]PAUSE",0
CURDATA0:
    DB " ",0
CURDATA1:
    DB ">",0


; ----------------------------------------------------------------------------------------------------
; 曲データ
; サウンドドライバを使用するプログラムで定義が必要
; ----------------------------------------------------------------------------------------------------

INCLUDE "sample_res/00.asm"
INCLUDE "sample_res/01.asm"
INCLUDE "sample_res/02.asm"
INCLUDE "sample_res/03.asm"
INCLUDE "sample_res/04.asm"
INCLUDE "sample_res/05.asm"
INCLUDE "sample_res/06.asm"
INCLUDE "sample_res/07.asm"
INCLUDE "sample_res/sfx_03.asm"
INCLUDE "sample_res/sfx_pause.asm"


; ====================================================================================================
; ワークエリア
; プログラム起動時にcrtでゼロでramに設定される 
; ====================================================================================================
SECTION bss_user

; ----------------------------------------------------------------------------------------------------
; その他ワークエリア
; ----------------------------------------------------------------------------------------------------
; ■キー入力バッファ
KEYBUFF:
    DB  $00,$00,$00,$00,$00,$00,$00,$00 ; キーマトリクス行0
    DB  $00,$00,$00,$00,$00,$00,$00,$00 ; キーマトリクス行1
    DB  $00,$00,$00,$00,$00,$00,$00,$00 ; キーマトリクス行6
KEYBUFF_SV:
    DB  $00,$00,$00,$00,$00,$00,$00,$00 ; キーマトリクス行0
    DB  $00,$00,$00,$00,$00,$00,$00,$00 ; キーマトリクス行1
    DB  $00,$00,$00,$00,$00,$00,$00,$00 ; キーマトリクス行6

